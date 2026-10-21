extends SceneTree
## Draft-only batch authoring. Authoritative Document/Verifier/Rules own gameplay.
const Document = preload("res://scripts/editor_document.gd")
const Rules = preload("res://scripts/rescue_rules.gd")
const OUTPUT := "res://data/campaign-drafts"
const REPORTS := "res://reports/campaign"
var failed: Array = []
var manifest: Array = []
var through := 30

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--through="):
			through = clampi(int(arg.trim_prefix("--through=")), 1, 30)
	call_deferred("run")

func write_json(path: String, data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failed.append("Cannot write " + path)
		return
	file.store_string(JSON.stringify(data, "  ", true, false) + "\n")

func compact_timeline(config: Dictionary, inputs: Array) -> Dictionary:
	var sim = Rules.new()
	sim.load_level(config)
	var metrics := {"first_pickup_us": -1, "last_pickup_us": -1, "first_delivery_us": -1, "last_delivery_us": -1, "first_fire_us": -1, "last_fire_us": -1, "final_hit_us": -1, "max_occupied_slots": 0, "waiting_target_events": 0, "armor_hits": [], "tool_uses": 0, "conservation_errors": []}
	var cursor := 0
	var event_budget := 20000
	while event_budget > 0:
		event_budget -= 1
		if cursor < inputs.size() and sim.time_us == int(inputs[cursor].time_us):
			var input: Dictionary = inputs[cursor]
			if not sim.select_front(input.column_id, input.team_id).ok:
				metrics["error"] = "Rejected replay input"
				break
			cursor += 1
		metrics.max_occupied_slots = maxi(metrics.max_occupied_slots, 5 - sim.slots.count(null))
		for event in sim.drain_events():
			match event.type:
				"bead_picked_up":
					if metrics.first_pickup_us < 0: metrics.first_pickup_us = event.time_us
					metrics.last_pickup_us = event.time_us
				"bead_delivered":
					if metrics.first_delivery_us < 0: metrics.first_delivery_us = event.time_us
					metrics.last_delivery_us = event.time_us
				"cannon_fired":
					if metrics.first_fire_us < 0: metrics.first_fire_us = event.time_us
					metrics.last_fire_us = event.time_us
				"armor_broken":
					metrics.armor_hits.append({"armor_id": event.armor_id, "color": event.color, "demand": event.amount, "time_us": event.time_us, "knockback": event.applied_knockback})
				"team_work_state":
					if event.get("state") == "waiting_target": metrics.waiting_target_events += 1
				"tool_used": metrics.tool_uses += 1
				"victory": metrics.final_hit_us = event.time_us
		if sim.status not in ["ready", "running"]: break
		var next_time: int = sim._next_event_time()
		if cursor < inputs.size(): next_time = mini(next_time, int(inputs[cursor].time_us))
		if next_time == sim.NEVER or next_time < sim.time_us: break
		sim._advance_to(next_time)
	metrics["status"] = sim.status
	metrics["terminal_reason"] = sim.terminal_reason
	metrics["event_budget_remaining"] = event_budget
	metrics["conservation_errors"] = sim.conservation_errors()
	metrics["pickup_to_final_hit_tail_us"] = int(metrics.final_hit_us) - int(metrics.last_pickup_us)
	metrics["delivery_to_final_hit_tail_us"] = int(metrics.final_hit_us) - int(metrics.last_delivery_us)
	metrics["final_flight_us"] = int(metrics.final_hit_us) - int(metrics.last_fire_us)
	return metrics

func author_sheet(config: Dictionary) -> String:
	var v: Dictionary = config.validation
	var text := "# %02d · %s\n\n" % [int(config.campaign_draft_number), config.pattern_name]
	text += "Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.\n\n"
	text += "- Stable ID: `%s`; version: `%s`; seed: `%d`.\n" % [config.level_id, config.content_version, int(config.seed)]
	text += "- Goal: %s\n- Progression: %s.\n" % [config.objective, config.author_notes.progression_band]
	text += "- Thumbnail: [%s](%s-thumbnail.png).\n- Source: [%s](%s.json).\n\n" % [config.pattern_name, config.level_id, config.level_id, config.level_id]
	text += "## Board and conservation\n\n%d × %d. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.\n\n```text\n%s\n```\n\n" % [int(config.width), int(config.height), "\n".join(config.grid)]
	text += "| Color | Beads | Team quota | Armor demand |\n|---|---:|---:|---:|\n"
	for row in v.color_conservation:
		text += "| %s | %d | %d | %d |\n" % [row.color, row.board, row.quota, row.armor]
	text += "\n## Candidate columns (front → back)\n\n"
	for column in config.columns:
		var parts: Array[String] = []
		for team in column.teams: parts.append("%s %s ×%d" % [team.id, team.color, int(team.quota)])
		text += "- %s: %s.\n" % [column.id, " → ".join(parts) if not parts.is_empty() else "empty"]
	text += "\n%s\n\n## Complete armor order\n\n" % config.author_notes.queue_intent
	for armor in config.armors: text += "- %s: %s ×%d.\n" % [armor.id, armor.color, int(armor.demand)]
	text += "\n%s\n\n## Threat and timing\n\n" % config.author_notes.armor_intent
	text += "- Dragon start %.2f; route %.2f; speed %.2f units/s; initial distance %.2f.\n" % [config.dragon.initial_position, config.dragon.route_length, config.dragon.speed_units_sec, float(config.dragon.route_length)-float(config.dragon.initial_position)]
	text += "- Dispatch %.2fs; transport %.2f cells/s; in-flight cap %d; cannon cooldown %.2fs; flight %.2fs.\n" % [config.parameters.dispatch_interval_sec, config.parameters.transport_speed_cells_sec, int(config.parameters.max_inflight_ants), config.parameters.cannon_cooldown_sec, config.parameters.projectile_flight_sec]
	text += "- Minimum transport leg %.2fs; pickup hold %.2fs (simulation time; legacy omission = 0).\n" % [float(config.parameters.get("transport_min_leg_sec", 0.0)), float(config.parameters.get("pickup_pause_sec", 0.0))]
	text += "- Finite knockback %.2f, capped at %.2f and clamped at route start.\n" % [config.dragon.knockback_distance, config.dragon.max_knockback_distance]
	text += "- %s\n" % config.author_notes.time_budget_policy
	text += "\n## Tools\n\n"
	for tool in config.tools:
		text += "- %s: unlock %d; 1 use; %s in this draft's intended level context. No tools used by the proof.\n" % [tool.id, int(tool.unlock_level), "available" if int(config.level_number) >= int(tool.unlock_level) else "locked"]
	text += "\n## Automated proof\n\n- Status: %s; Rules %s; verified %s.\n- Gameplay hash: `%s`.\n" % [v.status, v.get("rules_api_version", ""), v.get("verified_at_utc", ""), v.get("content_sha256", "")]
	if v.get("ok", false):
		text += "- Final hit %.6fs; final-hit contact margin %.6fs; minimum click spacing 0.75s.\n" % [float(v.terminal_time_us)/1000000, float(v.final_hit_margin_us)/1000000]
		var timeline: Dictionary = v.timeline
		text += "- Last pickup %.6fs; last delivery %.6fs; final fire %.6fs; pickup-to-hit tail %.6fs; delivery-to-hit tail %.6fs.\n" % [float(timeline.last_pickup_us)/1000000, float(timeline.last_delivery_us)/1000000, float(timeline.last_fire_us)/1000000, float(timeline.pickup_to_final_hit_tail_us)/1000000, float(timeline.delivery_to_final_hit_tail_us)/1000000]
		text += "- Maximum occupied slots %d; target-wait events %d; tools used %d; conservation errors %d.\n\n" % [int(timeline.max_occupied_slots), int(timeline.waiting_target_events), int(timeline.tool_uses), timeline.conservation_errors.size()]
		text += "| Time (s) | Column | Expected front team |\n|---:|---|---|\n"
		for input in v.no_tool_solution: text += "| %.6f | %s | %s |\n" % [float(input.time_us)/1000000, input.column_id, input.team_id]
		text += "\n## Boundary test copies\n\n"
		for key in v.boundary_replays:
			var b: Dictionary = v.boundary_replays[key]
			if b.status == "NOT_RUN":
				text += "- %s: NOT_RUN. %s\n" % [key, b.get("reason", "No current boundary certificate.")]
			else:
				text += "- %s: %s; %s at %.6fs. Only the test copy's route is shortened; authored configuration is unchanged.\n" % [key, b.status, b.get("outcome", "n/a"), float(b.get("time_us", 0))/1000000]
	else:
		text += "- Failure reason: %s. No completion claim.\n" % v.get("reason", "unknown")
	text += "\n## Human inspection and acceptance\n\n%s\n\nCheck motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.\n" % config.author_notes.playtest_conclusion
	return text

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORTS))
	for index in range(1, through + 1):
		var path := OUTPUT + "/campaign-%02d.json" % index
		var document = Document.new()
		var imported: Dictionary = document.import_json(FileAccess.get_file_as_string(path))
		if not imported.ok:
			failed.append("%02d import: %s" % [index, imported.reason])
			continue
		var result: Dictionary = document.validate_solution(null, 16000)
		result["visual_acceptance"] = "NOT_RUN"
		if result.get("ok", false):
			result["timeline"] = compact_timeline(document.config, document.solution)
			for key in result.boundary_replays:
				if result.boundary_replays[key].status != "PASS": failed.append("%02d boundary: %s" % [index, key])
		else:
			failed.append("%02d proof: %s" % [index, result.get("reason", "unknown")])
		document.validation = result
		var exported: Dictionary = document.export_json(path)
		if not exported.ok: failed.append("%02d export: %s" % [index, exported.reason])
		var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var sheet := FileAccess.open(OUTPUT + "/campaign-%02d.md" % index, FileAccess.WRITE)
		sheet.store_string(author_sheet(config))
		var entry := {"level_id": config.level_id, "number": index, "name": config.pattern_name, "path": "res://data/campaign-drafts/campaign-%02d.json" % index, "sheet": "campaign-%02d.md" % index, "thumbnail": config.get("thumbnail", ""), "status": result.status, "human_playtest": "NOT_RUN", "visual_acceptance": "NOT_RUN", "production_eligible": false, "colors": config.initial_color_counts, "team_count": 0, "armor_count": config.armors.size(), "terminal_time_us": result.get("terminal_time_us", -1), "margin_us": result.get("final_hit_margin_us", -1), "content_sha256": result.get("content_sha256", "")}
		for column in config.columns: entry.team_count += column.teams.size()
		manifest.append(entry)
		print("%s %s: %s, hit %.3fs margin %.3fs" % [config.level_id, config.pattern_name, result.status, float(entry.terminal_time_us)/1000000, float(entry.margin_us)/1000000])
	write_json(REPORTS + "/manifest.json", {"content_version": "campaign-draft-1.0", "generated_at_utc": Time.get_datetime_string_from_system(true) + "Z", "requested": through, "completed": manifest.size(), "scope": "authoring_draft_timed_proofs", "runtime_catalog": "explicit_opt_in_campaign_drafts", "runtime_integration_reference": "docs/CAMPAIGN_FLOW.md", "human_playtest": "NOT_RUN", "visual_acceptance": "NOT_RUN", "failures": failed, "levels": manifest})
	print("CAMPAIGN BUILD: %d drafts; %d issues" % [manifest.size(), failed.size()])
	quit(0 if failed.is_empty() else 1)
