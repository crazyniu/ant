extends RefCounted
## Game 2 single-ant economy. Synchronous, single-writer, local-only transactions.
## All returned dictionaries are detached; callers cannot mutate the live ledger.
## Never use wall-clock duration: settlement accepts authoritative simulation time.

const SCHEMA_VERSION := 1
const ECONOMY_VERSION := 1
const PROFILE := "game2-ant-single-v1"
const PROFILE_DIRECTORY := "ant-single-v1"
const CONFIG_PATH := "res://data/ant-progression.json"
const PRIMARY_NAME := "progression.json"
const BACKUP_NAME := "progression.backup.json"
const MAX_EXACT_INTEGER := 9007199254740991

var base_path: String
## Only disk fault injection is supported. There is no test-ad reward capability.
var test_fail_stage := ""
var _loaded := false
var _ready := false
var _record: Dictionary = {}
var _config: Dictionary = {}
var _disk_bytes := PackedByteArray()
var _disk_exists := false
var _reason := "not_loaded"
var _quarantine_path := ""
var _recovery_allowed := false

func _init(profile_root: String = "user://ant-rescue") -> void:
	base_path = profile_root.path_join(PROFILE_DIRECTORY) if not profile_root.is_empty() else ""

static func generate_run_id() -> String:
	return "run-" + Crypto.new().generate_random_bytes(16).hex_encode()

func _load_config() -> bool:
	if base_path.is_empty():
		return false
	if not _config.is_empty():
		return true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if not parsed is Dictionary or parsed.get("schema_version") != 1 or parsed.get("economy_version") != ECONOMY_VERSION or parsed.get("profile") != PROFILE:
		return false
	if not parsed.get("types") is Dictionary or not parsed.get("levels") is Dictionary or not parsed.get("rewards") is Dictionary:
		return false
	if parsed.types.keys().size() != 2 or not parsed.types.has("worker") or not parsed.types.has("swift") or parsed.levels.size() != 4:
		return false
	for type_id in ["worker", "swift"]:
		if not _valid_product(parsed.types[type_id]):
			return false
	for level in range(1, 5):
		if not parsed.levels.has(str(level)) or not _valid_product(parsed.levels[str(level)]):
			return false
	for field in ["first_base", "first_time_max", "repeat_base", "repeat_time_max"]:
		if not _natural(parsed.rewards.get(field)):
			return false
	if parsed.types.worker.price != 0 or parsed.levels["1"].price != 0 or parsed.types.worker.speed_multiplier != 1.0 or parsed.levels["1"].speed_multiplier != 1.0:
		return false
	if not _finite_number(parsed.get("max_speed_multiplier")) or parsed.max_speed_multiplier < 1.0 or parsed.max_speed_multiplier > 1.5 or parsed.get("rewarded_ad_provider") != "unavailable":
		return false
	_config = parsed.duplicate(true)
	return true

func _valid_product(value: Variant) -> bool:
	return value is Dictionary and _natural(value.get("price")) and _finite_number(value.get("speed_multiplier")) and value.speed_multiplier >= 1.0 and value.speed_multiplier <= 1.5

func create_run(run_id: String, level_id: String, fast_seconds: Variant, normal_seconds: Variant) -> Dictionary:
	var prepared := _prepare_mutation()
	if not prepared.ok:
		return prepared
	if not _valid_id(run_id) or not _valid_id(level_id):
		return _result(false, "invalid_run_identity")
	if not _valid_thresholds(fast_seconds, normal_seconds):
		return _result(false, "invalid_reward_thresholds")
	if _record.runs.has(run_id):
		var prior: Dictionary = _record.runs[run_id]
		if prior.level_id != level_id or prior.fast_seconds != fast_seconds or prior.normal_seconds != normal_seconds:
			return _result(false, "run_id_conflict")
		return _run_result(true, "already_created", run_id)
	var candidate := _record.duplicate(true)
	candidate.runs[run_id] = {"level_id": level_id, "fast_seconds": float(fast_seconds), "normal_seconds": float(normal_seconds), "loadout": _loadout(_record.equipped_type, int(_record.level)), "outcome": "running", "receipt": {}}
	var saved := _save_candidate(candidate)
	return _run_result(true, "run_created", run_id) if saved.ok else saved

