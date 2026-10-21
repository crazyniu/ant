# Ant Rescue: single-ant rescue and growth

A portrait Godot **4.6.3** game: click a color to send one ant for one bead, deliver it to fire one matching projectile, and destroy a segmented serpent before its head reaches the fixed goal. Runtime UI is English and icon-first. Normal play is offline and needs no account, backend, external plugin or secret.

This development continuation adds the adventure map, preparation screen and local points/shop progression to the published single-click core at [`125646450cd1bf5e90d6d7cbc833ca34ff47bd75`](https://github.com/crazyniu/ant/commit/125646450cd1bf5e90d6d7cbc833ca34ff47bd75). Rules API is now **3.1.0**, with level schema **3**. There are **three current validation levels**, not a playable or accepted new 30-level campaign. The [draft PR](https://github.com/crazyniu/ant/pull/1) is not a merge, deployment or final acceptance.

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
- The base worker can solve all three current authored levels without upgrades, advertising, combos or mechanisms. No automatic 20/30-ant teams, five work slots, team quotas or board-equals-armor rule remain in current play.

## Map, preparation, points and shop

The full-screen map uses the real three-level catalog and saved completion/unlock states. Preparation shows the selected level's scene preview, segment/HP information, fixed target and owned ant types. Map region, scroll and selected level are persisted for return navigation. Additional themed regions and varied target art are not yet delivered.

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
- `data/serpent-levels/`: only the three current authored validation levels.

Start with [current implementation](docs/CURRENT_IMPLEMENTATION.md), [UI components](docs/UI_COMPONENTS.md), [asset placement](ASSETS.md) and [verification boundaries](docs/PUBLIC_VERIFICATION.md). Older documents with a historical-version notice are reference material, not current acceptance criteria.

## Verification and unfinished scope

Retained reports record **18** headless production-flow checks, **133** three-level same-input growth checks and **1,062** local progression-service assertions without reported failures. The growth report measures earlier delivery and final hits for Swift Lv.4 while keeping enemy speed unchanged. These reports have different scopes and are not one whole-project pass. See [PUBLIC_VERIFICATION.md](docs/PUBLIC_VERIFICATION.md) for exact sources and timings.

Actual **1440 × 2560 GL captures** now cover Home, adventure map, preparation, shop and settings using a fresh profile with zero points. The final capture includes the revised map path/node proportions, reduced preparation copy and disabled unaffordable shop actions; these pages were visually inspected. Do not label the meta UI user-approved or reuse the old core recording as evidence of these new screens. Headless signal-driven checks are not native mouse input or natural human play. The capture reports 14 loaded cues and BGM playing on a **Dummy** audio driver, not human sound-quality approval. No runtime script error was reported, but a one-resource-in-use diagnostic remains at shutdown.

Still pending: the new 30-level content and its authoring/validation chain; distinct themed scenes and fixed defense targets; optional junction combos and hidden supplies; real ad SDK; human difficulty/economy testing, final visual approval, hardware audio and device acceptance. No automatic merge or deployment is implied.

## Rights

No project-wide open-source license has been selected. Public hosting alone is not a license grant. DejaVu retains [its bundled license](licenses/DejaVu.txt). Generated-image and original synthesized-audio provenance is recorded in [ASSETS.md](ASSETS.md) and the source manifests; it is not a legal-clearance warranty. No competitor artwork or borrowed recording is bundled. A shop design reference is not evidence of user approval.
