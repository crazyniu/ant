extends Control
## Event-only presentation. Never owns gameplay state, settles ammo, or calls Rules.
## Coordinate space: 940 × 1672; inherit the owning root's uniform canvas scale.

const PALETTE := {
	"red": Color("f75a45"), "blue": Color("54baff"), "yellow": Color("ffd45b"),
	"green": Color("88df69"), "purple": Color("be8af9"), "white": Color("fff3d9"),
}
const MAX_EFFECTS := 40
const MAX_PARTICLES := 220
const MAX_PROJECTILES := 4
const MAX_LIFETIME := 2.8
## Baseline pixels, before the owner's uniform 1440 × 2560 scale. The former
## 8-pixel shot read as a stray bead; this 36-pixel shell is deliberate ammunition.
const PROJECTILE_RADIUS := 18.0
const PROJECTILE_TRAIL_LENGTH := 96.0
const PROJECTILE_TRAIL_SAMPLES := 16
## Presentation completion contract. Only the outcome modal may wait for this;
## authoritative victory, progress saving and unlocks must remain immediate.
const DRAGON_DEFEAT_DURATION := 1.60
const DRAGON_DEFEAT_HIT_STOP := 0.10
const DRAGON_DEFEAT_FALL_START := 0.42
const DRAGON_DEFEAT_LANDING_TIME := 0.92
const DRAGON_DEFEAT_SETTLE_END := 1.16
const DRAGON_DEFEAT_FADE_START := 1.30
const GOLD := Color("ffce65")
const IVORY := Color("fff7d9")
const INK := Color("854124")

@export var auto_advance := true
var reduced_motion := false
var _paused := false
var _backgrounded := false
var _speed := 1.0
var _clock := 0.0
var _simulation_us := 0
var _synced := false
var _run_id := -1
var _last_sequence := -1
var _terminal := false
var _effects: Array[Dictionary] = []
var _projectiles: Array[Dictionary] = []
var _recoil_age := 9.0
var _hit_age := 9.0
var _dragon_defeat_age := -1.0
var _knockback_pixels := Vector2.ZERO
var _charge := 0.0
var _charge_color := GOLD
var _accepted := 0
var _dropped := 0
var _layout := {
	"segment_mode": false, "cannon_muzzle": Vector2(466, 909), "cannon_center": Vector2(472, 950),
	"dragon_hit": Vector2(300, 184), "dragon_foot": null, "nest": Vector2(467, 1074),
	"cell_points": {}, "board_origin": Vector2(147.25, 324.25), "cell_size": Vector2(19.1, 18.5),
	"rescue_center": Vector2(829, 163), "route_direction": Vector2.RIGHT,
	"route_units_to_pixels": 1.0,
	"stock_points": {"red": Vector2(404, 1007), "blue": Vector2(585, 966),
		"yellow": Vector2(657, 966), "green": Vector2(729, 966),
		"purple": Vector2(801, 966), "white": Vector2(873, 966)},
	"slot_points": [Vector2(144, 1215), Vector2(306, 1215), Vector2(468, 1215), Vector2(630, 1215), Vector2(792, 1215)],
	"tool_points": {"extra_slot": Vector2(201, 1569), "shuffle": Vector2(380, 1569),
		"recall": Vector2(559, 1569), "scout": Vector2(738, 1569)},
	"protected_rects": [Rect2(16, 10, 800, 89), Rect2(417, 987, 115, 46), Rect2(548, 984, 365, 36),
		Rect2(83, 1250, 122, 43), Rect2(245, 1250, 122, 43), Rect2(407, 1250, 122, 43),
		Rect2(569, 1250, 122, 43), Rect2(731, 1250, 122, 43), Rect2(233, 1603, 33, 33),
		Rect2(412, 1603, 33, 33), Rect2(591, 1603, 33, 33), Rect2(770, 1603, 33, 33)],
}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	size = Vector2(940, 1672)
	clip_contents = true
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_backgrounded = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_backgrounded = false

## All positions are centers in the FX node's LOCAL baseline coordinates.
## This copies context and never holds actor or simulation references.
func set_layout(context: Dictionary) -> void:
	for key in context:
		if _layout.has(key):
			_layout[key] = context[key].duplicate(true) if context[key] is Dictionary or context[key] is Array else context[key]
	if context.get("dragon_hit") is Vector2:
		for shot in _projectiles:
			shot.to = context.dragon_hit
	queue_redraw()

func set_paused(value: bool) -> void:
	_paused = value

func set_backgrounded(value: bool) -> void:
	_backgrounded = value

func set_reduced_motion(value: bool) -> void:
	if reduced_motion == value:
		return
	reduced_motion = value
	if value:
		_effects.clear()
		_recoil_age = 9.0
		_hit_age = 9.0
	queue_redraw()

## Restart and teardown invalidate all old poses, projectiles, particles and IDs.
func reset_for_run(run_id: int) -> void:
	_run_id = run_id
	_last_sequence = -1
	_terminal = false
	_synced = false
	_simulation_us = 0
	_clock = 0.0
	_speed = 1.0
	_paused = false
	_charge = 0.0
	_effects.clear()
	_projectiles.clear()
	_recoil_age = 9.0
	_hit_age = 9.0
	_dragon_defeat_age = -1.0
	_knockback_pixels = Vector2.ZERO
	queue_redraw()

## Call once after Rules.update(), before consume_events(). No supplied object is modified.
## The snapshot is also enough to update charge; no charge-up delay is introduced.
func sync_snapshot(snapshot: Dictionary) -> void:
	var run: int = int(snapshot.get("run_id", _run_id))
	if run < _run_id:
		return
	if run != _run_id:
		reset_for_run(run)
	_simulation_us = maxi(0, int(snapshot.get("time_us", _simulation_us)))
	_synced = true
	_paused = bool(snapshot.get("paused", false))
	_speed = clampf(float(snapshot.get("speed_multiplier", 1.0)), 1.0, 2.0)
	var state: String = str(snapshot.get("status", "running"))
	_terminal = state in ["victory", "defeat", "load_error"]
	if _terminal:
		_charge = 0.0
	else:
		var stock:Dictionary=snapshot.get("inventory",{})
		_charge=0.0
		for segment in snapshot.get("segments",[]):
			if int(segment.get("hp",0))>0 and int(stock.get(segment.color,0))>0:
				set_cannon_charge(1.0,str(segment.color));break
	queue_redraw()

