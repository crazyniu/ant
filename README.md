# First-level review candidate (2026-10-22)

Only the user-approved first level is accessible in this candidate. Later level content remains archived for compatibility, not enabled or newly tested. Do not merge or deploy this review branch. Visuals are **not user accepted**. Native 1440×2560 GL has verified the a1ee1d8 complete-ant cards and five colors only; overall1:1 and the latest HUD-removal delta remain unaccepted.

See [current full-ant/card-color correction](reports/first-level/batch-3/README.md) and its exact unaccepted differences. The rejected c763ed1 bust is replaced by a complete ant candidate; native GPU five-color verification is recorded in batch3; overall visual acceptance remains open. Superseded images/raw snapshots are kept in history and local evidence, not accumulated in the current tree. [Batch 2](reports/first-level/batch-2/README.md) and `FIRST_LEVEL_PUBLICATION.json` describe the immutable initial `0491e05` publication, not the latest changed-file hashes. The current delta is in batch-3/summary.json. Earlier `SOURCE_MANIFEST.json` / `PUBLICATION_CHECK.json` and the implementation history below describe the already-published base, not current first-level acceptance.

Latest small delta: [remove the rejected cannon-side inventory HUD](reports/first-level/batch-4/README.md), preserving internal ammo rules and existing controls;87 first-ball headless checks passed. This is not completed loading animation.

---

# Ant Rescue: single-ant rescue and growth

A portrait Godot **4.6.3** game: click a color to send one ant for one bead, deliver it to fire one matching projectile, and destroy a segmented serpent before its head reaches the fixed goal. Runtime UI is English and icon-first. Normal play is offline and needs no account, backend, external plugin or secret.

Current source includes adventure/preparation/shop progression, independently authored ruins and Ice Valley levels, Traveler’s Twin Groves in the existing woodland scene, Threefold Supply Steps with the carapace serpent, the six-color Snow Courtyard, Traveler’s Branching Crossing, and Caravan’s Split Seal. Rules API remains **3.1.0**, with level schema **3**. There are **twelve current validation levels**, not a completed or accepted new 30-level campaign. Source integration is not merge, deployment or final acceptance.

## Run

Open `project.godot` in the official standard Godot 4.6.3 editor, allow the first resource import, then press **F5**.

```sh
# Rebuild the uncommitted import cache.
godot --headless --editor --path . --import
# Current production entry.
godot --path . --rendering-method gl_compatibility
```

`scenes/startup.tscn` is the entry: actual resource Loading → Home → full-screen adventure map or saved-level preparation → actual game-scene Loading → Play. Map nodes open full preparation; the map and result provide access to the independent shop. Loading uses threaded resource status, not a fabricated percentage or minimum wait, and failed loading exposes Retry.

The viewport is **1440 × 2560**, with a uniformly scaled **940 × 1672** logical canvas. Bitmap native sizes are listed in [ASSETS.md](ASSETS.md); a 2K-class viewport does not make a 941 × 1672 background native 2K.

**Do not use `--campaign-drafts` for this build.** Its reserved new-serpent catalog has no authored bundled campaign. Old automatic-team data, editor tools and reports may remain in this development tree, but cannot be used as current gameplay or new-mode acceptance. `scenes/main.tscn` is a legacy component gallery, not the playable entry.

## Current gameplay

- One legal color click reserves one reachable matching bead and creates one worker task. At most **four** workers are transporting, including pickup and unloading. Full capacity rejects the click without a hidden queue.
- The number on each color entry is the **uncollected bead count**, including reserved beads. Pickup removes the bead; completed unloading alone grants inventory and releases the worker.
- Each bead funds one matching projectile for one damage. Normal segments have **HP1**; armored segments have **HP2**, with a cracked state after the first hit. Stable segment IDs prevent retargeting errors.
- The serpent follows a **finite, non-looping route**. Removing a segment shortens the body without moving its head backward. The head has no extra hidden health bar.
- Actual damage removing the final live segment wins. Board clear, pickup, delivery or firing does not win; leftover beads and inventory are allowed. Earlier head contact loses. At exactly the same simulation microsecond, due damage resolves before contact.
- The base worker can solve all twelve current authored levels without upgrades, advertising, combos or mechanisms. No automatic 20/30-ant teams, five work slots, team quotas or board-equals-armor rule remain in current play.

