# Shared scene layout contract

Godot 4.6.3; logical 940×1672 uniformly presented at 1440×2560. Scene layouts are local JSON consumed by both live play and preparation. They are not baked gameplay screenshots or rule replacements.

## Current scenes

- Woodland princess, levels 1–3: `data/scenes/woodland-princess.json`. Original right-side open serpent road and center-bottom entrance remain unchanged.
- Ruins supply cart, level 4: `data/scenes/ruins-cart.json`. A separately generated empty ruins courtyard, left-side open serpent road ending at a fixed upper-right cart, shifted nest/cannon and left-biased grid entrance.
- Ruins Supply Fork, level 6: `data/scenes/ruins-fork.json`. Existing ruins/cart art with shifted nest/cannon and a central transport approach.
- Ice Valley winter camp, levels 5 and 7: `data/scenes/ice-camp.json`. Independent snow ground, right-to-upper-left finite serpent road, fixed camp on a circular platform and a right-biased ant entrance. Snow does not alter transport physics. Level 7 changes the bead puzzle and serpent appearance, not this shared scene geometry.
- Woodland traveler, level 8: `data/scenes/forest-traveler.json`. Existing woodland ground, central nest/gateway and finite right/top enemy road, with an independent fixed traveler on the upper-left platform. The two-island puzzle and fifth color do not add an escort mechanic.

## Fields

- `background`: independent empty-ground texture.
- `board_plane`: optional projected corners, fitted width basis and depth ratio. The grid's integer dimensions/occupancy stay in the level config.
- `nest.position`, `nest.gateway`, `nest.width`: ground anchor, clear visual approach and uniform physical width. Its sprite's measured anchor remains in `assets/serpent/nest-entry.json`.
- `cannon.rect`, `pivot`, `muzzle`, `center`: independent art bounds, recoil pivot and FX origins.
- `stock.start`, `spacing`: light icon/count row, not an inventory capacity.
- `route`: finite ordered Curve2D knots with optional tangent handles. `serpent.goal_s` maps to the route endpoint, never modulo. Art-side body compression cannot move the authoritative head.
- `defense_target`: stable identity, fixed status, texture/optional atlas region, measured local ground anchor, physical width, displayed width and world foot. It must match the level's guardian identity. Win presentation reuses this guardian rather than hardcoding a princess. Optional `contact_shadow=[radius_x,radius_y]` draws a separate ground ellipse at the same foot; it does not alter collision, route or target state.
- `walkable_polygon`: inspected clear-ground envelope for bounded route verification, not the logical obstacle solver.

`transport.entrance_cell` belongs to the level's authoritative rules. It must be an integer cell on the one-cell exterior transit ring. If omitted, `[width/2,height]` preserves earlier timing and routes. Rules choose only a reachable matching unreserved target; pickup, not reservation, opens the cell. Renderer rounds only permitted transit corners and goes through the configured gateway. All four transport stages retain their authoritative event deadlines.

## Art placement and scaling

The ruins background is native 941×1672; the transparent supply-cart slice is native 1247×942. Its nonuniform alpha crop and wheel anchor are in `assets/worlds/manifest.json`. Do not split an atlas into equal cells or derive contact points merely from image center. The 2K viewport is not a claim that every raster has native 2K detail.

For TextureRect controls, set `EXPAND_IGNORE_SIZE` before assigning a native texture, then set layout bounds. This prevents a large cart or coin source from inflating its result slot. Keep backgrounds, artwork, icons, numbers and input rectangles separate.

## Level 4 acceptance boundary

The candidate is a 24-bead RGBY puzzle with an enclosed yellow core and 12 normal/armored body segments totaling 16 HP. The authored base-worker solution uses 16 independent inputs, no tools or rewards; it leaves eight beads. It tests a different opening and route, not only a new skin. The 66-second threat budget is a test configuration, not final difficulty approval.

Required bounded checks: valid/missing scene contract, visible guardian identity, original three timing invariance, one new timed solution, per-color supply, four-task limit, no hidden queued input, actual occupied-grid routes, clear-ground endpoints/separation, preparation count fit, real loading, natural final hit and correct guardian/result dimensions. Store captures outside the source tree. Human pacing, sound, visual approval and target-device input remain separate acceptance steps.

## Level 5 acceptance boundary

The 24-bead RGBY puzzle has a near red gate and farther green gate opening different yellow targets, unlike level 4's single enclosed-core layout. Each color has six supply beads and four initial HP; eight ordinary and four armored segments total 16 damage. Base Worker, no upgrades/tools/rewards, uses 16 actual independent clicks; the final hit at 26.90 seconds leaves two beads per color. Threat contact is at 66 seconds.

New rule checks are limited to level 5, both exact-event and 100ms frame-step replay, pickup-only gate opening, accounting, per-color damage, armor and transport capacity. Scene checks cover the real 16 routes, clear-ground polygon, separation from the outer road, correct preparation/guardian/result, and natural final hit/save. The rules file and existing level 4 data hashes must remain unchanged. No old 30-level pass is inherited.

The snow ground is native 940×1672 RGB. The transparent camp is 1373×981 after measured alpha >1 crop `[93,23,1466,1004]` from 1536×1024; contact anchor `[687,875]`, width 170 logical pixels. The manifest records source and anchor. Snow-ground detail is not claimed to be native 2K.

## Level 6 region variant