func set_cannon_charge(ratio: float, color_id: String) -> void:
	_charge = clampf(ratio, 0.0, 1.0) if is_finite(ratio) else 0.0
	_charge_color = _color(color_id)
	queue_redraw()

func consume_events(events: Array, context: Dictionary = {}) -> int:
	if not context.is_empty():
		set_layout(context)
	var count := 0
	for event in events:
		if event is Dictionary and consume_event(event):
			count += 1
	return count

## Authoritative event envelope required. Old runs and duplicate sequences are ignored.
## Return true means an event was understood, NOT that gameplay succeeded.
func consume_event(event: Dictionary, context: Dictionary = {}) -> bool:
	if not event.has("type") or not event.has("run_id") or not event.has("sequence"):
		return false
	var run: int = int(event.run_id)
	var sequence: int = int(event.sequence)
	if run < _run_id or (run == _run_id and sequence <= _last_sequence):
		_dropped += 1
		return false
	if run > _run_id:
		reset_for_run(run)
	_last_sequence = sequence
	if not context.is_empty():
		set_layout(context)
	var kind: String = str(event.type)
	var color: Color = _color(str(event.get("color", "yellow")))
	var seed_value: int = run * 1000003 + sequence * 7919
	var origin := _event_point(event)
	match kind:
		"level_loaded":
			pass
		"pause_changed":
			set_paused(bool(event.get("paused", false)))
			_speed = clampf(float(event.get("speed_multiplier", 1.0)), 1.0, 2.0)
		"speed_changed":
			_speed = clampf(float(event.get("speed_multiplier", 1.0)), 1.0, 2.0)
		"team_selected":
			var point := _slot_point(int(event.get("slot", -1)))
			_ring(point, color, 34.0, 0.38)
			_burst(point, color, 7, "spark", seed_value, 90.0, 0.48)
		"ant_dispatched":
			_burst(_layout.nest, color, 3, "dust", seed_value, 28.0, 0.32)
		"bead_picked_up":
			# One local contact puff on the authoritative pickup, not a new hit
			# mechanic. No persistent ring or overlapping multicolor explosion.
			_burst(origin, IVORY, 3, "contact", seed_value, 14.0, 0.20)
		"bead_delivered":
			var stocks: Dictionary = _layout.stock_points
			var stock: Vector2 = stocks.get(str(event.get("color", "")), _layout.cannon_center)
			_flight_spark(_layout.nest, stock, color, seed_value)
			_ring(stock, color, 16.0, 0.38)
		"cannon_fired":
			_fire(event, color, seed_value)
		"segment_hit":
			_remove_projectile(int(event.get("projectile_id",event.get("id",-1))))
			_hit_age=0.0
			_add_effect({"kind":"impact","pos":_layout.dragon_hit,"color":color,"radius":35.0,"life":.24})
			_burst(_layout.dragon_hit,GOLD,5,"spark",seed_value,90.0,.35)
		"segment_removed":
			_burst(_layout.dragon_hit,color,10,"shard",seed_value,105.0,.55)
			_burst(_layout.dragon_hit,IVORY,3,"contact",seed_value+1,20.0,.24)
		"projectile_refunded":
			_remove_projectile(int(event.get("projectile_id",event.get("id",-1))))
		"armor_broken":
			_remove_projectile(int(event.get("id", -1)))
			_hit_age = 0.0
			var distance: float = clampf(float(event.get("applied_knockback", 0.0)) * float(_layout.route_units_to_pixels), 0.0, 36.0)
			var direction: Vector2 = _layout.route_direction
			# Main already positioned the dragon at dragon_after. Start at the old visual
			# position, then decay this residual to zero; never add a second knockback.
			_knockback_pixels = direction.normalized() * distance
			var impact: Vector2 = _layout.dragon_hit + (_knockback_pixels if not reduced_motion else Vector2.ZERO)
			_add_effect({"kind": "impact", "pos": impact, "color": color, "radius": 54.0, "life": 0.42})
			_burst(impact, color, 15, "shard", seed_value, 164.0, 0.85)
			_burst(impact, GOLD, 8, "spark", seed_value + 1, 105.0, 0.48)
		"armor_changed":
			pass # The actor view swaps armor. No state transitions happen in FX.
		"blocked_changed":
			if bool(event.get("blocked", false)):
				_tool_hint("shuffle", seed_value)
				_tool_hint("recall", seed_value + 1)
		"victory":
			_terminal = true
			_charge = 0.0
			_projectiles.clear()
			# Only presentation follows this clock. Victory/save processing never waits.
			if _dragon_defeat_age < 0.0:
				_dragon_defeat_age = 0.0
				if not _layout.segment_mode:_dragon_landing_dust(seed_value + 3)
				_ring(_layout.rescue_center, GOLD, 58.0, 0.75)
				_burst(_layout.rescue_center, GOLD, 46, "confetti", seed_value, 150.0, 2.4)
		"defeat", "load_error":
			_terminal = true
			_charge = 0.0
			_projectiles.clear()
			_ring(_layout.dragon_hit, Color("e99062"), 29.0, 0.5)
		"recoverable_error":
			set_paused(true)
			_projectiles.clear()
		"target_reserved", "slot_released", "dragon_started", "team_work_state", "color_clicked", "bead_unloading":
			pass # Avoid duplicated debit/pickup cues and per-ant visual noise.
		_:
			return false
	_accepted += 1
	queue_redraw()
	return true

