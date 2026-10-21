# Single-click segmented serpent core v3

Current scope: one click → one worker → one bead → one projectile → one damage. API 3.0.0 / schema 3 replaces the automatic-team v2 interaction. Historical automatic-team checks are superseded and are not current-target acceptance. No old 33-level regression is claimed.

## Core now

- `click_color(color)` accepts only in unpaused ready/running state with fewer than four transport tasks and an unreserved, four-direction exterior-reachable matching bead. It atomically creates exactly one task/reservation. Only the first successful click starts the serpent. No team pool, quotas, five work slots, automatic dispatch timer, buffered click or hidden retry exists.
- Rejections return `{ok:false,reason,queued:false}`. Reasons are `simulation_frozen`, `unknown_color`, `carrier_limit`, `color_blocked`, `color_all_reserved`, `color_collected`. Rejection neither starts the threat nor changes resources. Legacy `select_team` / `select_front` explicitly reject `automatic_team_dispatch_removed`.
- The color-entry number is every bead not yet picked up, including reserved beads. Reservation leaves the cell occupied and number unchanged. Pickup opens the cell and decrements that number. Completed unloading alone adds one matching inventory bead and frees one carrier place. All outbound, pickup-pause, return and unloading time occupies the same four-place capacity.
- Config has no teams. Per-color board supply must be at least the sum of visible segment initial HP, not equal to it. Victory permits leftover board, inventory or transport tasks.
- Segments are stable `{id,color,kind,hp}` records: `normal` begins HP1, `armored` begins HP2. Runtime adds `max_hp`. The first armored hit leaves the same ID and `kind: armored` at HP1; the second deletes its live ID. Head has no extra HP. No upgrade, combo or mechanism is needed to complete these levels.
- All positive-stock colors compete by frontmost legal live rank. A front segment without matching stock cannot block a supplied color farther back. Fire subtracts one bead and starts cooldown; only one projectile can be in flight. Its stable target ID never remaps after rank changes.
- Hits deal exactly one damage. Ordinary hits never push back or accelerate the head. Empty live list immediately wins (`final_segment_hit`), while live-head contact with the finite goal loses (`dragon_contact`). At the same microsecond, a due projectile hit resolves before contact; earlier contact suppresses later hits even inside one render update.
- `head_s` is absolute finite-route progress. Surviving body rank r has canonical `s = head_s - (r+1)*pitch`. Initial body must fit at nonnegative route positions. Deletion compacts rear ranks only; visual gap closure belongs to rendering.
- `apply_external_hit(segment_id,event_run_id)` remains a future-extension/test hook, not a player ability. Old-run, paused, terminal, duplicate or unknown hits reject. A lethal external hit invalidating the projectile's exact target ends that projectile and refunds its color exactly once before possible victory; a nonlethal armored hit does not invalidate it. Removing an earlier different ID never retargets the shot. Presentation callbacks never settle damage.
- Pause freezes simulation and inputs, and resets speed to x1. x2 scales all simulation timing together. Restart invalidates the previous run. Terminal clocks/resources do not advance.
- Old queue tools are unavailable (`tool_states()` is empty; requests reject without consumption). Shop, growth, ads, combos and mechanisms remain Pending, not hidden dependencies of the base slice.

## Config and transport fields

Schema 3 requires grid/palette, segments, serpent, parameters and transport. The base worker is color-independent; its configurable motion values are not inferred from red/blue/green. This slice does not implement a multi-type or growth system.

`transport = {carrier_type:"worker", outbound_speed_cells_sec:2.5, returning_speed_cells_sec:2.0, pickup_pause_sec:0.30, unload_pause_sec:0.20}`.

`parameters = {max_inflight_ants:4, cannon_cooldown_sec:0.65, projectile_flight_sec:0.45}`.

A task preserves its fixed path and exposes `id, run_id, carrier_type, color, cell_id, path, distance_cells, depart_us, pickup_us, return_depart_us, unload_us, delivery_us, outbound_duration_us, return_duration_us, leg_duration_us, stage`. `leg_duration_us` is the outbound-only compatibility field, not the slower return duration.

Stages:

