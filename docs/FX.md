# Ant Rescue event effects

## Scope and ownership

`scripts/rescue_fx.gd` is a presentation-only `Control`. It accepts the authoritative event envelope from `reports/rules/API.md` and local layout coordinates, then draws lightweight shaded 2D effects. It does not import Rules, store a Rules reference, mutate any supplied snapshot/event/layout object, debit ammo, select a team, consume a tool, grant victory, or wait on an animation callback. No external assets, shaders, particle scene resources, timers or Tween instances are required.

The module is ready to bind, but its isolated tests do not constitute final visual approval of the composed game. The scene owner must inspect a real rendered frame/movie after binding the actual actors and HUD. A test of the existing visual fixture is not a test of a playable 30-level build.

## Public API

- `set_layout(context: Dictionary)`: merge and deep-copy known layout entries. Coordinates are **centers in this node's local 940 × 1672 space**. Add the FX node beneath the existing uniformly scaled root; do not separately apply the 1440 × 2560 viewport scale. `board_origin` is the **center of cell (0, 0)**, not the corner.
- `sync_snapshot(snapshot)`: call every active frame, after `Rules.update(real_delta)` and before draining/consuming events. Synchronizes run, exact simulation time, pause, ×1/×2 speed, terminal status and cannon inventory charge. It does not advance any Rules state.
- `consume_event(event, context = {}) -> bool`: accept a Rules event. Every event must contain `type`, `run_id` and `sequence`. The return value means “understood”, not gameplay success. `target_reserved`, `armor_changed` and other state-only events intentionally add no particles.
- `consume_events(events, context = {}) -> int`: consumes an ordered batch and returns the number understood. Drain Rules once only; share that returned batch with audio and FX.
- `cannon_pose()`: returns `{offset: Vector2, rotation: float, scale: Vector2}`. Position uses baseline pixels and rotation uses radians. Apply relative to the cannon's **base** pose on each frame, never add cumulatively.
- `dragon_pose()`: returns the same keys plus `modulate: Color`, `visible: bool`, `defeat_complete: bool`, `defeat_age: float` and `defeat_phase: String`. Position the dragon from the current snapshot first, then add this finite residual visual offset. The residual begins at the previous location and decays toward `dragon_after`; it is not a second gameplay knockback. On authoritative `victory`, a separate final-hit collapse runs for **`DRAGON_DEFEAT_DURATION = 1.60` active real seconds**, then `visible` becomes false, alpha becomes zero and `defeat_complete` stays true until reset. Apply scale/rotation around a **foot-level pivot**. Never hide the dragon immediately on the victory event. The owner may defer **only the outcome modal** until `defeat_complete` is true; victory, unlocks and progress saving remain immediate. `defeat_age` / `defeat_phase` are presentation diagnostics, not gameplay state.
- `set_cannon_charge(ratio, color_id)`: optional for a visual fixture. Uses only arrived inventory divided by the current armor's demand, clamped to `[0, 1]`. It creates no firing delay.
- `set_paused(bool)`: suspend particles, projectile age, recoil, hit pose and final collapse/fade while a modal or manual pause is open. Also automatically respects `SceneTree.paused` and app focus loss.
- `set_backgrounded(bool)`: explicit app/background hook when the host manages focus itself.
- `set_reduced_motion(bool)`: remove actor motion, smoke, travelling stock sparks, projectile trails and tumbling confetti/shards; use a few static, fading sparkle accents instead. The final dragon defeat becomes a stationary opaque hold followed by the same concluding fade, with the same 1.60-second duration and no rotation, compression, displacement or landing dust. Switching this preference during the fade preserves its current alpha and progress. The essential shot itself still follows its authoritative trajectory. Switching on clears existing transient bursts immediately.
- `play_tool(tool_id, accepted = false, target = null) -> bool`: local tool presentation; aliases `plus → extra_slot`, `hint → scout`. The default only outlines the tool icon and does not imply success. A confirmed tool success may use `accepted = true`; `target` is an optional local `Vector2` for the affected slot/bead. The play adapter calls this once for an accepted `tool_used` rule event. The generic event consumer intentionally does not duplicate that tool presentation. Cancelled, rejected and stale requests do not call it with accepted=true.
- `reset_for_run(run_id)`: clear old transient effects, projectiles, poses and deduplication state. A larger run received through snapshot/events does this automatically. A smaller run is ignored, so old delayed events cannot decorate a new run.
- `advance(real_delta)`: deterministic manual tick for tests or an owner-controlled frame loop. Set `auto_advance = false` first; never also let `_process` advance the same frame. Negative or nonfinite deltas are ignored. Large frames expire cosmetic backlog.
- `debug_snapshot()`: a detached deep copy for tests/diagnostics, including active particle count and both poses. Never use its counters to drive gameplay.

