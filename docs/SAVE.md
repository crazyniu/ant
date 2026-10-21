# Local save and progression service

Implements the current PRD §6.3 and §8 in `scripts/save_service.gd`. This is an
isolated synchronous service, not an autoload or a simulation owner. The game
owns victory detection, run IDs, scene changes, audio application, dialogs, and
available content. No frame state, economy, server, or account data is saved.

## Construction and API

```gdscript
const SaveService = preload("res://scripts/save_service.gd")
var saves = SaveService.new(
    "user://ant-rescue",
    ["validation-01", "validation-02", "validation-03"],
    30
)
var result: Dictionary = saves.load_save()
```

The constructor takes an injectable **directory**, an ordered catalog of actual
loadable level IDs, and a campaign capacity (default 30, maximum 30). The three
default IDs match the current level JSON files. Catalog position is the stable,
one-based progression number. Append newly made content; do not reorder or reuse
IDs. A smaller available catalog may read a full-campaign save without truncating
historical completions or unlocks. Changing existing identities requires an
explicit migration, not a silent remap.

All action methods return `{ok: bool, reason: String, state: Dictionary}`.
Always check `ok` before reporting a save or allowing newly unlocked navigation.
State is a detached deep copy; changing it does not change the service.

- `load_save()` reads and validates first. Only a genuinely fresh absent record
  initializes and persists defaults. A valid existing save is never rewritten
  merely by reading it.
- `get_view_state()` returns the current safe view without writing.
- `mark_complete(level_id: String, content_version: String)` accepts a playable,
  unlocked level and a nonblank explicit content version. It records each exact
  `(level_id, content_version)` once. Repeating it returns `already_completed`
  without touching either file. Replaying an older level or another content
  version never revokes historical unlocks or advances more than the sequential
  next level. Call only after the authoritative final-hit victory event.
- `set_current_entrance(level_id: String)` selects an available unlocked level.
  It does not mark it complete. Persist this before scene replacement; an error
  must not be mistaken for a saved entrance.
- `set_volumes(music, sfx)` atomically saves both slider percentages, independently
  rounded and clamped to 0–100. Zero means mute; there is no separate persisted
  mute bit. Non-numeric values, NaN, and infinity fail without writing. Preview
  slider movement through audio, then commit on drag end or settings close,
  rather than writing on every `value_changed` signal.
- `set_tutorial_completed(completed: bool = true)` persists the completed/skipped
  flag. Opening the tutorial is not itself completion.
- `recover_from_backup()` is an explicit UI recovery action, only available after
  a recoverable load error. It does not automatically roll back a healthy save.
- `recover_with_defaults(confirm_progress_reset: bool = false)` requires the
  caller to pass `true` only after an explicit user reset choice. It preserves
  existing evidence first. Unsupported schemas cannot be reset or downgraded
  through this API, even with that flag.

Every normal mutation reads before writing, including when called before the
first explicit `load_save()`. It refreshes an out-of-date instance from disk before
applying its change. Use one owner on the main thread: this is not an interprocess
locking protocol. Concurrent writer processes are not supported.

## Safe view and UI integration

The view includes persisted fields plus:

- `ready`, `reason`, `recovery_required`, `recovery_allowed` and
  `corrupt_backup_path` for load/recovery status.
- `total_capacity`, `available_level_count`, and `available_unlocked`.
- `levels`: **only the supplied actual catalog**, with ID, number, unlocked and
  completed flags. Unready/corrupt states expose no playable unlocks.
- `current_entrance_available` and `resume_level_id`. The latter is the persisted
  entrance when loadable, or the highest available unlocked level in a smaller
  build. This safe fallback does not rewrite the original entrance.
- `next_level_id`: empty unless the current entrance is completed and the next
  level is both saved as unlocked and actually available. Completing validation
  level 3 records highest unlock 4 while exposing just three actual levels and
  no Next button. Completing production level 30 never unlocks 31.
- `restart_mode: "level_start"` and `resumes_in_progress_run: false`.

Starting the app constructs a fresh simulation from `resume_level_id`; tell the
player the level restarts. Do not imply restoration of ant tasks, reservations,
ammo, projectiles, dragon distance, cooldown, or elapsed time. Live background
pause remains the game controller's responsibility.

