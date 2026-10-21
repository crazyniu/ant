extends SceneTree
const Checker = preload("res://tools/validate_serpent_level.gd")
var checks := 0
var failures: Array = []
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-05.json"))
	var before := JSON.stringify(config)
	var valid := Checker.inspect(config, true)
	check(valid.ok and valid.terminal_time_us == 26900000, "real ice base-worker final hit")
	check(valid.remaining_beads == 8 and valid.maximum_carriers == 4, "surplus and capacity")
	check(valid.longest_no_dispatch_opportunity_us == 1700000, "exact waits match independent prior evidence")
	check(valid.accepted_inputs == 16 and valid.path_cells.size() == 16, "all authored inputs checked")
	check(valid.guardian_id == "winter_camp" and valid.scene_id == "ice_camp", "scene target identity")
	check(valid.events.back().type == "victory" and valid.events[-3].type == "segment_hit", "event trace ends with real hit")
	check(JSON.stringify(config) == before, "checker never modifies input")
	var mutated := config.duplicate(true); mutated.solution.inputs[0].color = "yellow"
	check(not Checker.inspect(mutated).ok, "reject initially blocked input")
	mutated = config.duplicate(true); mutated.solution.inputs[1].at_sec = 0
	check(not Checker.inspect(mutated).ok, "reject duplicate timestamps")
	mutated = config.duplicate(true); mutated.solution.inputs[0].at_sec = 0.5
	check(not Checker.inspect(mutated).ok, "reject delayed time origin")
	mutated = config.duplicate(true); mutated.scene_layout = "res://data/scenes/missing.json"
	check(not Checker.inspect(mutated).ok, "missing scene is explicit")
	mutated = config.duplicate(true); mutated.defense_target.id = "princess"
	check(not Checker.inspect(mutated).ok, "guardian mismatch rejected")
	mutated = config.duplicate(true); mutated.solution.inputs = [{"at_sec": 0, "color": "red"}]
	check(not Checker.inspect(mutated).ok, "partial solution cannot pass at dragon contact")
	mutated = config.duplicate(true); mutated.rewards.normal_seconds = mutated.rewards.fast_seconds
	check(not Checker.inspect(mutated).ok, "invalid reward thresholds rejected")
	mutated = config.duplicate(true); mutated.transport.entrance_cell = [6, 7]
	check(not Checker.inspect(mutated).ok, "illegal inside entrance rejected")
	check(not Checker.inspect({}).ok, "malformed object returns report without crash")
	var report := {"checks": checks, "failures": failures, "scope": "One valid05 and deliberately invalid variants; no full historical suite, no gameplay mutation"}
	var path := OS.get_environment("ANT_LEVEL_CHECK_REPORT")
	if not path.is_empty():
		var file := FileAccess.open(path, FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")); file.close()
	print("LEVEL_CHECK_ENTRY ", JSON.stringify(report)); quit(0 if failures.is_empty() else 1)
