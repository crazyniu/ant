# Original audio provenance

This package contains a 40-second, 96 BPM, 16-bar original C-major score as `bgm_castle_garden.ogg`, plus 14 original stereo 44.1 kHz PCM16 WAV cues. The bundled `generate_audio.py` synthesizes oscillator/noise sources and the authored score using Python 3 and NumPy. No third-party recordings, borrowed MIDI, melody reference or external samples were used.

All 15 runtime audio files are loaded by `scripts/audio_service.gd`. The service uses one music player, independent music/effect gain, explicit Vorbis looping and a bounded effect pool. Saved zero remains silent. Dummy-driver measurements and automated recording are not hardware listening approval.

`manifest.json` preserves file hashes, sizes, encoding and original source-master hashes. The reproducible lossless BGM master is not a runtime dependency and is not bundled. To recreate it, copy the generator into a separate build directory and run it there; use the encoder arguments recorded in the manifest if recreating OGG. Godot playback itself requires neither Python nor FFmpeg.

These are project-generated outputs subject to owner and applicable service terms. This provenance record is not a separate legal warranty, an asset-pack license or a project-wide open-source license grant.
