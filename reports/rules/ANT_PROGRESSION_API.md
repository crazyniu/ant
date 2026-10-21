# Single-ant progression service

Status: local Godot 4.6.3 service implementation and bounded headless verification, 2026-10-21. This is not UI, macOS, live ad SDK, economy-balance or 30-level acceptance.

## Files and isolation

- Service: `scripts/ant_progression.gd` (RefCounted, no autoload or dependency on legacy `save_service.gd`).
- Configuration: `data/ant-progression.json`, schema/economy version 1, profile `game2-ant-single-v1`.
- Construct with `Progression.new(profile_root)`. The service always appends `ant-single-v1/` to that root.
- Default primary: `user://ant-rescue/ant-single-v1/progression.json`.
- Same-directory backup: `progression.backup.json`; verified candidates use `.tmp`; damage is preserved as `.corrupt.<sha256>.json`.
- For an isolated test/auto-replay/candidate build, supply its isolated root. Do not pass the already-appended child directory.
- Neither legacy `save.json` nor game-one files are read or written. Main campaign completion/unlock authority stays with its existing service; do not interpret this economy ledger as a replacement catalog.

## Runtime call sequence

```gdscript
const Progression = preload("res://scripts/ant_progression.gd")
var progression = Progression.new(profile_root)
var loaded = progression.load_save()
# Only proceed with economy-backed gameplay when loaded.ok / loaded.state.ready.

var run_id = Progression.generate_run_id()
var started = progression.create_run(run_id, level_id, fast_seconds, normal_seconds)
# On success, started.run.loadout is a detached frozen snapshot for this entire run.
# Configure authoritative rules/tasks from this snapshot, not live shop state.

var saved = progression.settle_run(run_id, "won", elapsed_sim_seconds)
# If !saved.ok, show pending-save/retry. Do not claim credited reward or move on.
# Retry with the SAME run_id. Display saved.run.receipt only after saved.ok.
```

`create_run` requires per-level thresholds, with finite `0 < fast_seconds < normal_seconds`; there is no global fallback threshold. The three current level thresholds are supplied by the integrating caller. They must be calibrated from baseline-worker authoritative solves, not wall-clock capture duration. The run freezes thresholds, ant type, carry level and movement multiplier before gameplay starts. Persisting a running journal is not mid-round resume: restarting gameplay must use a new run ID and replay the level from its beginning.

`settle_run(run_id, outcome, elapsed_sim_seconds)` accepts `won`, `lost` or `cancelled`. The caller supplies time from the first successful dispatch to the actual final damage, excluding paused/background time and retaining identical simulation seconds at x1/x2. The service is not a combat authority and does not infer victory or elapsed time from wall clock. Settle failure/cancellation with zero or the actual nonnegative elapsed time. They add no points and never subtract the existing balance.

Receipt fields: `elapsed_sim_seconds`, `first_clear`, `base`, `time_bonus`, `total`. A first committed clear awards 100 plus 0–50; repeat clear 20 plus 0–10. Bonus is `floor(maximum * clamp((normal - elapsed) / (normal - fast), 0, 1))`. First-clear status and credit share one atomic commit. Same-outcome duplicate settlement returns the original receipt (`already_settled`), including after restart. Later callback timing cannot change it. Conflicting outcome or a changed level/threshold tuple under one run ID is rejected. ID generation uses 128 random bits; do not reuse run IDs for retries that actually start new gameplay.

## Shop, equipment and navigation

- `purchase(request_id, product_id)` supports `swift`, `level_2`, `level_3`, `level_4`. `worker` is a no-debit already-owned success.
- Use a stable unique request ID for one intended purchase and its retries, bound to the exact product. A new intentional product purchase needs a new ID. Upgrades name the target level, so repeated clicks cannot implicitly buy the next level.
- Swift: 500 points, type movement multiplier 1.20. Worker is initially owned, multiplier 1.00.
- Shared carry levels 2/3/4 cost 100/150/250 and have multipliers 1.05/1.10/1.15. Prerequisites are sequential. All colors and types share this one level.
- Final movement multiplier is type times current-level multiplier, capped at 1.50. Swift level 4 is 1.38, not a cumulative product of all level bonuses. Pick-up, unloading, cannon speed and concurrent-ant count are not modified by this service.
- `equip(type_id)` only accepts owned types. Unlocking does not silently equip. Equipment changes do not alter previously created runs.
- `set_navigation({"region_id": "forest", "scroll_y": 624.5, "selected_level": 3})` atomically saves map return position. Scroll is finite/nonnegative; selected level is an integer 1–30. Defaults: empty region, scroll 0, level 1. The UI remains responsible for catalog availability and its actual region/scroll limits.
- `get_run(run_id)` returns a detached persisted run snapshot, or `{}` if absent. It is a view, not a reload operation.

