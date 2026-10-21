# Runtime and development dependencies

## Run the game

- Godot 4.6.3 stable, standard edition (GDScript, not .NET). GL Compatibility renderer.
- No plugins, addons, package download, network service, login, API key, native library, FFmpeg, NumPy or SciPy is required for normal gameplay.
- Open `project.godot` in Godot, wait for the first real resource import, then press F5; F5 runs the configured startup/Home entry. Do not open `scenes/main.tscn` as the playable game: it is a visual gallery.
- All source PNG/OGG/WAV/font/JSON files and import metadata are included. The `.godot/` cache is intentionally omitted and rebuilt by Godot. Export templates and engine binaries are not shipped; install the matching official templates only if exporting later.
- Desktop viewport is 1440×2560 with preserved portrait aspect. Physical window size depends on the local display/window manager. Check real local pointer mapping and display scaling.

## Optional authoring and evidence tools

- Python 3 for authoring scripts and manifest utilities.
- NumPy for `assets/audio/generate_audio.py`; NumPy + SciPy for offline `tests/validate_audio_mix.py` analysis. These are not game dependencies.
- Pillow for optional thumbnail/rendering tools that import PIL.
- FFmpeg with libvorbis for regenerating the compact BGM from the reproducible WAV master, and for optional MovieWriter video encoding. Not needed to play the bundled OGG.
- The standalone Level Studio is `scenes/editor.tscn` and uses Godot itself.

## Rights and provenance

- `licenses/DejaVu.txt` supplies the included font license.
- `ASSETS.md` and `docs/asset-manifest.json` record current AI-generated image provenance, actual source sizes, slicing, anchors and usage. They do not claim a third-party copyright clearance or legal warranty.
- `assets/audio/README.md`, `manifest.json` and `generate_audio.py` record original synthesized music/effects, hashes and reproducibility. No third-party recordings, downloaded melodies or reference-game assets are included.
- Project code and generated outputs are delivered to the requesting user for continuation; no new open-source license or redistribution permission is invented by this handoff.
