# 07 · Candy Cottage

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-07`; version: `campaign-draft-1.0`; seed: `2026102107`.
- Goal: Roof and base expose door and window; reserve a slot for blue window quota.
- Progression: 06–10 order and stock.
- Thumbnail: [Candy Cottage](campaign-07-thumbnail.png).
- Source: [campaign-07](campaign-07.json).

## Board and conservation

18 × 18. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
..................
............WW....
........RR..WW....
.......RRRR.WW....
......RRRRRRWW....
.....RRRRRRRWW....
....RRRRRRRRRR....
...RRRRRRRRRRRR...
..RRRRRRRRRRRRRR..
...YYYYYYYYYYYY...
...YYYYYYYGGGYY...
...YYBBBYYGGGYY...
...YYBBBYYGGGYY...
...YYBBBYYGGGYY...
...YYYYYYYGGGYY...
...YYYYYYYGGGYY...
...YYYYYYYGGGYY...
..GGGGGGGGGGGGGG..
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 55 | 55 | 55 |
| blue | 9 | 9 | 9 |
| yellow | 66 | 66 | 66 |
| green | 35 | 35 | 35 |
| purple | 0 | 0 | 0 |
| white | 10 | 10 | 10 |

## Candidate columns (front → back)

- column-1: red-01 red ×12 → green-03 green ×9 → yellow-04 yellow ×10 → red-05 red ×7.
- column-2: yellow-01 yellow ×10 → yellow-05 yellow ×14.
- column-3: green-01 green ×14 → red-02 red ×10 → yellow-06 yellow ×6.
- column-4: white-01 white ×10 → yellow-02 yellow ×14 → red-03 red ×14.
- column-5: blue-01 blue ×9 → green-02 green ×12 → yellow-03 yellow ×12 → red-04 red ×12.

First-front color order red,yellow,green,white,blue. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: blue ×5.
- armor-02: yellow ×33.
- armor-03: red ×28.
- armor-04: green ×18.
- armor-05: white ×5.
- armor-06: white ×5.
- armor-07: green ×17.
- armor-08: red ×27.
- armor-09: yellow ×33.
- armor-10: blue ×4.

Alternate forward/reverse cycles of blue,yellow,red,green,white; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 68.00; speed 1.00 units/s; initial distance 68.00.
- Dispatch 0.17s; transport 14.00 cells/s; in-flight cap 20; cannon cooldown 2.10s; flight 0.95s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.55, capped at 0.55 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; available in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; available in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; locked in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; locked in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:38Z.
- Gameplay hash: `f9ccb365f22bf1b16a09d2a2587848e8f6fde328d8d36f1d5eb2f00e0fc6ce8e`.
- Final hit 42.545716s; final-hit contact margin 30.404284s; minimum click spacing 0.75s.
- Last pickup 31.080000s; last delivery 32.740000s; final fire 41.595716s; pickup-to-hit tail 11.465716s; delivery-to-hit tail 9.805716s.
- Maximum occupied slots 5; target-wait events 0; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | red-01 |
| 0.750000 | column-1 | green-03 |
| 1.500000 | column-1 | yellow-04 |
| 2.250000 | column-1 | red-05 |
| 3.000000 | column-2 | yellow-01 |
| 5.250000 | column-2 | yellow-05 |
| 6.750000 | column-3 | green-01 |
| 7.500000 | column-3 | red-02 |
| 9.000000 | column-3 | yellow-06 |
| 11.250000 | column-4 | white-01 |
| 14.250000 | column-4 | yellow-02 |
| 16.500000 | column-4 | red-03 |
| 17.250000 | column-5 | blue-01 |
| 18.750000 | column-5 | green-02 |
| 19.500000 | column-5 | yellow-03 |
| 24.750000 | column-5 | red-04 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
