# 03 · Paper Lantern

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-03`; version: `campaign-draft-1.0`; seed: `2026102103`.
- Goal: Open red sides before the enclosed yellow light; extra slot first available.
- Progression: 01–05 exposed foundations.
- Thumbnail: [Paper Lantern](campaign-03-thumbnail.png).
- Source: [campaign-03](campaign-03.json).

## Board and conservation

14 × 16. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
.....YYYY.....
.....YYYY.....
...YYYYYYYY...
...YYRRRRYY...
...RRYYYYRR...
...RRYYYYRR...
..RRRYYYYRRR..
..RRRYYYYRRR..
..RRRYYYYRRR..
...RRYYYYRR...
...RRYYYYRR...
.....RRRR.....
....YYYYYY....
......R.R.....
......R.R.....
......R.R.....
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 48 | 48 | 48 |
| blue | 0 | 0 | 0 |
| yellow | 54 | 54 | 54 |
| green | 0 | 0 | 0 |
| purple | 0 | 0 | 0 |
| white | 0 | 0 | 0 |

## Candidate columns (front → back)

- column-1: red-01 red ×14 → red-02 red ×12 → red-03 red ×10 → red-04 red ×12.
- column-2: yellow-01 yellow ×12 → yellow-02 yellow ×10 → yellow-03 yellow ×14 → yellow-04 yellow ×12 → yellow-05 yellow ×6.
- column-3: empty.
- column-4: empty.
- column-5: empty.

First-front color order red,yellow. Introductory colors use dedicated lanes. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: red ×48.
- armor-02: yellow ×54.

Alternate forward/reverse cycles of red,yellow; 1 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 45.00; speed 1.00 units/s; initial distance 45.00.
- Dispatch 0.19s; transport 14.00 cells/s; in-flight cap 20; cannon cooldown 1.80s; flight 0.80s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.55, capped at 0.55 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; available in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; locked in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; locked in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; locked in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:37Z.
- Gameplay hash: `325ee2a62c4f6eb383c23aed9984b321c19d9c8068ce15bdef8eb91d520634e4`.
- Final hit 23.435716s; final-hit contact margin 22.114284s; minimum click spacing 0.75s.
- Last pickup 20.832858s; last delivery 22.635716s; final fire 22.635716s; pickup-to-hit tail 2.602858s; delivery-to-hit tail 0.800000s.
- Maximum occupied slots 5; target-wait events 2; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | red-01 |
| 0.750000 | column-1 | red-02 |
| 1.500000 | column-1 | red-03 |
| 2.250000 | column-1 | red-04 |
| 3.000000 | column-2 | yellow-01 |
| 9.000000 | column-2 | yellow-02 |
| 9.750000 | column-2 | yellow-03 |
| 10.500000 | column-2 | yellow-04 |
| 12.750000 | column-2 | yellow-05 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
