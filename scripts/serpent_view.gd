extends Control
## Independent movable body pieces on one finite curve. No damage, ammo or victory writes.
const Route = preload("res://scripts/serpent_path.gd")
const Shadow = preload("res://scripts/contact_shadow.gd")
const PALETTE={"red":Color("ed4137"),"blue":Color("329cfa"),"yellow":Color("fbc52c"),"green":Color("68d849"),"purple":Color("a25fe6"),"white":Color("f7efdb")}
const ART_PROFILES={"default":"res://assets/serpent/serpent-atlas.json","ice_crest":"res://assets/serpent/ice-serpent-atlas.json","ruins_carapace":"res://assets/serpent/carapace-serpent-atlas.json"}
const DIRECTIONS=["E","SE","S","SW","W","NW","N","NE"]
var route:RefCounted=Route.new()
var atlas:Texture2D
var manifest:Dictionary={}
var bodies:Dictionary={}
var region_cache:Dictionary={}
var fading:Array[Dictionary]=[]
var head:Control
var head_art:TextureRect
var tail:Control
var tail_art:TextureRect
var body_diameter:=48.0
var head_physical_width:=84.0
var tail_physical_width:=-1.0
var auxiliary:Dictionary={}
var auxiliary_atlas:Texture2D
var last_head_s:=0.0
var head_s:=0.0
var goal_s:=1.0
var pitch:=40.0
var clock:=0.0
var speed:=1.0
var suspended:=false
var terminal:=""
var current_head_direction:=""
var ready_art:=false
func _init()->void:
	name="Serpent";mouse_filter=Control.MOUSE_FILTER_IGNORE
static func manifest_path_for(config:Dictionary)->String:
	return str(ART_PROFILES.get(str(config.get("art_profile","default")),""))
func configure(config:Dictionary,knots:Array)->bool:
	var metadata_path:=manifest_path_for(config)
	if metadata_path.is_empty():return false
	if not FileAccess.file_exists(metadata_path):return false
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	if not parsed is Dictionary:return false
	manifest=parsed;atlas=load(str(manifest.path) if str(manifest.path).begins_with("res://") else "res://"+str(manifest.path))
	if atlas==null:return false
	head_physical_width=float(config.get("head_physical_width",84.0));tail_physical_width=float(config.get("tail_physical_width",-1.0))
	goal_s=float(config.goal_s);pitch=float(config.pitch);head_s=float(config.head_start_s);last_head_s=head_s
	route.configure(knots,goal_s)
	body_diameter=clampf(pitch*route.baked_length/goal_s*1.13,35.0,62.0)
	head=Control.new();head.name="Head";head.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(head)
	var shadow:=Shadow.new();shadow.name="GroundContact";shadow.radius=Vector2(35,12);head.add_child(shadow)
	head_art=TextureRect.new();head_art.name="HeadArt";head_art.mouse_filter=Control.MOUSE_FILTER_IGNORE;head_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;head.add_child(head_art)
	tail=Control.new();tail.name="Tail";tail.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(tail);move_child(tail,0)
	tail_art=TextureRect.new();tail_art.name="TailArt";tail_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;tail_art.mouse_filter=Control.MOUSE_FILTER_IGNORE;tail.add_child(tail_art)
	ready_art=true;queue_redraw();return true
func sync_snapshot(snapshot:Dictionary)->void:
	if not ready_art:return
	suspended=bool(snapshot.paused);speed=float(snapshot.speed_multiplier)
	terminal=str(snapshot.status) if snapshot.status in ["victory","defeat"] else ""
	head_s=float(snapshot.head_s);var head_step:=head_s-last_head_s
	var alive:Array=snapshot.alive_segment_ids
	for segment in snapshot.segments:
		var id:String=segment.id
		if int(segment.hp)<=0:continue
		var rank:int=alive.find(id);var canonical:float=float(snapshot.segment_s[id])
		if not bodies.has(id):_make_body(segment,rank,canonical)
		var entry:Dictionary=bodies[id]
		if int(entry.rank)!=rank:
			entry.offset=float(entry.display_s)+head_step-canonical;entry.start=clock
		entry.rank=rank;entry.canonical=canonical
		entry.display_s=canonical+float(entry.offset)*pow(1.0-clampf((clock-float(entry.start))/.24,0,1),3)
		entry.node.position=route.point_at(float(entry.display_s))
		var impact:=clampf((clock-float(entry.get("hit_start",-9.0)))/.23,0,1)
		entry.node.scale=Vector2(1.0+sin(impact*PI)*.09,1.0-sin(impact*PI)*.10)
		_update_armor(entry,segment)
	# Removed pieces stay addressable for the event's exact local impact this frame.
	for id in bodies:
		if id not in alive:bodies[id].node.position=route.point_at(float(bodies[id].display_s)+head_step)
	head.position=route.point_at(maxf(0.0,head_s-pitch*.30))
	_set_head_heading(route.tangent_at(head_s))
	head.visible=terminal!="victory"
	tail.visible=not alive.is_empty()
	if not alive.is_empty():
		var last:Dictionary=bodies[alive[-1]]
		var tail_s:=maxf(0.0,float(last.display_s)-pitch*.30)
		tail.position=route.point_at(tail_s)
		var key:String=DIRECTIONS[posmod(roundi(route.tangent_at(tail_s).angle()/(PI/4)),8)]
		_apply_region(tail_art,manifest.tails[key],tail_physical_width if tail_physical_width>0 else body_diameter*.84)
	last_head_s=head_s
