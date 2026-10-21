# Ant Rescue: single-click serpent core

A Godot 4.6.3 GDScript source snapshot of the validated single-click core, API 3.0.0 / level schema 3. This replaces the public automatic-team baseline `859594922d10d081ed52567a0c0efa548ecad9fa` for the default game entry.

## Run

Open `project.godot` in Godot 4.6.3, allow the first resource import, then press F5. The entry is startup → Home → Play, with three authored serpent validation levels. The viewport is portrait 1440 × 2560; the logical canvas is 940 × 1672. Normal play is offline and needs no account, plugin or secret.

Default saves live under `user://ant-rescue/serpent-click-v1`. `ANT_RESCUE_PROFILE_DIR` may override the root. Saved entrance resumes as a fresh round, not a mid-round board. The replay option owns a separate temporary test profile.

## Included scope

One color click sends one worker for one bead. At most four workers travel concurrently. Each delivered bead becomes one projectile and one damage. Normal segments take one hit, armored segments take two with a cracked intermediate state. Actual final impact wins; the serpent head reaching the finite endpoint first loses. Removing a segment shortens the body without moving the head backward.

Current three-level timing, recorded-source hashes and limitations are in `docs/VERIFICATION.md`; the implementation contract is `docs/CORE_CONTRACT.md`. Runtime art, dynamic atlas dependencies, measured regions and provenance remain in `assets/`, `data/ant-regions.json`, `ASSETS.md` and `docs/asset-manifest.json`.

## Explicitly excluded

Adventure map, independent shop, progression/economy/rewards, additional ant types, ads, combos, mechanisms and the 30-level campaign are not implemented or accepted in this snapshot. Do not use `--campaign-drafts`: the future serpent-campaign catalog has no bundled content. The old automatic-team campaign and incompatible editor/generation chain are intentionally omitted. `scenes/main.tscn` is a shared legacy component gallery, not the current playable entry or acceptance target.

The supplied automated recording covers level 2 at normal speed. It is not human playtesting, hardware listening, target-device performance or final visual approval. No whole-project/33-level regression was rerun for this publication freeze.

## Reproducible checks

First import: `godot --headless --editor --path . --import`.

Current bounded test sources are under `tests/`: serpent rules, ground routes, scene adapter, color controls and startup resource loading. Run a selected test with `godot --headless --path . --script tests/test_serpent_rules.gd`, using isolated HOME/XDG directories for test profiles. `tests/capture_serpent_journey.gd` records authored inputs in the actual scene; set `ANT_RESCUE_EVIDENCE_DIR` outside this source folder. These sources are included for reproduction, not a claim that every check was rerun during packaging.

## Rights

No project-wide open-source license has been selected. Public hosting is not a new license grant. The DejaVu font retains `licenses/DejaVu.txt`. Image and synthesized-audio provenance does not constitute a legal clearance warranty. No competitor artwork or borrowed recording is bundled. See `ASSETS.md` and `DEPENDENCIES.md`.