func get_run(run_id: String) -> Dictionary:
	return _record.get("runs", {}).get(run_id, {}).duplicate(true)

func settle_run(run_id: String, outcome: String, elapsed_sim_seconds: Variant) -> Dictionary:
	var prepared := _prepare_mutation()
	if not prepared.ok:
		return prepared
	if not _record.runs.has(run_id):
		return _result(false, "run_not_found")
	if not outcome in ["won", "lost", "cancelled"]:
		return _result(false, "invalid_run_outcome")
	var run: Dictionary = _record.runs[run_id]
	if run.outcome != "running":
		return _run_result(run.outcome == outcome, "already_settled" if run.outcome == outcome else "run_outcome_conflict", run_id)
	if not _finite_number(elapsed_sim_seconds) or float(elapsed_sim_seconds) < 0.0:
		return _result(false, "invalid_simulation_time")
	var first_clear: bool = outcome == "won" and not _record.completed_levels.has(run.level_id)
	var receipt := _reward(outcome, first_clear, float(elapsed_sim_seconds), float(run.fast_seconds), float(run.normal_seconds))
	if int(_record.balance) > MAX_EXACT_INTEGER - int(receipt.total):
		return _result(false, "balance_limit")
	var candidate := _record.duplicate(true)
	candidate.runs[run_id].outcome = outcome
	candidate.runs[run_id].receipt = receipt
	candidate.balance = int(candidate.balance) + int(receipt.total)
	if first_clear:
		candidate.completed_levels[run.level_id] = run_id
	var saved := _save_candidate(candidate)
	return _run_result(true, "settled", run_id) if saved.ok else saved

func purchase(request_id: String, product_id: String) -> Dictionary:
	var prepared := _prepare_mutation()
	if not prepared.ok:
		return prepared
	if not _valid_id(request_id):
		return _result(false, "invalid_request_id")
	if _record.purchases.has(request_id):
		var prior: Dictionary = _record.purchases[request_id]
		var duplicate_result := _result(prior.product_id == product_id, "already_purchased" if prior.product_id == product_id else "request_id_conflict")
		duplicate_result.transaction = prior.duplicate(true)
		return duplicate_result
	var cost := 0
	var next_level := 0
	if product_id == "worker":
		return _result(true, "already_owned")
	elif product_id == "swift":
		if _record.owned_types.has("swift"):
			return _result(true, "already_owned")
		cost = int(_config.types.swift.price)
	elif product_id in ["level_2", "level_3", "level_4"]:
		next_level = int(product_id.right(1))
		if int(_record.level) >= next_level:
			return _result(true, "already_owned")
		if int(_record.level) != next_level - 1:
			return _result(false, "level_prerequisite")
		cost = int(_config.levels[str(next_level)].price)
	else:
		return _result(false, "product_not_found")
	if int(_record.balance) < cost:
		return _result(false, "insufficient_points")
	var candidate := _record.duplicate(true)
	candidate.balance = int(candidate.balance) - cost
	if next_level > 0:
		candidate.level = next_level
	else:
		candidate.owned_types.append("swift")
	candidate.purchases[request_id] = {"product_id": product_id, "cost": cost}
	var saved := _save_candidate(candidate)
	if saved.ok:
		saved.reason = "purchased"
		saved.transaction = candidate.purchases[request_id].duplicate(true)
	return saved

func equip(type_id: String) -> Dictionary:
	var prepared := _prepare_mutation()
	if not prepared.ok:
		return prepared
	if not _record.owned_types.has(type_id):
		return _result(false, "type_not_owned")
	var candidate := _record.duplicate(true)
	candidate.equipped_type = type_id
	return _save_candidate(candidate)

