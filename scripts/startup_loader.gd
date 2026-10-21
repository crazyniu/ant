extends Node
## A finite, local-resource startup batch. No scene transitions or artificial waits.
## Resources stay strongly referenced until handover/release or this node exits.
## Godot exposes no cancellation for native threaded loads. Exiting the tree stops
## our polling/callbacks; an already submitted native request may finish afterwards.

signal progress_changed(value: float)
signal completed(finished_request_id: int)
signal failed(error: Dictionary)

enum State { IDLE, LOADING, COMPLETED, FAILED }

const MAX_PATHS := 64
const MAX_POLLS_PER_FRAME := 32

var state: State = State.IDLE
var progress := 0.0
var request_id := 0
var last_error: Dictionary = {}

var _paths: Array[String] = []
var _resources: Dictionary = {}
var _next_index := 0
var _active_path := ""


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _ready() -> void:
	# Godot enables a declared _process when entering the tree after _init.
	set_process(state == State.LOADING)


func start(paths: Array[String]) -> Error:
	# Do not supersede a live native request, or silently replace the caller's job.
	if state == State.LOADING:
		return ERR_BUSY
	if not is_inside_tree() or is_queued_for_deletion():
		return ERR_UNCONFIGURED
	request_id += 1
	var current_request := request_id
	state = State.LOADING
	last_error = {}
	_resources.clear()
	_paths.clear()
	_next_index = 0
	_active_path = ""
	progress = 0.0
	# Keep the caller's original batch for retry, including invalid/missing paths.
	for path in paths:
		var canonical := path.simplify_path()
		if not _paths.has(canonical):
			_paths.append(canonical)
	if _paths.is_empty() or _paths.size() > MAX_PATHS:
		_fail(current_request, "", "validation", ERR_INVALID_PARAMETER,
			"Startup requires 1 to %d distinct local resource paths." % MAX_PATHS)
		return ERR_INVALID_PARAMETER
	for path in _paths:
		if not (path.begins_with("res://") or path.begins_with("user://")):
			_fail(current_request, path, "validation", ERR_INVALID_PARAMETER,
				"Only project or local user resource paths are supported.")
			return ERR_INVALID_PARAMETER
		if not ResourceLoader.exists(path):
			_fail(current_request, path, "validation", ERR_FILE_NOT_FOUND,
				"A required startup resource is missing or unsupported.")
			return ERR_FILE_NOT_FOUND
	set_process(true)
	progress_changed.emit(progress)
	# Start on the next process frame, leaving the boot page free to draw first.
	return OK


func retry() -> Error:
	if state == State.LOADING:
		return ERR_BUSY
	if state != State.FAILED:
		return ERR_UNAVAILABLE
	return start(_paths.duplicate())


func get_resource(path: String) -> Resource:
	# Never triggers a synchronous load, even when called before completion.
	if state != State.COMPLETED:
		return null
	return _resources.get(path.simplify_path()) as Resource


func release_resources() -> Error:
	# Call only after the destination has its own references/has been instantiated.
	if state == State.LOADING:
		return ERR_BUSY
	_resources.clear()
	return OK


func _process(_delta: float) -> void:
	if state != State.LOADING or is_queued_for_deletion():
		return
	var current_request := request_id
	# Cached resources can finish in this frame; only a genuine pending request
	# yields. The cap bounds main-thread work without a minimum display duration.
	for _poll in range(MAX_POLLS_PER_FRAME):
		if not _owns_request(current_request):
			return
		if _active_path.is_empty():
			_begin_next(current_request)
			if not _owns_request(current_request):
				return
		var native_progress: Array = []
		var native_status := ResourceLoader.load_threaded_get_status(_active_path, native_progress)
		match native_status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var fraction := float(native_progress[0]) if not native_progress.is_empty() else 0.0
				_set_progress((float(_resources.size()) + clampf(fraction, 0.0, 1.0)) / float(_paths.size()))
				return
			ResourceLoader.THREAD_LOAD_LOADED:
				# Successful retrieval is only allowed after the native loaded status.
				var resource := ResourceLoader.load_threaded_get(_active_path)
				if resource == null:
					_fail(current_request, _active_path, "retrieve", ERR_CANT_ACQUIRE_RESOURCE,
						"The completed request did not return a resource.", native_status)
					return
				_resources[_active_path] = resource
				_active_path = ""
				_set_progress(float(_resources.size()) / float(_paths.size()))
				if _resources.size() == _paths.size():
					_finish(current_request)
					return
			ResourceLoader.THREAD_LOAD_FAILED:
				# FAILED is terminal too: consume its native token, never as a resource.
				# Without this non-pending cleanup, Godot reuses the failed token on
				# every request for this path and a repaired-file retry cannot succeed.
				ResourceLoader.load_threaded_get(_active_path)
				_fail(current_request, _active_path, "load", ERR_CANT_OPEN,
					"Godot could not load a required startup resource.", native_status)
				return
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_fail(current_request, _active_path, "status", ERR_INVALID_DATA,
					"The native startup request is missing or invalid.", native_status)
				return


func _begin_next(expected_request: int) -> void:
	if not _owns_request(expected_request) or not _active_path.is_empty():
		return
	if _next_index >= _paths.size():
		_finish(expected_request)
		return
	var path := _paths[_next_index]
	# One request at a time and no native subthreads: startup never floods workers.
	var error := ResourceLoader.load_threaded_request(path, "", false, ResourceLoader.CACHE_MODE_REUSE)
	if error != OK:
		_fail(expected_request, path, "request", error,
			"Godot rejected a startup resource request.")
		return
	_active_path = path
	_next_index += 1


func _set_progress(value: float) -> void:
	# Equal-weight resource completion plus the active request's actual progress.
	# This is not byte/elapsed-time progress and has no cosmetic percentage timer.
	if is_equal_approx(progress, value):
		return
	progress = value
	progress_changed.emit(progress)


func _finish(expected_request: int) -> void:
	if not _owns_request(expected_request) or _resources.size() != _paths.size():
		return
	state = State.COMPLETED
	set_process(false)
	completed.emit(expected_request)


func _fail(expected_request: int, path: String, phase: String, code: Error,
		message: String, native_status := -1) -> void:
	if not _owns_request(expected_request):
		return
	state = State.FAILED
	set_process(false)
	_active_path = ""
	_resources.clear()
	last_error = {
		"request_id": expected_request, "path": path, "phase": phase,
		"code": code, "message": message, "native_status": native_status,
		"retryable": true,
	}
	failed.emit(last_error.duplicate(true))


func _owns_request(expected_request: int) -> bool:
	return expected_request == request_id and state == State.LOADING \
		and is_inside_tree() and not is_queued_for_deletion()


func _exit_tree() -> void:
	# Invalidates any already queued/deferred owner callbacks without a new signal.
	request_id += 1
	set_process(false)
	if not _active_path.is_empty():
		var native_status := ResourceLoader.load_threaded_get_status(_active_path)
		if native_status in [ResourceLoader.THREAD_LOAD_LOADED, ResourceLoader.THREAD_LOAD_FAILED]:
			ResourceLoader.load_threaded_get(_active_path)
		# Never block exit on IN_PROGRESS. Godot has no cancel/release-token API;
		# that single native request can remain owned by the engine until shutdown.
	state = State.IDLE
	_active_path = ""
	_paths.clear()
	_resources.clear()
	last_error.clear()
	progress = 0.0
