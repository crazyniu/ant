extends SceneTree

const Progression = preload("res://scripts/ant_progression.gd")
var assertions := 0
var failures: Array[String] = []
var cases: Array[String] = []
var fixture_number := 0
var fixture_root := "/tmp/ant-progression-tests-%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()]

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	assertions += 1
	if not condition:
		failures.append(description)
		push_error(description)

func service():
	fixture_number += 1
	return Progression.new(fixture_root.path_join(str(fixture_number)))

func primary(s) -> String:
	return s.base_path.path_join(Progression.PRIMARY_NAME)

func read(s) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(primary(s)))

func write(path: String, data: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "fixture is writable")
	if file:
		file.store_string(data if data is String else JSON.stringify(data))
		file.close()

func win(s, id: String, level_id: String, seconds: float = 10.0) -> Dictionary:
	check(s.create_run(id, level_id, 10.0, 30.0).ok, "create reward fixture " + id)
	return s.settle_run(id, "won", seconds)

func funded_service():
	var s = service()
	for i in range(8):
		check(win(s, "earned-%s" % i, "serpent-%s" % i).ok, "fund through a unique real settlement API")
	check(s.get_view_state().points == 1200, "eight test wins produce 1200 points")
	return s

func test_defaults_isolation_and_restart() -> void:
	cases.append("defaults, profile isolation, detached views, durable navigation and restart")
	var s = service()
	check(not s.get_view_state().ready, "unloaded service is not ready")
	var root: String = s.base_path.get_base_dir()
	var legacy_path := root.path_join("save.json")
	var game1_path := root.path_join("game1/save.json")
	write(legacy_path, "legacy must remain untouched")
	write(game1_path, "game1 must remain untouched")
	var loaded: Dictionary = s.load_save()
	check(loaded.ok and loaded.reason == "initialized", "fresh economy initializes atomically")
	check(loaded.state.balance == 0 and loaded.state.points == 0, "new economy has no gifted points")
	check(loaded.state.owned_types == ["worker"] and loaded.state.equipped_type == "worker", "free worker starts owned/equipped")
	check(loaded.state.carry_level == 1 and loaded.state.loadout.speed_multiplier == 1.0, "level one worker is baseline")
	check(loaded.state.type_multipliers == {"worker": 1.0, "swift": 1.2} and loaded.state.level_multiplier == 1.0, "UI multipliers exposed")
	check(loaded.state.shop[1].price == 500 and loaded.state.shop[2].price == 100 and loaded.state.shop[3].price == 150 and loaded.state.shop[4].price == 250, "config contains exact initial costs")
	check(s.base_path.ends_with("/ant-single-v1") and FileAccess.file_exists(primary(s)), "economy always uses its own profile child")
	check(FileAccess.get_file_as_string(legacy_path) == "legacy must remain untouched" and FileAccess.get_file_as_string(game1_path) == "game1 must remain untouched", "legacy and game1 bytes unchanged")
	var navigation := {"region_id": "forest", "scroll_y": 624.5, "selected_level": 3}
	check(s.set_navigation(navigation).ok, "map location saves")
	navigation.selected_level = 30
	check(s.get_view_state().navigation.selected_level == 3, "navigation input is detached")
	check(s.set_navigation({"region_id": "forest", "scroll_y": -1, "selected_level": 1}).reason == "invalid_navigation", "negative scroll rejected")
	check(s.set_navigation({"region_id": "forest", "scroll_y": 0, "selected_level": 31}).reason == "invalid_navigation", "out of catalog number rejected")
	var restarted = Progression.new(root)
	check(restarted.load_save().ok and restarted.get_view_state().navigation.scroll_y == 624.5, "map location survives restart")
	var view: Dictionary = s.get_view_state()
	view.owned_types.append("swift")
	view.navigation.region_id = "changed"
	view.shop.clear()
	check(s.get_view_state().owned_types == ["worker"] and s.get_view_state().navigation.region_id == "forest" and s.get_view_state().shop.size() == 5, "returned nested views cannot edit ledger")
	check(s.purchase("free-worker", "worker").reason == "already_owned", "worker is never repeatedly purchased")
	check(s.equip("swift").reason == "type_not_owned", "unowned type cannot be equipped")
	check(s.purchase("no-points", "swift").reason == "insufficient_points", "insufficient funds denied without debt")
	check(s.purchase("skip", "level_3").reason == "level_prerequisite", "cannot skip level prerequisite")
	check(Progression.generate_run_id() != Progression.generate_run_id(), "generated run identifiers differ")

