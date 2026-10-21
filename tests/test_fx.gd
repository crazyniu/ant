extends SceneTree
const FX = preload("res://scripts/rescue_fx.gd")
const Rules = preload("res://scripts/rescue_rules.gd")
var failures: Array[String] = []
var assertions := 0
var fx_nodes: Array[Control] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	assertions += 1
	if not value:
		failures.append(message)
		push_error(message)

func make_fx():
	var fx = FX.new()
	fx.auto_advance = false
	root.add_child(fx)
	fx.reset_for_run(1)
	fx_nodes.append(fx)
	return fx

func event(kind: String, sequence: int, fields: Dictionary = {}) -> Dictionary:
	var value := {"type": kind, "run_id": 1, "sequence": sequence, "time_us": sequence * 1000}
	value.merge(fields, true)
	return value

func test_event_dispatch_and_dedupe() -> void:
	var fx = make_fx()
	check(fx.mouse_filter == Control.MOUSE_FILTER_IGNORE, "FX never intercept pointer input")
	check(fx.focus_mode == Control.FOCUS_NONE, "FX never takes keyboard focus")
	check(fx.size == Vector2(940, 1672), "FX uses baseline coordinates without double scaling")
	var selected := event("team_selected", 1, {"color": "red", "slot": 2})
	var original := selected.duplicate(true)
	check(fx.consume_event(selected), "team_selected accepted")
	check(fx.debug_snapshot().particle_count == 7, "selection uses a small bounded sparkle cluster")
	check(not fx.consume_event(selected), "duplicate event sequence rejected")
	check(selected == original, "event dictionary is never mutated")
	check(not fx.consume_event(event("bead_picked_up", 0)), "out-of-order event rejected")
	check(not fx.consume_event({"type": "cannon_fired"}), "missing run/sequence rejected")
	var old_event := event("cannon_fired", 10, {"run_id": 0})
	check(not fx.consume_event(old_event), "stale run rejected")
	var inert_before: Dictionary = fx.debug_snapshot()
	check(fx.consume_event(event("target_reserved", 2)), "reservation event understood")
	check(fx.debug_snapshot().particle_count == inert_before.particle_count, "reservation does not replay pickup or debit effects")
	check(fx.consume_event(event("armor_changed", 3)), "armor_changed is presentation-safe")

func test_projectile_and_finite_pose() -> void:
	var fx = make_fx()
	var fired := event("cannon_fired", 1, {"id": 81, "fire_us": 0, "hit_us": 1000000, "color": "blue", "amount": 10})
	fx.consume_event(fired)
	check(fx.debug_snapshot().projectiles.size() == 1, "shot launches immediately, without waiting for charge/recoil")
	fx.set_layout({"dragon_hit": Vector2(350, 190)})
	check(fx.debug_snapshot().projectiles[0].to == Vector2(350, 190), "shot follows current locked armor center as dragon moves")
	fx.advance(0.06)
	check(fx.cannon_pose().offset.length() > 0.5, "cannon has bounded visible recoil")
	check(fx.cannon_pose().offset.length() <= 11.0, "cannon recoil bounded at 11 baseline pixels")
	fx.advance(0.3)
	check(fx.cannon_pose().offset == Vector2.ZERO and fx.cannon_pose().scale == Vector2.ONE, "cannon pose returns exactly to identity")
	fx.set_layout({"route_units_to_pixels": 2.0})
	fx.consume_event(event("armor_broken", 2, {"id": 81, "color": "blue", "dragon_before": 40.0, "dragon_after": 32.0, "applied_knockback": 8.0}))
	check(fx.debug_snapshot().projectiles.is_empty(), "only corresponding authoritative hit retires the visual shot early")
	check(fx.dragon_pose().offset == Vector2(16, 0), "dragon starts with old-to-new residual, not a second knockback")
	check(fx.debug_snapshot().effects[-3].pos == Vector2(366, 190), "impact burst meets the old visible position before settling")
	fx.advance(0.2)
	check(fx.dragon_pose().offset.x > 0.0 and fx.dragon_pose().offset.x < 16.0, "finite knockback residual decays")
	fx.advance(0.3)
	check(fx.dragon_pose().offset == Vector2.ZERO and fx.dragon_pose().rotation == 0.0 and fx.dragon_pose().modulate == Color.WHITE, "dragon transform/tint restore exactly")
	fx.consume_event(event("armor_broken", 3, {"applied_knockback": 10000.0}))
	check(fx.dragon_pose().offset.length() <= 36, "large rule-space knockback cannot make oversized visual motion")
	fx.advance(20.0)
	check(fx.debug_snapshot().effects.is_empty(), "all hit particles expire after long frame")

