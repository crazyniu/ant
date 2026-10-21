# Bounded complete-journey capture

`tests/capture_complete_journey.gd` is an **automated pointer-input demonstration**, not a human playtest, graphical acceptance, or listening acceptance. It loads the real 30-level candidate at `campaign-01`, uses a genuinely fresh `/tmp/ant-rescue-complete-journey-*` profile, and never seeds progression.

## Single graphical recording

Run only after the shared graphical desktop is available. Choose a new external evidence directory. Keep the Godot window focused throughout; a real focus loss correctly pauses the game and can fail the bounded demonstration.

```sh
# Run from the unpacked project directory containing project.godot.
PROJECT="$PWD"
OUT="$(dirname "$PROJECT")/ant-rescue-evidence/complete-journey"
mkdir -p "$OUT" /tmp/ant-rescue-journey-home/.local/share /tmp/ant-rescue-journey-home/.cache
HOME=/tmp/ant-rescue-journey-home \
XDG_DATA_HOME=/tmp/ant-rescue-journey-home/.local/share \
XDG_CACHE_HOME=/tmp/ant-rescue-journey-home/.cache \
ANT_RESCUE_EVIDENCE_DIR="$OUT" \
godot --path "$PROJECT" --rendering-method gl_compatibility \
  --fixed-fps 24 --max-fps 24 --write-movie "$OUT/complete-journey.avi" \
  -s tests/capture_complete_journey.gd
```

Use the existing verified cloud graphical display; this command does not provision or claim ownership of a desktop. The explicit temporary HOME/XDG directories prevent Godot log/cache creation in the real account home. Do not add `--auto-replay` or `--capture-play`: the harness refuses those bypass flags. The genuine profile is retained in `/tmp` for evidence inspection, never copied into the player's profile.

Duration depends on the current authored transport schedule and death presentation. Actual screenshot draw waits may add frames. Success exits automatically; per-step bounds and an independent 45-second engine-time watchdog bound failures. The reported duration is engine process time, not encoding wall time. Inspect finalized AVI duration/frame count and source hashes; do not reuse a prior recording as evidence for changed motion.

`--max-fps 24` requests real-time pacing so the unchanged audio service's wall-clock cooldowns stay closer to the movie timeline. MovieWriter may still run differently from wall time. Record observed elapsed wall time externally if needed. No audio cooldown or gameplay clock is patched. Every emitted accepted/dropped cue is logged; a headless fast run is **not** evidence of final listening quality.

## Focused logic-only verification

```sh
mkdir -p /tmp/ant-rescue-journey-logic
HOME=/tmp/ant-rescue-journey-home \
XDG_DATA_HOME=/tmp/ant-rescue-journey-home/.local/share \
XDG_CACHE_HOME=/tmp/ant-rescue-journey-home/.cache \
ANT_RESCUE_EVIDENCE_DIR=/tmp/ant-rescue-journey-logic \
godot --headless --path "$PROJECT" --fixed-fps 24 \
  -s tests/capture_complete_journey.gd -- --logic-only
```

Headless mode never waits for `RenderingServer.frame_post_draw`, never saves screenshots, and marks graphical/listening validation as not run. This optional complete-journey harness is separate from the bounded current-motion verification in `tests/test_motion_binding.gd` and `tests/capture_motion_review.gd`. A historical complete-journey capture is not a current-motion pass.

## Real UI route

Tutorial → pause → settings → pointer-drag music to zero → restore music 65 → sound 60 → settings X → pause Continue → seven authored legal front-team selections → naturally simulated carriers, deliveries, shot and final hit → authored 1.60-second weighted collapse → real saved result → Next Level → real `campaign-02` → pause → leave confirmation → selector showing only levels 1 and 2 unlocked.

Only the real scene's normal `_process` updates simulation and presentation. The harness never calls `rules.update_us`, `select_front`, `auto_replay`, result presentation, save completion, or an unlock override. It never modifies level configuration, resources, or player data. Input is `InputEventMouseButton` and `InputEventMouseMotion` delivered through the viewport. The seven selections check both current front identity and genuine success. If a quantized boundary needs additional time, the harness waits for the actual free slot and transition state; that delay is recorded.

## External evidence

- `complete-journey-report.json`: outcome, bounds, exact input timestamps, all cue played/dropped signals, 62-node real first board and 80-node real second board checkpoints, terminal rules snapshot, genuine save path/hash, conservation, collapse and unlock checks.
- `complete-journey-state-observations.json`: read-only per-frame task and projectile observations. Scheduled event times come from actual tasks/projectiles. This is explicitly not an intercepted raw event stream.
- `complete-journey-source-sha256.json`: source and asset hashes for the recorded version.
- Eight 1440×2560 PNGs: tutorial, settings, initial first level, real shot, collapse midframe, natural result, next level, and genuine unlocked selector. Every PNG hash is in the report.
- `complete-journey.avi`: one uncut MovieWriter recording, created only by the graphical command.

The harness does not cut or retime footage, fabricate a win, upload files, modify Notion, or publish source. Manual audio/visual acceptance remains separate.
