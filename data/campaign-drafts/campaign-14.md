# 14 · Jade Teapot

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-14`; version: `campaign-draft-1.0`; seed: `2026102114`.
- Goal: Handle hole remains enclosed; clear blue body before white and green medallion.
- Progression: 11–20 layers and split quotas.
- Thumbnail: [Jade Teapot](campaign-14-thumbnail.png).
- Source: [campaign-14](campaign-14.json).

## Board and conservation

20 × 18. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
.......RRRR.........
.......RRRR.........
....YYYYYYYYYY......
....YYYYYYYYYY......
B...YYYYYYYYYY..PP..
BB..BBBBBBBBBB.PPPP.
BBBBBBBBBBBBBBPP..PP
BBBBBBBWWWWBBBPP..PP
BBBBBBWWGGWWBBPP..PP
BBBBBWWGGGGWWBPP..PP
BBBBBWWGGGGWWBBPPPP.
..BBBWWWGGWWWBBBPP..
...BBBWWWWWWBBB.....
...BBBBWWWWBBBB.....
....BBBBBBBBBB......
......BBBBBB........
....YYYYYYYYYYY.....
....YYYYYYYYYYY.....
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 8 | 8 | 8 |
| blue | 94 | 94 | 94 |
| yellow | 52 | 52 | 52 |
| green | 12 | 12 | 12 |
| purple | 28 | 28 | 28 |
| white | 32 | 32 | 32 |

## Candidate columns (front → back)

- column-1: blue-01 blue ×11 → white-03 white ×6 → blue-06 blue ×13.
- column-2: yellow-01 yellow ×15 → blue-02 blue ×15 → blue-07 blue ×11.
- column-3: purple-01 purple ×13 → yellow-02 yellow ×13 → blue-03 blue ×13 → blue-08 blue ×5.
- column-4: white-01 white ×11 → purple-02 purple ×11 → yellow-03 yellow ×11 → blue-04 blue ×11.
- column-5: red-01 red ×8 → green-01 green ×12 → white-02 white ×15 → purple-03 purple ×4 → yellow-04 yellow ×13 → blue-05 blue ×15.

First-front color order blue,yellow,purple,white,red,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: green ×6.
- armor-02: white ×16.
- armor-03: blue ×47.
- armor-04: red ×4.
- armor-05: yellow ×26.
- armor-06: purple ×14.
- armor-07: purple ×14.
- armor-08: yellow ×26.
- armor-09: red ×4.
- armor-10: blue ×47.
- armor-11: white ×16.
- armor-12: green ×6.

Alternate forward/reverse cycles of green,white,blue,red,yellow,purple; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 80.00; speed 1.00 units/s; initial distance 80.00.
- Dispatch 0.15s; transport 14.00 cells/s; in-flight cap 24; cannon cooldown 2.40s; flight 1.05s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.40, capped at 0.40 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; available in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; available in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; available in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; locked in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:02:33Z.
- Gameplay hash: `4280a31753503753b8cf3aa694142c82279616894a8cd2ea2e50a4da0ace145c`.
- Final hit 54.988572s; final-hit contact margin 29.411428s; minimum click spacing 0.75s.
- Last pickup 35.535715s; last delivery 37.481430s; final fire 53.938572s; pickup-to-hit tail 19.452857s; delivery-to-hit tail 17.507142s.
- Maximum occupied slots 5; target-wait events 2; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | blue-01 |
| 0.750000 | column-2 | yellow-01 |
| 1.500000 | column-2 | blue-02 |
| 2.250000 | column-1 | white-03 |
| 3.000000 | column-1 | blue-06 |
| 3.750000 | column-2 | blue-07 |
| 7.200000 | column-3 | purple-01 |
| 9.750000 | column-3 | yellow-02 |
| 11.250000 | column-3 | blue-03 |
| 12.000000 | column-3 | blue-08 |
| 12.750000 | column-4 | white-01 |
| 15.750000 | column-4 | purple-02 |
| 16.800000 | column-4 | yellow-03 |
| 19.500000 | column-4 | blue-04 |
| 21.000000 | column-5 | red-01 |
| 21.750000 | column-5 | green-01 |
| 24.000000 | column-5 | white-02 |
| 24.750000 | column-5 | purple-03 |
| 26.400000 | column-5 | yellow-04 |
| 27.750000 | column-5 | blue-05 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
