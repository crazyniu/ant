# 29 · Orchid Guardian

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-29`; version: `campaign-draft-1.0`; seed: `2026102129`.
- Goal: Wings, jaw and belly occupy different channels; six-color endgame cadence.
- Progression: 21–30 combined planning.
- Thumbnail: [Orchid Guardian](campaign-29-thumbnail.png).
- Source: [campaign-29](campaign-29.json).

## Board and conservation

24 × 24. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
........................
...........RR..RR.......
...........RR..RR.......
...........RRGGRR.......
.........GGRRGGRRG.YY...
.P.......GGGGGGGGGGYYGG.
.PP.....GGGGGGGGGGBGGGG.
.PPP....GGGGGGGGGGGGGGG.
.PPPP...GGGGGGGGGGGGGGG.
..PPPP..GGGGGGGGGG......
..PPPP.GGGGGPPPPPPPPPP..
..PPPPGGGGGGGPPPPPPPPP..
..PPPPGGGWWGGPPPPPPPP...
..PPPPGGWWWWGPPPPPPP....
..PPPPGGWWWWGPPPPPPP....
....PPGGWWWWGPPPPPP.....
.....PGGWWWWGPPPPP......
.RRRRGGGWWWWGGG.........
RRRRRRGGGWWGGG..........
RRYRRRGGYYYYYY..........
RRRRRR.GYYYYYYY.........
RRBRRR..YYYYYYYY........
.RBRR..YYYYYYYYYY.......
.B.....YYYYY............
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 45 | 45 | 45 |
| blue | 4 | 4 | 4 |
| yellow | 41 | 41 | 41 |
| green | 117 | 117 | 117 |
| purple | 89 | 89 | 89 |
| white | 24 | 24 | 24 |

## Candidate columns (front → back)

- column-1: green-01 green ×12 → white-02 white ×12 → yellow-03 yellow ×15 → purple-04 purple ×16 → green-05 green ×16.
- column-2: purple-01 purple ×16 → red-02 red ×14 → purple-05 purple ×14 → green-06 green ×14.
- column-3: yellow-01 yellow ×14 → green-02 green ×16 → red-03 red ×12 → purple-06 purple ×12 → green-07 green ×12.
- column-4: white-01 white ×12 → purple-02 purple ×14 → green-03 green ×14 → red-04 red ×3 → purple-07 purple ×5 → green-08 green ×16.
- column-5: red-01 red ×16 → blue-01 blue ×4 → yellow-02 yellow ×12 → purple-03 purple ×12 → green-04 green ×12 → green-09 green ×5.

First-front color order green,purple,yellow,white,red,blue. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: blue ×2.
- armor-02: white ×8.
- armor-03: green ×39.
- armor-04: purple ×30.
- armor-05: red ×15.
- armor-06: yellow ×14.
- armor-07: yellow ×14.
- armor-08: red ×15.
- armor-09: purple ×30.
- armor-10: green ×39.
- armor-11: white ×8.
- armor-12: blue ×1.
- armor-13: blue ×1.
- armor-14: white ×8.
- armor-15: green ×39.
- armor-16: purple ×29.
- armor-17: red ×15.
- armor-18: yellow ×13.

Alternate forward/reverse cycles of blue,white,green,purple,red,yellow; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 109.00; speed 1.00 units/s; initial distance 109.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:46Z.
- Gameplay hash: `83b41b703343310f874c5acea0d67372081aed845b89810958358cfc93608283`.
- Final hit 84.344286s; final-hit contact margin 31.455714s; minimum click spacing 0.75s.
- Last pickup 47.568572s; last delivery 49.665716s; final fire 83.194286s; pickup-to-hit tail 36.775714s; delivery-to-hit tail 34.678570s.
- Maximum occupied slots 5; target-wait events 6; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | green-01 |
| 0.750000 | column-2 | purple-01 |
| 1.500000 | column-2 | red-02 |
| 2.250000 | column-2 | purple-05 |
| 3.000000 | column-2 | green-06 |
| 3.750000 | column-3 | yellow-01 |
| 10.500000 | column-1 | white-02 |
| 11.250000 | column-1 | yellow-03 |
| 12.000000 | column-1 | purple-04 |
| 12.750000 | column-1 | green-05 |
| 13.500000 | column-3 | green-02 |
| 18.750000 | column-3 | red-03 |
| 21.000000 | column-3 | purple-06 |
| 23.250000 | column-3 | green-07 |
| 24.000000 | column-4 | white-01 |
| 24.750000 | column-4 | purple-02 |
| 26.250000 | column-4 | green-03 |
| 29.250000 | column-4 | red-04 |
| 31.500000 | column-4 | purple-07 |
| 32.250000 | column-4 | green-08 |
| 33.000000 | column-5 | red-01 |
| 34.500000 | column-5 | blue-01 |
| 35.250000 | column-5 | yellow-02 |
| 36.000000 | column-5 | purple-03 |
| 42.000000 | column-5 | green-04 |
| 42.750000 | column-5 | green-09 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