func test_pause_speed_and_background() -> void:
	var fx = make_fx()
	fx.consume_event(event("cannon_fired", 1))
	fx.advance(0.04)
	fx.set_paused(true)
	var before: Dictionary = fx.debug_snapshot()
	fx.advance(4.0)
	check(fx.debug_snapshot() == before, "explicit modal pause freezes every particle, shot and actor pose")
	fx.set_paused(false)
	fx.set_backgrounded(true)
	before = fx.debug_snapshot()
	fx.advance(4.0)
	check(fx.debug_snapshot() == before, "background suspension freezes presentation")
	fx.set_backgrounded(false)
	paused = true
	before = fx.debug_snapshot()
	fx.advance(4.0)
	check(fx.debug_snapshot() == before, "SceneTree pause also freezes manual advancement")
	paused = false
	fx.consume_event(event("speed_changed", 2, {"speed_multiplier": 2}))
	var clock_before: float = fx.debug_snapshot().clock
	fx.advance(0.1)
	check(is_equal_approx(fx.debug_snapshot().clock - clock_before, 0.2), "active presentation follows simulation speed once")
	fx.consume_event(event("pause_changed", 3, {"paused": true, "speed_multiplier": 1}))
	check(fx.debug_snapshot().paused, "rule pause event freezes visuals")
	fx.consume_event(event("pause_changed", 4, {"paused": false, "speed_multiplier": 1}))
	clock_before = fx.debug_snapshot().clock
	fx.advance(0.1)
	check(is_equal_approx(fx.debug_snapshot().clock - clock_before, 0.1), "resume restores x1 presentation speed")

func test_projectile_readability_and_authoritative_path() -> void:
	var fx = make_fx()
	fx.set_layout({"cannon_muzzle": Vector2(480, 918), "dragon_hit": Vector2(365, 210), "protected_rects": []})
	var fired := event("cannon_fired", 1, {"id": 41, "color": "purple", "fire_us": 200000, "hit_us": 800000})
	fx.consume_event(fired)
	var shot: Dictionary = fx.debug_snapshot().projectiles[0]
	check(FX.PROJECTILE_RADIUS == 18.0, "ammunition has a readable 36-baseline-pixel body, about 55 pixels at the 2K viewport")
	check(FX.PROJECTILE_TRAIL_LENGTH == 96.0 and FX.PROJECTILE_TRAIL_SAMPLES == 16, "soft ribbon geometry has fixed local length and sample budgets")
	check(fx._shot_position(shot, 0.0) == shot.from, "shot begins at the exact authoritative muzzle")
	check(fx._shot_position(shot, 1.0) == shot.to, "shot terminates exactly at the target without floating-point bow residue")
	check(fx._shot_position(shot, -0.4) == shot.from and fx._shot_position(shot, 1.4) == shot.to, "out-of-range geometry cannot overshoot muzzle or impact")
	for time_us in [200000, 350000, 500000, 650000, 800000]:
		fx.sync_snapshot({"run_id": 1, "time_us": time_us, "speed_multiplier": 2, "status": "running"})
		var fraction: float = fx._shot_fraction(shot)
		check(is_equal_approx(fraction, float(time_us - 200000) / 600000.0), "flight fraction is derived from authoritative fire/hit microseconds")
		var position: Vector2 = fx._shot_position(shot, fraction)
		fx.advance(0.01)
		check(fx._shot_position(shot, fx._shot_fraction(shot)) == position, "visual advancement at x2 cannot advance a synchronized projectile")
		var span: float = fx._shot_trail_fraction(shot, fraction)
		check(span >= 0.0 and span <= fraction, "trail never samples time before cannon fire")
		var total_length := 0.0
		var previous: Vector2 = fx._shot_position(shot, fraction - span)
		for sample in range(1, 65):
			var point: Vector2 = fx._shot_position(shot, fraction - span + span * float(sample) / 64.0)
			total_length += previous.distance_to(point)
			previous = point
		check(total_length <= FX.PROJECTILE_TRAIL_LENGTH + 0.01, "curved trail stays inside its 96-baseline-pixel length bound")
	check(fx.debug_snapshot().projectiles.size() == 1, "visual arrival never triggers its own hit, ammo debit or outcome")
	fx.consume_event(event("armor_broken", 2, {"id": 99, "color": "purple"}))
	check(fx.debug_snapshot().projectiles.size() == 1, "an unrelated hit cannot retire this shell")
	fx.consume_event(event("armor_broken", 3, {"id": 41, "color": "purple"}))
	check(fx.debug_snapshot().projectiles.is_empty(), "matching authoritative impact retires the shell")
	var effects: Array = fx.debug_snapshot().effects
	check(effects[-3].kind == "impact" and effects[-3].radius == 54.0 and effects[-3].life == 0.42, "elastic impact is one finite local record, not a fullscreen flash")
	check(effects[-2].particles.size() == 15, "beveled fragments keep the existing bounded shard count")
	var stationary := {"from": Vector2(200, 200), "to": Vector2(200, 200)}
	check(fx._shot_position(stationary, 0.5) == Vector2(200, 200) and fx._shot_tangent(stationary, 0.5) == Vector2.UP, "degenerate local layout stays finite without invented travel")

