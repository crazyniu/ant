extends SceneTree
## Bounded evidence probe for this one draft. No generator, catalog, save or gameplay edits.
const Rules = preload("res://scripts/rescue_rules.gd")
const CheckEntry = preload("res://tools/validate_serpent_level.gd")
var failures: Array = []
var assertions := 0

func check(value: bool, label: String) -> void:
	assertions += 1
	if not value: failures.append(label)

func fresh(config: Dictionary):
	var rules = Rules.new()
	check(rules.load_level(config), "Draft loads with unchanged production rules")
	return rules

func frame_replay(config: Dictionary) -> Dictionary:
	var r = fresh(config)
	var events: Array = r.drain_events()
	var paths: Array = []
	for input in config.solution.inputs:
		var at_us := Rules.seconds_to_us(float(input.at_sec))
		while r.time_us < at_us and r.status == "running":
			r.update_us(mini(100000, at_us - int(r.time_us)))
			check(r.conservation_errors().is_empty(), "100ms step conservation")
			events.append_array(r.drain_events())
		var old_board: int = r.board.size()
		var old_tasks: int = r.tasks.size()
		var accepted: Dictionary = r.click_color(input.color)
		check(accepted.ok and not accepted.queued, "Exactly the authored frame input is accepted")
		if not accepted.ok: break
		check(r.board.size() == old_board and r.tasks.size() == old_tasks + 1, "One click reserves one bead and one ant without pickup")
		paths.append(r.tasks[accepted.task_id].duplicate(true))
		if r.tasks.size() == 4:
			var before: Dictionary = r.snapshot()
			var blocked: Dictionary = r.click_color("blue")
			check(not blocked.ok and blocked.reason == "carrier_limit" and not blocked.queued and r.snapshot() == before, "Full carrier rejection has no mutation or queue")
		events.append_array(r.drain_events())
	while r.status == "running":
		r.update_us(100000)
		check(r.conservation_errors().is_empty(), "Final frame-step conservation")
		events.append_array(r.drain_events())
	return {"events": events, "snapshot": r.snapshot(), "paths": paths}

func describe(r, label: String) -> Dictionary:
	var best := {}
	var reachable := {}
	for color in ["red", "blue", "green", "yellow"]:
		best[color] = r.best_target(color)
		reachable[color] = r.reachable_cell_ids(color)
	return {"label": label, "time_us": r.time_us, "board_count": r.board.size(), "best_targets": best, "reachable_ids": reachable, "delivered_counts": r.delivered_counts.duplicate()}

func opening_probes(c: Dictionary) -> Array:
	var stages: Array = []
	var r = fresh(c)
	stages.append(describe(r, "Initial: three legal colors; yellow entirely blocked"))
	check(r.reachable_cell_ids("yellow").is_empty() and r.reachable_cell_ids("blue").size() == 4, "All yellow blocked; only four of six required blue beads exterior")
	check(r.best_target("red").cell_id == 56 and r.best_target("red").distance == 3, "Red opening is near central gate [6,5]")
	check(r.best_target("green").cell_id == 67 and r.best_target("green").distance == 3, "Green opening is equally short side gate [7,6]")
	var before: Dictionary = r.snapshot()
	var blocked: Dictionary = r.click_color("yellow")
	check(not blocked.ok and blocked.reason == "color_blocked" and not blocked.queued and r.snapshot() == before, "Initially blocked yellow click does not mutate or queue")
	r.update_us(2000000)
	check(r.status == "ready" and r.time_us == 0 and r.threat_started_us == -1, "Rejected opening cannot start threat")
	check(r.click_color("red").ok, "Red opening accepted")
	r.update_us(1199999)
	check(r.board.has(56) and r.reachable_cell_ids("yellow").is_empty(), "Red reservation does not open gate before pickup")
	r.update_us(1)
	check(r.reachable_cell_ids("yellow") == [46, 57] and not r.reachable_cell_ids("blue").has(36) and not r.reachable_cell_ids("blue").has(45), "Red pickup opens yellow but neither blue core")
	check(r.delivered_counts.red == 0 and r.inventory.red == 0, "Gate pickup grants no ammunition")
	stages.append(describe(r, "Stage 1: red [6,5] picked up; yellow [6,4] and [7,5] newly reachable"))
	r.update_us(200000)
	check(r.click_color("yellow").cell_id == 46, "Fresh explicit click selects the yellow bridge")
	r.update_us(1599999)
	check(r.board.has(46) and not r.reachable_cell_ids("blue").has(36) and not r.reachable_cell_ids("blue").has(45), "Yellow reservation does not expose core")
	r.update_us(1)
	check(r.reachable_cell_ids("blue").has(36) and r.reachable_cell_ids("blue").has(45), "Stage 2 yellow pickup exposes both required blue core cells")
	check(r.delivered_counts.yellow == 0 and r.inventory.yellow == 0, "Yellow bridge pickup still grants no ammunition")
	stages.append(describe(r, "Stage 2: yellow [6,4] picked up; blue [6,3] and [5,4] reachable at five cells"))
	r.update_us(199999)
	check(r.delivered_counts.red == 0, "Red not credited one microsecond before delivery")
	r.update_us(1)
	check(r.delivered_counts.red == 1 and r.shot_counts.red == 1 and r.hit_counts.red == 0, "Red delivery at 3.2s supplies the first shot, not early damage")
	r = fresh(c)
	check(r.click_color("green").ok, "Green opening accepted")
	r.update_us(1199999)
	check(r.reachable_cell_ids("yellow").is_empty(), "Green reservation cannot open yellow")
	r.update_us(1)
	check(r.reachable_cell_ids("yellow") == [57] and r.best_target("yellow").distance == 4, "Green pickup opens a different single yellow wing")
	stages.append(describe(r, "Alternate stage 1: green [7,6] picked up; yellow [7,5] exposed and outer blue [8,6] shortens from six cells to four"))
	r.update_us(200000)
	check(r.click_color("yellow").cell_id == 57, "Green-first chooses different yellow target")
	r.update_us(1600000)
	check(r.reachable_cell_ids("yellow") == [47] and not r.reachable_cell_ids("blue").has(36) and not r.reachable_cell_ids("blue").has(45), "Green wing opens next yellow but not the blue core yet")
	stages.append(describe(r, "Alternate stage 2: yellow [7,5] picked up; upper yellow [7,4] reachable, core remains blocked"))
	r = fresh(c)
	check(r.click_color("blue").cell_id == 65, "Exterior blue ammunition is a third valid initial choice")
	r.update_us(1200000)
	check(r.reachable_cell_ids("yellow").is_empty(), "Exterior blue pickup does not automatically open yellow")
	stages.append(describe(r, "Blue-first: external [5,6] supplies armor ammunition without exposing yellow"))
	r.update_us(62000000)
	check(r.status == "defeat" and r.terminal_time_us == 62000000 and not r.alive_segment_ids.is_empty(), "Living enemy reaches fixed finite goal at exactly 62s")
	return stages

