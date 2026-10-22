# First-level batch 3: five battle-card portrait candidates

**Candidate, not 1:1 accepted. No Godot/GL screenshot or native-input acceptance is claimed here.** This is a bounded follow-up to public `0491e05510829dee88b930bd5f86698f86e43082`. Only the five battle color-card illustrations change. Shop, world ants, round balls, stage, paths, cannon and gameplay rules are not changed.

## Actual change

- Independent transparent `assets/first-level/card-portrait.png`, with region/pivot-like display placement, source reference, alpha bounds and SHA-256 in `card-portrait.json`.
- Derived with built-in image generation from the actual approved leftmost blue-card crop, not a new overall art direction. The accepted-for-candidate source pixels and generated alpha are copied unchanged; Godot uses an AtlasTexture region to remove far transparent padding.
- A large three-quarter, viewer-facing head and small upper thorax replace the five old side-facing walking-ant thumbnails. The same one blue source is tinted through the existing shader into blue/red/yellow/green/purple. This is a HUD illustration, not a new ant class or a change to world-ant physical size.
- `scripts/play.gd::build_candidates()` retains the existing five buttons, signal handlers, hit rectangles and numerical label rectangles. No 20/30 team size, duplicated blue selector, extra slot, plus or skill is restored.
- Card numbers are the real balls still on the board, **including reserved balls**. A reservation does not decrement them; actual pickup does. The production rules are unchanged.

## Source and same-position comparison

- Approved source: `reports/first-level/approved-battle.jpeg` (864×1536).
- Read-only reference crop: [approved-blue-card-crop.png](approved-blue-card-crop.png), original box `[50,1242,234,1396]`. It is an input/inspection reference, not a runtime card background.
- Exact generation instruction: [portrait-prompt.txt](portrait-prompt.txt). Two preceding variants were rejected before runtime binding for thick limbs/antenna tips and redesigned facial features; those rejected raster files are not shipped.
- [cards-reference-before-after.png](cards-reference-before-after.png) compares original art, `0491e05` card nodes and current portrait nodes in the same current button positions. Original four-card/20/30 labels are identified as legacy art, not current gameplay.
- [cards-live-state-offline.png](cards-live-state-offline.png) shows one reservation, full transport capacity, actual first pickup and pause. The first actual pickup in this bounded test is at3.7 simulated seconds; blue80 becomes79 then, not on the click.

These are **CPU node compositions, not Godot rendering**. Shader tint, filtering and text are approximated. Barrier/clock/check custom icons are omitted by this compositor. Red/yellow are initially dim because of actual blocked state, not because their raw portrait material is darker. Historical batch-2 exports omitted the old non-drawing card parent modulation; the comparison tool reconstructs only that known parent factor from the recorded blocked/collected icon and unchanged `sync_view()` logic. The reconstruction is explicit in code, not represented as a captured frame.

## Finite verification

Headless import and `tests/test_first_level_card_portraits.gd`: **79 checks, zero failures**. This covers five real source/tint bindings, non-intercepting art/text, unchanged hit/count rectangles, connected button signals sending one ant each, four-carrier capacity, authoritative counts before and after actual pickup, pause/restore and visibility. Signals are not native pointer events.

Initial node comparison against `0491e05`: all shared exported nodes are field-for-field identical; the only removals are the ten old portrait sprite/shadow children, and the only additions are the five independent portrait nodes. All stage, ball, carrier, cannon, label and other initial exported nodes remain unchanged. Exact source/evidence hashes are in [summary.json](summary.json).

The first narrow test harness had nine failed assertions because it used bit-exact floating-point rectangle equality and incorrectly expected reservations to remove board balls. [card-test-first-harness.json](card-test-first-harness.json) preserves that run. The harness was corrected to a0.001 logical-pixel tolerance and the frozen reservation/pickup semantics, then added actual pickup checks. No production rule was changed to satisfy the test.

Reproduce after a normal headless import:

```sh
godot --headless --path . --script tests/test_first_level_card_portraits.gd
python tools/compare_first_level_cards.py
```

Use an isolated HOME/XDG test profile. No later level or whole-game suite is exercised. Batch-2's110.425-second victory/148-point result and its other check counts remain evidence for `0491e05`, not a newly rerun result for this portrait-only commit.

## Still open

- The portrait is not a pixel-identical extraction. Antenna tips/front appendages remain somewhat thicker, the face rounder, and mouth/far-eye features more prominent than the approved original.
- The card frames/background panels are unchanged and still need their original-art material/composition review. An improved face does not make the whole card, bottom deck or full screen1:1.
- Shop still uses its old assets; no shop upgrade/economy work is included.
- Round-ball shape/highlights/packing, dragon, cannon crew/loading and complete screen restoration remain open under their existing issues.
- This portrait commit still needs real Godot rendering, native card hit tests and user visual confirmation. A supported desktop Godot route is now available for separate verification; prior shell/Xorg failures do not mean the entire graphics environment is unavailable.

Issue mapping: [#5](https://github.com/crazyniu/ant/issues/5), with future shop consistency under [#9](https://github.com/crazyniu/ant/issues/9). Keep both open. Do not merge/deploy this candidate.