func test_cannon_spring_and_protected_ribbons() -> void:
	var fx = make_fx()
	fx.consume_event(event("cannon_fired", 1))
	var axis := (Vector2(466, 909) - Vector2(472, 950)).normalized()
	var saw_return := false
	for i in range(35):
		var pose: Dictionary = fx.cannon_pose()
		check(pose.offset.length() <= 11.001 and absf(pose.rotation) <= 0.0351, "every recoil sample obeys the existing mechanical motion envelope")
		if pose.offset.dot(axis) > 0.01:
			saw_return = true
		fx.advance(0.01)
	check(saw_return, "cannon has a small elastic return instead of a weak one-direction wobble")
	check(fx.cannon_pose().offset == Vector2.ZERO and fx.cannon_pose().scale == Vector2.ONE, "spring ends exactly at the original 0.34-second rest boundary")
	fx.set_layout({"protected_rects": [Rect2(200, 200, 40, 40)]})
	check(fx._can_draw(Vector2(175, 220), 5) and fx._can_draw(Vector2(265, 220), 5), "ribbon culling fixture keeps both endpoints outside the label")
	check(not fx._can_draw_segment(Vector2(175, 220), Vector2(265, 220), 5), "whole-ribbon bounds protect a label crossed between endpoints")
	check(not fx._can_draw(Vector2(215, 190), FX.PROJECTILE_RADIUS + 3.5), "larger shell is also culled against nearby protected text")
	check(fx._can_draw_segment(Vector2(100, 100), Vector2(180, 180), 5), "local ribbon outside protected text remains drawable")

