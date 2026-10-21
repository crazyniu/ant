# 11 · Mushroom Grove

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-11`; version: `campaign-draft-1.0`; seed: `2026102111`.
- Goal: Two caps unlock stems and spots; independent quotas share five slots.
- Progression: 11–20 layers and split quotas.
- Thumbnail: [Mushroom Grove](campaign-11-thumbnail.png).
- Source: [campaign-11](campaign-11.json).

## Board and conservation

20 × 18. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
....................
....RRRRRR..........
..RRRRRRRRRR........
.RRRRRRYYYRRR.......
RRRYRRRYYYRRRR......
RRRRRRRYYYRRRR......
RRRRRRRRRRRRRPPPPP..
RRRYYRRRRRRRPPPPPPP.
RRRYYRRRRRRPPPBBPPPP
RRRRRRRRRRRPPPBBPPPP
RRRRRRRRRRRPPPPPPPPP
.....WWWW...PPPPPPP.
.....WWWW....PPPPP..
.....WWWW.....WWW...
.....WWWW.....WWW...
.....WWWW.....WWW...
.....WWWW.....WWW...
..GGGGGGGGGGGGGGGGG.
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 100 | 100 | 100 |
| blue | 4 | 4 | 4 |
| yellow | 14 | 14 | 14 |
| green | 17 | 17 | 17 |
| purple | 47 | 47 | 47 |
| white | 36 | 36 | 36 |

## Candidate columns (front → back)

- column-1: red-01 red ×11 → white-02 white ×15 → purple-04 purple ×8 → red-05 red ×15.
- column-2: purple-01 purple ×15 → white-03 white ×10 → red-06 red ×13.
- column-3: green-01 green ×13 → red-02 red ×15 → red-07 red ×11.
- column-4: white-01 white ×11 → purple-02 purple ×13 → red-03 red ×13 → red-08 red ×11.
- column-5: yellow-01 yellow ×14 → blue-01 blue ×4 → green-02 green ×4 → purple-03 purple ×11 → red-04 red ×11.

First-front color order red,purple,green,white,yellow,blue. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: yellow ×7.
- armor-02: purple ×24.
- armor-03: red ×50.
- armor-04: white ×18.
- armor-05: green ×9.
- armor-06: blue ×2.
- armor-07: blue ×2.
- armor-08: green ×8.
- armor-09: white ×18.
- armor-10: red ×50.
- armor-11: purple ×23.
- armor-12: yellow ×7.

Alternate forward/reverse cycles of yellow,purple,red,white,green,blue; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 78.00; speed 1.00 units/s; initial distance 78.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:39Z.
- Gameplay hash: `87db146ff81dae3adb54ce0f49959b37621a45c7186ccbe5519fcc4695673500`.
- Final hit 57.195716s; final-hit contact margin 25.204284s; minimum click spacing 0.75s.
- Last pickup 34.550000s; last delivery 36.710000s; final fire 56.145716s; pickup-to-hit tail 22.645716s; delivery-to-hit tail 20.485716s.
- Maximum occupied slots 5; target-wait events 3; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | red-01 |
| 0.750000 | column-1 | white-02 |
| 1.500000 | column-1 | purple-04 |
| 2.250000 | column-1 | red-05 |
| 3.000000 | column-2 | purple-01 |
| 3.750000 | column-2 | white-03 |
| 6.000000 | column-2 | red-06 |
| 9.750000 | column-3 | green-01 |
| 11.250000 | column-3 | red-02 |
| 13.500000 | column-3 | red-07 |
| 14.250000 | column-4 | white-01 |
| 15.750000 | column-4 | purple-02 |
| 19.500000 | column-4 | red-03 |
| 21.750000 | column-4 | red-08 |
| 22.500000 | column-5 | yellow-01 |
| 23.250000 | column-5 | blue-01 |
| 25.500000 | column-5 | green-02 |
| 26.250000 | column-5 | purple-03 |
| 28.500000 | column-5 | red-04 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
