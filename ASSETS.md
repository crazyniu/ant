# Current assets and placement contract

Scope: current single-ant serpent gameplay plus adventure/preparation/shop UI, 2026-10-21. Paths below are project-relative. Production resources use local `res://` paths, not generation-workspace paths or private download URLs. Native dimensions below were read from the actual PNG files; display size and viewport resolution are separate facts.

## Source records and rights

- `assets/meta-ui/manifest.json` is the source record for the new meta UI: exact source filenames, SHA-256, native sizes, source regions, centered anchors and measured alpha evidence. `generation-prompts.json` retains generation provenance; `validation-report.json` describes asset-level checks.
- `assets/serpent/serpent-atlas.json`, `nest-entry.json` and `reports/assets/serpent-actor-assets*.json` describe serpent/head/tail/armor/nest source regions, anchors, dimensions and provenance.
- `assets/motion/ant-directions.json`, `data/ant-regions.json`, `assets/ui/fusion/*-regions.json`, and `assets/ui/v03/*regions.json` define current per-resource regions.
- `docs/asset-manifest.json` is an older shared-art inventory. Its old board projection, total file count and automatic-team placement descriptions are **not** the current whole-build contract. Use the resource-specific manifests above and current renderer code for new serpent/meta assets. A package `SOURCE_MANIFEST.json` only establishes the exact snapshot for which it was generated; it must be refreshed for a new publication.

The PNG artwork was generated using the built-in image-generation service for this project. The shop design preview is a **reference only; user approval is not implied**. Generated provenance does not grant a new project license or constitute a legal-clearance warranty. No competitor image or complete concept screenshot is used as a runtime UI overlay. No project-wide open-source license has been selected. The bundled DejaVu font retains `licenses/DejaVu.txt`; public repository access alone is not a separate license grant.

## Current serpent, transport and shared UI images

| Project path | Actual native pixels | Mode | Current role / placement source |
|---|---:|---|---|
| `assets/serpent/environment.png` | 941 × 1672 | RGB | Current warm arena background for Home, map, preparation preview and play. Scene actors are independent. |
| `assets/serpent/serpent-atlas.png` | 1303 × 1774 | RGBA | Eight yaw heads, one body bead, eight yaw tails; `serpent-atlas.json` owns regions and chain-joint anchors. |
| `assets/serpent/serpent-armor-atlas.png` | 1536 × 748 | RGBA | Separate intact/cracked armor layers; per-entry paths and anchors in the serpent manifest. |
| `assets/serpent/nest-entry.png` | 905 × 529 | RGBA | Low ground entrance, not a raised doorway; `nest-entry.json` owns the foot anchor. |
| `assets/motion/ant-directions.png` | 1774 × 887 | RGBA | Eight-yaw worker identity used by directional carriers and current ant previews; sibling JSON owns physical scale and anchors. |
| `assets/ants-atlas.png` | 1536 × 1024 | RGBA | Shared static ant identity/portrait atlas; `data/ant-regions.json`. Its presence does not imply automatic teams. |
| `assets/characters-atlas.png` | 1536 × 1024 | RGBA | Shared cannon and existing princess/tower art. Old single-dragon/shield slices remain in the atlas but are not the current segmented enemy. |
| `assets/ui/fusion/beads.png` | 1536 × 1024 | RGBA | Independent board, carried and inventory bead materials; `bead-regions.json`. |
| `assets/ui/fusion/audio-icons.png` | 1774 × 887 | RGBA | Independent music and speaker emblems; `audio-regions.json`. |
| `assets/ui/v03/game-skin-atlas.png` | 1254 × 1254 | RGBA | Shared nine-slice panels and icons; `regions.json`. Old tool art is not evidence that old tools are playable. |
| `assets/ui/v03/settings-skin-atlas.png` | 1254 × 1254 | RGBA | Panel, plaque and separate track/fill/knob pieces; `regions.json`. |
| `assets/ui/v03/title-atlas.png` | 1254 × 1254 | RGBA | Existing sculpted English titles, independently measured crops; `title-regions.json`. |
| `assets/startup/title.png` | 1774 × 887 | RGBA | ANT RESCUE brand element; one aspect-fitted image, not a screen or nine-slice. |

`assets/environment.png` is the older **940 × 1672 RGB** ground plate retained for legacy/gallery references. Do not confuse it with the current `assets/serpent/environment.png`. The old gallery and its whole-dragon effects are not the current gameplay composition or acceptance target.

## New meta UI inventory

All following paths are under `assets/meta-ui/`. The three generated sources and eight independent crops are retained as production source assets, not historical alternatives.

| File | Actual native pixels | Mode | Layer / role |
|---|---:|---|---|
| `shop-workshop-background.png` | 941 × 1672 | RGB | Opaque workshop plate behind independently composed product/training UI. No numbers, prices, cards, buttons or characters are baked into it. |
| `titles-atlas.png` | 1024 × 1536 | RGBA | Source atlas for exactly ADVENTURE, READY, ANT SHOP, WORKER, SWIFT and TRAINING. |
| `adventure.png` | 964 × 221 | RGBA | Separate adventure page title. |
| `ready.png` | 607 × 208 | RGBA | Separate preparation page title. |
| `ant-shop.png` | 908 × 227 | RGBA | Separate shop title. |
| `worker.png` | 774 × 214 | RGBA | Separate worker name art. |
| `swift.png` | 544 × 198 | RGBA | Separate Swift name art. |
| `training.png` | 845 × 209 | RGBA | Separate shared-training title. |
| `icons-atlas.png` | 2172 × 724 | RGBA | Source atlas for the wing ornament and coin. Its width exceeds 2048; do not describe the entire asset pack as ≤2048 per axis. |
| `swift-wing.png` | 607 × 610 | RGBA | Separate gold wing/speed badge, no ant baked in. It does not imply flight gameplay. |
| `ant-coin.png` | 582 × 584 | RGBA | Independent ant-emblem coin, no amount baked in. |

