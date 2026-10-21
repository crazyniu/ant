# Shared scene layout contract

Godot 4.6.3; logical 940×1672 uniformly presented at 1440×2560. Scene layouts are local JSON consumed by both live play and preparation. They are not baked gameplay screenshots or rule replacements.

## Current scenes

- Woodland princess, levels 1–3: `data/scenes/woodland-princess.json`. Original right-side open serpent road and center-bottom entrance remain unchanged.
- Ruins supply cart, level 4: `data/scenes/ruins-cart.json`. A separately generated empty ruins courtyard, left-side open serpent road ending at a fixed upper-right cart, shifted nest/cannon and left-biased grid entrance.

## Fields

- `background`: independent empty-ground texture.
- `board_plane`: optional projected corners, fitted width basis and depth ratio. The grid's integer dimensions/occupancy stay in the level config.
- `nest.position`, `nest.gateway`, `nest.width`: ground anchor, clear visual approach and uniform physical width. Its sprite's measured anchor remains in `assets/serpent/nest-entry.json`.
- `cannon.rect`, `pivot`, `muzzle`, `center`: independent art bounds, recoil pivot and FX origins.
- `stock.start`, `spacing`: light icon/count row, not an inventory capacity.
- `route`: finite ordered Curve2D knots with optional tangent handles. `serpent.goal_s` maps to the route endpoint, never modulo. Art-side body compression cannot move the authoritative head.
- `defense_target`: stable identity, fixed status, texture/optional atlas region, measured local ground anchor, physical width, displayed width and world foot. It must match the level's guardian identity. Win presentation reuses this guardian rather than hardcoding a princess.
- `walkable_polygon`: inspected clear-ground envelope for bounded route verification, not the logical obstacle solver.

`transport.entrance_cell` belongs to the level's authoritative rules. It must be an integer cell on the one-cell exterior transit ring. If omitted, `[width/2,height]` preserves earlier timing and routes. Rules choose only a reachable matching unreserved target; pickup, not reservation, opens the cell. Renderer rounds only permitted transit corners and goes through the configured gateway. All four transport stages retain their authoritative event deadlines.

## Art placement and scaling

The ruins background is native 941×1672; the transparent supply-cart slice is native 1247×942. Its nonuniform alpha crop and wheel anchor are in `assets/worlds/manifest.json`. Do not split an atlas into equal cells or derive contact points merely from image center. The 2K viewport is not a claim that every raster has native 2K detail.

For TextureRect controls, set `EXPAND_IGNORE_SIZE` before assigning a native texture, then set layout bounds. This prevents a large cart or coin source from inflating its result slot. Keep backgrounds, artwork, icons, numbers and input rectangles separate.

## Level 4 acceptance boundary

The candidate is a 24-bead RGBY puzzle with an enclosed yellow core and 12 normal/armored body segments totaling 16 HP. The authored base-worker solution uses 16 independent inputs, no tools or rewards; it leaves eight beads. It tests a different opening and route, not only a new skin. The 66-second threat budget is a test configuration, not final difficulty approval.

Required bounded checks: valid/missing scene contract, visible guardian identity, original three timing invariance, one new timed solution, per-color supply, four-task limit, no hidden queued input, actual occupied-grid routes, clear-ground endpoints/separation, preparation count fit, real loading, natural final hit and correct guardian/result dimensions. Store captures outside the source tree. Human pacing, sound, visual approval and target-device input remain separate acceptance steps.
