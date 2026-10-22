# Bounded Shop button proportions (2026-10-22)

Base: `c70a52b34e4ae1f4a5a282cdfe04e1bbbeca17f3`. Shop only; previous reports describe their historical versions.

- Card actions retain their original `335×120` hit rectangles at `(90,896)` / `(515,896)`. Painted skins are centered `335×90` at y911, ratio **3.72:1**. Training retains `386×120` at `(409,1352)`, with centered `386×88` paint at y1368, ratio **4.39:1**.
- Existing primary/secondary skin regions remain; rendered nine-slice corners are **28**, not 42. The purchase row remains one combined action, not separate price/operation sub-buttons.
- Prices remain **38 px**, centered in 56-unit line boxes. Coins stay 48 square; purchase/training icons 52 square; equipment icons 64 square. Content control-box padding is at least 12 units above/below, price font metrics including outline leave at least 16. These are geometry/font checks, not measured rendered-pixel clearance.
- Back retains its original `120×120` hit rectangle and centered 68-square arrow. Its paint reuses the existing approved deck-controls medallion crop at proportional `100×98.47`, not a stretched capsule.
- Prices **500 / 100 / 150 / 250**, items, callbacks, ownership, equipment, locked/disabled/busy/max states, rewards and gameplay are unchanged. Cosmetic press/release scales only artwork, never the hit target.

## Limited verification

Godot **4.6.3**, isolated temporary profile and writable temporary XDG directories:

- `godot --headless --editor --path . --import`: passed without reported errors on the final run. Initial default-XDG attempts could not write the sandboxed user-data directories; no player profile was used.
- `godot --headless --path . --script tests/test_ant_shop_mobile_controls.gd`: **885 checks, 0 failures**. Covers the above geometry and six economy states, proportional coin/icon and lock padding, font fit, stable hits during press/release, real production economy callbacks, stale signals, failed-save retry, exact debits and reload. Detailed JSON is written inside the disposable profile; the command prints its path instead of overwriting historical reports.
- `godot --headless --path . --script tests/test_ant_shop_view.gd`: **ANT_SHOP_VIEW_OK**.

No full-suite, GUI, native touch, gameplay victory, audio, later-level or visual-acceptance claim. Parent must render and inspect the changed Shop before acceptance. No assets generated, push, merge or deployment.
