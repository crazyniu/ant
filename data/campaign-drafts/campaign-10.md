# 10 · Harbor Bell

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-10`; version: `campaign-draft-1.0`; seed: `2026102110`.
- Goal: Blue enamel is enclosed by yellow: plan inventory rather than armor-matching clicks.
- Progression: 06–10 order and stock.
- Thumbnail: [Harbor Bell](campaign-10-thumbnail.png).
- Source: [campaign-10](campaign-10.json).

## Board and conservation

18 × 18. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
.......GGGG.......
......GGGGGG......
......GGGGGG......
......GYYYYG......
.....YYYYYYYY.....
....YWYYYYYYYY....
...YYWYBBBBYYYY...
...YYWYBBBBYYYY...
...YYWYBBBBYYYY...
...YYWYBBBBYYYY...
...YYWYBBBBYYYY...
...YYYYBBBBYYYY...
...YYYYYYYYYYYY...
...YYYYYYYYYYYY...
.RRRRRRRRRRRRRRRR.
.RRRRRRRYYRRRRRRR.
.......YYYY.......
........YY........
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 30 | 30 | 30 |
| blue | 24 | 24 | 24 |
| yellow | 96 | 96 | 96 |
| green | 18 | 18 | 18 |
| purple | 0 | 0 | 0 |
| white | 6 | 6 | 6 |

## Candidate columns (front → back)

- column-1: yellow-01 yellow ×12 → blue-02 blue ×14 → yellow-06 yellow ×14.
- column-2: red-01 red ×10 → yellow-02 yellow ×10 → yellow-07 yellow ×12.
- column-3: green-01 green ×14 → red-02 red ×14 → yellow-03 yellow ×14 → yellow-08 yellow ×10.
- column-4: white-01 white ×6 → green-02 green ×4 → red-03 red ×6 → yellow-04 yellow ×12 → yellow-09 yellow ×2.
- column-5: blue-01 blue ×10 → yellow-05 yellow ×10.

First-front color order yellow,red,green,white,blue. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: blue ×12.
- armor-02: yellow ×48.
- armor-03: red ×15.
- armor-04: green ×9.
- armor-05: white ×3.
- armor-06: white ×3.
- armor-07: green ×9.
- armor-08: red ×15.
- armor-09: yellow ×48.
- armor-10: blue ×12.

Alternate forward/reverse cycles of blue,yellow,red,green,white; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 69.00; speed 1.00 units/s; initial distance 69.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:02:31Z.
- Gameplay hash: `19ce84c7f6f8986a9cc339235b920139f7b27901dc0d8066ef82a8bf08b1f443`.
- Final hit 35.334286s; final-hit contact margin 38.615714s; minimum click spacing 0.75s.
- Last pickup 30.767143s; last delivery 32.284286s; final fire 34.384286s; pickup-to-hit tail 4.567143s; delivery-to-hit tail 3.050000s.
- Maximum occupied slots 5; target-wait events 4; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | yellow-01 |
| 0.750000 | column-2 | red-01 |
| 1.500000 | column-2 | yellow-02 |
| 2.250000 | column-2 | yellow-07 |
| 3.000000 | column-1 | blue-02 |
| 5.250000 | column-1 | yellow-06 |
| 7.500000 | column-3 | green-01 |
| 9.000000 | column-3 | red-02 |
| 12.000000 | column-3 | yellow-03 |
| 15.300000 | column-3 | yellow-08 |
| 17.250000 | column-4 | white-01 |
| 19.500000 | column-4 | green-02 |
| 21.000000 | column-4 | red-03 |
| 22.500000 | column-4 | yellow-04 |
| 23.250000 | column-4 | yellow-09 |
| 24.000000 | column-5 | blue-01 |
| 24.750000 | column-5 | yellow-05 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
