# Current readable-transport rule validation

Rules API 1.2.0. Bounded authoritative old-input replay across 33 configurations: 21 pass unchanged; 12 rejected click schedules retimed and independently replayed successfully. Every original front-choice order is preserved with at least 0.75s spacing. No dragon, cannon, dispatch, cap, quota, armor or tool changes.

Focused `tests/test_transport_motion_timing.gd`: 63 assertions, zero failures. This is not a rerun of the historical full rule/campaign suites. Full-level boundary probes are NOT_RUN after this timing change; old certificates were invalidated.

## Current validation results

### validation-01: Sunrise Blossom
- Final hit 42.324286s; contact margin 15.875714s.
- Last pickup 26.705715s; last delivery 27.651430s; final fire 41.474286s.
- Complete no-tool sequence: 14 front selections; schedule retimed: False; original front-choice order preserved.
- Current gameplay hash: `231a74821a769f8acd5016be70abad3bd472384721e5d733648444a94f021aa1`.
- Full-level exact-contact copies: NOT_RUN. Current event trace is in the matching `-events.json` file.

### validation-02: Six-Wall Courtyard
- Final hit 53.158572s; contact margin 12.841428s.
- Last pickup 30.397143s; last delivery 31.914286s; final fire 52.308572s.
- Complete no-tool sequence: 17 front selections; schedule retimed: True; original front-choice order preserved.
- Current gameplay hash: `3320957ea9feb139c24ad832cf73459221c554e910beeac034cb01590bb77751`.
- Full-level exact-contact copies: NOT_RUN. Current event trace is in the matching `-events.json` file.

### validation-03: Twin Lantern Bridge
- Final hit 76.515716s; contact margin 0.434284s.
- Last pickup 23.230000s; last delivery 24.390000s; final fire 75.165716s.
- Complete no-tool sequence: 12 front selections; schedule retimed: False; original front-choice order preserved.
- Current gameplay hash: `d547795668e89791554adb424414869a65be9164c34536ea59df16820cd880e9`.
- Full-level exact-contact copies: NOT_RUN. Current event trace is in the matching `-events.json` file.

## Verified transport boundary

- Short one-cell outbound and return legs each last 0.55 simulation seconds; long routes keep their actual distance-based duration. Pickup hold lasts 0.16 seconds.
- Pickup removes the reserved bead exactly at arrival. The hold has `stage=returning` and one carried bead, but no inventory. Delivery alone credits stock.
- Pause freezes the hold and every clock. ×2 scales wall time, not event order or simulation timestamps. Legacy omitted optional fields preserve old fixture timing.
- Numeric/finite/nonnegative validation, editor defaults and import/export preservation are covered.
- Cannon cooldown is unchanged and measured from fire. Exact final-hit/contact tie wins; contact 1µs earlier loses; contact at delivery prevents stock credit.

## Not claimed

Human playtest, final visual/difficulty acceptance and target-device performance are NOT_RUN. Production eligibility remains false. Actual scene replay and presentation verification are separate. The narrow validation-03 margin is currently 0.434284s and requires human difficulty review; no budget was stretched.