## Call accepted=true once for an accepted authoritative tool_used event in the owner;
## this generic event consumer does not duplicate that cue or consume the tool.
## Rejected/preview actions use accepted=false and only outline their own icon.
## target is optional: a slot for extra_slot/recall, a bead center for scout.
func play_tool(tool_id: String, accepted: bool = false, target: Variant = null) -> bool:
	var aliases := {"plus": "extra_slot", "hint": "scout"}
	var tool: String = str(aliases.get(tool_id, tool_id))
	var points: Dictionary = _layout.tool_points
	if not points.has(tool) or _is_suspended():
		return false
	var point: Vector2 = points[tool]
	var color := GOLD if accepted else Color("eed9a4")
	var destination: Vector2 = target if target is Vector2 else point
	var seed_value := _run_id * 101 + int(_clock * 1000.0) + tool.hash()
	# A rejected/preview action only outlines its own icon. No target or success cue.
	if not accepted:
		_ring(point, color, 34.0, 0.42)
		queue_redraw()
		return true
	match tool:
		"extra_slot":
			_ring(destination, Color("9cebb8"), 39.0, 0.55)
			_burst(destination, Color("9cebb8"), 10, "spark", seed_value, 92.0, 0.65)
			_add_effect({"kind": "plus", "pos": destination, "color": IVORY, "life": 0.55})
		"shuffle":
			_add_effect({"kind": "swirl", "pos": destination, "color": Color("88deff"), "life": 0.65})
			_burst(destination, Color("88deff"), 8, "spark", seed_value, 75.0, 0.6)
		"recall":
			_flight_spark(destination, point, Color("c6a3ff"), seed_value)
			_add_effect({"kind": "recall", "pos": destination, "color": Color("c6a3ff"), "life": 0.65})
		"scout":
			_add_effect({"kind": "scout", "pos": destination, "color": GOLD, "life": 0.95})
			_burst(destination, IVORY, 6, "spark", seed_value, 30.0, 0.5)
	queue_redraw()
	return true

## Manual deterministic clock for tests/replays. Do not call this when auto_advance=true.
## Large deltas expire effects, rather than queueing a delayed animation backlog.
func advance(real_delta: float) -> void:
	if _is_suspended() or not is_finite(real_delta) or real_delta <= 0.0:
		return
	var step := minf(real_delta, 60.0) * (_speed if not _terminal else 1.0)
	_clock += step
	_recoil_age += step
	# A fatal hit holds only the dragon's existing impact pose, never the game,
	# particles, cannon, persistence or ordinary 0.48-second nonfatal hit clock.
	var hit_step := step
	if _dragon_defeat_age >= 0.0 and _dragon_defeat_age < DRAGON_DEFEAT_HIT_STOP:
		hit_step -= minf(step, DRAGON_DEFEAT_HIT_STOP - _dragon_defeat_age)
	_hit_age += hit_step
	if _dragon_defeat_age >= 0.0:
		_dragon_defeat_age = minf(_dragon_defeat_age + step, DRAGON_DEFEAT_DURATION)
	for index in range(_effects.size() - 1, -1, -1):
		_effects[index].age += step
		if float(_effects[index].age) >= float(_effects[index].life):
			_effects.remove_at(index)
	for index in range(_projectiles.size() - 1, -1, -1):
		_projectiles[index].age += step
		if float(_projectiles[index].age) > float(_projectiles[index].duration) + 0.25:
			_projectiles.remove_at(index)
	queue_redraw()

## Apply relative to your BASE actor transform each frame, never add cumulatively.
func cannon_pose() -> Dictionary:
	var offset := Vector2.ZERO
	var rotation_value := 0.0
	var stretch := Vector2.ONE
	if not reduced_motion and _recoil_age < 0.34:
		# Fast mechanical kick, one small spring return, exact rest at 0.34s.
		# This curve only poses the cannon; firing is never held for anticipation.
		var age := maxf(0.0, _recoil_age)
		var kick := smoothstep(0.0, 0.045, age) if age < 0.045 else 0.0
		if age >= 0.045:
			var p := clampf((age - 0.045) / 0.295, 0.0, 1.0)
			kick = cos(p * PI * 1.5) * pow(1.0 - p, 2.0)
		var axis: Vector2 = (_layout.cannon_muzzle - _layout.cannon_center).normalized()
		offset = -axis * kick * 11.0
		rotation_value = -0.035 * kick
		stretch = Vector2(1.0 + kick * 0.035, 1.0 - kick * 0.05)
	return {"offset": offset, "rotation": rotation_value, "scale": stretch}

## Render relative to the current authoritative dragon_after position.
## Ordinary hit motion/tint restore after 0.48 seconds. Victory adds a readable
## grounded outer pose lasting DRAGON_DEFEAT_DURATION active real seconds.
## The owner uses defeat_age for localized anatomy collapse, not whole-card tipping.
## defeat_complete may gate ONLY the outcome modal, never victory or saving.
func dragon_pose() -> Dictionary:
	var offset := Vector2.ZERO
	var rotation_value := 0.0
	var stretch := Vector2.ONE
	var tint := Color.WHITE
	if _hit_age < 0.48:
		var p := clampf(_hit_age / 0.48, 0.0, 1.0)
		tint = Color("fff0c5").lerp(Color.WHITE, minf(1.0, p * 3.0))
		if not reduced_motion:
			offset = _knockback_pixels * pow(1.0 - p, 3.0)
			rotation_value = sin(p * PI) * 0.025 * (1.0 - p)
	var complete := _dragon_defeat_age >= DRAGON_DEFEAT_DURATION
	if _dragon_defeat_age >= 0.0:
		if not reduced_motion:
			var collapse := _dragon_collapse_pose(_dragon_defeat_age)
			offset += collapse.offset
			rotation_value += collapse.rotation
			stretch = collapse.scale
		# The body stays opaque throughout the fall, impact and settling. Fade is
		# only the small conclusion, shared by reduced motion without alpha jumps.
		tint.a = 1.0 - smoothstep(DRAGON_DEFEAT_FADE_START, DRAGON_DEFEAT_DURATION, _dragon_defeat_age)
	return {"offset": offset, "rotation": rotation_value, "scale": stretch, "modulate": tint,
		"visible": not complete, "defeat_complete": complete,
		"defeat_age": _dragon_defeat_age, "defeat_phase": _dragon_defeat_phase()}

