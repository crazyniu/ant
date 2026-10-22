# First-level Home / Prep / tutorial candidate

**Later actual review:** d95384c failed four UI checks. The old numbers below remain
historical, not visual acceptance. See [defects and the small repair](../batch-7/README.md).

The prior runtime self-check found obsolete square-ball/red-cannon previews and
an inactive armor instruction. At a 456-wide runtime window the old 18-logical-pixel
tutorial text was only about 8.7 pixels and its 76-pixel action was too short for a
phone-oriented UI. This batch addresses those concrete defects, not the whole shop.

## Changes

- Home and Prep use the same read-only first-level scene builder. It creates the
  actual 240 round-ball cells, 20-segment initial dragon, princess, nest, bronze
  cannon and idle loading-ant nodes from the current scene contract. No gameplay
  instance, Rules run, in-flight ball, inventory HUD, or invented carrier task is
  created. It is not the approved concept image pasted into a background.
- A precommit source/alpha review caught title coverage: Home preview is now below
  the complete title and above Play, with a layout assertion. A separate review
  caught invalid-preview JSON hanging startup; it now reaches the existing error
  and Retry flow before Home/audio creation, without duplicate nodes.
- Home removes its old independent eight-piece decorative dragon/red cannon and
  shows the current first-level scene. New textures join actual startup loading.
- The map's miniature and existing supply/type icons reuse the round material.
  Their HUD scale is illustrative, not the world ball size. Actual scene balls
  remain 33.5 square and at the exact current gameplay cell centers.
- How To Play uses four short illustrated instructions, actual ant/ball/cannon/
  dragon art, and no inactive armor text. The normal first-entry/tutorial-save
  flow is retained. Prep omits the zero-armor tooltip teaching.
- Primary tutorial text is 36 logical pixels; at 360-wide full-canvas scale this
  is about 13.79 pixels. The main action is 140 logical pixels high (53.62 at 360),
  close hit bounds 128 (49.02 at 360). These are geometry measurements, not phone
  readability or touch acceptance. Actual GL must inspect wrapping and art too.
- `docs/FIRST_LEVEL_UI_SELF_CHECK.md` records the mobile-game (not webpage) and
  every-30-minute detailed review rule. Existing repeated-review scheduling is
  not duplicated by this commit.

## Evidence and open checks

`tests/test_first_level_previews.gd` checks only the approved first-level normal
Home/Prep/tutorial paths, actual ball cells/colors/size/centers, current cannon and
target regions, no fictional tasks, no run/save/economy changes from preview redraw,
text fit and scale, and the real tutorial-completion save handler. See summary.json
for exact bounded test results. Old multi-level Adventure tests are not used.

No new GL screenshots, phone touch, sound or user acceptance are claimed here.
Before acceptance, inspect every changed page at native 1440x2560 and phone-sized
window scale: Home preview integration against the forest, Prep detail density,
tutorial full text/art alignment/contrast/pressed states/real button behavior.
Fix obvious defects before submitting the result to the user.

This batch does not alter the current .8-second loading implementation, enemy budget, reward
thresholds, ball arrangement, rules, prices/upgrades, shop artwork or later levels.
Limited x1/x2 loading checks are recorded in batch5; full animation acceptance remains open. #9 and #11
remain open; this is not a claim that the whole UI is restored 1:1.

### Test-exit warning

All listed assertions and CLI cases passed. A repeat of the minimal48 test and
two short CLI exits logged an ObjectDB shutdown warning. One verbose repeat of
the same auto-replay CLI did not reproduce it; its cause is not established.
This remains an explicit runtime-cleanup investigation, not a clean-log claim
or evidence of an in-game visual failure.
