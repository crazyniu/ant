# 13 · Hummingbird Visit

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-13`; version: `campaign-draft-1.0`; seed: `2026102113`.
- Goal: Separated flower and bird regions; six-color queue with two destinations.
- Progression: 11–20 layers and split quotas.
- Thumbnail: [Hummingbird Visit](campaign-13-thumbnail.png).
- Source: [campaign-13](campaign-13.json).

## Board and conservation

20 × 20. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
....................
....................
.....G..............
.....GG.............
......GG......YYY.RR
......GGG....YYYWR..
......GGGG...YYYYY..
.BB....GGGGGGYYYYY..
..BBBB.GGGGGGGYYY...
...BBBBBBGGGGGGG....
....BBBBBGGGGGGG....
.....BBBBGGGGGGG....
.....BBBBGGGGGGG....
.........BGGGGG.....
.........P.GGG......
.RRR....PP..........
RRRRR..PPP..........
RRYRRPPPPP..........
RRRRR..PPP..........
.RRR................
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 23 | 23 | 23 |
| blue | 26 | 26 | 26 |
| yellow | 20 | 20 | 20 |
| green | 61 | 61 | 61 |
| purple | 14 | 14 | 14 |
| white | 1 | 1 | 1 |

## Candidate columns (front → back)

- column-1: green-01 green ×12 → purple-02 purple ×2 → green-05 green ×10.
- column-2: blue-01 blue ×10 → green-06 green ×3.
- column-3: yellow-01 yellow ×14 → green-02 green ×10 → red-02 red ×9.
- column-4: purple-01 purple ×12 → blue-02 blue ×14 → green-03 green ×14.
- column-5: white-01 white ×1 → red-01 red ×14 → yellow-02 yellow ×6 → blue-03 blue ×2 → green-04 green ×12.

First-front color order green,blue,yellow,purple,white,red. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: purple ×7.
- armor-02: red ×12.
- armor-03: green ×31.
- armor-04: blue ×13.
- armor-05: yellow ×10.
- armor-06: white ×1.
- armor-07: yellow ×10.
- armor-08: blue ×13.
- armor-09: green ×30.
- armor-10: red ×11.
- armor-11: purple ×7.

Alternate forward/reverse cycles of purple,red,green,blue,yellow,white; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 64.00; speed 1.00 units/s; initial distance 64.00.
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
- Gameplay hash: `b791e7d01922e45668dcb2343541553f76fd45cb1399fca479596ddf9a6d30a5`.
- Final hit 39.674286s; final-hit contact margin 28.325714s; minimum click spacing 0.75s.
- Last pickup 23.242858s; last delivery 25.045716s; final fire 38.624286s; pickup-to-hit tail 16.431428s; delivery-to-hit tail 14.628570s.
- Maximum occupied slots 5; target-wait events 1; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | green-01 |
| 0.750000 | column-1 | purple-02 |
| 1.500000 | column-1 | green-05 |
| 2.250000 | column-2 | blue-01 |
| 3.000000 | column-2 | green-06 |
| 3.750000 | column-3 | yellow-01 |
| 4.500000 | column-3 | green-02 |
| 5.250000 | column-3 | red-02 |
| 6.000000 | column-4 | purple-01 |
| 7.500000 | column-4 | blue-02 |
| 12.000000 | column-4 | green-03 |
| 12.750000 | column-5 | white-01 |
| 13.500000 | column-5 | red-01 |
| 14.250000 | column-5 | yellow-02 |
| 16.500000 | column-5 | blue-03 |
| 17.250000 | column-5 | green-04 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
