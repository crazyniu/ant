# Public snapshot verification

Snapshot: 2026-10-21, Godot 4.6.3 cloud-developed Game 2.

## What is unchanged

All 238 production script/shader, scene, resource/import, level-data and project-configuration files match the tested frozen handoff byte for byte. This includes startup/Home/threaded Loading, enlarged icon-only outcome actions, and the BGM lifecycle/gain/focus fix. Gameplay rules and timing were not changed for publication.

The public preparation removes private delivery instructions, private specification URLs and old output logs. Five review/capture helpers now write to portable `user://review-evidence/` paths rather than a particular machine's directory; one preview creates its output directory. Documentation and ignore rules are public-facing. The five changed test scripts passed Godot check-only parsing. This is not a new gameplay or visual test pass.

## Existing evidence applicable to this runtime

The frozen pair of source/resource archives was independently extracted to an empty directory, all 370 inventory entries matched their hashes, and Godot 4.6.3 imported successfully with exit 0 and no parse/script errors. Its configured startup -> Home -> real Loading -> ready play smoke passed in both catalogs: 3 validation entries with 216 live initial beads, and 30 candidate entries with 62 live initial beads. Checks used isolated profiles.

A same-version 57.5-second uncut normal-1x Godot run traversed fresh startup, Loading, Home, picker, tutorial, play, pause/Home, Settings, actual authored selections, natural final hit and Next. Output was 1440×2560 at 24fps. Final hit was 42.324286 simulated seconds; victory persisted and the conservation error list was empty. Result actions measured 560×118 logical units, scale 1, opacity 1.

The actual movie's no-input Home interval had BGM-only RMS -21.80 dBFS, peak -12.09 dBFS and zero clipped samples. Correlation with the original OGG was 0.9941. Result BGM continued with modal duck. The source OGG and all audio resources are unchanged; no replacement soundtrack was added to that evidence.

Bounded existing assertions: loader 64; startup normal 211; startup CLI isolation 26; audio service 157; actual audio scene lifecycle 77; focus initialization 11. Their scope is described in the corresponding tests and audio documentation. The publication preparation reuses that runtime evidence because hashes match; it does not label every test in the repository as freshly run.

## Explicit limits

- Cloud audio output used Dummy. Digital PCM is not speaker/headphone or human sound-quality approval.
- The prior all-30 scene sweep and per-level final-hit/contact certificates predate transport retiming. The current 33 core solutions and three scene bindings have their own scope in `reports/ui/motion-scope-handoff.json`; do not combine old results into a new full-suite claim.
- Human difficulty testing, final visual acceptance, actual target-device performance and mobile exports remain unverified.
- Reference ant-motion matching awaits decodable footage. An unavailable reference player did not establish observed movement or timing.
- Process exit can emit resource-in-use/ObjectDB/static bead Texture RID diagnostics. Bounded startup teardown identified the static bead cache; the minimal smoke is not a new comprehensive leak audit.
- Generated images, movies, caches and raw output logs are deliberately not committed. Relative evidence locations in historical scope reports describe generated outputs, not a dependency on private storage or proof that those files are included here.

`SOURCE_MANIFEST.json` identifies this public candidate's exact files and SHA-256 values. `PUBLICATION_CHECK.json` records the bounded sanitization and dependency checks; neither is a claim that GitHub publication has already happened.
