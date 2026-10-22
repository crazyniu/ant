# First-level original-led ball material candidate

Base: `f4b4c30`, 2026-10-22. Asset-only follow-up: five-color RGBA atlas,
its crop regions and manifest. No production script, level, rule, footprint,
board-center, route, timing, reward or input change. No merge or deployment.

## Asset and comparison

The built-in image tool used the approved design's native five-color samples,
not the previously incorrect production atlas, as its visual source. A first
output invented glass-like bottom ovals and was rejected. One targeted edit
removed those ovals while preserving the outer bodies and small upper-center
highlights. The selected RGBA file is copied byte-for-byte: no manual paint,
alpha reconstruction, color multiplication or per-role image conversion.

Only the latest candidate atlas is present in the working repository. Rejected
images and large offline node snapshots remain outside the repository. The
unused white crop is removed; this first-level palette has exactly five colors.
Each actual alpha128 body has eight source pixels of padding in its region.
At the unchanged 33.5×35.75 world draw size, visible bodies are approximately
32.26×34.43 logical units. Board/cargo/loading/hopper/flight retain one source
and one shared world-size contract, including the preceding receiving-grip fix.

New atlas: 1536×1024 RGBA, 52.74% fully transparent pixels, SHA-256
`55fcad55ed042dd885be350925a42755577c98d57d993f05a39269bca8278f7a`.
Manifest hash, all five crops and their eight-pixel padding were checked.

Two independent visual reads of the local offline original/candidate board
comparison found this closer than the old material: small highlights are now
upper-center rather than a broad diagonal left reflection, the lower body is
fuller, the bottom rim is reduced, and blue/yellow/purple are closer to the
approved palette. This is **generated restoration, not exact pixel extraction,
Godot rendering or 1:1 approval**.

Remaining specific differences:
- Lower-body width at90% height is roughly73–75%, versus the reference's
  uncertain79–86%; the bottom also looks somewhat flatter/more regular.
- Highlight diameter is closer, but the white core is hard and slightly right
  of the reference; the halo is tighter.
- Red lower-body shading remains too dark. Green is somewhat fluorescent;
  purple still lacks some of the reference's red-pink softness.
- Bright terrain at four-ball junctions differs from the reference's contact
  shading. Do not simply inflate the balls to hide that material/scene issue.

The approximate reference measurements use a roughly30-pixel, lossy JPEG
object. They are comparison guides, not invented pixel-exact alpha or acceptance
tolerances.

## Finite checks

Godot4.6.3 headless, first-level isolated profile, after reimporting the new atlas:
- `test_first_level_art_batch2.gd`: **7,612 checks**, no failures.
- `test_first_level_loading.gd`: **79 checks**, no failures.
- `test_first_level_previews.gd`: **1,705 checks**, no failures; expected controlled
  missing-preview warning and ObjectDB shutdown warning remain recorded.

Art/loading logs have no script/assertion/shutdown warning. The same bounded
world-chain, .80-second handoff, real fire/hit, pause/x2 and terminal-stop checks
were reused. No full-route test or gameplay/economy calibration was repeated.
These counts prove wiring and geometry, not the material's rendered appearance.

## Native acceptance still required

Inspect this exact candidate in real GL: small white points and red lower body
at phone proportion, four-ball contact gaps, and the same material through
pickup/carry/loading/flight. Check that the preexisting cannon occlusion and
hand-grip warp still look continuous at x1/x2. Prior b8 real victory and f4
geometry assertions do not certify these new pixels. Natural-play balance,
physical phone, audio, complete original-art fidelity and user confirmation
remain open. Keep the visual Issues open.