func test_dragon_final_hit_and_reset() -> void:
	var fx = make_fx()
	check(FX.DRAGON_DEFEAT_DURATION == 1.60, "named defeat duration is the 1.60-second modal-only contract")
	check(fx.dragon_pose().visible and not fx.dragon_pose().defeat_complete, "dragon starts visible, without a completed defeat pose")
	fx.set_layout({"dragon_foot": Vector2(320, 270)})
	fx.consume_event(event("armor_broken", 1, {"applied_knockback": 8.0}))
	var impact_pose: Dictionary = fx.dragon_pose()
	var won := event("victory", 2)
	fx.consume_event(won)
	var pose: Dictionary = fx.dragon_pose()
	check(pose.visible and not pose.defeat_complete and pose.modulate.a == 1.0, "victory begins visibly instead of hiding the final hit")
	check(pose.offset == impact_pose.offset and pose.rotation == impact_pose.rotation and pose.scale == impact_pose.scale, "collapse starts continuously from the last armor hit")
	check(pose.defeat_phase == "hit_stop", "fatal hit begins with local hit-stop")
	var dust: Dictionary = {}
	for effect in fx.debug_snapshot().effects:
		if effect.kind == "landing_dust": dust = effect
	check(not dust.is_empty() and dust.pos == Vector2(375, 277), "landing dust is anchored to the actual foot pivot, not the armor center")
	check(dust.particles.size() == 10 and dust.delay == FX.DRAGON_DEFEAT_LANDING_TIME, "one bounded dust record is delayed until body contact")
	fx.advance(0.06)
	pose = fx.dragon_pose()
	check(pose.offset == impact_pose.offset and pose.rotation == impact_pose.rotation and pose.modulate == impact_pose.modulate, "hit-stop holds the existing body pose instead of freezing gameplay")
	fx.advance(0.20)
	pose = fx.dragon_pose()
	check(pose.defeat_phase == "stagger" and pose.modulate.a == 1.0, "body visibly loses balance before starting its fall")
	fx.advance(0.41)
	pose = fx.dragon_pose()
	check(pose.defeat_phase == "fall" and pose.rotation > 0.018 and pose.rotation < 0.025 and pose.offset.y > 1.0, "collapse lowers the grounded outer pose without whole-card tipping at 0.67 seconds")
	check(pose.modulate.a == 1.0 and pose.scale == Vector2.ONE, "body remains opaque and undeformed throughout the fall")
	check(not fx.consume_event(won), "duplicate final event cannot restart the collapse")
	check(fx.dragon_pose() == pose, "ignored final event leaves exact pose progress unchanged")
	fx.advance(FX.DRAGON_DEFEAT_LANDING_TIME - float(fx.dragon_pose().defeat_age))
	pose = fx.dragon_pose()
	check(pose.defeat_phase == "landing" and is_equal_approx(pose.rotation, 0.045), "body reaches ground contact at 0.92 seconds")
	fx.advance(0.12)
	pose = fx.dragon_pose()
	check(pose.modulate.a == 1.0 and pose.offset.y <= 4.5 and pose.scale.y >= 0.975, "landing is opaque with at most 1.5 pixels of settling and 2.5 percent squash")
	fx.advance(0.26)
	pose = fx.dragon_pose()
	check(pose.modulate.a == 1.0 and pose.scale == Vector2.ONE and is_equal_approx(pose.rotation, 0.035), "fallen body rests at full opacity until 1.30 seconds")
	fx.advance(0.15)
	pose = fx.dragon_pose()
	check(pose.defeat_phase == "fade" and pose.visible and is_equal_approx(pose.modulate.a, 0.5), "only the concluding 0.30 seconds fade the settled body")
	fx.advance(0.14)
	check(fx.dragon_pose().visible and not fx.dragon_pose().defeat_complete, "dragon remains present at 1.59 seconds")
	fx.advance(FX.DRAGON_DEFEAT_DURATION - float(fx.dragon_pose().defeat_age))
	pose = fx.dragon_pose()
	check(not pose.visible and pose.defeat_complete and pose.modulate.a == 0.0 and pose.defeat_phase == "complete", "completion becomes exact and persistent at 1.60 active seconds")
	fx.advance(30.0)
	check(fx.dragon_pose() == pose, "completed dragon pose cannot reappear after celebration expires")
	fx.consume_event(event("victory", 3))
	check(fx.dragon_pose() == pose and fx.debug_snapshot().effects.is_empty(), "later same-run victory cannot replay body, dust or confetti")
	fx.reset_for_run(2)
	pose = fx.dragon_pose()
	check(pose.visible and not pose.defeat_complete and pose.offset == Vector2.ZERO and pose.rotation == 0.0 and pose.scale == Vector2.ONE and pose.modulate == Color.WHITE and pose.defeat_phase == "none", "restart restores visible identity including alpha and completion flag")
	check(not fx.consume_event(event("victory", 999)), "delayed old-run victory cannot collapse the restarted dragon")
	check(fx.dragon_pose() == pose, "old-run final event leaves new dragon unchanged")
	fx.consume_event(event("defeat", 1, {"run_id": 2}))
	check(fx.dragon_pose().visible and not fx.dragon_pose().defeat_complete, "player defeat never plays dragon death")

