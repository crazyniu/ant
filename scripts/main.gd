extends Control
## Formal visual gallery and shared components. Play.gd supplies authoritative gameplay.
const Bead = preload("res://scripts/bead.gd")
const BoardPlane = preload("res://scripts/board_plane.gd")
const ContactShadow = preload("res://scripts/contact_shadow.gd")
const Icon = preload("res://scripts/ui_icon.gd")
const AudioService = preload("res://scripts/audio_service.gd")
var audio_service: Node
const UiSkin = preload("res://scripts/ui_skin.gd")
const UiMotion = preload("res://scripts/ui_motion.gd")
var ui_motion: Node
var skin: RescueSkin
const INK := Color("682b0c")
const COLORS := ["red","blue","yellow","green","purple","white"]
var font: Font
var atlas: Texture2D
var ant_atlas: Texture2D
var bead_nodes: Array[Control] = []
var slots: Array[Control] = []
var candidate_columns: Array[Control] = []
var counts := {"red":0,"blue":0,"yellow":0,"green":0,"purple":0,"white":0}
var fixture: Dictionary = {}
var pause_overlay: Control
var modal_title := ""
var queue_transition_busy := false
var slot_teams: Array = []
var frame_cache: Dictionary = {}
var ui_animations: Array[Tween] = []
var audio_visual_state := {"music":70.0,"sound":70.0,"music_muted":false,"sound_muted":false}

func _ready() -> void:
	var canvas_scale:=minf(1440.0/940.0,2560.0/1672.0)
	size=Vector2(940,1672);scale=Vector2(canvas_scale,canvas_scale);position=(Vector2(1440,2560)-size*scale)*.5
	audio_service=AudioService.new();audio_service.name="AudioService";audio_service.apply_settings_state(audio_visual_state);add_child(audio_service)
	get_tree().node_added.connect(bind_new_button)
	font=load("res://assets/fonts/Title.ttf")
	skin=UiSkin.new()
	theme=Theme.new()
	for state in ["normal","hover","pressed","disabled","focus"]:theme.set_stylebox(state,"Button",StyleBoxEmpty.new())
	atlas=load("res://assets/characters-atlas.png")
	if ResourceLoader.exists("res://assets/ants-atlas.png"): ant_atlas=load("res://assets/ants-atlas.png")
	build_environment()
	build_mosaic()
	create_fixture()
	build_threat()
	build_transport()
	build_hud()
	build_slots()
	build_candidates()
	build_tools()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):show_screen(arg.trim_prefix("--screen="))
	if "--capture-ui" in OS.get_cmdline_user_args(): capture_ui()

func ensure_ui_motion() -> void:
	if is_instance_valid(ui_motion):return
	ui_motion=UiMotion.new();ui_motion.name="UIMotion";add_child(ui_motion)

func bind_new_button(node: Node) -> void:
	if node is Button and is_ancestor_of(node):
		if not node.pressed.is_connected(audio_service.play_ui_click):node.pressed.connect(audio_service.play_ui_click)
		ensure_ui_motion();ui_motion.bind_button(node)

func title_art(title: String, bounds: Rect2, parent: Node) -> TextureRect:
	var aliases:Dictionary={"CHOOSE A LEVEL":"LEVELS","PRINCESS SAVED!":"SAVED!","RESTART LEVEL?":"RESTART?","LEAVE THIS LEVEL?":"LEAVE?","RECALL A TEAM":"RECALL","NO MATCH YET":"NO MATCH","COULDN'T LOAD":"LOAD ERROR","COULDN'T SAVE":"SAVE ERROR","YOUR FIRST RESCUE":"HOW TO PLAY"}
	var key:String=aliases.get(title,title)
	var t:=skin.sprite("titles/"+key,bounds,parent,"TitleArt")
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t

func group(id: String, parent: Node = self) -> Control:
	var g:=Control.new();g.name=id;g.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(g);return g

func art(source: Rect2, target: Rect2, id: String, parent: Node = self, from: Texture2D = null) -> TextureRect:
	var at:=AtlasTexture.new();at.atlas=atlas if from==null else from;at.region=source;at.filter_clip=true
	var t:=TextureRect.new();t.name=id;t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;t.texture=at;t.position=target.position;t.size=target.size
	t.stretch_mode=TextureRect.STRETCH_SCALE
	t.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(t);return t

func frame(rect: Rect2, id: String, parent: Node = self, radius: int = 25, top: String = "fff3db", _bottom: String = "eed1a5", _border: String = "c49150") -> Panel:
	var key:="game/row"
	var corner:=minf(float(radius),rect.size.y*.28)
	if id=="ModalPanel":key="settings/panel";corner=58
	elif top in ["54d35b","39cb4d","68d663"]:key="settings/primary";corner=rect.size.y*.40
	elif id in ["Level","ArmorCard","PauseFrame"]:key="game/panel";corner=8
	elif "Tray" in id:key="game/panel";corner=18
	elif id.begins_with("Slot") or id.begins_with("ToolPlate") or id in ["FrontCard","ColumnPlate"]:corner=10
	return skin.panel(key,rect,parent,id,corner)

