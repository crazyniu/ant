# 18 · Coral Seahorse

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-18`; version: `campaign-draft-1.0`; seed: `2026102118`.
- Goal: Curved tail and body channels; keep a slot for the last blue bubbles.
- Progression: 11–20 layers and split quotas.
- Thumbnail: [Coral Seahorse](campaign-18-thumbnail.png).
- Source: [campaign-18](campaign-18.json).

## Board and conservation

20 × 22. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
....................
.........YYYYY......
........YYYYYYY.....
.......YYYYYYBYY....
.......YYYYYYYYYYYYY
.......YYYYYYYYYYYYY
.......YYYYYYYYYYYYY
.......YYYYYYYY.....
....PPPYYWWWYY......
..PPPPPYYWWWY.......
....PPPYYWWWY....B..
.....PPYYWWWY.......
......PYYWWWY.......
.....PPYYWWWY.....B.
....PPPYYYRRRRRRR...
..PPPPPYRRRRRRRRR...
.G...PPRRRR.RRRRR...
.G..G..RRR..RRRRR...
.GGG...RRR.....RR...
GG.....RRRR...RRR...
.G......RRRRRRRR....
.G........RRRR......
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 57 | 57 | 57 |
| blue | 3 | 3 | 3 |
| yellow | 90 | 90 | 90 |
| green | 10 | 10 | 10 |
| purple | 26 | 26 | 26 |
| white | 18 | 18 | 18 |

## Candidate columns (front → back)

- column-1: yellow-01 yellow ×14 → red-05 red ×9 → yellow-06 yellow ×10.
- column-2: red-01 red ×12 → yellow-02 yellow ×12 → yellow-07 yellow ×14.
- column-3: purple-01 purple ×10 → red-02 red ×10 → yellow-03 yellow ×10 → yellow-08 yellow ×4.
- column-4: white-01 white ×14 → purple-02 purple ×14 → red-03 red ×14 → yellow-04 yellow ×14.
- column-5: green-01 green ×10 → blue-01 blue ×3 → white-02 white ×4 → purple-03 purple ×2 → red-04 red ×12 → yellow-05 yellow ×12.

First-front color order yellow,red,purple,white,green,blue. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: white ×6.
- armor-02: yellow ×30.
- armor-03: purple ×9.
- armor-04: red ×19.
- armor-05: blue ×1.
- armor-06: green ×4.
- armor-07: green ×3.
- armor-08: blue ×1.
- armor-09: red ×19.
- armor-10: purple ×9.
- armor-11: yellow ×30.
- armor-12: white ×6.
- armor-13: white ×6.
- armor-14: yellow ×30.
- armor-15: purple ×8.
- armor-16: red ×19.
- armor-17: blue ×1.
- armor-18: green ×3.

Alternate forward/reverse cycles of white,yellow,purple,red,blue,green; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 86.00; speed 1.00 units/s; initial distance 86.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:41Z.
- Gameplay hash: `237053b9975637fe5c5b9c50f97e2c6405c17c5baf71564985402e37d0a4d1ca`.
- Final hit 60.981430s; final-hit contact margin 31.818570s; minimum click spacing 0.75s.
- Last pickup 32.450000s; last delivery 34.610000s; final fire 59.931430s; pickup-to-hit tail 28.531430s; delivery-to-hit tail 26.371430s.
- Maximum occupied slots 5; target-wait events 0; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | yellow-01 |
| 0.750000 | column-1 | red-05 |
| 1.500000 | column-1 | yellow-06 |
| 2.250000 | column-2 | red-01 |
| 3.000000 | column-2 | yellow-02 |
| 5.250000 | column-2 | yellow-07 |
| 6.000000 | column-3 | purple-01 |
| 7.500000 | column-3 | red-02 |
| 11.250000 | column-3 | yellow-03 |
| 12.000000 | column-3 | yellow-08 |
| 13.500000 | column-4 | white-01 |
| 15.000000 | column-4 | purple-02 |
| 15.750000 | column-4 | red-03 |
| 16.500000 | column-4 | yellow-04 |
| 18.000000 | column-5 | green-01 |
| 24.000000 | column-5 | blue-01 |
| 25.500000 | column-5 | white-02 |
| 26.250000 | column-5 | purple-03 |
| 27.000000 | column-5 | red-04 |
| 27.750000 | column-5 | yellow-05 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
