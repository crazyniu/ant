extends RefCounted
## Minimal shared presentation contract. Rules own the finite route distance and
## integer grid; these anchors are consumed identically in preview and gameplay.
const DEFAULT_PATH := "res://data/scenes/woodland-princess.json"
const Serpent=preload("res://scripts/serpent_view.gd")
const UiSkin=preload("res://scripts/ui_skin.gd")
const ContactShadow=preload("res://scripts/contact_shadow.gd")

static func load_for(config:Dictionary)->Dictionary:
	var appearance_path:=Serpent.manifest_path_for(config.get("serpent",{}))
	if appearance_path.is_empty() or not FileAccess.file_exists(appearance_path):return {"ok":false,"reason":"serpent_appearance_missing"}
	var appearance:Variant=JSON.parse_string(FileAccess.get_file_as_string(appearance_path))
	if not appearance is Dictionary or not ResourceLoader.exists(str(appearance.get("path",""))):return {"ok":false,"reason":"serpent_appearance_invalid"}
	var path:=str(config.get("scene_layout",DEFAULT_PATH))
	if not FileAccess.file_exists(path):return {"ok":false,"reason":"scene_layout_missing"}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:return {"ok":false,"reason":"scene_layout_invalid_json"}
	var data:Dictionary=parsed
	for field in ["nest","cannon","stock","board_plane","defense_target"]:
		if not data.get(field) is Dictionary:return {"ok":false,"reason":"scene_layout_invalid_"+field}
	if not data.get("route") is Array or data.route.size()<2:return {"ok":false,"reason":"scene_route_invalid"}
	for knot in data.route:
		if not knot is Dictionary or not valid_point(knot.get("position")):return {"ok":false,"reason":"scene_route_invalid"}
		for key in ["in","out"]:
			if knot.has(key) and not valid_point(knot[key]):return {"ok":false,"reason":"scene_route_invalid"}
	for point in [data.nest.get("position"),data.nest.get("gateway"),data.cannon.get("muzzle"),data.cannon.get("center"),data.cannon.get("pivot"),data.stock.get("start"),data.defense_target.get("foot"),data.defense_target.get("anchor")]:
		if not valid_point(point):return {"ok":false,"reason":"scene_anchor_invalid"}
	if not valid_numbers(data.cannon.get("rect"),4) or float(data.cannon.rect[2])<=0 or float(data.cannon.rect[3])<=0:return {"ok":false,"reason":"scene_cannon_rect_invalid"}
	for value in [data.nest.get("width"),data.stock.get("spacing"),data.defense_target.get("width"),data.defense_target.get("physical_width")]:
		if not positive_number(value):return {"ok":false,"reason":"scene_scale_invalid"}
	if data.stock.has("columns"):
		var columns:Variant=data.stock.columns
		if not positive_number(columns) or float(columns)!=floorf(float(columns)) or float(columns)>6:return {"ok":false,"reason":"scene_stock_columns_invalid"}
		if not positive_number(data.stock.get("row_spacing")):return {"ok":false,"reason":"scene_stock_rows_invalid"}
	for key in ["top_left","top_right","bottom_left","bottom_right"]:
		if data.board_plane.has(key) and not valid_point(data.board_plane[key]):return {"ok":false,"reason":"scene_board_corner_invalid"}
	for key in ["cell_width_basis","depth_ratio"]:
		if data.board_plane.has(key) and not positive_number(data.board_plane[key]):return {"ok":false,"reason":"scene_board_scale_invalid"}
	if not ResourceLoader.exists(str(data.get("background",""))) or not ResourceLoader.exists(str(data.defense_target.get("texture",""))):return {"ok":false,"reason":"scene_asset_missing"}
	if not data.defense_target.get("fixed",false) or float(data.defense_target.get("physical_width",0))<=0:return {"ok":false,"reason":"scene_target_invalid"}
	var expected:Dictionary=config.get("defense_target",{})
	if data.defense_target.has("contact_shadow"):
		if not valid_point(data.defense_target.contact_shadow) or float(data.defense_target.contact_shadow[0])<=0 or float(data.defense_target.contact_shadow[1])<=0:return {"ok":false,"reason":"scene_target_shadow_invalid"}
	if not expected.is_empty() and expected.get("id")!=data.defense_target.get("id"):return {"ok":false,"reason":"scene_target_identity_mismatch"}
	return {"ok":true,"data":data}

static func valid_point(value:Variant)->bool:
	return valid_numbers(value,2)
static func valid_numbers(value:Variant,count:int)->bool:
	if not value is Array or value.size()!=count:return false
	for number in value:
		if not (number is int or number is float) or not is_finite(float(number)):return false
	return true
static func positive_number(value:Variant)->bool:return (value is int or value is float) and is_finite(float(value)) and float(value)>0

static func point(value:Array)->Vector2:return Vector2(float(value[0]),float(value[1]))
static func rect(value:Array)->Rect2:return Rect2(float(value[0]),float(value[1]),float(value[2]),float(value[3]))
static func knots(data:Dictionary)->Array:
	var result:Array=[]
	for source in data.route:
		var knot:Dictionary={"position":point(source.position)}
		for key in ["in","out"]:
			if source.has(key):knot[key]=point(source[key])
		result.append(knot)
	return result

static func target_texture(data:Dictionary)->Texture2D:
	var target:Dictionary=data.defense_target
	var texture:Texture2D=load(str(target.texture))
	if target.has("region"):
		var cropped:=AtlasTexture.new();cropped.atlas=texture;cropped.region=rect(target.region);cropped.filter_clip=true;return cropped
	return texture

static func add_target(parent:Node,data:Dictionary)->TextureRect:
	var target:Dictionary=data.defense_target
	var source:=target_texture(data)
	var factor:=float(target.width)/float(target.physical_width)
	if target.has("contact_shadow"):
		var shadow:=ContactShadow.new();shadow.name="TargetFootShadow";shadow.radius=point(target.contact_shadow);shadow.position=point(target.foot);shadow.strength=.22;parent.add_child(shadow)
	var node:=UiSkin.place_texture(source,Rect2(point(target.foot)-point(target.anchor)*factor,source.get_size()*factor),parent,"DefenseTarget")
	node.set_meta("guardian_id",target.id);node.set_meta("ground_anchor",point(target.foot))
	return node

static func add_nest(parent:Node,data:Dictionary)->TextureRect:
	var meta:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/serpent/nest-entry.json"))
	var source:Texture2D=load("res://assets/serpent/nest-entry.png")
	var factor:=float(data.nest.width)/float(meta.physical_width)
	return UiSkin.place_texture(source,Rect2(point(data.nest.position)-point(meta.anchor)*factor,source.get_size()*factor),parent,"Nest")

## One anchor for inventory artwork, dynamic counts and delivery FX. Omitted
## columns preserves the exact legacy single-row positions.
static func stock_anchor(data:Dictionary,index:int)->Vector2:
	var columns:=int(data.stock.get("columns",0))
	var column:=index if columns<=0 else index%columns
	var row:=0 if columns<=0 else index/columns
	return point(data.stock.start)+Vector2(column*float(data.stock.spacing),row*float(data.stock.get("row_spacing",0)))