func _make_body(segment:Dictionary,rank:int,s:float)->void:
	var node:=Control.new();node.name="Segment_"+str(segment.id);node.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(node);move_child(node,0)
	var shadow:=Shadow.new();shadow.name="GroundContact";shadow.radius=Vector2(body_diameter*.46,body_diameter*.18);node.add_child(shadow)
	var art:=TextureRect.new();art.name="ScaleArt";art.mouse_filter=Control.MOUSE_FILTER_IGNORE;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.add_child(art)
	_apply_region(art,manifest.body,body_diameter)
	var material:=ShaderMaterial.new();material.shader=preload("res://scripts/combat_tint.gdshader");material.set_shader_parameter("tint",PALETTE[segment.color]);material.set_shader_parameter("tint_all",bool(manifest.get("body_tint_all",false)));art.material=material
	bodies[str(segment.id)]={"node":node,"art":art,"rank":rank,"canonical":s,"display_s":s,"offset":0.0,"start":clock,"hit_start":-9.0}
func _apply_region(art:TextureRect,info:Dictionary,diameter:float)->void:
	var a:Array=info.region;var key:=str(a)
	if not region_cache.has(key):
		var texture:=AtlasTexture.new();texture.atlas=atlas;texture.region=Rect2(a[0],a[1],a[2],a[3]);texture.filter_clip=true;region_cache[key]=texture
	art.texture=region_cache[key]
	var factor:float=diameter/float(info.get("physical_width",a[2]))
	art.size=Vector2(a[2],a[3])*factor
	var anchor:Array=info.get("anchor",[a[2]*.5,a[3]*.8]);art.position=-Vector2(anchor[0],anchor[1])*factor
func _set_head_heading(direction:Vector2)->void:
	var index:int=posmod(roundi(direction.angle()/(PI/4.0)),8);var key:String=DIRECTIONS[index]
	if key==current_head_direction:return
	if not manifest.heads.has(key):return
	_apply_region(head_art,manifest.heads[key],head_physical_width);current_head_direction=key
func target_point(id:String,fallback_s:float)->Vector2:
	if bodies.has(id):return bodies[id].node.position
	return route.point_at(fallback_s)
func consume_event(event:Dictionary)->void:
	if event.type=="segment_hit":
		var id:String=event.segment_id
		if bodies.has(id):bodies[id].hit_start=clock
	elif event.type=="segment_removed":
		var id:String=event.segment_id
		if bodies.has(id):
			var entry:Dictionary=bodies[id];fading.append({"node":entry.node,"start":clock,"hit_start":-9.0});bodies.erase(id)
	elif event.type=="victory":
		terminal="victory";head.hide()
func advance(delta:float)->void:
	if not ready_art or suspended or not is_finite(delta) or delta<=0:return
	clock+=delta*(speed if terminal.is_empty() else 1.0)
	for index in range(fading.size()-1,-1,-1):
		var entry:Dictionary=fading[index];var t:=clampf((clock-float(entry.start))/.22,0,1)
		var node:Control=entry.node
		node.modulate=Color(1.0,1.0,1.0,1.0-t);node.scale=Vector2.ONE*(1.0-.18*t)
		if t>=1:node.queue_free();fading.remove_at(index)

func _update_armor(entry:Dictionary,segment:Dictionary)->void:
	# Overlay metadata is provided by the independent production asset pack.
	var overlay:=entry.node.get_node_or_null("ArmorOverlay") as TextureRect
	if str(segment.get("kind","normal"))!="armored":
		if overlay:overlay.hide()
		return
	if not manifest.has("armor"):return
	if not overlay:
		overlay=TextureRect.new();overlay.name="ArmorOverlay";overlay.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;entry.node.add_child(overlay)
	var key:="cracked" if int(segment.hp)==1 else "intact"
	if overlay.get_meta("state","")==key:return
	overlay.set_meta("state",key)
	var info:Dictionary=manifest.armor[key];var r:Array=info.region
	if auxiliary_atlas==null:auxiliary_atlas=load(str(info.path))
	var texture:=AtlasTexture.new();texture.atlas=auxiliary_atlas;texture.region=Rect2(r[0],r[1],r[2],r[3]);texture.filter_clip=true;overlay.texture=texture
	var factor:=body_diameter/float(info.physical_width);var anchor:Array=info.anchor
	overlay.size=Vector2(r[2],r[3])*factor;overlay.position=-Vector2(anchor[0],anchor[1])*factor;overlay.show()

func add_princess(parent:Node,foot:Vector2)->Control:
	# Existing independent tower/princess source documented in the asset manifest is retained.
	# The new background provides a platform, not a baked princess or failure state.
	var art:=TextureRect.new();art.name="Princess";art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var tex:=AtlasTexture.new();tex.atlas=load("res://assets/characters-atlas.png");tex.region=Rect2(740,20,324,624);tex.filter_clip=true;art.texture=tex
	art.size=Vector2(81,156);art.position=foot-Vector2(40.5,156);parent.add_child(art);return art

func add_head_portrait(parent:Node,bounds:Rect2)->Control:
	var art:=TextureRect.new();art.name="ThreatDragon";art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if ready_art:
		_apply_region(art,manifest.heads.SE,bounds.size.x*.86)
		art.size*=minf(1.0,minf(bounds.size.x/art.size.x,bounds.size.y/art.size.y))
		art.position=bounds.get_center()-art.size*.5
	# A modal observes child_entered_tree and captures the resting transform.
	# Assign the final local bounds BEFORE attaching, otherwise its reveal tween
	# later restores the portrait to (0,0), outside the teaching row.
	parent.add_child(art)
	return art
