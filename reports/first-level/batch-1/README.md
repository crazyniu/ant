# First-level candidate: bounded code batch 1

Recorded 2026-10-22 UTC. Base checkpoint: `b28895054b88ffab85a70af435f1a82e118733dd`.
This is a local candidate, not first-level visual acceptance. No push, merge or deployment.

## Changes

- **I04:** A single catalog gate permits only normal `serpent-01`. Home, map, preparation, direct handlers, deferred resource load/handover, CLI, saved entrance and QA override are guarded. Winning first level does not show Next. Historical completed-level metadata, points and settings are retained rather than erased. Later catalog entries are not runtime permission.
- **I07:** Hopper reads `rules.next_fire_target()` rather than the first nonempty inventory color. It hides during flight or when no valid shot exists; the preview and actual subsequent fire share the authoritative selector.
- **I08:** Foot phase accumulates actual outbound/loaded route distance with stage-specific strides. Waiting and pickup do not advance steps; loaded movement continues phase. Production carrier sampling and fixed-distance/different-time cases are tested. This does not establish realistic foot planting or animation quality.
- **I09:** First-level rejection text uses logical rectangle `(52,1534,340,94)`, wraps and ignores input. It is left of speed `(420,1530,100,100)`, with transformed live-node bounds checked. No new controls added.

No new art, rule changes, shop changes, PRD writes or other-level work in this batch.

## Final bounded evidence

| Evidence | Result | Meaning |
| --- | --- | --- |
| `minimal-fixes.json` | 48 checks, 0 failures | Actual first-level controllers/handlers, historical metadata recovery, map node fully visible, hopper next-shot agreement, production distance-phase update, feedback bounds |
| `restoration-test.json` | 18,922 checks, 8,349 cargo samples, 0 failures | Actual first-level production nodes reach victory at 110.425 simulated seconds, 207 balls remain, final result saves and has no Next |
| `cli-gate.json` | 3/3 | `--level=2`, `--auto-replay --level=13`, and `--campaign-drafts --level=1` cannot enter later content |
| `settings-recovery.json` | 20 checks, 0 failures | Existing settings write-failure/retry callbacks and reload remain valid |
| `navigation-save-boundary.json` | 20 checks, 0 failures | Existing navigation save-boundary guards remain valid |

The final restoration test also asserts a real persisted **148-point** receipt under the existing candidate 110/130-second reward thresholds. This is automated candidate behavior, not calibrated economy or human-play acceptance. The earlier 65.95-second replay report is historical and is not reused as current evidence.

All final listed logs have no script errors or exit resource-leak errors. Negative gate tests intentionally emit `first_level_review_only` warnings. Early fixture/teardown failures were corrected in the tests: backup fixture setup, result-FX settling before modal assertions, and asynchronous audio release before teardown. No production audio code was changed.

`summary.json` records source/test hashes, final results, log hashes and exclusions. Logs are local evidence; structured JSON is committed. The prior dated development snapshot and layout/art reports remain historical snapshots, not claims that this batch passed GL review.

## Reproduction

Use an isolated HOME/XDG environment; do not run against production saves. After headless editor import, run only:

- `tests/test_first_level_minimal_batch.gd`
- `tests/test_first_level_restoration.gd`
- `tests/test_first_level_entry_cli.gd` with each of the three arguments above
- `tests/test_ant_settings_recovery.gd`
- `tests/test_ant_navigation_save_boundary.gd`

All use `godot --headless --path . --script <test>`; CLI arguments follow `--`.
The rejected later-level numbers exist only as gate inputs or historical metadata. No later-level configuration, scene or replay was exercised.

## Still open

This does not close the first-level task. The established visual-reference/shop discrepancies, world-ant footprint clearance, layered visual comparison, true GL/input/sound checks, natural-play timing, and final user approval remain open. Current environment GL restriction is unchanged; no retry or workaround was attempted in this batch. Existing 145-second budget and 110/130 reward thresholds remain candidate parameters pending human/visual validation.

After user acceptance, a separately authorized change must intentionally widen the gate; saves and catalog size cannot unlock it automatically.