func test_dragon_final_hit_timing_and_suspension() -> void:
	var fx = make_fx()
	fx.consume_event(event("speed_changed", 1, {"speed_multiplier": 2}))
	fx.consume_event(event("victory", 2))
	fx.advance(0.67)
	check(fx.dragon_pose().defeat_phase == "fall" and is_equal_approx(fx.dragon_pose().defeat_age, 0.67), "terminal collapse uses real seconds even after x2 gameplay")
	var before: Dictionary = fx.debug_snapshot()
	fx.sync_snapshot({"run_id": 1, "status": "victory", "paused": false, "speed_multiplier": 2, "time_us": 1000000})
	check(fx.dragon_pose() == before.dragon_pose, "terminal snapshot cannot restart or advance the cosmetic clock")
	fx.set_paused(true)
	before = fx.debug_snapshot()
	fx.advance(4.0)
	check(fx.debug_snapshot() == before, "modal pause freezes dragon collapse and alpha")
	fx.set_paused(false)
	fx.set_backgrounded(true)
	before = fx.debug_snapshot()
	fx.advance(4.0)
	check(fx.debug_snapshot() == before, "background freezes dragon collapse and alpha")
	fx.set_backgrounded(false)
	paused = true
	before = fx.debug_snapshot()
	fx.advance(4.0)
	check(fx.debug_snapshot() == before, "SceneTree pause freezes final dragon presentation")
	paused = false
	fx.advance(FX.DRAGON_DEFEAT_DURATION - float(fx.dragon_pose().defeat_age))
	check(fx.dragon_pose().defeat_complete, "resumed collapse finishes after exactly 1.60 active real seconds")
	fx.reset_for_run(2)
	fx.consume_event(event("victory", 1, {"run_id": 2}))
	fx.advance(1.45)
	var alpha_before: float = fx.dragon_pose().modulate.a
	fx.set_reduced_motion(true)
	check(fx.dragon_pose().offset == Vector2.ZERO and fx.dragon_pose().rotation == 0.0 and fx.dragon_pose().scale == Vector2.ONE, "enabling reduced motion removes in-flight collapse transforms immediately")
	check(fx.dragon_pose().modulate.a == alpha_before, "motion preference change preserves fade progress without flashing")
	check(fx.debug_snapshot().effects.is_empty(), "reduced motion also removes scheduled landing dust")
	fx.set_reduced_motion(false)
	check(fx.dragon_pose().modulate.a == alpha_before, "restoring motion does not restart the final fade")
	fx.advance(60.0)
	check(fx.dragon_pose().defeat_complete and not fx.dragon_pose().visible and fx.debug_snapshot().effects.is_empty(), "oversized frame completes collapse without replaying landing dust")

func test_dragon_final_hit_partition_and_bounds() -> void:
	var a = make_fx()
	var b = make_fx()
	for fx in [a, b]:
		fx.consume_event(event("armor_broken", 1, {"applied_knockback": 10000.0}))
		fx.consume_event(event("victory", 2))
	a.advance(0.04)
	a.advance(0.08)
	a.advance(0.92)
	b.advance(1.04)
	check(a.debug_snapshot() == b.debug_snapshot(), "hit-stop and delayed dust are frame-partition independent through contact")
	var fx = make_fx()
	fx.consume_event(event("armor_broken", 1, {"applied_knockback": 10000.0}))
	fx.consume_event(event("victory", 2))
	for i in range(161):
		var pose: Dictionary = fx.dragon_pose()
		check(absf(pose.offset.x) <= 36.0 and pose.offset.y <= 4.5 and absf(pose.rotation) <= 0.05, "all defeat phases keep the outer sprite grounded without large card rotation")
		check(pose.scale.x <= 1.01 and pose.scale.y >= 0.975 and pose.scale.y <= 1.0, "all defeat phases avoid the old excessive squash")
		if float(pose.defeat_age) <= FX.DRAGON_DEFEAT_FADE_START:
			check(pose.modulate.a == 1.0, "every falling/landing/rest sample is fully opaque")
		var snapshot: Dictionary = fx.debug_snapshot()
		check(snapshot.effects.size() <= FX.MAX_EFFECTS and snapshot.particle_count <= FX.MAX_PARTICLES, "landing dust shares existing effect/particle caps")
		fx.advance(0.01)

