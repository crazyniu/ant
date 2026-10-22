extends SceneTree
## First-level candidate geometry/event assertions, not an animation-feel pass.
const Saves=preload("res://scripts/save_service.gd")
const Catalog=preload("res://scripts/level_catalog.gd")
const Loading=preload("res://scripts/first_level_loading.gd")
var scene:Control
var checks:=0
var failures:Array[String]=[]
var samples:Array=[]
func check(ok:bool,note:String)->void:
	checks+=1
	if not ok:failures.append(note);push_error(note)
func _initialize()->void:call_deferred("run")
func pose()->void:
	scene.sync_view();scene.consume_rule_events();scene.fx.advance(0);scene.serpent.advance(0);scene.apply_actor_poses()
func advance(delta_us:int)->void:scene.rules.update_us(delta_us);pose()
func center(node:Control)->Vector2:return scene.get_node("TransportScene").get_global_transform().affine_inverse()*(node.get_global_transform()*(node.size*.5))
func sample(label:String)->void:
	var cannon:Control=scene.get_node("TransportScene/Cannon")
	check(scene.loading_balls.size()==1,label+": one actual task-owned incoming ball")
	if scene.loading_balls.size()!=1:return
	var id=scene.loading_balls.keys()[0];var ball:Control=scene.loading_balls[id]
	check(ball.get_parent()==cannon,label+": incoming ball is cannon child")
	check(ball.get_script().resource_path=="res://scripts/first_level_bead.gd" and ball.color_id=="blue",label+": same blue ball class")
	check(Vector2(ball.edge,ball.footprint_height).distance_to(ball.size)<.001,label+": material paint preserves both world-ball axes")
	check((ball.size*ball.scale*cannon.scale).distance_to(scene.APPROVED_BALL_SIZE)<.001,label+": recoil does not resize ammo")
	check(not scene.carriers[id].get_node("CarriedBead").visible,label+": no duplicate cargo ball")
	check(scene.rules.inventory.blue==0 and scene.rules.delivered_counts.blue==0 and scene.rules.shot_counts.blue==0,label+": no early credit/debit/fire")
	check(scene.rules.tasks.size()==1,label+": unload still occupies one of four transport slots")
	check(ball.material.shader.resource_path=="res://scripts/first_level_loading_occlusion.gdshader",label+": independent brass/opening alpha mask wired")
	var gunner:Node2D=cannon.get_node("LoaderAnt")
	var hands:Vector2=scene.get_node("TransportScene").get_global_transform().affine_inverse()*(gunner.get_global_transform()*(Loading.GUNNER_BALL_OFFSET+Loading.receiving_grip_offset()))
	if label=="unload-start":check(hands.distance_to(center(ball))<.01,label+": bound receiving-hand anchor matches same ball center")
	check(gunner.show_behind_parent,label+": brass occludes loader instead of feet walking on front panel")
	check((gunner.get_node("Ant").material.get_shader_parameter("grip_offset")*Loading.GUNNER_SCALE).distance_to(Loading.receiving_grip_offset())<.001,label+": receiving hands alone follow the ball profile")
	samples.append({"label":label,"time_us":scene.rules.time_us,"center":[center(ball).x,center(ball).y],"world_size":[ball.size.x*ball.scale.x*cannon.scale.x,ball.size.y*ball.scale.y*cannon.scale.y],"neutral_receiver_to_ball_distance":hands.distance_to(center(ball))})
