# BGM restoration and bounded verification · 2026-10-21

## Findings and fix

- The original 40-second OGG was present, loaded and looping. No new score or audio asset was generated.
- Every gameplay modal previously called `set_game_paused(true)`, which stopped the BGM transport. That silenced the tutorial, pause menu and result panels, not just active gameplay.
- The existing source score was quiet. At the default 70% slider, actual Master PCM measured approximately -26.70 dBFS RMS in the controlled segment. The `-10 dB` bus parameter was a limiter ceiling, not a fixed attenuation setting.
- `AudioService` now keeps BGM playing 4 dB quieter during gameplay modals. Settings restores normal music gain without unpausing gameplay. Background and actual SceneTree suspension still freeze transport and discard stale effects.
- Music source gain is +3 dB, with a -9 dBFS music ceiling and unchanged -5 dBFS SFX ceiling. Their maximum sum retains approximately 0.75 dB headroom before any slider reduction. Master and unrelated buses are not modified.
- Saved zero and explicit mute remain silent. Scene owners apply saved settings before adding/starting the audio service, avoiding a default-volume first block on a saved-zero entry.
- Read-only status now includes driver, output device, actual Master/music/SFX bus gain/mute state, music player gain and modal duck state.

## Final-source automated results

- `tests/test_audio.gd`: 157 assertions passed. Includes all resources, actual OGG loop wrap, pause/background continuity, independent zero/mute behavior, bounded voice pools and the new modal duck policy.
- `tests/test_audio_scene_flow.gd`: 77 assertions passed across real startup/home/threaded loading/tutorial/play/pause/settings/saved-zero/home/re-entry/retry. Exactly one AudioService remained after each scene transition. Rule time stayed frozen while modal BGM advanced. Result panels were explicit presentation-only probes, not a claimed natural victory or defeat.
- `tests/capture_audio_mix.gd` plus `tests/validate_audio_mix.py`: actual AudioServer Master PCM, not waveform synthesis or a mixed-in replacement track. The music-only samples explicitly started no SFX.

| Controlled segment | RMS dBFS | Sample peak dBFS | Notes |
| --- | ---: | ---: | --- |
| Before, BGM-only at 70% | -26.664 | -14.580 | Original player/limiter values |
| After, BGM-only at 70% | -21.532 | -12.099 | Approximately +5.13 dB RMS |
| Modal BGM-only at 70% | -25.383 | -13.223 | Continues softly, gameplay frozen |
| Settings BGM-only at 70% | -21.497 | -12.099 | Normal audition gain |
| Zero / explicit mute / background | Exact zero | Exact zero | All captured PCM samples zero |
| Full music + 12 synchronous SFX | -12.867 | -1.215 | No clipped samples; 4× true-peak estimate -1.210 dBFS |

Output files and manifests live outside the source project at `../ant-rescue-evidence/audio-fix-current/`. Core evidence: `mix-validation.json`, `capture-manifest.json`, `scene-audio-flow.json`, `before_bgm_70.wav`, `after_bgm_70.wav`, `modal_bgm_70.wav`, `settings_bgm_70.wav` and `full_volume_dense_mix.wav`.

Source OGG SHA-256: `b6c3ccc34cf32da60fac535e531012f061b698386002433c0e99a24ec68da7f4` (unchanged).

AudioService SHA-256 for this capture: `d6ee7a75fae71ec9db6a2ab62d569d2ddd622c4cf85ab8d33300fa8d835bf6f4`.

## Reproduction

```sh
export ANT_RESCUE_AUDIO_EVIDENCE_DIR=/tmp/ant-rescue-audio-evidence
# In a sandbox with no writable home, also set XDG_DATA_HOME/XDG_CACHE_HOME
# to writable temporary directories.
godot --headless --path . --audio-driver Dummy -s tests/test_audio.gd
godot --headless --path . --audio-driver Dummy -s tests/test_audio_scene_flow.gd
godot --headless --path . --audio-driver Dummy -s tests/capture_audio_mix.gd
python tests/validate_audio_mix.py "$ANT_RESCUE_AUDIO_EVIDENCE_DIR"
```

The PCM validator uses NumPy and SciPy only for offline analysis. The game requires neither.

## Limits, not acceptance claims

The active cloud launch could not open its live ALSA/PulseAudio device and fell back to Dummy. Dummy-driver PCM and MovieWriter audio can prove digital BGM exists, but cannot prove the cloud window's speakers are audible. Human listening, target-device output and mobile audio interruption/routing are NOT_RUN. No merge, deployment, new shared permissions or full campaign replay was performed for this bounded audio fix.

## Focus-handover follow-on patch

After the natural MovieWriter recording started, a bounded focus-inheritance correction was applied. Before autoplay, a new service now inherits the actual nonheadless window focus state, because it cannot receive a focus-out notification sent before its creation during threaded loading. Headless/offline execution does not invent a missing-window suspension. Pause/background policy is applied before the first play call. This changes no gain, limiter, original audio, cue selection or gameplay logic.

- Recording/mix version: `d6ee7a75fae71ec9db6a2ab62d569d2ddd622c4cf85ab8d33300fa8d835bf6f4`.
- Follow-on AudioService version: `ce289df629938b50ec663912344db90268aab04abc2ef992c096134b5d0020a6`.
- `tests/test_audio_focus_handover.gd`: 11 assertions passed on the follow-on version. An injected initial lost-focus query produced exact-zero real Master PCM, including the first block. Application focus-in notification restored BGM PCM without clearing gameplay pause; later focus-out re-silenced it. Saved zero/mute remained zero on foreground.
- `focus-handover.json` and `focus-handover.log` are in the external audio evidence directory. The test validates the initialization policy and PCM, not real OS window switching or hardware output. The earlier full MovieWriter recording must not be presented as an exact-hash full run of this later focus patch.

## Final same-version handoff recording

The subsequent 57.5-second uncut 1× MovieWriter run includes the focus patch (`ce289df629938b50ec663912344db90268aab04abc2ef992c096134b5d0020a6`) and current icon-only result controls. It traversed real startup/Home/Loading to natural first-level victory at 42.324286 simulated seconds and Next. In its actual audio, the no-input Home segment at 5.50–6.75 seconds measured -21.80 dBFS RMS and -12.09 dBFS peak with zero clipped samples; correlation with the original OGG was 0.9941. Result BGM was playing and softly ducked. See reports/ui/startup-result-audio-handoff.json. This supersedes only the older movie-version mismatch, not the explicit lack of human listening or hardware output acceptance.
