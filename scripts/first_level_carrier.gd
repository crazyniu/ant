extends RefCounted
## Eight painted yaw views, with local articulation only. The caller retains
## route position, depth, visibility and all pickup/delivery event ownership.
## Heading/posture use simulation time; foot phase uses actual travelled pixels.

const GAIT_SHADER = preload("res://scripts/first_level_carrier.gdshader")
const MANIFEST_PATH := "res://assets/first-level/slender-ants.json"
const WORLD_DIAMETER := 62.0 # Before the existing .88..1 ground-depth projection.
const CACHE_KEY := &"directional_carrier_state"
const DEFAULT_DIAMETER := 48.0
const SOURCE_PHYSICAL_WIDTH := 420.0
# Candidate visual tuning, not a measured cadence from the reference footage.
const OUTBOUND_CADENCE := 3.6
const LOADED_CADENCE := 3.1
# Nominal stride length preserves the current baseline cadence while phase
# follows actual distance, including upgraded speed, stops and rounded routes.
const OUTBOUND_STRIDE_PIXELS := 33.5 * 2.5 / OUTBOUND_CADENCE
const LOADED_STRIDE_PIXELS := 33.5 * 2.0 / LOADED_CADENCE
const TURN_SPEED := PI / 0.4 # At most 90 degrees in 0.2 simulation seconds.
const FRAME_ANGLE := PI / 4.0
const FRAME_HYSTERESIS := PI / 72.0
const DIRECTION_NAMES := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
const COLORS := {
	"red": Color("ed4137"), "blue": Color("329cfa"),
	"yellow": Color("fbc52c"), "green": Color("68d849"),
	"purple": Color("a25fe6"), "white": Color("f7efdb"),
}
static var _manifest: Dictionary = {}
static var _atlas: Texture2D
static var _textures: Array[AtlasTexture] = []

static func _finite(value: Variant, fallback: float = 0.0) -> float:
	var number := float(value)
	return number if is_finite(number) else fallback

static func _direction(context: Dictionary) -> Vector2:
	var value: Vector2 = context.get("direction", Vector2.RIGHT)
	if not value.is_finite() or value.length_squared() < 0.000001:
		return Vector2.ZERO
	return value.normalized()

static func phase_at_distance(outbound:float,loaded:float,offset:float=0.0)->float:
	return TAU*(maxf(0.0,_finite(outbound))/OUTBOUND_STRIDE_PIXELS+maxf(0.0,_finite(loaded))/LOADED_STRIDE_PIXELS)+_finite(offset)

static func sample(context: Dictionary) -> Dictionary:
	var time := maxf(0.0, _finite(context.get("time", 0.0)))
	var diameter := maxf(1.0, _finite(context.get("diameter", DEFAULT_DIAMETER), DEFAULT_DIAMETER))
	var stage := String(context.get("stage", "outbound"))
	var pickup := clampf(_finite(context.get("pickup", 0.0)), 0.0, 1.0)
	var moving := bool(context.get("moving", true)) and stage != "pickup"
	var loaded := stage == "returning"
	var crouch := sin(pickup * PI) if stage == "pickup" and pickup > 0.0 and pickup < 1.0 else 0.0
	var phase := phase_at_distance(_finite(context.get("outbound_distance",context.get("distance",0.0))),_finite(context.get("loaded_distance",0.0)),_finite(context.get("phase_offset",0.0)))
	var walk := 1.0 if moving else 0.0
	var stride := (9.0 if loaded else 12.0) * walk
	var lift := (11.0 if loaded else 15.0) * walk
	var direction := _direction(context)
	var heading := direction.angle() if direction != Vector2.ZERO else 0.0
	var frame := posmod(int(round(heading / FRAME_ANGLE)), 8)
	# Body translations are screen-space <= 0.18 logical px, converted back to
	# source pixels. There is no vertical walking bob or whole-actor transform.
	var sway := sin(phase * 2.0) * 0.18 * walk
	var source_scale := diameter / SOURCE_PHYSICAL_WIDTH
	return {
		"time": time, "phase": phase, "diameter": diameter, "stage": stage,
		"moving": moving, "load": 1.0 if loaded else 0.0, "crouch": crouch,
		"heading": heading, "frame_index": frame, "direction_name": DIRECTION_NAMES[frame],
		"gait": Vector4(sin(phase) * stride, maxf(0.0, cos(phase)) * lift,
			-sin(phase) * stride, maxf(0.0, -cos(phase)) * lift),
		"posture": Vector2(sway / source_scale, (0.16 * float(loaded) + 0.95 * crouch) / source_scale),
		"body_sway_px": sway, "source_scale": source_scale,
	}

