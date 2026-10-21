# P3 four conserving tool rules

Validated on 2026-10-21 with Godot 4.6.3, against the current Ant Rescue PRD §§4–5. API version: **1.1.0**.

## Results

- **291 targeted tool assertions PASS**, zero failures and no Godot parse/script errors in the final output.
- **35,536 existing P2 assertions PASS** after the additive tool changes. Three no-tool validation replays retain their exact timings and ×1/×2, float/integer, coarse/fine and hit/contact-boundary equivalence.
- Extra slot changes five to six, consumes only on success, clears genuine full-slot blockage, and resets on retry.
- Recall restores only remaining undispatched quota to the source front, including reappearing empty columns. Existing outbound reservations and returning tasks continue without duplication. A shuffled team's source is its actual dispatch column.
- Recall selection is intentionally token-authorized while paused. Cancellation costs nothing. Commit never advances/resumes time. Stale tokens, retries and recoverable-error pauses cannot accidentally authorize it.
- Scout returns an atomic valid front plus exposed unreserved cells and armor/inventory/cooldown relationship. It never removes beads or selects a team; no valid suggestion costs nothing.
- Shuffle changes only waiting order. Exact copied live state drives a complete timed search followed by an independent replay. Too-late dragon contact, unverified/illegal/instant-click plans, unchanged layouts and exhausted search budgets preserve the exact original state and use count.
- Frozen-state cases cover current work, outbound/returning tasks, reservations, in-flight projectile, cooldown, stock of a noncurrent color, current elapsed time, remaining dragon distance, speed ×2 and fractional time.
- Final-hit/contact exact ties pass; contact 1µs earlier rejects the shuffle proof without consumption.

## Authored validation levels

The tool suite enables all four tools only in its copied test configs (`production_level_number=16`). Shipped independent validation metadata is not turned into production progression.

| Level | Verified shuffled final hit | Search + verification steps |
|---|---:|---:|
| validation-01 | 40.395 s | 1,390 |
| validation-02 | 50.295 s | 1,652 |
| validation-03 | 75.180 s | 1,187 |

Every accepted result has a timestamped legal input sequence and final hit time in `test-report.json`. The test independently replays each returned certificate on another cloned rules instance. These are automated playbacks, **not human playtesting** and not guarantees for different later player choices.

## Reproduce

From the project directory, with writable temporary Godot directories:

```sh
HOME=/tmp/ant-rescue-rules-home XDG_DATA_HOME=/tmp/ant-rescue-rules-data \
XDG_CACHE_HOME=/tmp/ant-rescue-rules-cache \
godot --headless --path . --script tests/test_tools.gd

HOME=/tmp/ant-rescue-rules-home XDG_DATA_HOME=/tmp/ant-rescue-rules-data \
XDG_CACHE_HOME=/tmp/ant-rescue-rules-cache \
godot --headless --path . --script tests/test_rules.gd
```

API integration and all failure/selection contracts: `../rules/API.md`.

## Scope boundaries

No `play.gd`, `main.gd`, audio or FX files changed in this batch. Production tool UI, hint highlighting duration, recall modal rendering, progression/save integration, editor, 30-level delivery, audio audition, human difficulty/visual acceptance, Mac and mobile execution are **not established by this report**. Default unlock levels remain tentative 3/6/9/16; replaying earlier levels with persistently unlocked tools needs the progression layer's explicit unlock context decision.

The shuffle solver is intentionally bounded and non-exhaustive. Its work-step budget is deterministic, not a wall-clock measurement. Failure to find a proof never claims the state is impossible and never consumes a use.
