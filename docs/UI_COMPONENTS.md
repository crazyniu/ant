# Current UI component contract

Version: single-ant API 3.1.0 and map/preparation/shop continuation, 2026-10-21. This replaces the earlier automatic-team UI contract. See `CURRENT_IMPLEMENTATION.md` for rules/economy authority and `PUBLIC_VERIFICATION.md` for bounded evidence.

## Canvas and hierarchy

The logical canvas is 940 × 1672, uniformly scaled into the 1440 × 2560 portrait viewport. Use Godot's transformed control coordinates for pointer input, not separately unscaled screen positions. A desktop capture does not establish acceptance on every window size or device.

Gameplay layers are environment/finite route/target → independent serpent and bead actors → carriers and inventory → color controls/capacity HUD → blocking overlays. Full-screen map, preparation and shop replace the page rather than masquerading as the old modal level picker. Decorative controls ignore input; active hit targets and blocking shades own it.

## Reusable skin and new artwork

`ui_skin.gd` loads measured `assets/ui/v03/regions.json` entries. Atlas crops use `filter_clip`; textures ignore minimum native size where appropriate. Nine-slice corners stay uniformly scaled rather than stretching full panel art. Titles are separate aspect-fitted sprites; do not stretch letters to fill an arbitrary rectangle.

`assets/meta-ui/manifest.json` owns the native source sizes and crop coordinates for ADVENTURE, READY, ANT SHOP, WORKER, SWIFT, TRAINING, the wing badge and coin. The workshop plate is 941 × 1672, not native 2K. Background, panels, ant previews, wing ornament, coin, text and buttons remain separate. All prices, points, carry levels, gains and ownership/equipment flags are actual service state.

## Gameplay input and presentation

- Each color has one live entry. One legal click creates one transport task for one bead. Numbers mean uncollected beads including reservations, not team quota.
- Capacity shows current transports out of four. Busy input is rejected without buffering. Collected, blocked and all-reserved color states remain distinct.
- Pickup removes one board bead; unloading grants one inventory bead. The UI cannot invent stock before delivery.
- HP1 normal and HP2 armored segments retain stable identity; the first armored hit shows cracked armor. Actual final damage is the victory source, not an animation completion signal.
- Remaining beads or inventory do not invalidate a victory. There are no 20/30 automatic teams, five working slots or old extra-slot tools in current play.
- The existing fixed rescue target is still princess art. Different future targets/themes are not implemented merely because a config field or label exists.

## Full-screen navigation

- Startup shows actual resource progress and Retry on resource failure. Home opens the real map or saved-level preparation.
- Map nodes reflect the three available level definitions and persistent completion/unlock status. The connected path is behind nodes, with correctly scaled panel art and independent hit rectangles.
- Preparation presents a scene preview, actual segment/HP/supply summary, target and owned type choices. Begin commits equipment/entrance and freezes the run loadout before play.
- Shop displays owned/equipped worker/Swift, actual points, price and shared next-level gain. Unaffordable purchase/training actions have neutral locked artwork and disabled hit targets. The Swift ornament is an independent fixed-corner badge, not a second ant layer. The view requests purchases/equipment changes; only the progression service commits them.
- Region, scroll and selected level are retained when returning. An interrupted/rebuilt page must not apply an old deferred scroll restoration to a newer page.
- Result displays only the persisted receipt. A save failure shows pending/retry rather than credited success; navigation cannot bypass unfinished victory persistence.

## Audio, unavailable actions and verification

Music and sound use separate icons/sliders; zero remains silent, including after relaunch. Background focus and pause follow the game lifecycle. Successful asset loading or a playing BGM flag on a Dummy audio driver is not speaker/headphone listening approval.

The rewarded-ad SDK is not integrated. Do not display a mock success or grant points for a simulated click/callback. Unavailable advertising is separate from normal progression, free retry and navigation.

Current headless flow verification drives production handlers, not native mouse/touch input. The final five-page GL capture includes the map/preparation/shop fixes and has been visually inspected. That bounded review remains distinct from user visual acceptance, native-input testing and a whole-game interaction pass. Recheck rapid repeated actions, page back/return, save failures, scroll restoration and input blocking on the final source revision.

## Intrinsic texture-size guard

Use `UiSkin.place_texture(source, bounds, parent, id, keep_aspect)` for standalone bitmap controls. It sets zero custom minimum and `EXPAND_IGNORE_SIZE` before assigning a texture, then applies bounds and attaches the node. `sprite`, adventure thumbnails, scene guardian/nest and result guardian/coins all use it. Do not assign large native textures first and then copy inline size-setting code: cached texture minimums can inflate the result panel. Keep aspect for portraits/coins; use explicit projection dimensions for ground objects. The affected-scene check inspects actual post-tree guardian and coin sizes plus all four preparation count bounds.

## Color dispatch row

Active colors share one equal-width, centered row. `Play.color_control_layout(count)` distributes the available width dynamically rather than wrapping at three; one to six colors keep the same 116-logical-pixel touch height. Icons and live remaining counts scale within each plate. Four-color play is not a 3+1 layout.

An unreachable color uses a desaturated ant and a small road barrier, never an ownership lock. Its tooltip and rejected tap say “No reachable bead”; the click does not queue a task, reserve a target or consume a bead. Ownership padlocks remain valid only on real level/type unlocks. Busy, reserved and collected states keep their distinct feedback.
