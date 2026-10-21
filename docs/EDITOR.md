# Ant Rescue Level Studio

Standalone, desktop-only Godot level authoring for PRD §7.2–7.3. It is not the player runtime, a replacement for the three validation levels, or a claim that the final 30 levels exist. No project default, production level, player save, or progression file is changed by opening the editor.

## Open

From this project directory:

```sh
godot --path . scenes/editor.tscn
```

The studio retains a fixed 1440 × 1000 logical canvas, rendered with Godot viewport scaling and aspect `keep`. Its restored window is uniformly fitted inside the screen's usable area with decoration clearance; smaller screens open maximized instead of forcing an oversized 1440-pixel-wide window. Godot transforms pointer input through the same viewport scale, so the right edge and hotspots remain accessible without cropping. The project's default 1440 × 2560 portrait gameplay remains unchanged. Use Godot 4.6.3. In sandboxed environments, supply writable `HOME`, `XDG_DATA_HOME`, and `XDG_CACHE_HOME` as shown under Tests.

## Author a level

1. Open one of the three validation fixtures, import a JSON file, or choose New. Imports always become authoring drafts; imported proof claims are not trusted. Invalid JSON or unsafe nested structures leave the current document untouched. Structurally shaped but unbalanced configurations remain editable and explicitly unverified.
2. Paint on the bead grid. Choose a palette color or Blank, then Paint, Erase, or connected-region Fill. Right-click always erases. Drag painting, Undo, Redo, and grid resize (1–48 cells per side) are supported. Resize preserves the top-left area and fills additions with blanks; Undo restores cropped cells.
3. Use Pattern to set level ID, original pattern name, objective, content version, seed and symbol palette. The six supported colors use the current production bead atlas. A custom palette maps single non-dot characters to those six colors; `.` remains blank. Renaming a symbol without updating cells is rejected rather than losing artwork.
4. The balanced-queue helper derives quotas and armor totals from the current pattern. Choose 1–8 columns and a quota cap. This is a deterministic structural scaffold, not random artwork, a guaranteed solution, or automatic production content. The saved grid, seed and content version make the result reproducible; no hidden random state exists.
5. In Queues, add/delete columns and teams, edit stable IDs/colors/quotas, and move teams up/down. The displayed top team is the playable front. Each edit invalidates old proof.
6. In Dragon, add/reorder/edit every armor segment, demand, dragon initial/route position, speed, finite knockback, dispatch interval, transport speed, capacity, cooldown and projectile flight. Toggle available tools and their unlock level; each remains one use per level. The no-tool verifier never requests a tool.
7. External exposure outlines are computed by `RescueRules.reachable_cell_ids()`, including every edge, four-neighbor exterior connection, and enclosed holes. When queues are temporarily unbalanced, a throwaway balanced quota scaffold calculates geometry on the exact same grid. It never changes the authored queue, timing or armor.
8. Start/reset preview, select front-team buttons, Step 0.25s, or Play/pause. The same RescueRules simulation drives board removal, reservation dots, route traces, five slots, work states, inventory, armor progression and dragon-route display. The authoring board is deliberately orthographic for accurate painting, not a replacement for the runtime's projected BoardPlane. No duplicated combat or reachability implementation exists here.
9. Preview records only accepted selections, with exact simulation-microsecond timestamps. Recorded clicks must be at least 750,000µs apart, including after manual pauses. Observation before the first accepted selection does not run threat. A rapid repeat cannot silently select a new team.
10. Verify the recorded sequence, independently recheck an imported sequence, or Find and verify a bounded no-tool solution. Watch verified replay replays the accepted inputs at their exact simulation timestamps and continues through the final hit.

All editor UI is English. There are no player-save writes, unlocks, auto-promotion, merges or deployment operations. It is safe to open this beside the production project, but coordinate access before using a shared desktop.

## Verification and fail-closed export

