extends SceneTree

const SaveService = preload("res://scripts/save_service.gd")
var failures: Array[String] = []
var assertions := 0
var test_names: Array[String] = []
var fixture_root := "/tmp/ant-rescue-save-tests-%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()]
var fixture_number := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)
		push_error(message)

func new_service(levels: Array = SaveService.DEFAULT_LEVELS, capacity: int = 30):
	fixture_number += 1
	return SaveService.new(fixture_root.path_join(str(fixture_number)), levels, capacity)

func bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path)

func write(path: String, value: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "fixture can be written: " + path)
	if file:
		file.store_buffer(value if value is PackedByteArray else str(value).to_utf8_buffer())
		file.close()

func disk_record(service) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(service.base_path.path_join("save.json")))

func test_fresh_and_restart() -> void:
	test_names.append("fresh_initialization_restart_and_detached_safe_views")
	var service = new_service()
	check(not service.get_view_state().ready and service.get_view_state().available_unlocked == 0, "unloaded state exposes no playable unlock")
	var result: Dictionary = service.load_save()
	check(result.ok and result.reason == "initialized", "fresh absent save initializes atomically")
	check(result.state.highest_unlocked == 1 and result.state.available_unlocked == 1, "only first level begins unlocked")
	check(result.state.total_capacity == 30 and result.state.available_level_count == 3 and result.state.levels.size() == 3, "capacity thirty is distinct from three available levels")
	check(not result.state.tutorial_completed and result.state.music_volume == 70 and result.state.sfx_volume == 70, "fresh tutorial and independent audio defaults")
	check(bytes(service.base_path.path_join("save.json")) == bytes(service.base_path.path_join("save.backup.json")), "first committed record also has a valid backup")
	check(service.mark_complete("validation-01", "v1").ok, "first completion persists")
	check(service.set_current_entrance("validation-02").ok, "unlocked entrance persists")
	check(service.set_tutorial_completed().ok and service.set_volumes(0, 23).ok, "tutorial and both settings persist")
	var restarted = SaveService.new(service.base_path)
	var loaded: Dictionary = restarted.load_save()
	check(loaded.ok and loaded.state.current_entrance.level_id == "validation-02", "process restart returns selected level entrance")
	check(loaded.state.restart_mode == "level_start" and not loaded.state.resumes_in_progress_run, "restart explicitly means new level, not frame continuation")
	check(loaded.state.music_volume == 0 and loaded.state.sfx_volume == 23 and loaded.state.tutorial_completed, "restart restores independent zero-mute settings and tutorial")
	check(disk_record(service).keys().size() == 7 and not disk_record(service).has("run_id") and not disk_record(service).has("inventory"), "no volatile simulation or economy is serialized")
	loaded.state.completed_levels.clear()
	loaded.state.current_entrance.level_id = "tampered"
	loaded.state.levels.clear()
	check(restarted.get_view_state().completed_levels.has("validation-01") and restarted.get_view_state().current_entrance.level_id == "validation-02" and restarted.get_view_state().levels.size() == 3, "returned nested views cannot mutate committed state")

func test_sequential_idempotent_progression() -> void:
	test_names.append("sequential_unlock_replay_content_versions_and_missing_next_content")
	var service = new_service()
	check(service.mark_complete("validation-02", "v1").reason == "level_locked", "mutation first loads and rejects completing locked level")
	check(service.mark_complete("not-built", "v1").reason == "level_unavailable", "unavailable content cannot complete")
	check(service.mark_complete("validation-01", " ").reason == "invalid_content_version", "blank content version rejected")
	check(service.set_current_entrance("validation-02").reason == "level_locked", "locked level cannot become entrance")
	check(service.set_current_entrance("not-built").reason == "level_unavailable", "unavailable level cannot become entrance")
	var complete: Dictionary = service.mark_complete("validation-01", "v1")
	check(complete.ok and complete.state.highest_unlocked == 2 and complete.state.next_level_id == "validation-02", "first saved victory exposes next real level")
	var original := bytes(service.base_path.path_join("save.json"))
	var backup := bytes(service.base_path.path_join("save.backup.json"))
	service.test_fail_stage = "write_temp"
	check(service.mark_complete("validation-01", "v1").reason == "already_completed", "exact duplicate is a no-write success even when writes fail")
	check(bytes(service.base_path.path_join("save.json")) == original and bytes(service.base_path.path_join("save.backup.json")) == backup, "idempotent completion changes no primary or backup bytes")
	service.test_fail_stage = ""
	check(service.mark_complete("validation-02", "v1").ok and service.mark_complete("validation-03", "v1").ok, "available levels complete sequentially")
	check(service.set_current_entrance("validation-03").ok, "select last available level")
	check(service.get_view_state().highest_unlocked == 4 and service.get_view_state().available_unlocked == 3 and service.get_view_state().next_level_id.is_empty(), "future fourth unlock is recorded but no absent next level is offered")
	check(service.mark_complete("validation-01", "v2").ok, "a distinct content version is recorded")
	var view: Dictionary = service.get_view_state()
	check(view.highest_unlocked == 4 and view.completed_levels["validation-01"].content_versions == ["v1", "v2"], "completed replay preserves unlocks and all completion versions")
	check(SaveService.new(service.base_path).load_save().state.highest_unlocked == 4, "highest unlock survives relaunch")

