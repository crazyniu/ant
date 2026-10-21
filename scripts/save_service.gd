extends RefCounted
## Synchronous, single-writer local progression. A candidate becomes visible only
## after verified temporary bytes atomically replace the primary file.

const SCHEMA_VERSION := 1
const DEFAULT_CAPACITY := 30
const DEFAULT_LEVELS := ["validation-01", "validation-02", "validation-03"]
const DEFAULT_VOLUME := 70
const PRIMARY_NAME := "save.json"
const BACKUP_NAME := "save.backup.json"

var base_path: String
var available_levels: Array[String] = []
var total_capacity: int
## Test-only one-stage fault injection; an empty string disables it.
var test_fail_stage := ""
var _loaded := false
var _ready := false
var _record: Dictionary = {}
var _disk_bytes := PackedByteArray()
var _disk_exists := false
var _reason := "not_loaded"
var _quarantine_path := ""
var _recovery_allowed := false
var _configuration_valid := true

func _init(directory: String = "user://ant-rescue", levels: Array = DEFAULT_LEVELS, capacity: int = DEFAULT_CAPACITY) -> void:
	base_path = directory
	total_capacity = capacity
	for level in levels:
		if not level is String or level.is_empty() or available_levels.has(level):
			_configuration_valid = false
		else:
			available_levels.append(level)
	_configuration_valid = _configuration_valid and not base_path.is_empty() and not available_levels.is_empty() and capacity >= available_levels.size() and capacity <= DEFAULT_CAPACITY

func load_save() -> Dictionary:
	_loaded = true
	_ready = false
	_recovery_allowed = false
	_quarantine_path = ""
	if not _configuration_valid:
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
				if name.begins_with("save.") and name.contains(".corrupt."):
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

func set_volumes(music: Variant, sfx: Variant) -> Dictionary:
	var prepared := _prepare_mutation()
	if not prepared.ok:
		return prepared
	if not _finite_number(music) or not _finite_number(sfx):
		return _result(false, "invalid_volume")
	var candidate := _record.duplicate(true)
	candidate.music_volume = clampi(roundi(float(music)), 0, 100)
	candidate.sfx_volume = clampi(roundi(float(sfx)), 0, 100)
	return _save_candidate(candidate)

func set_tutorial_completed(completed: bool = true) -> Dictionary:
	var prepared := _prepare_mutation()
	if not prepared.ok:
		return prepared
	var candidate := _record.duplicate(true)
	candidate.tutorial_completed = completed
	return _save_candidate(candidate)

func set_current_entrance(level_id: String) -> Dictionary:
	var prepared := _prepare_mutation()
	if not prepared.ok:
		return prepared
	var number := available_levels.find(level_id) + 1
	if number == 0:
		return _result(false, "level_unavailable")
	if number > int(_record.highest_unlocked):
		return _result(false, "level_locked")
	var candidate := _record.duplicate(true)
	candidate.current_entrance = {"level_id": level_id, "level_number": number}
	return _save_candidate(candidate)

func mark_complete(level_id: String, content_version: String) -> Dictionary:
	var prepared := _prepare_mutation()
	if not prepared.ok:
		return prepared
	var number := available_levels.find(level_id) + 1
	if number == 0:
		return _result(false, "level_unavailable")
	if number > int(_record.highest_unlocked):
		return _result(false, "level_locked")
	if content_version.strip_edges().is_empty():
		return _result(false, "invalid_content_version")
	var candidate := _record.duplicate(true)
	if not candidate.completed_levels.has(level_id):
		candidate.completed_levels[level_id] = {"level_number": number, "content_versions": []}
	var versions: Array = candidate.completed_levels[level_id].content_versions
	if versions.has(content_version):
		return _result(true, "already_completed")
	versions.append(content_version)
	# Completing a replay never revokes historical unlocks; missing production
	# content is still hidden by available_unlocked and next_level_id below.
	candidate.highest_unlocked = maxi(int(candidate.highest_unlocked), mini(number + 1, total_capacity))
	return _save_candidate(candidate)

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