static func prepare(actor: Control, color_id: String, diameter: float = DEFAULT_DIAMETER) -> bool:
	if actor.has_meta(CACHE_KEY):
		return true
	var sprite := actor.get_node_or_null("Ant") as TextureRect
	if sprite == null or not _load_art():
		return false
	var material := ShaderMaterial.new()
	material.shader = GAIT_SHADER
	material.set_shader_parameter("tint", COLORS.get(color_id, COLORS.green))
	var original := {
		"texture": sprite.texture, "material": sprite.material,
		"position": sprite.position, "size": sprite.size, "scale": sprite.scale,
		"rotation": sprite.rotation, "pivot": sprite.pivot_offset,
		"flip_h": sprite.flip_h, "flip_v": sprite.flip_v,
		"expand": sprite.expand_mode, "stretch": sprite.stretch_mode,
	}
	var state := {
		"original": original, "material": material, "color_id": color_id,
		"diameter": maxf(1.0, _finite(diameter, DEFAULT_DIAMETER)),
		"initialized": false, "last_time": -1.0, "heading": 0.0,
		"frame_index": -1, "last_pose": {},
	}
	var bead := actor.get_node_or_null("CarriedBead") as Control
	if bead != null:
		state.bead_original = {"position": bead.position, "rotation": bead.rotation, "pivot": bead.pivot_offset}
	sprite.material = material
	sprite.flip_h = false
	sprite.flip_v = false
	sprite.rotation = 0.0
	sprite.scale = Vector2.ONE
	sprite.pivot_offset = Vector2.ZERO
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	actor.set_meta(CACHE_KEY, state)
	_set_frame(sprite, state, 0)
	return true

static func apply(actor: Control, context: Dictionary) -> Dictionary:
	if not actor.has_meta(CACHE_KEY):
		if not prepare(actor, String(context.get("color_id", "green")), _finite(context.get("diameter", DEFAULT_DIAMETER), DEFAULT_DIAMETER)):
			return sample(context)
	var state: Dictionary = actor.get_meta(CACHE_KEY)
	var input := context.duplicate()
	input.diameter = state.diameter
	var pose := sample(input)
	var time: float = pose.time
	# Repeated sync, including an input-direction change while paused, must not
	# advance the heading or any pose. Explicit reset starts a new visual clock.
	if state.initialized and time == float(state.last_time):
		var frozen: Dictionary = Dictionary(state.last_pose).duplicate()
		_place_bead(actor, state, frozen)
		return frozen
	var direction := _direction(context)
	var target: float = direction.angle() if direction != Vector2.ZERO else float(state.heading)
	var previous_stage := String(state.last_pose.get("stage", ""))
	if String(pose.stage) == "pickup":
		# The game's pre-existing finite hold provides this turn envelope. It
		# adds no delay/event; the ordinary travel rate limit remains separate.
		if previous_stage != "pickup" or not state.has("pickup_heading"):
			state.pickup_heading = float(state.heading) if state.initialized else target
		state.heading = float(state.pickup_heading) + PI * smoothstep(0.0, 1.0, clampf(_finite(context.get("pickup", 0.0)), 0.0, 1.0))
	elif not state.initialized or time < float(state.last_time) or (String(pose.stage) == "returning" and previous_stage != "returning"):
		# A skipped hold at low frame rate must not cause backwards return travel.
		state.heading = target
	else:
		state.heading = rotate_toward(float(state.heading), target, TURN_SPEED * (time - float(state.last_time)))
	state.heading = wrapf(float(state.heading), -PI, PI)
	var frame := posmod(int(round(float(state.heading) / FRAME_ANGLE)), 8)
	if state.initialized:
		var prior_center := float(state.frame_index) * FRAME_ANGLE
		if absf(angle_difference(prior_center, float(state.heading))) < FRAME_ANGLE * 0.5 + FRAME_HYSTERESIS:
			frame = int(state.frame_index)
	var sprite := actor.get_node("Ant") as TextureRect
	if frame != int(state.frame_index):
		_set_frame(sprite, state, frame)
	pose.heading = state.heading
	pose.frame_index = frame
	pose.direction_name = DIRECTION_NAMES[frame]
	pose.color_id = state.color_id
	pose.region = _textures[frame].region
	pose.foot_anchor = _v2(_manifest.poses[frame].foot_anchor)
	pose.sprite_position = sprite.position
	pose.sprite_size = sprite.size
	pose.leg_groups = _leg_groups(frame)
	pose.leg_count = _manifest.poses[frame].legs.size()
	pose.cargo_bottom_contact = _v2(_manifest.poses[frame].cargo_bottom_contact)
	var material: ShaderMaterial = state.material
	material.set_shader_parameter("gait", pose.gait)
	material.set_shader_parameter("posture", pose.posture)
	# Axis follows the rendered view, never a rotated card. Vertical travel is
	# foreshortened on the ground plane; swing-foot lift is separately upward.
	var frame_heading := float(frame) * FRAME_ANGLE
	var gait_axis := Vector2(cos(frame_heading), sin(frame_heading) * 0.42)
	material.set_shader_parameter("gait_axis", gait_axis)
	pose.gait_axis = gait_axis
	_place_bead(actor, state, pose)
	state.initialized = true
	state.last_time = time
	state.last_pose = pose.duplicate()
	actor.set_meta(CACHE_KEY, state)
	return pose