func _initialize() -> void:
	var c: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/serpent-levels/serpent-07.json"))
	var exact: Dictionary = CheckEntry.inspect(c, true)
	check(exact.ok, "Existing one-level CLI inspection passes")
	var frame := frame_replay(c)
	check(exact.events == frame.events, "100ms updates reproduce every exact-event record")
	check(frame.snapshot.status == "victory" and frame.snapshot.terminal_time_us == 27850000, "Final actual-hit victory at 27.85s")
	check(frame.snapshot.board.size() == 4 and frame.snapshot.tasks.is_empty() and frame.snapshot.projectile.is_empty(), "Victory leaves four unused beads without pending transport or projectile")
	check(frame.snapshot.hit_counts == {"red": 3, "blue": 6, "green": 5, "yellow": 3}, "Per-color actual damage equals intended HP")
	var cracked := 0
	var removed := 0
	for event in exact.events:
		if event.type == "segment_hit" and event.kind == "armored" and event.hp == 1: cracked += 1
		if event.type == "segment_removed": removed += 1
	check(cracked == 4 and removed == 13, "Four visible armor cracks and thirteen removed segments")
	var stages := opening_probes(c)
	var alt := c.duplicate(true)
	alt.solution.inputs[0].color = "green"
	alt.solution.inputs[3].color = "red"
	var alternate: Dictionary = CheckEntry.inspect(alt, true)
	check(alternate.ok, "A complete green-first authored solution also wins")
	var alternate_frame := frame_replay(alt)
	check(alternate.events == alternate_frame.events, "Green-first 100ms trace matches exact events")
	var report := {"passed": failures.is_empty(), "assertions": assertions, "failures": failures,
		"engine": Engine.get_version_info().string, "rules_api": Rules.API_VERSION,
		"level_sha256": FileAccess.get_sha256("res://data/serpent-levels/serpent-07.json"),
		"scope": "Only serpent-07 independent draft: unchanged production rules and existing CLI, exact and 100ms red/green-first solutions, pickup-only stages, per-color accounting, capacity, finite-goal loss. No GL, ground support, natural input, audio, target devices, human balance, economy awards, catalog, other levels or publication tested.",
		"main_solution": c.solution, "main_summary": exact.duplicate(true), "transport_tasks": frame.paths,
		"opening_stages": stages, "green_first_inputs": alt.solution.inputs,
		"green_first_summary": alternate.duplicate(true), "green_first_transport_tasks": alternate_frame.paths,
		"green_first_events": alternate.events, "terminal_snapshot": frame.snapshot}
	report.main_summary.erase("events")
	report.green_first_summary.erase("events")
	var output := FileAccess.open("res://reports/rules/ice-supply-rules.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t") + "\n")
	print(JSON.stringify({"passed": failures.is_empty(), "assertions": assertions, "failures": failures, "main_final_us": exact.terminal_time_us, "green_first_final_us": alternate.terminal_time_us}))
	quit(0 if failures.is_empty() else 1)