### Layout dictionary

The defaults match the initial UI fixture and should be refreshed when the scene geometry changes.

| Key | Type / meaning |
| --- | --- |
| `cannon_muzzle` | `Vector2`, center at the end of the barrel |
| `cannon_center` | `Vector2`, recoil origin / barrel axis reference |
| `dragon_hit` | `Vector2`, current authoritative armor/body impact center |
| `dragon_foot` | Optional `Vector2`, authoritative untransformed foot pivot for landing dust. If omitted/null, use `dragon_hit + Vector2(-40, 62)`, matching the current sprite |
| `nest` | `Vector2`, return delivery/departure center |
| `board_origin` | `Vector2`, center of board cell (0, 0) |
| `cell_size` | `Vector2`, grid pitch in baseline pixels |
| `stock_points` | Dictionary mapping six color IDs to bead/icon centers, not numeric labels |
| `slot_points` | Array of slot/ant center `Vector2` values, not quota centers |
| `tool_points` | Dictionary mapping `extra_slot`, `shuffle`, `recall`, `scout` to tool icon centers |
| `rescue_center` | `Vector2`, princess/tower celebration point |
| `route_direction` | `Vector2`, normalized internally; direction of increasing dragon route position |
| `route_units_to_pixels` | Float conversion from Rules route distance to baseline pixels |
| `protected_rects` | Array of `Rect2` regions that must remain unobstructed, especially numeric labels, controls and HUD |

Each primitive is culled against the supplied protected rectangles; the Control clips to its local bounds. Keep the FX child above actors but below HUD/modal/confirmation layers. It has `MOUSE_FILTER_IGNORE`, `FOCUS_NONE`, and no input handler. Do not assign a global high `z_index` that raises it over modals. If the owner moves the dragon over time, refresh `dragon_hit` before event consumption. A fired projectile keeps its armor/projectile identity and follows the refreshed `dragon_hit` position while the dragon moves. Supply the authoritative, un-offset center; the hit burst adds the same old-to-new residual as `dragon_pose()` so impact meets the visible actor before it settles.

### Minimal scene binding

```gdscript
const RescueFX = preload("res://scripts/rescue_fx.gd")
var fx = RescueFX.new()

func build_effect_layer() -> void:
    fx.auto_advance = false
    # Add after world/actors and before HUD/overlays, under the scaled baseline root.
    add_child(fx)
    fx.set_layout({"cannon_muzzle": Vector2(466, 909)})

func update_game(delta: float) -> void:
    # Expire/advance prior effects, then receive this frame's exact new events.
    fx.advance(delta)
    rules.update(delta) # exactly once; no separate ×2 multiplication
    var snapshot = rules.snapshot()
    render_authoritative_state(snapshot)
    fx.set_layout({"dragon_hit": current_dragon_armor_center})
    fx.sync_snapshot(snapshot)
    var events = rules.drain_events()
    fx.consume_events(events)
    # The same batch can be passed to audio; do not drain Rules a second time.
    var cannon_pose = fx.cannon_pose()
    cannon.position = cannon_base_position + cannon_pose.offset
    cannon.rotation = cannon_base_rotation + cannon_pose.rotation
    cannon.scale = cannon_base_scale * cannon_pose.scale
    var dragon_pose = fx.dragon_pose()
    dragon.position = authoritative_dragon_position + dragon_pose.offset
    dragon.rotation = dragon_base_rotation + dragon_pose.rotation
    dragon.scale = dragon_base_scale * dragon_pose.scale
    dragon.modulate = dragon_base_modulate * dragon_pose.modulate
    dragon.visible = dragon_pose.visible
```

When a modal opens, pause both Rules and FX immediately instead of waiting for the next active game frame. Closing a modal must explicitly resume them. Because Godot may stop the owner callback while paused, a pause handler must itself call `fx.set_paused(false)` when resuming. Terminal state is different from pause: Rules is frozen, but the FX node must keep advancing its finite dragon collapse and victory celebration in real time. Neither terminal snapshots nor repeated victory envelopes restart a dragon defeat or its dust/confetti already in progress or completed; only a new run restores the dragon. During terminal presentation, do not open a modal that pauses FX before `dragon_pose().defeat_complete`; otherwise the presentation clock correctly remains suspended until the owner resumes it.

## Effect vocabulary