func set_navigation(navigation: Dictionary) -> Dictionary:
	var prepared := _prepare_mutation()
	if not prepared.ok:
		return prepared
	if not _valid_navigation(navigation):
		return _result(false, "invalid_navigation")
	var candidate := _record.duplicate(true)
	candidate.navigation = navigation.duplicate(true)
	return _save_candidate(candidate)

func _valid_navigation(value: Variant) -> bool:
	return value is Dictionary and value.size() == 3 and value.get("region_id") is String and value.region_id.length() <= 160 and _finite_number(value.get("scroll_y")) and float(value.scroll_y) >= 0.0 and _integer(value.get("selected_level")) and int(value.selected_level) >= 1 and int(value.selected_level) <= 30

func rewarded_ad_status(run_id: String = "") -> Dictionary:
	return {"available": false, "reason": "ad_sdk_unavailable", "run_id": run_id, "additional_points": 0}

func request_rewarded_ad(run_id: String) -> Dictionary:
	return {"ok": false, "reason": "ad_sdk_unavailable", "run_id": run_id}

func claim_rewarded_ad(run_id: String, reward_id: String, _provider_receipt: Dictionary = {}) -> Dictionary:
	# Deliberately has no success path, provider injection, debug flag or fake reward.
	# A future SDK must validate a provider receipt and atomically journal both IDs.
	return {"ok": false, "reason": "ad_sdk_unavailable", "run_id": run_id, "reward_id": reward_id}

func get_view_state() -> Dictionary:
	var state := {"schema_version": SCHEMA_VERSION, "profile": PROFILE, "balance": 0, "owned_types": [], "equipped_type": "", "level": 0, "completed_levels": {}}
	for key in ["balance", "owned_types", "equipped_type", "level", "completed_levels", "navigation"]:
		if _record.has(key):
			state[key] = _record[key].duplicate(true) if _record[key] is Dictionary or _record[key] is Array else _record[key]
	state.points = state.balance
	state.carry_level = state.level
	state.type_multipliers = {}
	state.level_multiplier = 1.0
	state.navigation = _record.get("navigation", {"region_id": "", "scroll_y": 0.0, "selected_level": 1}).duplicate(true)
	state.ready = _ready
	state.reason = _reason
	state.recovery_required = _loaded and not _ready
	state.recovery_allowed = _recovery_allowed
	state.corrupt_backup_path = _quarantine_path
	state.ad_available = false
	state.ad_reason = "ad_sdk_unavailable"
	state.shop = []
	state.loadout = {}
	if _ready:
		state.loadout = _loadout(state.equipped_type, int(state.level))
		state.level_multiplier = state.loadout.level_multiplier
		for type_id in ["worker", "swift"]:
			state.type_multipliers[type_id] = float(_config.types[type_id].speed_multiplier)
		for type_id in ["worker", "swift"]:
			state.shop.append({"product_id": type_id, "price": int(_config.types[type_id].price), "owned": state.owned_types.has(type_id), "equipped": state.equipped_type == type_id, "speed_multiplier": float(_config.types[type_id].speed_multiplier), "available": not state.owned_types.has(type_id) and int(state.balance) >= int(_config.types[type_id].price)})
		for level in range(2, 5):
			state.shop.append({"product_id": "level_" + str(level), "price": int(_config.levels[str(level)].price), "owned": int(state.level) >= level, "equipped": int(state.level) == level, "speed_multiplier": float(_config.levels[str(level)].speed_multiplier), "available": int(state.level) == level - 1 and int(state.balance) >= int(_config.levels[str(level)].price)})
	return state

func _loadout(type_id: String, level: int) -> Dictionary:
	var type_multiplier := float(_config.types[type_id].speed_multiplier)
	var level_multiplier := float(_config.levels[str(level)].speed_multiplier)
	return {"ant_type": type_id, "level": level, "type_multiplier": type_multiplier, "level_multiplier": level_multiplier, "speed_multiplier": minf(type_multiplier * level_multiplier, float(_config.max_speed_multiplier))}

