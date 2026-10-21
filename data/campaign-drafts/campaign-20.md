# 20 · Rainbow Spiral Shell

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-20`; version: `campaign-draft-1.0`; seed: `2026102120`.
- Goal: Six nested colored bands with a diagonal opening; repeated demands store surplus.
- Progression: 11–20 layers and split quotas.
- Thumbnail: [Rainbow Spiral Shell](campaign-20-thumbnail.png).
- Source: [campaign-20](campaign-20.json).

## Board and conservation

22 × 20. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
......................
........PPPPPP........
.....PPPPPPPPPPPP.....
....PPPPBBBBBBPPPP....
...PPPBBBBBBBBBBPP....
..PPPBBBBGGGGBBBBP....
..PPBBBGGGGGGGGBBB....
.PPPBBGGGYYYYGGGBBPPP.
.PPBBGGGYYRRYYGGGBBPP.
.PPBBGGYYRRRRYYGGBBPP.
.PPBBGGYYRWWRYYGGBBPP.
.PPBBGGYYYYRYYYGGBBPP.
.PPPBGGGYYYYYYGGGBPPP.
..PPBBGGGYYYYYYGBBPP..
..PPPBBGGGGGYYYYBPPP..
...PPPBBBGGGGBYYYYP...
....PPPPBBBBBBPYYYYY..
......PPPPPPPPPPPYYYY.
........PPPPPP.....YY.
......................
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 9 | 9 | 9 |
| blue | 69 | 69 | 69 |
| yellow | 54 | 54 | 54 |
| green | 55 | 55 | 55 |
| purple | 101 | 101 | 101 |
| white | 2 | 2 | 2 |

## Candidate columns (front → back)

- column-1: purple-01 purple ×12 → yellow-03 yellow ×14 → green-04 green ×13 → blue-05 blue ×11 → purple-06 purple ×14.
- column-2: blue-01 blue ×16 → purple-02 purple ×16 → yellow-04 yellow ×12 → purple-07 purple ×12.
- column-3: green-01 green ×14 → blue-02 blue ×14 → purple-03 purple ×14 → purple-08 purple ×5.
- column-4: yellow-01 yellow ×12 → green-02 green ×12 → blue-03 blue ×12 → purple-04 purple ×12.
- column-5: red-01 red ×9 → white-01 white ×2 → yellow-02 yellow ×16 → green-03 green ×16 → blue-04 blue ×16 → purple-05 purple ×16.

First-front color order purple,blue,green,yellow,red,white. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: red ×3.
- armor-02: white ×1.
- armor-03: purple ×34.
- armor-04: blue ×23.
- armor-05: green ×19.
- armor-06: yellow ×18.
- armor-07: yellow ×18.
- armor-08: green ×18.
- armor-09: blue ×23.
- armor-10: purple ×34.
- armor-11: white ×1.
- armor-12: red ×3.
- armor-13: red ×3.
- armor-14: purple ×33.
- armor-15: blue ×23.
- armor-16: green ×18.
- armor-17: yellow ×18.

Alternate forward/reverse cycles of red,white,purple,blue,green,yellow; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 100.00; speed 1.00 units/s; initial distance 100.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:02:35Z.
- Gameplay hash: `57e24dab8430a978c95a6696d2d4fef274745ee3600b3bf46468ee10dbe222ec`.
- Final hit 73.424286s; final-hit contact margin 32.975714s; minimum click spacing 0.75s.
- Last pickup 45.450000s; last delivery 47.110000s; final fire 72.374286s; pickup-to-hit tail 27.974286s; delivery-to-hit tail 26.314286s.
- Maximum occupied slots 5; target-wait events 18; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | purple-01 |
| 0.750000 | column-1 | yellow-03 |
| 1.500000 | column-2 | blue-01 |
| 2.250000 | column-1 | green-04 |
| 3.000000 | column-1 | blue-05 |
| 3.750000 | column-1 | purple-06 |
| 9.000000 | column-2 | purple-02 |
| 10.500000 | column-2 | yellow-04 |
| 12.750000 | column-2 | purple-07 |
| 13.500000 | column-3 | green-01 |
| 14.250000 | column-3 | blue-02 |
| 19.500000 | column-3 | purple-03 |
| 21.000000 | column-3 | purple-08 |
| 21.750000 | column-4 | yellow-01 |
| 23.550000 | column-4 | green-02 |
| 24.750000 | column-4 | blue-03 |
| 25.500000 | column-4 | purple-04 |
| 30.000000 | column-5 | red-01 |
| 30.750000 | column-5 | white-01 |
| 32.250000 | column-5 | yellow-02 |
| 33.000000 | column-5 | green-03 |
| 33.750000 | column-5 | blue-04 |
| 34.500000 | column-5 | purple-05 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
