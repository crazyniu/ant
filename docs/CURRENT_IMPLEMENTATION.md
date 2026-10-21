# Current implementation contract

Version: 2026-10-21 Traveler’s Twin Groves continuation; rules API 3.1.0, level schema 3, economy schema/version 1. This document describes current source behavior and separates it from the broader product target. The earlier automatic-team contract and its 30-level reports are historical. The published API 3.0.0 core is a prior, smaller snapshot, not evidence that the new UI has passed review.

## Authority and data flow

| Responsibility | Current owner |
|---|---|
| Combat, transport, reservations, timing, victory/defeat | `scripts/rescue_rules.gd` |
| Scene input, events, effects, terminal persistence and navigation | `scripts/play.gd` |
| Threaded resource loading, Home and meta-screen handoff | `scripts/startup.gd`, `scripts/startup_loader.gd` |
| Full-screen map and preparation presentation | `scripts/adventure_view.gd` |
| Independent shop presentation | `scripts/ant_shop_view.gd` |
| Points, purchase ledger, equipment, frozen run loadout, navigation state | `scripts/ant_progression.gd` |
| Ordered catalog and level/settings completion save | `scripts/level_catalog.gd`, `scripts/save_service.gd` |
| Economy parameters | `data/ant-progression.json` |
| Available authored levels | `data/serpent-levels/serpent-01.json` through `serpent-08.json` |

The gameplay adapter, not animation callbacks, applies the authoritative result. Views consume detached state and emit requests. They must never fabricate balances, damage, unlocks, item ownership, completed levels or ad receipts.

## Single-click rules retained

1. One legal click sends one ant for one reachable, unreserved bead. Four-direction exterior reachability includes openings on every side, not just the bottom edge. Rejected input does not reserve, consume, start the serpent or queue a future task.
2. At most four tasks occupy capacity, including outbound, pickup, return and unloading. The on-board count includes reservations until pickup. Delivery, after unloading, credits inventory once.
3. One bead is one projectile and one damage. Normal HP1 and armored HP2 segments have stable IDs; the first armored hit leaves a cracked HP1 segment, the second removes it. Ordinary cannon fire has at most one projectile in flight. Inventory is deducted on fire, damage on actual hit.
4. Per-color supply must cover that color's sum of initial segment HP. Equality is not required. Victory permits leftover board beads, inventory and transports. Neither board clear nor shot launch is victory.
5. The head progresses monotonically on a finite, non-looping route. Removing a middle segment compacts later body ranks but does not move the head. The final live segment's deletion wins; a still-living serpent's earlier goal contact loses. Strictly simultaneous due damage resolves first.
6. Pause/background freeze simulation and inputs. Simulation speed scales all timing together. Loadout selection cannot change a running round. Presentation cannot debit ammo or settle terminal state again.

There are no current automatic 20/30-ant teams, queue quotas, five work slots, fixed front-armor-only attack requirement or old tool-unlock progression. An inherited node name or retained gallery does not reintroduce these mechanics.

## Current entry and meta screens

- Startup performs real resource loading before Home. Home's primary action opens preparation for the saved entrance; its map action opens the full-screen adventure map.
- Map nodes come from the actual loaded catalog and completion/unlock state. They open full preparation, not a modal level grid. Eight current level definitions are available, including ruins/parked-cart, ice/winter-camp and woodland/traveler slices.
- Preparation derives segment counts, total HP, supply and fixed-goal preview from the selected configuration. Owned worker/Swift selection is committed before launching the actual game scene.
- The independent shop is reachable from map and results. Balance, item prices, owned/equipped state and next shared level reflect service state. Product views use separate panels, title sprites, ant actors, ornaments and real text.
- Navigation persists region, scroll and selected level. Returning from the shop/preparation uses that state, rather than inventing a new selection. Persistence is not evidence that all target devices have passed scrollbar/mouse testing.
- Result presentation follows committed victory and the real saved reward receipt. Save failure leaves a retryable pending result and must not claim an uncommitted unlock or reward.

Levels 1–3 guard the princess in woodland. Level 4 guards a stationary supply cart in a new ruins ground with a left-side finite enemy route. `scene_layout.gd` shares background, board envelope, nest gateway, cannon, stock and fixed target anchors across preparation and gameplay. Level 5 guards a stationary winter camp in a snow valley with a right-to-upper-left finite road. Level 6 adds a ruins supply fork; level 7 adds an Ice Supply Ridge puzzle in the existing snow scene; level 8 adds two resource islands and a stationary traveler in the existing woodland. These are bounded additions, not delivery of every proposed target or region.

