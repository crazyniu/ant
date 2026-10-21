# Shared board-plane presentation

The simulation remains integer grid coordinates and microsecond events. Camera projection is presentation only; it never changes reachability, picking, reserved obstacles, transport deadlines, inventory, armor or victory ordering.

## Projection

The 940×1672 logical canvas is uniformly scaled by min(1440/940,2560/1672) into a portrait 1440×2560 viewport. The window fits/maximizes with aspect preserved. Independent UI controls receive Godot-transformed inputs, not manually corrected screen coordinates.

scripts/board_plane.gd defines one mild near-orthographic trapezoid:
- Top-left (175,350), top-right (765,350).
- Bottom-left (130,890), bottom-right (810,890).
- Each row interpolates the left/right edge; each column interpolates along that row.
- Cell center is project(x+0.5,y+0.5). Footprint is derived from neighboring projected grid corners.

Validation levels1/2 use16×16 grids with216/256 actual beads; level3 uses18×14 with172 actual beads. Empty cells create no bead node. The1022-bead gallery castle is a separate35×31 layout specimen, not playable balance. Grid scale follows dimensions, not a fixed design-image count. Changing a level does not stretch its logical topology or fabricate extra beads.

## Layered objects and anchors

- assets/environment.png is an empty background. It contains no gameplay bead, ant, cannon, nest, dragon, tower or clickable UI.
- Each live bead is an independent RescueBead Control, sharing a six-color generated material atlas but using its own visibility and projected footprint.
- Ground ant group origin represents the ground foot point. The ant sprite uses a fitted transparent region with a lower-edge anchor; a separate soft contact shadow stays at the same origin. Carried bead is another child, visible only after authoritative pickup.
- Ground ant depth scale ranges0.88–1.0. UI ant emblems use their own legibility sizing and are not world-scale carriers.
- Moving carriers use the same projected grid coordinates as beads. The logical origin outside the board maps to the nest entrance(467,1074). Projected path segments are sampled by cumulative screen-space arc length, avoiding sudden visual speed changes on the long nest-to-board segment. Transport sampling does not decide delivery or change rule time.
- Pickup FX receive a cell_points dictionary from the same BoardPlane rather than the former linear board-origin calculation. Cannon, stock and dragon anchors are explicitly supplied by the adapter.
- UI slots, front-team targets, rear-team labels, HUD and tool icons remain orthographic. Rear teams have no target nodes. UI control hits are not inferred from an illustration.

## Material slicing

The ant, bead and free audio-icon sheets use actual alpha>=4 connected silhouettes plus7source-pixel gutters, not equal-sized atlas cells. AtlasTexture.filter_clip prevents neighboring bleed. Runtime uses complete relative paths, no temporary generation path. Source provenance/dimensions/hashes are in ASSETS.md and docs/asset-manifest.json.

Approved direction and actual screenshots remain separate. Current fused GL captures are outside source at ../ant-rescue-evidence/fusion-ui/ and real first-level playback at ../ant-rescue-evidence/fusion-play/. A captured automatic replay does not assert human playtesting, final device performance or actual listening.
