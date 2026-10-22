# First-level ball profile candidate

Base: `b5e7fe7`, 2026-10-22. Only the approved first level. No gameplay,
board-center, route, speed, timing, reward or level-access change. This is a small
geometry correction, **not completed material restoration or GL acceptance**.

## Change and reference boundary

The approved 864×1536 design has tightly packed, mildly vertical balls. Native
JPEG boundaries are uncertain by roughly 1–2 pixels; they are not recovered
alpha masks. Existing board centers already approximate the design's spacing,
so the 240 centers, flower pattern and four board corners stay unchanged.

The shared world footprint changes from 33.5×33.5 to **33.5×35.75 logical units**.
With the unchanged source alpha, the visible body is approximately 32.25×34.37,
reducing the previous roughly 2.2-unit vertical gap at the 34.4-unit row pitch.
This is a geometry candidate, not a claim that a mathematical ellipse equals
the approved fuller lower-body contour.

A dedicated `approved_world_ball()` creates board, carried, incoming loading
and hopper balls with both dimensions. Preview and real projectile drawing use
the same shared vector. Existing depth/recoil compensation preserves that
world footprint. Tutorial/palette UI icons remain intentionally illustrative
sizes; no rejected side-inventory HUD returns. The carrier's back contact is
unchanged. All world roles retain one atlas and its real five-color regions.

The taller ball raises its center by 1.125 units while its bottom stays on the
carrier's back. The first loading test correctly caught the old receiving-hand
center mismatch. Only the two raised receiving forelegs now compensate that
height; planted feet, cannon and the 4-unit push animation remain unchanged.
The same actual .80-second unload still owns inventory credit, capacity release
and fire timing. No early credit, hidden ball or extra inventory is introduced.

## Finite checks

Godot4.6.3 headless, isolated temporary profile, first-level-only:

- `test_first_level_art_batch2.gd`: **7,612 checks, no failures**. 240 board balls,
  sixteen eight-view/depth cargo samples, 1,200 live cargo samples, 360 live
  hopper samples, 64 actual loading samples, 36 pickup and 36 projectile-draw
  samples. Checks final world basis dimensions and material paint footprint.
- `test_first_level_loading.gd`: **79 checks, no failures** after grip correction.
  The preceding 76-check run had one genuine 1.12488-unit receiving-center
  failure; it is retained locally, not relabeled success. Corrected initial
  receive error is 0.000391 logical units. Real single delivery/debit/fire/hit,
  pause, x2, recoil mask and real 145-second defeat during a second unload are
  checked. This is not a complete playthrough.
- `test_first_level_previews.gd`: **1,705 checks, no failures**. Current Home,
  Map/Prep preview geometry and tutorial contract retain the shared size.
  The controlled missing-preview warning and ObjectDB exit warning remain
  recorded; this run is not warning-free.

Final art and loading logs have no script/assertion/shutdown errors. Node export
and offline composition are local QA only. The art test now writes outside the
repository by default, preserving the versioned historical batch-2 report.
No new full-route or economy regression was run because rule/config bytes did
not change.

Unchanged SHA-256:
- Rules: `61c7718f206b4bcc8dc96fcdd1bb67a19ba2a0fda43a9041abddc3f400472942`
- First-level JSON: `e5adc544bfbb8c82d883252f70a7c36fa19695693cad9f7804a9058a6044bfea`
- Ball atlas: `0c353fb03ed54f8f71036bb489802b026b072fd1b94e5e4a69d3a8b0c594d60b`

## Still open

The offline approved/candidate comparison still shows the wrong broad upper-left
highlight, overly dark lower rim and insufficiently full lower contour. Two
image-generation candidates failed that comparison and were not adopted or
published. Existing ball material therefore remains explicitly unfinished.

Current native GL must check the actual packed board, carried silhouette,
foreleg warp and cannon-opening clipping at x1/x2; node assertions cannot check
pixels or movement feel. The previous b8 native win does not certify this later
geometry delta. Physical phone, natural player balance, audio, complete original
art fidelity and user acceptance remain open. No merge, deployment or Issue
closure is implied.
