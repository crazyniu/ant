# 04 · Little Sailboat

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-04`; version: `campaign-draft-1.0`; seed: `2026102104`.
- Goal: Three exposed choices and a small last wave; quota zero is not victory.
- Progression: 01–05 exposed foundations.
- Thumbnail: [Little Sailboat](campaign-04-thumbnail.png).
- Source: [campaign-04](campaign-04.json).

## Board and conservation

16 × 16. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
................
........Y.......
........Y.......
........Y.......
......W.YY......
.....WW.YYY.....
....WWW.YYYY....
...WWWW.YYYYY...
..WWWWW.YYYYYY..
........Y.......
........Y.......
.BBBBBBBBBBBBBB.
..BBBBBBBBBBBB..
...BBBBBBBBBB...
................
.BBBBBB...BBBBB.
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 0 | 0 | 0 |
| blue | 47 | 47 | 47 |
| yellow | 25 | 25 | 25 |
| green | 0 | 0 | 0 |
| purple | 0 | 0 | 0 |
| white | 15 | 15 | 15 |

## Candidate columns (front → back)

- column-1: blue-01 blue ×10 → blue-02 blue ×8 → blue-03 blue ×12 → blue-04 blue ×10 → blue-05 blue ×7.
- column-2: white-01 white ×8 → white-02 white ×7.
- column-3: yellow-01 yellow ×12 → yellow-02 yellow ×10 → yellow-03 yellow ×3.
- column-4: empty.
- column-5: empty.

First-front color order blue,white,yellow. Introductory colors use dedicated lanes. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: yellow ×25.
- armor-02: blue ×47.
- armor-03: white ×15.

Alternate forward/reverse cycles of yellow,blue,white; 1 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 44.00; speed 1.00 units/s; initial distance 44.00.
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
- Gameplay hash: `a86e7a2700e0880f63addac8817847ca9f89dd90d88474433ee1872de9a25359`.
- Final hit 23.328572s; final-hit contact margin 21.771428s; minimum click spacing 0.75s.
- Last pickup 17.554286s; last delivery 18.928572s; final fire 22.528572s; pickup-to-hit tail 5.774286s; delivery-to-hit tail 4.400000s.
- Maximum occupied slots 5; target-wait events 0; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | blue-01 |
| 0.750000 | column-1 | blue-02 |
| 1.500000 | column-1 | blue-03 |
| 2.250000 | column-1 | blue-04 |
| 3.000000 | column-1 | blue-05 |
| 5.250000 | column-2 | white-01 |
| 6.000000 | column-2 | white-02 |
| 9.750000 | column-3 | yellow-01 |
| 11.250000 | column-3 | yellow-02 |
| 12.000000 | column-3 | yellow-03 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
