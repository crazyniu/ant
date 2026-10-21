# 23 · Festival Bridge

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-23`; version: `campaign-draft-1.0`; seed: `2026102123`.
- Goal: Three supports and two lanterns; delayed colors stockpile ahead of alternating armor.
- Progression: 21–30 combined planning.
- Thumbnail: [Festival Bridge](campaign-23-thumbnail.png).
- Source: [campaign-23](campaign-23.json).

## Board and conservation

24 × 20. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
........................
.WWW................WWW.
WYYYW..............WYYYW
WYYYW...GG....GG...WYYYW
WYYYW...GG....GG...WYYYW
.WWW....GG....GG....WWW.
..P..................P..
.YPYYYYYYYYYYYYYYYYYYPY.
..P..................P..
..PRRRRRRRRRRRRRRRRRRP..
..RRRRRRRRRRRRRRRRRRRR..
..RRRRR..RRRRRR..RRRRR..
..RRRR....RRRR....RRRR..
..RRR......RR......RRR..
..RRR......RR......RRR..
..RRR......RR......RRR..
..RRR......RR......RRR..
..RRR......RR......RRR..
..RRR......BBBBBBB.RRR..
.BBBBBBBB.........BBBBBB
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 112 | 112 | 112 |
| blue | 21 | 21 | 21 |
| yellow | 38 | 38 | 38 |
| green | 12 | 12 | 12 |
| purple | 8 | 8 | 8 |
| white | 24 | 24 | 24 |

## Candidate columns (front → back)

- column-1: red-01 red ×10 → white-03 white ×2 → yellow-04 yellow ×2 → red-05 red ×14 → red-10 red ×4.
- column-2: yellow-01 yellow ×14 → blue-02 blue ×7 → red-06 red ×12.
- column-3: white-01 white ×12 → red-02 red ×14 → red-07 red ×10.
- column-4: purple-01 purple ×8 → yellow-02 yellow ×12 → red-03 red ×12 → red-08 red ×14.
- column-5: blue-01 blue ×14 → green-01 green ×12 → white-02 white ×10 → yellow-03 yellow ×10 → red-04 red ×10 → red-09 red ×12.

First-front color order red,yellow,white,purple,blue,green. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: green ×4.
- armor-02: purple ×3.
- armor-03: red ×38.
- armor-04: yellow ×13.
- armor-05: blue ×7.
- armor-06: white ×8.
- armor-07: white ×8.
- armor-08: blue ×7.
- armor-09: yellow ×13.
- armor-10: red ×37.
- armor-11: purple ×3.
- armor-12: green ×4.
- armor-13: green ×4.
- armor-14: purple ×2.
- armor-15: red ×37.
- armor-16: yellow ×12.
- armor-17: blue ×7.
- armor-18: white ×8.

Alternate forward/reverse cycles of green,purple,red,yellow,blue,white; 3 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 90.00; speed 1.00 units/s; initial distance 90.00.
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

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:43Z.
- Gameplay hash: `b5fa8fc09d074e851d1c35a40f7c007860402bc07f774d99ff62008b402ff520`.
- Final hit 69.671430s; final-hit contact margin 27.128570s; minimum click spacing 0.75s.
- Last pickup 31.961429s; last delivery 33.692858s; final fire 68.521430s; pickup-to-hit tail 37.710001s; delivery-to-hit tail 35.978572s.
- Maximum occupied slots 5; target-wait events 1; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | red-01 |
| 0.750000 | column-1 | white-03 |
| 1.500000 | column-1 | yellow-04 |
| 2.250000 | column-1 | red-05 |
| 3.000000 | column-1 | red-10 |
| 3.750000 | column-2 | yellow-01 |
| 4.500000 | column-2 | blue-02 |
| 5.250000 | column-2 | red-06 |
| 6.000000 | column-3 | white-01 |
| 6.750000 | column-3 | red-02 |
| 9.000000 | column-3 | red-07 |
| 12.000000 | column-4 | purple-01 |
| 13.500000 | column-4 | yellow-02 |
| 14.250000 | column-4 | red-03 |
| 15.750000 | column-4 | red-08 |
| 16.500000 | column-5 | blue-01 |
| 17.250000 | column-5 | green-01 |
| 21.750000 | column-5 | white-02 |
| 22.500000 | column-5 | yellow-03 |
| 25.500000 | column-5 | red-04 |
| 26.250000 | column-5 | red-09 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
