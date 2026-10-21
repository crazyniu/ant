# 21 · Dragon Egg Shrine

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-21`; version: `campaign-draft-1.0`; seed: `2026102121`.
- Goal: Outer egg, purple core and yellow lightning share attention with two side pillars.
- Progression: 21–30 combined planning.
- Thumbnail: [Dragon Egg Shrine](campaign-21-thumbnail.png).
- Source: [campaign-21](campaign-21.json).

## Board and conservation

22 × 22. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
......................
.........WWWW.........
........WWWWWW........
.......WWWWWWWW.......
.YYY..WWWPPPPWWW..YYY.
.YYY..WWPPPPPPWW..YYY.
.YYY.WWWPPPPPPWWW.YYY.
..G..WWPPYPPPPPWW..G..
..G..WWPPYPPPPPWW..G..
..G..WWPYYYYYYPWW..G..
..G..WWPPPPPYYPWW..G..
..G..WWPPPPPYPPWW..G..
..G..WWWPPPYPPWWW..G..
..G...WWPPPPPPWW...G..
..G...WWWPPPPWWW...G..
..G....WWWWWWWW....G..
........WWWWWW........
...RRRRRRRRRRRRRRRR...
...RRRRRRRRRRRRRRRR...
...RRRRRRRRRRRRRRRR...
.BBBBBBBBBBBBBBBBBBBB.
.BBBBBBBBBBBBBBBBBBBB.
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 48 | 48 | 48 |
| blue | 40 | 40 | 40 |
| yellow | 30 | 30 | 30 |
| green | 18 | 18 | 18 |
| purple | 60 | 60 | 60 |
| white | 84 | 84 | 84 |

## Candidate columns (front → back)

- column-1: white-01 white ×15 → blue-02 blue ×13 → purple-03 purple ×13 → red-04 red ×9 → white-05 white ×13.
- column-2: red-01 red ×13 → yellow-02 yellow ×11 → blue-03 blue ×11 → purple-04 purple ×11 → white-06 white ×11.
- column-3: purple-01 purple ×11 → white-02 white ×13 → green-02 green ×7 → yellow-03 yellow ×6 → blue-04 blue ×1 → purple-05 purple ×10 → white-07 white ×6.
- column-4: blue-01 blue ×15 → red-02 red ×11 → white-03 white ×11.
- column-5: yellow-01 yellow ×13 → green-01 green ×11 → purple-02 purple ×15 → red-03 red ×15 → white-04 white ×15.

First-front color order white,red,purple,blue,yellow,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: purple ×20.
- armor-02: yellow ×10.
- armor-03: white ×28.
- armor-04: blue ×14.
- armor-05: red ×16.
- armor-06: green ×6.
- armor-07: green ×6.
- armor-08: red ×16.
- armor-09: blue ×13.
- armor-10: white ×28.
- armor-11: yellow ×10.
- armor-12: purple ×20.
- armor-13: purple ×20.
- armor-14: yellow ×10.
- armor-15: white ×28.
- armor-16: blue ×13.
- armor-17: red ×16.
- armor-18: green ×6.

Alternate forward/reverse cycles of purple,yellow,white,blue,red,green; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 102.00; speed 1.00 units/s; initial distance 102.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:02:36Z.
- Gameplay hash: `893e090b55aaa79a985a14f864d4f9906fe6800b2519e8a932a00c0c7449d505`.
- Final hit 64.887144s; final-hit contact margin 43.912856s; minimum click spacing 0.75s.
- Last pickup 40.845715s; last delivery 42.791430s; final fire 63.737144s; pickup-to-hit tail 24.041429s; delivery-to-hit tail 22.095714s.
- Maximum occupied slots 5; target-wait events 25; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | white-01 |
| 0.750000 | column-1 | blue-02 |
| 1.500000 | column-2 | red-01 |
| 2.250000 | column-2 | yellow-02 |
| 3.000000 | column-2 | blue-03 |
| 6.000000 | column-1 | purple-03 |
| 8.250000 | column-1 | red-04 |
| 9.750000 | column-1 | white-05 |
| 10.500000 | column-2 | purple-04 |
| 11.250000 | column-2 | white-06 |
| 14.250000 | column-3 | purple-01 |
| 15.000000 | column-3 | white-02 |
| 18.000000 | column-3 | green-02 |
| 18.750000 | column-3 | yellow-03 |
| 20.020000 | column-3 | blue-04 |
| 20.770000 | column-3 | purple-05 |
| 21.750000 | column-3 | white-07 |
| 22.500000 | column-4 | blue-01 |
| 23.250000 | column-4 | red-02 |
| 24.000000 | column-4 | white-03 |
| 25.500000 | column-5 | yellow-01 |
| 27.000000 | column-5 | green-01 |
| 30.750000 | column-5 | purple-02 |
| 31.500000 | column-5 | red-03 |
| 32.250000 | column-5 | white-04 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
