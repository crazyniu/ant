# Campaign authoring, draft version 1.0

## Current delivery and acceptance boundary

Thirty original, distinct bead-pattern drafts are stored in `data/campaign-drafts/`. Each has a JSON configuration, a standalone Markdown authoring sheet, and a companion PNG made from the project's actual bead sprites. These remain **authoring drafts**, integrated as an explicit opt-in playable candidate through `--campaign-drafts`, not finally accepted production content. See [runtime entry and progression](CAMPAIGN_FLOW.md).

- 30 distinct silhouettes, not the same mask with different colors.
- Every present color has exact `board = total team quota = total armor demand`; absent supported colors are explicitly zero in the authoring report.
- Five stable candidate columns per level, including empty columns in introductory levels. Five starting work slots. Never a sixth candidate column.
- Independent team quota chunks, mixed-color queue continuations from level 6, and separate armor demand slices/order.
- At least one complete no-tool replay per draft, with accepted expected-front team IDs and integer simulation microseconds. Consecutive selections are at least 750,000 μs apart.
- Finite dragon speed/route and bounded nonzero knockback. No free ammunition, removed threats, zero-time input floods or forced victory states.
- Each proof reaches the final armor hit through the real transport, cannon cooldown and projectile flight. The compact timeline includes the final event and all armor hits, not huge transport logs.
- Current full-level boundary certificates are `NOT_RUN` after the readable-transport timing change. Historical certificates are invalidated rather than reused. The focused transport fixture verifies exact-final-hit/contact ties, contact 1µs earlier, and contact at delivery. No full 66-probe sweep was run in this bounded batch.
- Human playtest and visual acceptance are both `NOT_RUN`, and `production_eligible` remains false. Do not count these as 30 finally accepted levels.

The authoring contract is implemented by the local rules API and documented in reports/rules/API.md. The default three validation fixtures remain available. The opt-in 30-level catalog has a separate profile and uses the same rules, formal UI, audio and FX.

## Inspect the work

- [All 30 current thumbnails](../reports/campaign/campaign-overview.png)
- [Compact manifest and artifact checksums](../reports/campaign/manifest.json)
- [Finite regression report](../reports/campaign/test-report.json)
- Per-level complete sheets and files: see the index below.

The PNG sheets are authoring previews, not runtime screenshots. Each per-level sheet includes its entire board with empty cells, actual six-color ledger, complete front-to-back queues, armor sequence, threat/timing parameters, tool unlock context, dated replay proof, full timestamped selection sequence, explicit boundary verification status and outstanding human-playtest questions.

## Progression and deliberate authoring choices

| Drafts | Design focus | Colors | Bead range | Proven run length | Current contact margin |
|---|---|---:|---:|---:|---:|
| 01–05 | Exposed choices, quota exhaustion, delivery vs victory, basic internal seeds | 1–3 | 62–103 | 14.98–26.23 s | 19.02–22.11 s |
| 06–10 | Front order, spare-slot planning, current and future color stock | 4–5 | 161–202 | 35.33–51.08 s | 27.87–38.62 s |
| 11–20 | Multiple regions, layered exposure, split quotas, repeated armor colors | 6 | 145–290 | 39.67–73.42 s | 20.05–41.54 s |
| 21–30 | Combined six-color planning, deeper queues and longer cannon tails | 6 | 212–404 | 52.52–84.34 s | 20.37–47.70 s |

These are provisional authoring bands, not a claim of monotonic measured human difficulty. Current route budgets are intentionally conservative. A deterministic successful input sequence cannot establish whether a first-time player recognizes the motif, chooses meaningful alternatives, or finds the pressure fun. Those questions remain for human playtesting before any promotion.

The source generator draws each motif with a different authored set of shapes and color regions. Fixed seed and content version identify the reproducible content; geometry does not depend on a random palette fill. Introductory levels keep colors on readable lanes. From level 6, first fronts follow the authored color order and later quota chunks rotate among lanes, so taking one front exposes another future color. With six colors, the sixth initial team follows the fifth front in column 5. Armor slices alternate independent forward/reverse color cycles and are not copied from team quotas.

Tool unlocks are `extra_slot:3`, `shuffle:6`, `recall:9`, `scout:16`, one use per level. Drafts set `level_number` to the intended authoring context while `production_level_number` stays null. This exercises unlocks in the editor without publishing the levels. All winning proofs use no tools.

## Readable transport contract

