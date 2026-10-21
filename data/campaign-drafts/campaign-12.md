# 12 · Lantern Fox

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-12`; version: `campaign-draft-1.0`; seed: `2026102112`.
- Goal: Ear, eye and muzzle layers; do not overfill slots with the outer fur color.
- Progression: 11–20 layers and split quotas.
- Thumbnail: [Lantern Fox](campaign-12-thumbnail.png).
- Source: [campaign-12](campaign-12.json).

## Board and conservation

20 × 20. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
....................
....................
..R...............R.
..RRR...........RRR.
..RRPRR.......RRPRR.
..RRPPRRRRRRRRRPPRR.
..RRPPPRRRRRRPPPPRR.
..RRPPRRRRRRRRPPPRR.
...RPRRRRRRRRRRPPR..
...RRBBRRRRRRBBRRR..
...RRBBRRRRRRBBRRR..
...RRRRRRRRRRRRRRR..
...RWWWRRRRRRRWWWR..
...WWWWWWRRWWWWWWR..
...RRWWWWYYWWWWWR...
.....RRWWYYWWWRR....
......RRRWRWRRR.....
........RRRRR.......
.........RRR........
......GGGGGGGG......
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 134 | 134 | 134 |
| blue | 8 | 8 | 8 |
| yellow | 4 | 4 | 4 |
| green | 8 | 8 | 8 |
| purple | 21 | 21 | 21 |
| white | 34 | 34 | 34 |

## Candidate columns (front → back)

- column-1: red-01 red ×15 → red-06 red ×11 → red-11 red ×2.
- column-2: purple-01 purple ×13 → red-02 red ×13 → red-07 red ×15.
- column-3: white-01 white ×11 → purple-02 purple ×8 → red-03 red ×11 → red-08 red ×13.
- column-4: blue-01 blue ×8 → white-02 white ×15 → red-04 red ×15 → red-09 red ×11.
- column-5: yellow-01 yellow ×4 → green-01 green ×8 → white-03 white ×8 → red-05 red ×13 → red-10 red ×15.

First-front color order red,purple,white,blue,yellow,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: blue ×4.
- armor-02: white ×17.
- armor-03: red ×67.
- armor-04: purple ×11.
- armor-05: green ×4.
- armor-06: yellow ×2.
- armor-07: yellow ×2.
- armor-08: green ×4.
- armor-09: purple ×10.
- armor-10: red ×67.
- armor-11: white ×17.
- armor-12: blue ×4.

Alternate forward/reverse cycles of blue,white,red,purple,green,yellow; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 77.00; speed 1.00 units/s; initial distance 77.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:02:32Z.
- Gameplay hash: `f3775d693ec8fb5f054f7f802bce9b2c3c4fab09d4c14610214f5744cb2c00ce`.
- Final hit 42.660000s; final-hit contact margin 38.740000s; minimum click spacing 0.75s.
- Last pickup 33.128572s; last delivery 35.217144s; final fire 41.610000s; pickup-to-hit tail 9.531428s; delivery-to-hit tail 7.442856s.
- Maximum occupied slots 5; target-wait events 22; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | red-01 |
| 0.750000 | column-1 | red-06 |
| 1.500000 | column-1 | red-11 |
| 2.250000 | column-3 | white-01 |
| 3.000000 | column-2 | purple-01 |
| 3.750000 | column-2 | red-02 |
| 5.250000 | column-2 | red-07 |
| 6.000000 | column-5 | yellow-01 |
| 8.250000 | column-4 | blue-01 |
| 9.000000 | column-4 | white-02 |
| 12.000000 | column-4 | red-04 |
| 15.000000 | column-3 | purple-02 |
| 15.750000 | column-3 | red-03 |
| 18.300000 | column-3 | red-08 |
| 20.400000 | column-4 | red-09 |
| 21.750000 | column-5 | green-01 |
| 23.250000 | column-5 | white-03 |
| 24.000000 | column-5 | red-05 |
| 26.400000 | column-5 | red-10 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
