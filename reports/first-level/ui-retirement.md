# First-level UI retirement: bounded lifecycle fix

Scope: first-level UI only. No visual redesign, gameplay, reward, route, timing, input-emulation setting, save schema or asset change. Existing visual candidates remain unaccepted. No whole-round replay was performed for this change.

## Evidence and fix

The two b8f200b real GL engine-touch sessions contained five `can_process: !is_inside_tree()` errors around Map→Preparation (twice), successful Training refresh, Settings X→Paused, and Pause→Leave. Historical logs lack the exact object/caller stack, so those individual objects are not retrospectively claimed as captured.

A standalone ordinary Button using `Input.parse_input_event(ScreenTouch)` reproduced the same error when its real `pressed` callback immediately detached its UI subtree and queued deletion. The test injected no mouse event or game callback; Godot generated the paired mouse event. Delayed detachment or hidden in-tree retirement did not reproduce it (16 behavioral checks). Godot 4.6.3's [Input](https://github.com/godotengine/godot/blob/4.6.3-stable/core/input/input.cpp) and [Viewport](https://github.com/godotengine/godot/blob/4.6.3-stable/scene/main/viewport.cpp) source support this ordering: emulated mouse release can run the callback before the original touch release checks its focus object.

`UiMotion.retire_control` now disables input, disconnects retired Button callbacks, hides the subtree, gives it a unique retired name, and queues deletion while keeping it in-tree through the event boundary. Adventure pages, Shop rebuilds, and completed/discarded modals use this helper. Business callbacks still execute synchronously; no delayed purchases or delayed navigation were introduced. The original 0.12-second modal close animation remains.

A second pre-existing failure appeared on fresh Map entry: deferred `_restore_scroll` received an already-freed typed Control. It now passes only a page-generation integer, checks it before waiting and after layout, and uses the current scroll control only if the generation still matches. Early rejection of obsolete generations also removes the shutdown warning seen in an intermediate run.

## Finite validation

- Frozen 8e6bd63 baseline, same common production UI input path: 31 behavioral checks; **8 lifecycle errors and 2 deferred-object errors** reproduced. This was not a zero-error pass.
- Final `test_first_level_ui_retirement.gd`: **58 checks, no failures**, no error/warning lines. Actual engine touch inputs exercise both Map entry buttons, Back, one fixture-funded Training purchase, one real blue dispatch, Gear, Settings X→Paused, Leave Cancel→Paused, explicit Continue, and immediate Gear while the prior Pause close animation is still active. Every injected contact produces one touch pair and one engine-generated mouse pair; no mouse is injected by the test.
- `test_first_level_map_visibility.gd`: **184 checks, no failures**, no error/warning lines. Initial and saved offsets, current first-level preview and Leave entry remain bounded and visible.
- `test_ant_shop_mobile_controls.gd`: **909 checks, no failures**, no error/warning lines. Its old 33.5×33.5 world-ball expectation was updated to the already-existing f4 shared 33.5×35.75 contract. The stale Swift signal assertion now requires no second purchase request, not merely no second debit; old handlers are intentionally disconnected. Prices, ownership, save-failure retry, upgrade effects and geometry remain unchanged.

The purchase receipts are isolated service fixtures, not played victories. Raw baseline/intermediate/final logs are retained locally; only this summary and repeatable test are published. Earlier baseline errors and intermediate harness issues are not erased or relabeled.

## Still unverified

No GL or physical-phone validation of this lifecycle commit. No multitouch, OS cancellation, audio, natural-player balance or new full-round claim. Existing b8 real victory/purchase/cold-start evidence stays version-specific. Visual acceptance, the design-first gate, all open art issues and final user approval remain open.
