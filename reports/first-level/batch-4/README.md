# First-level batch 4: remove rejected inventory HUD

Base: [a1ee1d8](https://github.com/crazyniu/ant/commit/a1ee1d854e53b3fef4def2b3afaa588ddd741b47). Only the approved first level. No later-level work, merge or deployment.

## Exact scope

The approved scene no longer creates the five colored inventory balls and five inventory numbers beside the cannon. Its label updater and arrival-label animation are disabled, and delivery no longer draws the obsolete nest-to-inventory star or inventory ring. This does not remove real muzzle feedback or shots.

The internal inventory ledger, capacity, debit/refund/conservation and event deadlines are unchanged. Actual carriers, HopperAmmo, five color cards and their remaining board counts, four transport pedestals/count, speed, pause and settings remain. No replacement statistics or fake controls are added. The change is conditional to the approved first-level scene; archived layouts are not advanced or newly tested.

## Finite verification

**87 headless checks, zero failures**, in `tests/test_first_level_inventory_hud.gd`: actual connected blue dispatch, pickup, unloading, delivery, once-only debit/fire, flight, pause and hit; real counts and conservation at each checkpoint; absence of obsolete stock nodes/feedback. Only one first-level supply cycle, not full gameplay, native mouse, audio or GL acceptance.

Exact unchanged times: pickup 3.700s; unloading starts 8.625s; delivery and fire both 8.825s; hit 9.275s. First shot remains blue. Five card counts reflect the actual board, and transport capacity releases only on delivery.

Initial exported render records fall from 327 to 317. Exactly five side balls and five labels disappear. All 317 remaining records match after normalizing the construction-order names of two anonymous TopHUD controls. No full snapshots or new comparison images are added to the repository.

```sh
godot --headless --path . --script tests/test_first_level_inventory_hud.gd
```

The test writes only local evidence. See [summary.json](summary.json) for checks, timestamps and exact changed/unchanged source hashes.

## Still open in #6

This is **not** a completed loading animation. The current 200ms unloading window has no continuous back-to-hopper hand-off; first delivery and fire occur at the same authoritative timestamp, so there is no post-credit loading interval. A readable hand-off must use valid transport states and the real fire event without inventing inventory or silently delaying rules. Cannon-worker assets, contact/ownership transitions, pause/x2/terminal edge cases and real GL/user acceptance remain open.

Native a1ee1d8 full-ant/five-color verification is separately recorded in batch 3. It does not validate this later HUD-removal delta. Current device audio uses Dummy; no listening pass is claimed.


## Subsequent native GL check, exact b4a6d7d build

At 2026-10-22 03:49:32 UTC, native 1440×2560 OpenGL evidence and actual input confirmed removal of the rejected right-side inventory group. One blue click changed 80→79, transport returned to0/4, and the first blue segment disappeared without the HUD returning. No empty-node UI error was observed. Frozen HEAD and tracked-clean source were independently checked; driver build-ref is operator-supplied. PNG hash is in summary.json. This validates only this removal/basic supply-chain delta, not the later loading candidate, overall1:1, audio or user acceptance.