func test_all_thirty_and_catalog_subset() -> void:
	test_names.append("thirty_level_capacity_final_level_and_smaller_available_catalog")
	var levels: Array = SaveService.DEFAULT_LEVELS.duplicate()
	for i in range(4, 31):
		levels.append("production-%02d" % i)
	var service = new_service(levels)
	for level in levels:
		check(service.mark_complete(level, "release-1").ok, "full capacity completion: " + level)
	check(service.set_current_entrance(levels[29]).ok, "final level may be current entrance")
	check(service.get_view_state().highest_unlocked == 30 and service.get_view_state().next_level_id.is_empty(), "final production level never unlocks thirty-one")
	var restarted = SaveService.new(service.base_path, levels)
	check(restarted.load_save().state.completed_levels.size() == 30, "all thirty completions survive reload")
	var smaller = SaveService.new(service.base_path)
	var result: Dictionary = smaller.load_save()
	check(result.ok and result.state.highest_unlocked == 30 and result.state.available_unlocked == 3, "smaller catalog does not revoke or truncate saved progress")
	check(not result.state.current_entrance_available and result.state.resume_level_id == "validation-03", "unavailable saved entrance gives a safe available fallback without rewriting history")
	check(smaller.set_volumes(31, 72).ok and disk_record(smaller).completed_levels.size() == 30, "settings change in smaller build preserves all thirty completions")

func test_settings_clamping_and_load_before_write() -> void:
	test_names.append("load_before_write_audio_clamping_and_concurrent_snapshot_refresh")
	var initial = new_service()
	initial.mark_complete("validation-01", "v1")
	var other = SaveService.new(initial.base_path)
	check(other.set_volumes(-20, 130).ok, "settings mutation loads existing progression first")
	check(other.get_view_state().music_volume == 0 and other.get_view_state().sfx_volume == 100 and other.get_view_state().highest_unlocked == 2, "volume endpoints clamp independently without resetting progression")
	check(initial.set_tutorial_completed().ok, "stale service reloads before its write")
	check(initial.get_view_state().music_volume == 0 and initial.get_view_state().sfx_volume == 100, "stale instance does not revert newer settings")
	check(initial.set_volumes(40.4, 60.6).ok and initial.get_view_state().music_volume == 40 and initial.get_view_state().sfx_volume == 61, "finite fractional slider values round to whole percent")
	var prior := bytes(initial.base_path.path_join("save.json"))
	for invalid in [NAN, INF, -INF, "50", null, true]:
		check(not initial.set_volumes(invalid, 50).ok and not initial.set_volumes(50, invalid).ok, "non-finite or nonnumeric setting rejected: " + str(invalid))
	check(bytes(initial.base_path.path_join("save.json")) == prior, "invalid settings never alter disk")
	initial.test_fail_stage = "write_temp"
	check(initial.set_volumes(40, 61).reason == "unchanged", "same settings are a no-write success")
	check(initial.set_tutorial_completed().reason == "unchanged", "same tutorial flag is a no-write success")
	var committed: Dictionary = initial.get_view_state()
	check(not initial.set_volumes(0, 0).ok and initial.get_view_state() == committed, "failed settings commit cannot leak preview values into saved state")
	check(not initial.set_tutorial_completed(false).ok and initial.get_view_state() == committed, "failed tutorial commit preserves previous flag")