- **Charge:** color gathers softly inside the muzzle with a warm inner reflection, a slim color-matched rim and three small orbit highlights. The subtle breathing stays within 5% of its local glow radius. Charge indicates arrived stock only, never a second cooldown, health bar or gameplay delay.
- **Cannon fire:** a color/gold tapered muzzle flame with a cream core, a local 33-pixel pressure ring, three-layer warm smoke and short sparks. The barrel reaches its mechanical kick after 0.045 seconds, makes one small elastic return and restores its exact base pose at 0.34 seconds. Recoil remains capped at 11 baseline pixels and 0.035 radians. Projectile motion still begins immediately; anticipation never delays a rule event.
- **Projectile:** a 36-baseline-pixel colored enamel/energy shell, approximately 55 pixels across at the 1440 × 2560 viewport, replaces the former 16-pixel-diameter bead. A brass rim, shaded underside, bright warm core and small specular highlight provide depth without hiding the six ammo colors. Four feathered, continuously tapered ribbon layers replace the seven disconnected trail dots; each uses 16 segments and the actual curved trail is capped at 96 baseline pixels. All samples use the same slight trajectory and synchronized `fire_us..hit_us` fraction, not accumulated animation position or a separately animated trail. The explicit final sample equals the exact target center; only the corresponding authoritative hit removes the projectile early. Visual arrival never changes armor, ammo, victory or defeat. Protected-rectangle tests cover entire ribbon segments as well as the larger shell, not just trail sample centers.
- **Armor break:** one 0.42-second local compression/rebound cue combines broken gold/color pressure arcs, a restrained bright contact core and short radial glints, all inside a 58-pixel bound. Fifteen thicker enamel fragments have beveled gold/light edges, shaded faces, a dark thickness edge and analytical tumbling. The existing eight gold sparks and particle budgets remain unchanged. The dragon receives its existing warm local tint and finite 0.48-second residual settling, capped at 36 baseline pixels. Armor remains the authoritative health representation, not a second HP track. No screen shake, fullscreen flash or repeated hit flicker.
- **Pickup:** a small cell-local halo and five tiny facets. Reservations do not trigger pickup effects.
- **Delivery:** a short spark toward that color's stock icon plus a small local ring. Counts come only from the final Rules snapshot, so same-timestamp delivery/fire cannot double-count.
- **Team selection / dispatch:** a compact slot sparkle and small nest departure dust. `slot_released` does not move or destroy in-flight ants.
- **Tools:** mint plus/slot bloom; blue double-arrow swirl for shuffle; lilac recall arc and return mote; gold four-corner scouting glint. A rejected or informational preview is only a neutral outline of the icon. The truly blocked event hints locally at shuffle and recall once; it is neither a loss nor a tool activation.
- **Final dragon hit:** the existing impact pose holds for 0.10 seconds, then a grounded outer pose supports the owner’s localized body/head/wing/leg collapse, makes ground contact and settles before fading. Whole-sprite tipping is deliberately avoided; the owner drives localized deformation from `defeat_age`. The sprite remains **fully opaque through 1.30 seconds**; fading is only the final 0.30-second conclusion, not the action itself. Maximum extra displacement is 4.5 baseline pixels downward (3 resting + 1.5 landing press), maximum added rotation is 0.045 radians (2.6°), and brief landing deformation is limited to 1% horizontal stretch / 2.5% vertical squash. The existing nonfatal 0.48-second hit and 36-pixel residual cap are unchanged. Only authoritative `victory` starts the sequence; player `defeat` does not. No new model, physics body, timer, callback, camera shake or gameplay delay is used.
- **Ground contact:** one deterministically seeded record of 10 warm dust motes is scheduled alongside the victory event and drawn only from 0.92 seconds onward, around the supplied foot pivot. Dust shares the existing global effect/particle budgets, expires at 1.60 seconds, respects protected HUD regions and never replays after skipped/oversized frames. Reduced motion omits it entirely.
- **Final rescue:** 46 shaded paper confetti pieces near the princess plus a modest gold ring, expiring after 2.4 seconds. It is triggered alongside the final dragon collapse only by authoritative `victory`, never delivery or an arbitrary visual timer.


The existing `(220, 193)` foot pivot remains unchanged. The outer pose alone keeps the current sprite’s measured opaque bottom within about 4.3 baseline pixels of its original ground, leaving room under an 8-pixel ground-contact envelope. Owner shader deformation should keep the paws/lowest texture band anchored, not add a second global downward shift. Verify the final rendered composition, not just outer-pose bounds.

### Final-hit phase contract

