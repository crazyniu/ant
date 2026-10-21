# RescueRules API 1.2.0

This is the authoritative rule contract implemented by scripts/rescue_rules.gd. It is independent of the visual-only 1,022-bead gallery fixture. Current runtime and acceptance scope are summarized in docs/PUBLIC_VERIFICATION.md.

## Integration boundary

Load `res://scripts/rescue_rules.gd` and instantiate its `RefCounted` class. No scene, animation, save system, signal connection or randomness is required. Only this module writes gameplay state. Keep `main.gd` drawing code as a consumer; never debit inventory or finish a run from animation/tween callbacks.

1. Parse a `data/levels/validation-0N.json` file and call `load_level(config)`. It returns `false` with `validation_errors` and a `load_error` event on invalid data. `snapshot()` is safe even on malformed data.
2. Render the actual grid, columns, slots, armor order and all six inventories from that loaded configuration. Do not use visual-fixture quota counts to drive the rules.
3. The front button calls `select_front(column_id, expected_team_id)`. Use stable string column IDs and the currently displayed front team's ID. The expected ID prevents a stale second click from selecting a newly advanced team. Integer original column indices are also accepted; empty columns keep stable IDs, even if the view hides and recenters them.
4. Feed real elapsed seconds to `update(delta)` exactly once per active frame. Do **not** multiply `delta` by the UI speed separately. `set_speed(1 or 2)` applies to every simulation subsystem. For exact replays, `update_us(integer_real_microseconds)` is available.
5. Consume `drain_events()` once and update visuals/audio from those events. Read `snapshot()` for current state, or read fields without mutating them. Snapshot dictionaries/arrays are deep copies.
6. Call `set_paused(true)` for pause/settings/selection modals and focus loss. Pause freezes all simulated time and resets speed to ×1. Resume is explicit `set_paused(false)`; opening observation before first accepted team selection has no threat time.
7. `restart()` reloads the same configuration and increments `run_id`. Each load or restart increments it. A view callback must verify `accepts_callback(captured_run_id)` before showing a delayed effect. The rule layer has no callback-driven settlement API.

### Return/state contract

`select_front` returns `{ok, team_id, slot, run_id}` or `{ok:false, reason}`. Rejected input mutates nothing. Reasons: `simulation_frozen`, `unknown_column`, `empty_column`, `not_front_or_stale_input`, `slots_full`.

States: `unloaded`, `load_error`, `ready`, `running`, `victory`, `defeat`. A recoverable internal transport error retains `running` but sets `paused=true`, emits `recoverable_error`, and leaves inventory untouched. Present restart/recovery, not a false win; do not simply hide the error and continue.

The first accepted team selection starts the dragon, including when that team must wait for its color. The first ant can dispatch at simulation time zero. Later selections cannot reset the global dispatch interval, even if earlier quota-one teams released their slots immediately.

Exactly five starting slots are present. A slot is `null` or a team with `id`, `color`, original `quota`, remaining quota `remaining`, stable `source_column`, and `work_state`. Work states distinguish `waiting_target` from `waiting_capacity` and `working`. `blocked=true` requires all slots occupied and no possible dispatch, in-flight transport, in-flight shot, or stocked current-color future shot. It is a prompt, never a separate loss condition.

## Times, transport and ordering

All authoritative time is integer microseconds (`TIMEBASE=1_000_000`). Duration parameters are converted once per scheduling decision; travel durations round up to a microsecond. Fractional frame microseconds carry across `update(float)`. Dragon position is evaluated from a simulation-time anchor, not accumulated per render frame.

At the same timestamp: scheduled projectile hit → dragon contact → due pickup/delivery in stable task-ID order → one dispatch opportunity → auto-fire. A final hit on the exact contact timestamp wins. A nonfinal hit applies its finite knockback before contact is reconsidered. Contact even 1µs earlier ends the run, including inside one oversized `update` call; later hits do not execute. A delivery or newly fired shot on a contact timestamp cannot prevent loss.

Transport tasks retain their own task ID, team ID and run ID after their original slot is reused. `path` is a list of integer `[x,y]` cells, beginning at `(width // 2, height)` on the bottom exterior ring and ending at the bead. The ring is `x=-1..width`, `y=-1..height`; it connects all four board edges. Every intermediate in-board cell was empty at dispatch. Only the endpoint may be occupied. Use path interpolation over `depart_us..pickup_us`, hold at the endpoint during `pickup_us..return_depart_us`, then reverse it over `return_depart_us..delivery_us`. `leg_duration_us` is the same authoritative travel duration on both legs. Reserved beads remain visible and blocking until `bead_picked_up`; return transport is safe because obstacles only disappear.

Optional `parameters.transport_min_leg_sec` and `parameters.pickup_pause_sec` must be numeric, finite and nonnegative; omitted values default to zero for legacy fixtures. Current 33 authored configurations and new editor/generator defaults use 0.55s minimum per leg, 0.16s pickup hold and 14 cells/s. Travel is `ceil(max(path_distance / speed, minimum_leg) × 1_000_000)`, at least one microsecond. Pickup is exactly arrival/removal; return departure is pickup plus hold; delivery is return departure plus that same travel duration. During the hold the task is already `returning`, carries one conserved bead, and provides no inventory. Pause and ×2 apply to all of these simulation times. No animation callback delays or settles an event.