static func _place_bead(actor: Control, state: Dictionary, pose: Dictionary) -> void:
	var bead := actor.get_node_or_null("CarriedBead") as Control
	if bead != null:
		if not state.has("bead_original"):
			state.bead_original = {"position": bead.position, "rotation": bead.rotation, "pivot": bead.pivot_offset}
		# The same full-size ball meets this view's back, rather than floating
		# over a shared head-center anchor. No cargo scale or route is changed.
		var entry:Dictionary=_manifest.poses[int(pose.frame_index)]
		var contact:=(_v2(entry.cargo_bottom_contact)-_v2(entry.foot_anchor))*float(state.diameter)/SOURCE_PHYSICAL_WIDTH
		var local_span:=bead.size*bead.scale
		bead.position = contact-Vector2(local_span.x*.5,local_span.y)
		bead.position += Vector2(pose.posture) * float(pose.source_scale)
		bead.rotation = float(state.bead_original.rotation)

static func reset(actor: Control) -> void:
	if not actor.has_meta(CACHE_KEY):
		return
	var state: Dictionary = actor.get_meta(CACHE_KEY)
	var sprite := actor.get_node_or_null("Ant") as TextureRect
	if sprite != null:
		var original: Dictionary = state.original
		sprite.texture = original.texture
		sprite.material = original.material
		sprite.position = original.position
		sprite.size = original.size
		sprite.scale = original.scale
		sprite.rotation = original.rotation
		sprite.pivot_offset = original.pivot
		sprite.flip_h = original.flip_h
		sprite.flip_v = original.flip_v
		sprite.expand_mode = original.expand
		sprite.stretch_mode = original.stretch
	var bead := actor.get_node_or_null("CarriedBead") as Control
	if bead != null and state.has("bead_original"):
		bead.position = state.bead_original.position
		bead.rotation = state.bead_original.rotation
		bead.pivot_offset = state.bead_original.pivot
	actor.remove_meta(CACHE_KEY)

static func _load_art() -> bool:
	if not _textures.is_empty():
		return true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not parsed is Dictionary or not parsed.has("poses") or parsed.poses.size() != 8:
		push_error("Directional carrier requires its eight-view art manifest.")
		return false
	_manifest = parsed
	_atlas = load(String(_manifest.get("texture", "res://assets/first-level/slender-ants.png"))) as Texture2D
	if _atlas == null:
		return false
	for entry: Dictionary in _manifest.poses:
		var region: Array = entry.region
		var texture := AtlasTexture.new()
		texture.atlas = _atlas
		texture.region = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
		texture.filter_clip = true
		_textures.append(texture)
	return true

static func _set_frame(sprite: TextureRect, state: Dictionary, frame: int) -> void:
	var entry: Dictionary = _manifest.poses[frame]
	var texture := _textures[frame]
	var scale := float(state.diameter) / SOURCE_PHYSICAL_WIDTH
	sprite.texture = texture
	sprite.size = texture.region.size * scale
	sprite.position = -_v2(entry.foot_anchor) * scale
	var atlas_size := _atlas.get_size()
	var region := texture.region
	var material: ShaderMaterial = state.material
	material.set_shader_parameter("atlas_rect", Vector4(region.position.x / atlas_size.x,
		region.position.y / atlas_size.y, region.size.x / atlas_size.x, region.size.y / atlas_size.y))
	material.set_shader_parameter("source_size", region.size)
	material.set_shader_parameter("foot_anchor", _v2(entry.foot_anchor))
	for index in range(6):
		var leg: Array = entry.legs[index] if index<entry.legs.size() else [0,0,0,0]
		material.set_shader_parameter("leg_%d" % index, Vector4(float(leg[0]), float(leg[1]), float(leg[2]), float(leg[3])))
	material.set_shader_parameter("leg_count",entry.legs.size())
	material.set_shader_parameter("leg_groups", _leg_groups(frame))
	var groups:Array=entry.leg_groups
	material.set_shader_parameter("leg_groups_extra",Vector2(float(groups[4]) if groups.size()>4 else 0.0,float(groups[5]) if groups.size()>5 else 0.0))
	state.frame_index = frame

static func _leg_groups(frame: int) -> Vector4:
	var groups:Array=_manifest.poses[frame].leg_groups
	return Vector4(float(groups[0]),float(groups[1]),float(groups[2]),float(groups[3]) if groups.size()>3 else 0.0)

static func _v2(values: Array) -> Vector2:
	return Vector2(float(values[0]), float(values[1]))
