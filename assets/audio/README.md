# Ant Rescue audio kit · 2026-10-21

## Provenance and license record

The original 15 WAV masters were generated locally from the unchanged included `generate_audio.py`. The runnable kit now ships the full BGM as compact Ogg Vorbis plus all 14 original WAV SFX: original oscillator/noise sound design and a newly authored score. There are no external samples, recorded performances, borrowed MIDI files, melody references or third-party asset-pack dependencies. Python 3 and NumPy are synthesis tools; no tool/library audio is embedded.

These are original project-generated outputs, subject to the project owner's terms and applicable assistant-service terms. This is a transparent provenance record, not a separate legal warranty or a claim that a third party has granted an asset license. `manifest.json` contains the exact per-file SHA-256, source hash, sizes, format, duration and measured levels. The generator still reproduces the lossless source masters with the same NumPy environment. Run it in a separate directory as described below so it does not replace the runtime manifest or add an unused BGM WAV to the project.

## Contents

- `bgm_castle_garden.ogg`: 40 seconds, 96 BPM, 16 bars, C major; independent harp arpeggios, breathy melody, warm pad, bass, celesta accents and wooden pulse. Full-length sample loop with circular reverb tails, not a short beep or repeated arpeggio alone.
- `ui_click.wav`: softened wooden confirmation.
- `dispatch.wav`, `pickup.wav`, `return.wav`: team departure, individual bead pickup, delivery at nest.
- `cannon.wav`, `armor_hit.wav`, `warning.wav`: rounded toy cannon, softened armor chime, distinct route warning.
- `tool_plus.wav`, `tool_shuffle.wav`, `tool_recall.wav`, `tool_hint.wav`: four distinct accepted/released tool cues matching current UI IDs.
- `win.wav`, `lose.wav`, `error.wav`: outcome and unavailable-action cues.

All files are stereo at 44.1 kHz. BGM is native Ogg Vorbis, nominal 160 kbps, with the exact original 40-second duration and 1,764,000 decoded frames. The 14 short SFX retain their original PCM16 WAV bytes and SHA-256 hashes. Included `.wav.import` files disable Godot’s default QOA compression for those SFX. `AudioStreamOggVorbis.loop = true` and `loop_offset = 0.0` explicitly configure BGM looping; WAV loop-mode/frame properties are not used for Vorbis. Keep paths relative to `res://assets/audio/`. Soft attacks/releases and low source peaks are measured safeguards, not a substitute for actual listening.

## Integration contract

Instantiate `scripts/audio_service.gd` once as a child of the long-lived main scene. Its `_ready()` creates only the reserved `AntMusic` and `AntSFX` buses, preloads files, creates one music player and 12 bounded SFX players, and starts music by default. Apply the saved settings before adding the child so a saved zero never begins with a default-volume audio block. Set `autoplay_music = false` before adding the child if the owner wants explicit startup. No autoload or `project.godot` change is required.

Available methods:

- `play_ui_click()`: only accepted button activations, not hover, slider motion or every pressed frame. Connect each button once.
- `play_event(id)`: `dispatch`, `pickup`, `return`, `cannon`, `armor_hit`, `warning`, `win`, `lose`, `error` and the direct tool IDs above. Returns `true` only when a voice starts.
- `play_tool(id)`: `plus` / `extra_slot`, `shuffle`, `recall`, `hint`. Call only after a real tool action is accepted and applied. Merely opening a tool-detail modal is a UI click, not a skill release.
- `set_music_volume(0..1)` and `set_sfx_volume(0..1)`: the current UI uses only a music/speaker icon plus its independent volume slider. Zero volume silences the corresponding bus; a positive value restores it. Do not add a separate mute toggle. Internal `set_music_muted(bool)` / `set_sfx_muted(bool)` remain compatibility APIs, default false, and the new UI does not need them.
- `apply_settings_state(dictionary)`: adapter for the existing UI fields `music` / `sound` in 0..100 and optional legacy `music_muted` / `sound_muted` (default false). Call after each slider change, and once after creating the service but before `add_child`. The audio service applies live gains; saving preferences is the owning scene’s responsibility.
- `start_music(restart=false)`, `stop_music()`; restarting is explicit, ordinary resume retains position.
- `set_game_paused(bool)`: call alongside actual pause state. It does not change SceneTree pause. Music continues at a 4 dB lower menu level while old SFX are discarded; UI clicks/errors/outcomes still work. Tutorial, pause and result panels therefore no longer accidentally remove the score. Only actual SceneTree suspension or app background freezes music transport. The service runs while the SceneTree is paused and also detects tree pause changes.
- `set_music_preview(bool)`: settings-only music audition while the gameplay pause stays active. It restores normal gain on the existing BGM, not a second player; background and SceneTree pause override it. The owning settings page enables it and all other modals/close paths disable it. A changed nonzero SFX slider plays one `ui_click` on release, never continuously while dragging. Zero still suppresses all previews.
- `set_backgrounded(bool)`: OS application-focus notifications invoke this automatically. Backgrounding pauses music, stops old SFX and rejects all new SFX. Foreground restores only if SceneTree pause is clear, at normal gain for gameplay/settings or reduced gain for a gameplay modal. It never unpauses gameplay itself.
- `get_status()`: loaded paths, pause/duck/gain/volume state, actual driver/output device, bounded active voices, accepted count and drop-reason counters.

Carrier events share a 90 ms minimum gap; cannon/armor share 65 ms. Individual cooldowns additionally cap identical events. Sounds are dropped rather than queued. Eight ordinary voices and four reserved UI/tool/outcome voices prevent carrier storms from allocating nodes or drowning out higher-priority cues. The original BGM has +3 dB source gain, the music limiter ceiling is -9 dBFS and SFX ceiling is -5 dBFS. The slider is an independent linear gain. These are limiter ceilings, not fixed bus attenuation. Their full-volume maximum sum remains below 0 dBFS. Master and unrelated buses are not edited.

