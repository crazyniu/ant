extends SceneTree
## Bounded transport contract fixtures only. No campaign sweep or proof mutation.
const Rules = preload("res://scripts/rescue_rules.gd")
const Document = preload("res://scripts/editor_document.gd")
var assertions := 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		push_error(message)
func fixture() -> Dictionary:
	return {"schema_version": 1, "level_id": "transport-fixture", "width": 1, "height": 1, "grid": ["R"], "palette": {"R": "red"}, "columns": [{"id": "red", "teams": [{"id": "red-1", "color": "red", "quota": 1}]}], "armors": [{"id": "armor-red", "color": "red", "demand": 1}], "parameters": {"dispatch_interval_sec": 0.1, "transport_speed_cells_sec": 14.0, "transport_min_leg_sec": 0.55, "pickup_pause_sec": 0.16, "max_inflight_ants": 20, "cannon_cooldown_sec": 2.0, "projectile_flight_sec": 0.25}, "dragon": {"route_length": 100.0, "initial_position": 0.0, "speed_units_sec": 1.0, "knockback_distance": 0.0, "max_knockback_distance": 0.0}}
func start(config: Dictionary):
	var sim = Rules.new()
	check(sim.load_level(config), "configuration loads: " + str(sim.validation_errors))
	check(sim.select_front("red", "red-1").ok, "first exact front is legal")
	return sim
func events_of(events: Array, type: String) -> Array:
	return events.filter(func(event: Dictionary) -> bool: return event.type == type)
func test_leg_and_hold() -> void:
	var sim = start(fixture())
	var task: Dictionary = sim.tasks[1]
	check(task.leg_duration_us == 550000 and task.pickup_us == 550000, "one-cell travel is at least 0.55 simulation seconds")
	check(task.return_depart_us == 710000 and task.delivery_us == 1260000, "honest pickup hold separates arrival and return departure")
	for event in events_of(sim.drain_events(), "ant_dispatched"):
		check(event.return_depart_us == task.return_depart_us and event.leg_duration_us == task.leg_duration_us, "render consumer receives authoritative leg and return-depart times")
	sim.update_us(549999)
	check(sim.board.size() == 1 and sim.reservations.size() == 1 and sim.tasks[1].stage == "outbound", "reserved bead remains an obstacle until exact arrival")
	sim.update_us(1)
	check(sim.board.is_empty() and sim.reservations.is_empty() and sim.tasks[1].stage == "returning", "pickup removes bead exactly at arrival, not after hold")
	check(sim.inventory.red == 0 and sim.delivered_counts.red == 0 and sim.spent_counts.red == 0, "carrying hold gives no ammunition")
	check(sim.conservation_errors().is_empty(), "picked bead is conserved during hold")
	var pickups := events_of(sim.drain_events(), "bead_picked_up")
	check(pickups.size() == 1 and pickups[0].time_us == 550000 and pickups[0].return_depart_us == 710000, "pickup emits once with complete return metadata")
	sim.update_us(159999)
	check(sim.tasks[1].stage == "returning" and sim.inventory.red == 0, "task remains returning throughout pickup hold")
	sim.set_paused(true)
	var paused: Dictionary = sim.snapshot()
	sim.update_us(9000000)
	sim.update(9.0)
	check(sim.snapshot() == paused, "pause freezes pickup hold and every authoritative clock")
	sim.set_paused(false)
	sim.update_us(1)
	check(sim.time_us == 710000 and sim.inventory.red == 0 and sim.tasks.size() == 1, "return departure is movement metadata, not delivery")
	sim.update_us(549999)
	check(sim.delivered_counts.red == 0 and sim.projectile.is_empty(), "no inventory or cannon fire one microsecond before delivery")
	sim.update_us(1)
	check(sim.tasks.is_empty() and sim.delivered_counts.red == 1 and sim.spent_counts.red == 1 and sim.inventory.red == 0, "delivery credits once and authority may fire immediately")
	var events: Array = sim.drain_events()
	check(events_of(events, "bead_delivered").size() == 1 and events_of(events, "cannon_fired").size() == 1, "one arrival causes precisely one delivery and one fire")
	check(sim.status == "running" and sim.projectile.hit_us == 1510000, "delivery and fire never commit victory")
	sim.update_us(249999)
	check(sim.status == "running", "final flight remains authoritative until exact hit")
	sim.update_us(1)
	check(sim.status == "victory" and sim.terminal_time_us == 1510000 and sim.conservation_errors().is_empty(), "only final armor hit wins with conservation intact")
