extends SceneTree
## Normal 1x Godot movie. Only approved deterministic selections are automatic.
class ReviewClock extends Node:
	var harness:SceneTree
	var seconds:=0.0
	var frames:=0
	func _process(delta:float)->void:
		seconds+=delta;frames+=1;harness.observe(seconds,frames)
var scene:Control
var clock_node:ReviewClock
var out:="user://review-evidence/motion-current"
var shots:Dictionary={}
var final_hit_seconds:=-1.0
var report:Dictionary={}
var done:=false
var pickup_probe:=-1
func _initialize()->void:call_deferred("run")
func run()->void:
	DirAccess.make_dir_recursive_absolute(out)
	scene=load("res://scenes/play.tscn").instantiate()
	scene.auto_replay=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);current_scene=scene
	clock_node=ReviewClock.new();clock_node.harness=self;root.add_child(clock_node)
	report={"automatic_replay":true,"human_playtest":false,"speed":1,"viewport":[1440,2560],"source_hashes":{}}
	for p in ["scripts/play.gd","scripts/rescue_rules.gd","scripts/rescue_fx.gd","scripts/carrier_motion.gd","scripts/carrier_motion.gdshader","scripts/combat_tint.gdshader","data/levels/validation-01.json"]:report.source_hashes[p]=FileAccess.get_sha256("res://"+p)
func observe(seconds:float,frames:int)->void:
	if done:return
	if seconds>55:finish(false,"watchdog");return
	for id in scene.rules.tasks:
		var task:Dictionary=scene.rules.tasks[id]
		if pickup_probe<0 and task.stage=="returning" and scene.rules.time_us<task.return_depart_us and scene.rules.time_us-task.pickup_us>=40000:
			pickup_probe=id;capture("ants-pickup",id)
		if id==pickup_probe and scene.rules.time_us-task.return_depart_us>=150000 and not shots.has("ants-loaded-return"):
			capture("ants-loaded-return",id)
	if seconds>=5 and not shots.has("ants-walk"):capture("ants-walk")
	if seconds>=5.17 and not shots.has("ants-next-step"):capture("ants-next-step")
	if scene.rules.status=="defeat":finish(false,"natural_defeat");return
	if scene.rules.status!="victory":return
	if final_hit_seconds<0:
		final_hit_seconds=seconds;report.final_hit_seconds=seconds;report.final_hit_frame=frames
		report.final_hit_us=scene.rules.time_us;report.saved_at_final_hit=scene.victory_saved
	var age:float=scene.fx.dragon_pose().defeat_age
	for entry in [["dragon-hit-stop",.08],["dragon-fall",.62],["dragon-landing",.96],["dragon-settle",1.22]]:
		if age>=entry[1] and not shots.has(entry[0]):capture(entry[0])
	if scene.fx.dragon_pose().defeat_complete and not shots.has("result"):
		capture("result");report.result_seconds=seconds
	if seconds-final_hit_seconds>=2.8:finish(true,"natural_final_hit")
func capture(id:String,target_task:int=-1)->void:
	shots[id]={"movie_seconds":clock_node.seconds,"simulation_us":scene.rules.time_us}
	if target_task>=0 and scene.carriers.has(target_task):
		var actor:Control=scene.carriers[target_task]
		shots[id].carrier={"task":target_task,"logical_position":[actor.position.x,actor.position.y],"stage":scene.rules.tasks[target_task].stage}

	call_deferred("save_shot",id)
func save_shot(id:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+id+".png")
func finish(ok:bool,reason:String)->void:
	done=true;report.pass=ok;report.reason=reason;report.shots=shots
	report.final_status=scene.rules.status;report.conservation_errors=scene.rules.conservation_errors()
	report.audio=scene.audio_service.get_status();report.duration_seconds=clock_node.seconds
	var f:=FileAccess.open(out+"/motion-recording.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("MOTION_RECORDING ",JSON.stringify(report))
	scene.set_process(false);scene.queue_free();await process_frame;await process_frame
	quit(0 if ok else 1)
