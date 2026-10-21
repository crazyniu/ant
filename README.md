# Ant Rescue · Game 2

A portrait 2D Godot project combining color-matched ant collection with automatic cannon attacks against a dragon's colored armor.

This repository contains the Godot **4.6.3** cloud-developed snapshot from 2026-10-21. Runtime UI is English and icon-first. No account, backend, network service, external plugin or secret is needed to play.

## Run

Install the official standard Godot 4.6.3 editor, import `project.godot`, let the editor rebuild its import cache, then press **F5**.

```sh
# First import; the .godot cache is intentionally not committed.
godot --headless --editor --path . --import
# Default: startup -> real Loading -> Home -> three validation levels.
godot --path . --rendering-method gl_compatibility
# Optional: 30 candidate levels with a separate progress profile.
godot --path . --rendering-method gl_compatibility -- --campaign-drafts
# Standalone level-authoring workspace, not the game entry.
godot --path . scenes/editor.tscn
```

Main scene: `scenes/startup.tscn`. `scenes/main.tscn` is a visual specimen gallery, not the playable entry. Loading reads actual threaded resource status without a fixed delay or fabricated progress. A failed batch exposes Retry.

The rendered viewport is **1440×2560**. The internal 940×1672 layout scales uniformly. Physical window size depends on the display/window manager; preserve aspect ratio and check pointer mapping on the target computer. Source bitmap resolutions are listed in `ASSETS.md`; a 2K viewport does not make every bitmap native 2K.

## Gameplay contract

- Only a queue column's front team can enter one of five work slots. Distinct teams remain separately clickable, including teams of the same color.
- The first accepted team starts the threat. Dispatch reserves a reachable matching bead and debits team quota; pickup opens the cell; delivery alone credits the matching inventory.
- For every color: initial board count = total team quota = total armor demand. Reservations, carried beads, stored inventory and spent ammunition are separate conserved states.
- Matching sufficient stock plus finished cooldown automatically fires. Cooldown starts at fire; an armor segment cannot receive duplicate in-flight shots. Remaining stock stays valid after the armor changes.
- The only victory is the actual final hit breaking the final armor. Board clear, last delivery and projectile launch are not victory. Dragon contact first loses; at the exact same simulation timestamp, hit is processed before contact.
- Final hit locks/saves victory immediately. The finite death presentation precedes the result panel without changing authoritative rules or saving twice.
- Four conserving tools unlock at levels 3/6/9/16. Candidate content is not silently substituted into the three-level default catalog.

## Save and audio behavior

Validation progress uses `user://ant-rescue/`; candidate progress uses its `campaign-drafts/` child. `ANT_RESCUE_PROFILE_DIR` overrides the root, not the catalog separation. Relaunch restores the saved entrance as a fresh round, not a mid-round board. `--auto-replay` uses an isolated temporary profile and never advances ordinary player progress.

Music and effects have separate icon-and-slider controls; zero means silence. Saved zero is never reset to make a demonstration audible. Music continues softly through tutorial/pause/result panels, returns to normal gain in Settings, and suspends in the background. The snapshot includes the actual BGM lifecycle/gain fix and enlarged icon-only result actions.

## Code and art map

- `scripts/startup.gd`, `startup_loader.gd`: startup, Home, local asynchronous loading and retry.
- `scripts/play.gd`: real input, presentation, navigation and persistence adapter.
- `scripts/rescue_rules.gd`: authoritative microsecond event simulation.
- `scripts/level_catalog.gd`, `save_service.gd`: catalog identity and isolated atomic local saves.
- `scripts/board_plane.gd`, `bead.gd`, `carrier_motion.gd`: shared ground projection and independent movable pieces.
- `scripts/rescue_fx.gd`, `audio_service.gd`, `ui_motion.gd`: bounded rule-event effects and UI motion.
- `assets/`, `data/`: current textures/atlases, audio, font, regions and all playable/candidate configurations.
- `docs/`, `reports/rules/API.md`: implementation contracts and explicit verification limits.

Start with `docs/UI_COMPONENTS.md`, `docs/BOARD_PLANE.md`, `ASSETS.md`, `docs/asset-manifest.json` and `DEPENDENCIES.md`. Keep measured alpha regions, contact anchors, aspect-preserving titles and uniformly scaled nine-slice corners. Do not bake movable game objects into one background image.

## Verification and remaining acceptance

See `docs/PUBLIC_VERIFICATION.md`. Production code, current assets and level data are byte-identical to the tested frozen snapshot; public preparation only removes private handoff material, cleans documentation and makes five review-output paths portable.

The snapshot has a same-version normal-speed natural first-level run through startup, Home, Loading, play, victory and Next, and isolated imported startup checks for both catalogs. BGM was measured in the actual movie audio. These are automated checks, not human listening, device performance, final visual approval or human completion of all 30 candidate levels. The old all-30 scene sweep and per-level boundary certificates predate transport retiming and must not be treated as current full acceptance.

Reference ant-motion matching is still pending usable video footage; unavailable reference playback was not treated as an observation. A known process-exit static bead texture-cache diagnostic remains documented. Gameplay and loading checks passed despite that shutdown diagnostic.

Useful bounded checks:

```sh
godot --headless --path . --script tests/test_handoff_smoke.gd
godot --headless --path . --script tests/test_handoff_smoke.gd -- --campaign-drafts
godot --headless --path . --script tests/test_startup_loader.gd
godot --headless --path . --script tests/test_startup_flow.gd
godot --headless --path . --script tests/test_audio_scene_flow.gd
```

Use an isolated `ANT_RESCUE_PROFILE_DIR` for manual test runs. Some tests intentionally exercise invalid resources. Capture outputs and generated caches/videos are not repository source; regenerate them locally rather than committing old versions.

## Rights and provenance

No project-wide open-source license has been selected. Public hosting alone is not a new license grant. The included DejaVu font retains `licenses/DejaVu.txt`. Image provenance and original synthesized audio are recorded in `ASSETS.md` and `assets/audio/README.md`; no reference-game artwork or borrowed recordings are bundled. AI-generation provenance is not a legal clearance warranty.