1. `outbound` until pickup_us.
2. `returning` from pickup, with a stationary pickup pause until return_depart_us, then movement back along the fixed path.
3. `unloading` at unload_us (arrival at cannon), until delivery_us; still occupies capacity and grants no ammo yet.
4. At delivery_us, credit one bead and erase the completed task.

The current near-nest layouts use mostly 3–5 cells one way, with one 6-cell line in the third solution. This gives mostly **3.2–5.0s complete transport**, with one 5.9s trip, including pauses. Transport speeds did not increase. The previous 7–9-cell layout and its 6.8–8.6s trips are retained only as historical evidence.

## Snapshot and events for integration

Snapshot exposes:

- `available_counts`: per-color on-board/not-picked-up counts, including reservations.
- `clickable_counts`: per-color reachable unreserved counts.
- `reserved_counts`: per-color reserved, not-yet-picked-up counts.
- `carrier_count`, `carrier_limit:4`, `capacity_full`.
- `color_states[color] = {state, available_count, reserved_count, clickable_count, capacity_full}`. `collected` means zero on-board beads; `all_reserved` means every remaining bead is reserved; `blocked` means remaining unreserved beads exist but none are reachable; otherwise `ready`. Capacity is orthogonal, not an invented color count.
- `tasks`, board/reservations, inventory and accounting counters; no teams/slots.
- Stable `segments` (HP may be 0/1/2), `alive_segment_ids`, `alive_count`, `head_s`, `head_start_s`, `goal_s`, `segment_pitch`, ID-keyed `segment_s`.
- Empty or live `projectile = {id,run_id,target_segment_id,color,amount:1,flight_us,fire_us,hit_us}`.
- `dragon_position` / `dragon_position()` remain absolute-head compatibility aliases, not HP; `dragon_contact_us` is the finite contact deadline.

All events include `type, sequence, run_id, time_us, time_sec`. A successful input emits `color_clicked` (color/task_id/carrier count/limit), `target_reserved`, and `ant_dispatched`. Transport continues with `bead_picked_up`, new `bead_unloading`, and `bead_delivered`. Transport events carry the task fields above, with no team_id or slot. `dragon_started`, `cannon_fired`, pause/speed and terminal event names remain.

`segment_hit` carries stable segment/target IDs, current HP, max_hp, kind, source, head_s, former_rank, pre-hit-removal target_s, projectile_id and original projectile fields. It occurs on both armored hits. `segment_removed` occurs only at HP0 and additionally carries post-removal live IDs/count. `projectile_refunded` carries the original projectile and reason. Pre-removal target_s remains available after view deletion. External hits have projectile_id -1.

## Accounting

Per color: initial = on-board + carried (returning or unloading) + delivered; delivered = inventory + net spent; dispatched = outbound + carried + delivered; net spent = successful projectile damage hits + current projectile; shots = net spent + refunded shots. Outbound reservations remain part of on-board counts. Exclusive task/reservation pairing, nonnegative resources and capacity ≤4 are checked. No team/quota equation remains. External hits consume no projectile ammo.

## Three small authored levels and bounded verification

All boards are sparse 10×8, with 18/20/22 supply beads rather than the superseded large automatic-team boards. `solution.inputs` contains `{at_sec,color}`; every successive click is 1.4s later, at x1, without tools, retries or rejected inputs.

- serpent-01: 18 beads; 12 normal segments; 12 necessary clicks; victory at 19.95s; six beads remain.
- serpent-02: 20 beads; 8 normal + 4 armored segments = 16 HP; 16 necessary clicks; victory at 26.45s; four beads remain.
- serpent-03: 22 beads; 6 normal + 5 armored segments = 16 HP; 16 necessary clicks; victory at 27.35s; six beads remain.

All three reach at most four simultaneous workers. Segment pitch is 4; goal_s is 122; head_start_s is segment_count×4+4; speed is (goal−start)/60. The verified contact deadline is exactly 60,000,000us in each level, leaving 40.05/33.55/32.65s margins. The first four simultaneous red/blue/green/red clicks release three carriers at 3.2s and the fourth at 4.1s, rather than holding all four for at least 6.8s.

Current packaging verification and evidence boundaries are in `VERIFICATION.md`. Map, shop, progression, economy and 30-level campaign are outside this snapshot.
