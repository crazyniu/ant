extends RefCounted
class_name RescueSkin

var atlases: Dictionary = {}
var regions: Dictionary = {}
var textures: Dictionary = {}

func _init() -> void:
	regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/v03/regions.json"))
	regions["titles"]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/v03/title-regions.json"))
	atlases["titles"]=load("res://assets/ui/v03/title-atlas.png")
	for page in ["game","settings"]:
		atlases[page]=load("res://assets/ui/v03/"+page+"-skin-atlas.png")

func texture(key: String) -> AtlasTexture:
	if not textures.has(key):
		var pieces:=key.split("/");var data:Array=regions[pieces[0]][pieces[1]]
		var t:=AtlasTexture.new();t.atlas=atlases[pieces[0]];t.region=Rect2(data[0],data[1],data[2],data[3]);t.filter_clip=true;textures[key]=t
	return textures[key]

func sprite(key: String, bounds: Rect2, parent: Node, id: String) -> TextureRect:
	return place_texture(texture(key),bounds,parent,id)

static func place_texture(source:Texture2D,bounds:Rect2,parent:Node,id:String,keep_aspect:bool=false)->TextureRect:
	# Native texture dimensions must never become a control's minimum size.
	# Keep this order: ignore intrinsic size, assign texture, set bounds, attach.
	var node:=TextureRect.new();node.name=id
	node.custom_minimum_size=Vector2.ZERO;node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED if keep_aspect else TextureRect.STRETCH_SCALE
	node.texture=source;node.position=bounds.position;node.size=bounds.size
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(node)
	return node

func panel(key: String, bounds: Rect2, parent: Node, id: String, corner: float = 22.0) -> Panel:
	var p:=Panel.new();p.name=id;p.position=bounds.position;p.size=bounds.size;p.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.add_theme_stylebox_override("panel",StyleBoxEmpty.new());parent.add_child(p)
	var n:=NinePatchRect.new();n.name="PaintedNineSlice";n.texture=texture(key);n.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var margin:=100 if key=="settings/panel" else 64
	var ratio:=corner/float(margin)
	n.patch_margin_left=margin;n.patch_margin_right=margin;n.patch_margin_top=margin;n.patch_margin_bottom=margin
	n.size=bounds.size/ratio;n.scale=Vector2(ratio,ratio)
	p.add_child(n);return p