func text_label(value: String, rect: Rect2, px: int, id: String, parent: Node = self, color: Color = INK, outline: bool = false) -> Label:
	var l:=Label.new();l.name=id;l.text=value;l.position=rect.position;l.size=rect.size
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font",font);l.add_theme_font_size_override("font_size",px)
	l.add_theme_color_override("font_color",color)
	if outline:
		l.add_theme_color_override("font_outline_color",Color("fff9e8"));l.add_theme_constant_override("outline_size",3)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(l);return l

func icon(kind: String, rect: Rect2, parent: Node, color: Color=Color("fff9e8")) -> Control:
	var i:=Icon.new();i.kind=kind;i.position=rect.position;i.size=rect.size;i.ink=color;parent.add_child(i);return i

func bead(id: String, pos: Vector2, edge: float, parent: Node = self) -> Control:
	var b:=Bead.new();b.color_id=id;b.edge=edge;b.position=pos;b.size=Vector2(edge,edge+3);parent.add_child(b);return b

func ground_ant(color_id:String,foot:Vector2,id:String,parent:Node=self,diameter:float=45.0)->Control:
	var actor:=group(id,parent);actor.position=foot
	var shadow:=ContactShadow.new();shadow.name="FootShadow";shadow.radius=Vector2(diameter*.37,diameter*.12);shadow.position=Vector2(0,0);actor.add_child(shadow)
	var sprite:=ant(color_id,Rect2(-diameter*.5,-diameter*.84,diameter,diameter*.86),"Ant",actor)
	sprite.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return actor

func place_board_bead(color_id:String,x:int,y:int,plane:RefCounted,parent:Node)->Control:
	var span:Vector2=plane.footprint(x,y)*.98;var center:Vector2=plane.center(x,y)
	var b:=Bead.new();b.color_id=color_id;b.edge=span.x;b.footprint_height=span.y*1.07;b.position=center-Vector2(span.x*.5,span.y*.57);b.size=Vector2(span.x,span.y*1.07);parent.add_child(b);return b

func build_environment() -> void:
	if ResourceLoader.exists("res://assets/environment.png"):
		var bg:=TextureRect.new();bg.name="Environment";bg.texture=load("res://assets/environment.png")
		bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.size=Vector2(940,1672);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(bg)
	# The clean environment is decorative only; every bead and actor is an independent node.
	var tray:=group("BoardTrayBounds");tray.position=Vector2(72,297);tray.size=Vector2(796,690)

func castle_color(x: int,y: int) -> String:
	var color_id: String="blue"
	# A new castle mosaic, not a crop of the reference illustration.
	if ((x-4)*(x-4)*.4+(y-4)*(y-4)<7) or ((x-7)*(x-7)*.7+(y-4)*(y-4)<4) or ((x-30)*(x-30)*.45+(y-4)*(y-4)<8): color_id="white"
	if y>=23: color_id="green"
	if y>=17 and y<=24 and (x<4 or x>30): color_id="green"
	if y>=19 and y<=22 and ((x>=3 and x<=10) or (x>=25 and x<=31)): color_id="purple"
	# Central keep, layered roof, and golden doorway.
	if x>=12 and x<=22 and y>=16 and y<=28: color_id="yellow"
	if x>=16 and x<=18 and y>=22 and y<=28: color_id="blue"
	if y>=9 and y<=18 and x>=15 and x<=19: color_id="white"
	if y>=7 and y<=10 and abs(x-17)<=y-7+1: color_id="red"
	if y>=3 and y<=7 and x==17: color_id="red"
	if y>=3 and y<=5 and x>=18 and x<=21-(y-3): color_id="purple"
	# Two lower towers and two upper spires.
	for cx in [6,28]:
		if abs(x-cx)<=2 and y>=16 and y<=24: color_id="yellow"
		if abs(x-cx)<=1 and y>=19 and y<=20: color_id="white"
		if y>=13 and y<=16 and abs(x-cx)<=y-13: color_id="red"
		if y==12 and x==cx: color_id="yellow"
	for cx in [11,23]:
		if abs(x-cx)<=1 and y>=11 and y<=17:color_id="blue"
		if y>=9 and y<=11 and abs(x-cx)<=y-9: color_id="purple"
		if y==8 and x==cx:color_id="yellow"
	if y>=20 and y<=24 and ((x>=10 and x<=12) or (x>=22 and x<=24)): color_id="purple"
	if y==17 and x>=10 and x<=24 and x%3!=0:color_id="red"
	# Foreground leaves and flowers give the silhouette natural edges.
	if y>=26 and (x<12 or x>22): color_id="green"
	if y==25 and x%5==1:color_id="yellow"
	if y==27 and (x==8 or x==26):color_id="red"
	return color_id