## Economy and frozen loadouts

Defaults are worker owned/equipped, shared level 1 and zero points. Worker type speed is ×1.00; Swift is a one-time 500-point unlock at ×1.20. Shared levels 2/3/4 cost 100/150/250 points and have speed multipliers ×1.05/×1.10/×1.15. Both types retain one-bead capacity and four concurrent transport tasks.

Final movement multiplier = type multiplier × current-level multiplier, capped at 1.50. Swift Lv.4 is ×1.38. Previous level bonuses are not multiplied again. Pickup/unloading pauses, projectile timing and enemy speed are not automatically accelerated to cancel growth.

`create_run` persists a unique `run_id`, selected level, reward thresholds and detached loadout. `play.gd` passes the frozen loadout into rules before the first click. Mid-run shop changes cannot alter existing tasks. The rules' integer event-run identity and the persistent economy `run_id` serve different scopes; never substitute one for the other.

First clear earns 100 plus 0–50 points; repeat clear earns 20 plus 0–10. For each level, the bonus is the floored, clamped linear interpolation between its fast and normal simulation-time thresholds. Measure from first accepted dispatch to final damage. Pause and background time do not count; ×2 does not earn extra by using a shorter wall-clock recording.

Settlement is idempotent by persistent run ID. Same-run retry returns the original receipt; incompatible repeated outcomes reject. Failure/cancellation awards zero and does not deduct existing points. Purchase requests are bound to an exact product ID; debit and unlock/upgrade commit together, prerequisites and available points are rechecked, and duplicates do not double-charge.

The balance ledger and level/settings save are separate services, not one cross-file atomic transaction. The adapter settles the reward first, then marks level completion, and gates successful result navigation on both. A retry uses the same reward run ID, preventing a second credit if the completion write previously failed.

## Persistence and failure boundaries

Default level/settings root: `user://ant-rescue/serpent-click-v1/`. The integrated progression service receives that resolved root and appends `ant-single-v1/`, yielding `user://ant-rescue/serpent-click-v1/ant-single-v1/progression.json`. The standalone progression API's default root is different; do not append either suffix twice.

`ANT_RESCUE_PROFILE_DIR` overrides the root before catalog suffixing. Replay/testing uses isolated profiles. Neither game-one nor automatic-team saves are silently migrated. Stored entrances restart a level from its beginning; a persisted run journal is not frame-perfect resume.

Progression commits write/flush/verify a candidate and backup before atomic primary replacement. Failed writes do not present candidate state as committed. Damaged records are preserved for explicit recovery; future versions block downgrade. This is a synchronous single-writer design, not interprocess locking or a proven power-loss guarantee. See `reports/rules/ANT_PROGRESSION_API.md` for service calls and recovery semantics.

Advertising is unavailable: status/request/claim APIs reject with `ad_sdk_unavailable`; no debug receipt or claimed success can grant points. A future real SDK needs provider validation and durable run/reward-ID deduplication. “Watch for another equal reward” is product intent only.

## Content, tooling and acceptance

The broader design remains in `reports/design/current-product-spec.md` and `reports/design/click-ant-current.md`. It includes work not yet implemented. Current source and bounded reports, not a concept image or old checklist, establish implementation status.

Only `serpent-01` through `serpent-08` are current. The reserved `--campaign-drafts` path points to a future serpent catalog with no authored files. Old `data/campaign-drafts/`, old validation levels, the legacy editor/generation chain and old campaign tests must not be substituted or advertised as available new-mode content.

Remaining scope: the rest of the new 30 independent levels and a fuller authoring workflow beyond the explicit single-level CLI; further independently authored themed scenes and fixed targets; optional junction combos and hidden supplies; real rewarded ads; human difficulty/economy and natural-input testing; final visual, audio and target-device acceptance. The earlier five-page GL capture at 1440 × 2560 includes the map/preparation/shop fixes and has been visually inspected; it is separate from the level-8 runtime evidence and does not establish traveler user visual acceptance. The separate level-7 runtime report records automated GL evidence, not human approval. User approval and device/native-input acceptance remain separate. Exact retained test results and their limits are in `PUBLIC_VERIFICATION.md`.