func test_rewards_and_idempotency() -> void:
	cases.append("clamped linear first/repeat rewards, effective simulation time, terminal run IDs")
	var s = service()
	for i in range(6):
		var seconds: float = [0.0, 10.0, 15.0, 20.0, 30.0, 50.0][i]
		var bonus: int = [50, 50, 37, 25, 0, 0][i]
		var result := win(s, "first-%s" % i, "level-%s" % i, seconds)
		check(result.ok and result.run.receipt.base == 100 and result.run.receipt.time_bonus == bonus and result.run.receipt.total == 100 + bonus and result.run.receipt.first_clear, "first-clear linear/floor/clamp at " + str(seconds))
		var repeat := win(s, "repeat-%s" % i, "level-%s" % i, seconds)
		var repeat_bonus: int = [10, 10, 7, 5, 0, 0][i]
		check(repeat.ok and repeat.run.receipt.base == 20 and repeat.run.receipt.time_bonus == repeat_bonus and not repeat.run.receipt.first_clear, "repeat linear/floor/clamp at " + str(seconds))
	var before := FileAccess.get_file_as_bytes(primary(s))
	var points: int = s.get_view_state().points
	for i in range(5):
		check(s.settle_run("first-0", "won", 999.0).reason == "already_settled", "duplicate victory returns original receipt despite callback delay")
	check(s.settle_run("first-0", "won", 999).run.receipt.total == 150 and s.get_view_state().points == points, "duplicate cannot replace original elapsed/reward")
	check(FileAccess.get_file_as_bytes(primary(s)) == before, "duplicate callbacks cause no writes")
	var restarted = Progression.new(s.base_path.get_base_dir())
	check(restarted.load_save().ok and restarted.settle_run("first-0", "won", 0).reason == "already_settled" and restarted.get_view_state().points == points, "run reward is idempotent across restart")
	check(s.create_run("first-0", "different", 10, 30).reason == "run_id_conflict", "same run ID cannot identify another level")
	check(s.create_run("first-0", "level-0", 10, 31).reason == "run_id_conflict", "same run cannot change thresholds")
	check(s.create_run("first-0", "level-0", 10, 30).reason == "already_created", "same create request idempotent")
	for outcome in ["lost", "cancelled"]:
		check(s.create_run(outcome, "no-clear", 10, 30).ok, "terminal non-win created")
		var ended: Dictionary = s.settle_run(outcome, outcome, 25)
		check(ended.ok and ended.run.receipt.total == 0 and ended.state.points == points and not ended.state.completed_levels.has("no-clear"), "failure/cancellation grants zero and preserves balance")
		check(s.settle_run(outcome, "won", 10).reason == "run_outcome_conflict", "failed/abandoned run cannot be turned into reward")
	check(s.settle_run("missing", "won", 10).reason == "run_not_found", "unknown run callback cannot mint points")
	check(s.create_run("invalid-time", "level", 30, 30).reason == "invalid_reward_thresholds", "equal thresholds rejected")
	check(s.create_run("invalid-time", "level", 0, 30).reason == "invalid_reward_thresholds", "nonpositive fast threshold rejected")
	check(s.create_run("invalid-time", "level", 10, NAN).reason == "invalid_reward_thresholds", "nonfinite threshold rejected")
	check(s.create_run("active", "level", 40, 80).ok, "per-level distinct thresholds accepted")
	for invalid in [-1, NAN, INF, "10", null, true]:
		check(s.settle_run("active", "won", invalid).reason == "invalid_simulation_time", "invalid elapsed rejected: " + str(invalid))
	check(s.settle_run("active", "victory", 40).reason == "invalid_run_outcome", "invalid terminal status rejected")
	check(s.settle_run("active", "won", 60).run.receipt.time_bonus == 25, "duration uses the run's own level thresholds")