`data/scenes/ruins-fork.json` shares current ruins ground and parked-cart art, but uses a shifted center approach and `entrance_cell=[5,8]`. The enemy remains on the finite left/top road. No road, nest, actor or target is baked into a replacement screenshot. Eighteen beads supply twelve HP, with nonuniform blue5/red4/green3 demand and a mandatory enclosed-blue opening. This changes routing and staged supply rather than only recoloring the same 24/16 puzzle.

## Level 7 Ice Supply Ridge

`serpent-07` reuses the exact level-5 `ice-camp.json`, snow ground, fixed camp, finite road, board projection and `[6,8]` entrance. Existing levels 1–6 stay unchanged. Its 21 beads (R4/B6/G8/Y3) supply 17 HP (R3/B6/G5/Y3) across nine normal and four armored segments. Both enclosed blue cells and all three initially blocked yellow cells are necessary; four red/green surplus beads remain after victory.

Red pickup opens the central yellow bridge, then central-yellow pickup opens the blue core. Green pickup gives an alternative yellow-wing opening and shorter exterior-blue route. Pickup, not reservation, changes reachability. Both complete authored base-Worker routes use 17 inputs and reach the final hit at 27.85s before the 62s goal; there is no freezing, slipping, slowdown or extra-health rule.

Preparation and play select the same `serpent.art_profile="ice_crest"`: independent white-horned broad head, faceted body, eight head/tail yaws and the existing intact/cracked armor overlays. Use `assets/serpent/ice-serpent-atlas.json` for measured physical scales and chain anchors; do not rotate whole sprites or change route geometry to fit the appearance.

The 43 bounded scene checks cover the authored occupied-grid routes, clear-ground samples, road separation, derived preparation counts and selected appearance. They complement 668 rule assertions and 50 appearance checks. Automated GL victory is recorded separately in `reports/ui/ice-supply-runtime.json`; none of these establishes human visual acceptance. Native input, audio, target devices and difficulty/economy balance still require separate review.

## Level 8 Traveler’s Twin Groves

`data/scenes/forest-traveler.json` reuses the woodland background, empty default `board_plane` override, nest foot `[467,1008]`, gateway `[467,940]` and existing finite right/top road. The authored rule entrance is `[5,8]`. Enemy approach and the interior carrier lane remain separate; the traveler stays fixed, with no escort or new transport rule. Existing levels 1–7 and the authoritative rules are unchanged.

The 21-bead, five-color board consists of two offset islands of 11 and 10 beads separated by the empty x=5 approach. Supply R4/B4/G4/Y5/P4 funds damage R3/B3/G3/Y2/P4 across 11 normal and two armored segments. Green pickup opens the left purple core; blue pickup opens the right purple core. Exterior purple opens neither, but supplies the purple armor. Both purple cores are necessary; pickup, not reservation, changes access.

The green-first and purple-first Worker Lv.1 sequences each use 15 inputs, with first delivery at 3.20s and 4.10s respectively. Both win on final damage at 25.05s before the 60s threat and leave six beads. Neither requires upgrades, ads, tools, bonuses or new mechanisms. Preparation shows all five required-hit counts in three columns and two rows; live dispatch stays a single row of five equal-width buttons.

The independent `assets/worlds/forest-traveler.png` is a measured-alpha 936×1204 RGBA crop, not a complete scene image. Its local anchor `[498,1186]` maps to world foot `[155,182]`; physical width 928 scales uniformly to 88 logical pixels. Optional contact-shadow radii `[24,7]` share that foot. Use `reports/assets/forest-traveler-assets.json` and [asset placement](../ASSETS.md), not equal-cell crops or the transparent canvas center.

The current same-version 834-check rule report and 63-check integrated scene report pass with distinct scopes. Scene checks cover the shared target, five-color preparation/input layout and 3,015 carrier-ground samples, with minimum enemy-centerline separation about 112.34 logical pixels. Production single-level CLI validation passes. The separate `reports/ui/forest-traveler-runtime.json` records the same-version actual automated GL journey and final hit at 25.05s. These checks and the recording do not establish human visual, native-input, audio or device acceptance; see `PUBLIC_VERIFICATION.md` for the current verification boundary.


## Threefold Supply Steps, level 9

Level 9 reuses `data/scenes/ruins-fork.json` without modifying it: central rule entrance `[5,8]`, nest `[480,1010]`, gateway `[480,930]`, fixed cart foot `[808,192]`, and the finite outer left-to-upper-right road. The new three-lobed mosaic and initial body budget are level data, not baked into ground art. Red/yellow middle opening and blue/yellow right opening give different legal nearest-bead paths; no occupied bead cell becomes walkable before actual pickup.

`serpent.art_profile="ruins_carapace"` selects the new broad-shell silhouette, while body color tint, visible HP2 overlays, chain-joint yaw anchors and spacing retain the existing renderer contract. The four color entrances remain equal-width in one row. Preparation shows the real 13 ordinary/two armored counts and four color requirements, not artwork example values.

The bounded scene report `reports/ui/ruins-three-gate-scene.json` checks 3,417 sampled route points remain on inner clear ground and at least 129.79 logical pixels from the enemy centerline, plus the actual profile/guardian/input controls. Rendering and human acceptance remain separate from these checks. See `ASSETS.md` for alpha cutting and joint anchors and `PUBLIC_VERIFICATION.md` for the current real-GL boundary.