func test_determinism_and_boundaries() -> void:
	var a = make_fx()
	var b = make_fx()
	var impact := event("armor_broken", 1, {"color": "purple", "applied_knockback": 3})
	a.consume_event(impact)
	b.consume_event(impact)
	check(a.debug_snapshot() == b.debug_snapshot(), "identical event seeds produce identical particles")
	a.advance(0.125)
	a.advance(0.125)
	b.advance(0.25)
	check(a.debug_snapshot() == b.debug_snapshot(), "analytical particle state is frame-partition independent")
	var before: Dictionary = a.debug_snapshot()
	a.advance(-1.0)
	a.advance(NAN)
	a.advance(INF)
	check(a.debug_snapshot() == before, "negative/nonfinite deltas cannot corrupt presentation")
	for i in range(2, 400):
		a.consume_event(event("armor_broken", i, {"color": "purple", "applied_knockback": 3}))
		var state: Dictionary = a.debug_snapshot()
		check(state.effects.size() <= FX.MAX_EFFECTS and state.particle_count <= FX.MAX_PARTICLES, "event flood never exceeds global effect/particle limits")
	for i in range(400, 420):
		a.consume_event(event("cannon_fired", i, {"id": i, "fire_us": 0, "hit_us": 999999999}))
	check(a.debug_snapshot().projectiles.size() <= FX.MAX_PROJECTILES, "projectile concurrency is bounded")
	a.advance(1000000.0)
	check(a.debug_snapshot().effects.is_empty() and a.debug_snapshot().projectiles.is_empty(), "oversized frame drops backlog instead of leaking effects")

func test_layout_and_tool_boundaries() -> void:
	var fx = make_fx()
	var layout := {"board_origin": Vector2(20, 30), "cell_size": Vector2(10, 12),
		"stock_points": {"red": Vector2(80, 90)}, "tool_points": {"extra_slot": Vector2(100, 100),
		"shuffle": Vector2(200, 100), "recall": Vector2(300, 100), "scout": Vector2(400, 100)}}
	fx.set_layout(layout)
	layout.stock_points.red = Vector2(-999, -999)
	fx.consume_event(event("bead_picked_up", 1, {"path": [[0, 0], [2, 3]], "color": "red"}))
	check(fx.debug_snapshot().effects[0].pos == Vector2(40, 66), "pickup resolves actual event cell into local board position")
	fx.consume_event(event("bead_delivered", 2, {"color": "red"}))
	var effects: Array = fx.debug_snapshot().effects
	check(effects[-2].to == Vector2(80, 90), "delivery spark follows copied stock context, not externally mutated layout")
	for tool in ["extra_slot", "shuffle", "recall", "scout"]:
		check(fx.play_tool(tool, false, Vector2(-700, -700)), "all four tool preview cues exist")
		var preview: Dictionary = fx.debug_snapshot().effects[-1]
		check(preview.kind == "ring" and preview.pos != Vector2(-700, -700), "rejected tool only hints at icon, never pretends target changed")
		check(fx.play_tool(tool, true, Vector2(450, 400)), "authoritative tool_used success has a distinct owner-triggered cue")
	check(fx.play_tool("plus") and fx.play_tool("hint"), "existing UI aliases are supported")
	check(not fx.play_tool("unrecognized"), "unknown tools do not create effects")
	fx.set_paused(true)
	check(not fx.play_tool("shuffle", true), "suspended tool cue does not queue surprise animation")
	fx.set_paused(false)
	fx.advance(10)
	fx.consume_event(event("blocked_changed", 3, {"blocked": true}))
	check(fx.debug_snapshot().effects.size() == 4, "blocked state gives local shuffle and recall hints, not fake tool outcomes")

