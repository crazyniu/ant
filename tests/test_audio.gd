extends SceneTree
## Automated engine checks only. Does not claim listening or gameplay integration.
const AudioService = preload("res://scripts/audio_service.gd")
var failures: Array[String] = []
var assertions := 0

func check(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		failures.append(message)

func _initialize() -> void:
	call_deferred("run")

func wait_seconds(seconds: float) -> void:
	await create_timer(seconds, true).timeout

func run() -> void:
	var audio := AudioService.new()
	audio.autoplay_music = false
	root.add_child(audio)
	await process_frame
	check(audio.get_status().load_errors.is_empty(), "Every audio source must load")
	check(audio.get_status().loaded_cues == 14, "Expected 14 effect cues")
	check(audio.get_status().max_sfx == 12, "Expected fixed 12-voice bound")
	check(audio.get_child_count() == 13, "One music player plus exactly 12 SFX players")
	check(not audio.get_status().music_playing, "Opt-out autoplay must be respected")
	var music_index := AudioServer.get_bus_index(audio.MUSIC_BUS)
	var sfx_index := AudioServer.get_bus_index(audio.SFX_BUS)
	check(music_index > 0 and sfx_index > 0 and music_index != sfx_index, "Independent custom music/SFX buses")
	check(audio._music.bus == audio.MUSIC_BUS, "Music player routes to music bus")
	check(is_equal_approx(audio._music.volume_db, audio.MUSIC_GAIN_DB), "BGM has the calibrated source gain")
	check(db_to_linear(audio.MUSIC_CEILING_DB) + db_to_linear(audio.SFX_CEILING_DB) < 1.0, "Music plus saturated SFX ceilings retain mix headroom")
	for voice in audio._normal + audio._priority:
		check(voice.bus == audio.SFX_BUS, "SFX player must route to SFX bus")
	for index in [music_index, sfx_index]:
		check(AudioServer.get_bus_send(index) == &"Master", "Custom bus sends to Master")
		check(AudioServer.get_bus_effect_count(index) == 1, "One dedicated safety limiter per custom bus")
		check(AudioServer.get_bus_effect(index, 0) is AudioEffectHardLimiter, "Hard limiter class")
	var bgm := audio._music.stream as AudioStreamOggVorbis
	check(bgm != null, "BGM imported as native Ogg Vorbis")
	check(audio.BGM_PATH.ends_with(".ogg"), "Runtime uses compact BGM rather than archived PCM master")
	check(is_equal_approx(bgm.get_length(), 40.0), "BGM is a full 40-second composition")
	check(bgm.loop, "Native Vorbis loop enabled")
	check(is_zero_approx(bgm.loop_offset), "Vorbis loop restarts at zero seconds")
	for event_id in audio.SFX_PATHS:
		var stream := audio._streams[event_id] as AudioStreamWAV
		check(stream != null and stream.get_length() >= 0.15, "Cue loads with useful duration: " + event_id)
		check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "SFX must not loop: " + event_id)
		check(stream.stereo and stream.mix_rate == 44100, "Cue format: " + event_id)
	var bus_count := AudioServer.bus_count
	audio._ensure_bus(audio.MUSIC_BUS, -10.0)
	audio._ensure_bus(audio.SFX_BUS, -5.0)
	check(AudioServer.bus_count == bus_count, "Bus initialization must be idempotent")
	check(AudioServer.get_bus_effect_count(sfx_index) == 1, "Idempotence must not stack limiters")
	audio.set_music_volume(0.25)
	check(absf(db_to_linear(AudioServer.get_bus_volume_db(music_index)) - .25) < .001, "Music gain reaches its bus")
	check(absf(db_to_linear(AudioServer.get_bus_volume_db(sfx_index)) - .7) < .001, "Music gain does not change SFX")
	audio.set_music_muted(true)
	check(AudioServer.is_bus_mute(music_index), "Music mute reaches its bus")
	check(not AudioServer.is_bus_mute(sfx_index), "Music mute independent from SFX")
	audio.set_sfx_volume(0.42)
	audio.set_sfx_muted(true)
	check(AudioServer.is_bus_mute(sfx_index), "SFX mute reaches its bus")
	check(not audio.play_event(&"pickup"), "Muted SFX must not start or queue")
	audio.set_music_muted(false)
	check(not AudioServer.is_bus_mute(music_index) and AudioServer.is_bus_mute(sfx_index), "SFX mute independent from music")
	audio.set_music_volume(-10.0)
	check(audio.music_volume == 0 and AudioServer.is_bus_mute(music_index), "Zero/clamped-negative music gain is silent")
	audio.set_sfx_volume(10.0)
	check(audio.sfx_volume == 1.0, "SFX gain upper clamp")
	audio.apply_settings_state({"music": 35.0, "sound": 60.0, "music_muted": false, "sound_muted": false})
	check(is_equal_approx(audio.music_volume, .35) and is_equal_approx(audio.sfx_volume, .6), "Existing 0–100 settings adapter")
	check(not audio.music_muted and not audio.sfx_muted, "Settings adapter independent mute state")
	audio.set_sfx_volume(0.0)
	check(AudioServer.is_bus_mute(sfx_index), "SFX slider at zero silences its bus without a separate mute toggle")
	check(not AudioServer.is_bus_mute(music_index), "Zero SFX does not silence music")
	check(not audio.play_event(&"dispatch"), "Zero SFX rejects playback rather than queues it")
	audio.set_sfx_volume(.6)
	check(not AudioServer.is_bus_mute(sfx_index), "Positive SFX slider restores sound without a mute toggle")
	audio.set_music_volume(0.0)
	check(AudioServer.is_bus_mute(music_index) and not AudioServer.is_bus_mute(sfx_index), "Zero music slider independently silences music")
	audio.set_music_volume(.35)
	check(not AudioServer.is_bus_mute(music_index), "Positive music slider restores music")
	check(audio.play_ui_click(), "First UI click starts")
	check(not audio.play_ui_click(), "Duplicate immediate click is rate limited")
	check(not audio.play_event(&"invented_event"), "Unknown event is safely rejected")
	check(not audio.play_tool(&"invented_tool"), "Unknown tool is safely rejected")
	await wait_seconds(.16)
	var accepted_pickups := 0
	for i in range(500):
		if audio.play_event(&"pickup"):
			accepted_pickups += 1
	check(accepted_pickups == 1, "500 simultaneous pickups collapse to one audible cue")
	check(not audio.play_event(&"return"), "Different carrier cues share a group cooldown")
	check(int(audio.get_status().dropped.get(&"event_cooldown", 0)) >= 499, "Dense-event drops are observable")
	await wait_seconds(.16)
	check(audio.play_event(&"return"), "Carrier cue becomes available after the real clock gap")
	check(audio.play_event(&"cannon"), "Combat event starts independently from carriers")
	check(not audio.play_event(&"armor_hit"), "Cannon and armor events share a combat gap")
	await wait_seconds(.16)
	check(audio.play_event(&"armor_hit"), "Armor cue resumes after group gap")
	audio.start_music()
	check(audio.get_status().music_playing, "Music player starts")
	await wait_seconds(.15)
	check(float(audio.get_status().music_position) > .03, "Music transport actually advances before pause")
	audio._music.play(39.85)
	await wait_seconds(.4)
	check(audio.get_status().music_playing and float(audio.get_status().music_position) < .8, "Real music transport wraps across the 40-second loop boundary")
	audio.set_game_paused(true)
	check(not audio.get_status().music_paused and audio.get_status().music_ducked, "Gameplay modal keeps reduced music playing")
	check(is_equal_approx(audio._music.volume_db, audio.MUSIC_GAIN_DB + audio.MUSIC_DUCK_DB), "Modal music gain ducks by the configured amount")
	audio.set_music_preview(true)
	check(audio.get_status().game_paused and audio.get_status().music_preview and not audio.get_status().music_paused, "Settings auditions music without clearing gameplay pause")
	check(not audio.get_status().music_ducked and is_equal_approx(audio._music.volume_db, audio.MUSIC_GAIN_DB), "Settings previews the actual normal music level")
	check(not audio.play_event(&"pickup"), "Settings audition never resumes gameplay sound cues")
	audio.set_backgrounded(true)
	check(audio.get_status().music_paused, "Background overrides settings audition")
	audio.set_backgrounded(false)
	check(not audio.get_status().music_paused and audio.get_status().game_paused, "Foreground returns only the settings music preview")
	paused=true
	await process_frame
	await process_frame
	check(audio.get_status().music_paused, "SceneTree pause overrides settings audition")
	paused=false
	await process_frame
	await process_frame
	audio.set_music_preview(false)
	check(not audio.get_status().music_paused and audio.get_status().game_paused and audio.get_status().music_ducked, "Leaving settings restores softly playing modal music")
	check(audio.get_status().active_sfx == 0, "Pausing discards old SFX")
	check(not audio.play_event(&"dispatch"), "Paused gameplay does not emit simulation cues")
	check(audio.play_ui_click(), "UI click remains available while gameplay is paused")
	var held_position: float = audio.get_status().music_position
	await wait_seconds(.15)
	check(float(audio.get_status().music_position) > held_position + .03, "Music transport advances through a paused gameplay modal")
	audio.set_backgrounded(true)
	held_position = audio.get_status().music_position
	await wait_seconds(.06)
	check(not audio.play_ui_click(), "Background rejects UI sounds too")
	check(absf(float(audio.get_status().music_position) - held_position) < .03, "Application background still freezes the actual music position")
	audio.set_backgrounded(false)
	check(not audio.get_status().music_paused and audio.get_status().game_paused and audio.get_status().music_ducked, "Foreground returns to ducked BGM without unpausing gameplay")
	audio.set_game_paused(false)
	check(not audio.get_status().music_paused, "Explicit resume resumes music without restart")
	check(absf(float(audio.get_status().music_position) - held_position) < .04, "Resume preserves held music position rather than restarting")
	check(not audio.get_status().music_ducked and is_equal_approx(audio._music.volume_db, audio.MUSIC_GAIN_DB), "Gameplay resume restores normal gain")
	audio.set_backgrounded(true)
	audio.set_game_paused(false)
	check(audio.get_status().music_paused, "Gameplay resume must not clear background suspension")
	audio.set_backgrounded(false)
	check(not audio.get_status().music_paused, "Foreground resumes only when no pause reason remains")
	paused = true
	await process_frame
	await process_frame
	check(audio.get_status().music_paused, "Service detects paused SceneTree while running ALWAYS")
	check(not audio.play_event(&"pickup"), "SceneTree pause rejects carrier events")
	await wait_seconds(.06)
	check(audio.play_ui_click(), "SceneTree pause keeps UI click channel usable")
	paused = false
	await process_frame
	await process_frame
	check(not audio.get_status().music_paused, "SceneTree resume restores music")
	audio.stop_all_sfx()
	await wait_seconds(.2)
	# Artificially occupy the normal pool to exercise exhaustion deterministically.
	for voice in audio._normal:
		voice.stream = bgm
		voice.play()
	check(not audio.play_event(&"pickup"), "Exhausted normal pool drops rather than allocates")
	check(int(audio.get_status().dropped.get(&"voice_limit", 0)) >= 1, "Voice-pool exhaustion reason reported")
	check(audio.play_event(&"win"), "Reserved priority voice remains available under carrier saturation")
	check(audio.get_child_count() == 13 and audio.get_status().active_sfx <= 12, "Burst does not allocate unbounded players")
	audio.stop_all_sfx()
	# Give every cue a real start on a fresh service so prior cooldowns cannot mask it.
	audio.queue_free()
	await process_frame
	audio = AudioService.new()
	audio.autoplay_music = false
	root.add_child(audio)
	await process_frame
	check(AudioServer.bus_count == bus_count, "Service replacement does not duplicate buses")
	for event_id in audio.SFX_PATHS:
		check(audio.play_event(event_id), "Each cue can start: " + event_id)
		await wait_seconds(.16)
	await wait_seconds(.4)
	for tool_id in [&"plus", &"shuffle", &"recall", &"hint"]:
		check(audio.play_tool(tool_id), "Each tool alias maps to a releasable cue: " + tool_id)
		await wait_seconds(.16)
	check(audio.get_status().active_sfx <= 12, "All-cue preview remains bounded")
	audio.stop_music()
	check(not audio.get_status().music_playing, "Music stop is explicit")
	var report := {
		"pass": failures.is_empty(), "assertions": assertions, "failures": failures,
		"engine": Engine.get_version_info().string, "sfx_files": audio.SFX_PATHS.size(),
		"bgm_seconds": bgm.get_length(), "bgm_format": "Ogg Vorbis", "audio_driver": AudioServer.get_driver_name(), "max_sfx_players": 12,
		"scope": "Headless Godot resource, bus, gain/zero-volume silence, actual loop wrap/resume, pause/background, cooldown and bounded voice-pool checks only.",
		"listening": "NOT RUN", "production_gameplay_event_integration": "NOT CLAIMED"
	}
	print(JSON.stringify(report, "\t"))
	var output := FileAccess.open("res://assets/audio/godot-test-report.json", FileAccess.WRITE)
	if output:
		output.store_string(JSON.stringify(report, "\t") + "\n")
	audio.stop_all_sfx()
	audio.stop_music()
	audio.queue_free()
	bgm = null
	await process_frame
	await wait_seconds(.1)
	quit(0 if failures.is_empty() else 1)
