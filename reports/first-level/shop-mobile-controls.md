# Bounded first-level Shop correction

Base: `68a20a56940b276d84e50a33af0a0f5a2ef552f2`. Reviewed the actual earlier `ant-b9907d9-session1/capture-012-1295005-1440x2560.png` before editing. This report is a new Shop-only delta; earlier reports remain unchanged.

## Change

- Worker/Swift capacity uses the existing `first_level_bead.gd` round-ball material at **52×52 HUD units**, not the old square bead. World size remains **33.5×33.5**.
- Capacity remains **1**. Removed the tiny repeated `ONE BEAD PER TRIP` sentence. Movement uses the exact existing Prep `Emblem.speed` lightning class, not a generic chevron.
- Both cards show the current effective type × shared-level multiplier: initial Worker **+0%**, Swift **+20%**; Lv4 Worker **+15%**, Swift **+38%**. No change to progression, prices, rewards, capacity or frozen loadout rules.
- Important numerical labels are **38 logical px** (14.55px at 360 width); error feedback is **32** (12.26px). Names remain existing painted title assets.
- Actual equipment/purchase Buttons and their existing gold-edged painted skins share **120-unit height** (45.96px at 360 width). Worker/Swift actions: **335×120**, at `(90,896)` / `(515,896)`. Training: **386×120**, at `(409,1352)`.
- Skin correction after parent review: the earlier revision only checked that a nine-slice existed; inherited `frame()` still chose the thin `game/row` for cream actions. Actions now explicitly use **game/primary** or **game/secondary**, with 42-unit corners. The focused test checks the actual atlas path/region, not just node presence.
- Back now uses **game/secondary**, `(28,45,120,120)` with 34-unit corners and a centered 68×68 arrow. Its title gap remains 32 units. Normal/hover/pressed/disabled event-layer styles stay empty; Shop-only keyboard focus is a 3-unit border without center fill. No global style was changed.
- Stats, price/icon contents and training panel were repositioned together. Training panel is `(55,1100,830,410)`; feedback starts at y1534. Controls remain inside their own cards, separate from statistics and feedback. No invisible hit expansion over adjacent text.
- Ownership, equipped/disabled, insufficient-balance, busy and max-level states remain actual Buttons. Max-level tooltip now describes the cap instead of suggesting a nonexistent next purchase.

## Verification

- Godot **4.6.3** headless import: final run had no errors.
- New `tests/test_ant_shop_mobile_controls.gd`: **440 checks, 0 failures**, summarized in [shop-mobile-controls.json](shop-mobile-controls.json). This includes the 311-check functional/font baseline plus actual primary/secondary regions, full Back geometry, transparent interaction states, visible border-only focus and price containment.
- Existing `tests/test_ant_shop_view.gd`: `ANT_SHOP_VIEW_OK`.
- New test uses a disposable `/tmp` Worker Lv1/zero-point profile and the real Startup → first-level Prep → Shop callbacks. Existing first-level reward settlement creates fixture funds; these are **not played victories**. No other levels were loaded or tested.
- Covers zero points / locked 500 and 100 prices; one Swift press/one 500 debit; stale repeated signals; owned/equipped states; failed write preserving ledger and retry; 100/150/250 upgrades; Lv4/+38%; shared Worker +15%; max cap; reload with exactly four paid products; return to first-level Prep; font fit and action geometry. Final headless runs had no script errors or shutdown warnings.
- Scope is signal-driven functional/node/font checking, **not native touch, GL rendering, listening, natural gameplay, device performance or 1:1 visual acceptance**. Parent native Shop inspection remains required.

Source SHA-256 (`scripts/ant_shop_view.gd`): `a11a4e3a46b09e48b36ad2735319cc243777ad052c0aaf7a7ce58be774ad9ca9`.