An atomic reservation and quota decrement emits two informational events at the same timestamp (`target_reserved`, `ant_dispatched`). Do not debit anything a second time while consuming either event. Quota zero releases the slot immediately, not when a transport ends.

## Events

Every event includes `type`, `time_us`, derived `time_sec`, `run_id`, and monotonically increasing `sequence` within that run. Task/projectile `id` is separate from `sequence`.

- `level_loaded`: level ID and API version.
- `load_error`: validation error array.
- `team_selected`: team ID, color, remaining quota, slot, source column.
- `dragon_started`: first accepted selection.
- `target_reserved`, `ant_dispatched`: complete transport metadata and route; dispatch adds `team_remaining`.
- `slot_released`: slot and former team identity. Still-in-flight tasks remain independent.
- `bead_picked_up`: task metadata with returning stage; now remove the board bead in the view.
- `bead_delivered`: task metadata; same-color inventory was credited exactly once. A following fire at the same timestamp may already debit it, so use the event stream for effects and final snapshot for numeric labels.
- `team_work_state`, `blocked_changed`: waiting/capacity/no-progress presentation.
- `cannon_fired`: projectile ID, locked armor ID, color, amount, `fire_us`, `hit_us`. Ammo is already debited. Cooldown begins at `fire_us`.
- `armor_broken`: projectile metadata plus `dragon_before`, `dragon_after`, `applied_knockback`. Now change armor presentation, not at firing.
- `armor_changed`: next armor object and index.
- `victory`: only final armor hit. `defeat`: only dragon contact. Terminal state freezes immediately. Persist/unlock later in the separately implemented save layer, once per run.
- `pause_changed`, `speed_changed`: control-state presentation.
- `recoverable_error`: explanation and recovery recommendation; simulation is paused, no free ammo is fabricated.

`inventory` is unbounded, separate by color, and never expires. An armor can have only one in-flight shot. A later armor of the same color can use surplus inventory. `armors[armor_index]` is valid only when `armor_index < armors.size()`; victory increments it to the array size.

`conservation_errors()` validates board + picked/returning + delivered, inventory + spent, and candidates/slots + dispatched for every color. Reservations are a subset of board, not an extra quantity. Fired ammo counts as spent while the projectile is in flight; hit does not spend again.

## Four conserving tools (P3 rule layer)

`request_tool(tool_id: String, payload: Dictionary = {})` returns `{ok, consumed, ...}`. Failure always has `ok=false`, `consumed=false`, a specific `reason`, and does not emit `tool_used`. Success spends the tool's one use and emits exactly one `tool_used` with `tool_id`, `remaining=0`, and `result`. Only ready/running states accept tools; terminal/load-error/recoverable-transport-error states reject them. Normal paused input is rejected, except the deliberate recall-selection flow below.

`tool_states()` and `snapshot().tools` expose normalized definitions, `unlocked`, `used`, `remaining`, and `implementation="RULES_IMPLEMENTED"`. The four default IDs and tentative unlock levels are `extra_slot:3`, `shuffle:6`, `recall:9`, `scout:16`. An explicit `config.tools` array may override unlock levels or restrict enabled tools, but each configured tool must have exactly one use per level. Unknown/duplicate IDs and malformed configuration reject the level. Unlock context is `production_level_number`, falling back to `level_number`, then 1; the independent validation fixtures with a null production number therefore do not silently unlock production tools. Progression/save integration must provide the intended level context. Loading/restarting clears uses and resets to five slots.

- `extra_slot`: no payload. Adds precisely slot index 5, taking five slots to six. Returns `slot`, `slot_count`. A prior use or an already-added slot fails without consumption. Adding the slot can clear the full-slot blocked presentation but never dispatches a team or advances time.
- `recall`: payload `{slot:int, expected_team_id?:String}`. Returns `team_id`, `remaining_quota`, `column_id`, `reveal_column`, `slot`. Only positive **undispatched** remaining quota returns to that team's source column front. Empty source columns retain their stable IDs and become visible again when `reveal_column=true`. `slot_released` carries `reason="recall"`. All existing tasks, reservations, stock and already-debited dispatched counts remain intact. After shuffle, source means the actual column the team was selected from, not its old pre-shuffle position. Supplying the displayed expected ID guards stale modal selection.
- `scout`: no payload, atomic at request time. Requires a free slot and at least one front team with a currently exposed, unreserved same-color target. Returns `column_id`, `team_id`, `color`, `remaining_quota`, all legal `exposed_cell_ids`, `suggested_at_us`, `run_id`; and `current_armor`, `armor_inventory`, `armor_shortfall`, `armor_shot_in_flight`, `cooldown_remaining_us`, `selection_matches_armor`. It does not select a team, remove/reserve a bead, start threat or pause. `guaranteed_solution=false` is intentional: the suggested front may differ from armor color and may become stale after time advances. No exposed front / full slots costs nothing.
- `shuffle`: no payload normally. Reorders only waiting candidates, preserving every team ID/color/quota/remaining amount and each column's candidate count. Slots, board, reservations, current stock, tasks, projectile, cooldown, dragon clocks, speed, fractional time and event history remain unchanged. It commits only after an independent complete timed replay wins at the final armor hit from a copy of the **current** state. Details below.

