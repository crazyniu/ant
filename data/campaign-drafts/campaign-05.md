# 05 · Seeded Strawberry

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-05`; version: `campaign-draft-1.0`; seed: `2026102105`.
- Goal: Green crown and red fruit expose small yellow seeds; basic waiting.
- Progression: 01–05 exposed foundations.
- Thumbnail: [Seeded Strawberry](campaign-05-thumbnail.png).
- Source: [campaign-05](campaign-05.json).

## Board and conservation

16 × 16. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
................
........G.......
........GG......
....GGGGGGGGG...
....RGGGGGGG....
...RRRRRRRRRR...
..RRRYRRRRYRRR..
..RRRRRRRRRRRR..
..RRRRRRRRRRRR..
...YRRRRYRRRR...
....RRRRRRRY....
.....RRRRRRR....
......RYRRR.....
.......RRR......
.......RRR......
........R.......
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 78 | 78 | 78 |
| blue | 0 | 0 | 0 |
| yellow | 6 | 6 | 6 |
| green | 19 | 19 | 19 |
| purple | 0 | 0 | 0 |
| white | 0 | 0 | 0 |

## Candidate columns (front → back)

- column-1: green-01 green ×10 → green-02 green ×9.
- column-2: red-01 red ×14 → red-02 red ×12 → red-03 red ×10 → red-04 red ×14 → red-05 red ×12 → red-06 red ×10 → red-07 red ×6.
- column-3: yellow-01 yellow ×6.
- column-4: empty.
- column-5: empty.

First-front color order green,red,yellow. Introductory colors use dedicated lanes. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: red ×78.
- armor-02: green ×19.
- armor-03: yellow ×6.

Alternate forward/reverse cycles of red,green,yellow; 1 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 47.00; speed 1.00 units/s; initial distance 47.00.
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
- Gameplay hash: `cbe806e55bba6f63521e72077db2f11bdacc8525d81258e5022687b0ff0163ae`.
- Final hit 26.225716s; final-hit contact margin 21.874284s; minimum click spacing 0.75s.
- Last pickup 20.522858s; last delivery 21.825716s; final fire 25.425716s; pickup-to-hit tail 5.702858s; delivery-to-hit tail 4.400000s.
- Maximum occupied slots 5; target-wait events 3; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | green-01 |
| 0.750000 | column-1 | green-02 |
| 1.500000 | column-2 | red-01 |
| 2.250000 | column-2 | red-02 |
| 3.000000 | column-2 | red-03 |
| 5.250000 | column-2 | red-04 |
| 6.750000 | column-2 | red-05 |
| 12.000000 | column-2 | red-06 |
| 12.750000 | column-2 | red-07 |
| 13.500000 | column-3 | yellow-01 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
