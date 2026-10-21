# 08 · Ribbon Butterfly

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-08`; version: `campaign-draft-1.0`; seed: `2026102108`.
- Goal: Split wings and antennae need different queues; purple opens blue centers.
- Progression: 06–10 order and stock.
- Thumbnail: [Ribbon Butterfly](campaign-08-thumbnail.png).
- Source: [campaign-08](campaign-08.json).

## Board and conservation

18 × 18. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
.....R......R.....
......R....R......
..PPPP.R..R.PPPP..
.PPPPPP.RR.PPPPPP.
PPPBBPPPRRPPPBBPPP
PPBBBBPPRRPPBBBBPP
PPBBBBPPRRPPBBBBPP
PPPBBPPPRRPPPBBPPP
.PPPPPP.RR.PPPPPP.
..PYYYY.RR.YYYYP..
...YYYY.RR.YYYY...
..YYYYYYRRYYYYYY..
..YYYYYYRRYYYYYY..
..YYYYYYRRYYYYYY..
...YYYY.RR.YYYY...
...YYYY.RR.YYYY...
..................
..................
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 32 | 32 | 32 |
| blue | 24 | 24 | 24 |
| yellow | 68 | 68 | 68 |
| green | 0 | 0 | 0 |
| purple | 74 | 74 | 74 |
| white | 0 | 0 | 0 |

## Candidate columns (front → back)

- column-1: purple-01 purple ×9 → blue-03 blue ×2 → yellow-05 yellow ×11 → purple-06 purple ×11.
- column-2: yellow-01 yellow ×13 → purple-02 purple ×13 → yellow-06 yellow ×9 → purple-07 purple ×8.
- column-3: red-01 red ×11 → yellow-02 yellow ×11 → purple-03 purple ×11 → yellow-07 yellow ×2.
- column-4: blue-01 blue ×9 → red-02 red ×9 → yellow-03 yellow ×9 → purple-04 purple ×9.
- column-5: blue-02 blue ×13 → red-03 red ×12 → yellow-04 yellow ×13 → purple-05 purple ×13.

First-front color order purple,yellow,red,blue. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: blue ×12.
- armor-02: purple ×37.
- armor-03: yellow ×34.
- armor-04: red ×16.
- armor-05: red ×16.
- armor-06: yellow ×34.
- armor-07: purple ×37.
- armor-08: blue ×12.

Alternate forward/reverse cycles of blue,purple,yellow,red; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 72.00; speed 1.00 units/s; initial distance 72.00.
- Dispatch 0.17s; transport 14.00 cells/s; in-flight cap 20; cannon cooldown 2.10s; flight 0.95s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.55, capped at 0.55 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; available in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; available in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; locked in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; locked in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:38Z.
- Gameplay hash: `82ab07c47d8b3970d8e3eb96cfb878529ea3da8c5234ea20b3fa020700d02e13`.
- Final hit 41.832858s; final-hit contact margin 34.017142s; minimum click spacing 0.75s.
- Last pickup 35.132858s; last delivery 36.935716s; final fire 40.882858s; pickup-to-hit tail 6.700000s; delivery-to-hit tail 4.897142s.
- Maximum occupied slots 5; target-wait events 0; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | purple-01 |
| 0.750000 | column-2 | yellow-01 |
| 1.500000 | column-2 | purple-02 |
| 2.250000 | column-2 | yellow-06 |
| 3.000000 | column-2 | purple-07 |
| 3.750000 | column-3 | red-01 |
| 9.000000 | column-1 | blue-03 |
| 9.750000 | column-1 | yellow-05 |
| 10.500000 | column-1 | purple-06 |
| 11.250000 | column-3 | yellow-02 |
| 12.000000 | column-3 | purple-03 |
| 12.750000 | column-3 | yellow-07 |
| 15.000000 | column-4 | blue-01 |
| 18.000000 | column-4 | red-02 |
| 19.500000 | column-4 | yellow-03 |
| 20.250000 | column-4 | purple-04 |
| 21.000000 | column-5 | blue-02 |
| 22.500000 | column-5 | red-03 |
| 25.500000 | column-5 | yellow-04 |
| 27.000000 | column-5 | purple-05 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