## Ruins scene contract

`data/scenes/ruins-cart.json` is presentation data, not a rule override. `transport.entrance_cell=[3,8]` is the exterior BFS source for level 4; omission retains the original center-bottom entrance. Transit paths still terminate at a reachable bead and cannot cross occupied cells. Enemy route uses finite rule arc length without looping. Guardian identity must match level data. Missing scene files/assets fail explicitly rather than silently substituting the princess scene.

The new base-worker candidate has 24 beads (six per RGBY), 12 segments / 16 initial HP (four per color), an enclosed yellow core, and a 66-second threat budget. Its 16-click authored solution uses 1.4-second input gaps and wins at 27.35 seconds, leaving eight beads; this is solvability evidence, not difficulty approval. Thirteen transports are 3–5 logical cells and three are six cells. New content must be independently solved and visually reviewed, not cloned to fill a 30-node catalog.

## Ice Valley scene contract

`data/scenes/ice-camp.json` shares snow ground, independent camp anchor, board envelope, nest gateway, cannon and enemy route between preparation and play. `transport.entrance_cell=[6,8]` is level 5's exterior BFS source. The nearby red gate at `[6,5]` opens two yellow cells on actual pickup; the farther green gate at `[8,6]` opens one. Blue exterior beads provide ammunition without opening that yellow core. There is no ice-specific movement or damage mechanic.

The candidate has 24 beads (six per RGBY), eight normal plus four armored segments, 16 HP total (four per color), and a 66-second threat budget. Its 16-input Worker Lv.1 authored solution wins at 26.90 simulation seconds, leaving eight beads. The exact 16-route sequence is `[3,4,4,4,4,3,4,5,4,3,6,5,5,5,6,5]`, with 14 routes of 3–5 and two of six. First delivery is 3.20 seconds. Longest wait until any legal new dispatch is 1.70 seconds; the 2.20-second full-capacity span includes a legal handoff at 19.90 seconds, so it is not uninterrupted inactivity. Reward thresholds 28/42 seconds remain candidate tuning, not human balance approval.

## Current authoring entry

`tools/validate_serpent_level.gd` provides one-level schema/scene/base-solution/accounting checks and optional ordered event JSON. It is a small adapter over the unchanged production rules, not a solver or gameplay system. Full visual editing, thumbnail export, authored thirty-level coverage and human testing remain unfinished. Live color controls follow the current requirement: equal-width single row, dynamic color count, unobstructed hit areas; level 8 has five buttons. Blocked color uses a road-barrier symbol and no-reachable feedback, never a purchase lock. Preparation’s five required-hit counts use a separate three-column, two-row informational layout so the fifth value stays inside its panel. Ice snow is presentation only and adds no new movement/damage rule.

## Ruins fork contract

Level 6 uses `data/scenes/ruins-fork.json` and the existing ruins/cart art; no new bitmap is duplicated. Its entrance `[5,8]`, shifted nest/cannon, 18-bead three-color fork and ten-segment combination differ from level 4. Required damage is blue5/red4/green3, including two blue armor segments. Only four blue beads are exterior, so base supply requires opening at least one core bead. A near red gate opens core45 after 1.2 seconds; green opens core46 after 1.6 seconds; an exterior blue pickup opens neither but its first shot cracks armor. Actual pickup, not reservation, owns the opening.

Twelve authored inputs at 1.4-second intervals yield a 20.85-second final hit before the 60-second goal. Routes are `[3,3,4,4,4,4,4,4,4,5,5,5]`; this authored schedule has no interval when all color entries lack a legal opportunity. Six beads remain. This does not prove the choices equally attractive to humans or the candidate 22/35-second bonus thresholds balanced. Level 6 retains the default head/body assets; level 7 selects the separate ice-crest appearance described below.

## Ice Supply Ridge contract

Level 7, “Break the Supply Ridge,” reuses `data/scenes/ice-camp.json`, the fixed winter camp and entrance `[6,8]`. Its 21-bead budget is red4/blue6/green8/yellow3; required damage is red3/blue6/green5/yellow3. Nine normal and four armored segments total 17 HP. Blue and yellow have no surplus: both inner blue cells and all yellow cells must be collected. Victory leaves one red and three green beads, not a cleared board.