func build_mosaic() -> void:
	var board:=group("Mosaic")
	var plane:=BoardPlane.new(35,31)
	for y in range(31):
		for x in range(35):
			var skip: bool=(y==0 and (x<2 or x>32)) or (y>26 and (x<y-24 or x>58-y)) or (y==30 and x>=13 and x<=21) or (y in [5,6,12,13] and (x==0 or x==34)) or (y in [8,9,17] and x==34) or (y in [10,11,18] and x==0)
			if skip:continue
			var id:=castle_color(x,y);counts[id]+=1
			var b:=place_board_bead(id,x,y,plane,board)
			b.name="Bead_%02d_%02d" % [x,y];b.set_meta("cell",Vector2i(x,y));bead_nodes.append(b)

func create_fixture() -> void:
	# This is a coherent visual state, not a playable level or approved balance.
	# Inventory already arrived, while all remaining board beads are unreserved.
	var stock: Dictionary={"red":18,"blue":6,"yellow":4,"green":0,"purple":0,"white":0}
	var active: Dictionary={"red":22,"blue":18,"yellow":32,"green":0,"purple":0,"white":0}
	var carrying:Dictionary={"red":8,"blue":1,"yellow":3,"green":2,"purple":1,"white":0}
	var initial:=counts.duplicate();var queue_totals:=counts.duplicate()
	for id in COLORS:
		initial[id]+=stock[id]+carrying[id];queue_totals[id]-=active[id]
	var queues: Array = [[],[],[],[],[]]
	for i in range(6):
		var id:String=COLORS[i];var left:int=queue_totals[id];var index:int=i if i<5 else 4
		while left>0:
			var n:=20 if id=="red" and queues[index].is_empty() else mini(40,left)
			queues[index].append({"color":id,"quota":n,"id":"%s_%d"%[id,queues[index].size()]});left-=n
	if queues[4].size()>3 and queues[4][-1].color=="white":
		var white:Dictionary=queues[4].pop_back();queues[4].insert(2,white)
	slot_teams=[{"color":"red","quota":22,"id":"active_red"},{"color":"blue","quota":18,"id":"active_blue"},{"color":"yellow","quota":32,"id":"active_yellow"},null,null]
	fixture={"board":counts.duplicate(),"stock":stock,"carrying":carrying,"active":active,"queue_totals":queue_totals,"initial":initial,"armor_total":initial.duplicate(),"current_armor":{"color":"red","need":20},"next_colors":["blue","yellow"],"visual_only":true,"queues":queues}

func build_threat() -> void:
	var stage:=group("DragonRoute")
	var markers:=group("RouteMarkers",stage)
	# Route dots convey direction without a second health bar.
	for x in range(440,799,23):
		var dot:=Panel.new();dot.position=Vector2(x,252+sin(x*.016)*7);dot.size=Vector2(14,6)
		var s:=StyleBoxFlat.new();s.bg_color=Color("ed7638") if x<660 else Color("f14532");s.set_corner_radius_all(4);s.set_border_width_all(1);s.border_color=Color("ffefbf");dot.add_theme_stylebox_override("panel",s);markers.add_child(dot)
	for x in [513,602]:icon("arrow",Rect2(x,236,39,35),markers,Color("ed7b34"))
	var dragon:=art(Rect2(22,145,714,480),Rect2(103,79,394,203),"Dragon",stage)
	dragon.pivot_offset=Vector2(220,193)
	art(Rect2(740,20,324,624),Rect2(784,8,146,282),"PrincessTower",stage)

func ant(color_id: String, rect: Rect2, id: String, parent: Node = self, opacity: float = 1.0) -> Control:
	if ant_atlas!=null:
		var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/ant-regions.json"))
		var a:Array=manifest[color_id]
		var t:=art(Rect2(a[0],a[1],a[2],a[3]),rect,id,parent,ant_atlas);t.modulate.a=opacity;return t
	# Missing art is never presented to the user. Structural preflight still runs.
	var holder:=group(id,parent);holder.position=rect.position;holder.size=rect.size;return holder