## Scope and verification

This audio-kit validation covers assets and the standalone audio service, not the complete gameplay integration. Event wiring belongs to the owning scene and its separate integration tests. A presentation/demo playback must be labeled as a preview, not evidence of production mechanic acceptance.

Run an import then tests:

```
godot --headless --editor --path . --import
godot --headless --path . --audio-driver Dummy -s tests/test_audio.gd
python assets/audio/validate_audio.py
```

`tests/test_audio.gd` checks real Godot file loads, native Vorbis looping and actual transport wrap/resume, bus separation and controls, pause/background behavior, rate limiting and bounded voice pools. `validate_audio.py` independently checks Ogg metadata plus decoded floating-point samples, all WAV contents, hashes, sizes, clipping, peaks, DC, non-silence, cue distinctness and seam discontinuity; it requires local `ffmpeg` and `ffprobe` only for validation, not gameplay. Neither proves perceptual balance. Human listening, hardware speakers/headphones, mobile interruption routing and production gameplay timing are NOT RUN until explicitly tested.

## Recorded checks

Latest automated results are in `godot-test-report.json` and `file-validation-report.json`. The source generator was run twice and all 15 WAV SHA-256 hashes matched exactly. Engine tests include 500 same-frame pickup requests collapsing to one accepted cue, fixed-pool exhaustion with priority playback still available, independent zero-volume silence and restoration, actual transport crossing the 40-second loop boundary, and pause/resume position continuity. These are automated transport/data checks, not listening approval.

## Compact source packaging and reproduction

The 7,056,044-byte PCM BGM master and its old import sidecar were moved recoverably outside the runnable project to `../ant-rescue-archive/2026-10-21/audio-source-master/`. They were not deleted. No BGM, SFX, score bars, or runtime dependencies were removed. `generate_audio.py` is unchanged; its SHA-256 is `c5a91091f5868fc08add211d4151b413d525a14ed6b45e4475befbfe3e338a05`. The original BGM WAV SHA-256 is `c9e8f3e0fb389eda152a13b4cf493b7993f48f95272c71e651e1af878b9d338e`. Both are also recorded in `manifest.json`.

To reconstruct the source masters without bloating the runnable folder, from the project root:

```sh
mkdir -p ../ant-rescue-audio-rebuild
cp assets/audio/generate_audio.py ../ant-rescue-audio-rebuild/
python ../ant-rescue-audio-rebuild/generate_audio.py
cd ../ant-rescue-audio-rebuild
ffmpeg -hide_banner -loglevel error -n -fflags +bitexact -i bgm_castle_garden.wav -map_metadata -1 -c:a libvorbis -b:a 160k -ar 44100 -ac 2 -flags:a +bitexact -fflags +bitexact -serial_offset 0 bgm_castle_garden.ogg
sha256sum bgm_castle_garden.wav bgm_castle_garden.ogg
```

The recorded encoder is FFmpeg 7.1.5 with libvorbis. Bit-exact output flags make repeat encodes byte-identical on this build; another encoder version may differ. Nominal 160 kbps is a quality/bitrate target, not a claim that the simple synthesized score needs that many stored bits every second. Native OGG playback needs no FFmpeg installation, external codec, network or absolute archive path. The `.ogg.import` file ships with the project; Godot recreates its own import cache after extraction. Do not include `.godot/` or the archived master in the delivery ZIP.

Digital and headless Dummy-driver tests are automated checks, not actual listening, Mac playback, speaker/headphone validation or hardware audio approval.

## Missing-BGM fix and digital mix evidence

`tests/test_audio_scene_flow.gd` exercises actual boot, home, threaded play loading, tutorial, pause, settings, saved-zero home/re-entry and retry audio lifecycle. Its result panels are explicitly presentation-only probes, not claimed gameplay wins. `tests/capture_audio_mix.gd` records real AudioServer Master PCM with separate BGM-only segments so non-silent SFX cannot be mistaken for music. `tests/validate_audio_mix.py` checks those files, including a 4× true-peak estimate (NumPy/SciPy used for analysis only).

Run these bounded checks with `ANT_RESCUE_AUDIO_EVIDENCE_DIR` pointing outside the project, then pass that directory to the Python validator. Default output is `user://audio-mix-evidence`. The unchanged original OGG remains the only music source.

The 2026-10-21 controlled default-70% comparisons measured BGM RMS around -26.7 dBFS before and -21.5 dBFS after (approximately +5.1 dB). Modal BGM measured -25.38 dBFS, settings -21.50 dBFS. Saved zero, explicit mute and background captures contained exact zero PCM. Repeated full-volume music plus 12 simultaneous warning voice captures remained at or below -0.97 dBFS sample peak, with no sample or 4× estimated intersample clipping. Source OGG SHA-256 is unchanged: `b6c3ccc34cf32da60fac535e531012f061b698386002433c0e99a24ec68da7f4`.

These are real digital mix measurements on the Dummy driver. They do not make the cloud window's unavailable ALSA/PulseAudio output into a working speaker, and they are not a human listening pass. MovieWriter or PCM files can contain BGM even when the live environment has no output device. Hardware listening and target-device output remain NOT_RUN.

The subsequent focus-handover patch initializes new services from nonheadless window focus before autoplay, preventing music from starting when loading finishes in the background. `tests/test_audio_focus_handover.gd` provides 11 targeted initialization/PCM assertions; see `docs/AUDIO_MIX_RESTORE.md` for the before/after hashes and explicit recording-version boundary. It does not claim real OS focus-switch or hardware listening validation.
