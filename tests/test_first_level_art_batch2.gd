extends SceneTree
const Ball=preload("res://scripts/first_level_bead.gd")
const Motion=preload("res://scripts/first_level_carrier.gd")
var scene:Control
var checks:=0
var failures:Array[String]=[]
var role_samples:Dictionary={}
var views:Array=[]
var stages:Dictionary={}
var projectile_samples:=0
var pickup_samples:=0
func check(ok:bool,note:String)->void:
	checks+=1
	if not ok:failures.append(note);push_error(note)
func pair(v:Vector2)->Array:return [v.x,v.y]
func check_ball(node:Control,role:String)->void:
	var t:Transform2D=scene.get_global_transform().affine_inverse()*node.get_global_transform()
	var dimensions:=Vector2(t.x.length()*node.size.x,t.y.length()*node.size.y)
	check(dimensions.distance_to(Ball.WORLD_SIZE)<.001,role+" final world diameter remains 33.5")
	check(node.get_script()==Ball,role+" uses the one ball implementation")
	role_samples[role]=int(role_samples.get(role,0))+1
func collect(node:Node)->void:
	if node is Control and node.get_script()==Ball:
		var path:=str(scene.get_path_to(node))
		var role:="other"
		if path.begins_with("Mosaic/"):role="board"
		elif "Stock" in path:role="stock"
		elif "Hopper" in path:role="hopper"
		elif "Carried" in path:role="cargo"
		check_ball(node,role)
	for child in node.get_children():collect(child)