func build_transport() -> void:
	var layer:=group("TransportScene")
	var plane:=BoardPlane.new(35,31)
	var samples:Array[Vector2]=[Vector2(-1,5),Vector2(-1,12),Vector2(-1,20),Vector2(2,30),Vector2(35,6),Vector2(35,15),Vector2(35,24)]
	for i in samples.size():
		var sample:Vector2=samples[i];var col:String=COLORS[i%6]
		var actor:=ground_ant(col,plane.center(sample.x,sample.y),"Carrier%02d"%i,layer,36*plane.depth_scale(sample.y))
		bead(col,Vector2(-7,-37),17,actor)
	art(Rect2(481,678,480,307),Rect2(350,1000,231,149),"Nest",layer)
	art(Rect2(48,654,412,337),Rect2(385,876,173,148),"Cannon",layer)
	ground_ant("red",Vector2(467,1143),"NestArrival",layer,42)
	frame(Rect2(414,985,116,48),"CurrentAmmo",layer,12)
	bead("red",Vector2(392,995),24,layer)
	text_label("18 / 20",Rect2(418,988,108,40),26,"AmmoCount",layer,Color("a52b1c"))
	var stock:=group("Stock",layer)
	for j in range(1,6):
		var x:=550+(j-1)*72
		bead(COLORS[j],Vector2(x+21,952),29,stock)
		var count:=text_label(str(fixture.stock[COLORS[j]]),Rect2(x+1,984,67,34),25,"Count",stock,Color("fff7d9"))
		count.add_theme_color_override("font_outline_color",Color("573719"));count.add_theme_constant_override("outline_size",5)

func build_hud() -> void:
	var hud:=group("TopHUD")
	frame(Rect2(24,18,73,66),"PauseFrame",hud,22)
	icon("pause",Rect2(33,28,55,43),hud,INK)
	var pause:=Button.new();pause.name="PauseButton";pause.position=Vector2(24,18);pause.size=Vector2(73,66);pause.flat=true;pause.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;pause.pressed.connect(show_pause);hud.add_child(pause)
	frame(Rect2(118,18,115,51),"Level",hud,20)
	text_label("01",Rect2(125,20,100,44),29,"LevelNumber",hud,INK,true)
	art(Rect2(973,741,179,202),Rect2(441,10,87,87),"CurrentArmorShield",hud)
	var first_link:=icon("arrow",Rect2(556,35,30,37),hud,Color("a26825"));first_link.name="ArmorLink1"
	art(Rect2(1168,740,159,201),Rect2(610,27,58,64),"NextArmorBlue",hud)
	var second_link:=icon("arrow",Rect2(692,42,25,30),hud,Color("a26825"));second_link.name="ArmorLink2"
	art(Rect2(1337,741,167,202),Rect2(743,27,58,64),"NextArmorYellow",hud)

func build_slots() -> void:
	var work:=group("WorkSlots")
	for i in range(5):
		var x:=67+i*162
		var p:=frame(Rect2(x,1173,154,126),"Slot%d"%(i+1),work,16,"fffaf1","f1e1c9","caa777");slots.append(p)
		if slot_teams[i]!=null:
			var team:Dictionary=slot_teams[i]
			ant(team.color,Rect2(x+23,1179,107,73),"Worker%d"%i,work)
			text_label(str(team.quota),Rect2(x+16,1250,122,43),36,"Quota%d"%i,work,Color("b9251f") if team.color=="red" else Color("174184") if team.color=="blue" else INK,true)

func build_candidates() -> void:
	var queue:=group("CandidateQueues")
	for i in range(5):
		var x:=70+i*164;var g:=group("Column%d"%(i+1),queue);candidate_columns.append(g)
		for row in range(mini(3,fixture.queues[i].size())):
			var entry:Dictionary=fixture.queues[i][row]
			var col:String=entry.color
			var y:=1325+row*57
			if row==0:frame(Rect2(x+3,y,146,55),"FrontCard",g,12)
			var alpha:=1.0 if row==0 else .70 if row==1 else .55
			ant(col,Rect2(x+14,y+2,66,47),"Ant%d"%row,g,alpha)
			var l:=text_label(str(entry.quota),Rect2(x+83,y+5,60,42),28,"Quota%d"%row,g,Color("b5221c") if col=="red" else Color("1b4b83") if col=="blue" else INK,true);l.modulate.a=alpha
			if row==0:
				var b:=Button.new();b.name="FrontButton";b.flat=true;b.position=Vector2(x+3,y);b.size=Vector2(146,55);b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;b.tooltip_text="%s · %d"%[col.to_upper(),entry.quota];g.add_child(b)
				var team_id:String=entry.id
				b.pressed.connect(func():preview_select_front(i,team_id))

func preview_select_front(column: int, expected_id: String) -> bool:
	# UI-only selection contract; the P2 simulation owns dispatch after integration.
	if queue_transition_busy or is_instance_valid(pause_overlay):return false
	if column<0 or column>=fixture.queues.size() or fixture.queues[column].is_empty():return false
	if fixture.queues[column][0].id!=expected_id:return false
	var empty:=slot_teams.find(null)
	if empty<0:return false
	var selected:Dictionary=fixture.queues[column].pop_front()
	slot_teams[empty]=selected
	fixture.active[selected.color]+=selected.quota
	fixture.queue_totals[selected.color]-=selected.quota
	queue_transition_busy=true
	for path in ["WorkSlots","CandidateQueues"]:
		var old:=get_node(path);remove_child(old);old.queue_free()
	slots.clear();candidate_columns.clear();build_slots();build_candidates()
	get_tree().create_timer(.18).timeout.connect(func():queue_transition_busy=false)
	return true

