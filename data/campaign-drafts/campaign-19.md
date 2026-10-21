# 19 · Moonlit Palace

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-19`; version: `campaign-draft-1.0`; seed: `2026102119`.
- Goal: Crescent and twin towers; white roof and yellow gate release on different paths.
- Progression: 11–20 layers and split quotas.
- Thumbnail: [Moonlit Palace](campaign-19-thumbnail.png).
- Source: [campaign-19](campaign-19.json).

## Board and conservation

22 × 20. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
....YYY...............
...YYY................
..YYY.................
.YYYY..............R..
.YYYY...R.........RRR.
.YYYY..RRR........RRR.
.YYYY..RRR.......RRRRR
.YYYYYRRRRRWWWWWWBBBBB
..YYYYBBBBBWWWWWWBBBBB
...YYYBBBBBWWWWWWBBBBB
....YYBBBBBWWWWWWBBBBB
......BBBBBPPPPPPBBBBB
......BBBBBPYYYYPBBBBB
......BBBBBPYYYYPBBBBB
......BBBBBPYYYYPBBBBB
......BBBBBPYYYYPBBBBB
......BBBBBPYYYYPBBBBB
......BBBBBPYYYYPBBBBB
........PPPPYYYYPPPP..
....GGGGGGGGGGGGGGGGGG
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 24 | 24 | 24 |
| blue | 105 | 105 | 105 |
| yellow | 67 | 67 | 67 |
| green | 18 | 18 | 18 |
| purple | 26 | 26 | 26 |
| white | 24 | 24 | 24 |

## Candidate columns (front → back)

- column-1: yellow-01 yellow ×14 → red-02 red ×10 → blue-04 blue ×12 → yellow-05 yellow ×11.
- column-2: blue-01 blue ×12 → white-02 white ×12 → blue-05 blue ×16.
- column-3: purple-01 purple ×16 → yellow-02 yellow ×12 → green-02 green ×2 → blue-06 blue ×14.
- column-4: red-01 red ×14 → blue-02 blue ×16 → yellow-03 yellow ×16 → blue-07 blue ×12.
- column-5: white-01 white ×12 → green-01 green ×16 → purple-02 purple ×10 → blue-03 blue ×14 → yellow-04 yellow ×14 → blue-08 blue ×9.

First-front color order yellow,blue,purple,red,white,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: white ×8.
- armor-02: purple ×9.
- armor-03: yellow ×23.
- armor-04: blue ×35.
- armor-05: green ×6.
- armor-06: red ×8.
- armor-07: red ×8.
- armor-08: green ×6.
- armor-09: blue ×35.
- armor-10: yellow ×22.
- armor-11: purple ×9.
- armor-12: white ×8.
- armor-13: white ×8.
- armor-14: purple ×8.
- armor-15: yellow ×22.
- armor-16: blue ×35.
- armor-17: green ×6.
- armor-18: red ×8.

Alternate forward/reverse cycles of white,purple,yellow,blue,green,red; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 96.00; speed 1.00 units/s; initial distance 96.00.
- Dispatch 0.15s; transport 14.00 cells/s; in-flight cap 24; cannon cooldown 2.40s; flight 1.05s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.40, capped at 0.40 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; available in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; available in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; available in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; available in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:02:34Z.
- Gameplay hash: `91a8851862602803fdd24816c8b11c4b391319d526863e760644b1f15212c103`.
- Final hit 61.260000s; final-hit contact margin 41.540000s; minimum click spacing 0.75s.
- Last pickup 41.671429s; last delivery 43.902858s; final fire 60.210000s; pickup-to-hit tail 19.588571s; delivery-to-hit tail 17.357142s.
- Maximum occupied slots 5; target-wait events 1; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | yellow-01 |
| 0.750000 | column-1 | red-02 |
| 1.500000 | column-1 | blue-04 |
| 2.250000 | column-1 | yellow-05 |
| 3.000000 | column-2 | blue-01 |
| 5.250000 | column-2 | white-02 |
| 6.000000 | column-2 | blue-05 |
| 9.750000 | column-3 | purple-01 |
| 10.500000 | column-3 | yellow-02 |
| 12.000000 | column-3 | green-02 |
| 13.500000 | column-3 | blue-06 |
| 14.250000 | column-4 | red-01 |
| 18.150000 | column-4 | blue-02 |
| 19.500000 | column-4 | yellow-03 |
| 21.750000 | column-4 | blue-07 |
| 24.000000 | column-5 | white-01 |
| 24.750000 | column-5 | green-01 |
| 30.150000 | column-5 | purple-02 |
| 30.900000 | column-5 | blue-03 |
| 31.650000 | column-5 | yellow-04 |
| 33.000000 | column-5 | blue-08 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