Meta crops are measured from alpha > 4 content with an 8-native-pixel margin, not equal rows/columns. The original source RGBA is retained unchanged in each crop; low-alpha generator noise is not used to define the visible bounds. The manifest records source `[x,y,width,height]` and default centered anchors. Crop borders have recorded maximum alpha 0 or 1. Transparent RGB is not a visible background.

The background is **not native 2K** and no upscale is claimed. A 1440 × 2560 viewport may scale a 941 × 1672 plate; it cannot add generated detail. Titles and icons preserve aspect ratio and should ordinarily be displayed at or below native resolution.

## Composition and interaction layers

Keep scene/background, paths, targets, ant/serpent actors, panels, ornaments, title sprites, dynamic text and input hit targets independent. Do not slice a complete concept screen into a fake fullscreen UI.

- Adventure: current arena background, independently drawn route/nodes, live completion/unlock state, live points and separate page title. Node panels must not stretch their corner treatment, and the route must remain visible behind nodes.
- Preparation: a level-derived preview and real HP/supply/target information, separate type cards/previews, current ownership/selection and a real start action. It is a full page, not a decorative modal substitute.
- Shop: workshop background → nine-slice panels → existing ant actor → separate Swift wing badge → title sprites → live balances/prices/levels/effects → button hit targets. The coin has no baked price. Product card layout is not user approval of the concept.
- Result: the actual persisted receipt owns base points, time bonus and credited total. A coin/title image never owns economic state.
- Settings: music/sound emblems, slider track, fill and knob are distinct. Numeric/function state stays in real controls. Decorative artwork must ignore mouse input.

Preserve `AtlasTexture.filter_clip`, measured per-resource bounds, alpha-border handling and aspect-fitted word art. Nine-slice panels use uniform corner scale; never stretch lettering or a complete panel bitmap to simulate a new layout. Do not infer source crops from equal atlas cells.

## Ground and actor anchors

`board_plane.gd` is the current presentation source. It uses a 505-pixel top edge inside the 530-pixel bottom edge, bottom y=850, and a grid-dependent fitted height to keep the current sparse 10 × 8 boards near-square. See `docs/BOARD_PLANE.md`. Earlier (175,350) / (130,890) coordinates are superseded. Rules remain integer cells; presentation cannot alter reachability or delivery time.

The nest manifest places the center of the open hole at foot anchor `(454,264)` in its 905 × 529 image. The current recommended world foot is `(467,1008)` and physical width is 869 source pixels. Scale uniformly from that physical width and draw behind ants. Do not align by the image's lower border or use the old `(467,1074)` endpoint.

Directional ant views use measured foot/limb anchors and common physical scale, rather than rotating an entire card or normalizing every view to equal projected width. The shader recolors body material while retaining dark bands and eyes. Carried beads are separate nodes. Runtime routes, heading changes, pickup and unloading presentation follow the authoritative task's fixed timing.

Serpent head/tail views use chain-joint anchors and yaw selection, not whole-card rotation. Body beads remain independently positioned along the finite route. Intact/cracked armor is an overlay, not a recolored body or another damage event. Rendering a gap close cannot move authoritative head progress. See `reports/assets/serpent-actor-assets.md` for the bounded crop/anchor audit.

## Font, sound and procedural components

- `assets/fonts/Title.ttf`: DejaVu Sans Condensed Bold; bundled license `licenses/DejaVu.txt`. Balances, prices, levels, HP and remaining counts are real text, never image placeholders.
- `assets/audio/`: original locally synthesized 40-second Ogg Vorbis BGM and 14 PCM WAV cues. Source generation, hashes and encoding details are in its README, manifest and generator. No borrowed samples or recordings are bundled. Retained old tool cues do not prove those tools are available.
- Small control glyphs, map paths, contact shadows and bounded local effects are original Godot drawing/shader components. They are separate from generated image provenance.

## Validation and publication boundaries

Asset-level reports establish only their recorded files, measured dimensions/regions and source relationships. The old eight-PNG fusion audit and `docs/asset-manifest.json` are not a current total-file inventory. Current meta-asset checks are not a final assembled GL, native input, human listening or device-performance pass.

The final production GL capture contains five 1440 × 2560 pages after the map/preparation/shop fixes. Developer inspection confirmed visible map paths, correctly proportioned nodes, reduced preparation copy, disabled unaffordable shop buttons and an independent fixed-corner Swift badge. No user visual approval is claimed. Source, test, asset, rendered-scene and human-acceptance evidence remain separate; see `docs/PUBLIC_VERIFICATION.md`.

Publish source/resources, runtime manifests, font license and appropriately scoped tests/reports. Exclude generated import caches, temporary profiles, captures/videos, archived concepts and generation workspaces. Refresh package inventory after code/assets change. Old campaign files that remain in a development tree must not be described as the new single-ant campaign.
