# 27 · Cloudberry Airship

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-27`; version: `campaign-draft-1.0`; seed: `2026102127`.
- Goal: Three nested balloon bands plus suspended gondola; stock different armor colors early.
- Progression: 21–30 combined planning.
- Thumbnail: [Cloudberry Airship](campaign-27-thumbnail.png).
- Source: [campaign-27](campaign-27.json).

## Board and conservation

24 × 20. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
........................
........PPPPPPPP........
.....PPPPPPPPPPPPPP.....
...PPPPPYYYYYYYYPPPPP...
..PPPYYYYYYYYYYYYYYPPP..
.PPPYRRRRRRRRRRRRRRYPPP.
.PPYYRRRRRRRRRRRRRRYYPP.
.PPYYRRRRRRRRRRRRRRYYPP.
.BPPYRRRRRRRRRRRRRRYPPB.
.BBPPYYYYYYYYYYYYYYPPBB.
.BBBPPPPYYYYYYYYPPPPBBB.
.BBBBPPPPPPPPPPPPPPBBBBB
.BB....WPPPPPPPPW.....BB
........W......W........
........W......W........
........GGGGGGGG........
........GBBGGBBG.....W..
........GBBGGBBG........
..W.....GGGGGGGG........
........................
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 56 | 56 | 56 |
| blue | 33 | 33 | 33 |
| yellow | 56 | 56 | 56 |
| green | 24 | 24 | 24 |
| purple | 90 | 90 | 90 |
| white | 8 | 8 | 8 |

## Candidate columns (front → back)

- column-1: purple-01 purple ×16 → blue-02 blue ×14 → red-03 red ×14 → yellow-04 yellow ×14 → purple-05 purple ×14.
- column-2: yellow-01 yellow ×14 → blue-03 blue ×3 → red-04 red ×12 → purple-06 purple ×12.
- column-3: red-01 red ×12 → purple-02 purple ×14 → green-02 green ×12 → red-05 red ×2 → purple-07 purple ×6.
- column-4: blue-01 blue ×16 → yellow-02 yellow ×12 → purple-03 purple ×12.
- column-5: white-01 white ×8 → green-01 green ×12 → red-02 red ×16 → yellow-03 yellow ×16 → purple-04 purple ×16.

First-front color order purple,yellow,red,blue,white,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: red ×19.
- armor-02: green ×8.
- armor-03: purple ×30.
- armor-04: yellow ×19.
- armor-05: blue ×11.
- armor-06: white ×3.
- armor-07: white ×3.
- armor-08: blue ×11.
- armor-09: yellow ×19.
- armor-10: purple ×30.
- armor-11: green ×8.
- armor-12: red ×19.
- armor-13: red ×18.
- armor-14: green ×8.
- armor-15: purple ×30.
- armor-16: yellow ×18.
- armor-17: blue ×11.
- armor-18: white ×2.

Alternate forward/reverse cycles of red,green,purple,yellow,blue,white; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 98.00; speed 1.00 units/s; initial distance 98.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:02:37Z.
- Gameplay hash: `08f9d4a43c22ab7674dde63001777461fbd0f6fe3b66a1c46b01d78a8b16e5d9`.
- Final hit 67.590000s; final-hit contact margin 37.210000s; minimum click spacing 0.75s.
- Last pickup 39.728572s; last delivery 41.817144s; final fire 66.440000s; pickup-to-hit tail 27.861428s; delivery-to-hit tail 25.772856s.
- Maximum occupied slots 5; target-wait events 42; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | purple-01 |
| 0.750000 | column-1 | blue-02 |
| 1.500000 | column-4 | blue-01 |
| 2.250000 | column-2 | yellow-01 |
| 3.000000 | column-2 | blue-03 |
| 5.250000 | column-1 | red-03 |
| 6.750000 | column-1 | yellow-04 |
| 10.500000 | column-1 | purple-05 |
| 11.760000 | column-2 | red-04 |
| 12.750000 | column-2 | purple-06 |
| 16.500000 | column-3 | red-01 |
| 17.250000 | column-3 | purple-02 |
| 18.000000 | column-3 | green-02 |
| 20.300000 | column-3 | red-05 |
| 21.420000 | column-3 | purple-07 |
| 22.170000 | column-4 | yellow-02 |
| 24.000000 | column-4 | purple-03 |
| 25.500000 | column-5 | white-01 |
| 26.250000 | column-5 | green-01 |
| 27.000000 | column-5 | red-02 |
| 30.000000 | column-5 | yellow-03 |
| 30.750000 | column-5 | purple-04 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