func test_purchase_equip_and_frozen_loadout() -> void:
	cases.append("atomic unlock/upgrade costs, request idempotency and frozen run loadout")
	var s = funded_service()
	check(s.create_run("before-upgrades", "frozen", 10, 30).ok, "freeze baseline run")
	check(s.purchase("buy-swift", "swift").ok and s.get_view_state().points == 700, "swift debits 500 and unlocks")
	check(s.get_view_state().equipped_type == "worker", "purchase does not silently equip")
	check(s.equip("swift").ok, "owned swift equips")
	check(s.purchase("buy-l2", "level_2").ok and s.get_view_state().points == 600, "shared level 2 costs 100")
	check(s.purchase("buy-l3", "level_3").ok and s.get_view_state().points == 450, "shared level 3 costs 150")
	check(s.purchase("buy-l4", "level_4").ok and s.get_view_state().points == 200, "shared level 4 costs 250")
	var view: Dictionary = s.get_view_state()
	check(view.carry_level == 4 and is_equal_approx(view.loadout.speed_multiplier, 1.38) and view.loadout.speed_multiplier <= 1.5, "swift L4 = 1.2 * 1.15 = 1.38, no cumulative level stacking")
	check(s.create_run("after-upgrades", "frozen", 10, 30).run.loadout.speed_multiplier == view.loadout.speed_multiplier, "new run freezes newly equipped loadout")
	check(s.get_run("before-upgrades").loadout.ant_type == "worker" and s.get_run("before-upgrades").loadout.level == 1 and s.get_run("before-upgrades").loadout.speed_multiplier == 1.0, "earlier entire run keeps worker L1")
	check(s.equip("worker").ok and is_equal_approx(s.get_view_state().loadout.speed_multiplier, 1.15), "level is shared across types")
	check(s.get_run("after-upgrades").loadout.ant_type == "swift", "changing equipment does not mutate an active run")
	var detached: Dictionary = s.get_run("after-upgrades")
	detached.loadout.speed_multiplier = 50
	check(is_equal_approx(s.get_run("after-upgrades").loadout.speed_multiplier, 1.38), "returned run cannot mutate frozen loadout")
	var prior := FileAccess.get_file_as_bytes(primary(s))
	s.test_fail_stage = "write_temp"
	check(s.purchase("buy-swift", "swift").reason == "already_purchased" and s.purchase("buy-l2", "level_2").reason == "already_purchased", "same purchase requests are no-write successes")
	check(s.purchase("another-swift", "swift").reason == "already_owned", "new request for owned product never debits")
	check(s.purchase("buy-swift", "level_4").reason == "request_id_conflict", "request ID bound to exact product")
	check(s.purchase("", "swift").reason == "invalid_request_id", "blank purchase request rejected")
	check(s.purchase("unknown", "cash").reason == "product_not_found", "no external economy product")
	check(FileAccess.get_file_as_bytes(primary(s)) == prior and s.get_view_state().points == 200, "rapid duplicate actions leave exact disk balance unchanged")
	s.test_fail_stage = ""
	var restarted = Progression.new(s.base_path.get_base_dir())
	check(restarted.load_save().ok and restarted.get_view_state().carry_level == 4 and restarted.get_view_state().points == 200, "complete purchase ledger restarts")
	check(restarted.purchase("buy-l4", "level_4").reason == "already_purchased", "purchase callback deduplicates after restart")

