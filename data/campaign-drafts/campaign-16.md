# 16 · Tidepool Crab

Draft only. Human playtest: **NOT_RUN**. Visual acceptance: **NOT_RUN**. Playable in the explicit `--campaign-drafts` candidate; not promoted to final content.

- Stable ID: `campaign-16`; version: `campaign-draft-1.0`; seed: `2026102116`.
- Goal: Claws, legs and eye stalks expose the shell; scout unlock is optional.
- Progression: 11–20 layers and split quotas.
- Thumbnail: [Tidepool Crab](campaign-16-thumbnail.png).
- Source: [campaign-16](campaign-16.json).

## Board and conservation

20 × 18. Dot is an empty cell. R red; B blue; Y yellow; G green; P purple; W white.

```text
....................
.R..R..........R..R.
RR..RR........RR..RR
RRRRRR........RRRRRR
RRRRRR.BW..WB.RRRRRR
RRRYRR.WW..WW.RRYRRR
.RRRY..WWRRWW..YRRR.
....Y.RRRRRRRRY.....
.....YRRRRRRRRY.....
.GG..RYRPPPPRYR..GG.
...GGGRRPPPPRRGGG...
...GGRRRPPPPRRRGG...
.GGG..RRRRRRRR..GGG.
...G....RRRR....G...
..G..............G..
.G................G.
....................
....................
```

| Color | Beads | Team quota | Armor demand |
|---|---:|---:|---:|
| red | 96 | 96 | 96 |
| blue | 2 | 2 | 2 |
| yellow | 10 | 10 | 10 |
| green | 26 | 26 | 26 |
| purple | 12 | 12 | 12 |
| white | 10 | 10 | 10 |

## Candidate columns (front → back)

- column-1: red-01 red ×12 → red-06 red ×14.
- column-2: yellow-01 yellow ×10 → red-02 red ×10 → red-07 red ×12.
- column-3: green-01 green ×14 → red-03 red ×14 → red-08 red ×10.
- column-4: white-01 white ×10 → green-02 green ×12 → red-04 red ×12 → red-09 red ×2.
- column-5: blue-01 blue ×2 → purple-01 purple ×12 → red-05 red ×10.

First-front color order red,yellow,green,white,blue,purple. Later quota slices rotate between lanes; selecting a front reveals a different future color. A sixth initial color, if present, follows the fifth front in column 5. Team quotas vary independently of armor slices.

## Complete armor order

- armor-01: purple ×6.
- armor-02: red ×48.
- armor-03: blue ×1.
- armor-04: white ×5.
- armor-05: green ×13.
- armor-06: yellow ×5.
- armor-07: yellow ×5.
- armor-08: green ×13.
- armor-09: white ×5.
- armor-10: blue ×1.
- armor-11: red ×48.
- armor-12: purple ×6.

Alternate forward/reverse cycles of purple,red,blue,white,green,yellow; 2 independently sized segment(s) per present color.

## Threat and timing

- Dragon start 0.00; route 66.00; speed 1.00 units/s; initial distance 66.00.
- Dispatch 0.15s; transport 14.00 cells/s; in-flight cap 24; cannon cooldown 2.40s; flight 1.05s.
- Minimum transport leg 0.55s; pickup hold 0.16s (simulation time; legacy omission = 0).
- Finite knockback 0.40, capped at 0.40 and clamped at route start.
- Predeclared budget = ceil(beads × dispatch + teams × 0.75 + armor segments × cooldown × 0.60 + twice width-plus-height / 14 + band grace). Measured final-hit tail and margin must be recorded after authoritative replay.

## Tools

- extra_slot: unlock 3; 1 use; available in this draft's intended level context. No tools used by the proof.
- shuffle: unlock 6; 1 use; available in this draft's intended level context. No tools used by the proof.
- recall: unlock 9; 1 use; available in this draft's intended level context. No tools used by the proof.
- scout: unlock 16; 1 use; available in this draft's intended level context. No tools used by the proof.

## Automated proof

- Status: TIMED_REPLAY_VERIFIED; Rules 1.2.0; verified 2026-10-21T11:01:40Z.
- Gameplay hash: `87c61e2701a0fb8802f965f0b7742dfd49575be98e6c7d9bf9a689bad70e19ef`.
- Final hit 50.345716s; final-hit contact margin 20.054284s; minimum click spacing 0.75s.
- Last pickup 25.100000s; last delivery 27.260000s; final fire 49.295716s; pickup-to-hit tail 25.245716s; delivery-to-hit tail 23.085716s.
- Maximum occupied slots 5; target-wait events 2; tools used 0; conservation errors 0.

| Time (s) | Column | Expected front team |
|---:|---|---|
| 0.000000 | column-1 | red-01 |
| 0.750000 | column-1 | red-06 |
| 1.500000 | column-2 | yellow-01 |
| 2.250000 | column-2 | red-02 |
| 3.000000 | column-2 | red-07 |
| 3.750000 | column-3 | green-01 |
| 9.000000 | column-3 | red-03 |
| 9.750000 | column-3 | red-08 |
| 10.500000 | column-4 | white-01 |
| 12.750000 | column-4 | green-02 |
| 13.500000 | column-4 | red-04 |
| 16.500000 | column-4 | red-09 |
| 18.000000 | column-5 | blue-01 |
| 18.750000 | column-5 | purple-01 |
| 19.500000 | column-5 | red-05 |

## Boundary test copies

- exact_final_hit_tie: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.
- contact_1us_earlier: NOT_RUN. Transport timing changed; old full-level certificate invalidated. This batch runs focused timing/contact fixtures rather than a new whole-campaign boundary sweep.

## Human inspection and acceptance

NOT_RUN: automated proof is not a human difficulty, motif-recognition or visual acceptance.

Check motif recognition in the 2K runtime, meaningful front choices, slow/fast player cadence, avoidable waits and pressure. Automated replay is one valid route, not proof all choices succeed.
