extends SceneTree
## Finite campaign acceptance regression: 30 drafts, 30 paced proofs, 60 boundaries.
const Document = preload("res://scripts/editor_document.gd")
const Verifier = preload("res://scripts/editor_verifier.gd")
const Rules = preload("res://scripts/rescue_rules.gd")
var assertions := 0
var failures: Array[String] = []
var entries: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
		push_error(message)

func check_last_flight(config: Dictionary, inputs: Array, final_time: int) -> void:
	var sim = Rules.new()
	check(sim.load_level(config), config.level_id + " boundary runtime loads")
	for input in inputs:
		sim.update_us(int(input.time_us) - sim.time_us)
		check(sim.select_front(input.column_id, input.team_id).ok, config.level_id + " accepts exact expected front")
		sim.drain_events()
	sim.update_us(final_time - sim.time_us - 1)
	check(sim.status == "running", config.level_id + " cannot win one microsecond before final hit")
	check(sim.board.is_empty() and sim.tasks.is_empty(), config.level_id + " board clear and final delivery are not victory")
	check(not sim.projectile.is_empty() and sim.armor_index == sim.armors.size() - 1, config.level_id + " final projectile is still authoritative")
	sim.update_us(1)
	check(sim.status == "victory" and sim.terminal_reason == "final_armor_hit", config.level_id + " final hit alone wins")
	check(sim.conservation_errors().is_empty(), config.level_id + " no invented or lost ammunition")
	var after: Dictionary = sim.snapshot()
	sim.update_us(100000000)
	check(sim.snapshot() == after, config.level_id + " terminal simulation is frozen")

