# Current shared board-plane presentation

Version: single-ant serpent continuation, 2026-10-21. This replaces the automatic-team board coordinates and large-board counts in the previous version. Integer logical cells and microsecond events remain authoritative; projection cannot change reachability, reservations, transport deadlines, inventory or terminal ordering.

## Projection source

`scripts/board_plane.gd` defines the current near-orthographic envelope:

- Top x endpoints: 215 and 720; bottom endpoints: (205,850) and (735,850).
- Maximum height: 850 − 365 = 485 logical pixels.
- Actual fitted height: min(485, 515 / columns × rows × 0.93), so sparse boards do not stretch vertically.
- The actual upper y coordinate is 850 − fitted height. For the current 10 × 8 boards, fitted height is 383.16 and upper y is 466.84.
- Each row interpolates the left/right edges; each column interpolates across that row. Cell center is `project(x+0.5,y+0.5)`. Footprint derives from neighboring projected cell corners.

The logical 940 × 1672 canvas is uniformly scaled into the 1440 × 2560 viewport. Rules retain their own grid topology; render scaling must not create extra cells or change paths.

## Current content and independent layers

The current three authored boards are 10 × 8, containing 18, 20 and 22 beads. Empty cells have no bead node. Their base-worker solutions leave 6, 4 and 6 beads respectively. The previous 216/256/172-bead boards and gallery mosaic are not current gameplay counts.

Board beads, carriers, carried beads, nest, cannon, serpent/armor and shadows are independent nodes/layers. Physical materials come from the current atlases; there is no baked board screenshot. A reservation keeps the bead and obstacle present until pickup. Only a rule pickup removes the bead, and only completed unloading adds inventory.

## Contact and route anchors

The ant group origin is its ground-contact point. Directional views use `assets/motion/ant-directions.json` for measured foot/limb anchors and a shared physical scale; do not center the sprite solely by its image bounds. Carried beads stay separate from body art.

The low nest entrance uses `assets/serpent/nest-entry.json`: foot anchor (454,264), source 905 × 529, physical width 869, recommended world foot (467,1008). Place the hole center at the route endpoint with uniform scaling, behind the ant. The old (467,1074) endpoint is superseded.

`carrier_route.gd` and the current scene adapt logical transport paths for ground presentation; the rules own occupied-grid reachability and exact task durations. Do not move a transport through an occupied bead or treat a visual shortcut as a valid rule route. Serpent presentation follows its own finite route and chain-joint anchors, separately from transport corridors.

## Evidence limit

The current growth report validates three authored solutions and resource conservation; retained route/crop reports cover their recorded sources. Neither a projection calculation nor a screenshot proves every possible route, human difficulty or target-device pointer mapping. See `PUBLIC_VERIFICATION.md` and `ASSETS.md` for the relevant boundaries.
