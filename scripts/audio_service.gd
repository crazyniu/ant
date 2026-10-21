extends Node
## Event-driven audio for Ant Rescue. Music and effects remain independently adjustable.
## Gameplay code must call an event only AFTER the corresponding action succeeds.
## Owning scene: instantiate once, add_child(), and keep for its entire lifetime.

signal cue_played(event_id: StringName)
signal cue_dropped(event_id: StringName, reason: StringName)

const MUSIC_BUS: StringName = &"AntMusic"
const SFX_BUS: StringName = &"AntSFX"
# The original score is quiet (-20.34 dBFS RMS before gain). Keep it present at
# the default 70% slider without rewriting assets or overriding saved settings.
const MUSIC_GAIN_DB := 3.0
const MUSIC_DUCK_DB := -4.0
# At full sliders these independent ceilings sum below 0 dBFS: -9 dB + -5 dB
# is at most -0.75 dBFS, including a saturated simultaneous music/SFX burst.
const MUSIC_CEILING_DB := -9.0
const SFX_CEILING_DB := -5.0
const BGM_PATH := "res://assets/audio/bgm_castle_garden.ogg"
const SFX_PATHS := {
	&"ui_click": "res://assets/audio/ui_click.wav",
	&"dispatch": "res://assets/audio/dispatch.wav",
	&"pickup": "res://assets/audio/pickup.wav",
	&"return": "res://assets/audio/return.wav",
	&"cannon": "res://assets/audio/cannon.wav",
	&"armor_hit": "res://assets/audio/armor_hit.wav",
	&"warning": "res://assets/audio/warning.wav",
	&"tool_plus": "res://assets/audio/tool_plus.wav",
	&"tool_shuffle": "res://assets/audio/tool_shuffle.wav",
	&"tool_recall": "res://assets/audio/tool_recall.wav",
	&"tool_hint": "res://assets/audio/tool_hint.wav",
	&"win": "res://assets/audio/win.wav",
	&"lose": "res://assets/audio/lose.wav",
	&"error": "res://assets/audio/error.wav",
}
const COOLDOWN_MS := {
	&"ui_click": 45, &"dispatch": 130, &"pickup": 100, &"return": 130,
	&"cannon": 120, &"armor_hit": 100, &"warning": 1400,
	&"tool_plus": 350, &"tool_shuffle": 350, &"tool_recall": 350, &"tool_hint": 350,
	&"win": 1500, &"lose": 1500, &"error": 250,
}
const TOOL_EVENTS := {&"plus": &"tool_plus", &"extra_slot": &"tool_plus", &"shuffle": &"tool_shuffle", &"recall": &"tool_recall", &"hint": &"tool_hint"}
const NORMAL_VOICES := 8
const PRIORITY_VOICES := 4
const CARRIER_GAP_MS := 90
const COMBAT_GAP_MS := 65
const UI_EVENTS := [&"ui_click", &"error", &"win", &"lose"]
const CARRIER_EVENTS := [&"dispatch", &"pickup", &"return"]
const COMBAT_EVENTS := [&"cannon", &"armor_hit"]

@export var autoplay_music := true
var music_volume := 0.7
var sfx_volume := 0.7
var music_muted := false
var sfx_muted := false
var _music: AudioStreamPlayer
var _normal: Array[AudioStreamPlayer] = []
var _priority: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _load_errors: Array[String] = []
var _next_allowed: Dictionary = {}
var _next_carrier_ms := 0
var _next_combat_ms := 0
var _priority_cursor := 0
var _game_paused := false
var _music_preview := false
var _backgrounded := false
var _last_tree_paused := false
var _accepted := 0
var _dropped: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# A scene created after focus was lost will never receive that old notification.
	# Inherit the real window state at ownership handover; keep explicit suspension.
	_backgrounded = _backgrounded or _initial_background_state()
	_ensure_bus(MUSIC_BUS, MUSIC_CEILING_DB)
	_ensure_bus(SFX_BUS, SFX_CEILING_DB)
	_music = AudioStreamPlayer.new()
	_music.name = "GardenMusic"
	_music.bus = MUSIC_BUS
	_music.volume_db = MUSIC_GAIN_DB
	add_child(_music)
	var original := load(BGM_PATH) as AudioStreamOggVorbis
	if original:
		var looping := original.duplicate() as AudioStreamOggVorbis
		# Vorbis loops use seconds, not WAV loop_mode or PCM sample-frame bounds.
		looping.loop = true
		looping.loop_offset = 0.0
		_music.stream = looping
	else:
		_load_errors.append(BGM_PATH)
	for event_id in SFX_PATHS:
		var stream := load(SFX_PATHS[event_id]) as AudioStreamWAV
		if stream:
			_streams[event_id] = stream
		else:
			_load_errors.append(SFX_PATHS[event_id])
	for i in range(NORMAL_VOICES + PRIORITY_VOICES):
		var voice := AudioStreamPlayer.new()
		voice.name = "Cue%02d" % i
		voice.bus = SFX_BUS
		add_child(voice)
		if i < NORMAL_VOICES:
			_normal.append(voice)
		else:
			_priority.append(voice)
	_apply_bus_settings()
	_last_tree_paused = get_tree().paused
	if autoplay_music:
		start_music()
	_update_pause_state()