func _dragon_collapse_pose(age: float) -> Dictionary:
	var offset := Vector2.ZERO
	var rotation_value := 0.0
	var stretch := Vector2.ONE
	if age >= DRAGON_DEFEAT_SETTLE_END:
		offset.y = 3.0
		rotation_value = 0.035
	elif age >= DRAGON_DEFEAT_LANDING_TIME:
		var p := clampf((age - DRAGON_DEFEAT_LANDING_TIME) / (DRAGON_DEFEAT_SETTLE_END - DRAGON_DEFEAT_LANDING_TIME), 0.0, 1.0)
		var press := sin(p * PI)
		offset.y = 3.0 + 1.5 * press
		rotation_value = lerpf(0.045, 0.035, smoothstep(0.0, 1.0, p))
		stretch = Vector2(1.0 + 0.01 * press, 1.0 - 0.025 * press)
	elif age >= DRAGON_DEFEAT_FALL_START:
		var p := clampf((age - DRAGON_DEFEAT_FALL_START) / (DRAGON_DEFEAT_LANDING_TIME - DRAGON_DEFEAT_FALL_START), 0.0, 1.0)
		# Keep the full sprite grounded. The owner supplies localized body/head/
		# wing/leg deformation from defeat_age, not a large whole-card rotation.
		offset.y = lerpf(0.5, 3.0, p * p)
		rotation_value = lerpf(0.012, 0.045, p * p)
	elif age >= DRAGON_DEFEAT_HIT_STOP:
		var p := smoothstep(DRAGON_DEFEAT_HIT_STOP, DRAGON_DEFEAT_FALL_START, age)
		offset.y = 0.5 * p
		rotation_value = 0.012 * p - 0.018 * sin(p * PI)
	return {"offset": offset, "rotation": rotation_value, "scale": stretch}

func _dragon_defeat_phase() -> String:
	if _dragon_defeat_age < 0.0: return "none"
	if _dragon_defeat_age < DRAGON_DEFEAT_HIT_STOP: return "hit_stop"
	if _dragon_defeat_age < DRAGON_DEFEAT_FALL_START: return "stagger"
	if _dragon_defeat_age < DRAGON_DEFEAT_LANDING_TIME: return "fall"
	if _dragon_defeat_age < DRAGON_DEFEAT_SETTLE_END: return "landing"
	if _dragon_defeat_age < DRAGON_DEFEAT_FADE_START: return "rest"
	if _dragon_defeat_age < DRAGON_DEFEAT_DURATION: return "fade"
	return "complete"

## One pre-seeded, delayed local dust record. Its absolute age makes landing
## frame-partition independent; skipped/oversized frames never replay a burst.
func _dragon_landing_dust(seed_value: int) -> void:
	if reduced_motion:
		return
	var count := mini(10, maxi(0, MAX_PARTICLES - _particle_count()))
	if count <= 0:
		return
	var foot: Vector2 = _layout.dragon_foot if _layout.dragon_foot is Vector2 else _layout.dragon_hit + Vector2(-40, 62)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var particles: Array[Dictionary] = []
	for i in range(count):
		var side := -1.0 if i % 2 == 0 else 1.0
		particles.append({"offset": Vector2(side * rng.randf_range(6.0, 36.0), rng.randf_range(-2.0, 2.0)),
			"velocity": Vector2(side * rng.randf_range(24.0, 48.0), rng.randf_range(-16.0, -6.0)),
			"gravity": Vector2.ZERO, "radius": rng.randf_range(7.0, 11.0), "spin": 0.0,
			"angle": 0.0, "phase": 0.0, "color": Color("d9be8b")})
	_add_effect({"kind": "landing_dust", "pos": foot + Vector2(55, 7), "color": Color("d9be8b"),
		"life": DRAGON_DEFEAT_DURATION, "delay": DRAGON_DEFEAT_LANDING_TIME, "particles": particles})

func debug_snapshot() -> Dictionary:
	return {"run_id": _run_id, "last_sequence": _last_sequence, "clock": _clock,
		"paused": _is_suspended(), "effects": _effects.duplicate(true),
		"projectiles": _projectiles.duplicate(true), "particle_count": _particle_count(),
		"charge": _charge, "accepted": _accepted, "dropped": _dropped,
		"cannon_pose": cannon_pose(), "dragon_pose": dragon_pose()}

func _is_suspended() -> bool:
	return _paused or _backgrounded or (is_inside_tree() and get_tree().paused)

func _color(color_id: String) -> Color:
	return PALETTE.get(color_id, GOLD)

func _slot_point(index: int) -> Vector2:
	var points: Array = _layout.slot_points
	return points[index] if index >= 0 and index < points.size() else _layout.nest

func _event_point(event: Dictionary) -> Vector2:
	var path: Array = event.get("path", [])
	if not path.is_empty():
		var cell: Variant = path[-1]
		if cell is Array and cell.size() >= 2:
			var key:="%d,%d"%[int(cell[0]),int(cell[1])]
			if _layout.cell_points.has(key):return _layout.cell_points[key]
			return _layout.board_origin + Vector2(float(cell[0]), float(cell[1])) * _layout.cell_size
	return _layout.nest

func _fire(event: Dictionary, color: Color, seed_value: int) -> void:
	_recoil_age = 0.0
	_charge = 0.0
	var muzzle: Vector2 = _layout.cannon_muzzle
	var aim: Vector2 = (_layout.dragon_hit - muzzle).normalized()
	_add_effect({"kind": "muzzle", "pos": muzzle, "color": color, "life": 0.20, "angle": aim.angle()})
	_ring(muzzle, GOLD, 33.0, 0.32)
	_burst(muzzle, Color("c7ad86"), 7, "smoke", seed_value, 28.0, 0.62)
	_burst(muzzle, GOLD, 8, "spark", seed_value + 2, 110.0, 0.37)
	if _projectiles.size() >= MAX_PROJECTILES:
		_projectiles.pop_front()
	var duration: float = clampf(float(int(event.get("hit_us", 600000)) - int(event.get("fire_us", 0))) / 1000000.0, 0.05, 8.0)
	_projectiles.append({"id": int(event.get("id", -1)), "from": muzzle, "to": _layout.dragon_hit,
		"color": color, "armor_id": str(event.get("armor_id", "")), "fire_us": int(event.get("fire_us", 0)), "hit_us": int(event.get("hit_us", 600000)),
		"duration": duration, "age": 0.0})