## Map, preparation, points and shop

The full-screen map uses the real twelve-level catalog and saved completion/unlock states. Preparation shows the selected level's scene preview, segment/HP information, fixed target and owned ant types. Map region, scroll and selected level are persisted for return navigation. The fourth level adds a ruins ground and stationary supply-cart objective; level five adds a snow valley, fixed winter camp and independently authored two-gate opening; level six returns to ruins with a smaller three-color, blue-armor supply fork; level seven reuses the snow scene for a two-stage supply ridge and the independent ice-crest serpent appearance; level eight returns to woodland with a fixed traveler, two resource islands and purple as a fifth color. Level nine adds a four-color, three-step opening in ruins with an independent carapace serpent. Level ten reuses the Ice Valley ground and crest serpent for a connected courtyard puzzle, with white as the sixth independently dispatchable color. Level eleven adds a connected woodland crossing with a central-opening versus early-blue-supply choice. Level twelve returns to the left-biased ruins entrance with a sealed purple vault and separate offset supply terrace. Further themed regions and targets remain content work.

- First clear: **100 + 0–50** time-bonus points. Replay clear: **20 + 0–10**. Failed or abandoned runs earn no new points and do not deduct existing points.
- Reward time is effective simulation time from first legal dispatch to final damage, not recording length or wall-clock time. Each level supplies its own bonus thresholds.
- The worker starts owned at ×1.00. Swift costs **500 points** and moves at **×1.20**. Both still carry one bead and share the same four-worker limit.
- Shared carry levels 2/3/4 cost **100/150/250** points and apply **×1.05/×1.10/×1.15**. Type × current-level multiplier gives Swift Lv.4 **×1.38**; bonuses are not cumulatively multiplied across previous levels.
- Each run freezes its equipped loadout before play. The shop displays real points, prices, ownership, equipment and training state. Purchase debit and unlock/upgrade share one atomic commit; `run_id` settlement is idempotent across retries and restart.
- The ad SDK is **not integrated**. No fake advertisement, simulated success or button grants an extra reward. Optional ad-doubling remains a future integration, not an accepted feature.

These are configurable first-pass economy values, not validated human difficulty or economy balance.

## Saves, audio and source map

Default level/settings saves use `user://ant-rescue/serpent-click-v1/`; the integrated economy ledger is in its `ant-single-v1/` child. `ANT_RESCUE_PROFILE_DIR` overrides the root before those suffixes. Game-one and legacy automatic-team progress are not migrated. Relaunch restores an entrance as a fresh round, not a mid-round board. `--auto-replay` uses a separate temporary profile.

Music and effects have independent controls; saved zero remains silent. Human listening, native macOS and target-device performance are separate acceptance steps.

- `scripts/startup.gd`, `startup_loader.gd`: resource loading, Home and meta-screen navigation.
- `scripts/adventure_view.gd`, `ant_shop_view.gd`: full-screen map/preparation and shop views.
- `scripts/ant_progression.gd`, `data/ant-progression.json`: local rewards, purchases, equipment, frozen loadouts and navigation persistence.
- `scripts/play.gd`, `rescue_rules.gd`: live scene adapter and authoritative microsecond rules.
- `scripts/level_catalog.gd`, `save_service.gd`: current catalog identity, completion/settings saves.
- `scripts/serpent_view.gd`, `serpent_path.gd`, `directional_carrier.gd`, `carrier_route.gd`: independent serpent and transport presentation.
- `data/serpent-levels/`: the twelve current authored validation levels.

