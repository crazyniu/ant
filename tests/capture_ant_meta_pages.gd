extends SceneTree
var scene:Control
var out:="/tmp/ant-meta-pages"
func _initialize()->void:call_deferred("run")
func run()->void:
	out=OS.get_environment("ANT_RESCUE_EVIDENCE_DIR")
	if out.is_empty():out="/tmp/ant-meta-pages"
	DirAccess.make_dir_recursive_absolute(out)
	scene=load("res://scenes/startup.tscn").instantiate();scene.profile_directory="/tmp/ant-rescue-meta-capture-%d"%Time.get_ticks_usec();scene.use_command_line_catalog=false;root.add_child(scene);current_scene=scene
	for i in range(6000):
		await process_frame
		if scene.home_ready:break
	if not OS.get_cmdline_user_args().has("--map-only"):await shot("home")
	scene.open_adventure("map");await shot("adventure-map")
	if scene.adventure.get_node("AdventurePage/PageTitleArt").size.x>470. or scene.adventure.get_node("AdventurePage/MapScroll").scroll_vertical<=0:
		push_error("Meta map initial layout check failed");quit(1);return
	if OS.get_cmdline_user_args().has("--map-only"):
		print("ANT_MAP_LAYOUT_OK ",scene.adventure.get_navigation_state());scene.queue_free();await process_frame;await process_frame;quit();return
	scene.open_adventure("preparation",1);await shot("preparation")
	scene.open_shop();await shot("ant-shop")
	scene.close_shop();scene.show_settings();await shot("settings")
	scene.close_current_modal()
	var report:Dictionary={"mode":"actual production startup/map/preparation/shop/settings; fresh isolated profile, no fabricated points","output_pixels":[root.get_texture().get_width(),root.get_texture().get_height()],"points":scene.economy_state.points,"phase":scene.phase,"profile_ready":scene.economy_state.ready,"audio":scene.audio_service.get_status()}
	var f:=FileAccess.open(out+"/meta-pages.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();print("ANT_META_PAGES ",JSON.stringify(report))
	scene.queue_free();await process_frame;await process_frame;quit()
func shot(id:String)->void:
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+id+"-2k.png")