func build_tools() -> void:
	var tools:=group("ToolTray")
	var kinds: Array[String]=["plus","shuffle","recall","hint"]
	var labels: Array[String]=["EXTRA SLOT","SHUFFLE","RECALL","HINT"]
	for i in range(4):
		var x:=139+i*179
		var painted:=skin.sprite("game/"+kinds[i],Rect2(x,1507,125,125),tools,"PaintedTool%d"%i)
		# One physical enamel icon per skill. No outer tray, repeated frames or labels.
		painted.pivot_offset=painted.size*.5
		frame(Rect2(x+94,1604,33,31),"UseBadge%d"%i,tools,9)
		text_label("1",Rect2(x+94,1603,33,28),19,"Uses%d"%i,tools)
		var b:=Button.new();b.name="ToolButton%d"%i;b.flat=true;b.position=Vector2(x,1507);b.size=Vector2(132,132);b.tooltip_text=labels[i];b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;tools.add_child(b)
		b.pressed.connect(func():show_tool_detail(labels[i],kinds[i]))

func pulse(target: Control, point: Vector2) -> void:
	var spark:=ColorRect.new();spark.mouse_filter=Control.MOUSE_FILTER_IGNORE;spark.color=Color(1,1,.75,.32);spark.position=point-Vector2(60,24);spark.size=Vector2(120,48);target.add_child(spark)
	var tween:=create_tween();tween.tween_property(spark,"modulate:a",0.0,.22);tween.tween_callback(spark.queue_free)

func dismiss_modal() -> void:
	audio_service.set_music_preview(false)
	audio_service.set_game_paused(false)
	modal_title=""
	dismiss_modal_visual()
	reset_presentation()

func dismiss_modal_visual() -> void:
	# Clear logical modal ownership immediately; the old page is inert artwork.
	var closing:=pause_overlay
	pause_overlay=null
	if is_instance_valid(closing):
		ensure_ui_motion();ui_motion.close_modal(closing)

func reset_presentation() -> void:
	for path in ["Mosaic","CandidateQueues","WorkSlots","TransportScene","DragonRoute/RouteMarkers","DragonRoute/Dragon","TopHUD/CurrentArmorShield","TopHUD/NextArmorBlue","TopHUD/NextArmorYellow"]:
		get_node(path).show()
	for child in get_node("TopHUD").get_children():
		if child is RescueIcon:child.show()
	for child in get_node("WorkSlots").get_children():child.show()
	for child in get_node("TransportScene").get_children():child.show()
	get_node("TransportScene/AmmoCount").text="18 / 20"
	var index:=1
	for child in get_node("TransportScene/Stock").get_children():
		if child is Label:
			child.text=str(fixture.stock[COLORS[index]]);index+=1

func apply_rescue_presentation() -> void:
	# A terminal UI specimen, not an assertion that the rule simulation ran.
	# Do not show a full board, active carriers or live armor behind a victory.
	for path in ["Mosaic","CandidateQueues","DragonRoute/RouteMarkers","DragonRoute/Dragon","TopHUD/CurrentArmorShield","TopHUD/NextArmorBlue","TopHUD/NextArmorYellow"]:
		get_node(path).hide()
	for child in get_node("TopHUD").get_children():
		if child is RescueIcon and child.kind=="arrow":child.hide()
	for child in get_node("WorkSlots").get_children():
		if child is TextureRect or child is Label:child.hide()
	for child in get_node("TransportScene").get_children():
		if child is RescueBead or "Carrier" in child.name or child.name=="NestArrival":child.hide()
	get_node("TransportScene/AmmoCount").text="0 / 0"
	for child in get_node("TransportScene/Stock").get_children():
		if child is Label:child.text="0"

func modal(title: String, rect: Rect2 = Rect2(170,520,600,620)) -> Control:
	reset_presentation()
	audio_service.set_music_preview(false)
	audio_service.set_game_paused(true)
	modal_title=title
	ensure_ui_motion()
	if is_instance_valid(pause_overlay):ui_motion.discard_modal(pause_overlay)
	pause_overlay=Control.new();pause_overlay.name="Modal";pause_overlay.size=Vector2(940,1672);pause_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(pause_overlay)
	ui_motion.prepare_modal(pause_overlay,rect.get_center())
	var shade:=ColorRect.new();shade.name="ModalShade";shade.color=Color(0.11,.07,.03,.55);shade.size=Vector2(940,1672);pause_overlay.add_child(shade)
	frame(rect,"ModalPanel",pause_overlay,45,"fff5de","e8c394")
	var title_width:=minf(rect.size.x-70,530)
	skin.sprite("settings/title",Rect2(470-title_width/2,rect.position.y-47,title_width,145),pause_overlay,"WoodTitlePlaque")
	title_art(title,Rect2(470-title_width/2+44,rect.position.y-5,title_width-88,65),pause_overlay)
	skin.sprite("settings/close",Rect2(rect.end.x-48,rect.position.y-21,63,63),pause_overlay,"PaintedClose")
	var close:=Button.new();close.name="CloseButton";close.flat=true;close.position=Vector2(rect.end.x-48,rect.position.y-21);close.size=Vector2(63,63);pause_overlay.add_child(close);close.pressed.connect(close_current_modal)
	return pause_overlay

