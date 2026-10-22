extends RefCounted
## Read-only scene artwork, never a gameplay instance, run or save.
const Layout=preload("res://scripts/scene_layout.gd")
const BoardProjection=preload("res://scripts/board_plane.gd")
const Ball=preload("res://scripts/first_level_bead.gd")
const Serpent=preload("res://scripts/serpent_view.gd")
const ArtSkin=preload("res://scripts/ui_skin.gd")
const Loading=preload("res://scripts/first_level_loading.gd")

static func read_configuration(path:String)->Dictionary:
	if not FileAccess.file_exists(path):return {"ok":false,"reason":"first_preview_config_missing"}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:return {"ok":false,"reason":"first_preview_config_invalid_json"}
	if not valid_config(parsed):return {"ok":false,"reason":"first_preview_config_invalid_shape"}
	return {"ok":true,"config":parsed}

static func valid_config(config:Dictionary)->bool:
	if config.get("level_id","")!="serpent-01" or config.get("width",0)!=16 or config.get("height",0)!=15:return false
	if not config.get("grid") is Array or config.grid.size()!=15 or not config.get("palette") is Dictionary:return false
	if not config.get("serpent") is Dictionary or not config.get("segments") is Array:return false
	for key in ["head_start_s","pitch","goal_s"]:
		if not config.serpent.get(key) is float and not config.serpent.get(key) is int:return false
	for row in config.grid:
		if not row is String or row.length()!=16:return false
		for cell in row:
			if not config.palette.has(cell):return false
	for segment in config.segments:
		if not segment is Dictionary or not segment.has("id") or not segment.has("color") or not segment.has("hp") or not segment.has("kind"):return false
	var checked:=Layout.load_for(config)
	return checked.ok and checked.data.get("presentation",{}).get("first_level_only",false)

static func build(config:Dictionary,bounds:Rect2,parent:Control,id:String="ScenePreview")->Control:
	if not valid_config(config):return null
	var checked:=Layout.load_for(config)
	if not checked.ok or not checked.data.get("presentation",{}).get("first_level_only",false):return null
	var layout:Dictionary=checked.data
	var viewport:=Control.new();viewport.name=id;viewport.mouse_filter=Control.MOUSE_FILTER_IGNORE
	viewport.position=bounds.position;viewport.size=bounds.size;viewport.clip_contents=true;parent.add_child(viewport)
	var scene:=Control.new();scene.name="ActualLevelScene";scene.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scene.size=Vector2(940,1672);scene.scale=Vector2.ONE*bounds.size.x/940.0;viewport.add_child(scene)
	ArtSkin.place_texture(load(str(layout.background)),Rect2(Vector2.ZERO,Vector2(940,1672)),scene,"Forest")
	var serpent:=Serpent.new();serpent.name="PreviewSerpent";scene.add_child(serpent)
	var source:Dictionary=config.get("serpent",{})
	if serpent.configure(source,Layout.knots(layout)):
		var segments:Array=config.get("segments",[]).duplicate(true);var ids:Array=[];var positions:Dictionary={}
		for index in segments.size():
			var segment_id:=str(segments[index].id);ids.append(segment_id)
			positions[segment_id]=float(source.head_start_s)-float(index+1)*float(source.pitch)
		serpent.sync_snapshot({"paused":true,"speed_multiplier":1,"status":"ready","head_s":float(source.head_start_s),"alive_segment_ids":ids,"segments":segments,"segment_s":positions})
	Layout.add_target(scene,layout)
	var plane:=BoardProjection.new(int(config.width),int(config.height),layout,config.get("transport",{}).get("entrance_cell",[]))
	for y in config.grid.size():
		var row:=str(config.grid[y])
		for x in row.length():
			if not config.palette.has(row[x]):continue
			var ball:=Ball.new();ball.name="Mosaic_%d_%d"%[x,y];ball.color_id=str(config.palette[row[x]])
			ball.edge=Ball.WORLD_SIZE.x;ball.footprint_height=Ball.WORLD_SIZE.y;ball.size=Ball.WORLD_SIZE
			ball.position=plane.center(x,y)-ball.size*.5;ball.set_meta("cell",Vector2i(x,y));ball.set_meta("color_id",ball.color_id);scene.add_child(ball)
	Layout.add_nest(scene,layout)
	var source_texture:=AtlasTexture.new();source_texture.atlas=load(str(layout.cannon.texture));source_texture.region=Layout.rect(layout.cannon.region);source_texture.filter_clip=true
	var cannon:=ArtSkin.place_texture(source_texture,Layout.rect(layout.cannon.rect),scene,"PreviewCannon")
	cannon.pivot_offset=Layout.point(layout.cannon.pivot)
	var gunner:=Loading.build_gunner(cannon)
	Loading.pose_gunner(gunner,cannon,Vector2(356.367,1048.443),Vector2.ZERO)
	viewport.set_meta("read_only_first_level",true)
	return viewport
