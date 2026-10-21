# 06 · Wayfinder Compass

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-06`; version: `campaign-draft-1.0`; seed: `2026102106`.
- Goal: Queue order differs from armor: hold white stock and clear yellow spokes.
- Progression: 06–10 order and stock.
- Thumbnail: [Wayfinder Compass](campaign-06-thumbnail.png).
- Source: [campaign-06](campaign-06.json).

## Board and conservation

18 × 18. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
..................
.........Y........
......BBBYBB......
.....BBBYYBBB.....
....BBBWYYYBBB....
...BBWWWRYYWWBB...
..BBBWWYRYYWWBBB..
..BBYYYRRYYWWWBB..
YYYYYYYRRYYYYYBB..
..BYYYYYYBYYYYYYY.
..BBWWYYYYYYYYBB..
..BBBWWYYYWWWBBB..
...BBWWYYYWWWBB...
....BBBYYYWBBB....
.....BBBYBBBB.....
......BBYBBB......
........Y.........
..................
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 6 | 6 | 6 |
| blue | 67 | 67 | 67 |
| yellow | 62 | 62 | 62 |
| green | 0 | 0 | 0 |
| purple | 0 | 0 | 0 |
| white | 26 | 26 | 26 |

## Candidate columns (front → back)

- column-1: blue-01 blue ×13 → white-03 white ×2 → yellow-05 yellow ×9 → blue-06 blue ×9.
- column-2: yellow-01 yellow ×11 → blue-02 blue ×11 → yellow-06 yellow ×9 → blue-07 blue ×1.
- column-3: red-01 red ×6 → yellow-02 yellow ×9 → blue-03 blue ×9.
- column-4: white-01 white ×13 → yellow-03 yellow ×13 → blue-04 blue ×13.
- column-5: white-02 white ×11 → yellow-04 yellow ×11 → blue-05 blue ×11.

First-front color order blue,yellow,red,white. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: red ×3.
- armor-02: yellow ×31.
- armor-03: blue ×34.
- armor-04: white ×13.
- armor-05: white ×13.
- armor-06: blue ×33.
- armor-07: yellow ×31.
- armor-08: red ×3.

Alternate forward/reverse cycles of red,yellow,blue,white; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 64.00; speed 1.00 units/s; initial distance 64.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:02:31Z.
- Gameplay hash: `57b4becc08c6dd9c5c95a823a972eed7a1df63cace5e0dc87290d7099b04a056`.
- Final hit 35.795716s; final-hit contact margin 32.054284s; minimum click spacing 0.75s.
- Last pickup 28.842858s; last delivery 30.645716s; final fire 34.845716s; pickup-to-hit tail 6.952858s; delivery-to-hit tail 5.150000s.
- Maximum occupied slots 5; target-wait events 4; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | blue-01 |
| 0.750000 | column-2 | yellow-01 |
| 1.500000 | column-1 | white-03 |
| 2.250000 | column-1 | yellow-05 |
| 3.000000 | column-1 | blue-06 |
| 3.750000 | column-2 | blue-02 |
| 6.000000 | column-2 | yellow-06 |
| 7.500000 | column-2 | blue-07 |
| 8.250000 | column-3 | red-01 |
| 9.750000 | column-3 | yellow-02 |
| 10.500000 | column-3 | blue-03 |
| 12.750000 | column-4 | white-01 |
| 13.500000 | column-4 | yellow-03 |
| 14.250000 | column-4 | blue-04 |
| 16.660000 | column-5 | white-02 |
| 18.000000 | column-5 | yellow-04 |
| 24.000000 | column-5 | blue-05 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
