extends SceneTree
## Real ResourceLoader checks, limited to tiny fixtures and two existing scripts.
## The corrupt-resource probe intentionally produces a Godot parse/load error.

const Loader = preload("res://scripts/startup_loader.gd")
const SMALL_A := "res://scripts/ui_skin.gd"
const SMALL_B := "res://scripts/ui_icon.gd"

var checks := 0
var failures: Array[String] = []
var completed_ids: Array[int] = []
var errors: Array[Dictionary] = []
var samples: Array[float] = []
var fixture_paths: Array[String] = []


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func make_loader() -> Loader:
	var loader := Loader.new()
	root.add_child(loader)
	loader.completed.connect(func(id: int): completed_ids.append(id))
	loader.failed.connect(func(error: Dictionary): errors.append(error))
	loader.progress_changed.connect(func(value: float): samples.append(value))
	return loader


func wait_for_loader(loader: Node) -> void:
	var deadline := Time.get_ticks_msec() + 10000
	while loader.state == Loader.State.LOADING and Time.get_ticks_msec() < deadline:
		await process_frame
	check(loader.state != Loader.State.LOADING, "Native loading reaches a terminal state within the test deadline")


func write_fixture(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "The isolated local test fixture can be written")
	if file:
		file.store_string(contents)
		file.close()
	if not fixture_paths.has(path):
		fixture_paths.append(path)


