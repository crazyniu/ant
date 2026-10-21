# 09 · Lily Pond Frog

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-09`; version: `campaign-draft-1.0`; seed: `2026102109`.
- Goal: Select a blocked belly early only if an outer-green slot stays free.
- Progression: 06–10 order and stock.
- Thumbnail: [Lily Pond Frog](campaign-09-thumbnail.png).
- Source: [campaign-09](campaign-09.json).

## Board and conservation

18 × 18. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
..................
....GGG....GGG....
...GGGGG..GGGGG...
...GWWGG..GGWWG...
...GWWGG..GGWWG...
...GGGGGGGGGGGG...
....GGGGGGGGGG....
...GGRRRRRRRRGG...
..GGGGGYYYYGGGGG..
..GGGGYYYYYYGGGG..
..GGGYYYYYYYYGGG..
...GGYYYYYYYYGG...
.GGGGGYYYYYYGGGGG.
GGGGGGGYYYYGGGGGGG
GGGGGG......GGGGGG
GGGGGG......GGGGGG
.GGGG........GGGG.
...BBBBBBBBBBBB...
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 8 | 8 | 8 |
| blue | 12 | 12 | 12 |
| yellow | 36 | 36 | 36 |
| green | 138 | 138 | 138 |
| purple | 0 | 0 | 0 |
| white | 8 | 8 | 8 |

## Candidate columns (front → back)

- column-1: green-01 green ×14 → yellow-02 yellow ×12 → green-05 green ×12 → green-10 green ×14.
- column-2: blue-01 blue ×12 → yellow-03 yellow ×10 → green-06 green ×10 → green-11 green ×12.
- column-3: white-01 white ×8 → green-02 green ×12 → green-07 green ×14 → green-12 green ×4.
- column-4: yellow-01 yellow ×14 → green-03 green ×10 → green-08 green ×12.
- column-5: red-01 red ×8 → green-04 green ×14 → green-09 green ×10.

First-front color order green,blue,white,yellow,red. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: yellow ×18.
- armor-02: white ×4.
- armor-03: green ×69.
- armor-04: blue ×6.
- armor-05: red ×4.
- armor-06: red ×4.
- armor-07: blue ×6.
- armor-08: green ×69.
- armor-09: white ×4.
- armor-10: yellow ×18.

Alternate forward/reverse cycles of yellow,white,green,blue,red; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 74.00; speed 1.00 units/s; initial distance 74.00.
- Dispatch 0.17s; transport 14.00 cells/s; in-flight cap 20; cannon cooldown 2.10s; flight 0.95s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.55, capped at 0.55 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; available in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; available in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; available in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; locked in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:38Z.
- Gameplay hash: `62107894eccebe8735046fba812442a79d784ab56e3ab109fbbbca8b3c4a23cc`.
- Final hit 51.081430s; final-hit contact margin 27.868570s; minimum click spacing 0.75s.
- Last pickup 35.884286s; last delivery 37.758572s; final fire 50.131430s; pickup-to-hit tail 15.197144s; delivery-to-hit tail 13.322858s.
- Maximum occupied slots 5; target-wait events 3; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | green-01 |
| 0.750000 | column-2 | blue-01 |
| 1.500000 | column-1 | yellow-02 |
| 2.250000 | column-1 | green-05 |
| 3.000000 | column-1 | green-10 |
| 7.500000 | column-2 | yellow-03 |
| 9.000000 | column-2 | green-06 |
| 11.250000 | column-2 | green-11 |
| 12.000000 | column-4 | yellow-01 |
| 15.000000 | column-4 | green-03 |
| 15.750000 | column-4 | green-08 |
| 17.250000 | column-5 | red-01 |
| 21.000000 | column-5 | green-04 |
| 23.250000 | column-5 | green-09 |
| 24.000000 | column-3 | white-01 |
| 24.750000 | column-3 | green-02 |
| 25.500000 | column-3 | green-07 |
| 30.750000 | column-3 | green-12 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
