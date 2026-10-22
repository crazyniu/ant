# First-level button-proportion candidate

Follow-up after `a017b56`, 2026-10-22. No gameplay configuration, budget, economy,
new feature, new level, image asset, merge or deployment change. This is not a
real-GL visual acceptance report.

## Existing faces and targets

Logical layout rectangles below describe controls, not pixel-tight opaque bounds.
Existing gold/enamel/wood assets are reused without stretching icons or text.

| Role | Paint rectangle | Preserved hit rectangle |
|---|---:|---:|
| Home Play | 400×96 | 400×136 |
| Prep equipment | 351×96 | 351×120 |
| Prep Begin | 560×100 | 560×127 |
| Shop equipment/purchase | 335×90 | 335×120 |
| Shop training | 386×88 | 386×120 |
| Common modal/result action | 560×100 | 560×118 |
| Loading return/retry | 560×100 | 560×136 |

Long faces use 28-unit nine-slice corners. Navigation uses proportional round
medallions, not empty long rectangular frames; larger existing targets remain.
Focus follows the face, not the transparent target. Loading decorations render
behind its focus layer and retain pressed tint without a new loading dependency.
Primary modal text retains white ink with a dark outline. Small checks/bright
primary-face contrast still require real phone-scale inspection.

## Related existing-page details

- The real a017 Map first-node position was verified, but its preview title touched
  the frame. The candidate reserves 46-unit side padding and two 38px title lines.
- Existing battle capacity count becomes 38px and full-capacity state 32px, placed
  in the open right deck margin beside the same four pedestals, not over cards.
  Temporary refusal feedback becomes 32px within its existing separate area.
  No extra HUD or transport capacity was added.
- Result receipt and unavailable-ad text are 32px with measured multiline spacing.
  The ad remains disabled, rewards are unchanged, and Next remains first-level gated.

## Finite automated evidence

Godot 4.6.3 headless, isolated temporary profiles. Final bounded checks:
previews/tutorial/status **1705**, first-node map/navigation **184**, shared
modals/settings/outcome fixtures **1510**, Shop **909**, settings recovery **20**,
navigation-save boundary **20**; no failed assertions or script exceptions.
Settings emitted ObjectDB/resource-in-use shutdown warnings; navigation also
emitted an ObjectDB shutdown warning. Earlier local
iterations rejected a nonexistent test-only API, inadequate title inset and an
exact-float assertion; those intermediate runs are not accepted evidence.

Outcome checks are presentation fixtures, not a new won run. Existing gameplay
and save boundaries are unchanged. Actual button animation, focus appearance,
font contrast, touch-device behavior and current-version full-page fidelity still
require real GL self-check against the approved art before user acceptance.
The actual a017 fixed-route defeat remains separately recorded; these layout
checks do not override that gameplay observation.