Start with [current implementation](docs/CURRENT_IMPLEMENTATION.md), [UI components](docs/UI_COMPONENTS.md), [asset placement](ASSETS.md) and [verification boundaries](docs/PUBLIC_VERIFICATION.md). Older documents with a historical-version notice are reference material, not current acceptance criteria.

## Verification and unfinished scope

Retained reports record **18** headless production-flow checks, **133** three-level same-input growth checks and **1,062** local progression-service assertions without reported failures. The growth report measures earlier delivery and final hits for Swift Lv.4 while keeping enemy speed unchanged. These reports have different scopes and are not one whole-project pass. See [PUBLIC_VERIFICATION.md](docs/PUBLIC_VERIFICATION.md) for exact sources and timings.

Earlier **1440 × 2560 GL captures** cover Home, adventure map, preparation, shop and settings using a fresh profile with zero points. The final capture includes the revised map path/node proportions, reduced preparation copy and disabled unaffordable shop actions; these pages were visually inspected. Do not label the meta UI user-approved or reuse the old core recording as evidence of these new screens. Headless signal-driven checks are not native mouse input or natural human play. The capture reports 14 loaded cues and BGM playing on a **Dummy** audio driver, not human sound-quality approval. No runtime script error was reported, but a one-resource-in-use diagnostic remains at shutdown.

Level 7 retains **668** bounded rule assertions, **50** appearance checks and **43** integrated scene checks. Its separate `reports/ui/ice-supply-runtime.json` records an automated GL victory, not human visual or difficulty approval. The current level-8 data passes **834** bounded rule checks in `reports/rules/forest-traveler-level08.json`, production single-level CLI validation and **63** integrated scene checks. These are separate scopes, not a rerun of the earlier levels or a full campaign pass. Its separate same-version `reports/ui/forest-traveler-runtime.json` records automated GL victory at 25.05 simulation seconds and a saved 150-point receipt; see [verification boundaries](docs/PUBLIC_VERIFICATION.md) for diagnostics and acceptance limits.

Still pending: the remaining new 30-level content and a fuller authoring workflow beyond the explicit single-level CLI; further themed scenes and fixed defense targets; optional junction combos and hidden supplies; real ad SDK; human difficulty/economy testing, final visual approval, hardware audio and device acceptance. No automatic merge or deployment is implied.

## Rights

No project-wide open-source license has been selected. Public hosting alone is not a license grant. DejaVu retains [its bundled license](licenses/DejaVu.txt). Generated-image and original synthesized-audio provenance is recorded in [ASSETS.md](ASSETS.md) and the source manifests; it is not a legal-clearance warranty. No competitor artwork or borrowed recording is bundled. A shop design reference is not evidence of user approval.

## Ruins continuation

Current catalog also includes `serpent-04`: an independently generated ruins courtyard, fixed supply cart, left-side finite serpent road, asymmetric ant entrance and four-color enclosed-core puzzle. Scene geometry is shared by preparation and live play. Use the adventure map after completing level 3; `--auto-replay --level=4` is an isolated automated review, not an unlock bypass for normal profiles. See `docs/SCENE_LAYOUTS.md` for the minimal content contract and `tests/test_ruins_rules.gd` / `tests/test_ruins_scene.gd` for bounded checks.

## Ice Valley continuation

`serpent-05` adds an independently generated snow valley and transparent fixed winter camp. The finite serpent road approaches from the right and ends at the upper-left camp; ants use a separate inner snowfield and right-biased entrance. Six beads per RGBY color fund four HP per color; sixteen independent base-worker inputs win at 26.90 simulation seconds and leave eight beads. A nearby red gate opens two yellow targets; a farther green gate opens one, giving different opening choices. Snow is visual only: no slipping, freezing or new damage rules. Level 4 and the authoritative rules remain unchanged. See `docs/SCENE_LAYOUTS.md` and the bounded `test_ice_rules.gd` / `test_ice_scene.gd` checks.

## Author one level

