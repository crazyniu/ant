# 25 · Phoenix Crest

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-25`; version: `campaign-draft-1.0`; seed: `2026102125`.
- Goal: Split wing feathers and inner chest; keep slots cycling while armor changes.
- Progression: 21–30 combined planning.
- Thumbnail: [Phoenix Crest](campaign-25-thumbnail.png).
- Source: [campaign-25](campaign-25.json).

## Board and conservation

24 × 22. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
........................
........................
...........PPP..........
.R........PPPBP........R
.RRR......PPPPP......RRR
.RRRR.....PPPPP.....RRRR
..RYRRR..RRPPPR...RRRYR.
..RRYYRRRRRWWRRRRRRYYRR.
..RRYYYYRRRWWRRRRYYYYRR.
...RRYYYYRWWWWRYYYYYRR..
...RRYYYYYWWWWRYYYYRRR..
...RRRRYYYWWWWRYYYRRRR..
...RRRRRRYWWWWRYRRRRR...
......RRRRWWWWRRRR......
.........RRWWRR.........
.........RGGGRRR........
.........RRGGRRR........
.........RRGGRRR........
........RRRGG.RRR.......
........RR..G..RR.......
........R...G...R.......
............G...........
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 124 | 124 | 124 |
| blue | 1 | 1 | 1 |
| yellow | 40 | 40 | 40 |
| green | 12 | 12 | 12 |
| purple | 20 | 20 | 20 |
| white | 26 | 26 | 26 |

## Candidate columns (front → back)

- column-1: red-01 red ×13 → white-02 white ×11 → yellow-04 yellow ×1 → red-05 red ×11 → red-10 red ×7.
- column-2: yellow-01 yellow ×11 → white-03 white ×2 → red-06 red ×15.
- column-3: purple-01 purple ×15 → red-02 red ×11 → red-07 red ×13.
- column-4: white-01 white ×13 → yellow-02 yellow ×15 → red-03 red ×15 → red-08 red ×11.
- column-5: blue-01 blue ×1 → green-01 green ×12 → purple-02 purple ×5 → yellow-03 yellow ×13 → red-04 red ×13 → red-09 red ×15.

First-front color order red,yellow,purple,white,blue,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: purple ×7.
- armor-02: white ×9.
- armor-03: red ×42.
- armor-04: yellow ×14.
- armor-05: blue ×1.
- armor-06: green ×4.
- armor-07: green ×4.
- armor-08: yellow ×13.
- armor-09: red ×41.
- armor-10: white ×9.
- armor-11: purple ×7.
- armor-12: purple ×6.
- armor-13: white ×8.
- armor-14: red ×41.
- armor-15: yellow ×13.
- armor-16: green ×4.

Alternate forward/reverse cycles of purple,white,red,yellow,blue,green; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 88.00; speed 1.00 units/s; initial distance 88.00.
- Dispatch 0.14s; transport 14.00 cells/s; in-flight cap 24; cannon cooldown 2.70s; flight 1.15s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.40, capped at 0.40 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; available in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; available in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; available in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; available in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:44Z.
- Gameplay hash: `b1e143379bbed769072f81fb38dae1be4453c50e0919f214bf8ce2c08673506a`.
- Final hit 52.518572s; final-hit contact margin 41.481428s; minimum click spacing 0.75s.
- Last pickup 33.574286s; last delivery 35.948572s; final fire 51.368572s; pickup-to-hit tail 18.944286s; delivery-to-hit tail 16.570000s.
- Maximum occupied slots 5; target-wait events 26; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | red-01 |
| 0.750000 | column-3 | purple-01 |
| 1.500000 | column-3 | red-02 |
| 2.250000 | column-3 | red-07 |
| 3.000000 | column-1 | white-02 |
| 4.500000 | column-5 | blue-01 |
| 5.250000 | column-4 | white-01 |
| 7.500000 | column-1 | yellow-04 |
| 8.250000 | column-1 | red-05 |
| 9.000000 | column-1 | red-10 |
| 10.500000 | column-2 | yellow-01 |
| 12.000000 | column-2 | white-03 |
| 13.500000 | column-2 | red-06 |
| 14.250000 | column-4 | yellow-02 |
| 15.000000 | column-4 | red-03 |
| 15.750000 | column-4 | red-08 |
| 18.000000 | column-5 | green-01 |
| 23.250000 | column-5 | purple-02 |
| 24.000000 | column-5 | yellow-03 |
| 24.750000 | column-5 | red-04 |
| 25.500000 | column-5 | red-09 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