func _remove_projectile(id: int) -> void:
	for index in range(_projectiles.size() - 1, -1, -1):
		if int(_projectiles[index].id) == id:
			_projectiles.remove_at(index)

func _tool_hint(tool: String, seed_value: int) -> void:
	var points: Dictionary = _layout.tool_points
	if points.has(tool):
		_ring(points[tool], GOLD, 39.0, 0.8)
		_burst(points[tool] + Vector2(0, -39), GOLD, 3, "spark", seed_value, 14.0, 0.75)

func _ring(point: Vector2, color: Color, radius: float, life: float) -> void:
	_add_effect({"kind": "ring", "pos": point, "color": color, "radius": radius, "life": life})

func _flight_spark(from: Vector2, to: Vector2, color: Color, seed_value: int) -> void:
	if reduced_motion:
		_burst(to, color, 3, "spark", seed_value, 0.0, 0.4)
	else:
		_add_effect({"kind": "transfer", "pos": from, "to": to, "color": color, "life": 0.42})

func _particle_count() -> int:
	var count := 0
	for effect in _effects:
		count += (effect.get("particles", []) as Array).size()
	return count

func _add_effect(effect: Dictionary) -> void:
	if _effects.size() >= MAX_EFFECTS:
		_effects.pop_front()
	effect["age"] = 0.0
	effect["life"] = clampf(float(effect.get("life", 0.4)), 0.05, MAX_LIFETIME)
	_effects.append(effect)

func _burst(point: Vector2, color: Color, count: int, kind: String, seed_value: int, speed: float, life: float) -> void:
	if reduced_motion:
		if kind in ["dust", "smoke", "contact"]:
			return
		count = mini(count, 4)
		kind = "spark"
		speed = 0.0
		life = minf(life, 0.55)
	var available := maxi(0, MAX_PARTICLES - _particle_count())
	count = mini(count, available)
	if count <= 0:
		_dropped += 1
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var particles: Array[Dictionary] = []
	for i in range(count):
		var angle := rng.randf_range(-PI, PI)
		var velocity := Vector2.from_angle(angle) * speed * rng.randf_range(0.35, 1.0)
		var acceleration := Vector2.ZERO
		var tint := color
		var radius := rng.randf_range(2.2, 5.5)
		var spawn := Vector2.from_angle(angle) * rng.randf_range(2.0, 9.0)
		if kind == "confetti":
			velocity = Vector2(rng.randf_range(-speed, speed), rng.randf_range(-speed * 1.45, -speed * 0.4))
			acceleration = Vector2(0, 150)
			tint = PALETTE.values()[i % PALETTE.size()]
			radius = rng.randf_range(3.5, 7.0)
		elif kind == "shard":
			acceleration = Vector2(0, 190)
			radius = rng.randf_range(6.0, 11.5)
		elif kind == "smoke":
			velocity = Vector2(velocity.x, -absf(velocity.y) - 16.0)
			radius = rng.randf_range(6.0, 12.0)
		elif kind == "dust":
			velocity.y = -absf(velocity.y)
		elif kind == "contact":
			velocity.y = -absf(velocity.y) - 4.0
			radius = rng.randf_range(2.5, 4.0)
			spawn *= 0.35
		if reduced_motion:
			spawn *= 2.0
		particles.append({"offset": spawn, "velocity": velocity, "gravity": acceleration,
			"radius": radius, "spin": 0.0 if reduced_motion else rng.randf_range(-5.0, 5.0), "angle": angle, "color": tint,
			"phase": rng.randf_range(0.0, TAU)})
	_add_effect({"kind": kind, "pos": point, "color": color, "life": life, "particles": particles})

func _can_draw(point: Vector2, radius: float = 0.0) -> bool:
	if not Rect2(Vector2.ZERO, size).grow(radius).has_point(point):
		return false
	var bounds := Rect2(point - Vector2.ONE * radius, Vector2.ONE * maxf(1.0, radius * 2.0))
	for rect in _layout.protected_rects:
		if rect is Rect2 and rect.intersects(bounds):
			return false
	return true

## A trail segment can cross a label even when both ends are outside it.
## Conservative whole-segment culling keeps the larger ammunition off HUD text.
func _can_draw_segment(from: Vector2, to: Vector2, padding: float) -> bool:
	var bounds := Rect2(from, Vector2.ZERO).expand(to).grow(padding)
	if not Rect2(Vector2.ZERO, size).intersects(bounds):
		return false
	for rect in _layout.protected_rects:
		if rect is Rect2 and rect.intersects(bounds):
			return false
	return true

func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0) * color.a)

func _draw() -> void:
	_draw_charge()
	for effect in _effects:
		_draw_effect(effect)
	for shot in _projectiles:
		_draw_projectile(shot)
	_draw_defeat_stars()

func _draw_defeat_stars() -> void:
	if _layout.segment_mode:return
	# A brief local defeated cue, not another health indicator or a screen flash.
	if _dragon_defeat_age < .25 or _dragon_defeat_age >= DRAGON_DEFEAT_DURATION:return
	var opacity:=smoothstep(.25,.42,_dragon_defeat_age)*(1.0-smoothstep(1.30,1.60,_dragon_defeat_age))
	var slump:=0.0 if reduced_motion else smoothstep(.10,.92,_dragon_defeat_age)
	var center:Vector2=_layout.dragon_hit+Vector2(63,-83+34*slump)
	var orbit:=0.0 if reduced_motion else (_dragon_defeat_age-.25)*3.8
	var ring:=PackedVector2Array()
	for i in range(25):
		var a:=float(i)/24.0*TAU;ring.append(center+Vector2(cos(a)*25,sin(a)*6))
	draw_polyline(ring,_alpha(GOLD,opacity*.65),1.7,true)
	for i in range(3):
		var a:=orbit+float(i)*TAU/3.0
		var point:=center+Vector2(cos(a)*25,sin(a)*6)
		_draw_star(point,7.2,_alpha(INK,opacity*.7),a*.25)
		_draw_star(point+Vector2(0,-1),5.7,_alpha(GOLD,opacity),a*.25)

