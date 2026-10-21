extends SceneTree
var out:="/tmp/ant-color-row-capture"
func _initialize()->void:call_deferred("run")
func shot(id:String)->void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+id+"-2k.png")
func run()->void:
	if not OS.get_environment("ANT_RESCUE_EVIDENCE_DIR").is_empty():out=OS.get_environment("ANT_RESCUE_EVIDENCE_DIR")
	DirAccess.make_dir_recursive_absolute(out)
	var play=load("res://scenes/play.tscn").instantiate()
	play.auto_replay=true;play.use_command_line_catalog=false;play.use_command_line_level=false;play.level_index=4
	play.profile_directory="/tmp/ant-rescue-color-row-%d"%Time.get_ticks_usec();play.profile_directory_resolved=true
	root.add_child(play);current_scene=play;play.set_process(false);play.auto_replay=false
	await process_frame;await process_frame
	play.sync_view();await shot("ruins-single-row")
	var before:int=play.rules.tasks.size();var remaining:int=play.rules.board.size()
	play.color_buttons.yellow.emit_signal("pressed")
	await process_frame;await shot("blocked-feedback")
	var bounds:Dictionary={}
	for color in play.color_buttons:bounds[color]=str(play.color_buttons[color].get_rect())
	var report:Dictionary={"scope":"Actual GL four-color layout and rejected blocked-color handler only; no gameplay timing change","pixels":[root.get_texture().get_width(),root.get_texture().get_height()],"color_rects":bounds,"blocked_kind":play.get_node("CandidateQueues/ColorState_yellow").kind,"tooltip":play.color_buttons.yellow.tooltip_text,"tap_feedback":play.get_node("ClickFeedback").text,"tasks_unchanged":play.rules.tasks.size()==before,"beads_unchanged":play.rules.board.size()==remaining,"source_hashes":{}}
	for path in ["scripts/play.gd","scripts/ui_icon.gd","data/serpent-levels/serpent-04.json","scripts/rescue_rules.gd"]:report.source_hashes[path]=FileAccess.get_sha256("res://"+path)
	var f:=FileAccess.open(out+"/color-row-capture.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("COLOR_ROW_CAPTURE ",JSON.stringify(report))
	play.queue_free();await process_frame;await process_frame;quit(0 if report.tasks_unchanged and report.beads_unchanged else 1)