`tools/validate_serpent_level.gd` checks one explicit current-schema JSON and its exact authored Worker Lv.1 solution, using production rules without touching player saves. It exports per-color supply/HP, real event timing, transport paths and optional step trace. See [tools/README.md](tools/README.md). This small CLI entry is not a completed visual editor or thirty-level authoring pipeline.

## Ruins Supply Fork

`serpent-06` reuses the current ruins region's ground/cart resources, with a new central transport approach and a distinct 18-bead fork layout. Ten segments need 12 damage: blue 5 (two HP2 armored segments), red 4 and green 3. The four exterior blue beads are insufficient by themselves: at least one enclosed core bead must be opened and carried. Red opens the nearer core entrance, green the farther one, while exterior blue starts cracking armor without opening either. The authored twelve-click Worker Lv.1 solution wins at 20.85 simulation seconds, leaving six beads. This is a new level configuration, not a newly illustrated region, new enemy species, or human difficulty approval.

## Ice Supply Ridge

`serpent-07`, “Break the Supply Ridge,” reuses the level-5 snow ground, winter camp, finite road and entrance `[6,8]`. Its 21 beads (R4/B6/G8/Y3) fund 17 damage (R3/B6/G5/Y3) across nine normal and four armored segments. Actual red pickup opens a yellow bridge; that yellow pickup exposes two inner blue cells. A green-first route opens a separate yellow wing. These are occupancy-based choices, not scripted gates or new ice rules.

The authored 17-input Worker Lv.1 solution finishes on actual damage at 27.85 simulation seconds before the 62-second threat, leaving four beads. `serpent.art_profile="ice_crest"` selects a separate white-horned broad head, faceted body and eight-yaw head/tail atlas without changing HP, armor or timing. Existing levels 1–6 retain their data and default appearance. See [scene layout](docs/SCENE_LAYOUTS.md) and [art usage](ASSETS.md); human balance, final visual and target-device acceptance remain pending.

## Traveler’s Twin Groves

`serpent-08` uses `data/scenes/forest-traveler.json`: the existing woodland ground and finite right/top road, a separate stationary traveler sprite, center-bottom entrance `[5,8]` and default serpent appearance. Two independently authored, offset resource islands introduce purple alongside red, blue, green and yellow. Actual green pickup opens the left purple core; blue pickup opens the right. The traveler does not move and there is no escort or new combat mechanic. Levels 1–7 and the authoritative rules remain unchanged.

Its 21 beads fund 15 HP across 11 normal and two armored segments, one purple and one blue. Both green-first and purple-first Worker Lv.1 solutions use 15 inputs without upgrades, tools, ads or bonuses. First delivery is 3.20s or 4.10s respectively; both win on final damage at 25.05s before the 60s threat, leaving six beads. Preparation fits five required-color counts in three columns and two rows; live dispatch remains five equal-width buttons in one row. See [scene layout](docs/SCENE_LAYOUTS.md) and [traveler asset placement](ASSETS.md). Human pacing, visual, audio and target-device acceptance remain outstanding.


## Level 9: Threefold Supply Steps

`serpent-09` reuses the central-entrance ruins ground and fixed parked supply cart from `data/scenes/ruins-fork.json`, but independently authors a three-lobed, stepped resource pattern. The carapace serpent uses distinct blunt-horn and broad-shell artwork through `serpent.art_profile="ruins_carapace"`; ordinary HP1 and visibly armored HP2 semantics stay unchanged. There is no new attack, escort or resource rule.

23 beads fund 17 damage (13 ordinary and two armored segments). Both authored base Worker Lv.1 solutions use 17 inputs at 1.4-second intervals and finish on final damage at 28.75 simulation seconds before the 62-second threat, leaving six beads. Red→yellow opens the required blue core at 3.00s; blue→yellow takes a different right-hand yellow first and opens the same blue core via an upper branch at 7.20s. Actual nearest-reachable targets differ; this is not a manual cell-selection claim. Sixteen routes are 3–5 cells and one is six cells, with longest no-dispatch interval 0.80s in these solutions. Human strategy, pacing and difficulty remain to be tested.

