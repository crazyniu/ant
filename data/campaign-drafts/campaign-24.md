# 24 · Reef Lighthouse

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-24`; version: `campaign-draft-1.0`; seed: `2026102124`.
- Goal: Striped tapering tower; independent top lamp and base route challenge order.
- Progression: 21–30 combined planning.
- Thumbnail: [Reef Lighthouse](campaign-24-thumbnail.png).
- Source: [campaign-24](campaign-24.json).

## Board and conservation

22 × 24. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
......................
.........PPP..........
........PPPPPP........
.......BBBBBBBB.......
.......BBYYYYBB.......
.......BBYYYYBB.......
.......BBBBBBBB.......
........WWWWWW........
........WWWWWW........
.......RRRRRRRR.......
.......RRRRRRRR.......
.......RRRRRRRR.......
.......WWWWWWWW..BBBBB
BBBBB..WWWWWWWW.......
.......WWWWWWWW.......
......RRRRRRRRRR......
......RRRRRRRRRR......
......RRRRRRRRRR......
......WWWBBBWWWW......
......WWWBBBWWWW......
...GGGGGGBBBGGGGGG....
..GGGGGGGGGGGGGGGGG...
.GGGGGGGGGGGGGGGGGGG..
......................
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 54 | 54 | 54 |
| blue | 43 | 43 | 43 |
| yellow | 8 | 8 | 8 |
| green | 48 | 48 | 48 |
| purple | 9 | 9 | 9 |
| white | 50 | 50 | 50 |

## Candidate columns (front → back)

- column-1: white-01 white ×15 → green-03 green ×11 → blue-04 blue ×4 → red-05 red ×2.
- column-2: red-01 red ×13 → white-02 white ×13 → green-04 green ×9.
- column-3: blue-01 blue ×11 → red-02 red ×11 → white-03 white ×11.
- column-4: green-01 green ×15 → blue-02 blue ×15 → red-03 red ×15 → white-04 white ×11.
- column-5: yellow-01 yellow ×8 → purple-01 purple ×9 → green-02 green ×13 → blue-03 blue ×13 → red-04 red ×13.

First-front color order white,red,blue,green,yellow,purple. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: yellow ×3.
- armor-02: purple ×3.
- armor-03: red ×18.
- armor-04: blue ×15.
- armor-05: white ×17.
- armor-06: green ×16.
- armor-07: green ×16.
- armor-08: white ×17.
- armor-09: blue ×14.
- armor-10: red ×18.
- armor-11: purple ×3.
- armor-12: yellow ×3.
- armor-13: yellow ×2.
- armor-14: purple ×3.
- armor-15: red ×18.
- armor-16: blue ×14.
- armor-17: white ×16.
- armor-18: green ×16.

Alternate forward/reverse cycles of yellow,purple,red,blue,white,green; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 88.00; speed 1.00 units/s; initial distance 88.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:43Z.
- Gameplay hash: `103e0f25aa362e6b6ef567bf4994a3f83681f9dd6bd4b5db4d22db4cdccdb5f1`.
- Final hit 74.430000s; final-hit contact margin 20.370000s; minimum click spacing 0.75s.
- Last pickup 31.040000s; last delivery 32.848572s; final fire 73.280000s; pickup-to-hit tail 43.390000s; delivery-to-hit tail 41.581428s.
- Maximum occupied slots 5; target-wait events 19; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | white-01 |
| 0.750000 | column-1 | green-03 |
| 1.500000 | column-1 | blue-04 |
| 2.250000 | column-1 | red-05 |
| 3.000000 | column-2 | red-01 |
| 3.750000 | column-2 | white-02 |
| 4.500000 | column-2 | green-04 |
| 5.250000 | column-3 | blue-01 |
| 6.000000 | column-3 | red-02 |
| 10.500000 | column-3 | white-03 |
| 12.000000 | column-4 | green-01 |
| 12.750000 | column-4 | blue-02 |
| 13.500000 | column-4 | red-03 |
| 14.250000 | column-4 | white-04 |
| 19.500000 | column-5 | yellow-01 |
| 21.000000 | column-5 | purple-01 |
| 21.750000 | column-5 | green-02 |
| 22.500000 | column-5 | blue-03 |
| 23.250000 | column-5 | red-04 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
