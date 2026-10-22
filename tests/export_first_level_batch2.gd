extends SceneTree
var scene:Control
var records:Array=[]
func pair(v:Vector2)->Array:return [v.x,v.y]
func rgba(c:Color)->Array:return [c.r,c.g,c.b,c.a]
func _initialize()->void:call_deferred("run")
func run()->void:
	scene=load("res://scenes/play.tscn").instantiate();scene.auto_replay=true;scene.use_command_line_catalog=false;scene.use_command_line_level=false
	root.add_child(scene);current_scene=scene;scene.set_process(false)
	await process_frame
	if not scene.ready_to_simulate:quit(1);return
	export_state("initial")
	for i in 160:
		scene.advance_replay(.05);scene.sync_view();scene.consume_rule_events();scene.fx.advance(.05);scene.serpent.advance(.05);scene.apply_actor_poses()
	export_state("walking-8s")
	scene.audio_service.stop_music();scene.audio_service.stop_all_sfx();await create_timer(.4).timeout
	scene.queue_free();await process_frame;await create_timer(.15).timeout;quit(0)
func export_state(label:String)->void:
	records=[];walk(scene)
	var f:=FileAccess.open("res://reports/first-level/batch-2/nodes-"+OS.get_environment("ANT_ART_SNAPSHOT")+"-"+label+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"label":"OFFLINE NODE COMPOSITION · NOT GODOT RENDER","state":label,"time_us":scene.rules.time_us,"canvas":[940,1672],"nodes":records},"\t"));f.close()
func texture_record(texture:Texture2D)->Dictionary:
	if texture is AtlasTexture:return {"path":texture.atlas.resource_path,"region":[texture.region.position.x,texture.region.position.y,texture.region.size.x,texture.region.size.y]}
	return {"path":texture.resource_path,"region":[0,0,texture.get_width(),texture.get_height()]}
func walk(node:Node)->void:
	if node is CanvasItem and not node.is_visible_in_tree():return
	if node is Control:
		var transform:Transform2D=scene.get_global_transform().affine_inverse()*node.get_global_transform()
		var item:Dictionary={"name":str(scene.get_path_to(node)),"matrix":[transform.x.x,transform.x.y,transform.y.x,transform.y.y,transform.origin.x,transform.origin.y],"size":pair(node.size),"modulate":rgba(node.modulate)}
		if node is TextureRect:
			item.merge(texture_record(node.texture));item.type="texture"
			if node.material is ShaderMaterial:
				item.shader=node.material.shader.resource_path
				item.tint_all=node.material.get_shader_parameter("tint_all") if item.shader=="res://scripts/combat_tint.gdshader" else false
				var tint:Variant=node.material.get_shader_parameter("tint")
				if tint is Color:item.tint=rgba(tint)
			records.append(item)
		elif node is Label:
			item.horizontal_alignment=node.horizontal_alignment;item.vertical_alignment=node.vertical_alignment;item.type="label";item.text=node.text;item.font_size=node.get_theme_font_size("font_size");item.color=rgba(node.get_theme_color("font_color"));item.outline=node.get_theme_constant("outline_size");item.outline_color=rgba(node.get_theme_color("font_outline_color"));records.append(item)
		elif node.get_script()!=null and node.get_script().resource_path=="res://scripts/first_level_bead.gd":
			var regions:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/first-level/bead-regions.json"))
			item.type="texture";item.path="res://assets/first-level/round-beads.png";item.region=regions[node.color_id];item.size=[node.edge,node.footprint_height];records.append(item)
		elif node.get_script()!=null and node.get_script().resource_path=="res://scripts/contact_shadow.gd":
			item.type="shadow";item.radius=pair(node.radius);item.strength=node.strength;records.append(item)
		elif node.get_script()!=null and node.get_script().resource_path=="res://scripts/ui_icon.gd":
			item.type="icon";item.kind=node.kind;records.append(item)
		elif node.get_script()!=null and node.get_script().resource_path=="res://scripts/first_level_medallion.gd":
			item.type="gear";records.append(item)
	for child in node.get_children():walk(child)
