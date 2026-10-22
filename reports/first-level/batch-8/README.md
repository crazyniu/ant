# Mobile typography after real b990 UI inspection

This batch addresses the Home/Preparation/HowTo/Loading text defects found in the real b9907d9 screen review: [reproduction and evidence](https://github.com/crazyniu/ant/issues/9#issuecomment-6333500921). It is not a complete mobile-UI or original-art acceptance.

## Changes

- Home current-level state uses the existing cream text and dark outline on the wooden footer, 38 logical pixels in a 600×50 box. Both initial and fresh-round text fit; title/actions are unchanged.
- Preparation uses 38 for necessary level/capacity/effective-speed state, 32 for the secondary points balance. Capacity and speed share a numeric axis. The maximum real level/speed string fits without shrinking; the summary clears Begin. Worker/Swift ownership, selection and actual values are unchanged.
- Tutorial main instructions use 38 with 490-wide text regions, leaving ten pixels beyond the longest line; the timing notice uses 32. Existing four illustrations, continue/close controls and real tutorial persistence remain.
- Loading status now uses the existing official font, 38, and a 750-wide region. Its real failure message fits two lines above Retry. Back/Retry also use 38 with the already-correct official skin. Progress and cancel/retry ownership are unchanged.

At a 360-wide portrait display, 38/32 logical pixels correspond to approximately 14.55/12.26 pixels. These are layout checks, not a physical-phone or visual pass.

## Bounded verification

- `tests/test_first_level_previews.gd`: 1,640 checks, no assertion failures. Includes text dimensions, axis/spacing, true preview/config, all Loading button states, cancellation/retry, four tutorial-local illustrations and save handler.
- `tests/test_first_level_minimal_batch.gd`: 48 checks, no assertion failures. Only the first level; later numbers are rejected inputs, not later scenes.
- Expected invalid-preview/scene fault-injection warnings remain distinct from assertions. The preview process also emitted the known ObjectDB exit warning; this batch does not claim clean shutdown or resolve its cause.
- No gameplay, world-ball size/centers, asset, level, price, upgrade, enemy time or reward change.

## Still requires real inspection

New-version Home text against wood; Prep labels and maximum-value spacing; Loading long error and buttons; tutorial readability/reopen/tween. Parent's real b990 Home single-scene, Prep 20+five-color and tutorial fourth-row corrections are limited evidence for b990 only, not this new typography.

Shared Pause/action-button skin/actual touch area, Settings slider hit area and return-to-caller are a separate in-progress repair, not fixed by this batch. Battle/Shop/outcome small-state text, true mobile input, natural full play, actual sound, world-ball profile/material, whole-scene fidelity and user confirmation remain open.
