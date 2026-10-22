extends "res://scripts/main.gd"
## Full-screen presentation only. All purchases/equipment are committed by the
## progression service before this view receives a new snapshot.
signal back_requested
signal purchase_requested(product_id:String)
signal equip_requested(type_id:String)
const Motion = preload("res://scripts/directional_carrier.gd")
const CapacityBall = preload("res://scripts/first_level_bead.gd")
const SpeedEmblem = preload("res://scripts/adventure_view.gd").Emblem
var economy:Dictionary={}
var products:Dictionary={}
var built:=false
var busy:=false
var feedback:Label
var content:Control

func _ready()->void:
	size=Vector2(940,1672);mouse_filter=Control.MOUSE_FILTER_STOP
	font=load("res://assets/fonts/Title.ttf");skin=UiSkin.new();atlas=load("res://assets/characters-atlas.png");ant_atlas=load("res://assets/ants-atlas.png")
	theme=Theme.new()
	for s in ["normal","hover","pressed","disabled","focus"]:theme.set_stylebox(s,"Button",StyleBoxEmpty.new())
	built=true;rebuild()

func set_data(state:Dictionary,config:Dictionary={}) -> void:
	economy=state.duplicate(true);products=config.duplicate(true)
	if built:rebuild()

func set_busy(value:bool)->void:
	busy=value
	if built:rebuild()

func show_feedback(reason:String)->void:
	if is_instance_valid(feedback):feedback.text=reason.replace("_"," ").to_upper()

func rebuild()->void:
	if is_instance_valid(content):remove_child(content);content.queue_free()
	content=Control.new();content.name="ShopContent";content.size=size;content.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(content)
	var backdrop:=TextureRect.new();backdrop.name="Workshop";backdrop.texture=load("res://assets/meta-ui/shop-workshop-background.png") if ResourceLoader.exists("res://assets/meta-ui/shop-workshop-background.png") else load("res://assets/serpent/environment.png");backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;backdrop.size=size;backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(backdrop)
	icon_action("back",Rect2(28,45,108,108),func():back_requested.emit(),"Back to adventure")
	fixed_title("ANT SHOP",Rect2(180,45,580,120),"ShopTitle")
	frame(Rect2(665,197,230,76),"Balance",content,22)
	coin(Vector2(710,235),28);text_label(str(economy.get("points",0)),Rect2(748,207,129,56),38,"Points",content,INK,true)
	var owned:Array=economy.get("owned_types",["worker"])
	var equipped:String=economy.get("equipped_type","worker")
	build_type_card("worker",Rect2(55,320,405,730),owned.has("worker"),equipped=="worker")
	build_type_card("swift",Rect2(480,320,405,730),owned.has("swift"),equipped=="swift")
	build_training()
	feedback=text_label("",Rect2(95,1534,750,80),32,"ShopFeedback",content,Color("fff0cf"),true)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func build_type_card(kind:String,bounds:Rect2,owned:bool,equipped:bool)->void:
	skin.panel("settings/panel",bounds,content,"Card_"+kind,34)
	fixed_title(kind.to_upper(),Rect2(bounds.position+Vector2(35,27),Vector2(335,88)),"Title_"+kind)
	var foot:=bounds.position+Vector2(202,360)
	var actor:=ground_ant("blue",foot,"Preview_"+kind,content,220)
	Motion.prepare(actor,"blue",220);Motion.apply(actor,{"time":0.,"direction":Vector2(.8,.6),"moving":false,"stage":"idle","diameter":220.,"phase":0.})
	if kind=="swift":
		meta_icon("swift",Rect2(bounds.position+Vector2(323,138),Vector2(60,60)),"SwiftBadge")
	var mult:float=float(economy.get("type_multipliers",{}).get(kind,1.2 if kind=="swift" else 1.))
	# HUD icon scale is independent of the shared first-level WORLD_SIZE.
	text_label("1",Rect2(bounds.position+Vector2(208,408),Vector2(90,65)),38,"Capacity_"+kind,content)
	var b:=CapacityBall.new();b.name="CapacityBall_"+kind;b.color_id="blue";b.edge=52.;b.footprint_height=52.;b.position=bounds.position+Vector2(111,414);b.size=Vector2(52,52);content.add_child(b)
	var effective_mult:=minf(mult*float(economy.get("level_multiplier",1.)),float(products.get("max_speed_multiplier",1.5)))
	var speed:=SpeedEmblem.new();speed.name="SpeedEmblem_"+kind;speed.kind="speed";speed.position=bounds.position+Vector2(111,487);speed.size=Vector2(52,52);speed.ink=Color("c88420");content.add_child(speed)
	text_label("+%d%%"%roundi((effective_mult-1.)*100.),Rect2(bounds.position+Vector2(175,482),Vector2(170,62)),38,"Speed_"+kind,content)
	# The painted action and real Button share the same mobile-sized bounds.
	var action_bounds:=Rect2(bounds.position+Vector2(35,576),Vector2(335,120))
	if owned:
		frame(action_bounds,"Equip_"+kind,content,27,"54d35b" if equipped else "fff3db")
		icon("check" if equipped else "play",Rect2(action_bounds.get_center()-Vector2(32,32),Vector2(64,64)),content,Color.WHITE if equipped else INK)
		button("EquipButton_"+kind,action_bounds,func():equip_requested.emit(kind),equipped or busy,"Equipped" if equipped else "Equip "+kind)
	else:
		var price:int=int(products.get("types",{}).get(kind,{}).get("price",500))
		var affordable:=int(economy.get("points",0))>=price
		frame(action_bounds,"Buy_"+kind,content,27,"54d35b" if affordable else "fff3db")
		coin(action_bounds.position+Vector2(65,60),24)
		text_label(str(price),Rect2(action_bounds.position+Vector2(98,28),Vector2(120,64)),38,"Price_"+kind,content,Color.WHITE if affordable else INK,affordable)
		icon("plus" if affordable else "lock",Rect2(action_bounds.position+Vector2(246,34),Vector2(52,52)),content,Color.WHITE if affordable else INK)
		button("BuyButton_"+kind,action_bounds,func():purchase_requested.emit(kind),busy or not affordable or not economy.get("ready",true),"Unlock "+kind if affordable else "Need %d points"%price)