All current levels author 14 cells/s, a minimum 0.55s per leg and a 0.16s pickup hold. These are authoritative simulation durations, including at ×2 and pause. Board removal is exactly at pickup, stock only at delivery, and victory only at the final projectile hit. Existing proof hashes and timings were regenerated; full-level boundary probes remain `NOT_RUN`, not inherited.

## Reproduce and verify

Run from the project directory, using a writable HOME/XDG location in restricted environments:

```sh
# Rebuilding intentionally invalidates existing replay claims.
python tools/build_campaign_sources.py

# Generate proofs, complete sheets and portable bead-art PNGs through EditorDocument.
HOME=/tmp/ant-campaign-home \
XDG_DATA_HOME=/tmp/ant-campaign-data \
XDG_CACHE_HOME=/tmp/ant-campaign-cache \
godot --headless --path . --script scripts/campaign_build.gd

# Assemble only current previews and checksum the delivered JSON/PNG artifacts.
python tools/render_campaign_overview.py

# One bounded regression pass, without changing draft gameplay.
HOME=/tmp/ant-campaign-home \
XDG_DATA_HOME=/tmp/ant-campaign-data \
XDG_CACHE_HOME=/tmp/ant-campaign-cache \
godot --headless --path . --script tests/test_campaign.gd
```

For a first-five milestone only, use `python tools/build_campaign_sources.py --through 5` and pass `-- --through=5` to the Godot build. The overview renderer expects the complete current 30-level set. Python source generation uses the standard library; overview assembly additionally uses Pillow. Godot thumbnail export reuses the existing imported bead atlas.

`campaign_build.gd` uses `EditorDocument.import_json → validate_solution → export_json`. The existing `editor_verifier.gd` and `rescue_tool_solver.gd` own bounded human-paced planning and exact replay; `rescue_rules.gd` owns every dispatch, reservation, exposure route, delivery, inventory debit, armor change, dragon event and victory. No parallel gameplay implementation is embedded in the generator.

Each search uses a 16,000-work-step bound. No timeout or failed search is relabeled as a win. A separate compact-timeline pass has a 20,000-event bound. Current saved replay verification uses at most 1,278 work steps. Boundary probes use the Verifier's own finite default bound. There is no retry-until-success loop or outcome-based mutation of threat parameters. The readable-transport batch replayed all 33 old input sequences once, then retimed only 12 rejected click schedules (11 candidates and validation-02), preserving every front-choice identity/order and ≥0.75s cadence. All 33 now win. No dragon budget, cannon, dispatch or tool parameter changed.

The predeclared route budget is computed **before solving** from beads × dispatch interval, teams × 0.75 seconds, 0.60 × armor count × cooldown, an outward/return path allowance, and a band-specific grace period. It does not use the measured successful finish time to stretch a failing level. Exact post-knockback contact margin is measured by Rules after successful replay, with complete tail durations included in the authoring sheet.

The optional full regression suite checks all 30 full replays, 60 contact boundaries, exact content hashes, color conservation, unique silhouettes, five slots/columns, tool unlock context, and last-flight state. It was not rerun for this bounded transport batch; the current machine-readable report states the smaller actual scope. It explicitly demonstrates that an empty board plus fully returned ants one microsecond before the final hit is still `running`, and that the terminal result freezes afterwards. Empty, tool-bearing and zero-budget solutions fail closed.

## Promotion gate still open

1. Inspect each current thumbnail and the same file in the actual 2K Godot runtime/editor.
2. Human-playtest the intended level order and slower decision cadence. Record pattern recognition, alternative choices, waiting, slot pressure and threat pressure separately.
3. If geometry, queues, quotas, armor or timings change, rebuild the affected proof and boundary cases. Never reuse a stale content certificate.
4. Review those findings before promoting the existing opt-in candidate to final content. Do not silently change `content_kind`, `production_level_number` or acceptance labels.
5. Candidate progression/save and three-page selection have automated integration coverage documented in [CAMPAIGN_FLOW.md](CAMPAIGN_FLOW.md); that does not replace human acceptance.

## Level index

