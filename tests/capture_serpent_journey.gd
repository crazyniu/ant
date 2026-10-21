extends SceneTree
class LoggedPlay extends "res://scripts/play.gd":
	var event_trace:Array=[]
	func consume_rule_events()->void:
		for event in rules._events:
			if event.type in ["color_clicked","ant_dispatched","bead_picked_up","bead_unloading","bead_delivered","cannon_fired","segment_hit","segment_removed","victory","defeat"]:event_trace.append(event.duplicate(true))
		super.consume_rule_events()
class ReviewClock extends Node:
	var harness:SceneTree
	var seconds:=0.0
	func _process(delta:float)->void:
		seconds+=delta;harness.observe(seconds)
var scene:Control
var clock_node:ReviewClock
var out:="/tmp/ant-serpent-journey"
var done:=false
var shots:Dictionary={}
var terminal_at:=-1.0
var seen_events:=0
var maximum_carriers:=0
func _initialize()->void:call_deferred("run")
func run()->void:
	if not OS.get_environment("ANT_RESCUE_EVIDENCE_DIR").is_empty():out=OS.get_environment("ANT_RESCUE_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(out)
	scene=LoggedPlay.new();scene.auto_replay=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false;scene.level_index=2
	root.add_child(scene);current_scene=scene
	clock_node=ReviewClock.new();clock_node.harness=self;root.add_child(clock_node)
func observe(seconds:float)->void:
	if done:return
	maximum_carriers=maxi(maximum_carriers,scene.rules.tasks.size())
	for entry in [["initial",.1],["walking",2.8],["midgame",12.0]]:
		if seconds>=entry[1] and not shots.has(entry[0]):capture(entry[0])
	for index in range(seen_events,scene.event_trace.size()):
		var event:Dictionary=scene.event_trace[index]
		if event.type=="segment_hit" and event.kind=="armored" and int(event.hp)==1 and not shots.has("cracked-armor"):capture("cracked-armor")
		if event.type=="segment_removed" and int(event.alive_count)<=6 and not shots.has("shortened-snake"):capture("shortened-snake")
	seen_events=scene.event_trace.size()
	if not scene.rules.projectile.is_empty():
		var shot:Dictionary=scene.rules.projectile
		if scene.rules.time_us-int(shot.fire_us)>180000 and not shots.has("projectile"):capture("projectile")
	if scene.rules.status in ["victory","defeat"]:
		if terminal_at<0:terminal_at=seconds;capture("last-hit")
		if seconds-terminal_at>=1.85 and not shots.has("result"):capture("result")
		if seconds-terminal_at>=2.5:finish()
	elif seconds>65:finish()
func capture(id:String)->void:
	shots[id]={"movie_seconds":clock_node.seconds,"simulation_us":scene.rules.time_us,"carriers":scene.rules.tasks.size(),"alive_segments":scene.rules.alive_segment_ids.size()}
	call_deferred("save_shot",id)
func save_shot(id:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+id+"-2k.png")
func finish()->void:
	done=true
	var report:Dictionary={"mode":"Godot actual production scene with authored automatic clicks, not human playtest","speed":1,"movie_seconds":clock_node.seconds,"output_pixels":[root.get_texture().get_width(),root.get_texture().get_height()],"status":scene.rules.status,"final_hit_us":scene.rules.terminal_time_us,"remaining_beads":scene.rules.board.size(),"maximum_carriers":maximum_carriers,"conservation_errors":scene.rules.conservation_errors(),"audio":scene.audio_service.get_status(),"shots":shots,"events":scene.event_trace,"source_hashes":{}}
	report.victory_saved=scene.victory_saved
	report.pending_save_kind=scene.pending_save_kind
	for p in ["scripts/play.gd","scripts/rescue_rules.gd","scripts/rescue_fx.gd","scripts/carrier_route.gd","scripts/board_plane.gd","scripts/serpent_view.gd","scripts/serpent_path.gd","assets/serpent/serpent-atlas.png","assets/serpent/serpent-atlas.json","assets/serpent/serpent-armor-atlas.png","assets/serpent/environment.png","assets/serpent/nest-entry.png","assets/serpent/nest-entry.json","data/serpent-levels/serpent-02.json"]:report.source_hashes[p]=FileAccess.get_sha256("res://"+p)
	var f:=FileAccess.open(out+"/serpent-journey.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("SERPENT_JOURNEY ",JSON.stringify({"status":scene.rules.status,"final_hit_us":scene.rules.time_us,"maximum_carriers":maximum_carriers,"conservation_errors":scene.rules.conservation_errors()}))
	scene.set_process(false);scene.queue_free();await process_frame;await process_frame
	quit(0 if report.status=="victory" and report.conservation_errors.is_empty() and report.victory_saved else 1)