- `editor_verifier.gd` is a thin subclass of the existing `rescue_tool_solver.gd`. It uses its actual bounded search and independent complete replay, not a color-count shortcut or a second gameplay implementation. It never shuffles the authored candidate order to obtain an easier proof.
- The search uses the solver's 16,000-work-step default and 50,000 maximum. A work budget is deterministic, not a machine-speed-dependent wall-clock timeout. The bounded heuristic is not exhaustive: failure means no proof was obtained, not mathematical unsolvability.
- The verifier checks all initial color totals through Rules, legal front selections, five slots, timing, transport, cooling, projectiles, conservation and final-armor-hit victory. Tools and zero-interval synthetic click sequences are rejected.
- On successful proof, the report includes the input sequence, terminal time, final-hit margin, UTC verification timestamp, Rules API version and SHA-256 of canonical content. Content edits, Undo/Redo and failed proof attempts invalidate an old success. A hash mismatch at export also degrades it to unverified.
- Two separate altered-route replays exercise a full-level exact-final-hit contact tie and contact one microsecond earlier. They report actual outcome/time and PASS, REVIEW_REQUIRED or NOT_APPLICABLE. A shortened route can encounter a different earlier loss; that must remain visible rather than being mislabeled as a successful boundary case. The original level and successful no-tool proof are not changed by these test copies.
- The report always says `human_playtest: NOT_RUN` and `production_eligible: false`. Automated replay is not human testing. Author notes can retain recognition, pacing, waiting, choice quality and failure-boundary observations, but writing them does not automatically promote a level or claim a reviewed playtest.
- Export draft + PNG writes a JSON file plus a matching `-thumbnail.png` companion, with a portable filename reference inside the JSON. It retains the full authored configuration, seed/version, per-color board/quota/armor report, structural errors, proof state and timestamped candidate sequence. Invalid, timed-out and merely structural content may be saved for further editing but remain INVALID/UNVERIFIED. Exports into `res://data/levels/` are blocked, including the three fixture paths. Promotion into the formal 30-level set is a separate review, not an editor button.
- PNG thumbnail export uses the current production bead atlas and the exact current grid, including blank cells. Its size is derived from the grid. The ordinary FileDialogs ask before replacing the chosen existing target; the JSON export also replaces its same-basename `-thumbnail.png` companion. New/Import/close ask before discarding unsaved changes.

## Code boundaries

- `scripts/editor_document.gd`: editing, history, strict import, conservation report, preview/recording, proof lifecycle, reproducible draft export, thumbnail image.
- `scripts/editor_verifier.gd`: thin adapter to the authoritative solver, plus explicitly labeled altered-route boundary probes.
- `scripts/editor_grid.gd`: current bead-atlas rendering, exposure overlay, grid input and authoring route traces.
- `scripts/editor_studio.gd` / `scenes/editor.tscn`: native Godot authoring controls and isolated desktop scene.
- `tests/test_editor.gd`: finite regression suite and actual-viewport capture when run with a graphics display.

The adapter intentionally calls the solver's protected-style `_find_plan` and `_verify_replay` routines. Godot has no access restriction on these methods. They are covered by three-fixture integration tests; if the authoritative solver API changes, update this narrow adapter rather than forking gameplay logic.

## Tests and artifacts

```sh
mkdir -p /tmp/ant-editor-home /tmp/ant-editor-data /tmp/ant-editor-cache
HOME=/tmp/ant-editor-home \
XDG_DATA_HOME=/tmp/ant-editor-data \
XDG_CACHE_HOME=/tmp/ant-editor-cache \
ANT_RESCUE_EVIDENCE_DIR="$(pwd)/../ant-rescue-evidence/editor-current" \
godot --headless --path . --script tests/test_editor.gd
```

The finite suite covers paint/fill/erase, cropping/undo/redo, closed-hole exposure, queue conservation, malformed imports, timestamp legality, all three fixture replays, boundary copies, timeout/failure invalidation, exact-content hash roundtrip, PNG export, no production writes, live scene controls, preview recording and full visual-controller replay. It does not mutate the original three levels. Without `--headless`, it additionally captures the actual Godot viewport and then exits.

The test defaults to the portable `user://editor-evidence` directory. Set `ANT_RESCUE_EVIDENCE_DIR` to choose another output directory for every JSON, log-derived report, PNG and viewport capture. The example above writes outside the source tree:

- `../ant-rescue-evidence/editor-current/test-report.json`
- `../ant-rescue-evidence/editor-current/verified-validation-01.json` through `-03.json` (authoring copies only)
- `../ant-rescue-evidence/editor-current/roundtrip.json`
- `../ant-rescue-evidence/editor-current/validation-01-thumbnail.png`
- `../ant-rescue-evidence/editor-current/editor-studio.png`, `editor-pattern.png`, `editor-queues.png`, `editor-dragon.png`, `editor-live-preview.png` (only after a graphics run)

No successful automated result asserts human playtesting, original-pattern acceptance, finished 30-level content, native Mac support, or mobile support.

## Readable transport timing

New documents default to transport speed 14 cells/s, `transport_min_leg_sec = 0.55` and `pickup_pause_sec = 0.16`; all parameters appear in the existing dynamic timing editor. Import/export preserves both optional fields. They must be finite, numeric and nonnegative. Legacy omission means zero, not silently inserted defaults. Any timing edit invalidates proof before verification. The hold is authoritative simulation time after pickup and before return departure, not an inventory or animation delay.
