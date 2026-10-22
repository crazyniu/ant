# First-level card hover hints

Follow-up to `b8f200b`, 2026-10-22. The small default tooltip observed after
engine-touch simulation came from each color Button's `tooltip_text`, including
its repeated state synchronization. It was not the enlarged capacity or refusal
Label and did not use that Label's game font/theme.

The five approved first-level cards now keep default tooltip text empty at both
construction and synchronization. Existing state descriptions are retained in
`accessibility_description`; this preserves the content, but is not a screen-reader
acceptance claim. Count labels, state icons, tutorial and actual refusal feedback
remain. Other controls' tooltips and historical layouts are not changed.

No new input handler, mouse event, timer, queue or gameplay invocation is added.
The same `pressed` connection and hit/count rectangles remain. No asset, rule,
reward, level access, merge or deployment change is included.

## Finite check

`tests/test_first_level_card_portraits.gd`, Godot4.6.3 headless, isolated temporary
profile: **193 checks, no failed assertions**, normal exit, no script exception
or shutdown resource warning in this run. Five cards have no default tooltip
and retain the matching description through initial state, repeated sync,
dispatch, full capacity, pause and resume. Existing checks retain one connected
press → one ant, real fifth-press refusal, authoritative pickup counts and
unchanged hit/count rectangles. Per-state full node dumps stay local.

This is node/property/signal evidence, not new native input or GL acceptance.
Actual engine-touch hover delay, drag-out no-dispatch and held-release one-ant
behavior still require current-build GUI review. Physical phone, system cancel,
multitouch, screen reader, whole-scene fidelity and user confirmation remain open.