All yellow cells begin blocked. Actual red `[6,5]` pickup at 1.20s opens yellow `[6,4]` and `[7,5]`; picking the central yellow at 3.00s opens blue `[6,3]` and `[5,4]`. Reservation opens nothing and pickup does not credit inventory. Green `[7,6]` instead opens the yellow wing and shortens an exterior blue route; exterior blue supplies armor ammunition without opening yellow. These are ordinary occupancy/BFS consequences, not a required scripted red-only gate or an ice mechanic.

The red-first and green-first authored Worker Lv.1 solutions each use 17 independent inputs at 1.40-second gaps and finish on actual damage at 27.85 simulation seconds, before the 62-second finite goal. Sixteen transport routes are 3–5 cells and one is six; peak capacity is four. The longest all-color no-dispatch window is 0.80s. Reward thresholds 30/44s are provisional, not human difficulty/economy approval.

`serpent.art_profile="ice_crest"` selects `assets/serpent/ice-serpent-atlas.json` in both preparation and gameplay. The white-horned broad head, faceted body and eight-yaw head/tail art are presentation only. Measured regions, physical widths and chain anchors own placement; existing intact/cracked armor and normal HP1/armored HP2 behavior remain. Unknown profile IDs or missing resources fail explicitly. Levels 1–6 retain their data and default art/tint behavior.

Bounded evidence: `reports/rules/ice-supply-rules.json` records 668 passing assertions, `reports/assets/ice-serpent-test.json` 50 appearance checks, and `reports/ui/ice-supply-scene.json` 43 scene checks. Their scopes are distinct, not a full campaign pass. `reports/ui/ice-supply-runtime.json` separately records automated GL victory at 27.85s. Final visual acceptance, native input, sound and human pacing remain separate and are not claimed complete here.

## Traveler’s Twin Groves contract

Level 8 uses `data/serpent-levels/serpent-08.json` and `data/scenes/forest-traveler.json`. The existing woodland ground, central nest/gateway, finite right/top enemy road and default serpent appearance remain; the fixed target is `traveler`. This is not a moving escort. Levels 1–7 and `scripts/rescue_rules.gd` remain unchanged.

The 10×8 board has entrance `[5,8]` and two offset islands of 11 and 10 beads separated by an empty approach column. Red/blue/green/yellow/purple supply is 4/4/4/5/4; required damage is 3/3/3/2/4. Eleven normal and two armored segments total 15 HP. Purple and blue each have one HP2 segment. Purple has no surplus, so both enclosed purple cores must be collected; victory leaves six other beads.

When dispatched first, green `[4,6]` is picked up at 1.20s and opens left purple `[3,6]`; blue `[7,6]` is picked up at 1.60s and opens right purple `[7,5]`. An initial exterior purple `[2,7]` pickup opens neither core, but the delivered shot cracks purple armor. These independent openings follow ordinary occupancy and reachability. Reservation does not open gates; only completed unloading credits ammunition.

Both authored Worker Lv.1 routes use 15 independent inputs at 1.40-second gaps. Green-first delivers at 3.20s; swapping the first two inputs gives purple-first delivery at 4.10s. Both finish on actual damage at 25.05s before the 60.00s threat, leaving six beads. Peak capacity is four; the longest all-color no-dispatch interval is 0.80s. No upgrades, tools, ads, combo, bonuses or new rules are required. Reward thresholds 27/40s remain provisional.

Preparation and play share the traveler texture, measured ground anchor and uniform physical scale recorded in `reports/assets/forest-traveler-assets.json`; the optional contact shadow is presentation only. Preparation’s five required-color values fit three columns/two rows, while live play retains five equal-width single-row dispatch buttons.

`reports/rules/forest-traveler-level08.json` records 834 passing bounded rule checks against the current integrated level data and unchanged rules, with exact hashes. `reports/ui/forest-traveler-scene.json` records 63 passing integrated scene checks against that same level version. Production single-level CLI validation also passes. These do not constitute a rerun of prior levels or a whole-project pass. The same-version `reports/ui/forest-traveler-runtime.json` records actual automated GL victory at 25.05 simulation seconds, six unused beads, and saved completion plus 150 points. Runtime diagnostics and evidence limits are in `PUBLIC_VERIFICATION.md`. Human difficulty/economy, visual, native-input, audio and target-device acceptance remain outstanding.