| Draft | Original motif / complete sheet | Focus |
|---:|---|---|
| 01 | [First Sprout](../data/campaign-drafts/campaign-01.md) | One exposed color: select, exhaust quota, wait for delivery and final hit. |
| 02 | [Sunrise Ripples](../data/campaign-drafts/campaign-02.md) | Two separated regions: future blue stock survives yellow armor. |
| 03 | [Paper Lantern](../data/campaign-drafts/campaign-03.md) | Open red sides before the enclosed yellow light; extra slot first available. |
| 04 | [Little Sailboat](../data/campaign-drafts/campaign-04.md) | Three exposed choices and a small last wave; quota zero is not victory. |
| 05 | [Seeded Strawberry](../data/campaign-drafts/campaign-05.md) | Green crown and red fruit expose small yellow seeds; basic waiting. |
| 06 | [Wayfinder Compass](../data/campaign-drafts/campaign-06.md) | Queue order differs from armor: hold white stock and clear yellow spokes. |
| 07 | [Candy Cottage](../data/campaign-drafts/campaign-07.md) | Roof and base expose door and window; reserve a slot for blue window quota. |
| 08 | [Ribbon Butterfly](../data/campaign-drafts/campaign-08.md) | Split wings and antennae need different queues; purple opens blue centers. |
| 09 | [Lily Pond Frog](../data/campaign-drafts/campaign-09.md) | Select a blocked belly early only if an outer-green slot stays free. |
| 10 | [Harbor Bell](../data/campaign-drafts/campaign-10.md) | Blue enamel is enclosed by yellow: plan inventory rather than armor-matching clicks. |
| 11 | [Mushroom Grove](../data/campaign-drafts/campaign-11.md) | Two caps unlock stems and spots; independent quotas share five slots. |
| 12 | [Lantern Fox](../data/campaign-drafts/campaign-12.md) | Ear, eye and muzzle layers; do not overfill slots with the outer fur color. |
| 13 | [Hummingbird Visit](../data/campaign-drafts/campaign-13.md) | Separated flower and bird regions; six-color queue with two destinations. |
| 14 | [Jade Teapot](../data/campaign-drafts/campaign-14.md) | Handle hole remains enclosed; clear blue body before white and green medallion. |
| 15 | [Orchard Windmill](../data/campaign-drafts/campaign-15.md) | Four blades and tower overlap; split red/yellow quotas across repeated armor. |
| 16 | [Tidepool Crab](../data/campaign-drafts/campaign-16.md) | Claws, legs and eye stalks expose the shell; scout unlock is optional. |
| 17 | [Acorn Gateway](../data/campaign-drafts/campaign-17.md) | Cap overlaps nut shell, then white inset and blue center: three exposure steps. |
| 18 | [Coral Seahorse](../data/campaign-drafts/campaign-18.md) | Curved tail and body channels; keep a slot for the last blue bubbles. |
| 19 | [Moonlit Palace](../data/campaign-drafts/campaign-19.md) | Crescent and twin towers; white roof and yellow gate release on different paths. |
| 20 | [Rainbow Spiral Shell](../data/campaign-drafts/campaign-20.md) | Six nested colored bands with a diagonal opening; repeated demands store surplus. |
| 21 | [Dragon Egg Shrine](../data/campaign-drafts/campaign-21.md) | Outer egg, purple core and yellow lightning share attention with two side pillars. |
| 22 | [Clockwork Owl](../data/campaign-drafts/campaign-22.md) | White eye rings enclose blue pupils while body unlocks the red breast. |
| 23 | [Festival Bridge](../data/campaign-drafts/campaign-23.md) | Three supports and two lanterns; delayed colors stockpile ahead of alternating armor. |
| 24 | [Reef Lighthouse](../data/campaign-drafts/campaign-24.md) | Striped tapering tower; independent top lamp and base route challenge order. |
| 25 | [Phoenix Crest](../data/campaign-drafts/campaign-25.md) | Split wing feathers and inner chest; keep slots cycling while armor changes. |
| 26 | [Secret Garden Gate](../data/campaign-drafts/campaign-26.md) | Ring hedge encloses courtyard; flowers interrupt layers and gate stock waits. |
| 27 | [Cloudberry Airship](../data/campaign-drafts/campaign-27.md) | Three nested balloon bands plus suspended gondola; stock different armor colors early. |
| 28 | [Crystal Citadel](../data/campaign-drafts/campaign-28.md) | Three towers, two windows and enclosed gate: multi-object quota planning. |
| 29 | [Orchid Guardian](../data/campaign-drafts/campaign-29.md) | Wings, jaw and belly occupy different channels; six-color endgame cadence. |
| 30 | [Rescue Crown](../data/campaign-drafts/campaign-30.md) | Crown points expose three gems; combine queue planning, split quotas and final flight. |
