# Ant Rescue meta UI production assets

This is the current minimal warm-forest / gold / wood asset pack. It follows the ant-shop design preview (not final user acceptance) and existing serpent environment. It does not introduce a new art direction and does not modify game code.

## Use

- `shop-workshop-background.png`: opaque blank workshop plate, **native 941 × 1672**. No letters, numbers, UI cards, buttons or characters are baked into it. Its middle floor can sit behind two independently laid-out products; the wooden lower plane supports a training section.
- `titles-atlas.png`: current generated RGBA source, **native 1024 × 1536**, containing exactly ADVENTURE, READY, ANT SHOP, WORKER, SWIFT and TRAINING.
- `adventure.png`, `ready.png`, `ant-shop.png`, `worker.png`, `swift.png`, `training.png`: independent tightly bounded RGBA crops for convenient scene nodes. Preserve aspect ratio; do not stretch letters to a fixed box.
- `icons-atlas.png`: current generated RGBA source, **native 2172 × 724**.
- `swift-wing.png`: independent **607 × 610** gold wing ornament. The sprite has no character baked in; position it as a separate node next to the existing ant or use it as a speed badge.
- `ant-coin.png`: independent **582 × 584** front-facing gold ant-emblem coin. Amounts remain live text and are not baked in.

`manifest.json` records the source atlas region, default centered anchor, exact native size, source filename, SHA-256 and measured alpha evidence for every sprite. Regions use top-left pixel coordinates. The optional wing attachment anchor is only a visual starting point and must be tuned against the selected ant direction.

## Transparency and slicing

The original generated alpha is retained, not replaced. Content runs and bounding boxes were measured with alpha > 4 and an 8-native-pixel margin, rather than cutting the atlas into equal rows or columns. Alpha values 1–4 can be isolated generator noise, so they do not define visible content bounds. The retained crop pixels still exactly match the corresponding source atlas region, including their antialiasing. All crop borders have maximum alpha 0 or 1. Do not treat hidden RGB behind alpha 0 as a visible background.

`validation-report.json` contains pixel counts, alpha extrema, transparent percentages, native sizes, checksums and review results. The source atlases are retained because they are the current production sources, not older alternatives. No concept screen was sliced into a full-screen fake UI node.

## Resolution honesty

These assets target a 2K-class portrait layout, but the workshop plate is **not native 2K**. No file was resampled or enlarged. UI composition may scale or crop the background as required; that is display scaling, not additional generated detail. Icons and titles should ordinarily be displayed at or below their recorded native size.

The built-in image-generation tool was used for all three generated source assets. Exact requests and references are in `generation-prompts.json`. Existing ant direction assets stay in `assets/motion/ant-directions.png` and are not duplicated here.
