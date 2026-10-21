extends RefCounted
## Presentation-only carrier articulation. The caller owns actor position, depth,
## visibility, stage transitions and the simulation clock. No process/timer/tween.
##
## apply(actor, {time: seconds, distance: travelled logical pixels, moving: bool,
##   direction: Vector2, stage: "outbound"/"pickup"/"returning", pickup: 0..1,
##   diameter: logical width, phase_offset: radians, cadence: optional Hz})
## `time` must be the same frozen simulation time used for the route. Distance is
## exposed for diagnostics; cadence is time-based so long route segments cannot
## turn the readable walk into a rapidly vibrating blur. A supplied `phase`
## (radians) overrides cadence when the caller has a continuous stride clock.
## Pickup is a finite 0..1 hold envelope supplied by the caller, not a rule event.
## The four visible limbs use the original pixels; the hidden legs are not drawn.

const GAIT_SHADER = preload("res://scripts/carrier_motion.gdshader")
const CACHE_KEY := &"carrier_motion_base"
const DEFAULT_DIAMETER := 48.0
const OUTBOUND_CADENCE := 2.15
const LOADED_CADENCE := 1.65

static func sample(context: Dictionary) -> Dictionary:
	var time := maxf(0.0, float(context.get("time", 0.0)))
	var diameter := maxf(1.0, float(context.get("diameter", DEFAULT_DIAMETER)))
	var stage := String(context.get("stage", "outbound"))
	var pickup := clampf(float(context.get("pickup", 0.0)), 0.0, 1.0)
	var moving := bool(context.get("moving", true)) and stage != "pickup"
	var carrying := stage == "returning"
	var load_weight := 1.0 if carrying else 0.0
	var crouch := sin(pickup * PI) if pickup > 0.0 and pickup < 1.0 else 0.0
	var cadence := clampf(float(context.get("cadence", LOADED_CADENCE if carrying else OUTBOUND_CADENCE)), 0.0, 3.0)
	var phase := float(context.get("phase", time * TAU * cadence + float(context.get("phase_offset", 0.0))))
	var walk := (1.0 if moving else 0.0) * (1.0 - crouch * 0.85)
	var step_a := sin(phase)
	var step_b := sin(phase + PI)
	# The forward swing lifts; the opposing planted pair stays on its original
	# contact line. The body silhouette is never rotated or uniformly stretched.
	var stride := lerpf(0.052, 0.043, load_weight) * walk
	var lift := lerpf(0.070, 0.048, load_weight) * walk
	var direction: Vector2 = context.get("direction", Vector2.RIGHT)
	var facing := -1.0 if direction.x < -0.025 else 1.0
	if absf(direction.x) <= 0.025:
		facing = -1.0 if carrying else 1.0
	if stage == "pickup" and pickup >= 0.58:
		facing *= -1.0
	var body_drop := 0.012 * load_weight + 0.052 * crouch
	var body_sway := sin(phase * 2.0) * 0.006 * walk
	var antenna_sway := sin(phase + 0.7) * 0.010 * walk
	return {
		"phase": phase, "facing": facing, "moving": moving,
		"distance": maxf(0.0, float(context.get("distance", 0.0))),
		"diameter": diameter, "crouch": crouch, "load": load_weight,
		"gait": Vector4(step_a * stride, maxf(0.0, cos(phase)) * lift,
			step_b * stride, maxf(0.0, cos(phase + PI)) * lift),
		"posture": Vector4(body_drop, body_sway, antenna_sway, crouch),
		"bead_offset": Vector2(facing * sin(phase) * 0.009 * diameter * walk,
			(body_drop + absf(sin(phase * 2.0)) * 0.004 * walk) * diameter),
		"bead_rotation": facing * sin(phase) * 0.025 * walk,
	}

static func apply(actor: Control, context: Dictionary) -> Dictionary:
	var pose := sample(context)
	var sprite := actor.get_node_or_null("Ant") as TextureRect
	if sprite == null or sprite.texture == null:
		return pose
	if not actor.has_meta(CACHE_KEY):
		_prepare(actor, sprite)
	var base: Dictionary = actor.get_meta(CACHE_KEY)
	var material: ShaderMaterial = base.material
	# TextureRect.flip_h mirrors the actual source UVs, including its articulated
	# limbs. The actor and shadow are not mirrored or translated.
	sprite.flip_h = float(pose.facing) < 0.0
	material.set_shader_parameter("gait", pose.gait)
	material.set_shader_parameter("posture", pose.posture)
	var shadow := actor.get_node_or_null("FootShadow") as Control
	if shadow != null:
		shadow.position = base.shadow_position
	var bead := actor.get_node_or_null("CarriedBead") as Control
	if bead != null:
		if not base.has("bead_position"):
			base.bead_position = bead.position
			base.bead_rotation = bead.rotation
			base.bead_pivot = bead.pivot_offset
			actor.set_meta(CACHE_KEY, base)
		var width: float = float(pose.diameter)
		# Keep the bead above the thorax rather than over the eyes. Use the
		# existing bead node and edge; the parent alone controls its visibility.
		var rest := Vector2(-bead.size.x * 0.5, -width * 0.94 - bead.size.x * 0.28)
		bead.pivot_offset = Vector2(bead.size.x * 0.5, bead.size.y)
		bead.position = rest + Vector2(pose.bead_offset)
		bead.rotation = float(base.bead_rotation) + float(pose.bead_rotation)
	return pose

static func reset(actor: Control) -> void:
	if not actor.has_meta(CACHE_KEY):
		return
	var base: Dictionary = actor.get_meta(CACHE_KEY)
	var sprite := actor.get_node_or_null("Ant") as TextureRect
	if sprite != null:
		sprite.material = base.original_material
		sprite.flip_h = base.flip_h
	var shadow := actor.get_node_or_null("FootShadow") as Control
	if shadow != null:
		shadow.position = base.shadow_position
	var bead := actor.get_node_or_null("CarriedBead") as Control
	if bead != null and base.has("bead_position"):
		bead.position = base.bead_position
		bead.rotation = base.bead_rotation
		bead.pivot_offset = base.bead_pivot
	actor.remove_meta(CACHE_KEY)

static func _prepare(actor: Control, sprite: TextureRect) -> void:
	var material := ShaderMaterial.new()
	material.shader = GAIT_SHADER
	var region := Rect2(Vector2.ZERO, Vector2.ONE)
	var texture := sprite.texture
	if texture is AtlasTexture:
		var atlas_texture := texture as AtlasTexture
		if atlas_texture.atlas != null:
			var atlas_size := atlas_texture.atlas.get_size()
			region = Rect2(atlas_texture.region.position / atlas_size, atlas_texture.region.size / atlas_size)
	material.set_shader_parameter("atlas_rect", Vector4(region.position.x, region.position.y, region.size.x, region.size.y))
	var shadow := actor.get_node_or_null("FootShadow") as Control
	var base := {
		"material": material, "original_material": sprite.material,
		"flip_h": sprite.flip_h,
		"shadow_position": shadow.position if shadow != null else Vector2.ZERO,
	}
	sprite.material = material
	actor.set_meta(CACHE_KEY, base)
