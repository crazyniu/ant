# 26 · Secret Garden Gate

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-26`; version: `campaign-draft-1.0`; seed: `2026102126`.
- Goal: Ring hedge encloses courtyard; flowers interrupt layers and gate stock waits.
- Progression: 21–30 combined planning.
- Thumbnail: [Secret Garden Gate](campaign-26-thumbnail.png).
- Source: [campaign-26](campaign-26.json).

## Board and conservation

24 × 22. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
........................
.........GGRRGG.........
.......GGGRWRRGGG.......
.....GGGGGRRRRGGGGG.....
....RRGGG..RR..GGGPP....
...RWRRG........GPWPP...
...RRRR..........PPPP...
...GRR............PPG...
..GGG..............GGG..
..GGG..............GGG..
..GGG..............GGG..
..GGGG............GGGG..
..PPGG..YYYYYYYY..GGRR..
.PWPPG..YYYYYYYY..GRWRR.
.PPPPG..YYBBBBYY..GRRRR.
..PPGGG.YYBBBBYY.GGGRR..
..GGGGGGYYBBBBYYGGGGGG..
..GGGGGGYYBBBBYYGGGGGG..
..GGGGGGYYBBBBYYGGGGGG..
..GGGG.GYYBBBBYYG.GGGG..
..GGGG..YYBBBBYY..GGGG..
......WWWWWWWWWWWW......
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 33 | 33 | 33 |
| blue | 28 | 28 | 28 |
| yellow | 44 | 44 | 44 |
| green | 124 | 124 | 124 |
| purple | 22 | 22 | 22 |
| white | 17 | 17 | 17 |

## Candidate columns (front → back)

- column-1: green-01 green ×11 → yellow-02 yellow ×13 → green-06 green ×13.
- column-2: red-01 red ×15 → green-02 green ×15 → blue-02 blue ×11 → yellow-03 yellow ×11 → green-07 green ×11.
- column-3: purple-01 purple ×13 → red-02 red ×13 → green-03 green ×13 → blue-03 blue ×4 → yellow-04 yellow ×5 → green-08 green ×15.
- column-4: white-01 white ×11 → purple-02 purple ×9 → red-03 red ×5 → green-04 green ×11 → green-09 green ×13.
- column-5: yellow-01 yellow ×15 → blue-01 blue ×13 → white-02 white ×6 → green-05 green ×15 → green-10 green ×7.

First-front color order green,red,purple,white,yellow,blue. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: blue ×10.
- armor-02: white ×6.
- armor-03: red ×11.
- armor-04: purple ×8.
- armor-05: green ×42.
- armor-06: yellow ×15.
- armor-07: yellow ×15.
- armor-08: green ×41.
- armor-09: purple ×7.
- armor-10: red ×11.
- armor-11: white ×6.
- armor-12: blue ×9.
- armor-13: blue ×9.
- armor-14: white ×5.
- armor-15: red ×11.
- armor-16: purple ×7.
- armor-17: green ×41.
- armor-18: yellow ×14.

Alternate forward/reverse cycles of blue,white,red,purple,green,yellow; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 100.00; speed 1.00 units/s; initial distance 100.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:45Z.
- Gameplay hash: `63a2e76c32d5f2b19baef17c612930007358bfe57d393f10985015d652c6ce86`.
- Final hit 69.550000s; final-hit contact margin 37.250000s; minimum click spacing 0.75s.
- Last pickup 39.237143s; last delivery 41.254286s; final fire 68.400000s; pickup-to-hit tail 30.312857s; delivery-to-hit tail 28.295714s.
- Maximum occupied slots 5; target-wait events 5; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | green-01 |
| 0.750000 | column-1 | yellow-02 |
| 1.500000 | column-1 | green-06 |
| 2.250000 | column-2 | red-01 |
| 3.000000 | column-2 | green-02 |
| 3.750000 | column-2 | blue-02 |
| 8.250000 | column-2 | yellow-03 |
| 9.750000 | column-2 | green-07 |
| 11.250000 | column-3 | purple-01 |
| 12.750000 | column-3 | red-02 |
| 13.500000 | column-3 | green-03 |
| 15.750000 | column-3 | blue-03 |
| 17.250000 | column-3 | yellow-04 |
| 18.000000 | column-3 | green-08 |
| 20.250000 | column-4 | white-01 |
| 21.000000 | column-4 | purple-02 |
| 21.750000 | column-4 | red-03 |
| 22.500000 | column-4 | green-04 |
| 25.500000 | column-4 | green-09 |
| 27.750000 | column-5 | yellow-01 |
| 28.500000 | column-5 | blue-01 |
| 29.250000 | column-5 | white-02 |
| 30.000000 | column-5 | green-05 |
| 33.000000 | column-5 | green-10 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