func close_button(parent: Control, title: String, at_y: float) -> void:
	frame(Rect2(294,at_y,352,76),"ActionFrame",parent,24,"54d35b","27a33e","258338")
	text_label(title,Rect2(302,at_y+5,336,59),28,"ActionLabel",parent,Color.WHITE)
	var b:=Button.new();b.flat=true;b.position=Vector2(294,at_y);b.size=Vector2(352,76);parent.add_child(b)
	b.pressed.connect(dismiss_modal)

func action(parent: Control, title: String, at_y: float, callback: Callable, primary: bool = false) -> void:
	frame(Rect2(274,at_y,392,76),"Action_"+title,parent,24,"54d35b" if primary else "fff4de","27a33e" if primary else "edc995","258338" if primary else "c7985e")
	text_label(title,Rect2(282,at_y+5,376,59),27,"Text_"+title,parent,Color.WHITE if primary else INK)
	var b:=Button.new();b.name="Button_"+title;b.flat=true;b.position=Vector2(274,at_y);b.size=Vector2(392,76);parent.add_child(b);b.pressed.connect(callback)

func show_screen(which: String) -> void:
	match which:
		"pause": show_pause()
		"settings": show_settings()
		"levels": show_levels()
		"victory": show_outcome(true)
		"defeat": show_outcome(false)
		"restart": show_restart()
		"leave": show_leave()
		"save-error": show_save_error()
		"tutorial": show_tutorial()
		"recall": show_recall_selection()
		"blocked": show_blocked()
		"error": show_error()

func show_pause() -> void:
	var m:=modal("PAUSED")
	action(m,"CONTINUE",704,dismiss_modal,true)
	action(m,"SETTINGS",801,show_settings)
	action(m,"LEVEL SELECT",898,show_leave)
	action(m,"RESTART",995,func():show_restart())

func show_restart() -> void:
	var m:=modal("RESTART LEVEL?")
	skin.sprite("game/recall",Rect2(402,666,136,136),m,"RecallEmblem")
	text_label("YOUR CURRENT ROUND WILL RESET",Rect2(204,835,532,54),22,"RestartWarning",m)
	action(m,"RESTART",929,dismiss_modal,true)
	action(m,"CANCEL",1025,show_pause)

func show_settings() -> void:
	var m:=modal("SETTINGS",Rect2(143,585,654,440))
	audio_service.set_music_preview(true)
	var audio_icons:Texture2D=load("res://assets/ui/fusion/audio-icons.png")
	var audio_regions:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/fusion/audio-regions.json"))
	for i in range(2):
		var key:String="music" if i==0 else "sound"
		var y:=714+i*133
		var region:Array=audio_regions[key]
		var emblem:=art(Rect2(region[0],region[1],region[2],region[3]),Rect2(225,y-12,82,82),"AudioEmblem%d"%i,m,audio_icons)
		emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		skin.sprite("settings/track",Rect2(349,y,349,57),m,"SliderTrack%d"%i)
		var fill_clip:=Control.new();fill_clip.name="ProgressClip%d"%i;fill_clip.position=Vector2(369,y+15);fill_clip.size=Vector2(306*audio_visual_state[key]/100.0,27);fill_clip.clip_contents=true;fill_clip.mouse_filter=Control.MOUSE_FILTER_IGNORE;m.add_child(fill_clip)
		skin.sprite("settings/fill",Rect2(0,0,306,27),fill_clip,"AmberFill")
		var knob:=skin.sprite("settings/knob",Rect2(346+audio_visual_state[key]*3.06,y+3,49,49),m,"PearlKnob%d"%i)
		var slider:=HSlider.new();slider.name="MusicVolume" if i==0 else "SoundVolume";slider.position=Vector2(346,y);slider.size=Vector2(355,57);slider.value=audio_visual_state[key];slider.tooltip_text="Music volume · 0 = mute" if i==0 else "Sound volume · 0 = mute";m.add_child(slider)
		var blank:=texture_from_svg('<svg xmlns="http://www.w3.org/2000/svg" width="49" height="49"/>')
		for state in ["slider","grabber_area","grabber_area_highlight","focus"]:slider.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		for state in ["grabber","grabber_highlight","grabber_disabled"]:slider.add_theme_icon_override(state,blank)
		if key=="sound":slider.drag_ended.connect(func(changed):
			if changed:audio_service.play_ui_click())
		slider.value_changed.connect(func(value):audio_visual_state[key]=value;audio_visual_state[key+"_muted"]=value==0;fill_clip.size.x=306*value/100.0;knob.position.x=346+value*3.06;audio_service.apply_settings_state(audio_visual_state))

