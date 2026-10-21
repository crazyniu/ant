extends SceneTree
## Bounded final UX contract checks only; no campaign replay or audio acceptance.
const Fixture=preload("res://tests/p3_fixture.gd")
var checks:=0
var failures:Array[String]=[]
var profiles:Array[String]=[]
var capture:=false
var evidence:="user://review-evidence/final-feedback"
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func fresh(path:String,qa:=false,replacement:=false)->Control:
	var scene=load("res://scenes/play.tscn").instantiate()
	scene.profile_directory=path;scene.profile_directory_resolved=replacement
	scene.use_command_line_level=false;scene.use_command_line_catalog=false
	if qa:scene.qa_fixture_mode=true;scene.qa_level_config=Fixture.config()
	root.add_child(scene);scene.set_process(false);return scene
func drop(scene:Control)->void:scene.queue_free();await process_frame
func snap(id:String)->void:
	if not capture:return
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var pixels:=root.get_texture().get_image()
	check(pixels.get_size()==Vector2i(1440,2560),"Capture is actual 1440x2560 "+id)
	check(pixels.save_png(evidence.path_join(id+".png"))==OK,"Saved capture "+id)
func fits(label:Label)->bool:return label.get_minimum_size().x<=label.size.x+1
func run()->void:
	capture="--capture-feedback" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(evidence)
	root.size=Vector2i(1440,2560)
	var path:="/tmp/ant-rescue-feedback-%d"%Time.get_ticks_usec();profiles.append(path)
	var scene:=fresh(path)
	check(not scene.has_node("RoundRestartNotice"),"First-ever entry does not claim it is a restart")
	check(scene.modal_title=="YOUR FIRST RESCUE" and scene.rules.paused,"First tutorial remains a paused, single-action teaching screen")
	check(scene.pause_overlay.get_node("StepText1").text=="5 SLOTS · NO TARGET? TEAMS WAIT","Tutorial explicitly explains five-slot waiting")
	check(scene.pause_overlay.get_node("StepText2").text.contains("REACHABLE MATCHING"),"Tutorial describes reachable same-color targets")
	check(scene.pause_overlay.get_node("StepText5").text=="THE LAST HIT RESCUES HER","Tutorial retains last-hit victory")
	for label in scene.pause_overlay.find_children("*","Label",true,false):check(fits(label),"Tutorial text fits: "+label.text)
	await snap("01-tutorial")
	scene.finish_tutorial();await drop(scene)
	scene=fresh(path)
	check(scene.has_node("RoundRestartNotice"),"Existing profile explicitly announces fresh round, not midround continuation")
	check(not scene.rules.paused and scene.rules.status=="ready" and scene.rules.time_us==0,"Restart notice does not add a modal step or start threat")
	check(scene.get_node("RoundRestartNotice").mouse_filter==Control.MOUSE_FILTER_IGNORE and fits(scene.get_node("RoundRestartNotice")),"Restart notice is nonblocking and fits")
	await snap("02-relaunch-notice")
	check(scene.preview_select_front(0,str(scene.rules.columns[0].teams[0].id)),"First normal front input remains accepted under restart notice")
	check(not scene.has_node("RoundRestartNotice"),"First successful front clears restart notice")
	await drop(scene)
	scene=fresh(path,false,true)
	check(not scene.has_node("RoundRestartNotice"),"Same-process scene replacement does not claim process restoration")
	await drop(scene)
	var qa_path:=path+"-qa";profiles.append(qa_path);scene=fresh(qa_path,true)
	check(not scene.has_node("RoundRestartNotice"),"QA never creates a misleading restored-profile notice")
	check(scene.rules.select_front(0,"qa-red").ok,"Prepare one real active red team for live scout context")
	scene.rules.update_us(100000);scene.sync_view();scene.consume_rule_events()
	var result:Dictionary=scene.activate_tool("scout")
	check(result.ok and result.color!=result.current_armor.color,"Scout may recommend a reachable future-color front")
	check(scene.has_node("ScoutHints/CurrentArmor") and scene.has_node("ScoutHints/AmmoContext"),"Scout relates the highlighted current armor to live ammo")
	check(scene.get_node("ScoutHints/AmmoContext").text=="3 MORE RED AMMO · OTHER COLORS STAY STORED","Scout explains shortfall without discarding other stock")
	check(fits(scene.get_node("ScoutHints/AmmoContext")),"Scout shortfall text fits one line")
	await snap("03-scout-ammo-context")
	var saw_fire:=false;var saw_new_armor:=false;var saw_partial:=false
	for i in 160:
		scene._process(.02)
		if not scene.has_node("ScoutHints/AmmoContext"):break
		var label:Label=scene.get_node("ScoutHints/AmmoContext")
		if scene.rules.inventory.red>0 and scene.rules.armor_index==0:
			saw_partial=true
			check(label.text.begins_with(str(3-int(scene.rules.inventory.red))+" MORE RED"),"Delivered partial stock refreshes remaining ammo immediately")
		if not scene.rules.projectile.is_empty():
			saw_fire=true
			check(label.text=="SHOT ON THE WAY · AMMO ALREADY SPENT" and scene.rules.inventory.red==0,"In-flight hint acknowledges actual debit, never a full ammo claim")
		if scene.rules.armor_index==1:
			saw_new_armor=true
			check(label.text.begins_with("3 MORE BLUE AMMO"),"Next armor changes hint color and demand from live state")
			break
	check(saw_partial and saw_fire and saw_new_armor,"Real dispatch/pickup/delivery/fire/hit traversed all affected scout contexts")
	scene.tool_feedback("slots_full");scene.sync_view()
	check(not scene.get_node("ScoutHints/AmmoContext").visible,"Transient error and scout explanation never overlap")
	scene.rules.set_paused(true);var lifetime:float=scene.scout_seconds;scene._process(.1)
	check(scene.scout_seconds==lifetime,"Pause preserves scout hint lifetime")
	scene.rules.set_paused(false);scene._process(3)
	check(not scene.has_node("ScoutHints"),"Short scout context disappears with its highlight")
	check(scene.rules.conservation_errors().is_empty(),"Presentation explanations preserve all gameplay resources")
	await drop(scene)
	for directory in profiles:
		for file in DirAccess.get_files_at(directory):DirAccess.remove_absolute(directory+"/"+file)
		DirAccess.remove_absolute(directory)
	var report:={"pass":failures.is_empty(),"assertions":checks,"failures":failures,"real_gl_captures":capture,"scope":"Five-slot tutorial, honest cold-entry notice, short live scout armor/ammo feedback. No full-campaign or audio/human acceptance rerun."}
	var output:=FileAccess.open(evidence.path_join("gl-report.json" if capture else "headless-report.json"),FileAccess.WRITE);output.store_string(JSON.stringify(report,"\t"));output.close()
	print("FINAL_FEEDBACK_REPORT ",JSON.stringify(report))
	await create_timer(.2).timeout
	quit(0 if failures.is_empty() else 1)