Current bounded evidence is 1,466 level-rule assertions, 50 appearance checks, 60 integrated scene checks and production single-level CLI validation. These scopes are separate, not a whole-campaign rerun. Actual runtime evidence and diagnostics are recorded in [verification boundaries](docs/PUBLIC_VERIFICATION.md).


## Level 11: Traveler’s Branching Crossing

`serpent-11` reuses the woodland scene, fixed traveler, center-bottom entrance and default serpent appearance. Its connected crossing and two lower approaches are distinct from the earlier disconnected Twin Groves. Four-color supplies R4/B4/G8/Y6 total 22 beads; each color needs four damage across 12 normal and two armored segments. Blue and red have no surplus, so the enclosed blue cells must become reachable.

Red-first opens three central yellow branches; blue-first opens a lower blue supply pocket and cracks blue armor 4.20 seconds earlier. A later yellow pickup shortens the right blue route from eleven to five cells using normal occupancy-based pathfinding, not a scripted shortcut. Both authored Worker Lv.1 solutions use sixteen independent inputs, finish on actual damage at 26.60s before the 62s threat, and leave six beads. Fifteen chosen routes are 3–5 cells and one is six cells. These are bounded scripted solvability results, not human pacing or strategy approval.

Level-specific evidence is in `reports/rules/forest-crossing-level11.json`, `reports/ui/woodgate-scene.json`, `reports/authoring/woodgate-check.json` and the actual-GL report named in [verification boundaries](docs/PUBLIC_VERIFICATION.md). Rules and previous levels are unchanged; no new assets or mechanics are introduced.


## Level 12: Caravan’s Split Seal

`serpent-12` reuses `ruins-cart.json`, the parked supply cart and carapace serpent. Its left-biased `[3,8]` entrance serves two independently authored formations: a sealed purple vault and an offset supply terrace. Five colors supply 23 beads for 17 HP (13 normal plus two armored segments). All four purple beads start blocked and all are required.

Blue-first and red-first select different first purple beads. A yellow pickup shortens real upper red/green routes from 17/16 cells to 5/4, while the right blue opening supports another supply route. Two explicit seventeen-click Worker Lv.1 sequences at 1.6-second gaps both reach final damage at 31.05s before the 64s threat, leaving six beads. The solutions differ in first supply, first armor hit and armor removal order; equal completion times do not imply human balance approval.

Current bounded checks are 47 rules assertions, 64 integrated scene checks and the production single-level CLI. The real GL review captures map entry, preparation, loading, transport, firing and saved-result key states with event/source hashes, not a continuous movie or human playtest. Rules, earlier levels and existing assets remain unchanged. See [verification boundaries](docs/PUBLIC_VERIFICATION.md).


## Level 13: Ice Supply Channels

This bounded five-color winter-camp level reuses the snowpass scene and ice-crown appearance. Twenty-five beads supply 17 damage (13 ordinary and two armored segments). The central yellow-to-blue opening and outer red-to-inner-red route expose different required white beads through actual pickup-based pathfinding. Two explicit Worker Lv.1 solutions use 17 independent inputs and finish on actual last damage at 31.95 simulated seconds, leaving eight beads. Reward thresholds 33/47 seconds remain provisional, not human balance approval.

The retained current-level reports contain 78 rule checks, 89 scene checks with 3,417 route samples and 75 logical-pixel minimum enemy-centerline separation, plus the single-level CLI. Actual GL map/preparation/loading/play/result key states and 26 matching production hashes establish a saved 100+50=150 reward, no conservation error and at most four carriers. This is automatic authored input, not natural human play, a continuous movie, or a fresh audio recording.

The GL log includes unsupported VSync and ALSA output failure followed by Dummy fallback; no script exception is recorded. Human sound, difficulty and target-device acceptance remain unverified. Earlier content/rules and art bytes are unchanged; old suites were not rerun. No merge or deployment.