func close_current_modal() -> void:
	if modal_title in ["SETTINGS","RESTART LEVEL?","LEAVE THIS LEVEL?","CHOOSE A LEVEL"]:show_pause()
	else:dismiss_modal()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(pause_overlay):close_current_modal()
		else:show_pause()
		get_viewport().set_input_as_handled()

func texture_from_svg(svg: String) -> Texture2D:
	var im:=Image.new();im.load_svg_from_string(svg);return ImageTexture.create_from_image(im)

func simple_style(fill: Color, radius: int) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=fill;s.set_corner_radius_all(radius);s.content_margin_top=8;s.content_margin_bottom=8;return s

func show_levels() -> void:
	var m:=modal("CHOOSE A LEVEL",Rect2(149,392,642,898))
	for i in range(30):
		var x:=196+(i%5)*113;var y:=556+(i/5)*96
		var unlocked:bool=i==0
		frame(Rect2(x,y,98,83),"LevelTile%02d"%(i+1),m,23,"68d663" if unlocked else "f8e4c5","37ac40" if unlocked else "e0bc8a","b48c55")
		text_label(str(i+1),Rect2(x+4,y+7,90,47),30,"LevelNumber%02d"%(i+1),m,Color.WHITE if unlocked else Color("aa8359"))
		if not unlocked:icon("lock",Rect2(x+35,y+47,28,28),m,Color("b18d66"))
		var b:=Button.new();b.name="LevelButton%02d"%(i+1);b.flat=true;b.disabled=not unlocked;b.position=Vector2(x,y);b.size=Vector2(98,83);m.add_child(b)
		if unlocked:b.pressed.connect(dismiss_modal)

func show_outcome(won: bool) -> void:
	var m:=modal("PRINCESS SAVED!" if won else "TRY AGAIN",Rect2(143,432,654,838))
	if won:
		apply_rescue_presentation()
		art(Rect2(740,20,324,624),Rect2(403,640,134,258),"RescuedPrincess",m)
		text_label("THE FINAL HIT BROKE ALL ARMOR",Rect2(184,921,572,50),23,"OutcomeReason",m)
		action(m,"PLAY AGAIN",1008,dismiss_modal,true)
	else:
		art(Rect2(22,145,714,480),Rect2(267,615,405,258),"ThreatDragon",m)
		text_label("THE DRAGON REACHED THE TOWER",Rect2(179,916,582,50),22,"OutcomeReason",m)
		action(m,"RETRY",1008,dismiss_modal,true)
	action(m,"LEVEL SELECT",1110,show_levels)

func show_tool_detail(title: String, kind: String) -> void:
	var m:=modal(title);skin.sprite("game/"+kind,Rect2(402,655,136,136),m,"ToolEmblem")
	var copy: Dictionary={"plus":"ONE MORE WORK SLOT","shuffle":"REORDER WAITING TEAMS","recall":"RETURN AN ACTIVE TEAM","hint":"REVEAL A HELPFUL CHOICE"}
	text_label(copy[kind],Rect2(207,831,526,66),24,"ToolDescription",m)
	text_label("ONCE PER LEVEL",Rect2(237,898,466,47),20,"Allowance",m,Color("a47b4c"))
	if kind=="recall":
		action(m,"CHOOSE A TEAM",967,show_recall_selection,true)
		action(m,"CANCEL",1055,dismiss_modal)
	else:close_button(m,"BACK",997)

func show_recall_selection() -> void:
	var m:=modal("RECALL A TEAM")
	text_label("ONLY THE UNSENT QUOTA RETURNS",Rect2(209,640,522,52),22,"RecallContract",m)
	for i in range(3):
		var x:=228+i*170
		frame(Rect2(x,742,143,147),"RecallTeam%d"%i,m,26,"fff9eb","f0d2a7")
		ant(COLORS[i],Rect2(x+22,754,100,76),"RecallAnt%d"%i,m)
		text_label(str(fixture.active[COLORS[i]]),Rect2(x+8,831,127,44),32,"RecallQuota%d"%i,m)
		var b:=Button.new();b.name="RecallChoice%d"%i;b.flat=true;b.position=Vector2(x,742);b.size=Vector2(143,147);m.add_child(b)
		b.pressed.connect(func():pulse(m,Vector2(x+71,814)))
	text_label("CARRIERS ALREADY OUT WILL KEEP GOING",Rect2(201,919,538,45),19,"CarrierNotice",m,Color("a06d39"))
	action(m,"CANCEL",1010,dismiss_modal)

