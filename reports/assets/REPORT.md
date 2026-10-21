# Current source asset audit

Checked 2026-10-21T10:18:34.476285+00:00.

- 47 literal resource paths and 35 bounded dynamic expansions resolve.
- All 36 current manifest files match bytes and SHA-256.
- Eight current runtime PNGs are byte-identical to the measured fusion batch. The 57 nonempty, bounded and nonoverlapping atlas regions, actual-alpha gutters and BoardPlane/foot anchors retain their recorded numeric evidence.
- Full 40-second BGM now uses native Ogg Vorbis. Fourteen short SFX remain byte-identical PCM WAV. Runtime uses Vorbis loop/offset properties, not WAV loop-frame properties. Audio reports independently verify decode, full duration and actual engine loop wrap/resume. Listening remains NOT RUN.
- No old concept or standalone obsolete runtime image is included. Eight unused named regions remain embedded inside still-required atlas images and are marked as unused; they are not extra legacy files.
- The blue preview shield retains its previously recorded tight left crop. No new artwork change or unseen visual acceptance is asserted.

Current source archives must exclude .godot, screenshots, recordings, generation directories, archives, nested ZIPs and the lossless BGM master. The master is recoverably archived outside the project and reproducible from the included generator; gameplay uses the complete compact OGG. Exact archive size/hash and verification live in the external package manifest.

This source/path/hash audit does not prove final user acceptance, human playtesting, hardware listening or target-device performance.
