# First-level mobile modal controls

2026-10-22. Isolated implementation based on `b9907d9`. This report covers only
shared modals reachable from the approved first level. It is not visual acceptance,
a new level, merge, deployment, or approval to close the tracking Issue.

## Changes

- Shared text actions use the existing `game/primary` / `game/secondary` painted
  enamel-and-gold skins, not the thin list-row frame. Bounds are **560 × 118** logical
  units; text is **38 px**. At 360-wide scale, the hit height is **45.2 px**.
- Pause's four actions start at y=724, 864, 1004, 1144. The panel is
  (130, 480, 680, 830). The single Home target is now 120 × 120 and remains above
  Continue with a 24-unit gap. No extra controls or skills were added.
- Restart, Leave, running-round Map/Home confirmation, save/load recovery, reset
  confirmation, and startup recovery were reflowed as groups. Warnings are 38 px;
  subordinate recovery details are 32 px and wrap within measured bounds. No
  Home/Prep/tutorial/Loading typography or result/shop artwork was reworked here.
- Shared Close hit area is 120 × 120 around the unchanged 80 × 80 painted icon.
  All new static layout positions are assigned before scene attachment so modal
  motion caches the intended final coordinates.
- Settings sliders have **355 × 118** hit areas centered on their original track:
  y=683.5 / 816.5. Their 349 × 57 painted tracks, 49 × 49 knob, 306-unit x range,
  endpoint/zero-mute rules and persistence behavior stay unchanged. The two hit
  rectangles have a 15-unit vertical gap.
- Gear → Settings → X/Back returns directly to the same running game. Pause →
  Settings → X/Back returns to Pause. The original caller survives repeated save
  failure, recovery X/Back, and successful retry. Failure does not unfreeze or leave
  the game. Startup Settings still closes to its original Prep/Map screen.
- A focused boundary probe found that an immediate slider edit during the 0.22s
  entrance previously let the reveal tween restore the old knob position. The tiny
  `UiMotion.set_live_position` helper cancels that obsolete positional tween and
  updates its rest position, without changing audio or slider mapping.

## Reachable group inventory

| Owner | Existing groups checked |
| --- | --- |
| main shared by play | Pause (Continue, Settings, Level Select, Restart), Settings, Close |
| play | Restart, Leave, running-round level-select confirmation, Home confirmation, safe restart/error |
| play recovery | Save error for victory/settings/tutorial/entrance/default; load recovery; reset confirmation |
| startup recovery | Profile load/backup recovery; settings/navigation/other save errors |
| startup Settings | Preparation and map origins; existing failure retry checked separately |

Legacy gallery-only main methods, campaign pages, later levels, outcome artwork and
shop artwork were not newly developed or accepted. The first-level tutorial itself
was not edited; its existing explicit 128-unit Close override should be visually
rechecked when combining this shared base Close change with the parallel tutorial work.

## Verification

- `test_first_level_mobile_modals.gd`: **1399 / 1399 passed**. The JSON includes
  measured panel, button and label rectangles for every adjusted group, actual font
  metrics/line counts, original skin regions and color checks. Also covers pause
  Continue/confirmation Cancel, Settings origins × X/Back × save success/failure,
  repeated retry, independent disk reload, and unchanged run count/points.
- Synthetic viewport clicks at the expanded top/bottom slider bands verify 0/50/100
  values and knob mapping. Immediate edits during entrance verify no old-value snapback.
- `test_ant_settings_recovery.gd`: **20 / 20 passed**.
- `test_ant_navigation_save_boundary.gd`: **20 / 20 passed**.
- `git diff --check`: passed. Godot **4.6.3**, headless. Temporary isolated profiles only.
  An intermittent ObjectDB shutdown leak warning appeared in settings recovery;
  it did not produce an assertion or runtime script failure in the final run.

Reproduce from this checkout with a writable temporary Godot user/cache directory:

```sh
mkdir -p /tmp/ant-modal-godot-home/{cache,config,data} reports/flow
export HOME=/tmp/ant-modal-godot-home
export XDG_CACHE_HOME=$HOME/cache XDG_CONFIG_HOME=$HOME/config XDG_DATA_HOME=$HOME/data
godot --headless --editor --path . --import --quit
godot --headless --path . --script tests/test_first_level_mobile_modals.gd
godot --headless --path . --script tests/test_ant_settings_recovery.gd
godot --headless --path . --script tests/test_ant_navigation_save_boundary.gd
```

## Required parent/native recheck

1. At native 1440 × 2560 and a 360-wide phone-proportioned window: inspect Pause's
   four painted buttons and 38px labels, Home-to-Continue spacing, complete gold
   borders, panel margins, title/Close spacing, and press/release animation.
2. Inspect Restart, Leave/Home, save and load recovery at the same sizes: readable
   38/32px lines, full labels, no clipping/overlap, and complete panel bounds. The
   headless text-fit checks are not proof of final perceived visual quality.
3. From an active first-level game: Gear → Settings → X and Android-style Back;
   confirm no extra Pause page, the same round resumes, and Pause → Settings →
   X/Back instead stays paused. Recheck repeated open/close and failure retry.
4. Drag both sliders in their enlarged top/bottom bands, including immediately on
   entrance; verify the track art stays in place, the knob never snaps to its old
   value, the sliders do not steal each other's input, and zero is silent. Real
   touch and human listening remain untested.
5. Confirm Prep/Map Settings return and the parallel tutorial Close alignment.

No GUI, screenshot, GL rendering, native input, actual touch device, sound quality,
full multi-level suite, or user visual acceptance is claimed by this report.

Integration follow-up: tutorial Close is finalized before reveal animation; Pause
Level Select now uses one guarded Leave confirmation. See
`../mobile-navigation-review.md` for the subsequent combined checks.