func test_long_legacy_validation() -> void:
	var config := fixture()
	config.height = 8
	config.grid = ["R", ".", ".", ".", ".", ".", ".", "."]
	config.parameters.transport_speed_cells_sec = 4.0
	var sim = start(config)
	check(sim.tasks[1].leg_duration_us == 2000000 and sim.tasks[1].delivery_us == 4160000, "minimum leg never shortens longer real routes")
	config = fixture()
	config.parameters.erase("transport_min_leg_sec")
	config.parameters.erase("pickup_pause_sec")
	config.parameters.transport_speed_cells_sec = 16.0
	sim = start(config)
	check(sim.tasks[1].pickup_us == 62500 and sim.tasks[1].return_depart_us == 62500 and sim.tasks[1].delivery_us == 125000, "omitted optional fields preserve isolated legacy timing")
	for key in ["transport_min_leg_sec", "pickup_pause_sec"]:
		for invalid in [-0.01, "0.55", null, true, NAN, INF]:
			config = fixture()
			config.parameters[key] = invalid
			check(not Rules.validate_level(config).is_empty(), key + " rejects nonnumeric, nonfinite or negative values")
		config = fixture()
		config.parameters[key] = 0.0
		check(Rules.validate_level(config).is_empty(), key + " allows explicit zero for compatibility")
	var document = Document.new()
	check(document.config.parameters.transport_min_leg_sec == 0.55 and document.config.parameters.pickup_pause_sec == 0.16 and document.config.parameters.transport_speed_cells_sec == 14.0, "new editor documents expose current readable transport defaults")
	config = fixture()
	config.merge({"seed": 1, "pattern_name": "Timing fixture", "content_version": "test"})
	check(document.import_json(JSON.stringify(config)).ok, "readable timing imports")
	var exported: Dictionary = document.exported_config()
	check(exported.parameters.transport_min_leg_sec == 0.55 and exported.parameters.pickup_pause_sec == 0.16, "editor import/export preserves optional transport parameters")
func test_x2_cannon_and_contact() -> void:
	var sim = start(fixture())
	sim.set_speed(2)
	sim.update_us(275000)
	check(sim.time_us == 550000 and sim.tasks[1].stage == "returning", "x2 applies to outbound arrival")
	sim.update_us(80000)
	check(sim.time_us == 710000 and sim.inventory.red == 0, "x2 applies to pickup hold without awarding inventory")
	sim.update_us(275000)
	check(sim.time_us == 1260000 and sim.delivered_counts.red == 1, "x2 applies to return delivery")
	sim.update_us(125000)
	check(sim.terminal_time_us == 1510000 and sim.status == "victory", "x2 changes wall duration, never authoritative outcome time")
	var config := fixture()
	config.width = 2
	config.grid = ["RR"]
	config.columns[0].teams[0].quota = 2
	config.armors.append({"id": "armor-red-2", "color": "red", "demand": 1})
	sim = start(config)
	sim.update_us(3259999)
	check(sim.armor_index == 1 and sim.inventory.red == 1 and sim.spent_counts.red == 1, "surplus survives pickup hold and waits for original fire-based cooldown")
	sim.update_us(1)
	check(sim.projectile.fire_us == 3260000 and sim.spent_counts.red == 2, "second fire stays exactly two seconds after first fire")
	var fires := events_of(sim.drain_events(), "cannon_fired")
	check(fires.size() == 2 and fires[0].time_us == 1260000 and fires[1].time_us == 3260000, "hold does not alter cannon cooldown or double-debit stock")
	for case in [{"route": 1.51, "status": "victory", "time": 1510000}, {"route": 1.509999, "status": "defeat", "time": 1509999}, {"route": 1.26, "status": "defeat", "time": 1260000}]:
		config = fixture()
		config.dragon.route_length = case.route
		sim = start(config)
		sim.update_us(10000000)
		check(sim.status == case.status and sim.terminal_time_us == case.time, "exact hit/contact/delivery ordering survives timing change")
		if case.route == 1.26:
			check(sim.delivered_counts.red == 0 and sim.spent_counts.red == 0, "contact at delivery still wins before inventory or fire")
func run() -> void:
	test_leg_and_hold()
	test_long_legacy_validation()
	test_x2_cannon_and_contact()
	print("TRANSPORT TIMING TESTS: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