Ordinary mutations return `{ok, reason, state}`. Run creation/settlement add `run_id` and `run`; successful purchase and exact purchase retries include `transaction` (`product_id`, `cost`). Failed writes never expose candidate balances, ownership, levels or navigation as committed.

`get_view_state()` provides `ready`, `reason`, `balance` and alias `points`, `owned_types`, `equipped_type`, `level` and alias `carry_level`, `type_multipliers`, `level_multiplier`, current `loadout`, `completed_levels`, `navigation`, `shop`, `ad_available`, `ad_reason`, and recovery flags. Each shop row includes actual product ID, price, owned/equipped flags, multiplier and purchase availability. All returned dictionaries/arrays are detached copies.

Common action failures include `insufficient_points`, `type_not_owned`, `level_prerequisite`, `product_not_found`, `request_id_conflict`, `run_id_conflict`, `run_not_found`, `run_outcome_conflict`, invalid time/threshold/identity, and storage errors. No-debit repeat successes include `already_owned`, `already_purchased`, `already_created`, `already_settled`, `unchanged`.

## Advertising boundary

`rewarded_ad_status(run_id)` always returns `available: false`, `reason: ad_sdk_unavailable`, `additional_points: 0`. `request_rewarded_ad(run_id)` and `claim_rewarded_ad(run_id, reward_id, provider_receipt)` always fail with `ad_sdk_unavailable` and make no write. There is no simulated rewarded-ad provider, injectable success callback, debug claim path or fake credited reward in production code. Even a dictionary claiming `verified` or `completed` is rejected.

A future real SDK integration needs separately reviewed provider validation and atomic, persistent run-ID/reward-ID deduplication before any success path is added. This build does not claim that an ad doubles a reward or that ad integration has been accepted. Base reward remains available independently of advertising.

## Persistence and recovery contract

Like the existing local save implementation, this is a synchronous single-writer service. Each mutation reloads externally changed primary bytes, checks again before commit, writes and flushes a candidate, reads it back byte-for-byte, preserves the previous committed record as backup, then atomically renames the candidate over primary without first unlinking primary. Memory changes only after successful primary rename. Full-precision JSON preserves simulation-time/threshold floats across restart. One process/main-thread writer is the supported model; this is not an interprocess locking protocol or a tested guarantee against abrupt OS/power failure.

Load validates schema/economy/profile identity, ledger totals, ownership/level purchases, first-clear mapping, receipt calculation and frozen loadouts. JSON numeric fields are normalized after validation. Changing economy rules requires a versioned migration rather than editing old-ledger interpretation in place. No migration from legacy/game-one profiles is performed.

Corruption and missing-primary remnants block ordinary writes; damaged bytes are preserved before recovery. Future versions block downgrade/reset. `recover_from_backup()` is explicit and may restore the previous committed transaction, not the newest damaged transaction. `recover_with_defaults(true)` requires explicit reset confirmation and preserves extant recovery evidence. Neither recovery method may silently replace an already-valid primary. UI recovery actions should explain their consequence.

The `test_fail_stage` variable injects only storage faults; it does not grant currency or advertising capability. Supported stages: `write_temp`, `verify_temp`, `write_backup`, `verify_backup`, `replace_backup`, `replace_primary`, plus quarantine failure stages inherited from the local-save convention.

## Verified scope

`tests/test_ant_progression.gd` runs a finite 1,062-assertion suite, with all passing under Godot 4.6.3. Machine-readable output: `reports/rules/ant-progression-tests.json`.

Coverage: clean defaults and profile isolation; exact configured costs/multipliers; first/repeat threshold endpoints, clamp and floor; failure/cancellation; same-run and same-purchase deduplication across restart; ownership and upgrade prerequisites; frozen run loadouts; detached views; durable navigation; six injected I/O fault stages over five transaction categories; byte-exact rollback and retry; stale in-process readers; fake-ad rejection; corruption preservation; explicit backup/default recovery; missing-primary/temp handling; future schema guards; inconsistent ledger rejection.

```sh
TEST_PROFILE_DIR="$(mktemp -d)"
XDG_DATA_HOME="$TEST_PROFILE_DIR/data" \
XDG_CACHE_HOME="$TEST_PROFILE_DIR/cache" \
XDG_CONFIG_HOME="$TEST_PROFILE_DIR/config" \
godot --headless --path . --script tests/test_ant_progression.gd
```

Fixtures are unique under `/tmp`; no player profile is modified. Initial engine startup without writable XDG directories was an environment failure; the bounded test command above uses writable isolated directories. No UI/play/rules/startup files, Mac, Git history, remote branch, deployment or external design document were changed by this service work.