func _reward(outcome: String, first_clear: bool, elapsed: float, fast: float, normal: float) -> Dictionary:
	var base := 0
	var bonus := 0
	if outcome == "won":
		base = int(_config.rewards.first_base if first_clear else _config.rewards.repeat_base)
		var maximum := int(_config.rewards.first_time_max if first_clear else _config.rewards.repeat_time_max)
		bonus = floori(maximum * clampf((normal - elapsed) / (normal - fast), 0.0, 1.0))
	return {"elapsed_sim_seconds": elapsed, "first_clear": first_clear, "base": base, "time_bonus": bonus, "total": base + bonus}

func _run_result(ok: bool, reason: String, run_id: String) -> Dictionary:
	var result := _result(ok, reason)
	result.run = get_run(run_id)
	result.run_id = run_id
	return result

func _valid_id(value: Variant) -> bool:
	return value is String and not value.is_empty() and value == value.strip_edges() and value.length() <= 160

func _valid_thresholds(fast: Variant, normal: Variant) -> bool:
	return _finite_number(fast) and _finite_number(normal) and float(fast) > 0.0 and float(normal) > float(fast)

func _natural(value: Variant) -> bool:
	return _integer(value) and float(value) >= 0.0 and float(value) <= MAX_EXACT_INTEGER

func _defaults() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "economy_version": ECONOMY_VERSION, "profile": PROFILE, "balance": 0, "owned_types": ["worker"], "equipped_type": "worker", "level": 1, "completed_levels": {}, "runs": {}, "purchases": {}, "navigation": {"region_id": "", "scroll_y": 0.0, "selected_level": 1}}

func _decode(bytes: PackedByteArray) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {"ok": false, "reason": "invalid_json"}
	var value: Dictionary = parser.data
	if not _integer(value.get("schema_version")) or not _integer(value.get("economy_version")):
		return {"ok": false, "reason": "invalid_schema"}
	if value.schema_version != SCHEMA_VERSION or value.economy_version != ECONOMY_VERSION:
		return {"ok": false, "reason": "unsupported_schema"}
	var fields := _defaults().keys()
	if value.size() != fields.size():
		return {"ok": false, "reason": "invalid_fields"}
	for field in fields:
		if not value.has(field):
			return {"ok": false, "reason": "missing_field"}
	if not _valid_navigation(value.navigation) or value.profile != PROFILE or not _natural(value.balance) or not _integer(value.level) or int(value.level) < 1 or int(value.level) > 4:
		return {"ok": false, "reason": "invalid_profile"}
	if not value.owned_types is Array or not value.runs is Dictionary or not value.purchases is Dictionary or not value.completed_levels is Dictionary:
		return {"ok": false, "reason": "invalid_fields"}
	if value.owned_types != ["worker"] and value.owned_types != ["worker", "swift"]:
		return {"ok": false, "reason": "invalid_owned_types"}
	if not value.owned_types.has(value.equipped_type):
		return {"ok": false, "reason": "invalid_equipped_type"}
	var earned := 0
	var first_clears := {}
	for run_id in value.runs:
		var run: Variant = value.runs[run_id]
		if not _valid_id(run_id) or not _valid_run(run):
			return {"ok": false, "reason": "invalid_run"}
		if not value.owned_types.has(run.loadout.ant_type) or int(run.loadout.level) > int(value.level):
			return {"ok": false, "reason": "invalid_run_loadout"}
		if run.outcome == "running":
			continue
		var receipt: Dictionary = run.receipt
		var expected_reward := _reward(run.outcome, receipt.first_clear, float(receipt.elapsed_sim_seconds), float(run.fast_seconds), float(run.normal_seconds))
		if receipt.base != expected_reward.base or receipt.time_bonus != expected_reward.time_bonus or receipt.total != expected_reward.total:
			return {"ok": false, "reason": "invalid_reward"}
		if earned > MAX_EXACT_INTEGER - int(receipt.total):
			return {"ok": false, "reason": "balance_limit"}
		earned += int(receipt.total)
		if receipt.first_clear:
			if run.outcome != "won" or first_clears.has(run.level_id):
				return {"ok": false, "reason": "duplicate_first_clear"}
			first_clears[run.level_id] = run_id
	if first_clears != value.completed_levels:
		return {"ok": false, "reason": "invalid_completion_ledger"}
	for run in value.runs.values():
		if run.outcome == "won" and not first_clears.has(run.level_id):
			return {"ok": false, "reason": "missing_first_clear"}
	var products := []
	var spent := 0
	for request_id in value.purchases:
		var entry: Variant = value.purchases[request_id]
		if not _valid_id(request_id) or not entry is Dictionary or entry.size() != 2 or not entry.get("product_id") in ["swift", "level_2", "level_3", "level_4"] or not _natural(entry.get("cost")) or products.has(entry.product_id):
			return {"ok": false, "reason": "invalid_purchase"}
		var expected_cost := int(_config.types.swift.price) if entry.product_id == "swift" else int(_config.levels[entry.product_id.right(1)].price)
		if int(entry.cost) != expected_cost:
			return {"ok": false, "reason": "invalid_purchase_cost"}
		products.append(entry.product_id)
		if spent > MAX_EXACT_INTEGER - int(entry.cost):
			return {"ok": false, "reason": "balance_limit"}
		spent += int(entry.cost)
	if value.owned_types.has("swift") != products.has("swift"):
		return {"ok": false, "reason": "invalid_ownership_ledger"}
	for level in range(2, 5):
		if (int(value.level) >= level) != products.has("level_" + str(level)):
			return {"ok": false, "reason": "invalid_level_ledger"}
	if spent > earned or int(value.balance) != earned - spent:
		return {"ok": false, "reason": "invalid_balance_ledger"}
	# JSON reads numbers as doubles; normalize typed ledger integers after validation.
	value.balance = int(value.balance)
	value.level = int(value.level)
	value.navigation.selected_level = int(value.navigation.selected_level)
	for run in value.runs.values():
		run.loadout = _loadout(run.loadout.ant_type, int(run.loadout.level))
		if run.outcome != "running":
			for field in ["base", "time_bonus", "total"]:
				run.receipt[field] = int(run.receipt[field])
	for entry in value.purchases.values():
		entry.cost = int(entry.cost)
	return {"ok": true, "record": value}

