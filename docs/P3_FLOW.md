# P3 scene flow and isolated QA

`scenes/play.tscn` uses `scripts/play.gd`. Rules remain the sole gameplay owner;
`save_service.gd` owns verified local progression. Board beads, projected carrier
paths and pickup FX retain the shared `BoardPlane`, generated bead material and
`ground_ant` presentation. Carriers interpolate by displayed path arc length,
without altering authoritative pickup/delivery times or inventory.

## Actual entry and progression

- Normal first load initializes level 1 and its tutorial. The single LET'S GO action or
  skipping with X/ESC saves the same completed flag. Merely opening it does
  not save completion or start the dragon.
- Normal startup reads the saved entrance and creates a fresh run there. It does
  not restore an in-progress clock, reservations, carriers, ammo or tool uses. A nonmodal FRESH ROUND notice explicitly explains this on existing-profile cold entry and clears on the first successful team.
- `ANT_RESCUE_PROFILE_DIR` injects the save directory. With no override the normal
  location is `user://ant-rescue`. Reading an existing healthy profile does not
  rewrite it. All integration tests use unique `/tmp/ant-rescue-*` directories.
- Default launch offers the three actual validation levels. The explicit `--campaign-drafts` launch offers 30 real candidate files in a separate profile and three-page selector; see CAMPAIGN_FLOW.md. Saved sequential unlocks gate both catalogs.
- Victory comes only from the final authoritative hit. The event immediately settles victory even when saving fails; a finite 1.60-second visual collapse then hides the dragon, without delaying the rule outcome. Completion must save
  successfully before Next appears. On failure the terminal result stays pending
  behind Retry Save. Level 3 saves unlock 4 for future content but offers no absent
  fourth level. Next writes the selected entrance before replacing the scene.
- Restart/leave Cancel and X/ESC preserve the live round. A confirmed entry or
  restart constructs a new run. Volume previews update the separate audio buses;
  both values persist on slider drag end or settings close, not every movement.
  Zero is mute, without an extra saved mute switch.
- Corruption blocks gameplay. Retry Load, explicit Restore Backup and a separate
  Reset Progress confirmation are available when the service allows recovery.
  Existing damaged bytes are preserved. Unsupported future schemas cannot be
  silently reset/downgraded. A missing/invalid level source creates a navigable
  technical-error shell with Retry and the actual level selector, never a fake
  board or an empty noninteractive window.

## Four tools

Icons remain independent, without an outer tray. They display lock or actual
remaining uses and disable unavailable/used actions. Normal unlock context is the
entry's level number: extra slot 3, shuffle 6, recall 9, scout 16. Existing
validation JSON files retain `production_level_number: null`.

- Extra slot creates exactly the sixth actual slot; all six fit the same canvas.
- Recall opens a paused target selector, requests a rules selection token and
  validates the displayed team ID. Cancel/close invalidates it without spending.
  Only genuinely recallable teams are shown, centered in rows of at most three;
  their buttons keep the original slot identity. With no team it gives a short
  nonmodal message. Success restores only undispatched remaining quota and leaves all current
  carriers and reservations independent. It resumes before the release cue.
- Scout takes an atomic snapshot and briefly outlines the suggested front and
  legal unreserved cells without selecting, reserving, advancing or pausing.
  Invalidated hints disappear; it is advice, not a guaranteed winning solution.
- Shuffle uses the bounded solver. Only a complete independently replayed timed
  winner may commit. Exhaustion/unproved results leave the exact game state and
  use unchanged and show nonmodal `USE KEPT` feedback.
- Only the drained `tool_used` event drives `fx.play_tool(..., true, ...)` and
  `audio_service.play_tool`. Scout maps to the audio service's `hint` cue. Opening
  a selector, cancellation, failure and repeated draining do not play release
  success effects. Slot effects use the upper-center anchor and current five/six
  quota protection rectangles, above rebuilt slot artwork but below modals.

## Manual graphical QA

From this project directory:

```sh
HOME=/tmp/ant-p3-home XDG_CACHE_HOME=/tmp/ant-p3-cache \
XDG_CONFIG_HOME=/tmp/ant-p3-config XDG_DATA_HOME=/tmp/ant-p3-data \
godot --path . --script tests/run_p3_ui_fixture.gd
```

This explicit QA launcher copies the real first level in memory, adds four
`unlock_level: 1` test definitions and chooses a unique isolated profile. It does
not edit any validation JSON or real profile. The printed `P3_QA_ONLY` line
identifies it as a test, not production progression. Click the four actual icons,
select a front before recalling, cancel/reopen recall, and inspect the sixth slot.
Shuffle may honestly fail if the finite search cannot prove that live position.

Append `-- --tiny-tools` for the separate small deterministic fixture used to
prove all four success routes rapidly. Its 18-bead board is test data, not a new
production level. The full first-level copied configuration is the default.

`--auto-replay` always allocates its own `/tmp/ant-rescue-replay-*` profile,
regardless of the environment's normal profile setting, and skips only that
fixture's tutorial. `--level=N` in normal play cannot bypass saved unlocks.
Automatic replay and screenshots are not human playtesting.

## Finite verification

```sh
export HOME=/tmp/ant-p3-home XDG_CACHE_HOME=/tmp/ant-p3-cache
export XDG_CONFIG_HOME=/tmp/ant-p3-config XDG_DATA_HOME=/tmp/ant-p3-data
godot --headless --path . --script tests/test_p3_flow.gd
godot --headless --path . --script tests/test_play_binding.gd
godot --headless --path . --script tests/test_play_input.gd

# Each command below launches a genuinely separate process.
export ANT_RESCUE_PROFILE_DIR=/tmp/ant-rescue-cli-$(date +%s)-$$
godot --headless --path . --script tests/test_play_profile_cli.gd -- --probe=seed
godot --headless --path . --script tests/test_play_profile_cli.gd -- --probe=restart
godot --headless --path . --script tests/test_play_profile_cli.gd -- \
  --probe=auto-isolation --auto-replay --level=3
ANT_RESCUE_PROFILE_DIR=/tmp/ant-rescue-locked-$(date +%s)-$$ \
godot --headless --path . --script tests/test_play_profile_cli.gd -- \
  --probe=locked-level --level=3
```

Reports: `reports/ui/p3-flow-report.json`, `play-binding-report.json`, and
`play-input-report.json`. The P3 suite includes actual viewport pointer routing
through all four icons and recall targets, one successful audio/FX cue per tool,
conservation, six-slot bounds, stale/cancel paths, bounded shuffle failure and
independent final-hit replay of its successful proof, settings/tutorial saves,
save-failure retry, sequential Next, recovery and invalid-level navigation.
The three-level binding suite remains a full authoritative automatic replay with
actual UI/audio/FX nodes, not evidence of natural human completion or audio
listening. Graphical capture and visual acceptance are separate stages.
