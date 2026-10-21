# Current asset manifest and placement contract

All paths are relative to this Godot project. Runtime resources use local `res://` paths, never generation-workspace paths or private download URLs. `docs/asset-manifest.json` records current SHA-256, file sizes, actual bitmap dimensions, source provenance, alpha measurements, region manifests and placement anchors.

## Current image inventory

| Runtime image | Generation source / purpose | Actual pixels and transparency | Slice / anchor |
|---|---|---|---|
| assets/environment.png | exec-5634055f-4288-4140-bc62-3b3982342f36.png. Cohesive stone-bordered garden ground; no baked gameplay objects. | 940 × 1672 RGB, opaque. | Full logical canvas, origin (0,0), display 940 × 1672. The 1440 × 2560 viewport does not make this a native 2K source. |
| assets/ants-atlas.png | exec-8ea19348-0b71-4a05-9207-5ca81df92a47.png. Six ground-facing color-matched ants. | 1536 × 1024 RGBA; 71.97% alpha=0. | data/ant-regions.json. Actual alpha >=4 connected silhouettes plus 7 px on every side. Ground carriers use a foot/contact anchor, not image top-left. |
| assets/ui/fusion/beads.png | exec-663aa429-b489-40aa-ad2d-ed32f2306f4d.png. Six rounded-square physical bead materials. | 1536 × 1024 RGBA; 51.62% alpha=0. | bead-regions.json in the same folder; connected silhouettes +7 px. Independent live bead nodes use the common ground projection. |
| assets/ui/fusion/audio-icons.png | exec-c382e307-3ead-4b39-ab24-b714f1768136.png. Standalone music-note and speaker emblems without tile frames. | 1774 × 887 RGBA; 80.57% alpha=0. | audio-regions.json in the same folder; connected silhouettes +7 px. Aspect-centered in separate 82 × 82 logical UI rectangles. |
| assets/characters-atlas.png | exec-4a5f0290-36f9-43d7-8a1d-48701d181e0a.png. Existing dragon, princess/tower, cannon, nest and shields. | 1536 × 1024 RGBA; 51.20% alpha=0. | Seven distinct source rectangles in main.gd; explicit target rectangles. No equal-cell cuts. |
| assets/ui/v03/game-skin-atlas.png | exec-c01d3f5f-3b82-4658-b582-d36206c99f47.png. Shared stone/ivory panels and four enamel tools. | 1254 × 1254 RGBA; 28.26% alpha=0. | regions.json game entries; panel patch margins are 64 source px. |
| assets/ui/v03/settings-skin-atlas.png | exec-1a8975cd-4f75-4b03-8d31-e7a53f89175b.png. Shared modal panel, wood plaque, slider pieces, close and action. | 1254 × 1254 RGBA; 26.98% alpha=0. | regions.json settings entries; modal panel margins are 100 source px. Track, fill and knob are separate layers. Old music/sound tile and toggle slices are unused. |
| assets/ui/v03/title-atlas.png | exec-59a7cd41-490a-4d87-a502-7c505882fdaf.png. Sixteen English sculpted ivory art titles. | 1254 × 1254 RGBA; 49.38% alpha=0. | title-regions.json. Alpha-derived word bounds with gutters, aspect-centered over a separate wood plaque. |

These generation sources are from 2026-10-21. The current environment, ants, beads and audio emblems supersede the preceding loose image versions; old versions are archived outside this project. Existing shared actor and v03 UI atlases remain active current resources, not duplicate historical files.

## Common ground and contact anchors

`scripts/board_plane.gd` defines one near-orthographic ground projection: top edge (175,350) to (765,350), bottom edge (130,890) to (810,890). Its column/row counts come from the logical board. A cell center is project(x+0.5,y+0.5). Gallery and playable beads, live carrier route points and FX cell positions consume this same projection; rules retain integer logical cells.

A ground-ant group's origin is its ground/contact point. `ground_ant` positions that group at the projected location, creates `FootShadow` at local (0,0), and places the aspect-centered ant sprite at (-0.5d,-0.84d) with size (d,0.86d), where d is the diameter. Current source-alpha measurement puts the painted foot baseline within 0.102 logical px of group/shadow origin at d=39. Scale and route interpolation act on the whole group. Queue, slot and modal ant portraits still use explicit UI rectangles; they are not ground actors.

A board bead uses span=BoardPlane.footprint(x,y)×0.98, position=center−(span.x×0.5,span.y×0.57), and draw size (span.x,span.y×1.07). Stock and carried beads use the same generated color materials at explicit local sizes. Beads are independent live nodes, not a baked board image. Soft contact shadows are drawn by `contact_shadow.gd`; the ant atlas is not positioned by its visual center. The nest route endpoint is explicitly (467,1074), outside the regular board cells.

## Other runtime assets and provenance

- assets/fonts/Title.ttf is DejaVu Sans Condensed Bold from the installed font package. License: licenses/DejaVu.txt. Dynamic counts and necessary functional copy remain real text.
- assets/audio/ contains 15 locally synthesized originals: the full 40-second BGM loop as native Ogg Vorbis and 14 unchanged PCM WAV cues. The lossless BGM master is archived outside the runtime source, with its hash and reproducible encoding recorded in the audio README. Source, reproducible hashes and validation are in assets/audio/generate_audio.py, manifest.json and README.md. There are no external samples or borrowed melodies.
- Small directional/lock glyphs and contact shadows are original Godot drawing code. Bead appearance now uses the current generated material atlas rather than the preceding procedural rounded-square drawing.
- No complete concept screenshot or competitor artwork is a runtime overlay. AI image provenance is not a separate legal warranty; applicable service terms still apply. The font license is included.

