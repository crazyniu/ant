# Interaction and combat motion contract

The gameplay clock remains authoritative. No rule data, carrier speed, pickup timestamps, cannon flight duration, hit ordering, inventory debit or save timing changes in this pass. The previous 33-level core timing certificates therefore remain applicable; this is not a new claim of 30-level graphical or human acceptance.

## Reusable presentation

- `scripts/rescue_fx.gd`: 36 logical pixel projectile diameter (approximately 55 physical pixels at 1440×2560), shaded enamel/brass surface and bright core. Four tapered ribbon layers, 16 segments, at most 96 logical pixels behind the shot. Actual fire/hit microseconds own position; the tail cannot continue past a hit.
- Cannon charge is based on real matching stock. A successful fire produces bounded recoil/spring return, muzzle light and smoke. No added charging wait, invisible extra shot or fullscreen flash.
- Armor hit uses local elastic arcs and dimensional shards. The existing finite grounded dragon collapse and stars remain, with final-hit victory/save immediate and result delayed only for presentation.
- `scripts/ui_motion.gd`: art-only press 65 ms/release 150 ms, modal reveal 220 ms and close 120 ms, hint entrance 180 ms. Input hit rectangles do not scale. New pages pause and block input immediately. Closing pages lose input/callbacks immediately; reopening cancels retired tracks.
- `scripts/play.gd`: selected ant artwork reaches its slot in 240 ms; rear queue artwork advances in 160 ms; selected quota is always the current rules value. Queue button rectangles never travel. Each successful delivery briefly accents its live inventory number for 260 ms. Existing 160 ms pickup hold now visibly raises the load onto the carrier. These tracks use simulation time and freeze with pause.
- Art remains independent from controls. No new feature, permanent label, confirmation step, art atlas or third-party asset was introduced.

## Bounded checks and evidence

`tests/test_fx.gd`, `tests/test_ui_motion.gd`, `tests/test_interaction_motion_binding.gd` cover changed components. `tests/test_motion_binding.gd` replays the three actual gameplay scenes, retaining final hits at 42.324286 s, 53.158572 s and 76.515716 s. `tests/capture_interaction_polish.gd` records the same source in real Godot GL at 1440×2560 and 1×, with automatic UI mouse input and automatic published team choices. It is not human playtesting. Capture paths and source hashes are external under `../ant-rescue-evidence/interaction-polish-current/`; do not include movie history in the source package.

## Reference boundary

Current PRD reference: https://www.youtube.com/watch?v=tqBXIpu_GnI . Additional supplied reference: https://www.youtube.com/watch?v=OJLAGR6oidg . The permitted public player/media/store routes did not produce decodable moving gameplay frames in this review. Ant motion matching to the reference remains pending a playable recording; existing stride/speed has not been relabeled as reference-matched. The present changes are improvements assessed against actual current game output, not evidence of competitor timing or user visual approval.