func _valid_run(run: Variant) -> bool:
	if not run is Dictionary or run.size() != 6 or not _valid_id(run.get("level_id")) or not _valid_thresholds(run.get("fast_seconds"), run.get("normal_seconds")) or not run.get("loadout") is Dictionary or not run.get("receipt") is Dictionary or not run.get("outcome") in ["running", "won", "lost", "cancelled"]:
		return false
	var loadout: Dictionary = run.loadout
	if not loadout.get("ant_type") in ["worker", "swift"] or not _integer(loadout.get("level")) or int(loadout.level) < 1 or int(loadout.level) > 4 or loadout.size() != 5:
		return false
	var expected := _loadout(loadout.ant_type, int(loadout.level))
	for field in ["type_multiplier", "level_multiplier", "speed_multiplier"]:
		if not _finite_number(loadout.get(field)) or absf(float(loadout[field]) - float(expected[field])) > 0.000000001:
			return false
	if run.outcome == "running":
		return run.receipt.is_empty()
	var receipt: Dictionary = run.receipt
	return receipt.size() == 5 and _finite_number(receipt.get("elapsed_sim_seconds")) and float(receipt.elapsed_sim_seconds) >= 0.0 and receipt.get("first_clear") is bool and _natural(receipt.get("base")) and _natural(receipt.get("time_bonus")) and _natural(receipt.get("total"))

