# 22 · Clockwork Owl

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-22`; version: `campaign-draft-1.0`; seed: `2026102122`.
- Goal: White eye rings enclose blue pupils while body unlocks the red breast.
- Progression: 21–30 combined planning.
- Thumbnail: [Clockwork Owl](campaign-22-thumbnail.png).
- Source: [campaign-22](campaign-22.json).

## Board and conservation

22 × 22. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
......................
...PP.............P...
...PPP...........PP...
...PPPP.........PPP...
...PPPPP.......PPPP...
...PPWWWWPPPPWWWWPP...
...PWWWWWWPPWWWWWWP...
...WWWBBWWWWWWBBWWW...
...WWBBBBWWWWBBBBWW...
...WWBBBBWWWWBBBBWW...
...WWWBBWWWWWWBBWWW...
...PWWWWWYYYYWWWWWP...
...PPWWWWPYYYWWWWPP...
...PPPPPPPYYPPPPPPP...
...PPPPPPRRRRPPPPPP...
..PPPPPRRRRRRRRPPPP...
...PPPPRRRRRRRRPPPP...
....PPPRRRRRRRRPPP....
.....PPPPRRRRPPPP.....
......PPPPPPPPPP......
.......YY....YY.......
GGGGGGGGGGGGGGGGGGGGGG
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 32 | 32 | 32 |
| blue | 24 | 24 | 24 |
| yellow | 13 | 13 | 13 |
| green | 22 | 22 | 22 |
| purple | 110 | 110 | 110 |
| white | 78 | 78 | 78 |

## Candidate columns (front → back)

- column-1: purple-01 purple ×13 → red-02 red ×15 → white-05 white ×15 → purple-06 purple ×15.
- column-2: white-01 white ×11 → purple-02 purple ×11 → green-02 green ×7 → red-03 red ×6 → white-06 white ×13 → purple-07 purple ×13.
- column-3: blue-01 blue ×15 → white-02 white ×15 → purple-03 purple ×15 → purple-08 purple ×11.
- column-4: yellow-01 yellow ×13 → blue-02 blue ×9 → white-03 white ×13 → purple-04 purple ×13 → purple-09 purple ×8.
- column-5: red-01 red ×11 → green-01 green ×15 → white-04 white ×11 → purple-05 purple ×11.

First-front color order purple,white,blue,yellow,red,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: blue ×8.
- armor-02: yellow ×5.
- armor-03: purple ×37.
- armor-04: red ×11.
- armor-05: white ×26.
- armor-06: green ×8.
- armor-07: green ×7.
- armor-08: white ×26.
- armor-09: red ×11.
- armor-10: purple ×37.
- armor-11: yellow ×4.
- armor-12: blue ×8.
- armor-13: blue ×8.
- armor-14: yellow ×4.
- armor-15: purple ×36.
- armor-16: red ×10.
- armor-17: white ×26.
- armor-18: green ×7.

Alternate forward/reverse cycles of blue,yellow,purple,red,white,green; 3 independently sized segment(s) per present color.

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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:42Z.
- Gameplay hash: `de7d542fffb0ab574a71f5ef7c94d876635056dea832587d96145cd3e360fe96`.
- Final hit 70.155716s; final-hit contact margin 36.644284s; minimum click spacing 0.75s.
- Last pickup 41.134286s; last delivery 43.508572s; final fire 69.005716s; pickup-to-hit tail 29.021430s; delivery-to-hit tail 26.647144s.
- Maximum occupied slots 5; target-wait events 2; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | purple-01 |
| 0.750000 | column-2 | white-01 |
| 1.500000 | column-2 | purple-02 |
| 2.250000 | column-2 | green-02 |
| 3.000000 | column-1 | red-02 |
| 4.500000 | column-1 | white-05 |
| 6.750000 | column-1 | purple-06 |
| 7.500000 | column-2 | red-03 |
| 8.250000 | column-2 | white-06 |
| 12.000000 | column-2 | purple-07 |
| 13.500000 | column-3 | blue-01 |
| 15.000000 | column-3 | white-02 |
| 17.250000 | column-3 | purple-03 |
| 18.000000 | column-3 | purple-08 |
| 21.000000 | column-4 | yellow-01 |
| 23.250000 | column-4 | blue-02 |
| 24.750000 | column-4 | white-03 |
| 25.500000 | column-4 | purple-04 |
| 27.000000 | column-4 | purple-09 |
| 30.000000 | column-5 | red-01 |
| 30.750000 | column-5 | green-01 |
| 32.250000 | column-5 | white-04 |
| 33.750000 | column-5 | purple-05 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