func _draw_charge() -> void:
	if _charge <= 0.01 or _terminal:
		return
	var center: Vector2 = _layout.cannon_muzzle
	if not _can_draw(center, 31):
		return
	var orbit := 0.0 if reduced_motion else _clock * 1.2
	var breath := 1.0 if reduced_motion else 0.95 + 0.05 * sin(_clock * 4.0)
	# Color gathers inside the barrel, not in a second health/cooldown meter.
	draw_circle(center, 28.0 * breath, _alpha(_charge_color, 0.045 * _charge))
	draw_circle(center, 20.0, _alpha(_charge_color, 0.10 * _charge))
	draw_circle(center - Vector2(1, 2), 11.0 + _charge * 3.0, _alpha(IVORY, 0.12 * _charge))
	draw_arc(center, 23.0, 0, TAU, 40, _alpha(INK, 0.20), 4.0, true)
	draw_arc(center, 23.0, -PI * 0.5, -PI * 0.5 + TAU * _charge, 40, _alpha(_charge_color, 0.85), 3.4, true)
	draw_arc(center, 21.0, -PI * 0.5, -PI * 0.5 + TAU * _charge, 40, _alpha(IVORY, 0.50 * _charge), 1.0, true)
	for i in range(3):
		var phase := orbit + i * TAU / 3.0
		var point := center + Vector2.from_angle(phase) * (25.0 - 6.0 * _charge)
		draw_circle(point, 4.0, _alpha(_charge_color, 0.25 * _charge))
		_draw_star(point, 2.0 + 2.0 * _charge, _alpha(IVORY, 0.35 + _charge * 0.5), phase)

func _draw_effect(effect: Dictionary) -> void:
	var delay: float = float(effect.get("delay", 0.0))
	var age: float = float(effect.age) - delay
	if age < 0.0:
		return
	var p: float = clampf(age / (float(effect.life) - delay), 0.0, 1.0)
	var fade := pow(1.0 - p, 1.3)
	var point: Vector2 = effect.pos
	var tint: Color = effect.color
	var kind: String = effect.kind
	if effect.has("particles"):
		for particle in effect.particles:
			_draw_particle(particle, point, kind, age, p)
		return
	match kind:
		"ring":
			var radius: float = float(effect.radius) * (0.82 if reduced_motion else 0.35 + 0.65 * (1.0 - pow(1.0 - p, 3.0)))
			if _can_draw(point, radius + 3):
				draw_arc(point, radius, 0, TAU, 40, _alpha(tint, fade * 0.7), 2.5 * fade + 0.5, true)
		"muzzle":
			if not _can_draw(point, 47.0):
				return
			if reduced_motion:
				_draw_star(point, 8, _alpha(GOLD, fade * 0.6), 0)
			else:
				var angle: float = effect.angle
				var axis := Vector2.from_angle(angle)
				var side := axis.orthogonal()
				var length_value := 43.0 * (1.0 - p * 0.5)
				draw_circle(point + axis * 10, 27.0 * (1.0 - p * 0.35), _alpha(tint, fade * 0.11))
				var flame := PackedVector2Array([point - side * 13, point + axis * 20 - side * 9, point + axis * length_value, point + axis * 22 + side * 8, point + side * 13, point - axis * 5])
				draw_colored_polygon(flame, _alpha(tint.lerp(GOLD, 0.48), fade * 0.85))
				var core := PackedVector2Array([point - side * 7, point + axis * length_value * 0.78, point + side * 7, point - axis * 3])
				draw_colored_polygon(core, _alpha(IVORY, fade * 0.95))
				draw_arc(point, 15.0, angle - PI * 0.65, angle + PI * 0.65, 24, _alpha(GOLD, fade), 3.0, true)
		"impact":
			_draw_impact(point, tint, p)
		"transfer":
			var end: Vector2 = effect.to
			var pos := point.lerp(end, p) + Vector2(0, -sin(p * PI) * 24.0)
			if _can_draw(pos, 9):
				_draw_star(pos, 5.5, _alpha(tint, sin(p * PI)), p * PI)
				_draw_star(pos + Vector2(5, 8), 2.5, _alpha(IVORY, sin(p * PI) * 0.6), 0)
		"plus":
			if _can_draw(point, 18):
				var length_value := 9.0 if reduced_motion else 10.0 + sin(p * PI) * 5.0
				draw_line(point - Vector2(length_value, 0), point + Vector2(length_value, 0), _alpha(tint, fade), 4.0, true)
				draw_line(point - Vector2(0, length_value), point + Vector2(0, length_value), _alpha(tint, fade), 4.0, true)
		"swirl", "recall":
			if _can_draw(point, 40):
				var turns := 0.0 if reduced_motion else p * TAU
				for i in range(2 if kind == "swirl" else 1):
					var angle := turns + float(i) * PI
					draw_arc(point, 30.0, angle, angle + PI * 0.75, 22, _alpha(tint, fade), 3.0, true)
					var tip := point + Vector2.from_angle(angle + PI * 0.75) * 30.0
					_draw_star(tip, 4.5, _alpha(IVORY, fade), angle)
		"scout":
			if _can_draw(point, 25):
				var radius := 16.0 if reduced_motion else 17.0 + sin(p * PI) * 6.0
				for i in range(4):
					var angle := float(i) * PI * 0.5 + PI * 0.25
					draw_arc(point, radius, angle - 0.22, angle + 0.22, 10, _alpha(tint, fade), 3.0, true)
				_draw_star(point + Vector2(0, -radius - 4), 4.0, _alpha(IVORY, fade), 0)