func test_atomic_faults_and_retries() -> void:
	test_names.append("finite_fault_matrix_preserves_primary_no_false_unlock_and_idempotent_retry")
	for stage in ["write_temp", "verify_temp", "write_backup", "verify_backup", "replace_backup", "replace_primary"]:
		var service = new_service()
		service.mark_complete("validation-01", "v1")
		var original := bytes(service.base_path.path_join("save.json"))
		var before: Dictionary = service.get_view_state()
		service.test_fail_stage = stage
		var result: Dictionary = service.mark_complete("validation-02", "v1")
		check(not result.ok, stage + ": injected failure reported")
		check(result.state == before and result.state.highest_unlocked == 2 and not result.state.completed_levels.has("validation-02"), stage + ": no candidate data or false unlock leaks into memory")
		check(bytes(service.base_path.path_join("save.json")) == original, stage + ": old primary remains byte-exact")
		var restarted = SaveService.new(service.base_path)
		check(restarted.load_save().ok and restarted.get_view_state().highest_unlocked == 2, stage + ": restart ignores uncommitted temporary candidate")
		service.test_fail_stage = ""
		check(service.mark_complete("validation-02", "v1").ok and service.get_view_state().highest_unlocked == 3, stage + ": successful retry commits once")
		var committed := bytes(service.base_path.path_join("save.json"))
		check(bytes(service.base_path.path_join("save.backup.json")) == original, stage + ": previous valid record is backup")
		check(service.mark_complete("validation-02", "v1").reason == "already_completed" and bytes(service.base_path.path_join("save.json")) == committed, stage + ": duplicate retry is exactly idempotent")

func test_corruption_and_explicit_recovery() -> void:
	test_names.append("corruption_preserved_reported_and_explicit_backup_recovery")
	var service = new_service()
	service.mark_complete("validation-01", "v1")
	service.set_volumes(12, 34)
	var backup := bytes(service.base_path.path_join("save.backup.json"))
	var corrupted := "{ broken JSON: 这是原始损坏记录".to_utf8_buffer()
	write(service.base_path.path_join("save.json"), corrupted)
	var result: Dictionary = service.load_save()
	check(not result.ok and result.reason == "corrupt_save_recovery_required" and result.state.recovery_allowed, "corrupt data becomes recoverable error, never implicit defaults")
	check(result.state.available_unlocked == 0 and result.state.next_level_id.is_empty(), "recovery state offers no gameplay or next-level unlock")
	check(bytes(result.state.corrupt_backup_path) == corrupted and bytes(service.base_path.path_join("save.json")) == corrupted, "exact damaged bytes are quarantined while primary remains untouched")
	check(bytes(service.base_path.path_join("save.backup.json")) == backup, "last-valid backup is not replaced by corrupt bytes")
	check(not service.set_volumes(80, 80).ok and not service.mark_complete("validation-02", "v1").ok, "ordinary writes cannot bypass corruption recovery")
	service.test_fail_stage = "replace_primary"
	check(not service.recover_from_backup().ok and bytes(service.base_path.path_join("save.json")) == corrupted, "failed recovery leaves damaged original and old backup intact")
	service.test_fail_stage = ""
	var recovered: Dictionary = service.recover_from_backup()
	check(recovered.ok and recovered.reason == "recovered_backup" and recovered.state.highest_unlocked == 2, "explicit backup recovery restores previously committed progress")
	check(bytes(service.base_path.path_join("save.backup.json")) == backup, "recovery itself preserves valid backup")
	check(SaveService.new(service.base_path).load_save().ok, "recovered primary is independently readable")
	check(service.recover_from_backup().reason == "recovery_not_required", "valid primary cannot accidentally be downgraded to older backup")