func test_reduced_motion_and_rescue() -> void:
	var fx = make_fx()
	fx.set_reduced_motion(true)
	fx.consume_event(event("cannon_fired", 1, {"id": 4, "color": "red"}))
	fx.advance(0.06)
	check(fx.cannon_pose().offset == Vector2.ZERO and fx.cannon_pose().scale == Vector2.ONE, "reduced motion removes cannon displacement")
	fx.consume_event(event("armor_broken", 2, {"id": 4, "applied_knockback": 20}))
	check(fx.dragon_pose().offset == Vector2.ZERO and fx.dragon_pose().rotation == 0.0, "reduced motion removes dragon displacement/rotation")
	for effect in fx.debug_snapshot().effects:
		check(not effect.kind in ["smoke", "confetti", "shard"], "reduced motion uses steady sparkles, no tumbling/smoke")
		for particle in effect.get("particles", []):
			check(particle.velocity == Vector2.ZERO and particle.gravity == Vector2.ZERO, "reduced motion particles do not travel")
	fx.consume_event(event("victory", 3))
	check(fx.debug_snapshot().projectiles.is_empty(), "victory clears projectile remnants")
	fx.advance(1.45)
	var pose: Dictionary = fx.dragon_pose()
	check(pose.visible and pose.modulate.a > 0.0 and pose.modulate.a < 1.0, "reduced motion keeps a finite, readable final fade")
	check(pose.offset == Vector2.ZERO and pose.rotation == 0.0 and pose.scale == Vector2.ONE, "reduced-motion victory has no tilt, shrink or displacement")
	fx.advance(FX.DRAGON_DEFEAT_DURATION - float(fx.dragon_pose().defeat_age))
	check(fx.dragon_pose().defeat_complete and not fx.dragon_pose().visible, "reduced-motion final fade also completes at 1.60 seconds")
	fx.advance(3.0)
	check(fx.debug_snapshot().effects.is_empty(), "celebration expires even though terminal simulation time freezes")
	fx.set_reduced_motion(false)
	fx.reset_for_run(2)
	fx.consume_event(event("victory", 1, {"run_id": 2}))
	check(fx.debug_snapshot().particle_count == 56, "normal rescue budgets 46 confetti pieces and 10 scheduled landing dust particles")
	fx.advance(2.5)
	check(fx.debug_snapshot().particle_count == 0, "rescue confetti has a finite lifetime")

func test_snapshot_and_restart() -> void:
	var fx = make_fx()
	var snapshot := {"run_id": 1, "time_us": 400000, "paused": false, "status": "running", "speed_multiplier": 1,
		"armors": [{"color": "red", "demand": 20}], "armor_index": 0, "inventory": {"red": 10}}
	var before := snapshot.duplicate(true)
	fx.sync_snapshot(snapshot)
	check(fx.debug_snapshot().charge == 0.5, "charge reflects arrived ammo / actual armor demand")
	check(snapshot == before, "snapshot remains immutable")
	fx.consume_event(event("cannon_fired", 1, {"id": 1, "fire_us": 0, "hit_us": 1000000}))
	fx.sync_snapshot(snapshot)
	var shot: Dictionary = fx.debug_snapshot().projectiles[0]
	check(shot.fire_us == 0 and shot.hit_us == 1000000, "shot keeps authoritative simulation timestamps")
	fx.reset_for_run(2)
	check(fx.debug_snapshot().effects.is_empty() and fx.debug_snapshot().projectiles.is_empty(), "restart clears all transient objects")
	check(fx.cannon_pose().offset == Vector2.ZERO and fx.dragon_pose().offset == Vector2.ZERO, "restart resets both actor poses")
	check(not fx.consume_event(event("victory", 999)), "old-run delayed victory cannot show confetti after restart")
	fx.sync_snapshot(snapshot)
	check(fx.debug_snapshot().run_id == 2 and fx.debug_snapshot().charge == 0.0, "old-run snapshot cannot resurrect effects")
	fx.set_cannon_charge(NAN, "red")
	check(fx.debug_snapshot().charge == 0.0, "nonfinite charge is safe")
	fx.set_cannon_charge(3.0, "red")
	check(fx.debug_snapshot().charge == 1.0, "charge clamps to full without changing inventory")