func show_blocked() -> void:
	var m:=modal("NO MATCH YET")
	ant("blue",Rect2(398,659,144,116),"WaitingAnt",m)
	text_label("NO REACHABLE MATCHING BEADS",Rect2(203,814,534,53),23,"WaitingTitle",m)
	text_label("NO CARRIERS ARE STILL MOVING",Rect2(203,874,534,48),21,"WaitingHelp",m,Color("a06d39"))
	action(m,"BACK TO TOOLS",951,dismiss_modal,true)
	action(m,"RESTART",1042,show_restart)

func show_error() -> void:
	var m:=modal("COULDN'T LOAD")
	skin.sprite("game/recall",Rect2(400,669,140,140),m,"RecoveryEmblem")
	text_label("THIS LEVEL IS UNAVAILABLE",Rect2(205,853,530,52),24,"ErrorTitle",m)
	text_label("PLEASE TRY LOADING IT AGAIN",Rect2(203,911,534,45),21,"RecoveryNotice",m,Color("a06d39"))
	action(m,"TRY AGAIN",951,show_error,true)
	action(m,"LEVEL SELECT",1041,show_levels)

func show_leave() -> void:
	var m:=modal("LEAVE THIS LEVEL?")
	icon("arrow",Rect2(402,666,136,136),m,Color("d08436"))
	text_label("THIS ROUND WILL START OVER",Rect2(204,828,532,54),24,"LeaveWarning",m)
	text_label("COMPLETED LEVELS STAY UNLOCKED",Rect2(204,881,532,48),20,"ProgressNotice",m,Color("a06d39"))
	action(m,"LEVEL SELECT",971,show_levels,true)
	action(m,"CANCEL",1041,show_pause)

func show_save_error() -> void:
	var m:=modal("COULDN'T SAVE")
	skin.sprite("game/recall",Rect2(402,662,136,136),m,"SaveRecoveryEmblem")
	text_label("LEVEL COMPLETE · SAVE PENDING",Rect2(203,823,534,56),23,"SaveStatus",m)
	text_label("THE NEXT LEVEL IS NOT UNLOCKED YET",Rect2(197,886,546,45),19,"UnlockNotice",m,Color("a06d39"))
	action(m,"RETRY SAVE",951,show_save_error,true)
	action(m,"BACK",1041,dismiss_modal)

func show_tutorial() -> void:
	var m:=modal("YOUR FIRST RESCUE",Rect2(149,423,642,860))
	for path in ["CandidateQueues","WorkSlots","TransportScene"]:get_node(path).hide()
	ant("red",Rect2(400,552,140,106),"TutorialAnt",m)
	var steps: Array[String]=["CHOOSE A FRONT-ROW TEAM","ANTS CARRY REACHABLE MATCHING BEADS","DELIVERED BEADS BECOME AMMO","THE CANNON FIRES AUTOMATICALLY","BREAK THE FINAL ARMOR TO RESCUE HER"]
	for i in range(steps.size()):
		icon("arrow",Rect2(211,696+i*65,26,30),m,Color("d09536"))
		text_label(steps[i],Rect2(251,689+i*65,487,46),18,"StepText%d"%i,m)
	text_label("THE DRAGON WAITS FOR YOUR FIRST TEAM",Rect2(190,1037,560,48),20,"ObservationNotice",m,Color("a06d39"))
	action(m,"LET'S GO",1125,dismiss_modal,true)

func evidence_directory() -> String:
	var path:=OS.get_environment("ANT_RESCUE_EVIDENCE_DIR")
	if path.is_empty():path=ProjectSettings.globalize_path("user://evidence")
	DirAccess.make_dir_recursive_absolute(path)
	return path

func save_capture(name: String) -> void:
	await get_tree().create_timer(UiMotion.MODAL_DURATION+.05).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image:=get_viewport().get_texture().get_image()
	image.save_png(evidence_directory()+"/"+name+"-engine.png")
	print("UI_CAPTURE_OK ",name," ",image.get_size())

func capture_ui() -> void:
	await save_capture("main-ui")
	if "--capture-suite" in OS.get_cmdline_user_args():
		for screen in ["pause","settings","levels","victory","defeat","restart","leave","recall","blocked","error","save-error","tutorial"]:
			show_screen(screen)
			await save_capture(screen)
	var report: Dictionary={"beads":bead_nodes.size(),"slots":slots.size(),"candidate_columns":candidate_columns.size(),"fixture":fixture,"viewport":get_viewport().get_visible_rect().size,"window_size":DisplayServer.window_get_size(),"window_mode":DisplayServer.window_get_mode(),"rendering_method":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info().string}
	var f:=FileAccess.open(evidence_directory()+"/ui-structure.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close()
	get_tree().quit()
