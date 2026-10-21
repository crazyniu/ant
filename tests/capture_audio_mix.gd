extends SceneTree
## Digital AudioServer PCM evidence, not speaker listening or gameplay proof.
## Captures the actual limited mix; the BGM-only segments contain no SFX at all.
const AudioService = preload("res://scripts/audio_service.gd")
var audio: Node
var recorder: AudioEffectRecord
var out := ""
var segments: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func capture_segment(label: String, seconds: float, dense := false) -> void:
	audio.stop_all_sfx()
	audio._music.play(8.0)
	audio._update_pause_state()
	await create_timer(.15).timeout
	recorder.set_recording_active(true)
	if dense:
		for voice in audio._normal + audio._priority:
			voice.stream = audio._streams[&"warning"]
			voice.play()
	var initial: Dictionary = audio.get_status()
	await create_timer(seconds).timeout
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	var path := out.path_join(label + ".wav")
	var result := recording.save_to_wav(path)
	if result != OK:
		failures.append("Could not write " + path)
	segments.append({"name": label, "file": path, "seconds_requested": seconds,
		"sfx_started": 12 if dense else 0, "initial": initial, "final": audio.get_status()})

func run() -> void:
	out = OS.get_environment("ANT_RESCUE_AUDIO_EVIDENCE_DIR")
	if out.is_empty():
		out = "user://audio-mix-evidence"
	out = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out)
	audio = AudioService.new()
	root.add_child(audio)
	await process_frame
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	var music_limiter: AudioEffectHardLimiter = AudioServer.get_bus_effect(AudioServer.get_bus_index(audio.MUSIC_BUS), 0)
	# Baseline is the same unchanged score, same seek/70% volume and actual old
	# limiter/player settings. It is an explicitly marked test comparison only.
	audio._music.volume_db = -3.0
	music_limiter.ceiling_db = -10.0
	# capture_segment refreshes policy, so temporarily change gain just after seek.
	audio.stop_all_sfx();audio._music.play(8.0);audio._music.volume_db = -3.0
	await create_timer(.15).timeout
	recorder.set_recording_active(true)
	var baseline: Dictionary = audio.get_status()
	await create_timer(6.0).timeout
	recorder.set_recording_active(false)
	var baseline_path := out.path_join("before_bgm_70.wav")
	if recorder.get_recording().save_to_wav(baseline_path) != OK: failures.append("Could not write baseline")
	segments.append({"name":"before_bgm_70", "file":baseline_path, "seconds_requested":6.0,
		"sfx_started":0,"initial":baseline,"final":audio.get_status()})
	music_limiter.ceiling_db = audio.MUSIC_CEILING_DB
	await capture_segment("after_bgm_70", 6.0)
	audio.set_game_paused(true)
	await capture_segment("modal_bgm_70", 3.0)
	audio.set_music_preview(true)
	await capture_segment("settings_bgm_70", 3.0)
	audio.set_music_volume(0.0)
	await capture_segment("zero_music", 1.0)
	audio.set_music_volume(.7);audio.set_music_muted(true)
	await capture_segment("explicit_mute", 1.0)
	audio.set_music_muted(false);audio.set_backgrounded(true)
	await capture_segment("background_silence", 1.0)
	audio.set_backgrounded(false);audio.set_music_preview(false);audio.set_game_paused(false)
	audio.set_music_volume(1.0);audio.set_sfx_volume(1.0)
	await capture_segment("full_volume_dense_mix", 3.0, true)
	var report := {"pass": failures.is_empty(), "failures": failures,
		"engine": Engine.get_version_info().string, "audio_driver": AudioServer.get_driver_name(),
		"original_bgm_sha256": FileAccess.get_sha256(audio.BGM_PATH),
		"audio_service_sha256": FileAccess.get_sha256("res://scripts/audio_service.gd"),
		"segments": segments, "scope": "Actual AudioServer Master PCM captured with AudioEffectRecord. Digital mix evidence, not a hardware output or perceptual listening test.",
		"listening": "NOT_RUN", "hardware_output": "NOT_RUN"}
	var file := FileAccess.open(out.path_join("capture-manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print("AUDIO_MIX_CAPTURE ", JSON.stringify(report))
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	recorder = null
	music_limiter = null
	audio.queue_free()
	await process_frame
	audio = null
	await process_frame
	# Let the audio thread retire its last stopped Vorbis playback before exit.
	await create_timer(.2).timeout
	quit(0 if failures.is_empty() else 1)