func run() -> void:
	var unattached := Loader.new()
	check(unattached.start([SMALL_A]) == ERR_UNCONFIGURED, "An unattached node rejects work instead of silently waiting forever")
	check(unattached.retry() == ERR_UNAVAILABLE, "Retry requires a failed batch")
	unattached.free()
	var loader := make_loader()
	check(not loader.is_processing(), "An idle loader has no frame polling")
	check(loader.start([SMALL_A, SMALL_B, SMALL_A]) == OK, "A real local batch starts")
	var first_id: int = loader.request_id
	check(loader.state == Loader.State.LOADING and loader.progress == 0.0, "Starting never reports invented completed progress")
	check(loader.get_resource(SMALL_A) == null, "Early retrieval never performs a blocking load")
	check(loader.start([SMALL_B]) == ERR_BUSY and loader.request_id == first_id, "Repeated start does not replace an in-flight batch")
	check(loader.retry() == ERR_BUSY, "Retry does not duplicate an in-flight native request")
	check(loader.release_resources() == ERR_BUSY, "Handover cannot discard a partially loaded batch")
	await wait_for_loader(loader)
	check(loader.state == Loader.State.COMPLETED, "Both actual project resources complete successfully")
	check(loader._resources.size() == 2 and loader._paths.size() == 2, "Duplicate paths create one retained resource each")
	check(loader.progress == 1.0 and not loader.is_processing(), "Completion stops polling and reports actual full progress")
	check(completed_ids == [first_id] and errors.is_empty(), "Completion is emitted exactly once for the matching request")
	var retained_a: Resource = loader.get_resource(SMALL_A)
	var retained_b: Resource = loader.get_resource(SMALL_B)
	check(retained_a is Script and retained_b is Script, "Resources remain strongly retained for the scene handover")
	check(loader.get_resource("res://missing.tres") == null, "Retrieval outside the batch never loads unrelated resources")
	for index in range(samples.size()):
		check(samples[index] >= 0.0 and samples[index] <= 1.0, "Reported progress is bounded")
		if index > 0:
			check(samples[index] >= samples[index - 1], "The real batch progress does not move backwards")
	check(loader.release_resources() == OK and loader.get_resource(SMALL_A) == null, "Explicit handover release drops loader references")
	check(is_instance_valid(retained_a), "The destination's own strong reference survives loader release")
	# Holding the two scripts ensures CACHE_MODE_REUSE can complete both immediately.
	check(loader.start([SMALL_A, SMALL_B]) == OK, "A completed loader accepts a new finite batch")
	var second_id: int = loader.request_id
	loader._finish(first_id)
	loader._fail(first_id, SMALL_A, "status", ERR_INVALID_DATA, "Stale test callback")
	check(loader.state == Loader.State.LOADING and loader.last_error.is_empty(), "Stale success and failure identities cannot replace a newer job")
	loader._process(0.0)
	check(loader.state == Loader.State.COMPLETED and loader.progress == 1.0, "Cached resources finish in one poll without a minimum fake loading duration")
	check(completed_ids == [first_id, second_id], "Only the newer matching completion is delivered")
	loader._process(1000.0)
	check(completed_ids.size() == 2, "Elapsed time and extra polls cannot create another completion")

	var suffix := str(Time.get_ticks_usec())
	var missing := "user://startup_missing_%s.tres" % suffix
	check(loader.start([SMALL_A, missing]) == ERR_FILE_NOT_FOUND, "Missing resources fail preflight without scheduling a partial batch")
	check(loader.state == Loader.State.FAILED and not loader.is_processing(), "A missing-resource error terminates polling")
	check(loader.last_error.path == missing and loader.last_error.phase == "validation", "Structured failure identifies the missing path and phase")
	check(loader.last_error.request_id == loader.request_id and loader.last_error.code == ERR_FILE_NOT_FOUND, "Structured failure contains the exact request and error code")
	check(loader._active_path.is_empty() and loader._resources.is_empty(), "Failure retains neither an active native request nor partial resources")
	var missing_id: int = loader.request_id
	write_fixture(missing, "[gd_resource type=\"Resource\" format=3]\n\n[resource]\nresource_name = \"Recovered startup fixture\"\n")
	check(loader.retry() == OK and loader.request_id > missing_id, "Retry starts a distinct real request after the missing resource is restored")
	await wait_for_loader(loader)
	check(loader.state == Loader.State.COMPLETED, "Restored-resource retry actually succeeds")
	var recovered := loader.get_resource(missing)
	check(recovered != null and recovered.resource_name == "Recovered startup fixture", "Retry returns the newly available resource rather than a fake completion")
	check(loader.last_error.is_empty(), "Successful retry clears the previous diagnostic")
	check(loader.start([]) == ERR_INVALID_PARAMETER, "An empty manifest is rejected")
	check(loader.start(["https://invalid.example/asset.tres"]) == ERR_INVALID_PARAMETER, "Startup never requests network resources")
	var too_many: Array[String] = []
	for index in range(Loader.MAX_PATHS + 1):
		too_many.append("res://bounded_%s.tres" % index)
	check(loader.start(too_many) == ERR_INVALID_PARAMETER, "The finite resource manifest has a hard upper bound")

	# Fault injection only for a lost native token, with no actual request outstanding.
	check(loader.start([SMALL_A]) == OK, "A new diagnostic probe can start")
	loader._active_path = "res://tests/__unrequested_startup_resource__.tres"
	loader._process(0.0)
	check(loader.state == Loader.State.FAILED and loader.last_error.phase == "status", "A missing native request fails instead of hanging or calling threaded_get")
	check(loader.last_error.native_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, "The missing-request native status is retained in the diagnostic")

	var corrupt := "user://startup_corrupt_%s.tres" % suffix
	write_fixture(corrupt, "[gd_resource type=\"Resource\" format=3]\n\n[resource]\nresource_name = @invalid@\n")
	check(loader.start([corrupt]) == OK, "An existing but corrupt resource reaches the actual native loader")
	await wait_for_loader(loader)
	check(loader.state == Loader.State.FAILED and loader.last_error.get("phase") == "load", "An actual Godot parse failure becomes a structured load failure")
	check(loader.last_error.get("native_status") == ResourceLoader.THREAD_LOAD_FAILED, "The real native failed status is reported")
	check(loader.get_resource(corrupt) == null and not loader.is_processing(), "Native failure neither exposes a resource nor continues polling")
	write_fixture(corrupt, "[gd_resource type=\"Resource\" format=3]\n\n[resource]\nresource_name = \"Repaired native failure\"\n")
	check(loader.retry() == OK, "A failed native token is consumed so the repaired same path can be retried")
	await wait_for_loader(loader)
	check(loader.state == Loader.State.COMPLETED, "Repairing a corrupt file permits a successful real native retry")
	var repaired := loader.get_resource(corrupt)
	check(repaired != null and repaired.resource_name == "Repaired native failure", "The native retry returns the repaired resource contents")
	# Real cached Resource objects exercise the per-frame cap without 33 disk files.
	var warm_refs: Array[Resource] = []
	var warm_paths: Array[String] = []
	for index in range(Loader.MAX_POLLS_PER_FRAME + 1):
		var resource := Resource.new()
		var path := "user://startup_warm_%s_%s.tres" % [suffix, index]
		resource.take_over_path(path)
		warm_refs.append(resource)
		warm_paths.append(path)
	check(loader.start(warm_paths) == OK, "A finite cache-hit batch larger than one frame's work budget starts")
	loader._process(0.0)
	check(loader.state == Loader.State.LOADING and loader._resources.size() == Loader.MAX_POLLS_PER_FRAME, "A single poll cannot exceed the actual 32-resource work cap")
	check(is_equal_approx(loader.progress, float(Loader.MAX_POLLS_PER_FRAME) / warm_paths.size()), "Capped progress exactly reflects resources actually retrieved")
	loader._process(0.0)
	check(loader.state == Loader.State.COMPLETED, "The next poll finishes the remaining cached resource without waiting")

	# Remove while a native request has been submitted, before any get operation.
	var exiting := make_loader()
	check(exiting.start([SMALL_A, SMALL_B]) == OK, "A disposal probe starts")
	exiting._begin_next(exiting.request_id)
	var obsolete_id: int = exiting.request_id
	var completion_count := completed_ids.size()
	root.remove_child(exiting)
	check(exiting.state == Loader.State.IDLE and exiting.request_id > obsolete_id, "Leaving the tree invalidates the old generation immediately")
	check(not exiting.is_processing() and exiting._resources.is_empty(), "Leaving the tree drops owned references and stops polling")
	exiting._finish(obsolete_id)
	exiting._process(0.0)
	check(completed_ids.size() == completion_count, "Detached old callbacks cannot perform a late scene handover")
	exiting.free()
	loader.queue_free()
	await process_frame
	for path in fixture_paths:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var report := {
		"pass": failures.is_empty(), "checks": checks, "failures": failures,
		"scope": "Finite real threaded startup loads, deduplicated/retained resources, cache hits, actual progress, repeated start, generation guards, missing/corrupt resources, restored-resource retry and node disposal. No level scan, scene transition or visual acceptance.",
	}
	print("STARTUP_LOADER_REPORT ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