func load_save() -> Dictionary:
	_loaded = true
	_ready = false
	_recovery_allowed = false
	_quarantine_path = ""
	if not _load_config():
		return _blocked("invalid_configuration")
	var primary := _read_bytes(_path(PRIMARY_NAME))
	if not primary.ok:
		return _blocked(primary.reason)
	_disk_exists = primary.exists
	_disk_bytes = primary.bytes
	if not primary.exists:
		# A missing primary is fresh only when there is no evidence of prior data.
		if not _record.is_empty():
			_recovery_allowed = true
			return _blocked("missing_primary_recovery_required")
		for name in [BACKUP_NAME, PRIMARY_NAME + ".tmp", BACKUP_NAME + ".tmp"]:
			if _exists(_path(name)):
				_recovery_allowed = true
				return _blocked("missing_primary_recovery_required")
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(base_path)):
			for name in DirAccess.get_files_at(base_path):
				if name.begins_with("progression.") and name.contains(".corrupt."):
					_recovery_allowed = true
					return _blocked("missing_primary_recovery_required")
		return _commit(_defaults(), false, "initialized")
	var parsed := _decode(primary.bytes)
	if not parsed.ok:
		if parsed.reason == "unsupported_schema":
			return _blocked("unsupported_schema")
		var preserved := _quarantine(_path(PRIMARY_NAME), primary.bytes)
		if not preserved.ok:
			return _blocked("corrupt_backup_failed")
		_quarantine_path = preserved.path
		_recovery_allowed = true
		return _blocked("corrupt_save_recovery_required")
	_record = parsed.record
	_ready = true
	_reason = "loaded"
	return _result(true, "loaded")

func recover_from_backup() -> Dictionary:
	var prepared := _prepare_recovery()
	if not prepared.ok:
		return prepared
	var backup := _read_bytes(_path(BACKUP_NAME))
	if not backup.ok or not backup.exists:
		return _result(false, "no_valid_backup")
	var parsed := _decode(backup.bytes)
	if not parsed.ok:
		return _result(false, "backup_unsupported_schema" if parsed.reason == "unsupported_schema" else "no_valid_backup")
	# Preserve the backup during recovery, including when primary replacement fails.
	return _commit(parsed.record, true, "recovered_backup")

func recover_with_defaults(confirm_progress_reset: bool = false) -> Dictionary:
	if not confirm_progress_reset:
		return _result(false, "reset_confirmation_required")
	var prepared := _prepare_recovery()
	if not prepared.ok:
		return prepared
	var backup := _read_bytes(_path(BACKUP_NAME))
	var keep_valid_backup := false
	if backup.ok and backup.exists:
		var decoded := _decode(backup.bytes)
		if not decoded.ok and decoded.reason == "unsupported_schema":
			return _result(false, "backup_unsupported_schema")
		keep_valid_backup = decoded.ok
	# Explicit reset still preserves every extant recovery file before replacement.
	for name in [BACKUP_NAME, PRIMARY_NAME + ".tmp", BACKUP_NAME + ".tmp"]:
		var existing := _read_bytes(_path(name))
		if not existing.ok:
			return _result(false, "recovery_preservation_failed")
		if existing.exists:
			var preserved := _quarantine(_path(name), existing.bytes)
			if not preserved.ok:
				return _result(false, "recovery_preservation_failed")
	return _commit(_defaults(), keep_valid_backup, "recovered_defaults")

func _prepare_mutation() -> Dictionary:
	if not _loaded or not _ready:
		return load_save()
	# Re-read before every mutation. Another service instance's settings/progress
	# cannot be overwritten by this instance's stale snapshot.
	var disk := _read_bytes(_path(PRIMARY_NAME))
	if not disk.ok:
		return _blocked(disk.reason)
	if disk.exists != _disk_exists or disk.bytes != _disk_bytes:
		return load_save()
	return _result(true, "ready")

func _prepare_recovery() -> Dictionary:
	var loaded := load_save()
	if loaded.ok:
		return _result(false, "recovery_not_required")
	if not _recovery_allowed:
		return _result(false, _reason)
	# A stale candidate is never a committed record and must not silently win.
	for name in [PRIMARY_NAME + ".tmp", BACKUP_NAME + ".tmp"]:
		var temp := _read_bytes(_path(name))
		if not temp.ok:
			return _result(false, "recovery_preservation_failed")
		if temp.exists and not _quarantine(_path(name), temp.bytes).ok:
			return _result(false, "recovery_preservation_failed")
	return _result(true, "recovery_ready")

