# 02 · Sunrise Ripples

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-02`; version: `campaign-draft-1.0`; seed: `2026102102`.
- Goal: Two separated regions: future blue stock survives yellow armor.
- Progression: 01–05 exposed foundations.
- Thumbnail: [Sunrise Ripples](campaign-02-thumbnail.png).
- Source: [campaign-02](campaign-02.json).

## Board and conservation

14 × 14. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
......Y.......
..............
.Y...YYYY...Y.
....YYYYYY....
...YYYYYYYY...
...YYYYYYYY...
Y..YYYYYYYY..Y
...YYYYYYYY...
....YYYYYY....
.....YYYY.....
..BBBBBBBBBB..
..............
BBBBBBB.......
........BBBBBB
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 0 | 0 | 0 |
| blue | 23 | 23 | 23 |
| yellow | 57 | 57 | 57 |
| green | 0 | 0 | 0 |
| purple | 0 | 0 | 0 |
| white | 0 | 0 | 0 |

## Candidate columns (front → back)

- column-1: blue-01 blue ×8 → blue-02 blue ×12 → blue-03 blue ×3.
- column-2: yellow-01 yellow ×12 → yellow-02 yellow ×10 → yellow-03 yellow ×8 → yellow-04 yellow ×12 → yellow-05 yellow ×10 → yellow-06 yellow ×5.
- column-3: empty.
- column-4: empty.
- column-5: empty.

First-front color order blue,yellow. Introductory colors use dedicated lanes. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: yellow ×57.
- armor-02: blue ×23.

Alternate forward/reverse cycles of yellow,blue; 1 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 41.00; speed 1.00 units/s; initial distance 41.00.
- Dispatch 0.19s; transport 14.00 cells/s; in-flight cap 20; cannon cooldown 1.80s; flight 0.80s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.55, capped at 0.55 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; locked in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; locked in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; locked in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; locked in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:37Z.
- Gameplay hash: `a4dfba3f837b1b25ad793134954b74c59cdbf6f682c45076bfd1be3a30be6baf`.
- Final hit 20.341430s; final-hit contact margin 21.208570s; minimum click spacing 0.75s.
- Last pickup 16.295715s; last delivery 17.741430s; final fire 19.541430s; pickup-to-hit tail 4.045715s; delivery-to-hit tail 2.600000s.
- Maximum occupied slots 5; target-wait events 0; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | blue-01 |
| 0.750000 | column-1 | blue-02 |
| 1.500000 | column-1 | blue-03 |
| 2.250000 | column-2 | yellow-01 |
| 3.000000 | column-2 | yellow-02 |
| 3.750000 | column-2 | yellow-03 |
| 4.500000 | column-2 | yellow-04 |
| 9.750000 | column-2 | yellow-05 |
| 10.500000 | column-2 | yellow-06 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
