# Dependencies

- Godot 4.6.3 stable, standard GDScript edition, GL Compatibility renderer.
- All runtime PNG, OGG, WAV, font, JSON, shader and import settings are included. Godot regenerates `.godot/`; the cache is not source.
- No network, plugin, account, API key, native extension, Python, FFmpeg, NumPy or SciPy is required to play.
- Python 3 and NumPy are optional for `assets/audio/generate_audio.py`; FFmpeg with libvorbis is optional for recreating the compact BGM. Export templates are needed only for a future export and are not bundled.
- Run the configured startup scene, not the legacy shared-component gallery. The old automatic-team editor is intentionally excluded.
- The included font license is `licenses/DejaVu.txt`. No project-wide MIT or other open-source license is asserted. Asset provenance is recorded in `ASSETS.md`, the asset manifest and the audio manifest; this is not a legal warranty.