func _save_candidate(candidate: Dictionary) -> Dictionary:
	if candidate == _record:
		return _result(true, "unchanged")
	return _commit(candidate, false, "saved")

func _commit(candidate: Dictionary, keep_backup: bool, success_reason: String) -> Dictionary:
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_path))
	if directory_error != OK:
		return _result(false, "directory_write_failed")
	var now := _read_bytes(_path(PRIMARY_NAME))
	if not now.ok or now.exists != _disk_exists or now.bytes != _disk_bytes:
		return _result(false, "storage_changed_retry_load")
	var bytes := (JSON.stringify(candidate, "\t", true, true) + "\n").to_utf8_buffer()
	var temp := _path(PRIMARY_NAME + ".tmp")
	if not _write_verified(temp, bytes, "write_temp", "verify_temp"):
		return _result(false, "temporary_write_failed")
	if not keep_backup:
		var backup_bytes := _disk_bytes if _ready and _disk_exists else bytes
		var backup_temp := _path(BACKUP_NAME + ".tmp")
		if not _write_verified(backup_temp, backup_bytes, "write_backup", "verify_backup"):
			return _result(false, "backup_write_failed")
		if not _replace(backup_temp, _path(BACKUP_NAME), "replace_backup"):
			return _result(false, "backup_replace_failed")
	if not _replace(temp, _path(PRIMARY_NAME), "replace_primary"):
		return _result(false, "primary_replace_failed")
	_record = candidate.duplicate(true)
	_disk_bytes = bytes
	_disk_exists = true
	_ready = true
	_recovery_allowed = false
	_reason = success_reason
	return _result(true, success_reason)

func _write_verified(path: String, bytes: PackedByteArray, write_stage: String, verify_stage: String) -> bool:
	if _should_fail(write_stage):
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(bytes)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or _should_fail(verify_stage):
		return false
	var check := _read_bytes(path)
	return check.ok and check.exists and check.bytes == bytes

func _replace(source: String, target: String, stage: String) -> bool:
	if _should_fail(stage):
		return false
	# Same-directory rename: never unlink the previous primary first.
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(target)) == OK

func _should_fail(stage: String) -> bool:
	return test_fail_stage == stage

func _quarantine(source: String, bytes: PackedByteArray) -> Dictionary:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	var destination := source + ".corrupt." + hash.finish().hex_encode() + ".json"
	var prior := _read_bytes(destination)
	if prior.ok and prior.exists and prior.bytes == bytes:
		return {"ok": true, "path": destination}
	if _should_fail("quarantine") or not _write_verified(destination + ".tmp", bytes, "write_quarantine", "verify_quarantine"):
		return {"ok": false}
	if not _replace(destination + ".tmp", destination, "replace_quarantine"):
		return {"ok": false}
	return {"ok": true, "path": destination}

func _read_bytes(path: String) -> Dictionary:
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		return {"ok": false, "reason": "path_is_directory", "exists": true, "bytes": PackedByteArray()}
	if not FileAccess.file_exists(path):
		return {"ok": true, "exists": false, "bytes": PackedByteArray()}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "reason": "read_failed", "exists": true, "bytes": PackedByteArray()}
	var expected := file.get_length()
	var bytes := file.get_buffer(expected)
	var error := file.get_error()
	file.close()
	return {"ok": bytes.size() == expected and error == OK, "reason": "read_failed", "exists": true, "bytes": bytes}

func _exists(path: String) -> bool:
	return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path))

func _finite_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

func _integer(value: Variant) -> bool:
	return _finite_number(value) and floor(float(value)) == float(value)

func _path(name: String) -> String:
	return base_path.path_join(name)

func _blocked(reason: String) -> Dictionary:
	_ready = false
	_reason = reason
	return _result(false, reason)

func _result(ok: bool, reason: String) -> Dictionary:
	return {"ok": ok, "reason": reason, "state": get_view_state()}
