# 30 · Rescue Crown

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-30`; version: `campaign-draft-1.0`; seed: `2026102130`.
- Goal: Crown points expose three gems; combine queue planning, split quotas and final flight.
- Progression: 21–30 combined planning.
- Thumbnail: [Rescue Crown](campaign-30-thumbnail.png).
- Source: [campaign-30](campaign-30.json).

## Board and conservation

24 × 24. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
............W...........
........................
.W..........Y..........W
...........YYY..........
...........YYY..........
..Y.......YYYYY.......Y.
..YY......YYYYY......YY.
..YYY....YYYYYYY....YYY.
...YYY...YYYYYYY...YYY..
...YYYY.YYYYYYYYY.YYYY..
...YYYYYYYBBBBYYYYYYYY..
...YYYYYYBBBBBBYYYYYYY..
...YYPPYYBBBBBBYYGGYYY..
....YPPYYBBBBBBYYGGYY...
....YPPYYBBBBBBYYGGYY...
....YYYYYYBBBBYYYYYYY...
....RRRRRRRRRRRRRRRRY...
....RRRRRRRRRRRRRRRR....
....RRRRRRRRRRRRRRRR....
....RRRRRRRRRRRRRRRR....
.....YYYYYYYYYYYYYY.....
.....YYYYYYYYYYYYYY.....
........................
....WWWWWW....WWWWWW....
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 64 | 64 | 64 |
| blue | 32 | 32 | 32 |
| yellow | 159 | 159 | 159 |
| green | 6 | 6 | 6 |
| purple | 6 | 6 | 6 |
| white | 15 | 15 | 15 |

## Candidate columns (front → back)

- column-1: yellow-01 yellow ×15 → blue-03 blue ×4 → red-05 red ×11 → yellow-06 yellow ×11 → yellow-11 yellow ×13.
- column-2: red-01 red ×13 → yellow-02 yellow ×13 → white-02 white ×4 → red-06 red ×1 → yellow-07 yellow ×15 → yellow-12 yellow ×11.
- column-3: purple-01 purple ×6 → red-02 red ×11 → yellow-03 yellow ×11 → yellow-08 yellow ×13 → yellow-13 yellow ×3.
- column-4: blue-01 blue ×15 → red-03 red ×15 → yellow-04 yellow ×15 → yellow-09 yellow ×11.
- column-5: green-01 green ×6 → white-01 white ×11 → blue-02 blue ×13 → red-04 red ×13 → yellow-05 yellow ×13 → yellow-10 yellow ×15.

First-front color order yellow,red,purple,blue,green,white. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: blue ×11.
- armor-02: purple ×2.
- armor-03: green ×2.
- armor-04: yellow ×53.
- armor-05: red ×22.
- armor-06: white ×5.
- armor-07: white ×5.
- armor-08: red ×21.
- armor-09: yellow ×53.
- armor-10: green ×2.
- armor-11: purple ×2.
- armor-12: blue ×11.
- armor-13: blue ×10.
- armor-14: purple ×2.
- armor-15: green ×2.
- armor-16: yellow ×53.
- armor-17: red ×21.
- armor-18: white ×5.

Alternate forward/reverse cycles of blue,purple,green,yellow,red,white; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 103.00; speed 1.00 units/s; initial distance 103.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:47Z.
- Gameplay hash: `27f1b50490b606f44366136a10c10bd644c28fa7c5c5bdf9d2419082bb16819b`.
- Final hit 72.304286s; final-hit contact margin 37.495714s; minimum click spacing 0.75s.
- Last pickup 41.482858s; last delivery 43.785716s; final fire 71.154286s; pickup-to-hit tail 30.821428s; delivery-to-hit tail 28.518570s.
- Maximum occupied slots 5; target-wait events 4; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | yellow-01 |
| 0.750000 | column-2 | red-01 |
| 1.500000 | column-2 | yellow-02 |
| 2.250000 | column-2 | white-02 |
| 3.000000 | column-2 | red-06 |
| 3.750000 | column-2 | yellow-07 |
| 4.500000 | column-2 | yellow-12 |
| 6.000000 | column-1 | blue-03 |
| 8.250000 | column-1 | red-05 |
| 9.000000 | column-1 | yellow-06 |
| 9.750000 | column-1 | yellow-11 |
| 12.750000 | column-3 | purple-01 |
| 13.500000 | column-3 | red-02 |
| 15.750000 | column-3 | yellow-03 |
| 16.500000 | column-3 | yellow-08 |
| 18.000000 | column-3 | yellow-13 |
| 18.750000 | column-4 | blue-01 |
| 20.250000 | column-4 | red-03 |
| 21.000000 | column-4 | yellow-04 |
| 22.500000 | column-4 | yellow-09 |
| 25.500000 | column-5 | green-01 |
| 29.250000 | column-5 | white-01 |
| 30.000000 | column-5 | blue-02 |
| 30.750000 | column-5 | red-04 |
| 31.500000 | column-5 | yellow-05 |
| 32.250000 | column-5 | yellow-10 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
