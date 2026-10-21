# 15 · Orchard Windmill

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-15`; version: `campaign-draft-1.0`; seed: `2026102115`.
- Goal: Four blades and tower overlap; split red/yellow quotas across repeated armor.
- Progression: 11–20 layers and split quotas.
- Thumbnail: [Orchard Windmill](campaign-15-thumbnail.png).
- Source: [campaign-15](campaign-15.json).

## Board and conservation

20 × 20. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
....................
....................
..RR.........YYYY...
..RRR........YYYY...
..RRRR......YYYY....
.RRRRRR.....YYY.....
....RRRR...YYY......
......RRR..YY.......
........PPPP........
........PPPP........
........PPPPW.......
........PPPPRR......
.......YYWWWRRRR....
......YYYWWWWRRRRR..
.....YYYWWWWWWRRRR..
....YYYYBBBBWW.RRR..
...YYYYWBBBBWWW.RR..
..YYYYYWBBBBWWW.....
......WWBBBBWWW.....
GGGGGGGGGGGGGGGGGGGG
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 42 | 42 | 42 |
| blue | 16 | 16 | 16 |
| yellow | 41 | 41 | 41 |
| green | 20 | 20 | 20 |
| purple | 16 | 16 | 16 |
| white | 29 | 29 | 29 |

## Candidate columns (front → back)

- column-1: red-01 red ×15 → purple-02 purple ×1 → white-03 white ×3 → yellow-04 yellow ×2.
- column-2: yellow-01 yellow ×13 → blue-02 blue ×3.
- column-3: white-01 white ×11 → red-02 red ×13 → green-02 green ×9.
- column-4: purple-01 purple ×15 → yellow-02 yellow ×11 → red-03 red ×11.
- column-5: blue-01 blue ×13 → green-01 green ×11 → white-02 white ×15 → yellow-03 yellow ×15 → red-04 red ×3.

First-front color order red,yellow,white,purple,blue,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: purple ×8.
- armor-02: red ×21.
- armor-03: yellow ×21.
- armor-04: white ×15.
- armor-05: blue ×8.
- armor-06: green ×10.
- armor-07: green ×10.
- armor-08: blue ×8.
- armor-09: white ×14.
- armor-10: yellow ×20.
- armor-11: red ×21.
- armor-12: purple ×8.

Alternate forward/reverse cycles of purple,red,yellow,white,blue,green; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 69.00; speed 1.00 units/s; initial distance 69.00.
- Dispatch 0.15s; transport 14.00 cells/s; in-flight cap 24; cannon cooldown 2.40s; flight 1.05s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.40, capped at 0.40 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; available in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; available in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; available in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; locked in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:40Z.
- Gameplay hash: `eb7c5e02af00da952422923bc03fd5e5c8c74be696e88a4f4258b458e5e34696`.
- Final hit 43.095716s; final-hit contact margin 30.304284s; minimum click spacing 0.75s.
- Last pickup 26.307143s; last delivery 28.324286s; final fire 42.045716s; pickup-to-hit tail 16.788573s; delivery-to-hit tail 14.771430s.
- Maximum occupied slots 5; target-wait events 2; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | red-01 |
| 0.750000 | column-1 | purple-02 |
| 1.500000 | column-1 | white-03 |
| 2.250000 | column-1 | yellow-04 |
| 3.000000 | column-2 | yellow-01 |
| 3.750000 | column-3 | white-01 |
| 4.500000 | column-3 | red-02 |
| 5.250000 | column-3 | green-02 |
| 6.000000 | column-2 | blue-02 |
| 8.250000 | column-4 | purple-01 |
| 9.000000 | column-4 | yellow-02 |
| 9.750000 | column-4 | red-03 |
| 12.000000 | column-5 | blue-01 |
| 12.750000 | column-5 | green-01 |
| 17.250000 | column-5 | white-02 |
| 18.000000 | column-5 | yellow-03 |
| 19.500000 | column-5 | red-04 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