func test_no_backup_reset_and_preservation_failure() -> void:
	test_names.append("explicit_reset_confirmation_and_failed_quarantine_safety")
	var service = new_service()
	var corrupt := "not a save".to_utf8_buffer()
	write(service.base_path.path_join("save.json"), corrupt)
	service.test_fail_stage = "quarantine"
	check(service.load_save().reason == "corrupt_backup_failed" and not service.get_view_state().recovery_allowed, "quarantine failure blocks destructive recovery")
	check(not service.recover_with_defaults(true).ok and bytes(service.base_path.path_join("save.json")) == corrupt, "cannot reset while original preservation fails")
	service.test_fail_stage = ""
	check(service.load_save().reason == "corrupt_save_recovery_required", "repaired storage can preserve corruption")
	check(service.recover_from_backup().reason == "no_valid_backup", "absent backup is reported without reset")
	check(service.recover_with_defaults().reason == "reset_confirmation_required" and bytes(service.base_path.path_join("save.json")) == corrupt, "explicit destructive reset flag is mandatory")
	var preserved: String = service.get_view_state().corrupt_backup_path
	check(service.recover_with_defaults(true).ok and service.get_view_state().highest_unlocked == 1, "confirmed reset can establish a fresh valid record")
	check(bytes(preserved) == corrupt, "confirmed reset still preserves original corrupt bytes")
	check(bytes(service.base_path.path_join("save.backup.json")) == bytes(service.base_path.path_join("save.json")), "reset without a prior valid backup establishes a valid first backup")
	check(SaveService.new(service.base_path).load_save().ok, "reset primary loads after restart")

func test_future_schema_and_structural_damage() -> void:
	test_names.append("future_schema_never_overwritten_and_invalid_structure_quarantined")
	var service = new_service()
	service.load_save()
	var future := disk_record(service)
	future.schema_version = 99
	write(service.base_path.path_join("save.json"), JSON.stringify(future))
	var original := bytes(service.base_path.path_join("save.json"))
	check(service.load_save().reason == "unsupported_schema" and not service.get_view_state().recovery_allowed, "future schema reported distinctly and recovery disabled")
	check(not service.mark_complete("validation-01", "v1").ok and not service.recover_from_backup().ok and not service.recover_with_defaults(true).ok, "future schema cannot be overwritten by mutation, backup downgrade, or default reset")
	check(bytes(service.base_path.path_join("save.json")) == original, "future file remains byte-exact")
	var future_backup = new_service()
	write(future_backup.base_path.path_join("save.backup.json"), original)
	check(future_backup.load_save().reason == "missing_primary_recovery_required", "orphan future backup still requires recovery")
	check(future_backup.recover_from_backup().reason == "backup_unsupported_schema" and future_backup.recover_with_defaults(true).reason == "backup_unsupported_schema", "future backup cannot be silently downgraded or reset")
	check(bytes(future_backup.base_path.path_join("save.backup.json")) == original and not FileAccess.file_exists(future_backup.base_path.path_join("save.json")), "unsupported backup remains exact and no lower-schema primary is created")
	var mutations: Array = [
		func(record: Dictionary): record.highest_unlocked = 3,
		func(record: Dictionary): record.highest_unlocked = 1.5,
		func(record: Dictionary): record.current_entrance.level_number = 2,
		func(record: Dictionary): record.tutorial_completed = "true",
		func(record: Dictionary): record.music_volume = "loud",
		func(record: Dictionary): record.completed_levels = [],
		func(record: Dictionary): record.erase("sfx_volume"),
		func(record: Dictionary): record.unexpected_run_state = {},
		func(record: Dictionary): record.schema_version = null,
	]
	for mutate in mutations:
		var damaged = new_service()
		damaged.load_save()
		var record := disk_record(damaged)
		mutate.call(record)
		write(damaged.base_path.path_join("save.json"), JSON.stringify(record))
		check(damaged.load_save().reason == "corrupt_save_recovery_required", "structurally invalid known-schema record is quarantined")