func test_atomic_fault_matrix() -> void:
	cases.append("six persistence fault stages x five transaction categories, exact rollback and retry")
	for stage in ["write_temp", "verify_temp", "write_backup", "verify_backup", "replace_backup", "replace_primary"]:
		for operation in ["create", "settle", "purchase", "equip", "navigation"]:
			var s = funded_service()
			if operation == "settle":
				check(s.create_run("fault-run", "fault-level", 10, 30).ok, "pre-create failed-settlement run")
			if operation == "equip":
				check(s.purchase("pre-unlock", "swift").ok, "pre-unlock equipment")
			var before := FileAccess.get_file_as_bytes(primary(s))
			var state: Dictionary = s.get_view_state()
			s.test_fail_stage = stage
			var result := perform(s, operation)
			check(not result.ok and s.get_view_state() == state, stage + "/" + operation + ": no candidate leaks into committed view")
			check(FileAccess.get_file_as_bytes(primary(s)) == before, stage + "/" + operation + ": primary bytes untouched")
			var restarted = Progression.new(s.base_path.get_base_dir())
			check(restarted.load_save().ok and read(restarted) == JSON.parse_string(before.get_string_from_utf8()), stage + "/" + operation + ": restart ignores uncommitted temporary file")
			s.test_fail_stage = ""
			check(perform(s, operation).ok, stage + "/" + operation + ": retry commits once")
			var committed := FileAccess.get_file_as_bytes(primary(s))
			check(perform(s, operation).ok and FileAccess.get_file_as_bytes(primary(s)) == committed, stage + "/" + operation + ": duplicate retry does not rewrite")

func perform(s, operation: String) -> Dictionary:
	match operation:
		"create": return s.create_run("fault-run", "fault-level", 10, 30)
		"settle": return s.settle_run("fault-run", "won", 20)
		"purchase": return s.purchase("fault-purchase", "swift")
		"equip": return s.equip("swift")
		_: return s.set_navigation({"region_id": "ruins", "scroll_y": 120, "selected_level": 2})

func test_ads_and_stale_readers() -> void:
	cases.append("no mock ad reward capability, no duplicate callbacks, stale reader refresh")
	var s = funded_service()
	var before := FileAccess.get_file_as_bytes(primary(s))
	for i in range(4):
		check(not s.rewarded_ad_status("earned-0").available, "ad is visibly unavailable")
		check(s.request_rewarded_ad("earned-0").reason == "ad_sdk_unavailable", "no fake playback")
		check(s.claim_rewarded_ad("earned-0", "reward-0", {"verified": true, "completed": true, "test": true}).reason == "ad_sdk_unavailable", "fabricated receipt is never accepted")
	check(FileAccess.get_file_as_bytes(primary(s)) == before, "ad requests/callbacks cannot change balance or ledger")
	var other = Progression.new(s.base_path.get_base_dir())
	check(other.load_save().ok, "second instance loads")
	check(s.purchase("writer-one", "swift").ok, "first writer buys swift")
	check(other.purchase("writer-two", "level_2").ok and other.get_view_state().points == 600 and other.get_view_state().owned_types.has("swift"), "stale instance refreshes balance/ownership before debit")
	check(s.purchase("writer-two", "level_2").reason == "already_purchased" and s.get_view_state().carry_level == 2, "older instance sees other's request ledger")
	var restarted = Progression.new(s.base_path.get_base_dir())
	check(restarted.load_save().ok and restarted.claim_rewarded_ad("earned-0", "reward-0").reason == "ad_sdk_unavailable", "restart cannot enable ad reward")

