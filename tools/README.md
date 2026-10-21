# Single-level authoring check

Use official Godot 4.6.3 and import the project first. This is one short reusable entry over the **existing production rules**, not a generator, new test framework or completed visual editor.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tools/validate_serpent_level.gd -- \
  --level=res://data/serpent-levels/serpent-05.json \
  --report=/tmp/serpent-05-check.json --events
```

- Required: one explicit JSON level path. There is no implicit catalog/30-level scan.
- Optional `--report=path` writes the result; its directory must exist. It cannot overwrite the input path. Without it, only stdout is written. No player saves, catalog, source data or reward balance is changed.
- Optional `--events` includes the ordered real event trace. Without it, the summary still contains an event count and deterministic sequence SHA-256. This trace is data for step inspection, not an interactive replay editor.
- Exit 0: the authored Worker Lv.1 input sequence wins and accounting/path checks pass. Exit 1: content or solution fails. Exit 2: CLI/input JSON/report I/O error.

Checks: current schema and per-color base supply; named fixed target and existing shared scene/assets; valid reward thresholds; explicit increasing timestamps starting at 0; exactly the author's clicks with no retries or hidden queue; actual transport paths through empty cardinal cells; four-carrier capacity; conservation at authoritative event deadlines; final actual-hit victory and remaining supply. Summary includes final-hit/contact times, paths, supply/HP, peak carriers and exact windows with no legal dispatch opportunity. It uses `RescueRules._next_event_time()` to inspect the current API 3.1.0 event boundary, so a later rules API change must recheck this small adapter.

This does not claim ground-contact/obstacle-art correctness, visual clarity, realistic human decision time, native input, audio, performance, economic balance or a full editor. Keep the per-scene GL and measured-ground review. A failed explicit click remains a failed solution, not silently rescheduled. Short input intervals are reported as authored, not approved as human timing.

To author a new level, copy one current JSON into a separate draft, change identity/content version, region/scene/guardian and actual board/opening/route/segment decisions, then author a timed base-worker solution. Run only that new file; inspect its event trace and bounded actual scene. Add it to the catalog only once it is independently playable. Do not generate thirty near-identical entries to meet a count.

Current entry acceptance: `tests/test_level_check_entry.gd`, one valid level-5 replay plus deliberately invalid input/configuration variants. Previous 30/33 automatic-team suites are not current evidence.
