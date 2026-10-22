# Repair the four defects found in actual d95384c UI

The actual Home, Preparation, tutorial and Loading review failed. The three native
1440×2560 captures were at 04:47:22, 04:50:17 and 04:53:51 UTC; Loading was a
456×812 desktop crop at 04:51:44, not a native-2K screenshot. Reproduction, expected
behavior and capture hashes are in [the open defect record](https://github.com/crazyniu/ant/issues/9#issuecomment-6333097669).
The old 1,493 node assertions were insufficient visual evidence.

## Small repair

- Home contains exactly one full-canvas, unscaled actual first-level scene, not an
  opaque miniature map over another map. Its existing wood footer carries the
  logo, current-level label, Play and map entrance, above the artwork and clear of
  the cannon. Controls remain real controls, not an image background.
- Preparation keeps the real prominent 20 normal segments and five actual color
  icons. Five tiny repeated “4” labels were redundant and removed. Ant selection,
  locks and configuration are unchanged. Its intentionally framed preview stays.
- Tutorial art now belongs to four local clipped row containers. The head helper
  sets size/position **before** attachment: modal child-added animation must record
  the correct resting transform, not reset it to screen origin after entry.
- Loading Back/Retry use the existing painted secondary skin, 36-logical-pixel
  dark text and 560×136 bounds. Hover, pressed, hover-pressed, focus and disabled
  text are explicit. Atlas/font are bootstrap resources, with no dependency on
  the asynchronous game batch. Progress/cancellation/retry timing is unchanged.

## Bounded verification

- First-level preview/tutorial/loading test: **1,576 checks, zero assertion failures**.
  Includes six samples across the modal reveal, fourth-row containment after it,
  one Home background, real palette/total, all loading text/skin states, real Back
  generation invalidation, existing preview-failure Retry and tutorial saving.
- Minimal first-level controller/entry test: **48 checks, zero assertion failures**.
- Independent read-only review confirmed the settled/reopened fourth-row portrait
  and clear Home/control rectangles. It found a light hover-pressed text state,
  which was explicitly corrected and included in the final test above.
- Internal CPU composition inspected Home's single-scene layering and footer.
  It approximates sampling and omits custom icons. It is **not Godot rendering**
  and is not acceptance evidence. No duplicate raw node snapshots or images are
  added to the repository.

These are node/functional checks, not native visual, phone touch, audio or user
acceptance. Parent review must now repeat actual Home, Preparation, tutorial entry
and reopen, Loading/Back and applicable pressed states at native/phone scale.
Check logo/wood/plant integration and illustration bounds during animation, not
only the settled screenshot. #9 and #11 stay open. Existing shutdown/rapid-disposal
diagnostics remain distinct from this bounded success; no blanket clean-log claim.
No rules, unload duration, resource geometry, prices, upgrades or later levels changed.
