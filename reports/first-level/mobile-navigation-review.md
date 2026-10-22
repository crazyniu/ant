# First-level mobile navigation integration

2026-10-22. Follow-up to the real b9907d9 review recorded in Issues #9 and #11.
This is a code/node-tested candidate, not a new-renderer visual pass.

## Corrections

- A sole enabled first level uses a 1174-high map canvas matching its viewport,
  rather than a 1480-high multi-level trail. The real node and complete framed
  scene card are visible immediately. Saved offsets -1, 0, 411 and 99999 converge
  to the only valid position. No unavailable nodes are added.
- Adventure reuses the same read-only scene builder as Home/Preparation: the
  actual 240 colored balls, 20 ordinary dragon segments and bronze cannon.
  Both the medallion and complete scene card select level 1 through the existing
  guarded callback. The heading and live level state use 38-logical-pixel text.
- Pause → Level Select requires one Leave confirmation, not two. Cancel and the
  existing pending-victory-save guard remain. Leaving still uses the production
  cancellation/startup transition.
- Preparation's selection controls are 351×120 within taller, repositioned
  plinths. Both header controls are at least 116×116. Home in Pause is 120×120.
  Battle Pause/Gear/Speed retain approved artwork and centers, with 116×116
  actual hit rectangles inside the logical canvas. Speed state text is 38 px.
- Tutorial Close is created at its final 128×128 size/position before animation
  records its resting transform; its center stays aligned with the painted X.
- Integrated shared-modal and Shop fixes retain their separate reports. Shop
  actions now explicitly use primary/secondary game skins, not list-row skins.
- Two existing recovery tests now create their report directory and fail cleanly
  on report-write failure, rather than hanging on a missing fresh-checkout folder.

All geometry is in the existing 940×1672 logical canvas. A 116-unit target is
44.4 px at a 360-wide reference scale, not a claim about physical-device input.
The gameplay configuration, ball WORLD_SIZE, economy prices and upgrade rules
are unchanged. No later level was opened, tested or enabled.

## Bounded integration evidence

- Map visibility/normal navigation: 177 checks.
- Home/Preparation/tutorial/loading preview and text checks: 1649.
- Shared modal layout, caller return and volume recovery: 1399.
- Shop symbols, real purchase callbacks, states, skin regions and hit areas: 440.
- Settings recovery: 20; navigation save boundary: 20.
- Existing first-level scope/loader/gait/feedback regression: 48.

All final runs exited 0 with no assertion failures. Some existing headless tests
can emit an ObjectDB cleanup warning; this is not advertised as a clean-log run.
Early integration runs exposed a test-node-path mistake, a modal override
signature mismatch and a missing report directory. These were corrected before
the listed final runs; the failed attempts are not counted as passing evidence.

## Required actual review

Capture Home, Preparation, initial Adventure, Shop, tutorial, Pause and Settings
in the real renderer. Inspect alignment, padding, clipping, body/secondary text,
normal/pressed/disabled states, card/plinth balance and caller-specific return.
Exercise the larger target bounds and current engine-touch path separately.
The b9907d9 real-renderer observations do not certify these changed pages.
Whole-scene resemblance, ball material, animations, natural complete play,
physical-phone input, audible output and final user approval remain open.
