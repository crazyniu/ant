# 28 · Crystal Citadel

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-28`; version: `campaign-draft-1.0`; seed: `2026102128`.
- Goal: Three towers, two windows and enclosed gate: multi-object quota planning.
- Progression: 21–30 combined planning.
- Thumbnail: [Crystal Citadel](campaign-28-thumbnail.png).
- Source: [campaign-28](campaign-28.json).

## Board and conservation

24 × 24. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
........................
............Y...........
...R.......YYY......R...
..RR......YYYYY....RR...
..RRR....YYYYYYY...RRR..
.RRRR....PPPPPP...RRRR..
.RRRRR...PPPPPP...RRRRR.
.WWWWW...PPPPPP...WWWWW.
.WWWWW...PPPPPP...WWWWW.
.WBBWW...PPPPPP...WWBBW.
.WBBWW...PPPPPP...WWBBW.
.WBBWWBBBPPPPPPBBBWWBBW.
.WWWWWBBBPPPPPPBBBWWWWW.
.WWWWWGGBPPPPPPBGGWWWWW.
.WWWWWGGBPYYYYPBGGWWWWW.
.WWWWWGGBPYYYYPBGGWWWWW.
.WWWWWBBBPYYYYPBBBWWWWW.
.WWWWWBBBPYYYYPBBBWWWWW.
.WWWWWBBBPYYYYPBBBWWWWW.
.WWWWWBBBPYYYYPBBBWWWWW.
.WWWWWBBBPYYYYPBBBWWWWW.
...BBBBBBPYYYYPBBBBBB...
.GGGGGGGGGGGGGGGGGGGGGG.
.GGGGGGGGGGGGGGGGGGGGGG.
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 30 | 30 | 30 |
| blue | 72 | 72 | 72 |
| yellow | 48 | 48 | 48 |
| green | 56 | 56 | 56 |
| purple | 70 | 70 | 70 |
| white | 128 | 128 | 128 |

## Candidate columns (front → back)

- column-1: white-01 white ×14 → yellow-02 yellow ×16 → purple-03 purple ×16 → blue-04 blue ×16 → white-06 white ×16.
- column-2: red-01 red ×12 → white-02 white ×12 → green-02 green ×14 → yellow-03 yellow ×14 → purple-04 purple ×14 → blue-05 blue ×14 → white-07 white ×14.
- column-3: blue-01 blue ×16 → red-02 red ×16 → white-03 white ×16 → green-03 green ×12 → yellow-04 yellow ×6 → purple-05 purple ×12 → white-08 white ×12.
- column-4: purple-01 purple ×14 → blue-02 blue ×14 → red-03 red ×2 → white-04 white ×14 → green-04 green ×14 → purple-06 purple ×2 → white-09 white ×16.
- column-5: yellow-01 yellow ×12 → green-01 green ×16 → purple-02 purple ×12 → blue-03 blue ×12 → white-05 white ×12 → white-10 white ×2.

First-front color order white,red,blue,purple,yellow,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: purple ×24.
- armor-02: yellow ×16.
- armor-03: blue ×24.
- armor-04: white ×43.
- armor-05: red ×10.
- armor-06: green ×19.
- armor-07: green ×19.
- armor-08: red ×10.
- armor-09: white ×43.
- armor-10: blue ×24.
- armor-11: yellow ×16.
- armor-12: purple ×23.
- armor-13: purple ×23.
- armor-14: yellow ×16.
- armor-15: blue ×24.
- armor-16: white ×42.
- armor-17: red ×10.
- armor-18: green ×18.

Alternate forward/reverse cycles of purple,yellow,blue,white,red,green; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 125.00; speed 1.00 units/s; initial distance 125.00.
- Dispatch 0.14s; transport 14.00 cells/s; in-flight cap 24; cannon cooldown 2.70s; flight 1.15s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.40, capped at 0.40 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; available in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; available in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; available in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; available in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:02:40Z.
- Gameplay hash: `5a93d029885b7899d426773aa8dd33561cac765ca0ef3d054d4d27fdd3b767ae`.
- Final hit 84.101430s; final-hit contact margin 47.698570s; minimum click spacing 0.75s.
- Last pickup 63.948572s; last delivery 66.037144s; final fire 82.951430s; pickup-to-hit tail 20.152858s; delivery-to-hit tail 18.064286s.
- Maximum occupied slots 5; target-wait events 7; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | white-01 |
| 0.750000 | column-1 | yellow-02 |
| 1.500000 | column-1 | purple-03 |
| 2.250000 | column-1 | blue-04 |
| 3.000000 | column-1 | white-06 |
| 5.250000 | column-2 | red-01 |
| 14.000000 | column-2 | white-02 |
| 15.400000 | column-2 | green-02 |
| 17.640000 | column-2 | yellow-03 |
| 18.390000 | column-2 | purple-04 |
| 19.140000 | column-2 | blue-05 |
| 23.800000 | column-2 | white-07 |
| 26.040000 | column-3 | blue-01 |
| 27.580000 | column-3 | red-02 |
| 28.330000 | column-3 | white-03 |
| 29.080000 | column-3 | green-03 |
| 33.600000 | column-3 | yellow-04 |
| 36.820000 | column-3 | purple-05 |
| 37.570000 | column-3 | white-08 |
| 38.320000 | column-4 | purple-01 |
| 39.070000 | column-4 | blue-02 |
| 39.820000 | column-4 | red-03 |
| 40.740000 | column-4 | white-04 |
| 45.220000 | column-4 | green-04 |
| 45.970000 | column-4 | purple-06 |
| 47.040000 | column-4 | white-09 |
| 47.790000 | column-5 | yellow-01 |
| 48.860000 | column-5 | green-01 |
| 50.680000 | column-5 | purple-02 |
| 55.020000 | column-5 | blue-03 |
| 56.000000 | column-5 | white-05 |
| 58.240000 | column-5 | white-10 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
