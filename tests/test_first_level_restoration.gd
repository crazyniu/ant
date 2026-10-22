extends SceneTree
var scene:Control
var checks:=0
var failures:Array[String]=[]
var cargo_samples:=0
var stages:Dictionary={}
func check(value:bool,note:String)->void:
	checks+=1
	if not value:failures.append(note);push_error(note)
func _initialize()->void:call_deferred("run")
func run()->void:
	scene=load("res://scenes/play.tscn").instantiate();scene.auto_replay=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);current_scene=scene;scene.set_process(false)
	check(scene.ready_to_simulate,"First-level production scene ready")
	if not scene.ready_to_simulate:quit(1);return
	check(scene.level_index==1,"Only first level is exercised")
	check(scene.rules.board.size()==240,"16 by 15 live round-ball nodes")
	check(scene.color_buttons.size()==5,"Five actual source colors")
	check(int(scene.level_config.parameters.max_inflight_ants)==4,"Four-carrier limit")
	check(scene.rules.status=="ready","No automatic dispatch before first input")
	check(scene.get_node("TransportScene/Cannon").material==null,"Bronze cannon is not dyed by ammo color")
	for i in range(3200):
		scene.advance_replay(.05);scene.sync_view();scene.consume_rule_events();scene.fx.advance(.05);scene.serpent.advance(.05);scene.apply_actor_poses();scene.present_pending_outcome()
		check(scene.rules.tasks.size()<=4,"No hidden queued fifth carrier")
		for id in scene.carriers:
			var actor:Control=scene.carriers[id]
			if not is_instance_valid(actor) or not scene.rules.tasks.has(id):continue
			var task:Dictionary=scene.rules.tasks[id];stages[task.stage]=true
			var cargo:Control=actor.get_node("CarriedBead")
			var target:Array=task.path[-1];var expected:Vector2=scene.APPROVED_BALL_SIZE
			var world:Vector2=cargo.size*cargo.scale*actor.scale
			check(world.distance_to(expected)<.01,"Cargo retains the exact board-ball world size in every stage")
			check(cargo.get_script().resource_path=="res://scripts/first_level_bead.gd","Same round-ball asset class on board and carrier")
			cargo_samples+=1
		if scene.rules.status=="victory":break
	check(scene.rules.status=="victory","Actual final damage reaches victory")
	check(scene.rules.conservation_errors().is_empty(),"Ball ledger conserves resources")
	check(scene.victory_saved,"First-level victory saved")
	check(int(scene.reward_receipt.get("total",0))==148,"Latest 110/130 thresholds save 100 base plus 48 time points for this feasible replay")
	# The authoritative victory precedes the defeated-dragon presentation. Let
	# that real FX clock finish without advancing the already-finalized Rules.
	for i in range(120):
		scene.fx.advance(.05);scene.serpent.advance(.05);scene.present_pending_outcome()
		if is_instance_valid(scene.pause_overlay):break
	check(is_instance_valid(scene.pause_overlay) and scene.modal_title=="SAVED!","Real victory result panel becomes ready")
	if is_instance_valid(scene.pause_overlay):check(scene.pause_overlay.get_node_or_null("Button_NEXT LEVEL")==null,"Victory does not expose unapproved Next level")
	check(scene.pending_save_kind.is_empty(),"No pending save error")
	check(stages.has("outbound") and stages.has("returning") and stages.has("unloading"),"Outbound loaded-return and unload are observed")
	var report:Dictionary={"checks":checks,"failures":failures,"status":scene.rules.status,"time_us":scene.rules.time_us,"remaining_balls":scene.rules.board.size(),"cargo_samples":cargo_samples,"observed_stages":stages.keys(),"scope":"Headless production nodes/rules/size assertions only. Not GL rendering, real mouse, natural play, animation feel, sound or user approval."}
	print("FIRST_LEVEL_RESTORATION ",JSON.stringify(report))
	var report_path:=OS.get_environment("ANT_RESTORATION_REPORT")
	if report_path.is_empty():report_path="res://reports/first-level/batch-1/restoration-test.json"
	var f:=FileAccess.open(report_path,FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	scene.audio_service.stop_music();scene.audio_service.stop_all_sfx()
	await create_timer(.4).timeout # Finish the result-panel reveal before teardown.
	scene.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