func build_training()->void:
	var bounds:=Rect2(55,1100,830,410)
	skin.panel("settings/panel",bounds,content,"TrainingPanel",34)
	fixed_title("TRAINING",Rect2(235,1118,470,82),"TrainingTitle")
	var lv:int=int(economy.get("carry_level",1))
	var multiplier:float=float(economy.get("level_multiplier",1.))
	var next_mult:float=float(products.get("levels",{}).get(str(mini(lv+1,4)),{}).get("speed_multiplier",1.))
	var price:int=int(products.get("levels",{}).get(str(mini(lv+1,4)),{}).get("price",0))
	var actor:=ground_ant("blue",Vector2(205,1394),"TrainingAnt",content,175)
	Motion.prepare(actor,"blue",175);Motion.apply(actor,{"time":0.,"direction":Vector2.RIGHT,"moving":false,"stage":"idle","diameter":175.,"phase":0.})
	text_label("LV.%d"%lv+ ("  >  LV.%d"%(lv+1) if lv<4 else "  MAX"),Rect2(395,1210,410,60),38,"NextLevel",content)
	text_label("+%d%%"%roundi(((next_mult if lv<4 else multiplier)-1.)*100.),Rect2(425,1276,350,60),38,"TrainingEffect",content)
	var b:=Rect2(409,1352,386,120)
	var affordable:=int(economy.get("points",0))>=price
	frame(b,"TrainAction",content,25,"54d35b" if lv<4 and affordable else "fff3db")
	if lv<4:
		coin(b.position+Vector2(72,60),24);text_label(str(price),Rect2(b.position+Vector2(110,29),Vector2(130,62)),38,"TrainingPrice",content,Color.WHITE if affordable else INK,affordable);icon("arrow" if affordable else "lock",Rect2(b.position+Vector2(283,33),Vector2(53,53)),content,Color.WHITE if affordable else INK)
	else:icon("check",Rect2(b.get_center()-Vector2(30,30),Vector2(60,60)),content,INK)
	button("TrainingButton",b,func():purchase_requested.emit("level_%d"%(lv+1)),busy or lv>=4 or not affordable or not economy.get("ready",true),"Maximum training level" if lv>=4 else ("Upgrade all colors" if affordable else "Need %d points"%price))

func fixed_title(title:String,bounds:Rect2,id:String)->void:
	var path:="res://assets/meta-ui/"+title.to_lower().replace(" ","-")+".png"
	if ResourceLoader.exists(path):
		var v:=TextureRect.new();v.name=id;v.texture=load(path);v.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;v.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;v.position=bounds.position;v.size=bounds.size;v.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(v)
	else:text_label(title,bounds,42,id,content,INK,true)

func meta_icon(kind:String,bounds:Rect2,id:String)->void:
	var path:="res://assets/meta-ui/"+("ant-coin" if kind=="coin" else "swift-wing")+".png"
	if ResourceLoader.exists(path):
		var t:=TextureRect.new();t.name=id;t.texture=load(path);t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;t.position=bounds.position;t.size=bounds.size;t.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(t)
	else:icon("arrow",bounds,content,Color("f9c03f"))

func coin(center:Vector2,radius:float)->void:
	meta_icon("coin",Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2.),"Coin")

func icon_action(kind:String,bounds:Rect2,call:Callable,tip:String)->void:
	frame(bounds,"BackArt",content,30)
	var g:=icon("arrow",Rect2(bounds.position+Vector2(23,23),bounds.size-Vector2(46,46)),content,INK);g.rotation=PI;g.pivot_offset=g.size*.5
	button("BackButton",bounds,call,false,tip)

func button(id:String,bounds:Rect2,call:Callable,disabled:bool,tip:String)->void:
	var b:=Button.new();b.name=id;b.position=bounds.position;b.size=bounds.size;b.flat=true;b.disabled=disabled;b.tooltip_text=tip;content.add_child(b);b.pressed.connect(call)
