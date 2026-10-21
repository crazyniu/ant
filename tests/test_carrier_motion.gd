extends SceneTree
## Math/material contract only. Does not claim graphical or human acceptance.
const Motion = preload("res://scripts/carrier_motion.gd")
const Shadow = preload("res://scripts/contact_shadow.gd")
var assertions := 0
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func make_actor(region: Rect2) -> Control:
	var actor := Control.new()
	actor.position = Vector2(123.0, 456.0)
	actor.scale = Vector2.ONE * 0.82
	var shadow := Shadow.new()
	shadow.name = "FootShadow"
	shadow.radius = Vector2(48.0 * 0.37, 48.0 * 0.12)
	actor.add_child(shadow)
	var ant := TextureRect.new()
	ant.name = "Ant"
	ant.position = Vector2(-24.0, -48.0 * 0.84)
	ant.size = Vector2(48.0, 48.0 * 0.86)
	ant.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ant.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture := AtlasTexture.new()
	texture.atlas = load("res://assets/ants-atlas.png")
	texture.region = region
	texture.filter_clip = true
	ant.texture = texture
	actor.add_child(ant)
	var bead := Control.new()
	bead.name = "CarriedBead"
	bead.position = Vector2(-8.0, -40.0)
	bead.size = Vector2(19.0, 22.0)
	actor.add_child(bead)
	root.add_child(actor)
	return actor

func test_math() -> void:
	var context := {"time": 1.23, "distance": 89.0, "moving": true,
		"direction": Vector2.RIGHT, "stage": "outbound", "diameter": 48.0}
	var pose: Dictionary = Motion.sample(context)
	check(pose == Motion.sample(context), "same supplied time freezes exact gait/body/load pose")
	check(pose.gait.x * pose.gait.z <= 0.0, "exposed near and far feet stride in opposing directions")
	check(pose.gait.y * pose.gait.w < 0.00000001, "one foot group remains planted while its opposing group lifts")
	check(pose.gait.y >= 0.0 and pose.gait.w >= 0.0, "swing never moves a foot below its original ground line")
	check(pose.facing == 1.0, "positive movement faces right")
	context.direction = Vector2.LEFT
	check(Motion.sample(context).facing == -1.0, "negative movement faces left")
	context.stage = "returning"
	var loaded: Dictionary = Motion.sample(context)
	check(loaded.load == 1.0 and loaded.posture.x > pose.posture.x, "load bends posture without floating the feet")
	context.stage = "pickup"
	context.pickup = 0.5
	var pickup: Dictionary = Motion.sample(context)
	check(pickup.crouch > 0.99 and pickup.gait == Vector4.ZERO, "pickup hold visibly crouches and stops the walking cycle")
	check(pickup.posture.x > loaded.posture.x, "pickup is deeper than the loaded walking posture")
	context.pickup = 0.0
	check(Motion.sample(context).crouch == 0.0, "pickup envelope begins exactly at rest")
	context.pickup = 1.0
	check(Motion.sample(context).crouch == 0.0, "pickup envelope ends exactly at rest")
	context.stage = "outbound"
	context.pickup = 0.0
	context.moving = false
	check(Motion.sample(context).gait == Vector4.ZERO, "stationary actor has no leg treadmill")
	check(Motion.sample(context).posture == Vector4.ZERO, "stationary unloaded body and antennae are at rest")
	context.moving = true
	context.phase = PI * 0.5
	var forward: Dictionary = Motion.sample(context)
	context.phase = PI * 1.5
	var backward: Dictionary = Motion.sample(context)
	check(forward.gait.x > 0.04 and backward.gait.x < -0.04, "opposite quarter cycles visibly move the original leg pixels")
	for index in range(241):
		context.time = index * 0.05
		context.erase("phase")
		var bounded: Dictionary = Motion.sample(context)
		check(absf(bounded.gait.x) <= 0.0521 and bounded.gait.y <= 0.0701,
			"limb displacement remains inside measured local bounds")

func test_material_and_replay() -> void:
	var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/ant-regions.json"))
	var actors: Array[Control] = []
	var context := {"time": 1.23, "moving": true, "direction": Vector2.LEFT,
		"stage": "returning", "diameter": 48.0, "phase_offset": 0.3}
	var previous_material: ShaderMaterial
	for color in regions:
		var r: Array = regions[color]
		var actor := make_actor(Rect2(r[0], r[1], r[2], r[3]))
		actors.append(actor)
		var original_transform : Transform2D = actor.get_transform()
		var original_sprite_transform: Transform2D = actor.get_node("Ant").get_transform()
		var original_shadow_transform: Transform2D = actor.get_node("FootShadow").get_transform()
		var pose: Dictionary = Motion.apply(actor, context)
		var ant := actor.get_node("Ant") as TextureRect
		var bead := actor.get_node("CarriedBead") as Control
		var material := ant.material as ShaderMaterial
		check(actor.get_transform() == original_transform, "helper never owns route translation or depth scale")
		check(ant.get_transform() == original_sprite_transform, "helper never stretches or floats the whole sprite")
		check(actor.get_node("FootShadow").get_transform() == original_shadow_transform, "grounded contact shadow stays fixed")
		check(ant.flip_h, "actual TextureRect UVs face the requested direction")
		check(material.shader == Motion.GAIT_SHADER, "all carriers reuse one shared shader resource")
		if previous_material != null:
			check(material != previous_material, "per-carrier gait uniforms cannot bleed between actors")
		previous_material = material
		var expected := Vector4(float(r[0]) / 1536.0, float(r[1]) / 1024.0,
			float(r[2]) / 1536.0, float(r[3]) / 1024.0)
		check(material.get_shader_parameter("atlas_rect") == expected, "each ant samples only its measured atlas region")
		check(material.get_shader_parameter("gait") == pose.gait, "shader receives the exact sampled gait")
		var frozen_bead : Transform2D = bead.get_transform()
		for repeated in range(30):
			Motion.apply(actor, context)
		check(bead.get_transform() == frozen_bead, "repeated sync has no cumulative bead drift or double advance")
		var later := context.duplicate(true)
		later.time = 31.7
		Motion.apply(actor, later)
		var rewound: Dictionary = Motion.apply(actor, context)
		check(rewound == pose and bead.get_transform() == frozen_bead, "rewinding supplied time reconstructs the exact prior pose")
		Motion.reset(actor)
		check(ant.material == null and not ant.flip_h, "reset restores original material/facing")
		check(bead.position == Vector2(-8.0, -40.0) and bead.rotation == 0.0,
			"reset restores original bead rest transform")
		check(actor.get_transform() == original_transform, "reset also leaves authoritative actor transform alone")
	for actor in actors:
		actor.free()
	var shader_source := FileAccess.get_file_as_string("res://scripts/carrier_motion.gdshader")
	check(not "TIME" in shader_source, "shader has no independent realtime animation clock")
	check("COLOR.a *= inside" in shader_source and "half_pixel" in shader_source,
		"manual sampling includes explicit transparent bounds and half-texel atlas clamping")

func run() -> void:
	test_math()
	test_material_and_replay()
	if failures.is_empty():
		print("CARRIER_MOTION_PASS: %d assertions; deterministic articulation, pause, opposing planted/swing pairs, loaded posture, facing, six-region isolation, reset; graphical acceptance NOT_RUN" % assertions)
	else:
		print("CARRIER_MOTION_FAIL: %d/%d assertions failed" % [failures.size(), assertions])
	quit(0 if failures.is_empty() else 1)