func test_recovery_versions_and_ledger_validation() -> void:
	cases.append("recoverable corruption, future-version guard, missing primary and ledger validation")
	var s = funded_service()
	check(s.set_navigation({"region_id": "forest", "scroll_y": 1, "selected_level": 2}).ok, "last known backup contains funded ledger")
	var backup_path: String = s.base_path.path_join(Progression.BACKUP_NAME)
	var backup := FileAccess.get_file_as_bytes(backup_path)
	write(primary(s), "{ broken ")
	var corrupt := FileAccess.get_file_as_bytes(primary(s))
	var result: Dictionary = s.load_save()
	check(not result.ok and result.reason == "corrupt_save_recovery_required" and result.state.recovery_allowed, "damaged primary requires explicit recovery")
	check(FileAccess.get_file_as_bytes(result.state.corrupt_backup_path) == corrupt and FileAccess.get_file_as_bytes(backup_path) == backup, "damage quarantined exactly and backup preserved")
	check(not s.purchase("blocked", "swift").ok and not s.equip("worker").ok, "no economic mutation while damaged")
	s.test_fail_stage = "replace_primary"
	check(not s.recover_from_backup().ok and FileAccess.get_file_as_bytes(primary(s)) == corrupt, "failed recovery preserves original")
	s.test_fail_stage = ""
	check(s.recover_from_backup().ok and s.get_view_state().points == 1200 and FileAccess.get_file_as_bytes(backup_path) == backup, "explicit recovery restores previous committed economy")
	check(s.recover_from_backup().reason == "recovery_not_required", "valid primary cannot accidentally roll back")
	var record := read(s)
	record.schema_version = 999
	write(primary(s), record)
	var future := FileAccess.get_file_as_bytes(primary(s))
	check(s.load_save().reason == "unsupported_schema" and not s.recover_with_defaults(true).ok and not s.recover_from_backup().ok, "future schema cannot be downgraded/reset")
	check(FileAccess.get_file_as_bytes(primary(s)) == future, "future bytes stay exact")
	var missing = funded_service()
	DirAccess.remove_absolute(primary(missing))
	check(missing.load_save().reason == "missing_primary_recovery_required", "orphan backup never treated as fresh profile")
	check(missing.recover_from_backup().ok, "orphan known-version backup recovers explicitly")
	var orphan = service()
	write(orphan.base_path.path_join(Progression.PRIMARY_NAME + ".tmp"), JSON.stringify({"not_committed": true}))
	check(orphan.load_save().reason == "missing_primary_recovery_required" and orphan.recover_from_backup().reason == "no_valid_backup", "uncommitted candidate never promoted into awards")
	check(orphan.recover_with_defaults().reason == "reset_confirmation_required", "no implicit progress reset")
	check(orphan.recover_with_defaults(true).ok, "explicit reset preserves orphan then initializes")
	var mutators: Array = [
		func(v: Dictionary): v.balance = 999,
		func(v: Dictionary): v.owned_types.append("swift"),
		func(v: Dictionary): v.equipped_type = "swift",
		func(v: Dictionary): v.level = 4,
		func(v: Dictionary): v.profile = "game1",
		func(v: Dictionary): v.runs["earned-0"].receipt.total = 999,
		func(v: Dictionary): v.runs["earned-0"].loadout.speed_multiplier = 2,
		func(v: Dictionary): v.completed_levels.clear(),
		func(v: Dictionary): v.navigation.scroll_y = -2,
		func(v: Dictionary): v.unexpected_ad_reward = 120,
	]
	for mutate in mutators:
		var invalid = funded_service()
		var value := read(invalid)
		mutate.call(value)
		write(primary(invalid), value)
		check(invalid.load_save().reason == "corrupt_save_recovery_required", "structural/economy inconsistency cannot be accepted")

func run() -> void:
	test_defaults_isolation_and_restart()
	test_rewards_and_idempotency()
	test_purchase_equip_and_frozen_loadout()
	test_atomic_fault_matrix()
	test_ads_and_stale_readers()
	test_recovery_versions_and_ledger_validation()
	var report := {"test": "ant_progression", "engine": Engine.get_version_info().string, "assertions": assertions, "passed": failures.is_empty(), "failures": failures, "cases": cases, "scope": "Headless local service only; no UI, Mac, ad SDK or live balancing acceptance."}
	var output := FileAccess.open("res://reports/rules/ant-progression-tests.json", FileAccess.WRITE)
	if output:
		output.store_string(JSON.stringify(report, "\t") + "\n")
		output.close()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
