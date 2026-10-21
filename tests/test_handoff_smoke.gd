extends SceneTree
## Bounded package integrity probe: actual configured entry -> Home -> loaded play.
var failures:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,reason:String)->void:
	if not ok:failures.append(reason);push_error(reason)
func wait_for(kind:String)->Node:
	var deadline:=Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<deadline:
		var n:=current_scene
		if is_instance_valid(n):
			if kind=="home" and n.get("phase")=="home":return n
			if kind=="game" and n.get("ready_to_simulate")==true:return n
		await process_frame
	return null
func run()->void:
	var entry:PackedScene=load(ProjectSettings.get_setting("application/run/main_scene"))
	check(entry!=null,"configured startup scene missing")
	if entry==null:quit(1);return
	var boot:=entry.instantiate();root.add_child(boot);current_scene=boot
	var home:=await wait_for("home")
	check(home!=null,"real loader did not reach Home")
	if home==null:quit(1);return
	check(home.home_art.has_node("PlayButton"),"Home Play missing")
	home.home_art.get_node("PlayButton").pressed.emit()
	var game:=await wait_for("game")
	check(game!=null,"real play batch did not reach ready game")
	if game==null:quit(1);return
	var candidate:bool=OS.get_cmdline_user_args().has("--campaign-drafts")
	check(game.level_ids.size()==(30 if candidate else 3),"catalog count mismatch")
	check(game.bead_nodes.size()>0,"live bead nodes missing")
	check(game.rules.conservation_errors().is_empty(),"initial conservation mismatch")
	check(game.audio_service.get_status().music_playing,"music transport not running")
	print("HANDOFF_SMOKE ",JSON.stringify({"pass":failures.is_empty(),"failures":failures,"catalog_count":game.level_ids.size(),"bead_nodes":game.bead_nodes.size(),"level":game.level_config.level_id,"audio_driver":AudioServer.get_driver_name(),"hardware_listening":"NOT_RUN"}))
	quit(0 if failures.is_empty() else 1)
