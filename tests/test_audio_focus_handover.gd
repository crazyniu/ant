extends SceneTree
## Targeted inherited-focus policy and first-block PCM test. No display manipulation.
const AudioService = preload("res://scripts/audio_service.gd")
class BackgroundAtCreation extends "res://scripts/audio_service.gd":
	func _initial_background_state() -> bool:
		return true
var checks := 0
var failures: Array[String] = []
var states: Array[Dictionary] = []
var recorder: AudioEffectRecord

func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func has_samples(recording: AudioStreamWAV) -> bool:
	for sample in recording.data:
		if sample != 0: return true
	return false
func record_for(seconds: float) -> AudioStreamWAV:
	recorder.set_recording_active(true)
	await create_timer(seconds).timeout
	recorder.set_recording_active(false)
	return recorder.get_recording()
func run() -> void:
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	# The test seam substitutes a lost-focus query. Production uses the actual
	# nonheadless DisplayServer.window_is_focused() before the first play call.
	recorder.set_recording_active(true)
	var audio := BackgroundAtCreation.new()
	audio.apply_settings_state({"music":70.0,"sound":70.0})
	audio.set_game_paused(true)
	root.add_child(audio)
	check(audio.get_status().backgrounded and audio.get_status().music_paused, "New service inherits lost focus before autoplay")
	check(audio.get_status().game_paused and audio.get_status().music_ducked, "Inherited focus preserves the modal pause reason")
	await create_timer(.35).timeout
	recorder.set_recording_active(false)
	var captured := recorder.get_recording()
	check(captured.data.size() > 0 and not has_samples(captured), "Initial background handover has exact-zero Master PCM, including first block")
	states.append({"state":"created_while_backgrounded","audio":audio.get_status(),"pcm_nonzero":has_samples(captured)})
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not audio.get_status().backgrounded and not audio.get_status().music_paused, "Actual focus-in notification resumes the inherited suspension")
	check(audio.get_status().game_paused and audio.get_status().music_ducked, "Foreground resumes only ducked music, not gameplay")
	captured = await record_for(.35)
	check(has_samples(captured), "Foreground actually produces BGM PCM")
	states.append({"state":"foreground_modal","audio":audio.get_status(),"pcm_nonzero":has_samples(captured)})
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(audio.get_status().music_paused, "A later focus-out still suspends the service")
	await create_timer(.15).timeout
	captured = await record_for(.25)
	check(not has_samples(captured), "Later background PCM is silent after output latency")
	audio.queue_free(); await process_frame; await create_timer(.2).timeout
	# Saved zero must survive the same background-to-foreground transition.
	audio = BackgroundAtCreation.new()
	audio.apply_settings_state({"music":0.0,"sound":70.0,"music_muted":true})
	root.add_child(audio)
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	captured = await record_for(.3)
	check(audio.get_status().music_volume == 0 and audio.get_status().music_muted, "Foreground never overwrites saved zero/mute")
	check(not has_samples(captured), "Saved-zero foreground remains exact-zero PCM")
	audio.queue_free(); await process_frame; await create_timer(.2).timeout
	var normal := AudioService.new(); normal.autoplay_music = false
	root.add_child(normal)
	check(DisplayServer.get_name() == "headless" and not normal.get_status().backgrounded, "Headless driver does not invent a missing-window background state")
	normal.queue_free(); await process_frame
	var report := {"pass":failures.is_empty(),"assertions":checks,"failures":failures,"states":states,
		"audio_driver":AudioServer.get_driver_name(),"display_driver":DisplayServer.get_name(),
		"audio_service_sha256":FileAccess.get_sha256("res://scripts/audio_service.gd"),
		"scope":"Injected initial lost-focus query plus real AudioServer PCM and application focus notifications. Production nonheadless query uses window_is_focused; real OS window-focus switching and hardware listening are not claimed."}
	var out := OS.get_environment("ANT_RESCUE_AUDIO_EVIDENCE_DIR")
	if out.is_empty(): out="user://audio-mix-evidence"
	DirAccess.make_dir_recursive_absolute(out)
	var file:=FileAccess.open(out.path_join("focus-handover.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("AUDIO_FOCUS_HANDOVER ",JSON.stringify(report))
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	recorder=null;captured=null;audio=null;normal=null
	await create_timer(.2).timeout
	quit(0 if failures.is_empty() else 1)