func test_missing_primary_orphans_and_io_failures() -> void:
	test_names.append("missing_primary_orphans_nonfresh_evidence_and_filesystem_errors")
	var service = new_service()
	service.mark_complete("validation-01", "v1")
	service.set_volumes(15, 25)
	DirAccess.remove_absolute(service.base_path.path_join("save.json"))
	check(service.load_save().reason == "missing_primary_recovery_required", "missing primary with backup is not fresh initialization")
	check(service.recover_from_backup().ok and service.get_view_state().highest_unlocked == 2, "explicit missing-primary recovery retains backup progress")
	DirAccess.remove_absolute(service.base_path.path_join("save.json"))
	DirAccess.remove_absolute(service.base_path.path_join("save.backup.json"))
	check(service.load_save().reason == "missing_primary_recovery_required", "known in-memory history prevents fresh initialization after external removal of both files")
	var orphan = new_service()
	write(orphan.base_path.path_join("save.json.tmp"), "uncommitted candidate")
	check(orphan.load_save().reason == "missing_primary_recovery_required" and not FileAccess.file_exists(orphan.base_path.path_join("save.json")), "orphan candidate cannot masquerade as fresh or committed data")
	check(orphan.recover_from_backup().reason == "no_valid_backup", "orphan does not become an implicit backup")
	check(orphan.recover_with_defaults(true).ok, "explicit reset may replace preserved orphan")
	var evidence = new_service()
	write(evidence.base_path.path_join("save.json.corrupt.previous.json"), "previous data")
	check(evidence.load_save().reason == "missing_primary_recovery_required", "quarantine-only evidence prevents silent fresh start")
	var blocked = new_service()
	write(blocked.base_path, "directory blocked by regular file")
	check(not blocked.load_save().ok and FileAccess.get_file_as_string(blocked.base_path) == "directory blocked by regular file", "directory creation failure does not replace blocking file")
	var directory = new_service()
	DirAccess.make_dir_recursive_absolute(directory.base_path.path_join("save.json"))
	check(directory.load_save().reason == "path_is_directory", "directory at save path is not treated as absent data")
	var invalid = new_service([], 30)
	check(invalid.load_save().reason == "invalid_configuration", "empty catalog rejected before any writes")
	var duplicate = new_service(["a", "a"], 30)
	check(duplicate.load_save().reason == "invalid_configuration", "duplicate catalog IDs rejected")
	var broken_backup = new_service()
	write(broken_backup.base_path.path_join("save.json"), "bad primary")
	write(broken_backup.base_path.path_join("save.backup.json"), "bad backup")
	check(broken_backup.load_save().reason == "corrupt_save_recovery_required" and broken_backup.recover_from_backup().reason == "no_valid_backup", "invalid backup is not used as recovery data")
	check(broken_backup.recover_with_defaults(true).ok, "confirmed reset can replace a preserved invalid backup")
	var preserved_backup_found := false
	for file in DirAccess.get_files_at(broken_backup.base_path):
		if file.begins_with("save.backup.json.corrupt.") and FileAccess.get_file_as_string(broken_backup.base_path.path_join(file)) == "bad backup":
			preserved_backup_found = true
	check(preserved_backup_found and bytes(broken_backup.base_path.path_join("save.backup.json")) == bytes(broken_backup.base_path.path_join("save.json")), "invalid backup remains quarantined while live backup is valid after explicit reset")

func test_loaded_volume_normalization() -> void:
	test_names.append("loaded_numeric_audio_limits_clamp_without_autowriting")
	var service = new_service()
	service.load_save()
	var record := disk_record(service)
	record.music_volume = -2.5
	record.sfx_volume = 200
	write(service.base_path.path_join("save.json"), JSON.stringify(record))
	var original := bytes(service.base_path.path_join("save.json"))
	var result: Dictionary = service.load_save()
	check(result.ok and result.state.music_volume == 0 and result.state.sfx_volume == 100, "out-of-range finite saved slider values normalize safely")
	check(bytes(service.base_path.path_join("save.json")) == original, "loading and normalization never write over a valid existing record")

func remove_fixture(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	for child in DirAccess.get_directories_at(path):
		remove_fixture(path.path_join(child))
	DirAccess.remove_absolute(path)

func run() -> void:
	test_fresh_and_restart()
	test_sequential_idempotent_progression()
	test_all_thirty_and_catalog_subset()
	test_settings_clamping_and_load_before_write()
	test_atomic_faults_and_retries()
	test_corruption_and_explicit_recovery()
	test_no_backup_reset_and_preservation_failure()
	test_future_schema_and_structural_damage()
	test_missing_primary_orphans_and_io_failures()
	test_loaded_volume_normalization()
	remove_fixture(fixture_root)
	print(JSON.stringify({"pass": failures.is_empty(), "assertions": assertions, "tests": test_names, "failures": failures, "engine": Engine.get_version_info().string, "scope": "Isolated save/progression service; finite actual disk failure injection and restart/recovery tests. No game UI integration or hard-power-loss guarantee claimed."}, "\t"))
	quit(0 if failures.is_empty() else 1)
