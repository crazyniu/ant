# Segmented serpent actor asset handoff

Generated and inspected 2026-10-21 using the built-in image generator. The approved red-and-gold serpent concept was used as an identity/style reference, not cropped into a fake transparent actor.

## Production files

- `assets/serpent/serpent-atlas.png`: 1303 × 1774 RGBA, 2,377,771 bytes. Eight genuine head yaw views, one red spherical body bead and eight tail yaw views. SHA-256: `caf1130462c58cf121e529e60810218b2ae3d7dc3939670ebdefeb1788f9a360`.
- `assets/serpent/serpent-atlas.json`: renderer contract with root `path`, `heads`, `body`, `tails`, and per-entry `armor` paths.
- `assets/serpent/serpent-armor-atlas.png`: 1536 × 748 RGBA, 984,752 bytes. Two independent gold armor overlays, intact and visibly cracked. SHA-256: `c8595e610a0b5b17c22ac1d1fa908454b8c3ce9de8560720fb08ed9a23651d2d`.

## Placement

Use the direction key for actual yaw selection. Never rotate the entire head or tail sprite. `physical_width` is common across head views (420 source pixels) and across tails (360 source pixels); do not normalize projected sprite width per view. The reference target sizes are head physical width 76, bead diameter 40, and tail physical width 64 logical pixels.

Head anchors are rear neck-axis body-chain joints. Body anchor is its sphere center. Tail anchors are the gold-collar joints. The tail direction key names the movement/base direction; its tip points the opposite way. Place each sprite with `origin = path_attachment - anchor × scale` and `scale = target_width / physical_width`.

Armor entries each specify their own `path`. Both have a 768 × 748 region, anchor [384, 374], and physical width 734. Draw them at the bead's center with target width equal to bead diameter. Shader-recolor only the bead, not the gold armor. The interior hole contains no baked sphere and no pixel above alpha 1/255 inside the audited 210-pixel radius.

## Audit and limitations

The actor crops use the eight/nine largest connected components of true nonzero generated alpha, not a blind equal grid. Each keeps four pixels of source margin and eight pixels of new zero-alpha outer gutter. Source RGBA in each crop is byte-identical to the original; no painting, recoloring, resampling, alpha thresholding or whole-sprite rotation was used. All regions are bounded and non-overlapping; all anchors lie in their regions; all 17 actor regions have a fully transparent eight-pixel outer gutter. Horns, fins and tail tips were visually inspected and retained. The pack is under 2048 pixels per axis.

Generation produced faint low-alpha speckles in the original transparent area, mostly alpha ≤ 8/255. They are preserved rather than silently repainted. The main body has a circular silhouette and no directional protrusions, but its scale rows and upper-left highlight are not mathematically rotation-invariant; leave its rotation at zero.

There is no floor, cast floor shadow, scenery, text, quota, neighboring visible sprite or UI in the actor crops. Complete provenance, prompts, source hashes, crop coordinates, anchors, and checks are in `serpent-actor-assets.json` and `serpent-actor-assets-armor.json`. Original AI-source provenance is not a license claim or legal warranty.

## Separate princess request

The separate, fully clothed standing princess generation was rejected at the image service's output moderation stage (HTTP 400, `moderation_blocked`, category `other`). No princess image was produced or added to this project; the completed serpent and armor assets remain usable. This does not claim visual acceptance, gameplay validation, target-device performance, or permission to merge/deploy.
