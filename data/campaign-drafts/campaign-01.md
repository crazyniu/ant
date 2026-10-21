# 01 · First Sprout

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-01`; version: `campaign-draft-1.0`; seed: `2026102101`.
- Goal: One exposed color: select, exhaust quota, wait for delivery and final hit.
- Progression: 01–05 exposed foundations.
- Thumbnail: [First Sprout](campaign-01-thumbnail.png).
- Source: [campaign-01](campaign-01.json).

## Board and conservation

12 × 12. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
............
..GGGG......
.GGGGGGGGG..
.GGGGGGGGGG.
.GGGGGGGGGG.
..GGGGGGGGG.
......GGGG..
......G.....
......G.....
...GGGGGGG..
...GGGGGGG..
............
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 0 | 0 | 0 |
| blue | 0 | 0 | 0 |
| yellow | 0 | 0 | 0 |
| green | 62 | 62 | 62 |
| purple | 0 | 0 | 0 |
| white | 0 | 0 | 0 |

## Candidate columns (front → back)

- column-1: green-01 green ×10 → green-02 green ×8 → green-03 green ×12 → green-04 green ×10 → green-05 green ×8 → green-06 green ×12 → green-07 green ×2.
- column-2: empty.
- column-3: empty.
- column-4: empty.
- column-5: empty.

First-front color order green. Introductory colors use dedicated lanes. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: green ×62.

Alternate forward/reverse cycles of green; 1 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 34.00; speed 1.00 units/s; initial distance 34.00.
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
- Gameplay hash: `16c7dccb5f3ab9a1d139eea2dcb5e641d18b68f212eaa929768d61e9cbbb75b1`.
- Final hit 14.978572s; final-hit contact margin 19.021428s; minimum click spacing 0.75s.
- Last pickup 12.804286s; last delivery 14.178572s; final fire 14.178572s; pickup-to-hit tail 2.174286s; delivery-to-hit tail 0.800000s.
- Maximum occupied slots 5; target-wait events 0; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | green-01 |
| 0.750000 | column-1 | green-02 |
| 1.500000 | column-1 | green-03 |
| 2.250000 | column-1 | green-04 |
| 3.000000 | column-1 | green-05 |
| 5.250000 | column-1 | green-06 |
| 6.000000 | column-1 | green-07 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
