# Current carrier and dragon motion contract

Current ant transport uses 14 logical cells/s, at least 0.55s per one-way leg, plus a 0.16s pickup hold. The nearest round trip is therefore 1.26s rather than roughly 0.125–0.143s. Long routes keep their distance-based timing. Rules open the bead cell at pickup and add stock only on delivery; stage, path and all timestamps are authoritative.

`carrier_motion.gd` / `carrier_motion.gdshader` reuse the current atlas with local opposing leg, antenna and body motion. The 48px carrier has a grounded shadow, 24px load, 2.15Hz empty / 1.65Hz loaded strides and a finite pickup crouch/turn. Path translation and depth scale are not shader-owned. Per-actor phase uses simulation time, so pause and ×2 remain coherent. No extra sprite sheet or third-party art was added.

`rescue_fx.gd` uses a 1.60s cosmetic fatal sequence: 0.10s hit stop, loss of balance, accelerating fall, landing at 0.92s, settle, opaque through 1.30s, then 0.30s fade. Last-hit rules and save commit immediately. Only the outcome panel/jingle waits for presentation completion; background suspension freezes it and repeated events cannot repeat the save. Existing ordinary hits retain their separate timing.

## Bounded verification

- `tests/test_carrier_motion.gd`: local material/phase/atlas/anchor contract.
- `tests/test_transport_motion_timing.gd`: authoritative leg/hold/delivery and pause/×2/boundary contract.
- `tests/test_fx.gd`: finite fatal pose, landing, suspension and event deduplication.
- `tests/test_motion_binding.gd`: all three actual play scenes at 1x simulation, including actual carrier holds, delivery visibility, final-hit save and delayed result. Headless node replay is not graphical or human acceptance.
- `tests/capture_motion_review.gd`: normal 1x GL MovieWriter run of real validation-01. Two deliverable excerpts retain normal source speed: walking/pickup/return and final-hit/collapse/result. Trimming does not alter simulation or playback rate.

All 33 authored original front-choice orders were checked with the current transport parameters. Twelve schedules required later legal clicks; none required changes to threat budget, cannon, tools or dispatch spacing. All retain at least 0.75s between selections. Current core proof records are separate from the old all30 full-scene and full-level boundary certificates, which are not claimed current. Three validation final hits are 42.324286s, 53.158572s and 76.515716s; the third remains a tight technical timing case (0.434284s threat margin), not proof of comfortable human difficulty.

Runtime resources and component paths are listed in `ASSETS.md` and `docs/asset-manifest.json`. Current visual recordings/logs live outside the source project in `../ant-rescue-evidence/motion-current/`; do not package old videos/screenshots into source. Current-source hashes accompany that recording. Manual visual, listening, device and 30-level difficulty acceptance remain separate.

## Reference boundary

The two supplied YouTube pages were attempted in the cloud browser; page metadata loaded but the players never produced gameplay frames. This motion pass therefore follows the explicitly authorized experience-based approach, not claimed observation of the competitors' movement.

The dragon uses a bounded flat 32×24 2D mesh (825 vertices) over the unchanged atlas region. `combat_tint.gdshader` forward-deforms head, torso and wing regions by different amounts while retaining the planted paw band. The outer tilt is limited to 0.045 radians and settling to 0.035; it is not a whole-card flip. No texture inverse-warp or new 3D model is used.

A short three-star local defeat orbit appears above the slumping head from 0.25s until the finite conclusion. It makes the defeated state explicit without another meter, large rotation or global flash. It is phase-driven, bounded and has no rules/audio/persistence callback.

The precise current-versus-superseded evidence matrix, original-order proof coverage and exclusions are in `reports/ui/motion-scope-handoff.json`. Do not relabel historical full-campaign or exact-boundary passes as current after a transport timing change.