func _draw_particle(particle: Dictionary, origin: Vector2, kind: String, age: float, p: float) -> void:
	var point: Vector2 = origin + particle.offset + particle.velocity * age + particle.gravity * age * age * 0.5
	var radius: float = particle.radius
	var angle: float = particle.angle + particle.spin * age
	var fade := pow(1.0 - p, 1.4)
	var tint: Color = _alpha(particle.color, fade)
	if kind == "confetti":
		point.x += sin(age * 6.0 + float(particle.phase)) * 6.0 * p
	if not _can_draw(point, radius * 2.5):
		return
	match kind:
		"smoke":
			var expansion := radius * (0.7 + p * 1.8)
			draw_circle(point, expansion, _alpha(Color("856c53"), fade * 0.11))
			draw_circle(point - Vector2(expansion * 0.12, expansion * 0.16), expansion * 0.88, _alpha(Color("ddc9a8"), fade * 0.20))
			draw_circle(point - Vector2(expansion * 0.2, expansion * 0.25), expansion * 0.65, _alpha(IVORY, fade * 0.24))
		"dust":
			draw_circle(point, radius * (1.0 - p * 0.5), _alpha(tint, 0.28))
		"contact":
			var expansion := radius * (0.65 + p * 0.8)
			draw_circle(point, expansion * 1.35, _alpha(IVORY, fade * 0.18))
			draw_circle(point, expansion, _alpha(IVORY, fade * 0.72))
		"landing_dust":
			var expansion := radius * (0.7 + p * 0.8)
			draw_circle(point, expansion, _alpha(tint, 0.34))
			draw_circle(point - Vector2(1.0, expansion * 0.2), expansion * 0.62, _alpha(IVORY, fade * 0.19))
		"shard":
			# A bevel and lit face give each fragment thickness. The cosine only
			# rotates its face in depth; its ballistic position remains analytical.
			var face_width := 0.48 + 0.52 * absf(cos(age * float(particle.spin) + float(particle.phase)))
			var shape := PackedVector2Array([Vector2(-radius * 0.65, -radius), Vector2(radius * 0.8, -radius * 0.4), Vector2(radius * 0.35, radius), Vector2(-radius * 0.8, radius * 0.4)])
			for i in range(shape.size()):
				shape[i].x *= face_width
				shape[i] = point + shape[i].rotated(angle)
			var edge := PackedVector2Array()
			for vertex in shape:
				edge.append(vertex + Vector2(1.5, 2.5))
			draw_colored_polygon(edge, _alpha(INK, fade * 0.75))
			draw_polygon(shape, PackedColorArray([_alpha(particle.color.lerp(IVORY, 0.35), fade), tint, _alpha(particle.color.darkened(0.32), fade), tint]))
			draw_colored_polygon(PackedVector2Array([shape[0], shape[1], point]), _alpha(IVORY, fade * 0.20))
			draw_line(shape[0], shape[1], _alpha(IVORY, fade * 0.95), 1.8, true)
			draw_line(shape[1], shape[2], _alpha(GOLD, fade * 0.8), 1.4, true)
			draw_line(shape[2], shape[3], _alpha(INK, fade * 0.55), 1.5, true)
		"confetti":
			var width := radius * (0.35 + 0.65 * absf(sin(age * 7.0 + float(particle.phase))))
			var shape := PackedVector2Array([Vector2(-width, -radius), Vector2(width, -radius), Vector2(width, radius), Vector2(-width, radius)])
			for i in range(shape.size()):
				shape[i] = point + shape[i].rotated(angle)
			draw_colored_polygon(shape, tint)
			draw_line(shape[0], shape[1], _alpha(IVORY, fade * 0.5), 1.0, true)
		_:
			_draw_star(point, radius * (0.5 + 0.5 * fade), tint, angle)
			if radius > 3.8:
				draw_circle(point, radius * 0.28, _alpha(IVORY, fade))

func _draw_star(point: Vector2, radius: float, tint: Color, angle: float) -> void:
	var shape := PackedVector2Array()
	for i in range(8):
		shape.append(point + Vector2.from_angle(angle + float(i) * TAU / 8.0) * radius * (1.0 if i % 2 == 0 else 0.25))
	draw_colored_polygon(shape, tint)

func _draw_impact(point: Vector2, tint: Color, p: float) -> void:
	if not _can_draw(point, 58.0):
		return
	var fade := pow(1.0 - p, 1.6)
	if fade < .02:return # Avoid degenerate subpixel triangles at the effect tail.
	if reduced_motion:
		_draw_star(point, 11.0, _alpha(tint.lerp(IVORY, 0.4), fade * 0.7), PI * 0.25)
		return
	# One bounded compression/rebound at the hit point, not a full-screen flash.
	var radius := 12.0 + 40.0 * (1.0 - pow(1.0 - p, 4.0)) + sin(p * TAU) * 5.0 * (1.0 - p)
	draw_circle(point, radius * 0.88, _alpha(tint, fade * 0.09))
	draw_circle(point, radius * 0.55, _alpha(GOLD, fade * 0.09))
	draw_arc(point, radius, -PI * 0.88, PI * 0.02, 24, _alpha(GOLD, fade * 0.85), 3.0 * fade + 0.7, true)
	draw_arc(point, radius, PI * 0.12, PI * 1.02, 24, _alpha(tint.lerp(IVORY, 0.6), fade * 0.75), 2.2 * fade + 0.5, true)
	draw_arc(point, radius * 0.76, -PI * 0.6, PI * 0.45, 24, _alpha(IVORY, fade * 0.45), 1.4, true)
	var core_fade := pow(1.0 - p, 3.0)
	_draw_star(point, 22.0 * (1.0 - p * 0.55), _alpha(tint.lerp(GOLD, 0.35), core_fade * 0.85), PI * 0.12)
	_draw_star(point, 13.0 * (1.0 - p * 0.65), _alpha(IVORY, core_fade * 0.95), PI * 0.12)
	for i in range(6):
		var angle := float(i) * TAU / 6.0 + 0.18
		var axis := Vector2.from_angle(angle)
		var side := axis.orthogonal()
		var distance := 17.0 + (radius - 17.0) * 0.80
		var tip := point + axis * (distance + 8.0 * fade)
		var base := point + axis * distance
		draw_colored_polygon(PackedVector2Array([base - side * 2.2 * fade, tip, base + side * 2.2 * fade]), _alpha(GOLD, fade * 0.7))

