# First-level card correction: full ant, not a bust

**Candidate only, not pixel-identical extraction or user accepted.** The previous `c763ed1` half-body interpretation was wrong: the approved card retains a complete abdomen, thin standing legs and a three-quarter viewer-facing head. This correction replaces that rejected bust, without changing any gameplay rule or world actor.

## Current artifact

- `assets/first-level/card-portrait.png` now contains one complete blue ant. The old filename denotes a HUD illustration, not permission to crop off the body.
- `card-portrait.json` records source crop, unmodified generated-pixel hash, alpha bounds, source region and exact display geometry. Only source padding is excluded through AtlasTexture; head and abdomen are not independently stretched or resized.
- Source is the approved battle image's leftmost blue-card region `[50,1242,234,1396]`. This is an AI-assisted reconstruction, not an exact cutout. Antenna tips, joints and eye rim still differ and require actual-size/rendered comparison.
- Existing five buttons, real board counts, single-ant dispatch, four-carrier limit, blocked/pause dimming and count-label rectangles are unchanged. Original duplicate blue card,20/30 teams and old skills are not restored.
- Card frame/background remain unchanged. Restoring the complete ant silhouette does not establish the entire card/deck/screen as1:1.

## Real-GPU color defect corrected in source

The actual c763ed1 root-viewport PNG showed purple turning blue and yellow turning green. Its shader multiplied recolored pixels by fragment `COLOR`, which already includes the blue source texture. Following the [Godot4.6 CanvasItem contract](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/canvas_item_shader.html), it now captures node modulation in the vertex stage and applies that varying once. This affects only the five card plates and illustrations. Ten material instances remain independent; actual blocked/pause modulation is preserved. **The new shader still needs a fresh native2K per-color check.** CPU compositions did not model the old implicit second texture multiplication and did not prove its colors correct.

## Verification and small evidence policy

Headless import and **82 narrow checks passed**, including ten independent materials and a static shader contract. Five source/alpha checks passed. Of327 shared initial exported nodes,322 are unchanged; only five card illustration geometry records differ. This does not test shader output pixels.

The exact bounded result and source hashes are in [summary.json](summary.json). Only the card-specific test is rerun for this correction; earlier110.425s/148-point full replay belongs to0491e05, not a newly executed gameplay suite. Native pointer, GPU appearance, animation quality, audio and user approval are not inferred from headless checks.

Run after normal import, using isolated HOME/XDG directories:

```sh
ANT_CARD_EVIDENCE_DIR=/tmp/ant-card-evidence godot --headless --path . --script tests/test_first_level_card_portraits.gd
python tools/compare_first_level_cards.py --nodes-dir /tmp/ant-card-evidence
```

Without the environment variable, the test writes to `user://first-level-card-evidence`. Full node dumps and offline images stay local. The comparison explicitly labels itself **not Godot/GL**; CPU tint/filter/text are approximate; strong image reductions use a local area prefilter to avoid affine undersampling and small custom state icons are omitted. Real unavailable colors remain dim rather than being brightened for presentation.

The current tree retains only current runtime art, test/comparison code and concise verification records. Prior candidate imagery, repeated full-node snapshots and bulky geometry artifacts remain available in public commit history and a verified local archive; history was not rewritten. [c763ed1](https://github.com/crazyniu/ant/tree/c763ed1c6061e6ce6afffca37477738336b4915d/reports/first-level/batch-3) is the **rejected bust candidate**, not the visual target.

## Remaining work

- Actual Godot card rendering and native click comparison, then user visual confirmation.
- Source-faithful card frame/material and exact small feature matching.
- Ball packing/material, dragon texture/rendering, full moving-ant posture, cannon loading/recoil/hit animation and shop restoration remain separate open tasks. This correction changes none of them.
- A supported desktop Godot route is available. Separate actual device logs report audio fallback to Dummy; no sound listening pass is claimed.

[#5](https://github.com/crazyniu/ant/issues/5) and [#9](https://github.com/crazyniu/ant/issues/9) stay open. Only first level; no merge/deploy or later-level unlock.
