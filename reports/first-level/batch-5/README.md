# Batch5: actual same-ball handoff candidate

Base: `b4a6d7d`. Scope: first level only. No later level, merge, deployment or user visual acceptance. b4 HUD removal is independently GL-verified; this new animation is not.

## What changes

- Only numeric rule change: first-level `transport.unload_pause_sec` .20→.80 simulation seconds. Existing pickup, movement, enemy145s budget, cannon650ms, projectile450ms, capacities, upgrades and110/130 reward thresholds are unchanged.
- Same33.5 ball class/color/footprint. Actual cargo view is hidden only while its task owns the Cannon-child `LoadingBall<ID>`. The first .20s visibly holds at the measured back/contact center; .60s feeds behind the real painted brass and reaches the real opening at (452,1097). No star to removed stock HUD, no early credit or fake firing.
- The receiving ant stands at a fixed cannon-side position. Four feet stay planted; two forelegs use a bounded4px local push. It does not walk on the front metal or teleport between overlapping unload windows. Opening preview, incoming balls and loader are actual Cannon children; ball scale cancels recoil stretch.
- Occlusion samples the actual cannon alpha and measured10-point dark-mouth polygon. This is an implementation, not proof that the GPU result looks correct.
- `HopperAmmo` and charge use authoritative next legal fire target; both hide during an actual projectile or no legal shot. Real `cannon_fired` owns recoil, muzzle effect and projectile. Event ages use their actual simulation timestamp so a long update cannot prematurely expire a newly-created shot. This is opted in for first level only.

## Ownership/state table

| Actual state | Visible ball owner | Ledger and capacity |
|---|---|---|
| On board | Live board round-ball node | Unclaimed or reserved board resource |
| Picked up/returning | `LiveCarriers/<task>/CarriedBead` | Task holds ball; carrier slot occupied |
| Real unload window, .00–.20s | `Cannon/LoadingBall<ID>` at exact former back center; cargo hidden | Still task-owned; no early inventory |
| Real unload window, .20–.80s | Same `LoadingBall<ID>`, behind brass except actual opening | Still task-owned; carrier remains occupied |
| Actual delivery | Incoming node removed | One inventory credit; task/capacity released |
| Eligible but not fired | `Cannon/HopperAmmo`, authoritative next-fire color | Inventory not spent merely for preview |
| Actual fire | RescueFX actual projectile; loaded preview hidden | One real debit;650ms cooldown |
| Actual hit | Projectile removed, actual hit feedback |450ms flight, actual target/hit event |
| Pause/×2 | Same simulation clock for rule and presentation | No visual-only early credit/fire |

The first actual blue now picks up3.700s, begins unload8.625s, delivers/fires9.425s and hits9.875s. b4's8.825/9.275 timestamps are historical, not current candidate expectations.

## Finite checks, not visual acceptance

-72 loading geometry/event checks: same view ownership/diameter, measured first contact,200ms holding period, fixed support feet/bounded push, pause/×2, endpoint, no early credit, one debit/fire/hit, correct opening attachment under recoil, copper-frame/lip mask exclusions, padded forelimbs and a real145s defeat during unloading with frozen world position.
-93 first-blue HUD/conservation checks: preserved controls/no removed HUD and actual supply chain.
-48 gate/selector/distance-phase/feedback checks. Foreign level numbers are rejected inputs only, never loaded scenes.
-19938 production first-level assertions,8814 cargo-size samples: victory114.750s; real saved reward138 =100base+38time;207 balls remain; max4 carriers; max2 simultaneous unloading windows. Actual victory panel becomes ready; no Next button. No future level tested.

The same free Worker, same34 color order and minimum2s click gap were used. Clicks are retimed for actual capacity. Reusing old absolute timestamps under .8s unload rejects13 clicks and loses at145s; we do not present that obsolete input schedule as valid. Completion adds4.325s over old110.425s and leaves30.25s before the unchanged enemy deadline.

## Exact pending checks

Native GL×1/×2 grip/readability and transparency, repeated/overlapping delivery silhouettes, actual input and recoil, and the remaining target-change/inventory/error/victory-interruption presentation matrix remain unaccepted. The real145s defeat mid-unload is checked only at node/event level. Receiving asset is more side-on/chunky than the approved tiny worker; compare at actual scale, not only a cropped enlarged sprite. The ball travels behind the cannon after release; the worker does not visibly carry it through opaque brass. No claim of continuous visible hand grip over the whole107px transfer.

The original full-screen reference, entire UI, shop, real audio and user approval remain open. Root review must inspect actual screenshots/animation against original/PRD/global style/real functionality before any user acceptance request. Local raw nodes and redundant full screenshots are not added to the repository.


## Mobile-game self-check gate

Every implemented page is a portrait mobile-game interface, not a webpage/card-form layout: follow the approved game art, readable phone-scale hierarchy and real touch regions; avoid webpage-style panels, long explanatory text and duplicated controls. Review real screenshots and continuous input/animation against the approved image, PRD and global style before sharing for user acceptance. Headless counts and offline composites cannot satisfy this gate. Current new animation is still pending that native self-check. The existing periodic review is managed separately; no duplicate timer is created by this batch.