All boundaries are active **real seconds** from the authoritative `victory` event, independent of the prior ×1/×2 speed. Manual pause, focus/background loss and SceneTree pause suspend the sequence.

| Time | `defeat_phase` | Visible action |
| --- | --- | --- |
| 0.00–0.10 | `hit_stop` | Hold the existing hit pose locally; no simulation/global freeze |
| 0.10–0.42 | `stagger` | Restrained imbalance around the grounded foot pivot |
| 0.42–0.92 | `fall` | Opaque local anatomy collapse in owner shader; only small grounded outer lowering |
| 0.92–1.16 | `landing` | Ground contact, small pressure settle and local dust |
| 1.16–1.30 | `rest` | Hold the readable fallen body, fully opaque |
| 1.30–1.60 | `fade` | Short concluding fade of the settled body |
| ≥ 1.60 | `complete` | `visible = false`, alpha 0, `defeat_complete = true` until reset |

Named boundaries are `DRAGON_DEFEAT_HIT_STOP`, `DRAGON_DEFEAT_FALL_START`, `DRAGON_DEFEAT_LANDING_TIME`, `DRAGON_DEFEAT_SETTLE_END`, `DRAGON_DEFEAT_FADE_START` and `DRAGON_DEFEAT_DURATION`. `defeat_phase` is `none` and `defeat_age` is -1 before victory. Prefer the completion flag, not a duplicate owner timer, to reveal the outcome modal. Do not use this flag to decide or persist whether the player won.

## Budgets and timing

One `Control`, no spawned nodes per effect. Global caps: 40 active effect records, 220 particles and 4 projectiles. Every decorative effect lasts at most 2.8 seconds. Projectile fallback retention is capped at 8.25 seconds, even if a malformed/incomplete event stream loses its hit. Ring/impact maximum in built-in effects is 58 pixels. Projectile body radius is 18 pixels; the faint halo reaches 27.9 pixels and the tapered trail is at most 96 pixels long. These are local baseline pixels, not viewport pixels, and do not add any nodes or particle records. Confetti is localized to rescue, not emitted across the screen. At saturation, optional effects are dropped or the oldest effect is retired; simulation never waits.

Particles are analytically evaluated from age and seeded once by `(run_id, sequence)` with a local RNG, so event effects do not affect global randomness and are deterministic. No random calls are made while drawing. Animation time follows ×1/×2 while playing; victory cosmetics use real time while simulation is terminal. Synchronized projectile position is calculated from authoritative microseconds rather than accumulated animation frame position. For deterministic headless replays, manually advance with the same real-time slices while feeding the same snapshots/events.

## Validation

Run from the project folder:

```sh
mkdir -p /tmp/ant-rescue-fx-home /tmp/ant-rescue-fx-data /tmp/ant-rescue-fx-cache /tmp/ant-rescue-fx-config
HOME=/tmp/ant-rescue-fx-home \
XDG_DATA_HOME=/tmp/ant-rescue-fx-data \
XDG_CACHE_HOME=/tmp/ant-rescue-fx-cache \
XDG_CONFIG_HOME=/tmp/ant-rescue-fx-config \
godot --headless --path . --script tests/test_fx.gd
```

The finite runner exits nonzero on failure and writes its JSON summary to stdout. It covers real Rules replay with unchanged source dictionaries and inventory conservation, event dedupe, stale-run cancellation, projectile/hit IDs, finite recoil and knockback, exact identity restoration, pause/focus/SceneTree suspension, ×2 timing, nonfinite input deltas, deterministic partitioned advancement, saturation budgets, large-frame expiry, local layout mapping, all four tool previews and success cue artwork, reduced motion, terminal celebration and reset. Final-hit checks cover impact continuity, local hit-stop, each named phase and 1.30/1.60-second opacity/completion boundaries, bounded transforms sampled across the whole sequence, scheduled foot-anchored dust and frame partition independence, terminal real-time behavior, persistent invisibility, all pause modes, preference changes without fade restart, duplicate/stale events and restart restoration. The larger-ammunition checks additionally cover exact launch/hit geometry, synchronized microsecond fractions unaffected by visual ×2 advancement, fixed trail length/sample budgets, absence of animation-owned hits, ID-matched retirement, the entire spring-return envelope and ribbon crossings through protected labels. It yields rendering frames for every primitive, but a headless pass is not final visual approval; the scene owner must render the bound composition for that check.

A short three-star local defeat orbit appears above the slumping head from 0.25s until the finite conclusion. It makes the defeated state explicit without another meter, large rotation or global flash. It is phase-driven, bounded and has no rules/audio/persistence callback.
