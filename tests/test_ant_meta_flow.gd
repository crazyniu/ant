extends SceneTree
var checks:=0
var failures:Array=[]
var root_path:="/tmp/ant-rescue-meta-%d"%Time.get_ticks_usec()
func _initialize()->void:call_deferred("run")
func check(value:bool,note:String)->void:
	checks+=1
	if not value:failures.append(note);push_error(note)
func await_phase(phase_name:String)->Node:
	for i in range(6000):
		await process_frame
		if is_instance_valid(current_scene) and current_scene.get("phase")==phase_name:return current_scene
	return null
func run()->void:
	var boot=load("res://scenes/startup.tscn").instantiate();boot.profile_directory=root_path;boot.use_command_line_catalog=false;root.add_child(boot);current_scene=boot
	var home=await await_phase("home")
	check(home!=null,"cold entry reaches home")
	if home==null:quit(1);return
	home.open_adventure("map");check(home.adventure.screen=="map","full-screen map")
	home.adventure.choose_level.emit(1);check(home.adventure.screen=="preparation","node enters full preparation")
	home.adventure.get_node("AdventurePage/BackButton").pressed.emit()
	check(home.phase=="map" and home.adventure.screen=="map","preparation back synchronizes parent and displayed screen")
	home.adventure.get_node("AdventurePage/BackButton").pressed.emit()
	check(home.phase=="home" and not home.adventure.visible,"map back returns home in one action")
	home.open_adventure("preparation",1)
	home.adventure.begin_level.emit(1,"worker")
	var play:Node
	for i in range(6000):
		await process_frame
		if is_instance_valid(current_scene) and current_scene!=home and current_scene.get("ready_to_simulate")==true:play=current_scene;break
	check(play!=null,"real loader hands off into play")
	if play==null:quit(1);return
	play.set_process(false)
	if play.modal_title=="YOUR FIRST RESCUE":play.finish_tutorial()
	play.auto_replay=true
	for i in range(800):
		play.advance_replay(.05);play.sync_view();play.consume_rule_events();play.fx.advance(.05);play.serpent.advance(.05);play.apply_actor_poses()
		if play.rules.status=="victory":break
	check(play.rules.status=="victory" and play.victory_saved,"natural final hit persisted victory")
	check(play.reward_receipt.total==150,"first clear actual 150-point receipt")
	check(play.economy_state.points==150,"points committed before result")
	check(play.persist_victory() and play.economy_state.points==150,"repeat result does not award twice")
	play.transition_to_startup("shop")
	var shop_home=await await_phase("shop")
	check(shop_home!=null,"result opens independent shop")
	if shop_home==null:quit(1);return
	shop_home.shop.purchase_requested.emit("level_2")
	check(shop_home.economy_state.points==50 and shop_home.economy_state.carry_level==2,"real earned points buy upgrade")
	shop_home.shop.purchase_requested.emit("level_2")
	check(shop_home.economy_state.points==50,"repeat upgrade does not double debit")
	shop_home.shop.purchase_requested.emit("swift")
	check(shop_home.economy_state.points==50 and not shop_home.economy_state.owned_types.has("swift"),"insufficient balance preserved")
	shop_home.close_shop();check(shop_home.adventure.screen=="map","back returns full map")
	check(shop_home.adventure.selected_level==1,"saved map selection restored")
	shop_home.open_adventure("preparation",2);shop_home.adventure.begin_level.emit(2,"worker")
	var next_play:Node
	for i in range(6000):
		await process_frame
		if is_instance_valid(current_scene) and current_scene!=shop_home and current_scene.get("ready_to_simulate")==true:next_play=current_scene;break
	check(next_play!=null,"unlocked second level launches")
	if next_play!=null:
		check(is_equal_approx(next_play.rules.ant_loadout.speed_multiplier,1.05),"purchased shared upgrade reaches actual rules")
		next_play.set_process(false);next_play.queue_free()
	await process_frame;await process_frame
	var report:Dictionary={"checks":checks,"failures":failures,"scope":"headless production boot/map/preparation/play/reward/shop/purchase/re-entry flow; no native input or visual claim"}
	var f:=FileAccess.open("res://reports/ui/ant-meta-flow.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	print("ANT_META_FLOW ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
