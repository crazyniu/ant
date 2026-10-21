extends SceneTree
const View=preload("res://scripts/serpent_view.gd")
const Layout=preload("res://scripts/scene_layout.gd")
const Rules=preload("res://scripts/rescue_rules.gd")
var checks:=0
var failures:Array=[]
func check(value:bool,label:String)->void:
	checks+=1
	if not value:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-05.json"))
	var original:=View.new();root.add_child(original)
	var layout:=Layout.load_for(config)
	check(original.configure(config.serpent,Layout.knots(layout.data)),"legacy appearance still resolves")
	check(original.atlas.resource_path=="res://assets/serpent/serpent-atlas.png","existing level default atlas unchanged")
	var old_rules:=Rules.new();old_rules.load_level(config);original.sync_snapshot(old_rules.snapshot())
	var legacy_body:TextureRect=original.bodies[original.bodies.keys()[0]].art
	check(legacy_body.material.get_shader_parameter("tint_all")==false,"old red-mask shader behavior retained by default")
	var before:=JSON.stringify(config);var ice:=config.duplicate(true);ice.serpent.art_profile="ruins_carapace"
	var view:=View.new();root.add_child(view)
	check(Layout.load_for(ice).ok and view.configure(ice.serpent,Layout.knots(layout.data)),"carapace appearance loads in same scene contract")
	check(view.atlas.resource_path=="res://assets/serpent/carapace-serpent-atlas.png","new independent atlas selected")
	var ice_rules:=Rules.new();ice_rules.load_level(ice);view.sync_snapshot(ice_rules.snapshot())
	check(ice_rules.snapshot()==old_rules.snapshot(),"appearance flag changes no rule state")
	check(JSON.stringify(config)==before,"appearance fixture does not mutate original config")
	for i in range(8):
		view._set_head_heading(Vector2.from_angle(i*PI/4))
		check(view.current_head_direction==View.DIRECTIONS[i] and view.head_art.rotation==0,"real yaw pose not whole-image rotation")
		for group in ["heads","tails"]:
			var info:Dictionary=view.manifest[group][View.DIRECTIONS[i]];var r:Array=info.region;var a:Array=info.anchor
			check(r[0]>=0 and r[1]>=0 and r[0]+r[2]<=view.atlas.get_width() and r[1]+r[3]<=view.atlas.get_height(),"atlas region bounded "+group)
			check(a[0]>=0 and a[1]>=0 and a[0]<=r[2] and a[1]<=r[3],"joint anchor inside measured sprite "+group)
	var tinting:=true
	for entry in view.bodies.values():
		if entry.art.material.get_shader_parameter("tint_all")!=true:tinting=false
	check(tinting,"neutral carapace plates receive complete gameplay-color tint")
	var invalid:=ice.duplicate(true);invalid.serpent.art_profile="unavailable_skin"
	check(not Layout.load_for(invalid).ok,"unknown appearance rejected before scene entry")
	var invalid_view:=View.new();check(not invalid_view.configure(invalid.serpent,Layout.knots(layout.data)),"renderer cannot silently substitute wrong appearance")
	invalid_view.free();original.queue_free();view.queue_free();await process_frame;await process_frame
	var report:Dictionary={"checks":checks,"failures":failures,"scope":"appearance selection, eight real yaw poses, measured regions/anchors, old default tint flag, unchanged rule snapshots; not final GL art approval","atlas_sha256":FileAccess.get_sha256("res://assets/serpent/carapace-serpent-atlas.png"),"manifest_sha256":FileAccess.get_sha256("res://assets/serpent/carapace-serpent-atlas.json")}
	var file:=FileAccess.open("res://reports/assets/carapace-serpent-test.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("CARAPACE_SERPENT_SKIN ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
