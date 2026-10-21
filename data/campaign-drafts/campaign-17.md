# 17 · Acorn Gateway

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-17`; version: `campaign-draft-1.0`; seed: `2026102117`.
- Goal: Cap overlaps nut shell, then white inset and blue center: three exposure steps.
- Progression: 11–20 layers and split quotas.
- Thumbnail: [Acorn Gateway](campaign-17-thumbnail.png).
- Source: [campaign-17](campaign-17.json).

## Board and conservation

20 × 20. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
..........G.........
..........G.........
.........G..........
......PPPPPPPP......
....PPPPPPPPPPPP....
...PPPPPPPPPPPPPP...
...PPPPPPPPPPPPPP...
...RRRRRRRRRRRRRR...
...RRRRRRRRRRRRRR...
...RRRRRRRRRRRRRR...
.....YYYWWWWYYY.....
.....YYYWWWWYYY.....
.....YYWWBBWWYY.....
.....YYWWBBWWYY.....
.....YYWWBBWWYY.....
.....YYYWBBWYYY.....
......YYWWWWYY......
.......YYYYYY.......
........YYYY........
..GGGGGGGGGGGGGGGG..
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 42 | 42 | 42 |
| blue | 8 | 8 | 8 |
| yellow | 44 | 44 | 44 |
| green | 19 | 19 | 19 |
| purple | 48 | 48 | 48 |
| white | 26 | 26 | 26 |

## Candidate columns (front → back)

- column-1: purple-01 purple ×11 → white-02 white ×15 → yellow-03 yellow ×15 → red-04 red ×3.
- column-2: red-01 red ×15 → yellow-04 yellow ×5.
- column-3: yellow-01 yellow ×13 → purple-02 purple ×15 → green-02 green ×6.
- column-4: white-01 white ×11 → red-02 red ×13 → purple-03 purple ×13.
- column-5: blue-01 blue ×8 → green-01 green ×13 → yellow-02 yellow ×11 → red-03 red ×11 → purple-04 purple ×9.

First-front color order purple,red,yellow,white,blue,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: blue ×3.
- armor-02: white ×9.
- armor-03: red ×14.
- armor-04: purple ×16.
- armor-05: yellow ×15.
- armor-06: green ×7.
- armor-07: green ×6.
- armor-08: yellow ×15.
- armor-09: purple ×16.
- armor-10: red ×14.
- armor-11: white ×9.
- armor-12: blue ×3.
- armor-13: blue ×2.
- armor-14: white ×8.
- armor-15: red ×14.
- armor-16: purple ×16.
- armor-17: yellow ×14.
- armor-18: green ×6.

Alternate forward/reverse cycles of blue,white,red,purple,yellow,green; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 81.00; speed 1.00 units/s; initial distance 81.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:02:33Z.
- Gameplay hash: `6dc6006d7c2bf0d6c964594e5fc809c7bb24deed718f53f22b3a1ca444a8d359`.
- Final hit 62.160000s; final-hit contact margin 25.640000s; minimum click spacing 0.75s.
- Last pickup 29.478572s; last delivery 31.067144s; final fire 61.110000s; pickup-to-hit tail 32.681428s; delivery-to-hit tail 31.092856s.
- Maximum occupied slots 5; target-wait events 1; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | purple-01 |
| 0.750000 | column-2 | red-01 |
| 1.500000 | column-2 | yellow-04 |
| 2.250000 | column-3 | yellow-01 |
| 3.000000 | column-3 | purple-02 |
| 3.750000 | column-3 | green-02 |
| 4.500000 | column-1 | white-02 |
| 8.250000 | column-1 | yellow-03 |
| 9.750000 | column-1 | red-04 |
| 11.250000 | column-4 | white-01 |
| 12.000000 | column-4 | red-02 |
| 13.500000 | column-4 | purple-03 |
| 16.800000 | column-5 | blue-01 |
| 19.500000 | column-5 | green-01 |
| 20.250000 | column-5 | yellow-02 |
| 21.000000 | column-5 | red-03 |
| 22.650000 | column-5 | purple-04 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