## Current validation

`reports/assets/reference-audit.json` and REPORT.md record the pre-startup eight-PNG fusion slice audit. Its slice results apply to those unchanged atlases; its file count/hash snapshot is not the newer startup snapshot. The current package inventory is SOURCE_MANIFEST.json; docs/asset-manifest.json has refreshed current hashes and the additional original brand image. Original slice-audit findings:

- That audit covered eight runtime PNGs and 36 manifest entries. The startup title is a ninth runtime PNG, fitted whole with preserved aspect ratio, not a newly sliced atlas.
- All 57 slices are nonempty, within source bounds and pairwise nonoverlapping: 36 existing UI/title slices, 14 current ant/bead/audio slices and seven actor slices.
- All 14 current silhouettes use actual alpha >=4 connected bounds plus exactly seven source pixels per side, not equal-grid slicing. Boundary alpha is at most 2; no neighboring substantial silhouette or clipped substantial component was found.
- The 36 existing UI/title crops have alpha <8 on their boundaries. Keep AtlasTexture.filter_clip enabled; imports disable mipmaps and enable alpha-border correction.
- The existing blue shield is still a tight crop at its left alpha edge. Its substantial silhouette is retained, but smallest-display visual review remains appropriate. No claim is made that every faint low-alpha shadow pixel outside a crop is preserved.

Unused named slices within required atlases are game/primary, game/secondary, settings/music, settings/sound, settings/off, settings/on, settings/row and titles/CONTINUE. Removing these names would not shrink the source PNGs. Validation SVGs in reports/rules/ remain referenced by the three level thumbnail fields.

Source validation is not final GL visual approval, natural manual playtesting or target-device performance acceptance. The coherent direction is approved; the current fusion batch still has its own render-review gate.

## Source-package boundary

Keep current assets, source, fonts/licenses, levels and thumbnail dependencies, tests and compact reports. Exclude `.godot`, screenshots/evidence, design/history/archive folders, generation working folders, temp files, nested ZIPs and movie captures. Godot can regenerate `.godot` locally without making it part of the source package.

The current source ZIP is a tested snapshot, not the live edit directory. Its external package-manifest.json records contents and SHA-256. Rebuild only after the batch render/behavior check; archive the preceding ZIP outside this project. In-progress campaign drafts remain outside the tested P3 snapshot until their own validation.

Current screenshots live separately from project source. Capture output uses `ANT_RESCUE_EVIDENCE_DIR` when set, otherwise Godot's `user://evidence`. Current evidence locations are described in README.md.

## Carrier and dragon motion resources

The original six ant regions remain the only carrier bitmap source. `scripts/carrier_motion.gdshader` locally articulates measured near/far leg regions, thorax and antennae without sampling adjacent atlas cells; `scripts/carrier_motion.gd` applies independent per-actor uniforms. Runtime carriers are 48 logical pixels wide, with a 24-pixel carried bead. The grounded shadow and group translation/depth scale stay owned by `play.gd` and `BoardPlane`. A finite pickup crouch/turn uses the authoritative hold interval; loaded stride is 1.65 Hz versus 2.15 Hz outbound. Supplied simulation time freezes gait during pause. No new image, crop or license is introduced.

The existing dragon region uses its foot pivot (220,193). `rescue_fx.gd` presents a 1.60-second fatal-hit stop, stagger, fall, landing dust and settle; only its final 0.30 seconds fade. The actual rule final hit saves victory immediately. Presentation completion gates only the result overlay and cannot change win/loss or repeat a save.

The dragon uses a bounded flat 32×24 2D mesh (825 vertices) over the unchanged atlas region. `combat_tint.gdshader` forward-deforms head, torso and wing regions by different amounts while retaining the planted paw band. The outer tilt is limited to 0.045 radians and settling to 0.035; it is not a whole-card flip. No texture inverse-warp or new 3D model is used.

## Reusable interaction and combat presentation

`scripts/ui_motion.gd` owns cancellable button art, modal and hint tracks. `scripts/play.gd` binds simulation-clock team transfer, queue refill, finite pickup lift and stock accents. Existing textures/regions/anchors remain unchanged. `scripts/rescue_fx.gd` draws a 36-logical-pixel shaded projectile, continuous four-layer tapered trail and bounded local impact. These are original procedural components, not new externally licensed assets. Contracts and current evidence scope: `docs/INTERACTION_MOTION.md`.

## Startup brand

`assets/startup/title.png` is the current original AI-generated ANT RESCUE title (1774×887 RGBA, actual alpha bounds 0,0–1761,873). It is kept as one transparent brand element, not a complete screenshot. Use aspect-preserving fit, no nine-slice; Home display is 740×370 logical units and native/shell startup uses the same source. Existing environment, dragon/tower/cannon, ants and beads remain independent nodes. Generation provenance and SHA-256 are in `docs/asset-manifest.json`. The generated intermediate source stays outside the project.