func _initialize()->void:call_deferred("run")
func run()->void:
	scene=load("res://scenes/play.tscn").instantiate();scene.auto_replay=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);current_scene=scene;scene.set_process(false)
	check(scene.ready_to_simulate and scene.level_index==1,"Only actual first-level scene starts")
	if not scene.ready_to_simulate:quit(1);return
	collect(scene)
	var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Motion.MANIFEST_PATH))
	var atlas:Image=load(str(manifest.texture)).get_image()
	var actor:Control=scene.ground_ant("blue",Vector2.ZERO,"ArtProbe",scene,Motion.WORLD_DIAMETER)
	var ball:=Ball.new();ball.name="CarriedBead";ball.color_id="blue";ball.edge=Ball.WORLD_SIZE.x;ball.footprint_height=Ball.WORLD_SIZE.y;ball.size=Ball.WORLD_SIZE;actor.add_child(ball)
	Motion.prepare(actor,"blue",Motion.WORLD_DIAMETER)
	for depth in [.88,1.0]:
		actor.scale=Vector2.ONE*depth;ball.scale=Vector2.ONE/depth
		for frame in range(8):
			var state:Dictionary=actor.get_meta(Motion.CACHE_KEY);state.initialized=false;actor.set_meta(Motion.CACHE_KEY,state)
			var pose:Dictionary=Motion.apply(actor,{"time":10.0+frame,"stage":"returning","moving":true,"direction":Vector2.RIGHT.rotated(frame*PI/4.0),"loaded_distance":50.0})
			var entry:Dictionary=manifest.poses[frame];var sprite:TextureRect=actor.get_node("Ant");var material:ShaderMaterial=sprite.material
			check(int(pose.frame_index)==frame,"All eight anatomical views are selected")
			check(int(material.get_shader_parameter("leg_count"))==entry.legs.size(),"Only actual visible legs are enabled")
			for index in range(6):
				var binding:Vector4=material.get_shader_parameter("leg_%d"%index)
				if index<entry.legs.size():
					var leg:Array=entry.legs[index]
					check(binding==Vector4(leg[0],leg[1],leg[2],leg[3]),"Shader receives measured toe binding")
					var pixel:=Vector2i(roundi(float(entry.region[0])+float(leg[2])),roundi(float(entry.region[1])+float(leg[3])))
					check(atlas.get_pixelv(pixel).a>=.5,"Bound toe center is on solid visible art")
				else:check(binding==Vector4.ZERO,"Missing visible legs have disabled zero slots")
			var contact:Vector2=(Vector2(entry.cargo_bottom_contact[0],entry.cargo_bottom_contact[1])-Vector2(entry.foot_anchor[0],entry.foot_anchor[1]))*Motion.WORLD_DIAMETER/Motion.SOURCE_PHYSICAL_WIDTH
			contact+=Vector2(float(pose.posture.x),float(pose.posture.y))*float(pose.source_scale)
			var actual:=ball.position+Vector2(ball.size.x*.5,ball.size.y)*ball.scale
			check(actual.distance_to(contact)<.001,"Back contact compensates parent depth without shrinking cargo")
			check_ball(ball,"eight_view_cargo")
			var frozen:Dictionary=Motion.apply(actor,{"time":10.0+frame,"direction":Vector2.DOWN,"loaded_distance":9999.0})
			check(frozen.phase==pose.phase and frozen.frame_index==pose.frame_index,"Pause freezes actual foot phase and heading")
			views.append({"frame":entry.name,"depth_scale":depth,"visible_legs":entry.legs.size(),"cargo_bottom_world":pair(actual*depth)})
	actor.queue_free();await process_frame
	for step in range(360):
		scene.advance_replay(.05);scene.sync_view();scene.consume_rule_events();scene.fx.advance(.05);scene.serpent.advance(.05);scene.apply_actor_poses()
		check(scene.carriers.size()==scene.rules.tasks.size(),"Every real task has a valid production carrier")
		for id in scene.carriers:
			var carrier:Control=scene.carriers[id];var task:Dictionary=scene.rules.tasks[id];stages[task.stage]=true
			check_ball(carrier.get_node("CarriedBead"),"production_cargo")
			check(carrier.has_meta("carrier_route") and carrier.get_meta("carrier_route").total_length>0,"Live carrier uses an actual nonempty production route")
			var state:Dictionary=carrier.get_meta(Motion.CACHE_KEY)
			if state.last_pose.stage=="pickup":
				pickup_samples+=1
				var hold:=clampf(float(scene.rules.time_us-task.pickup_us)/float(task.return_depart_us-task.pickup_us),0.0,1.0)
				var item:Control=carrier.get_node("CarriedBead");var pose:Dictionary=state.last_pose;var entry:Dictionary=manifest.poses[int(pose.frame_index)]
				var contact:Vector2=(Vector2(entry.cargo_bottom_contact[0],entry.cargo_bottom_contact[1])-Vector2(entry.foot_anchor[0],entry.foot_anchor[1]))*Motion.WORLD_DIAMETER/Motion.SOURCE_PHYSICAL_WIDTH
				var back:=contact-Vector2(item.size.x*.5,item.size.y)*item.scale+Vector2(float(pose.posture.x),float(pose.posture.y))*float(pose.source_scale)
				var expected:=(-item.size*item.scale*.5).lerp(back,smoothstep(0,1,hold))
				check(item.position.distance_to(expected)<.001,"Pickup lifts the full-size source-cell ball to its view-specific back")
		for shot in scene.fx.debug_snapshot().projectiles:
			projectile_samples+=1
			check(scene.fx._layout.round_ball_size==Ball.WORLD_SIZE,"Actual shot uses the same 33.5 draw contract")
			var transform:Transform2D=scene.get_global_transform().affine_inverse()*scene.fx.get_global_transform()
			check((Vector2(transform.x.length(),transform.y.length())*scene.fx._layout.round_ball_size).distance_to(Ball.WORLD_SIZE)<.001,"Flight draw layer preserves final 33.5 world dimensions")
			check(scene.fx._layout.round_ball_asset==Ball.TEXTURE_PATH,"Actual shot uses the same atlas")
			check(scene.fx._layout.round_ball_regions.has(shot.color_id),"Actual shot color maps to the same source region")
	check(pickup_samples>0,"Actual finite pickup hold sampled")
	check(projectile_samples>0,"Real fire events exercised flight draw parameters")
	check(stages.has("outbound") and stages.has("returning") and stages.has("unloading"),"Live outbound, return and unloading sampled")
	var result:Dictionary={"checks":checks,"failures":failures,"role_samples":role_samples,"projectile_draw_contract_samples":projectile_samples,"pickup_pose_samples":pickup_samples,"views":views,"scope":"Headless live nodes, source alpha, transforms and actual shot draw parameters only; not GPU pixels, rendered leg warp, animation feel, real input or user approval."}
	var f:=FileAccess.open("res://reports/first-level/batch-2/art-test.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"\t"));f.close();print("ART_BATCH2 ",JSON.stringify(result))
	scene.audio_service.stop_music();scene.audio_service.stop_all_sfx();await create_timer(.4).timeout;scene.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
