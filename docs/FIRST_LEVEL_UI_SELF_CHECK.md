# First-level mobile-game UI self-check

This is an acceptance rule, not a claim that existing pages pass. Current work is
the approved first level only. Desktop Godot is a development verification host;
the product UI is a portrait mobile game, not a website. This does not authorize
new levels, controls, mobile packaging, SDKs, merging, or deployment.

## Design confirmation before implementation

Present one coherent first-level page/state design set for user confirmation
before further visual reconstruction. Use no irregularly shaped buttons: regular
rectangles/rounded rectangles for text actions and regular circles for icon actions.
Confirm silhouettes, visible proportions, type/icon occupancy, padding, and distinct
touch targets in the designs first. Keep the approved forest/character references
unless explicitly superseded. Existing candidates are not implicit design approval.
Authorized functionality fixes may continue independently. A user's explicit narrow
UI correction can be implemented without inventing a broader redesign.

The four transport pedestals remain, with the internal four-carrier rule. Do not
show an extra x / 4 numeric HUD beside them. Keep five color-card remaining counts,
the speed control, and existing full-capacity rejection feedback.

## Review every 30 minutes during development

Review all implemented pages and their related code against the approved art,
current requirements, actual rules, and global game style. Include Home, selection,
preparation, tutorial, battle, shop, pause/settings, outcome, and existing recovery
states without entering unapproved later levels. Preserve the existing progress
reporting cadence; this checklist does not create another scheduled task.

- Alignment, baselines, spacing, safe areas, silhouette/scale, and visual hierarchy.
- Font size/weight, text color and contrast, wrapping, clipping, and full labels.
- Use-specific visible button width/height, glyph/text occupancy, padding and phone
  touch areas. Long actions must not become squat slabs just to enlarge targets;
  round navigation icons and color cards keep their intended silhouettes. Visible
  faces and transparent targets are measured separately, centered and nonoverlapping.
  Nine-slice corners and text/icons must not stretch. Focus, pressed and disabled
  appearances must remain coherent with the visible face. No webpage card/form
  layout or long explanatory blocks replacing actual game presentation.
- Normal, pressed and disabled states; return paths, modal exclusion, continuous
  input, and animations. Do not add redundant controls to fill the approved art.
- Real quantities, prices, availability and functions agree with the requirements.
  Tutorials and previews show mechanisms actually enabled in the first level.

## Evidence and Issue loop

Run the actual candidate build. Capture every page actually checked, recording
commit, page/state, viewport and result (pass or specific defect). Check native
1440x2560 output and the equivalent smaller phone-proportioned window. Preserve
original-resolution evidence; do not present resized or offline images as native
runtime. Static screenshots are not animation, touch-device, sound, or natural
play validation. Use continuous real input or short runtime clips for animations.

Send the checked-page screenshots as requested with honest result labels. A defect
capture is a diagnostic record, not a finished product submitted for acceptance.
Never label unvisited pages as checked or infer UI success from headless assertions.
Fix obvious defects and rerun before requesting the user's final visual acceptance.

Use existing relevant Issues, not duplicate tickets. Each defect records reproducible
steps, expected/actual results, build/screenshot evidence, affected code or assets,
the fix, and the actual recheck result. Keep this rule in requirements; keep the
changing problem ledger and verification results in Issues and versioned reports.

Passing internal checks is not the user's approval. The first-level confirmation
gate remains closed until the user explicitly accepts it.