func run()->void:
	var profile:=ProjectSettings.globalize_path("user://ant-loading-%d"%Time.get_ticks_usec())
	var saves:=Saves.new(profile,Catalog.level_ids(false),30);check(saves.load_save().ok and saves.set_tutorial_completed().ok,"Isolated first-level profile")
	scene=load("res://scenes/play.tscn").instantiate();scene.profile_directory=profile;scene.profile_directory_resolved=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);current_scene=scene;scene.set_process(false);await process_frame
	check(scene.ready_to_simulate and scene.level_index==1,"Only first level")
	check(is_equal_approx(scene.level_config.transport.unload_pause_sec,.8),"Explicit 0.8 simulation-second candidate")
	check(is_equal_approx(scene.level_config.serpent.speed_units_sec,20.0/145.0),"Enemy speed unchanged")
	scene.color_buttons.blue.pressed.emit();pose();advance(8625000);sample("unload-start")
	var id=scene.loading_balls.keys()[0];var start:Vector2=center(scene.loading_balls[id])
	check(start.distance_to(scene.loading_sources[id])<.001,"No pickup-to-unload jump")
	advance(100000)
	check(center(scene.loading_balls[id]).distance_to(start)<.001,"The receiving grip holds the original ball during the first 0.2 seconds")
	var planted:Vector2=scene.get_node("TransportScene/Cannon/LoaderAnt").position
	advance(200000)
	check(is_equal_approx(scene.get_node("TransportScene/Cannon/LoaderAnt/Ant").material.get_shader_parameter("push").length()*Loading.GUNNER_SCALE,4.0),"Receiving foreleg push is bounded to four world pixels")
	check(scene.get_node("TransportScene/Cannon/LoaderAnt").position.distance_to(planted)<.001,"Supporting feet do not slide with the transferred ball")
	advance(100000);sample("unload-mid")
	var frozen:Vector2=center(scene.loading_balls[id]);var push:Vector2=scene.get_node("TransportScene/Cannon/LoaderAnt/Ant").material.get_shader_parameter("push")
	scene.rules.set_paused(true);advance(1000000)
	check(scene.rules.time_us==9025000 and center(scene.loading_balls[id]).distance_to(frozen)<.001,"Pause freezes world handoff")
	check(scene.get_node("TransportScene/Cannon/LoaderAnt/Ant").material.get_shader_parameter("push")==push,"Pause freezes receiving foreleg pose")
	scene.rules.set_paused(false);scene.rules.set_speed(2);advance(199999);sample("double-speed-near-completion")
	check(scene.rules.time_us==9424998,"Double speed advances only simulation handoff time")
	var target:Vector2=scene.get_node("TransportScene/Cannon").get_transform()*Vector2(97,182)
	check(center(scene.loading_balls[id]).distance_to(target)<.001,"Same ball reaches actual opening before credit")
	advance(1)
	check(scene.loading_balls.is_empty() and scene.rules.tasks.is_empty(),"Actual delivery removes handoff view/releases capacity")
	check(scene.rules.delivered_counts.blue==1 and scene.rules.spent_counts.blue==1 and scene.rules.shot_counts.blue==1,"Exactly one real delivery/debit/fire")
	check(scene.rules.projectile.color=="blue" and scene.fx.debug_snapshot().projectiles.size()==1,"Real fire owns one in-flight blue ball")
	check(not scene.get_node("TransportScene/Cannon/HopperAmmo").visible and scene.fx.debug_snapshot().charge==0.0,"No already-fired charge duplicates in opening")
	check(scene.fx._recoil_age==0.0,"Recoil starts at actual fire timestamp, not earlier frame start")
	check(scene.rules.conservation_errors().is_empty(),"Resource conservation holds")
	advance(225000)
	check(scene.rules.hit_counts.blue==1 and scene.fx.debug_snapshot().projectiles.is_empty(),"Actual hit consumes projectile once")
	# Inspect the presentation helper under nonuniform recoil, without changing Rules.
	var cannon:Control=scene.get_node("TransportScene/Cannon");var hopper:Control=cannon.get_node("HopperAmmo")
	cannon.scale=Vector2(1.08,.92);cannon.rotation=.05;scene.sync_loading_ball_poses()
	check((hopper.size*hopper.scale*cannon.scale).distance_to(scene.APPROVED_BALL_SIZE)<.001,"Loaded preview remains same world size under recoil")
	check(Vector2(hopper.edge,hopper.footprint_height).distance_to(hopper.size)<.001,"Loaded preview paint preserves both world-ball axes")
	check(center(hopper).distance_to(cannon.get_transform()*Vector2(97,182))<.001,"Loaded preview follows transformed cannon opening")
	check(not Geometry2D.is_point_in_polygon(Vector2(65,173),PackedVector2Array(Loading.OPENING_POLYGON)),"Known copper-frame point is excluded from actual opening mask")
	check(Geometry2D.is_point_in_polygon(Vector2(97,182),PackedVector2Array(Loading.OPENING_POLYGON)),"Actual loading center remains inside measured dark opening")
	check(not Geometry2D.is_point_in_polygon(Vector2(97,207),PackedVector2Array(Loading.OPENING_POLYGON)),"Foreground gold lip is not erased by a broad ellipse")
	for i in 10:check(hopper.material.get_shader_parameter("mouth_%d"%i)==Loading.OPENING_POLYGON[i],"Measured opening vertex is bound to the actual shader")
	var padded:TextureRect=cannon.get_node("LoaderAnt/Ant")
	check(padded.size.x/Loading.GUNNER_SCALE>937+4/Loading.GUNNER_SCALE+20,"Padded sprite preserves raised hand at maximum push")
	var ground:Transform2D=scene.get_node("TransportScene").get_global_transform().affine_inverse()*cannon.get_node("LoaderAnt").get_global_transform()
	check(ground.x.distance_to(Vector2.RIGHT)<.001 and ground.y.distance_to(Vector2.DOWN)<.001,"Recoil rotation and nonuniform stretch do not rotate or shear the planted ant")
	check(ground.origin.distance_to(scene.loader_idle_ball_center-Loading.GUNNER_BALL_OFFSET)<.001,"All four foot contacts remain grounded during cannon recoil")
	# Reach the real unchanged enemy deadline during a second genuine unload.
	# No private _finish call, artificial victory, changed enemy speed or economy.
	scene.rules.set_speed(1);pose()
	var travel:float=float(scene.rules.best_target("blue").distance)+float(scene.level_config.transport.approach_distance_cells)
	var before_unload_us:int=int(ceil(travel/2.5*1000000))+300000+int(ceil(travel/2.0*1000000))
	var dispatch_us:int=145000000-before_unload_us-400000
	advance(dispatch_us-scene.rules.time_us);scene.color_buttons.blue.pressed.emit();pose()
	advance(before_unload_us+100000)
	check(scene.loading_balls.size()==1 and scene.rules.status=="running","Second actual unload exists before real goal contact")
	var ending_id=scene.loading_balls.keys()[0]
	# Presentation-only recoil fixture on the real terminal boundary.
	cannon.scale=Vector2(1.08,.92);cannon.rotation=.05;scene.sync_loading_ball_poses()
	var terminal_expected:Vector2=Loading.transfer_center(scene.loading_sources[ending_id],cannon.get_transform()*Vector2(97,182),int(scene.rules.tasks[ending_id].unload_us),int(scene.rules.tasks[ending_id].delivery_us),145000000)
	advance(300000)
	check(center(scene.loading_balls[ending_id]).distance_to(terminal_expected)<.001,"Terminal freezes world ball center even when cannon recoil resets")
	check(scene.rules.status=="defeat" and scene.rules.time_us==145000000,"Real unchanged145s enemy contact ends during unload")
	check(scene.loading_balls.has(ending_id) and not scene.carriers[ending_id].get_node("CarriedBead").visible,"Terminal does not teleport incoming ball back to ant")
	var stopped:Vector2=center(scene.loading_balls[ending_id]);advance(1000000)
	check(center(scene.loading_balls[ending_id]).distance_to(stopped)<.001,"Ended handoff freezes without post-terminal delivery")
	check(scene.rules.delivered_counts.blue==1 and scene.rules.spent_counts.blue==1 and scene.rules.shot_counts.blue==1,"Frozen second ball is never credited, spent or fired")
	check(scene.rules.conservation_errors().is_empty(),"Terminal transport still conserves its task-owned ball")
	await create_timer(.9).timeout # Let the actual defeat overlay callback finish.
	var report={"checks":checks,"failures":failures,"samples":samples,"scope":"Headless source/node geometry, exact task timing, pause/x2, conservation, opening ownership, real fire/hit. Includes real145s defeat during unloading. No native pointer/GL, readable animation, material, audio, concurrent hand-grip or user acceptance."}
	var destination:=OS.get_environment("ANT_LOADING_REPORT");if destination.is_empty():destination="user://first-level-loading-test.json"
	var f:=FileAccess.open(destination,FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();print("FIRST_LEVEL_LOADING ",JSON.stringify(report))
	scene.audio_service.stop_music();scene.audio_service.stop_all_sfx();await create_timer(.4).timeout;scene.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
