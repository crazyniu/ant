extends SceneTree
## First-level-only Shop regression. Signals are not native touch/GL evidence.
const Progression=preload("res://scripts/ant_progression.gd")
const Ball=preload("res://scripts/first_level_bead.gd")
const SpeedEmblem=preload("res://scripts/adventure_view.gd").Emblem
var checks:=0
var failures:Array[String]=[]
var snapshots:Array=[]
var purchase_signals:=0
var profile:="/tmp/ant-rescue-shop-mobile-%d"%Time.get_ticks_usec()
var home:Node
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func press(id:String)->Button:
	var b:Button=home.shop.content.get_node(id)
	check(not b.disabled,id+" is a real enabled Button")
	if not b.disabled:b.pressed.emit()
	return b
func snapshot(label:String)->void:
	var s:Control=home.shop.content
	check(not s.has_node("CapacityCopy"),label+": redundant one-ball copy absent")
	var controls:Array=[]
	for id in ["EquipButton_worker","EquipButton_swift" if s.has_node("EquipButton_swift") else "BuyButton_swift","TrainingButton"]:
		var b:Button=s.get_node(id)
		var paint_id:String=id.replace("Button","") if id!="TrainingButton" else "TrainAction"
		var paint:Control=s.get_node(paint_id)
		check(b.size.y>=116.0,label+": "+id+" has mobile hit height")
		check(b.get_rect()==paint.get_rect(),label+": "+id+" hit matches painted action")
		check(paint.has_node("PaintedNineSlice"),label+": "+id+" uses existing painted skin")
		var primary:bool=false
		if id.begins_with("EquipButton_"):primary=home.economy_state.equipped_type==id.get_slice("_",1)
		elif id=="BuyButton_swift":primary=int(home.economy_state.points)>=500
		else:primary=int(home.economy_state.carry_level)<4 and int(home.economy_state.points)>=int(home.shop.products.levels[str(mini(int(home.economy_state.carry_level)+1,4))].price)
		check_skin(paint,"game/primary" if primary else "game/secondary",label)
		check_button_style(b,label)
		var panel:Control=s.get_node("TrainingPanel" if id=="TrainingButton" else "Card_"+id.get_slice("_",1))
		check(panel.get_rect().encloses(b.get_rect()),label+": "+id+" stays inside its own card")
		controls.append({"name":id,"rect":[b.position.x,b.position.y,b.size.x,b.size.y],"disabled":b.disabled})
	var back:Button=s.get_node("BackButton")
	check(back.size==Vector2(120,120) and back.get_rect()==s.get_node("BackArt").get_rect(),label+": Back is a real 45.96px target with matching art")
	check(s.get_node("ShopTitle").position.x-back.get_rect().end.x==32.0,label+": Back retains 32-unit title gap")
	check((s.get_node("BackArrow").position+s.get_node("BackArrow").size*.5).is_equal_approx(back.get_rect().get_center()) and s.get_node("BackArrow").size==Vector2(68,68),label+": Back arrow keeps centered proportional bounds")
	check_skin(s.get_node("BackArt"),"game/secondary",label)
	check_button_style(back,label)
	for kind in ["worker","swift"]:
		var b:Control=s.get_node("CapacityBall_"+kind)
		check(b.get_script()==Ball and b.size==Vector2(52,52),label+": "+kind+" uses shared round-ball material at HUD size")
		check(Ball.WORLD_SIZE==Vector2(33.5,33.5),label+": world ball size unchanged")
		check(s.get_node("SpeedEmblem_"+kind) is SpeedEmblem,label+": "+kind+" reuses Prep speed emblem")
		var action:Control=s.get_node("EquipButton_"+kind if s.has_node("EquipButton_"+kind) else "BuyButton_"+kind)
		for key in ["Capacity_"+kind,"Speed_"+kind]:
			var value:Label=s.get_node(key)
			check(value.get_rect().end.y<action.position.y,label+": "+key+" does not overlap action")
		check(s.get_node("Capacity_"+kind).text=="1",label+": "+kind+" keeps capacity one")
	for key in ["Points","Capacity_worker","Capacity_swift","Speed_worker","Speed_swift","NextLevel","TrainingEffect","Price_swift","TrainingPrice"]:
		if not s.has_node(key):continue
		var value:Label=s.get_node(key)
		var font_size:=value.get_theme_font_size("font_size")
		check(font_size>=38,label+": "+key+" is at least 14.55px at 360 width")
		check(value.get_theme_font("font").get_string_size(value.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x<=value.size.x,label+": "+key+" fits width")
		check(value.get_minimum_size().y<=value.size.y,label+": "+key+" fits height")
	check(s.get_node("ShopFeedback").get_theme_font_size("font_size")==32,label+": feedback is 12.26px at 360 width")
	check(s.get_node("TrainingEffect").get_rect().end.y<s.get_node("TrainingButton").position.y,label+": training effect clear of button")
	check(s.get_node("TrainingPanel").get_rect().end.y<s.get_node("ShopFeedback").position.y,label+": feedback clear of panel")
	for pair in [["Price_swift","BuyButton_swift"],["TrainingPrice","TrainingButton"]]:
		if s.has_node(pair[0]):check(s.get_node(pair[1]).get_rect().encloses(s.get_node(pair[0]).get_rect()),label+": real price stays inside its own painted action")
	snapshots.append({"name":label,"points":home.economy_state.points,"level":home.economy_state.carry_level,"equipped":home.economy_state.equipped_type,"worker_speed":s.get_node("Speed_worker").text,"swift_speed":s.get_node("Speed_swift").text,"controls":controls})
func check_skin(paint:Control,key:String,label:String)->void:
	var texture:AtlasTexture=paint.get_node("PaintedNineSlice").texture
	var expected:AtlasTexture=home.shop.skin.texture(key)
	check(texture.atlas.resource_path=="res://assets/ui/v03/game-skin-atlas.png" and texture.region==expected.region,label+": "+paint.name+" uses exact "+key+" atlas region, never game/row")
	var slice:NinePatchRect=paint.get_node("PaintedNineSlice")
	check((slice.size*slice.scale).is_equal_approx(paint.size),label+": "+paint.name+" painted slice matches panel bounds")
func check_button_style(b:Button,label:String)->void:
	for state in ["normal","hover","pressed","disabled"]:
		check(b.get_theme_stylebox(state) is StyleBoxEmpty,label+": "+b.name+" "+state+" event layer cannot cover painted skin")
	var focus:StyleBox=b.get_theme_stylebox("focus")
	check(focus is StyleBoxFlat and not focus.draw_center and focus.border_width_left>0 and focus.border_color.a>0,label+": "+b.name+" has visible border-only keyboard focus")
func run()->void:
	home=load("res://scenes/startup.tscn").instantiate();home.profile_directory=profile;home.use_command_line_catalog=false
	root.add_child(home);current_scene=home
	var deadline:=Time.get_ticks_msec()+15000
	while home.phase!="home" and Time.get_ticks_msec()<deadline:await process_frame
	check(home.phase=="home","Production entry loads isolated base profile")
	if home.phase!="home":quit(1);return
	check(home.meta_levels().size()==1 and home.level_index==1,"Only first level is exposed")
	home.open_adventure("preparation",1);home.open_shop()
	home.shop.purchase_requested.connect(func(_product):purchase_signals+=1)
	check(home.economy_state.points==0 and home.economy_state.carry_level==1 and home.economy_state.equipped_type=="worker","Baseline is Worker Lv1 with zero points")
	check(home.shop.content.get_node("BuyButton_swift").disabled and home.shop.content.get_node("TrainingButton").disabled,"Zero points locks both real purchase Buttons")
	check(home.shop.content.get_node("Price_swift").text=="500" and home.shop.content.get_node("TrainingPrice").text=="100","Existing initial prices stay 500 and 100")
	snapshot("zero_balance")
	# Fund only this throwaway profile using the existing first-level settlement
	# service. These receipts are fixtures, not played victories or new rewards.
	var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-01.json"))
	for i in 30:
		var run_id:="shop-fixture-first-level-%d"%i
		check(home.progression.create_run(run_id,config.level_id,config.rewards.fast_seconds,config.rewards.normal_seconds).ok,"First-level fixture run %d created"%i)
		check(home.progression.settle_run(run_id,"won",config.rewards.fast_seconds).ok,"First-level fixture receipt %d saved"%i)
	home.economy_state=home.progression.get_view_state()
	home.shop.set_data(home.economy_state,JSON.parse_string(FileAccess.get_file_as_string("res://data/ant-progression.json")))
	check(home.economy_state.points==1020,"Unchanged first/repeat rewards fund 1020 fixture points")
	check(not home.shop.content.get_node("BuyButton_swift").disabled,"Swift becomes purchasable")
	snapshot("affordable_swift")
	var old_swift:=press("BuyButton_swift")
	check(purchase_signals==1 and home.economy_state.points==520 and home.economy_state.owned_types.has("swift"),"One Button signal buys Swift once for 500")
	old_swift.pressed.emit()
	check(purchase_signals==2 and home.economy_state.points==520,"Repeated stale Swift signal cannot debit twice")
	check(home.shop.content.has_node("EquipButton_swift") and not home.shop.content.has_node("BuyButton_swift"),"Owned Swift replaces purchase with real equip Button")
	press("EquipButton_swift")
	check(home.economy_state.equipped_type=="swift" and home.shop.content.get_node("EquipButton_swift").disabled,"Equipped Swift has disabled selected Button")
	var before:Dictionary=home.progression._record.duplicate(true)
	home.progression.test_fail_stage="write_temp"
	press("TrainingButton")
	check(home.economy_state.points==520 and home.economy_state.carry_level==1,"Failed write keeps original balance and level")
	check(home.progression._record==before,"Failed write keeps original ledger")
	check(not home.shop.content.get_node("ShopFeedback").text.is_empty(),"Failed purchase surfaces actual save error")
	check(not home.shop.content.get_node("TrainingButton").disabled,"Failed purchase remains retryable")
	home.progression.test_fail_stage=""
	var old_training:=press("TrainingButton")
	check(home.economy_state.points==420 and home.economy_state.carry_level==2,"Retry buys only Lv2 at 100")
	old_training.pressed.emit()
	check(home.economy_state.points==420 and home.economy_state.carry_level==2,"Repeated stale training signal cannot buy or debit next level")
	check(home.shop.content.get_node("TrainingPrice").text=="150","Next real training price is 150")
	snapshot("swift_level_2")
	press("TrainingButton")
	check(home.economy_state.points==270 and home.economy_state.carry_level==3,"Lv3 costs 150")
	check(home.shop.content.get_node("TrainingPrice").text=="250","Last real training price is 250")
	press("TrainingButton")
	check(home.economy_state.points==20 and home.economy_state.carry_level==4,"Lv4 costs 250")
	check(home.shop.content.get_node("NextLevel").text=="LV.4  MAX" and home.shop.content.get_node("TrainingButton").disabled,"Max level remains a disabled actual Button")
	check(home.shop.content.get_node("TrainingButton").tooltip_text=="Maximum training level","Max-level hint does not invent a next purchase")
	check(not home.shop.content.has_node("TrainingPrice"),"Max level shows no fake next price")
	check(home.shop.content.get_node("Speed_swift").text=="+38%" and home.shop.content.get_node("Speed_worker").text=="+15%","Type cards display effective shared-level speed, not just base type bonus")
	check(is_equal_approx(home.economy_state.loadout.speed_multiplier,1.38),"Actual Swift Lv4 loadout remains x1.38")
	snapshot("swift_level_4_max")
	press("EquipButton_worker")
	check(is_equal_approx(home.economy_state.loadout.speed_multiplier,1.15),"Same training applies to Worker at x1.15")
	home.shop.set_busy(true)
	check(home.shop.content.get_node("EquipButton_swift").disabled and home.shop.content.get_node("TrainingButton").disabled,"Busy state disables action Buttons")
	home.shop.set_busy(false)
	var reloaded:=Progression.new(home.profile_directory)
	check(reloaded.load_save().ok,"Final isolated ledger reloads")
	var state:=reloaded.get_view_state()
	check(state.points==20 and state.carry_level==4 and state.equipped_type=="worker" and state.owned_types.has("swift"),"Reload preserves debits, shared level, ownership and equipment")
	check(reloaded._record.purchases.size()==4,"Exactly four paid products are committed")
	check(reloaded._record.completed_levels.keys()==["serpent-01"],"No other level fixture or unlock was tested")
	home.close_shop();check(home.phase=="preparation" and home.adventure.selected_level==1,"Back returns to first-level preparation")
	var report:Dictionary={"pass":failures.is_empty(),"checks":checks,"failures":failures,"scope":"First-level-only /tmp base profile, production Shop callbacks, fixture receipts through existing progression service, exact game/primary and game/secondary atlas-region assertions, transparent event layers, visible border-only focus, geometry/font/price bounds, duplicate signals, write failure/retry and reload. No gameplay victories, native touch, GL, audio, visual acceptance or later-level testing.","phone_scale":360.0/940.0,"primary_font":38,"secondary_font":32,"action_height":120,"back_rect":[28,45,120,120],"back_title_gap":32,"snapshots":snapshots}
	var output:=FileAccess.open("res://reports/first-level/shop-mobile-controls.json",FileAccess.WRITE);output.store_string(JSON.stringify(report,"\t")+"\n");output.close()
	home.audio_service.stop_music();home.audio_service.stop_all_sfx();await create_timer(.2).timeout
	home.queue_free();await process_frame;await process_frame
	print("ANT_SHOP_MOBILE_CONTROLS ",JSON.stringify({"pass":report.pass,"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