func get_view_state() -> Dictionary:
	var state := {"schema_version": SCHEMA_VERSION, "completed_levels": {}, "highest_unlocked": 0, "current_entrance": {}, "tutorial_completed": false, "music_volume": DEFAULT_VOLUME, "sfx_volume": DEFAULT_VOLUME}
	state.merge(_record.duplicate(true), true)
	state.ready = _ready
	state.reason = _reason
	state.total_capacity = total_capacity
	state.available_level_count = available_levels.size()
	state.available_unlocked = mini(int(_record.get("highest_unlocked", 0)), available_levels.size()) if _ready else 0
	state.recovery_required = _loaded and not _ready
	state.recovery_allowed = _recovery_allowed
	state.corrupt_backup_path = _quarantine_path
	state.restart_mode = "level_start"
	state.resumes_in_progress_run = false
	state.levels = []
	for i in range(available_levels.size()):
		var level_id := available_levels[i]
		state.levels.append({"level_id": level_id, "number": i + 1, "unlocked": _ready and i < int(state.available_unlocked), "completed": _record.get("completed_levels", {}).has(level_id)})
	state.next_level_id = ""
	var entrance: Dictionary = _record.get("current_entrance", {})
	var number: int = int(entrance.get("level_number", 0))
	state.current_entrance_available = _ready and number > 0 and number <= int(state.available_unlocked)
	state.resume_level_id = entrance.get("level_id", "") if state.current_entrance_available else ""
	if _ready and state.resume_level_id.is_empty() and int(state.available_unlocked) > 0:
		state.resume_level_id = available_levels[int(state.available_unlocked) - 1]
	if _ready and number > 0 and number < int(state.available_unlocked) and _record.completed_levels.has(entrance.level_id):
		state.next_level_id = available_levels[number]
	return state

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
	var bytes := (JSON.stringify(candidate, "\t", true) + "\n").to_utf8_buffer()
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

func _decode(bytes: PackedByteArray) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary:
		return {"ok": false, "reason": "invalid_json"}
	var value: Dictionary = parser.data
	if not _integer(value.get("schema_version")):
		return {"ok": false, "reason": "invalid_schema"}
	if int(value.schema_version) != SCHEMA_VERSION:
		return {"ok": false, "reason": "unsupported_schema"}
	var fields := ["schema_version", "completed_levels", "highest_unlocked", "current_entrance", "tutorial_completed", "music_volume", "sfx_volume"]
	if value.size() != fields.size():
		return {"ok": false, "reason": "invalid_fields"}
	for field in fields:
		if not value.has(field):
			return {"ok": false, "reason": "missing_field"}
	if not value.completed_levels is Dictionary or not value.current_entrance is Dictionary or not value.tutorial_completed is bool:
		return {"ok": false, "reason": "invalid_fields"}
	if not _integer(value.highest_unlocked) or int(value.highest_unlocked) < 1 or int(value.highest_unlocked) > total_capacity:
		return {"ok": false, "reason": "invalid_unlock"}
	if not _finite_number(value.music_volume) or not _finite_number(value.sfx_volume):
		return {"ok": false, "reason": "invalid_volume"}
	var completed_numbers: Array[int] = []
	for id in value.completed_levels:
		var entry: Variant = value.completed_levels[id]
		if not id is String or id.is_empty() or not entry is Dictionary or entry.size() != 2 or not _integer(entry.get("level_number")) or not entry.get("content_versions") is Array:
			return {"ok": false, "reason": "invalid_completion"}
		var number := int(entry.level_number)
		if number < 1 or number > int(value.highest_unlocked) or completed_numbers.has(number) or entry.content_versions.is_empty():
			return {"ok": false, "reason": "invalid_completion"}
		if number <= available_levels.size() and available_levels[number - 1] != id:
			return {"ok": false, "reason": "catalog_mismatch"}
		var versions: Array[String] = []
		for version in entry.content_versions:
			if not version is String or version.strip_edges().is_empty() or versions.has(version):
				return {"ok": false, "reason": "invalid_content_version"}
			versions.append(version)
		completed_numbers.append(number)
	for number in range(1, int(value.highest_unlocked)):
		if not completed_numbers.has(number):
			return {"ok": false, "reason": "nonsequential_unlock"}
	if completed_numbers.has(int(value.highest_unlocked)) and int(value.highest_unlocked) < total_capacity:
		return {"ok": false, "reason": "inconsistent_unlock"}
	var entrance: Dictionary = value.current_entrance
	if entrance.size() != 2 or not entrance.get("level_id") is String or entrance.level_id.is_empty() or not _integer(entrance.get("level_number")):
		return {"ok": false, "reason": "invalid_entrance"}
	var number := int(entrance.level_number)
	if number < 1 or number > int(value.highest_unlocked):
		return {"ok": false, "reason": "invalid_entrance"}
	if number <= available_levels.size() and available_levels[number - 1] != entrance.level_id:
		return {"ok": false, "reason": "catalog_mismatch"}
	value.music_volume = clampi(roundi(float(value.music_volume)), 0, 100)
	value.sfx_volume = clampi(roundi(float(value.sfx_volume)), 0, 100)
	return {"ok": true, "record": value}

func _defaults() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "completed_levels": {}, "highest_unlocked": 1, "current_entrance": {"level_id": available_levels[0], "level_number": 1}, "tutorial_completed": false, "music_volume": DEFAULT_VOLUME, "sfx_volume": DEFAULT_VOLUME}

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