### Recall selection modal

The caller owns pausing and resuming; rules never resume the clock for a confirmation:

1. Call `set_paused(true)`, show the recall selection UI, then call `begin_tool_selection("recall")`.
2. Keep its `token` and `run_id`. Confirm with `request_tool("recall", {"slot": index, "expected_team_id": displayed_id, "selection_token": token})` while still paused.
3. On cancellation call `cancel_tool_selection(token)`. No quota, use or gameplay snapshot is changed. On success the token is invalidated. A failed target selection does not consume the token or tool, allowing another selection in the same modal.
4. Close the modal, then explicitly call `set_paused(false)` only when the caller intends to resume. Pause resets ×2 to ×1. Resuming or restarting invalidates old tokens. A recoverable transport-error pause cannot authorize a tool.

Calling `begin_tool_selection` does not itself pause, resume or tick. Ordinary nonpaused `request_tool("recall", payload)` remains available for deterministic tests/controllers, but production target-selection UI must use the paused flow.

### Shuffle proof and bounded failure

`rescue_tool_solver.gd` tries bounded deterministic permutations and a greedy, human-paced selection search. It is not an exhaustive solver and does not label a structurally valid or potentially solvable arrangement as proven. A first plan is replayed again in a separate fresh exact-state clone. Both passes include the current elapsed simulation time, remaining dragon deadline and knockback, inventory, armor index, current work, returning/outbound tasks, reserved obstacles, dispatch pacing, cannon cooldown and in-flight projectile. A ready level's first input may be at time zero; subsequent inputs are separated by at least 750,000µs. A running-state proof waits at least 750,000µs before its first new input. The tail continues through final delivery, cooldown, final shot and final hit. Existing P2 exact-time hit-before-contact priority remains authoritative.

Success returns `proof.kind="complete_timed_victory_replay"`, `inputs` (`time_us`, `column_id`, `team_id`), `terminal_time_us`, `click_interval_us`, `run_id`, `start_time_us`, `start_contact_us`, `start_inventory`, `start_tasks`, `start_projectile`, `start_cooldown_until_us`, and `search_steps`. This is an automated replay certificate, not human-playtest evidence or a guarantee for different future user actions.

Optional testing/authoring payload fields:

- `search_budget`: deterministic simulation/search work-step budget, default 16,000 and hard maximum 50,000; zero fails immediately. It does not change the gameplay clock and is not a machine-speed-dependent wall-clock timeout.
- `candidate_order`: exact array containing every currently waiting team ID once. Invalid/missing/duplicated/in-work IDs reject it. Existing per-column queue lengths are retained when filling the order.
- `replay`: exact candidate selection input sequence for validation rather than heuristic plan discovery. It still undergoes the complete live-state/time/legality/conservation replay and cannot bypass proof.

Failure reasons include `search_budget_exhausted`, `no_verified_winning_replay`, `no_changed_arrangement`, `invalid_candidate_order`, and `invalid_search_budget`. Exhaustion, defeat, an incomplete/fabricated replay, and swapping otherwise identical color/remaining teams all leave the **exact internal state** unchanged, including queued events, cached routes, counters and uses. No solver output is committed partially.

`duplicate_for_replay()` deep-copies every script variable, including internal deadlines, event queue, cache and fractional carry. `replay_state()` exposes that full copy for tests/verification; it is not a persistence format or restore API. A clone's state cannot alias the live game.

### Remaining scope boundary

This change implements the four tool **rules**, not production tool modal/animation UI, progress saving, next-level navigation, tutorial persistence, editor UI, or final human-playtest acceptance. The validation pattern builder remains a reproducible authoring script for three fixtures, not the promised complete level editor/generator. The complete scope remains 30 independently authored, validated, playable levels. Existing play/audio/FX files are not changed by this tool batch.

## Test command

From the workspace root:

```sh
mkdir -p /tmp/ant-rescue-rules-home /tmp/ant-rescue-rules-data /tmp/ant-rescue-rules-cache
HOME=/tmp/ant-rescue-rules-home \
XDG_DATA_HOME=/tmp/ant-rescue-rules-data \
XDG_CACHE_HOME=/tmp/ant-rescue-rules-cache \
godot --headless --path ant-rescue-godot --script tests/test_rules.gd
```

The temporary writable HOME/XDG paths avoid this environment's denied default Godot user/log directories. The test runner writes the current JSON report and timestamped event logs under `reports/rules/`; successful validation updates each JSON file's replay metadata. Pattern authoring is reproducible with `python reports/rules/build_validation_levels.py` from the project folder, then the Godot tests. Rebuilding patterns intentionally resets their status to pending until revalidated.

Tool regression command (same HOME/XDG environment): `godot --headless --path ant-rescue-godot --script tests/test_tools.gd`. Reports and accepted replay proofs are written to `reports/tools/`.
