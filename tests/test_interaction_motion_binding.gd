extends SceneTree
## Bounded live adapter checks for cosmetic transfer/refill and modal integration.
var checks:=0
var failures:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(value:bool,message:String)->void:
	checks+=1
	if not value:failures.append(message);push_error(message)
func run()->void:
	var scene=load("res://scenes/play.tscn").instantiate()
	scene.profile_directory="/tmp/ant-rescue-interaction-%d"%Time.get_ticks_usec()
	scene.profile_directory_resolved=true;scene.qa_fixture_mode=true
	scene.use_command_line_level=false;scene.use_command_line_catalog=false
	root.add_child(scene);scene.set_process(false)
	var first:Dictionary=scene.rules.columns[0].teams[0]
	var previous_second:String=scene.rules.columns[0].teams[1].id
	var button:Control=scene.get_node("CandidateQueues/Column1/FrontButton")
	var hit_rect:=Rect2(button.position,button.size)
	check(scene.preview_select_front(0,first.id),"Front dispatch remains immediate")
	check(scene.rules.columns[0].teams[0].id==previous_second,"Queue rule refill does not wait for art")
	check(scene.team_arrivals.size()==1,"Selected ant has one bounded transfer visual")
	check(scene.queue_refills.size()>0,"Rear artwork slides to new front")
	check(not scene.get_node("WorkSlots/Worker0").visible,"Travelling and seated ant never duplicate")
	check(scene.get_node("WorkSlots/Quota0").text==str(scene.rules.slots[0].remaining),"Quota shows authoritative post-dispatch value during transfer")
	check(not scene.preview_select_front(0,previous_second),"Rapid double click still guarded")
	button=scene.get_node("CandidateQueues/Column1/FrontButton")
	check(Rect2(button.position,button.size)==hit_rect,"Refill never moves clickable hit rectangle")
	scene._process(.08)
	var arrival:Control=scene.team_arrivals[0].node
	var position_before:Vector2=arrival.position
	scene.show_pause();var time_before:int=scene.rules.time_us
	scene._process(.3)
	check(scene.rules.time_us==time_before and arrival.position==position_before,"Pause freezes gameplay cosmetic transfers with simulation")
	var overlay:Control=scene.pause_overlay
	scene.dismiss_modal()
	check(scene.pause_overlay==null and not scene.rules.paused,"Close resumes logic synchronously")
	check(overlay.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Retired panel cannot block or consume input")
	scene.show_settings()
	check(not is_instance_valid(overlay) or overlay.get_parent()==null,"Replacing page discards any retired visual")
	scene.dismiss_modal();scene._process(.2)
	check(scene.team_arrivals.is_empty() and scene.queue_refills.is_empty(),"Transfer and refill finish in bounded simulation time")
	check(scene.get_node("WorkSlots/Worker0").visible,"Seated ant restored after transfer")
	var saw_hold:=false;var saw_delivery:=false
	for i in 60:
		scene._process(.04)
		for id in scene.rules.tasks:
			var task:Dictionary=scene.rules.tasks[id]
			if task.stage=="returning" and scene.rules.time_us<task.return_depart_us:
				saw_hold=true
				var bead:Control=scene.carriers[id].get_node("CarriedBead")
				check(bead.scale.x>=.65 and bead.scale.x<=1.0,"Pickup lift stays finite and attached")
		if not scene.stock_arrivals.is_empty():saw_delivery=true
	check(saw_hold and saw_delivery,"Real pickup and stock arrival invoke motion")
	check(scene.rules.conservation_errors().is_empty(),"Cosmetic feedback does not alter conservation")
	var result:={"pass":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Current actual play adapter; no rule or timing changes"}
	var f:=FileAccess.open("res://reports/ui/interaction-motion-binding.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"\t"));f.close()
	print("INTERACTION_MOTION_BINDING ",JSON.stringify(result))
	scene.queue_free();await process_frame;await process_frame;await create_timer(.08).timeout
	quit(0 if failures.is_empty() else 1)