func _shot_fraction(shot: Dictionary) -> float:
	if _synced:
		return float(_simulation_us - int(shot.fire_us)) / maxf(1.0, float(int(shot.hit_us) - int(shot.fire_us)))
	return float(shot.age) / float(shot.duration)

func _shot_position(shot: Dictionary, fraction: float) -> Vector2:
	var start: Vector2 = shot.from
	var end: Vector2 = shot.to
	# Explicit endpoints avoid floating-point sine residue. This same path is
	# sampled by the shell and its trail; neither can overrun an authoritative hit.
	if fraction <= 0.0:
		return start
	if fraction >= 1.0:
		return end
	var bow := minf(25.0, start.distance_to(end) * 0.06)
	return start.lerp(end, fraction) + Vector2(sin(fraction * PI) * -bow, 0.0)

func _shot_tangent(shot: Dictionary, fraction: float) -> Vector2:
	var direction: Vector2 = shot.to - shot.from
	var bow := minf(25.0, direction.length() * 0.06)
	direction.x -= bow * PI * cos(clampf(fraction, 0.0, 1.0) * PI)
	return direction.normalized() if direction.length_squared() > 0.001 else Vector2.UP

func _shot_trail_fraction(shot: Dictionary, fraction: float) -> float:
	var distance: float = (shot.to as Vector2).distance_to(shot.from)
	# Derivative upper bound caps the actual curved ribbon at 96 baseline pixels,
	# independent of flight duration, speed multiplier, refresh rate or long frames.
	var speed_bound := distance + PI * minf(25.0, distance * 0.06)
	return minf(maxf(0.0, fraction), PROJECTILE_TRAIL_LENGTH / maxf(1.0, speed_bound))

func _draw_projectile_trail(shot: Dictionary, fraction: float) -> void:
	var span := _shot_trail_fraction(shot, fraction)
	if span <= 0.00001:
		return
	# A shot can become due a few microseconds before the render sample. Its
	# first ribbon would then be a wide, subpixel sliver that cannot triangulate.
	# Keep the shell visible; only reveal a trail once it has physical length.
	if _shot_position(shot, fraction).distance_squared_to(_shot_position(shot, fraction - span)) < 4.0:
		return
	var tint: Color = shot.color
	# Four feathered ribbons replace disconnected bead/dot afterimages. Vertex
	# alpha/width taper continuously to zero, so the tail has no hard square end.
	var widths := [18.0, 12.0, 8.0, 2.8]
	var opacity := [0.055, 0.12, 0.25, 0.60]
	for layer in range(widths.size()):
		var layer_color := tint.lerp(IVORY, 0.65) if layer == 3 else tint
		for i in range(PROJECTILE_TRAIL_SAMPLES):
			var u0 := float(i) / float(PROJECTILE_TRAIL_SAMPLES)
			var u1 := float(i + 1) / float(PROJECTILE_TRAIL_SAMPLES)
			var f0 := fraction - span * (1.0 - u0)
			var f1 := fraction - span * (1.0 - u1)
			var a := _shot_position(shot, f0)
			var b := _shot_position(shot, f1)
			if a.distance_squared_to(b) < 0.0625:
				continue
			var width0: float = float(widths[layer]) * pow(u0, 0.75)
			var width1: float = float(widths[layer]) * pow(u1, 0.75)
			if not _can_draw_segment(a, b, width1):
				continue
			var side0 := _shot_tangent(shot, f0).orthogonal() * width0
			var side1 := _shot_tangent(shot, f1).orthogonal() * width1
			var color0 := _alpha(layer_color, float(opacity[layer]) * u0)
			var color1 := _alpha(layer_color, float(opacity[layer]) * u1)
			if i == 0:
				draw_polygon(PackedVector2Array([a, b + side1, b - side1]), PackedColorArray([color0, color1, color1]))
			else:
				draw_polygon(PackedVector2Array([a + side0, b + side1, b - side1, a - side0]), PackedColorArray([color0, color1, color1, color0]))

func _draw_projectile_shell(point: Vector2, tint: Color, direction: Vector2) -> void:
	var radius := PROJECTILE_RADIUS
	# Brass rim, colored enamel, warm reflected underside, bright core and a
	# small specular catch. The colored surface remains readable for all six types.
	if _can_draw(point, radius * 1.55):
		draw_circle(point, radius * 1.55, _alpha(tint, 0.045))
		draw_circle(point, radius * 1.30, _alpha(tint, 0.10))
	if not _can_draw(point, radius + 3.5):
		return
	draw_circle(point + Vector2(1.4, 2.5), radius + 1.0, _alpha(INK, 0.50))
	draw_circle(point, radius, tint.darkened(0.55))
	draw_circle(point - Vector2(0.3, 0.5), radius - 1.1, GOLD.darkened(0.12))
	draw_circle(point, radius - 2.6, tint.darkened(0.20))
	draw_circle(point - Vector2(1.0, 1.8), radius - 3.5, tint)
	draw_arc(point, radius - 4.4, 0.10 * PI, 0.83 * PI, 24, _alpha(tint.darkened(0.42), 0.85), 3.0, true)
	draw_circle(point - Vector2(3.8, 4.6), 8.1, tint.lerp(IVORY, 0.42))
	draw_circle(point - Vector2(3.8, 4.8), 5.1, _alpha(IVORY, 0.86))
	draw_circle(point - Vector2(6.3, 7.8), 2.7, Color.WHITE)
	var angle := direction.angle()
	draw_arc(point, radius - 0.8, angle - 0.80, angle + 0.24, 18, _alpha(IVORY, 0.88), 1.5, true)
	draw_arc(point, radius - 0.8, angle + PI - 0.70, angle + PI + 0.40, 18, _alpha(GOLD, 0.9), 2.0, true)

func _draw_projectile(shot: Dictionary) -> void:
	var fraction := _shot_fraction(shot)
	if fraction < 0.0 or fraction > 1.0:
		return
	var point := _shot_position(shot, fraction)
	if not reduced_motion:
		_draw_projectile_trail(shot, fraction)
	_draw_projectile_shell(point, shot.color, _shot_tangent(shot, fraction))
