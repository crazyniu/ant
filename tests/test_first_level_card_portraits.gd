extends "res://tests/export_first_level_batch2.gd"
## Narrow card binding/state evidence. This is not native mouse or GL acceptance.
const Saves=preload("res://scripts/save_service.gd")
const Catalog=preload("res://scripts/level_catalog.gd")
var checks:=0
var failures:Array[String]=[]
var states:Array=[]
var evidence_directory:=""
func check(ok:bool,note:String)->void:
	checks+=1
	if not ok:failures.append(note);push_error(note)
func run()->void:
	evidence_directory=OS.get_environment("ANT_CARD_EVIDENCE_DIR")
	if evidence_directory.is_empty():evidence_directory="user://first-level-card-evidence"
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_directory))==OK,"Local evidence directory is writable without adding snapshots to source control")
	var profile:="/tmp/ant-card-portrait-%d"%Time.get_ticks_usec()
	var saves:=Saves.new(profile,Catalog.level_ids(false),30)
	check(saves.load_save().ok and saves.set_tutorial_completed().ok,"Isolated first-level test profile is ready")
	scene=load("res://scenes/play.tscn").instantiate()
	scene.profile_directory=profile;scene.profile_directory_resolved=true
	scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);current_scene=scene;scene.set_process(false)
	await process_frame
	check(scene.ready_to_simulate and scene.level_index==1,"Only approved first level starts")
	if not scene.ready_to_simulate:quit(1);return
	check(scene.color_buttons.size()==5,"Exactly five real color entrances remain")
	var colors:Array=["blue","red","yellow","green","purple"]
	var material_ids:Dictionary={}
	for i in colors.size():
		var color:String=colors[i]
		var actor:Control=scene.get_node("CandidateQueues/ColorAnt_"+color)
		var count:Label=scene.get_node("CandidateQueues/Remaining_"+color)
		var button:Button=scene.color_buttons[color]
		for artwork in [actor,scene.get_node("CandidateQueues/ColorPlate_"+color)]:
			material_ids[artwork.material.get_instance_id()]=true
		check(actor is TextureRect,"Card "+color+" uses independent portrait instead of walking-ant sprite")
		if actor is TextureRect:
			check(actor.texture is AtlasTexture and actor.texture.atlas.resource_path=="res://assets/first-level/card-portrait.png","Card "+color+" consumes shared portrait asset")
		check(actor.material is ShaderMaterial and actor.material.get_shader_parameter("tint")==scene.COLOR_VALUES[color],"Card "+color+" uses the real color identity")
		check(actor.mouse_filter==Control.MOUSE_FILTER_IGNORE and count.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Portrait and real number do not consume clicks")
		check(actor.get_index()<count.get_index(),"Real number is painted after portrait")
		check(button.position.distance_to(Vector2(62+i*165.6,1342))<.001 and button.size.distance_to(Vector2(153.6,176))<.001,"Existing card hit rectangle is unchanged")
		check(count.position.distance_to(Vector2(button.position.x+153.6*.56,1436))<.001 and count.size.distance_to(Vector2(153.6*.39,65))<.001,"Existing number rectangle is unchanged")
		check(count.is_visible_in_tree() and count.text==str(scene.rules.snapshot().available_counts[color]),"Card "+color+" shows authoritative available count, not old team size")
	check(material_ids.size()==10,"Each of five portraits and five plates owns its independent color material")
	var shader_source:=FileAccess.get_file_as_string("res://scripts/first_level_color.gdshader")
	check(shader_source.contains("item_modulate=COLOR;") and shader_source.contains("*item_modulate;") and not shader_source.contains("*COLOR;"),"Shader keeps vertex modulation separate from fragment texture COLOR; static contract, not GPU pixel acceptance")
	export_state("initial")
	for i in 4:
		var chosen:=""
		for color in colors:
			if scene.rules.snapshot().color_states[color].state=="ready":chosen=color;break
		check(not chosen.is_empty(),"An actual reachable color exists for the next free carrier")
		if chosen.is_empty():break
		var before:int=scene.rules.tasks.size()
		var available:int=scene.rules.snapshot().available_counts[chosen]
		scene.color_buttons[chosen].pressed.emit();scene.sync_view()
		check(scene.rules.tasks.size()==before+1,"One connected button press creates exactly one ant")
		# The frozen rules count balls still on the board, including reservations.
		# A click reserves; only the actual pickup removes a ball from this number.
		check(scene.get_node("CandidateQueues/Remaining_"+chosen).text==str(available),"Reservation does not falsely remove an uncollected board ball")
		if i==0:export_state("one-reserved")
	check(scene.rules.tasks.size()==4,"Transport capacity remains four")
	scene.color_buttons.blue.pressed.emit();scene.sync_view()
	check(scene.rules.tasks.size()==4,"Fifth press cannot create a fifth carrier")
	export_state("capacity-full")
	var original_board_count:int=scene.rules.board.size()
	for step in 300:
		scene.rules.update_us(50000);scene.sync_view();scene.consume_rule_events()
		scene.fx.advance(.05);scene.serpent.advance(.05);scene.apply_actor_poses()
		if scene.rules.board.size()<original_board_count:break
	check(scene.rules.board.size()<original_board_count,"A real first-level pickup occurs in the bounded card test")
	var displayed_total:=0
	for color in colors:
		var value:String=scene.get_node("CandidateQueues/Remaining_"+color).text
		check(value==str(scene.rules.snapshot().available_counts[color]),"Real pickup updates authoritative "+color+" count")
		displayed_total+=int(value)
	check(displayed_total==scene.rules.board.size(),"Five live card counts sum to actual remaining board balls")
	export_state("after-first-pickup")
	scene.rules.set_paused(true);scene.sync_view()
	for color in colors:
		check(scene.color_buttons[color].disabled,"Paused color button is disabled")
		var count:Label=scene.get_node("CandidateQueues/Remaining_"+color)
		check(count.is_visible_in_tree() and count.text==str(scene.rules.snapshot().available_counts[color]),"Paused real count remains visible")
	export_state("paused")
	scene.rules.set_paused(false);scene.sync_view()
	for color in colors:check(not scene.color_buttons[color].disabled,"Resume restores the existing button")
	var report:Dictionary={"checks":checks,"failures":failures,"states":states,"scope":"Only first-level card art binding, immutable hit/count rectangles, authoritative live counts, connected button signals, capacity and pause state. No later level, full gameplay replay, native input, GL shader pixels or user visual acceptance."}
	var f:=FileAccess.open(evidence_directory.path_join("card-test.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"));f.close()
	scene.audio_service.stop_music();scene.audio_service.stop_all_sfx()
	await create_timer(1.8).timeout
	scene.queue_free();await process_frame;await create_timer(.15).timeout
	print("FIRST_LEVEL_CARD_PORTRAITS ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
func export_state(label:String)->void:
	records=[];walk(scene)
	var path:=evidence_directory.path_join("nodes-"+label+".json")
	var f:=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"label":"OFFLINE NODE COMPOSITION · NOT GODOT RENDER","state":label,"time_us":scene.rules.time_us,"canvas":[940,1672],"nodes":records},"\t"));f.close()
	states.append({"state":label,"nodes":path.get_file(),"carrier_count":scene.rules.tasks.size(),"paused":scene.rules.paused})
