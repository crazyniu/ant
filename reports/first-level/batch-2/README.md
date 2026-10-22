# First-level visual batch 2: candidate, not accepted

This batch changes the actual first-level carrier attachment, articulated-leg metadata and exterior route geometry. It does **not** establish 1:1 visual fidelity, a rendered game screenshot, or completion of the first level. Other levels remain gated and were not played or modified.

## Actual changes

- The unchanged round ball now attaches to eight measured/anatomical back contacts instead of a shared floating point above the head. Parent depth projection is compensated without changing its 33.5 logical-world diameter. During the existing pickup hold, that same ball lifts from the source cell center onto the back; no new rule or delay was added.
- The source ant raster and 62-wide authored model are unchanged. Existing ground-depth projection is .88–1.0; 62 is **not** a constant final screen width in all views. The visible feet are now actually bound: E/SE/SW/W/N have four, S six, NW/NE three. Hidden legs do not receive invented transparent bindings. The shader supports up to six enabled legs.
- The first-level exterior centers and optional 12px screen-space corners were corrected. Interior resource centers, target endpoints, nest/gateway, dragon route, walkable polygon, rules paths, timing, rewards and concurrency were not moved. Corners use at most 45% of either adjacent segment and are opt-in for this scene only.
- Board, cargo, stock, hopper and flight draw parameters use one ball size/atlas authority. This is **not** a claim that the unloading-to-loading presentation is complete: the existing nest-to-stock effect is a 5.5px star, not the transported ball, and no cannon crew is present.

## Evidence and boundaries

| Check | Result | What it does not establish |
|---|---:|---|
| Actual first-level node/material-transform test | 4,826 assertions, no failures; 240 board balls, five stock balls, hopper, 16 view/depth combinations, 1,178 live cargo samples, 36 pickup samples, 36 shot draw-contract samples | GPU pixels, native filtering, leg-warp appearance or natural play |
| Full first-level production controller | 18,922 checks; 8,349 cargo samples; victory at 110.425s, 207 balls remain; 148 points saved; no Next button | Human readability/balance, real mouse, sound or GL acceptance |
| Entry/hopper/phase/feedback regression | 48 checks, no failures | Later levels are only rejected IDs/historical save metadata, never loaded |
| Production route audit | 369 routes / all 240 targets, 120Hz heading samples and all-phase foot-displacement bounds | Not every possible board occupancy; not body/cargo/dragon-image collision |

With the same measured foot model, the old route's bounded minimum was −7.745941px on the ground and −8.756363px including lifted-foot projection. The integrated route gives +3.032726px / +1.654878px. After an additional complete-frame movement allowance of 0.753371px, conservative sampled-model margins remain **+2.279355px / +0.901507px**. The declared ground polygon is not a segmented texture mask. Dragon distance is to the route centerline, not its visible silhouette. See [geometry method](audit_footpath_README.md) and [exact results](audit_footpath_integrated.json).

The longest route reduction is 41.418545px. Rules durations remain unchanged, so the greatest corresponding average screen-speed reduction is 3.5341%, not a speed-up. There is no teleport, new shortcut through occupied cells, smaller ant, changed 8.25-cell approach allowance, or changed 145-second budget.

## Images, explicitly offline

- [Reference / before / after](reference-before-after.png): the confirmed reference beside complete 8-second production-node compositions. The before snapshot is the prior candidate; the after snapshot uses this batch's actual positions. Not a Godot render. CPU tint is approximate; limb warp, particles and native font rendering are absent.
- [Eight-view back contact](cargo-before-after.png): unchanged source ant and ball with old/new attachment, enlarged 4×. Not animation acceptance.
- [Measured visible feet](audit_footpath_corrected_endpoint_overlay.png) and [actual-route geometry overlay](audit_footpath_geometry_overlay.png): analysis diagrams, not game screenshots.

No complete design image is used as a runtime background. Reference images are only comparison evidence. Runtime objects remain independent.

## Still visibly wrong / not accepted

1. Reference balls are slightly vertically oval in the drawing, densely packed, with small high highlights. Current atlas balls read too circular, separated and broadly highlighted. Two generated candidates were reviewed and **not selected**. No replacement ball PNG is included in this batch.
2. Reference color cards use large, viewer-facing ant portraits. Current cards show small side-facing full-body ants. Five real color controls remain correct for the current rules; old 20/30 teams must not return.
3. Dragon body materials/scales and overall 1:1 fidelity remain unverified and visibly different. This is not dismissed as a compositor limitation.
4. The cannon lacks crew. Stock is drawn beside the cannon rather than reproducing the reference's visible ammunition loading expression. An empty hopper in the 8-second image is also a simulation-state fact, not evidence that it can never display ammo. Current transfer FX is a small star to stock, not a full-size ball entering the hopper. The nest-to-hopper gap is 107.02px; the carrier route ends at the nest.
5. The shop still uses legacy ant/ball resources and old bead wording. The inventory names these associations rather than declaring them aligned.
6. Full body/antenna/cargo occlusion, upgraded-speed geometry, x1/x2 visual gait, concurrent crossings, native clicks, audio and real GL remain unaccepted. The existing environment restriction was not bypassed. A separate no-GL Chromium comparison launch also failed on the environment's local socket boundary; its evidence was produced with CPU composition instead.
7. User acceptance remains required before any later level is opened or replicated.

## Source inventory / reproduction

[Asset inventory](asset-inventory.md) and [machine-readable inventory](asset-inventory.json) record current roles, source files, crops, alpha bounds, transforms, hashes and mismatches. Source image 864×1536 is **not native 2K**. Logical 940×1672 maps to 1440×2560 using uniform scale 1.531100478 and horizontal offset 0.382775px. This batch's [summary](summary.json) binds code, tests and evidence hashes; prior batch reports are historical and not overwritten.

From the project root, after ordinary headless Godot import, run the first-level tests only:

```sh
ANT_RESTORATION_REPORT=res://reports/first-level/batch-2/restoration-test.json godot --headless --path . --script tests/test_first_level_restoration.gd
ANT_MINIMAL_REPORT=res://reports/first-level/batch-2/minimal-fixes.json godot --headless --path . --script tests/test_first_level_minimal_batch.gd
godot --headless --path . --script tests/test_first_level_art_batch2.gd
ANT_ART_SNAPSHOT=after godot --headless --path . --script tests/export_first_level_batch2.gd
python tools/render_first_level_offline.py reports/first-level/batch-2/nodes-after-walking-8s.json reports/first-level/batch-2/after-walking-offline.png
python tools/render_first_level_offline.py reports/first-level/batch-2/nodes-before-walking-8s.json reports/first-level/batch-2/before-walking-offline.png
python tools/compare_first_level_art.py
```

Use isolated HOME/XDG directories for tests. Raw route archives are gzip-compressed for publication; the geometry README gives decompression and production-export commands. Cached imports, interim failed exports, rejected replacement atlases and private source-retrieval identifiers are not part of the published candidate.

Next visual batch: viewer-facing large card portraits, then the approved ball material/packing. Keep the same shared size authority and real five-color/four-carrier mechanics. Cannon loading/crew and the linked shop remain separately open; no new skill buttons are being added to fill the original layout.