func run() -> void:
	var silhouettes: Dictionary = {}
	var ids: Dictionary = {}
	var colors_seen: Dictionary = {}
	for index in range(1, 31):
		var path := "res://data/campaign-drafts/campaign-%02d.json" % index
		check(FileAccess.file_exists(path), "Draft %02d exists" % index)
		if not FileAccess.file_exists(path): continue
		var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var tag: String = config.level_id
		check(tag == "campaign-%02d" % index and not ids.has(tag), tag + " stable unique ID")
		ids[tag] = true
		check(config.content_kind == "authoring_draft" and config.production_level_number == null, tag + " is not promoted")
		check(int(config.level_number) == index and int(config.seed) == 2026102100 + index, tag + " intended unlock context and fixed seed")
		check(config.columns.size() == 5, tag + " has exactly five candidate columns")
		check(config.palette == Document.PALETTE, tag + " uses only the six supported colors")
		check(Rules.validate_level(config).is_empty(), tag + " complete authoritative structure and conservation")
		check(config.dragon.speed_units_sec > 0 and config.dragon.route_length > 0, tag + " has finite positive threat")
		check(config.dragon.knockback_distance > 0 and config.dragon.knockback_distance <= 0.55 and config.dragon.max_knockback_distance <= 0.55, tag + " has finite bounded knockback")
		var mask := ""
		for row in config.grid:
			for symbol in row: mask += "." if symbol == "." else "#"
			mask += "\n"
		var silhouette_hash := mask.sha256_text()
		check(not silhouettes.has(silhouette_hash), tag + " has a unique silhouette, not a recoloring")
		silhouettes[silhouette_hash] = tag
		var present_colors := 0
		for color in config.initial_color_counts:
			if int(config.initial_color_counts[color]) > 0:
				present_colors += 1
				colors_seen[color] = true
		check(present_colors <= 3 if index <= 5 else present_colors >= 4, tag + " follows the introductory/advanced color progression")
		var document = Document.new()
		check(document.import_json(JSON.stringify(config)).ok, tag + " imports into production authoring document")
		check(document.validation.status == "UNVERIFIED", tag + " imported claims require independent replay")
		var proof: Dictionary = config.validation
		check(proof.status == "TIMED_REPLAY_VERIFIED" and proof.human_playtest == "NOT_RUN" and proof.visual_acceptance == "NOT_RUN" and not proof.production_eligible, tag + " honest acceptance status")
		check(document.fingerprint() == proof.content_sha256, tag + " certificate matches exact current gameplay")
		check(proof.structural_errors.is_empty() and proof.conservation_errors.is_empty(), tag + " no structural or conservation errors")
		check(proof.color_conservation.size() == 6, tag + " explicit absent-color zeros")
		for row in proof.color_conservation:
			check(row.board == row.quota and row.board == row.armor, tag + " matched " + row.color + " ledger")
		var inputs: Array = proof.no_tool_solution
		check(not inputs.is_empty(), tag + " includes full timestamped no-tool selections")
		var prior := -750000
		for input in inputs:
			check(int(input.time_us) - prior >= 750000, tag + " uses human-paced selection spacing")
			check(input.get("action", "select_front") == "select_front", tag + " no hidden tools in replay")
			prior = int(input.time_us)
		var verifier = Verifier.new()
		var fresh: Dictionary = verifier.verify_level(config, inputs, 16000)
		check(fresh.get("ok", false) and fresh.get("terminal_reason") == "final_armor_hit", tag + " independent full winning replay")
		if not fresh.get("ok", false): continue
		check(fresh.terminal_time_us == int(proof.terminal_time_us) and fresh.final_hit_margin_us == int(proof.final_hit_margin_us), tag + " timing is reproducible")
		check(int(proof.timeline.final_hit_us) == int(proof.terminal_time_us) and proof.timeline.status == "victory", tag + " tail metrics include the terminal event")
		check(proof.timeline.armor_hits.size() == config.armors.size(), tag + " every armor has a recorded hit")
		check(int(proof.timeline.final_flight_us) == Rules.seconds_to_us(float(config.parameters.projectile_flight_sec)), tag + " full final projectile flight is budgeted")
		check(int(proof.timeline.last_delivery_us) <= int(proof.timeline.last_fire_us) and int(proof.timeline.last_pickup_us) < int(proof.timeline.last_delivery_us), tag + " pickup, delivery, fire, hit order")
		check(proof.timeline.pickup_to_final_hit_tail_us > 0 and proof.timeline.delivery_to_final_hit_tail_us > 0 and proof.final_hit_margin_us > 0, tag + " complete positive tail and threat margin")
		check(proof.timeline.max_occupied_slots <= 5 and proof.timeline.tool_uses == 0, tag + " five-slot no-tool proof")
		var boundaries: Dictionary = verifier.probe_boundaries(config, inputs, fresh.terminal_time_us, fresh.final_hit_margin_us)
		for name in ["exact_final_hit_tie", "contact_1us_earlier"]:
			check(boundaries[name].status == "PASS", tag + " boundary " + name)
			check(boundaries[name].conservation_errors.is_empty() and not boundaries[name].budget_exhausted, tag + " boundary is finite and conserving")
		check_last_flight(config, inputs, fresh.terminal_time_us)
		check(config.tools.size() == 4, tag + " four configured tools")
		var tool_sim = Rules.new()
		tool_sim.load_level(config)
		for tool in tool_sim.tool_states():
			check(tool.unlocked == (index >= int(tool.unlock_level)) and tool.remaining == 1, tag + " explicit tool unlock " + tool.id)
		check(FileAccess.file_exists(path.get_basename() + ".md"), tag + " standalone authoring sheet exists")
		check(FileAccess.file_exists(path.get_base_dir() + "/" + config.thumbnail), tag + " portable current thumbnail exists")
		check(not FileAccess.file_exists("res://data/levels/" + tag + ".json"), tag + " not silently promoted")
		entries.append({"level_id": tag, "status": "PASS", "final_hit_us": fresh.terminal_time_us, "margin_us": fresh.final_hit_margin_us, "replay_inputs": inputs.size(), "boundary_cases": 2, "human_playtest": "NOT_RUN"})
		print("PASS " + tag)
	check(ids.size() == 30 and silhouettes.size() == 30, "Exactly 30 unique IDs and silhouettes")
	check(colors_seen.size() == 6, "Campaign exercises all six supported colors")
	# Small finite negative proof checks: do not accidentally accept empty or tool replays.
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign-drafts/campaign-01.json"))
	var verifier = Verifier.new()
	check(not verifier.verify_level(fixture, [], 16000).ok, "Empty replay cannot verify")
	check(verifier.verify_level(fixture, [{"action": "shuffle"}], 16000).reason == "non_selection_action_forbidden", "Tool action cannot masquerade as no-tool proof")
	check(verifier.solve_level(fixture, 0).reason == "search_budget_exhausted", "Finite budget exhaustion stays unverified")
	var file := FileAccess.open("res://reports/campaign/test-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "PASS" if failures.is_empty() else "FAIL", "generated_at_utc": Time.get_datetime_string_from_system(true) + "Z", "assertions": assertions, "failures": failures, "levels": entries, "human_playtest": "NOT_RUN", "visual_acceptance": "NOT_RUN", "production_eligible": false}, "  ", true, false) + "\n")
	print("CAMPAIGN TESTS: %d assertions, %d failures, %d levels" % [assertions, failures.size(), entries.size()])
	quit(0 if failures.is_empty() else 1)
