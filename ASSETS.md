# Current assets and placement contract

Scope: current single-ant serpent gameplay plus adventure/preparation/shop UI, 2026-10-21. Paths below are project-relative. Production resources use local `res://` paths, not generation-workspace paths or private download URLs. Native dimensions below were read from the actual PNG files; display size and viewport resolution are separate facts.

## Source records and rights

- `assets/meta-ui/manifest.json` is the source record for the new meta UI: exact source filenames, SHA-256, native sizes, source regions, centered anchors and measured alpha evidence. `generation-prompts.json` retains generation provenance; `validation-report.json` describes asset-level checks.
- `assets/serpent/serpent-atlas.json`, `nest-entry.json` and `reports/assets/serpent-actor-assets*.json` describe the default serpent/head/tail/armor/nest source regions, anchors, dimensions and provenance.
- `assets/serpent/ice-serpent-atlas.json` and `reports/assets/ice-serpent-assets.json` record the independent `ice_crest` appearance, source/packed hashes, measured alpha regions, physical widths and chain-joint anchors.
- `assets/motion/ant-directions.json`, `data/ant-regions.json`, `assets/ui/fusion/*-regions.json`, and `assets/ui/v03/*regions.json` define current per-resource regions.
- `docs/asset-manifest.json` is an older shared-art inventory. Its old board projection, total file count and automatic-team placement descriptions are **not** the current whole-build contract. Use the resource-specific manifests above and current renderer code for new serpent/meta assets. A package `SOURCE_MANIFEST.json` only establishes the exact snapshot for which it was generated; it must be refreshed for a new publication.

The PNG artwork was generated using the built-in image-generation service for this project. The shop design preview is a **reference only; user approval is not implied**. Generated provenance does not grant a new project license or constitute a legal-clearance warranty. No competitor image or complete concept screenshot is used as a runtime UI overlay. No project-wide open-source license has been selected. The bundled DejaVu font retains `licenses/DejaVu.txt`; public repository access alone is not a separate license grant.

## Current serpent, transport and shared UI images

| Project path | Actual native pixels | Mode | Current role / placement source |
|---|---:|---|---|
| `assets/serpent/environment.png` | 941 × 1672 | RGB | Current warm arena background for Home, map, preparation preview and play. Scene actors are independent. |
| `assets/serpent/serpent-atlas.png` | 1303 × 1774 | RGBA | Eight yaw heads, one body bead, eight yaw tails; `serpent-atlas.json` owns regions and chain-joint anchors. |
| `assets/serpent/ice-serpent-source.png` | 1122 × 1402 | RGBA | Preserved generated source for the ice-crest head, body and tail; provenance in `reports/assets/ice-serpent-assets.json`. |
| `assets/serpent/ice-serpent-atlas.png` | 1280 × 1600 | RGBA | Packed eight-yaw heads, faceted body and eight-yaw tails for level 7; `ice-serpent-atlas.json` owns regions, physical scale and chain anchors. |
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

The earlier meta-UI GL capture contains five 1440 × 2560 pages after the map/preparation/shop fixes. Developer inspection confirmed visible map paths, correctly proportioned nodes, reduced preparation copy, disabled unaffordable shop buttons and an independent fixed-corner Swift badge. No user visual approval is claimed, and these captures do not validate the new ice-crest appearance. Source, test, asset, rendered-scene and human-acceptance evidence remain separate; see `docs/PUBLIC_VERIFICATION.md`.

Publish source/resources, runtime manifests, font license and appropriately scoped tests/reports. Exclude generated import caches, temporary profiles, captures/videos, archived concepts and generation workspaces. Refresh package inventory after code/assets change. Old campaign files that remain in a development tree must not be described as the new single-ant campaign.

## Ruins ground and fixed supply cart

`assets/worlds/ruins-courtyard.png` is the original generated empty ground layer, native 941×1672. `assets/worlds/supply-cart.png` is a separate transparent cart crop, native 1247×942, derived from a 1433×1098 generated source. Crop bounds use alpha >1 to exclude isolated 1/255 noise; retained pixels preserve generated alpha. Width 168 logical pixels and measured wheel/contact anchor are configured in `data/scenes/ruins-cart.json` and `assets/worlds/manifest.json`. No character, bead or cannon is baked into the ground. Native bitmap detail is not claimed to be 2K merely because the viewport is 1440×2560.

Generated using the built-in image tool: background prompt used the existing woodland asset only for style and a new spatial guide for a left-to-top open route, clear courtyard and bottom gateway; cart prompt requested one independent stationary wooden supply cart, upper-left light, same gentle overhead view, true alpha and no text/people/scene. No borrowed competitor artwork. These provenance records do not constitute a legal-clearance warranty.

## Ice Valley ground and fixed winter camp

`assets/worlds/ice-valley.png` is a native 940×1672 RGB empty snow-ground layer. Its finite cobblestone route runs on the right toward an upper-left camp platform; the nest gateway, cannon, bead grid, ants and serpent remain independently composed nodes. `assets/worlds/winter-camp.png` is a 1373×981 RGBA crop from a 1536×1024 generated source, measured alpha >1 bounds `[93,23,1466,1004]`. Retained alpha is unchanged. The contact anchor `[687,875]`, physical width 1373 and displayed width 170 are recorded in `assets/worlds/manifest.json` and `data/scenes/ice-camp.json`.

Both were generated for this project using the built-in image service: the ground prompt specified existing gentle overhead/upper-left-light style, a distinct snow/pine/crystal border, empty central play area and a finite right-to-top road; the camp prompt specified one independent warm tent/lantern/bedroll grouping with real transparency and no people/text/UI. Source filenames are provenance identifiers, not runtime dependencies. No external artwork or legal-clearance guarantee is introduced. The two production files are sufficient current source resources; the rejected/temporary guide and raw generation workspace are not packaged.

## Ice-crest serpent appearance

Level 7 selects `serpent.art_profile="ice_crest"`; omission retains the default atlas and tint behavior used by levels 1–6. This is a separate white-horned broad-head/faceted-body silhouette, not a recolored default head. Preparation and play consume the same manifest. Snow/ice art introduces no freezing, slowing, extra health or alternate damage rule.

The original 1122×1402 RGBA source is preserved. Seventeen components were measured at alpha >8, with a three-pixel contour margin and nearest-component fringe retained within two pixels; they were packed into 1280×1600 without resizing. Source rectangles are not equal atlas cells. Use the manifest's per-part regions and chain anchors, head physical width 292, tail physical width 240 and body physical width 226. Heads display at 84 logical pixels; body diameter retains the route-derived 35–62 range and tail width is body diameter ×0.84. Select the eight real yaw poses under fixed lighting, never rotate the whole head/tail card.

The neutral body uses full-region luminance tint so RGBY gameplay colors remain distinct. Intact/cracked armor still uses `serpent-armor-atlas.png`; ordinary HP1 and armored HP2 semantics are unchanged. The 50 checks in `reports/assets/ice-serpent-test.json` cover profile selection, regions/anchors, yaw poses, default tint preservation and unchanged rule snapshots, not assembled GL appearance or final visual approval. Generated provenance and file hashes are recorded in `reports/assets/ice-serpent-assets.json`; they are not a legal-clearance warranty.
