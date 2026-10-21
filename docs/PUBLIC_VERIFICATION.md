# Current verification boundary

Updated 2026-10-21 for the bounded Threefold Supply Steps continuation. Current immediate published baseline: `9d3a2842dfdbb16fed12b9d80967541961208479` (eight current single-ant levels and the single-level authoring entry). Published core baseline: [`125646450cd1bf5e90d6d7cbc833ca34ff47bd75`](https://github.com/crazyniu/ant/commit/125646450cd1bf5e90d6d7cbc833ca34ff47bd75). Current development source adds API 3.1.0 growth integration; do not claim it is byte-identical to the frozen API 3.0.0 recording.

## Existing bounded reports

The following records were read for this documentation update. They are retained test evidence, not tests newly rerun by editing this document. Later changes to covered code require revalidation.

| Source | Recorded result | What it establishes |
|---|---|---|
| `tests/test_ant_meta_flow.gd` → `reports/ui/ant-meta-flow.json` | 18 checks, no failures | Headless production startup/Home → map → preparation → loading/play → final-hit reward → shop purchase → map → unlocked next-level entry; real 150-point first receipt, duplicate-credit/debit protection, insufficient balance, preparation/shop return-state preservation and actual ×1.05 rules loadout. |
| `tests/test_ant_growth_integration.gd` → `reports/rules/ant-growth-integration.json` | 133 checks, no failures | Same authored input sequences on three current levels, baseline worker versus Swift Lv.4; earlier delivery and final hit, conserved resources, ≤4 transport tasks, frozen loadout and unchanged enemy speed. |
| `tests/test_ant_progression.gd` → `reports/rules/ant-progression-tests.json` | 1,062 assertions, passed, no failures | Local progression service: costs/rewards, persistence/restart, duplicates, atomic purchase rollback/retry, frozen loadouts, navigation, injected storage failures, corrupt/future records and rejection of fake ad rewards. |

The flow test invokes production signals/methods and automatically replays authored inputs. It is not native mouse or touchscreen acceptance and does not establish that a human played the game. The service suite does not itself test composed UI, sound, the live ad SDK or economy balance. Do not add these different scopes into a “whole-game checks passed” claim.

## Measured growth result

All times below are authoritative simulation seconds from the three-level growth report, not video duration. Both loadouts use the same authored inputs and unchanged enemy speed.

| Current level | Worker Lv.1 final hit | Swift Lv.4 final hit | Beads remaining in both solves |
|---|---:|---:|---:|
| serpent-01 | 19.950000 | 18.958697 | 6 |
| serpent-02 | 26.450000 | 25.210871 | 4 |
| serpent-03 | 27.350000 | 25.863045 | 6 |

First delivery is 3.200000 seconds for worker and 2.456523 for Swift Lv.4 in all three cases. These are measurable gains on the current slices, not a claim that 500-point Swift pricing or repeated progression is balanced for players.

## Visual and source status

The actual production `tests/capture_ant_meta_pages.gd` capture produced **five 1440 × 2560 pages: Home, adventure map, preparation, shop and settings**. The separate `meta-pages.json` capture report records a fresh isolated profile, zero points, ready economy state and no fabricated balance. This is real scene rendering, not a concept screenshot. Capture artifacts are kept outside source.

The final capture completed after the map/preparation/shop revisions and was visually inspected on 2026-10-21. The observed fixes are a visible map path with non-stretched nodes; preparation without duplicate slogans, long descriptions or redundant carry/speed copy; boss/segment/target and per-color requirements presented with icons and real counts; neutral locked/disabled 500-point Swift and 100-point training actions at zero balance; and the Swift badge fixed separately in the card corner.

No runtime script error was reported during this capture. A one-resource-still-in-use diagnostic remains on process exit, so this is not a completely clean shutdown claim. Capture/inspection is not user approval, native-input acceptance or a claim that the result screen was included. The published core's normal-speed level-2 recording establishes only its recorded source version; it cannot validate new meta screens, reward presentation or newer navigation changes.

The capture reports 14 loaded sound cues, no load errors and BGM playing, with `audio_driver: Dummy`. These flags establish resource/lifecycle state, not audible speaker/headphone output, a recorded mixed soundtrack or human listening approval.

A read-only source check for this documentation update matched all 11 meta PNGs to their manifest dimensions and SHA-256, and all eight independent crops to the exact corresponding source-atlas pixel regions. No asset was changed. `assets/meta-ui/validation-report.json` records the earlier asset-level checks. It does not replace a composed running-scene inspection, native input test or user approval. Its native dimensions, transparency and source-crop relationships can be verified independently of gameplay. A shop concept reference is not an approved final UI.

Older `docs/`, `reports/campaign/`, automatic-team rule/UI reports and pre-serpent screenshots belong to superseded versions. In particular, historical 33-level runs, 20/30-ant teams, five-slot flows and old campaign candidate entry checks are not evidence for the current single-ant build. This document supersedes the prior automatic-team `PUBLIC_VERIFICATION.md`.

## Reproduce bounded checks

Import first with Godot 4.6.3. Use isolated writable HOME/XDG and `ANT_RESCUE_PROFILE_DIR` locations, not a player's profile. These scripts may refresh their corresponding report JSON files.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/test_ant_progression.gd
godot --headless --path . --script tests/test_ant_growth_integration.gd
godot --headless --path . --script tests/test_ant_meta_flow.gd
```

The commands describe reproduction, not an assertion that they were all rerun after every code change. Keep the exact checked source revision with any new report or capture. Capture videos, generated `.godot` caches and temporary profiles are not source assets.

## Still outside acceptance

- Remaining content for the new 30-level single-ant campaign and fuller authoring workflow beyond the explicit single-level CLI.
- Further distinct themed scenes and fixed targets beyond the current woodland, ruins and Ice Valley slices.
- Optional junction combos, hidden supplies and real advertising SDK.
- Natural human input, difficulty and economy tuning, full multi-level playthroughs.
- Final visual approval, hardware sound listening, macOS-native execution and target-device performance.
- A fresh whole-project regression for the final integrated source revision.

No report in this batch authorizes or implies merge, release or deployment.

## Ruins-scene continuation, baseline 8901b34

This continuation adds exactly one region/guardian slice, not a new 30-level batch. `test_ruins_rules.gd` passes 707 bounded assertions: all 16 level-4 inputs accepted, 27.35-second final hit before the 66-second deadline, four-carrier maximum, eight remaining beads, per-color accounting, blocked yellow opening, and unchanged original three replay terminal times. `test_ruins_scene.gd` passes 83 checks with 3216 authored-route samples, a minimum 70 logical-pixel separation from the enemy route centerline, shared scene/guardian projection and bounded result/control sizes. The inspected ground hull is limited to this art/layout and solution, not every hypothetical future path.

The final affected-scene headless run exits 0 with passing checks, but reports ObjectDB leaks and seven resources still in use at shutdown. The count varies between runs; assertions passing is not zero-error execution or proof that the earlier shutdown issue was fixed. Retained meta/growth/progression reports are not rerun as full suites by this scene batch.

The final same-version real GL capture is 1440×2560 at 30 FPS, 33.53 seconds unsped and uncut: preparation → real Loading → level 4 → last hit → saved-cart result. Production timers reach victory at 27.35 simulation seconds. Developer image inspection confirms four-color preparation counts fit, the fourth color button is unobscured, the cart stays on its goal platform, and result guardian/coins remain inside their allotted bounds. Cloud X11 reported two `BadShmSeg` startup diagnostics; the capture continued to completion. This is recorded as an environment diagnostic, not hidden as a clean run. Human play, listening and device acceptance are not claimed.

## Color-row presentation follow-up

After that full journey, a presentation-only follow-up replaced the four-color 3+1 layout with a dynamically sized single row and replaced unreachable-color padlocks with a road-barrier symbol, desaturated ant and “No reachable bead” feedback. The current two-state GL capture is 1440×2560 and matches the updated `play.gd`/`ui_icon.gd` hashes. The previous 33.53-second journey retains the earlier button arrangement and is not represented as a new full replay of this UI follow-up.

`test_color_row_layout.gd` passes 221 bounded checks: actual level-4 and level-1 Controls, equal non-overlapping targets, 44-point-equivalent minimum dimensions, rejected blocked clicks without reservations/count changes, valid single dispatch, modal guard, and pure geometry for 1–6 colors. It does not create new six-color content. The headless fixture reports three resources at shutdown; the two-state GL run reports one, plus unavailable ALSA output falling back to Dummy. These remain diagnostics, not hidden by passing assertions.

`rescue_rules.gd` and all level configurations are byte-identical to the validated ruins journey. The 707-rule suite and the whole journey were not repeated for this button-only change. The screenshots are developer inspected, not final user/device acceptance.

## Ice Valley continuation, baseline 2a5b0d1

This batch adds one actual level, not an inherited 30-level validation. `tests/test_ice_rules.gd` → `reports/rules/ice-rules.json` passes 1469 bounded checks across the new level's exact-event and 100ms-step authored replays. Both use Worker Lv.1 and 16 inputs, win at 26.90 simulation seconds, keep four-carrier capacity, consume exactly four damage per color and leave eight beads. Red and green opening routes differ; gate cells remain occupied until pickup. The unchanged rules/level-4 hashes are checked; the old 707 and 30-level suites were not repeated.

`tests/test_ice_scene.gd` → `reports/ui/ice-scene.json` passes 83 new-scene checks and samples 3216 points on the actual authored carrier routes. Minimum separation from the outer enemy route centerline is 75 logical pixels. The checks cover clear-ground bounds, shared preparation preview, fixed camp identity, real natural terminal state and bounded camp/coin result sizes. Headless exit is 0 but ObjectDB and two-resources-in-use shutdown diagnostics remain; no generalized leak fix is claimed.

The same-version real GL 1× capture is 995 frames at 30 FPS, 1440×2560, 33.1667 seconds including preparation, actual game loading and result. Its gameplay final hit is at 26.90 simulation seconds. The production adapter successfully records completion and a first-clear receipt of 100+50=150 points. Prerequisite levels 1–4 are unlocked only in a labelled isolated capture fixture, with no points granted; normal profiles still need their saved unlocks. The result is an actual winter-camp result, not a princess replacement image over the old logic.

Developer image inspection covers the initial snowfield, walking/pickup opening, projectile, shortened serpent and result: ants approach on the inner snowfield rather than the outside road; the camp sits on its top-left platform; nest/cannon remain independently anchored; four entrances stay in a single row; result content fits. Background native detail is 940×1672, not claimed native 2K. The actual recording reports no script error or resource-at-exit error; a cloud-driver V-Sync warning remains. Its final audio state is Dummy output, BGM playing and 14 cues loaded without load errors. Recorded mix and numerical audio checks are not human listening or hardware-output acceptance.

All 14 recorded production code/config/art hashes must match the frozen candidate. Frozen source excludes captures, raw movies, temporary profiles and old generated variants. Natural user input, listening, difficulty/economy tuning, final visual approval and Mac/device acceptance remain separate.

## Reusable single-level entry and ruins fork

`tools/validate_serpent_level.gd` adds one explicit level-path check over the existing production rules. `tests/test_level_check_entry.gd` passes 16 checks using valid level 5 and deliberately invalid variants; the actual CLI call also exits 0 at the independently established 26.90-second final hit. This is not a solver, framework, automatic catalog sweep or visual editor. It never changes player progress.

`tests/test_ruins_fork.gd` passes 54 bounded checks for level 6: 18-bead/12-HP budget, twelve authored Worker inputs, actual near red/far green/outer blue choices, pickup-only core access, one-point armor cracking, conservation, and 2412 sampled carrier points with minimum 129.79 logical-pixel enemy-centerline separation. The recorded rule final hit is 20.85 seconds against the 60-second contact time, leaving six beads. The reused rules and existing levels are unchanged. No earlier full historical suite was repeated.

The same-version real GL capture completes in 812 frames at 30 FPS, 1440×2560, 27.0667 seconds without speed-up or cuts. Its production base-worker final hit is 20.85 simulation seconds, maximum observed transport occupancy is 3/4, six beads remain, the fixed cart is saved, and the real first-clear 150-point receipt and completion are persisted. Only prerequisite levels 1–5 are marked complete in an isolated fixture; no points are granted for those prerequisites.

The first capture fixture omitted prerequisite 5 and was correctly blocked by the existing unlock guard. That incomplete recording was discarded from deliverables; the fixture now checks prerequisite/entrance success and exits quickly on failure. No gameplay unlock rule was weakened. Developer inspection of the corrected preparation, initial state, walking, projectile and result verifies shared scene projection, inner ant versus outer serpent route separation, the three-entry single row and bounded cart/coin/button dimensions. This is automated authored input, not natural human play or final visual acceptance.

This actual GL recording reports only unavailable V-Sync control; no script or resource-at-exit errors were emitted. Its captured soundtrack includes the production mix while runtime output is Dummy; BGM playing, loaded cues and numerical levels do not establish hardware audio or human listening approval. All fourteen recorded production code/config/art hashes must match the frozen candidate. Older suites were retained, not rerun as whole-project validation.


## Ice Supply Ridge and ice-crested appearance

This independent level-7 continuation uses the existing ice ground/camp and unchanged authoritative rules. `tests/test_ice_supply_rules.gd` records 668 assertions: 21-bead / 17-HP per-color budget, red→yellow→blue pickup-only opening, the distinct green-side route, exterior blue supply, exact-event versus 100ms updates for both complete authored solutions, capacity rejection without hidden queue, conservation, four armor cracks, thirteen removals and finite-goal defeat. Both base Worker solutions finish at 27.85 simulation seconds before the 62-second contact time; four beads remain. Only this level was replayed, not the old campaign suites.

`tests/test_ice_serpent_skin.gd` records 50 checks of explicit appearance selection, eight real yaw images rather than whole-head rotation, measured atlas region/anchor bounds, unchanged old default tinting, and identical rule snapshots for an appearance-only change. `tests/test_ice_supply_scene.gd` records 43 checks of the integrated level, shared preparation/camp/skin presentation and 3417 actual-path samples with minimum 75 logical-pixel separation from the outside enemy centerline. These three headless runs exit 0 without script or resource-at-exit diagnostics. The new source sheet was split by alpha components, not equal cells; packed pixel dimensions are not a claim of native 2K source art.

The actual GL capture is 1024 frames at 30 FPS, 1440×2560, **34.1333 seconds** unsped and uncut, including preparation, real Loading and result. The production game wins at **27.85 simulation seconds**, observes at most four carriers, saves the winter camp and commits completion plus a genuine 100+50=150 first-clear receipt. Only prerequisite levels 1–6 are marked complete in a labelled isolated fixture; no prerequisite points or Swift upgrades are supplied. The result shows four unused beads, not a forced board clear.

Developer inspection of preparation, initial, opened-core, shortened-snake/projectile and result images confirms independent head/body/tail assembly, visible color/armor distinctions, turning head pose, inner snowfield carrier paths, fixed camp support, four aligned entrances and bounded result art/buttons. This is not natural human input, final user art approval or hardware audio acceptance. The recorded runtime uses Dummy output with production BGM playing and 14 loaded cues; the captured soundtrack does not establish speaker/headphone listening quality.

The real GL run has only the cloud-driver V-Sync warning, with no script or resource-at-exit diagnostic. Eighteen recorded production code/config/art hashes must match the frozen candidate. Existing levels 1–6 and `rescue_rules.gd` stay byte-identical to the published baseline. New skin loading, whitelist validation and tint support are presentation changes; there is no ice damage, freezing, slipping or movement-speed rule. No old 30/33-level report is current-mode evidence, and no merge/deployment is implied.


## Level 8: Traveler’s Twin Groves

This increment is based on published commit `f5b23489c404a778b0f5f1a0f5e899cba46deb79`. It adds one independently authored two-island woodland puzzle, a fixed traveler target and purple as the fifth existing resource color. The authoritative rules and levels 1–7 remain byte-identical; prior tests are retained, not represented as a new full-campaign pass.

The current integrated level passes **834** bounded rule checks, production single-level CLI validation and **63** scene checks. The latter sample 3,015 carrier-ground positions, with minimum outer-road centerline separation 112.34 logical pixels, test actual five-color controls, and check the traveler’s opaque pixels do not intersect the speed control. The scene fixture exits 0 but emits ObjectDB and two-resource-in-use shutdown diagnostics; this is not described as a clean exit.

The actual same-version GL capture is **941 frames at 30 FPS**, **1440×2560**, **31.3667 seconds** unsped and uncut. Production gameplay wins on final damage at **25.05 simulation seconds**; 15 authored single-ant inputs use the base Worker Lv.1, maximum occupancy is four carriers, six beads remain, and the saved traveler result commits a genuine 100+50=150 first-clear receipt. Only prerequisite levels 1–7 are unlocked in the labelled isolated fixture, without points or upgrades. This is automatic production input replay, not human play.

The final ground-scale traveler uses its measured foot anchor and leaves the ×1 control clear. Preparation fits five real color requirements without cropping; gameplay uses five independent equal-width color buttons in one row. Developer inspection covered preparation, natural gameplay and the saved result. No user visual acceptance is implied. The GL log contains only unavailable V-Sync control, with no script or resource-at-exit diagnostic. Nineteen recorded production code/config/art hashes match the frozen candidate.

The captured soundtrack is the production mix; runtime audio output is Dummy. Fourteen cues load and BGM is playing, but numerical sound levels or an encoded track do not establish hardware output or human listening quality. Human pacing, natural input, economy, final art and target-device checks remain separate. No new escort, bonus, combat mechanism, full30 completion, merge or deployment is claimed.


## Level 9: Threefold Supply Steps

The current increment is based on `9d3a2842dfdbb16fed12b9d80967541961208479`. It adds one four-color, three-lobed staged-opening puzzle on the existing central-entrance ruins scene, plus the independent eight-yaw carapace serpent appearance. The authoritative rules, prior appearances and levels 1–8 remain unchanged.

The integrated candidate passes **1,466** bounded level-rule assertions, **50** appearance checks, **60** scene checks and production single-level CLI validation. Both 17-input Worker Lv.1 sequences finish at 28.75s, but they select different nearest yellow targets: the central blue core opens at 3.00s in the red-first route versus 7.20s in the blue-first route. Sixteen task paths are 3–5 cells and one is six cells; longest recorded all-color no-dispatch window is 0.80s. The scene check samples 3,417 carrier-ground positions with minimum enemy-centerline separation 129.79 logical pixels. These bounded measurements are not human strategy or balance approval.

The same-version actual GL journey is **1,053 frames at 30 FPS**, **1440×2560**, **35.10 seconds** unsped and uncut, including preparation, actual Loading, production play and the result. The final damage occurs at **28.75 simulation seconds**, observes at most four carriers, leaves six beads, and saves the cart plus a genuine 100+50=150-point first-clear receipt. Only prerequisites 1–8 are completed in the isolated recording fixture, without points or upgrades. Twenty recorded production code/config/art hashes must match the frozen candidate.

Developer inspection covered the new head/tail contact and turning posture, colored shell body and distinct intact/cracked HP2 overlay, cart footing, natural ground transport, four equal-width inputs and real preparation requirements. It does not establish user visual acceptance. The GL log contains the unavailable-V-Sync warning and a low-disk-space warning at 9.93GiB available; recording completed naturally, with no script or resource-at-exit diagnostic. The scene headless fixture exits 0 with passing assertions but reports ObjectDB and two resources still in use at shutdown; it is not called a clean exit.

The soundtrack contains the real production mix while cloud runtime output remains Dummy. A playing BGM player and encoded mix do not establish human listening or hardware acceptance. No old30/33-suite result is reused as evidence for this model, and no full campaign rerun, new combat mechanic, final economy balance, merge or deployment is claimed.