func test_real_rules_read_only() -> void:
	var config := {"schema_version": 1, "level_id": "fx-read-only", "width": 1, "height": 1,
		"grid": ["R"], "palette": {"R": "red"},
		"columns": [{"id": "red", "teams": [{"id": "red-1", "color": "red", "quota": 1}]}],
		"armors": [{"id": "red-armor", "color": "red", "demand": 1}],
		"parameters": {"dispatch_interval_sec": 0.1, "transport_speed_cells_sec": 10.0, "max_inflight_ants": 20, "cannon_cooldown_sec": 0.5, "projectile_flight_sec": 0.5},
		"dragon": {"route_length": 100.0, "speed_units_sec": 1.0, "initial_position": 0.0, "knockback_distance": 2.0, "max_knockback_distance": 2.0}}
	var rules = Rules.new()
	check(rules.load_level(config), "real Rules fixture validates")
	var fx = make_fx()
	fx.consume_events(rules.drain_events())
	rules.select_front("red", "red-1")
	for i in range(10):
		rules.update(0.1)
		var snapshot: Dictionary = rules.snapshot()
		var untouched := snapshot.duplicate(true)
		var events: Array = rules.drain_events()
		var original_events := events.duplicate(true)
		fx.sync_snapshot(snapshot)
		fx.consume_events(events)
		fx.advance(0.1)
		check(snapshot == untouched and events == original_events, "real rule payloads unchanged by presentation")
		check(rules.snapshot() == untouched, "visual advancement cannot write rule state")
	check(rules.status == "victory", "Rules can win without waiting for any visual animation")
	check(not fx.dragon_pose().defeat_complete, "authoritative victory is already recorded while the cosmetic collapse is still active")
	check(rules.conservation_errors().is_empty(), "FX never changes inventory conservation")
	check(not rules.request_tool("shuffle").ok, "FX cannot silently unlock or consume a production-locked tool")

func run() -> void:
	test_event_dispatch_and_dedupe()
	test_projectile_and_finite_pose()
	test_projectile_readability_and_authoritative_path()
	test_cannon_spring_and_protected_ribbons()
	test_pause_speed_and_background()
	test_dragon_final_hit_and_reset()
	test_dragon_final_hit_timing_and_suspension()
	test_dragon_final_hit_partition_and_bounds()
	test_determinism_and_boundaries()
	test_layout_and_tool_boundaries()
	test_reduced_motion_and_rescue()
	test_snapshot_and_restart()
	test_real_rules_read_only()
	# Let every primitive's _draw execute once, including successful tool variants.
	var visual = make_fx()
	visual.set_layout({"protected_rects": []})
	visual.set_cannon_charge(0.6, "red")
	visual.consume_event(event("cannon_fired", 1, {"id": 1, "fire_us": 0, "hit_us": 1000000}))
	visual.consume_event(event("armor_broken", 2, {"id": 99, "color": "blue"}))
	visual.consume_event(event("ant_dispatched", 3))
	visual.consume_event(event("bead_delivered", 4, {"color": "purple"}))
	for tool in ["extra_slot", "shuffle", "recall", "scout"]:
		visual.play_tool(tool, true, Vector2(400, 700))
	visual.advance(0.08)
	await process_frame
	await process_frame
	visual.consume_event(event("victory", 5))
	visual.advance(1.04)
	await process_frame
	for fx in fx_nodes:
		fx.queue_free()
	await process_frame
	print(JSON.stringify({"suite": "RescueFX", "assertions": assertions, "failures": failures, "passed": failures.is_empty()}))
	quit(0 if failures.is_empty() else 1)