On completion-write failure, keep the victory view and offer Retry Save; do not
advance or say “Saved.” The previous committed memory and primary record remain
unchanged, so retrying the same level/version is safe. A saved current entrance
does not automatically move forward on victory: explicit Next selects it.

On corruption, show a technical-error/recovery screen, not player defeat. Offer
backup restoration, retry read, and safe return. Offer a separately confirmed
fresh-start choice only where intended. Display the relevant error, but do not
show internal filesystem paths as normal player-facing text.

## Schema 1

The JSON contains exactly these fields:

```json
{
  "schema_version": 1,
  "completed_levels": {
    "validation-01": {"level_number": 1, "content_versions": ["v1"]}
  },
  "highest_unlocked": 2,
  "current_entrance": {"level_id": "validation-01", "level_number": 1},
  "tutorial_completed": true,
  "music_volume": 70,
  "sfx_volume": 70
}
```

Content versions are supplied by the caller, not inferred from a schema number,
wall-clock timestamp, or art preview. Every saved completion retains its content
versions. This preserves replay provenance but does not ship old level assets;
the content loader must ensure the chosen version has the intended board,
queue, and armor order. The service does not generate or randomize levels.

Validation rejects broken JSON, unknown fields, invalid shapes/types, missing
required fields, impossible or nonsequential unlocks, duplicate progression
numbers/versions, mismatched known catalog IDs and locked entrances. Finite
numeric audio values are safely clamped on load without auto-writing. Unsupported
schema versions produce `unsupported_schema` and remain byte-exact and
read-only; no speculative migrations run.

## Atomic commit and recovery files

All files live in the injected directory:

1. Serialize a private candidate to `save.json.tmp`; flush, close, and read it
   back to verify exact bytes.
2. Write and verify the previous committed bytes to `save.backup.json.tmp`.
   Atomically rename that file over `save.backup.json`. Initial creation uses
   the candidate as the first valid backup.
3. Atomically rename `save.json.tmp` over `save.json`, **without unlinking the
   original first**.
4. Only a successful primary rename publishes the candidate in memory.

A write, verification, or rename failure leaves the primary and committed
in-memory record unchanged. Temporary files are uncommitted evidence and never
silently promoted. A restart reads a valid primary even if a previous attempt
left a temporary file. A missing primary with a backup, temporary file, preserved
corrupt file, or known in-memory history requires explicit recovery, not defaults.

Corrupt primary bytes are copied, verified and preserved as
`save.json.corrupt.<sha256>.json` before recovery is allowed. The damaged primary
also stays untouched until explicit recovery commits. Failure to preserve the
damaged data yields `corrupt_backup_failed` and blocks replacement. Recovery
keeps the last valid backup instead of copying a corrupt primary over it. A
confirmed reset preserves extant backups and temporaries as well.

This protects against partial writes and failures/process interruption around
the tested commit boundaries. Godot's portable `flush`/rename API does not expose
directory fsync here; this is **not** a claim of unconditional hardware
power-loss durability. The backup can legitimately be one committed update old.
The service does not delete recovery evidence automatically.

## Verification

```sh
XDG_CACHE_HOME=/tmp/ant-cache XDG_CONFIG_HOME=/tmp/ant-config \
XDG_DATA_HOME=/tmp/ant-data godot --headless --path . --script tests/test_save.gd
```

The finite test suite creates unique isolated directories under `/tmp` and
removes only its own fixtures. It covers fresh load, process-style recreation,
load before write, stale-instance refresh, all 30 progression positions,
three-level visibility, replay/version idempotence, zero-mute/clamping,
candidate isolation, last-valid backup bytes, six injected commit-failure
boundaries, retry, corruption preservation, explicit backup/default recovery,
future schema blocking, malformed structures, missing primary/orphan evidence,
and filesystem failure. `test_fail_stage` is empty in production; tests can set
it or override `_should_fail(stage)` for deterministic fault injection.

Run evidence is emitted as JSON to stdout. These service checks do not claim
game-screen integration, natural human playtesting, actual audio listening,
platform-specific macOS/mobile execution, or physical power-cut testing.