func _process(_delta: float) -> void:
	if _last_tree_paused != get_tree().paused:
		_last_tree_paused = get_tree().paused
		_update_pause_state()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_backgrounded(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		set_backgrounded(false)

func _initial_background_state() -> bool:
	# Headless/offline tests have no focusable application window.
	return DisplayServer.get_name() != "headless" and not DisplayServer.window_is_focused()

func _ensure_bus(bus_name: StringName, ceiling: float) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")
	# Dedicated bus limits leave summing headroom without modifying Master.
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = ceiling
	limiter.release = 0.08
	AudioServer.add_bus_effect(index, limiter)

func _apply_bus_settings() -> void:
	var music_index := AudioServer.get_bus_index(MUSIC_BUS)
	var sfx_index := AudioServer.get_bus_index(SFX_BUS)
	if music_index >= 0:
		AudioServer.set_bus_volume_db(music_index, linear_to_db(maxf(music_volume, 0.0001)))
		AudioServer.set_bus_mute(music_index, music_muted or music_volume <= 0.0)
	if sfx_index >= 0:
		AudioServer.set_bus_volume_db(sfx_index, linear_to_db(maxf(sfx_volume, 0.0001)))
		AudioServer.set_bus_mute(sfx_index, sfx_muted or sfx_volume <= 0.0)

## Linear gain in [0, 1], not percentages and not decibels.
func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_settings()

func set_music_muted(value: bool) -> void:
	music_muted = value
	_apply_bus_settings()

func set_sfx_muted(value: bool) -> void:
	sfx_muted = value
	_apply_bus_settings()

## Convenience adapter for the existing UI's 0–100 settings dictionary.
func apply_settings_state(state: Dictionary) -> void:
	set_music_volume(float(state.get("music", 70.0)) / 100.0)
	set_sfx_volume(float(state.get("sound", 70.0)) / 100.0)
	set_music_muted(bool(state.get("music_muted", false)))
	set_sfx_muted(bool(state.get("sound_muted", false)))

func start_music(restart := false) -> void:
	if not is_instance_valid(_music) or not _music.stream:
		return
	# Apply inherited focus/pause before play, not after its first audio block.
	_update_pause_state()
	if restart or not _music.playing:
		_music.play()
	_update_pause_state()

func stop_music() -> void:
	if is_instance_valid(_music):
		_music.stop()

## Does not pause the SceneTree. Call alongside a real gameplay pause.
## Keeps menu BGM softly playing, clears stale SFX, but permits UI/outcome cues.
## Only app background or SceneTree suspension pauses the music transport.
func set_game_paused(value: bool) -> void:
	_game_paused = value
	_update_pause_state()

## Settings audition restores normal BGM gain while gameplay remains paused.
## App background and SceneTree suspension always take priority.
func set_music_preview(value: bool) -> void:
	_music_preview = value
	_update_pause_state()

## Focus notifications call this automatically; exposed for application lifecycle.
## Backgrounding rejects all new cues; resume never replays old carrier events.
func set_backgrounded(value: bool) -> void:
	_backgrounded = value
	_update_pause_state()

func _is_paused() -> bool:
	return _game_paused or (is_inside_tree() and get_tree().paused)

func _update_pause_state() -> void:
	if not is_instance_valid(_music):
		return
	_music.volume_db = MUSIC_GAIN_DB + (MUSIC_DUCK_DB if _game_paused and not _music_preview else 0.0)
	_music.stream_paused = _backgrounded or (is_inside_tree() and get_tree().paused)
	if _backgrounded or _is_paused():
		stop_all_sfx()

func stop_all_sfx() -> void:
	for voice in _normal + _priority:
		voice.stop()

func play_ui_click() -> bool:
	return play_event(&"ui_click")

## This is a release cue, not proof a skill has been released. Do not call merely
## for opening the tool-detail modal in the current non-playable UI fixture.
func play_tool(tool_id: StringName) -> bool:
	if not TOOL_EVENTS.has(tool_id):
		return _drop(tool_id, &"unknown_tool")
	return play_event(TOOL_EVENTS[tool_id])

## Returns true only when a voice actually starts. Dense bursts are dropped, not
## queued, so delayed pickup/fire audio cannot accumulate behind real events.
func play_event(event_id: StringName) -> bool:
	if not SFX_PATHS.has(event_id):
		return _drop(event_id, &"unknown_event")
	if not _streams.has(event_id):
		return _drop(event_id, &"missing_stream")
	if _backgrounded or (_is_paused() and event_id not in UI_EVENTS):
		return _drop(event_id, &"paused")
	if sfx_muted or sfx_volume <= 0.0:
		return _drop(event_id, &"muted")
	var now_ms := Time.get_ticks_msec()
	if now_ms < int(_next_allowed.get(event_id, 0)):
		return _drop(event_id, &"event_cooldown")
	if event_id in CARRIER_EVENTS and now_ms < _next_carrier_ms:
		return _drop(event_id, &"carrier_group_cooldown")
	if event_id in COMBAT_EVENTS and now_ms < _next_combat_ms:
		return _drop(event_id, &"combat_group_cooldown")
	var important := event_id not in CARRIER_EVENTS and event_id not in COMBAT_EVENTS
	var pool: Array[AudioStreamPlayer] = _priority if important else _normal
	var chosen: AudioStreamPlayer = null
	for voice in pool:
		if not voice.playing:
			chosen = voice
			break
	if chosen == null and important:
		# Reserved voices prevent dense carriers from hiding UI, tools or outcomes.
		chosen = _priority[_priority_cursor]
		_priority_cursor = (_priority_cursor + 1) % PRIORITY_VOICES
		chosen.stop()
	if chosen == null:
		return _drop(event_id, &"voice_limit")
	chosen.stream = _streams[event_id]
	chosen.play()
	_next_allowed[event_id] = now_ms + int(COOLDOWN_MS[event_id])
	if event_id in CARRIER_EVENTS:
		_next_carrier_ms = now_ms + CARRIER_GAP_MS
	if event_id in COMBAT_EVENTS:
		_next_combat_ms = now_ms + COMBAT_GAP_MS
	_accepted += 1
	cue_played.emit(event_id)
	return true

func _drop(event_id: StringName, reason: StringName) -> bool:
	_dropped[reason] = int(_dropped.get(reason, 0)) + 1
	cue_dropped.emit(event_id, reason)
	return false

## A read-only diagnostic snapshot for tests and integration troubleshooting.
func get_status() -> Dictionary:
	var active := 0
	var music_index := AudioServer.get_bus_index(MUSIC_BUS)
	var sfx_index := AudioServer.get_bus_index(SFX_BUS)
	for voice in _normal + _priority:
		if voice.playing:
			active += 1
	return {
		"music_bus": MUSIC_BUS, "sfx_bus": SFX_BUS,
		"audio_driver": AudioServer.get_driver_name(), "output_device": AudioServer.output_device,
		"master_muted": AudioServer.is_bus_mute(0), "master_volume_db": AudioServer.get_bus_volume_db(0),
		"music_bus_muted": AudioServer.is_bus_mute(music_index) if music_index >= 0 else true,
		"music_bus_volume_db": AudioServer.get_bus_volume_db(music_index) if music_index >= 0 else -80.0,
		"sfx_bus_muted": AudioServer.is_bus_mute(sfx_index) if sfx_index >= 0 else true,
		"sfx_bus_volume_db": AudioServer.get_bus_volume_db(sfx_index) if sfx_index >= 0 else -80.0,
		"music_playing": is_instance_valid(_music) and _music.playing,
		"music_paused": is_instance_valid(_music) and _music.stream_paused,
		"music_ducked": _game_paused and not _music_preview,
		"music_player_gain_db": _music.volume_db if is_instance_valid(_music) else 0.0,
		"music_position": _music.get_playback_position() if is_instance_valid(_music) else 0.0,
		"music_volume": music_volume, "sfx_volume": sfx_volume,
		"music_muted": music_muted, "sfx_muted": sfx_muted,
		"game_paused": _game_paused, "music_preview": _music_preview, "backgrounded": _backgrounded,
		"active_sfx": active, "max_sfx": NORMAL_VOICES + PRIORITY_VOICES,
		"accepted": _accepted, "dropped": _dropped.duplicate(),
		"loaded_cues": _streams.size(), "load_errors": _load_errors.duplicate(),
	}

func _exit_tree() -> void:
	# Release duplicated looping stream and all active playbacks on scene replacement.
	if is_instance_valid(_music):
		_music.stop()
		_music.stream = null
	for voice in _normal + _priority:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	_streams.clear()
