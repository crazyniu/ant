# First-level batch-2 runtime asset inventory

Source-derived candidate inventory for ant #5. This is not user visual acceptance, a pixel-identical restoration claim, or GPU/GL render verification. Only these inventory reports were written by this task. Other levels are untouched.

## Frame and evidence contract

- Logical canvas:940×1672. Both approved reference JPEGs:864×1536. Runtime viewport:1440×2560.
- Width ratio1440/940=1.531914894 is **not** the applied scale. Runtime min(width ratio,height ratio) chooses **1.531100478**. Content is1439.234449761×2560 with0.382775120 pixels horizontal margin on each side.
- Aspect-preserving reference fit to940×1672:scale1.087962963, resulting940×1671.111111111 with0.444444444 pixels vertical margin on each side. Direct864×1536→1440×2560 is exact scale5/3. Additional physical-window letterboxing follows project stretch/aspect=keep.
- Full approved images are evidence, not runtime backgrounds. Actual battle background is `assets/serpent/environment.png` (941×1672); fixed wooden deck is baked into it.
- All paths below are repository-relative. Crops use[x,y,width,height]; source anchors are crop-local unless noted. JSON includes full alpha measurements, hashes, source regions, per-view feet and transform data.

## Important differences and missing roles

- Cannon crew: **missing** as an independent art/animation/node role. Moving carriers, stock counters and one hopper ball are not crew.
- Battle ants use `assets/first-level/slender-ants.png`; shop still uses `assets/motion/ant-directions.png`, without the reference baskets/carried balls and integrated wings.
- Runtime color row is five unique cards; approved illustration shows four cards, including duplicate blue. Runtime transport capacity is four pads; reference illustration shows five. These are explicit differences, not a request to alter gameplay.
- Bottom battle control is speed; plus/return/magnifier tools from the illustration are not instantiated.
- Shop uses existing shared nine-slice panels, legacy previews and code glyphs, not the fully decorated approved shop composition.

### Actual visual differences still open

- Approved balls: slightly vertically oval, tightly packed, small highlights. Candidate: rounder balls, visible gaps and different/larger highlights.
- Approved cards: large portrait-like faces toward the viewer. Candidate: smaller side-facing full-body ants.
- Approved cannon: visibly filled bore/hopper. Candidate: separate side stock plus conditional hopper preview. The reviewed 8-second empty hopper is state-dependent and is not evidence of a permanently empty cannon.
- Delivery feedback exists, but is a nest-to-stock transfer star with radius5.5 and a stock ring, not the same33.5-unit ball visibly unloading into the cannon. Five shared size parameters do not establish a complete loading chain.
- These are real differences, not excused by offline shader approximation. Card portrait framing and ball material/spacing are intended for the next batch; this batch does not mark them fixed.

## Size and parent-scale rules

- Board, cargo, stock, hopper and in-flight balls use the same `round-beads.png` source regions and **33.5×33.5 world draw rectangle**, displayed as51.291866029×51.291866029 pixels at the fixed viewport. Source alpha silhouettes are not exactly equal to rectangle sizes.
- Carried balls cancel the ant actor depth scale using `bead.scale=1/actor.scale`; their world rectangle stays33.5×33.5 while contact offsets inherit the ant transform.
- Ant model nominal width is **62 before depth**; `.88..1` inherited depth gives nominal54.56..62 world width. Actual per-yaw crop/alpha widths vary. Do not state constant final width62.
- Shop inherits startup root scale once. Nine-slice internal child scaling changes border/corner rendering, not sibling ant/text scales.

## Runtime roles

### Battle background — present_existing

- Sources: `assets/serpent/environment.png` crop[0, 0, 941, 1672]
- Consumers: `scripts/play.gd:323` build_environment(); `scripts/startup.gd:152` build_home()
- Anchor:
  - kind: top_left
  - source: [0,0]
  - logical: [0,0]
  - definition_source: {"file":"scripts/play.gd","function":"build_environment","line":323}
- Sizing:
  - logical_rect: [0,0,940,1672]
  - source_to_logical_scale_xy: [0.998937301,1]
  - stretch: TextureRect EXPAND_IGNORE_SIZE, STRETCH_SCALE default; full opaque image.
  - display_rect: [0.38277512,0,1439.234449761,2560]
- Semantic match: Woodland dirt, stone lanes, tower platform, plants and bottom deck are shared motifs.
- Observed difference: Separate clean scene, not a pixel crop of the approved full composite. Native 941x1672 is squeezed by 1px in width to 940 logical units.
- Pending: Detailed composition/color/occlusion comparison and user visual acceptance remain pending.

### Board balls — present_candidate

- Sources: `assets/first-level/round-beads.png` crop[62, 62, 426, 413]; `assets/first-level/round-beads.png` crop[554, 62, 428, 413]; `assets/first-level/round-beads.png` crop[1047, 60, 428, 415]; `assets/first-level/round-beads.png` crop[61, 543, 429, 417]; `assets/first-level/round-beads.png` crop[553, 543, 430, 417]; `assets/first-level/round-beads.png` crop[1047, 541, 429, 420]
- Consumers: `scripts/play.gd:221` place_board_bead(); `scripts/play.gd:233` build_mosaic(); `scripts/first_level_bead.gd:18` _draw(); `scripts/board_plane.gd:39` center()
- Anchor:
  - kind: center
  - logical: BoardPlane.center(x,y); draw origin=center-[16.75,16.75]
  - source: Computed crop midpoint; no distinct atlas pivot stored.
- Sizing:
  - logical_size: [33.5,33.5]
  - nominal_display_size: [51.291866029,51.291866029]
  - material: Same atlas and color regions across first-level board, carried cargo, stock, hopper and flight; native rectangular crops are mapped into square logical rectangles.
  - alpha_caveat: 33.5 describes the draw rectangle, not an exact 33.5 opaque alpha diameter; source crop padding differs per color.
  - grid: [16.0,15.0]
  - parent_scale: No board depth scale applied to bead nodes; root canvas scale only.
  - board_plane: exact corners, exterior centers and scale metadata in scene JSON and inventory JSON.
- Semantic match: Independent round colored balls reproduce the board-ball role.
- Observed difference: Manual comparison: approved board balls are slightly vertically oval, densely packed and have smaller highlights. Current candidate balls read rounder with visible gaps and a different/larger highlight treatment. These are actual visual differences, not explained away as offline shader approximation.
- Pending: Next batch is intended to address ball material and spacing. This batch does not mark those differences fixed; rendered comparison and user acceptance remain pending.

### Carried cargo balls — present_candidate

- Sources: `assets/first-level/round-beads.png` crop[62, 62, 426, 413]; `assets/first-level/round-beads.png` crop[554, 62, 428, 413]; `assets/first-level/round-beads.png` crop[1047, 60, 428, 415]; `assets/first-level/round-beads.png` crop[61, 543, 429, 417]; `assets/first-level/round-beads.png` crop[553, 543, 430, 417]; `assets/first-level/round-beads.png` crop[1047, 541, 429, 420]
- Consumers: `scripts/play.gd:504` sync_carriers(); `scripts/first_level_carrier.gd:176` _place_bead()
- Anchor:
  - kind: per_view_bottom_center_back_contact
  - manifest: assets/first-level/slender-ants.json: poses[].cargo_bottom_contact and foot_anchor
  - formula: contact=(cargo_bottom_contact-foot_anchor)*(62/420); local_span=bead.size*bead.scale; position=contact-[local_span.x/2,local_span.y]+posture*(62/420)
  - pickup: During the existing pickup hold, origin interpolates from -local_span/2 to the back-contact origin; no size growth in the approved branch.
- Sizing:
  - logical_size: [33.5,33.5]
  - nominal_display_size: [51.291866029,51.291866029]
  - material: Same atlas and color regions across first-level board, carried cargo, stock, hopper and flight; native rectangular crops are mapped into square logical rectangles.
  - alpha_caveat: 33.5 describes the draw rectangle, not an exact 33.5 opaque alpha diameter; source crop padding differs per color.
  - parent_scale: actor.scale=depth_scale(.88..1); bead.scale=1/actor.scale cancels inherited depth, preserving 33.5x33.5 world draw size. Root scale remains. Ant and contact offsets still inherit depth.
  - visibility: returning and unloading, including pickup hold within returning stage
- Semantic match: Visible colored load rides with an ant.
- Observed difference: Back-contact positions and pickup presentation are measured/tuned candidates; interleaving/occlusion with the painted body is not final visual acceptance.
- Pending: Check all eight directions, pickup, loaded travel and unloading in a real rendered run.

### Stock inventory balls — present_candidate

- Sources: `assets/first-level/round-beads.png` crop[62, 62, 426, 413]; `assets/first-level/round-beads.png` crop[554, 62, 428, 413]; `assets/first-level/round-beads.png` crop[1047, 60, 428, 415]; `assets/first-level/round-beads.png` crop[61, 543, 429, 417]; `assets/first-level/round-beads.png` crop[553, 543, 430, 417]; `assets/first-level/round-beads.png` crop[1047, 541, 429, 420]
- Consumers: `scripts/play.gd:333` build_transport(); `scripts/scene_layout.gd:92` stock_anchor(); `scripts/play.gd:491` apply_gameplay_interaction_motion()
- Anchor:
  - kind: center
  - formula: SceneLayout.stock_anchor(index)+[24,0]
  - centers_and_labels: [{"color":"red","anchor":[620,1108],"ball_center":[644,1108],"counter_rect":[620,1121,53,34]},{"color":"blue","anchor":[674,1108],"ball_center":[698,1108],"counter_rect":[674,1121,53,34]},{"color":"yellow","anchor":[728,1108],"ball_center":[752,1108],"counter_rect":[728,1121,53,34]},{"color":"green","anchor":[620,1173],"ball_center":[644,1173],"counter_rect":[620,1186,53,34]},{"color":"purple","anchor":[674,1173],"ball_center":[698,1173],"counter_rect":[674,1186,53,34]}]
- Sizing:
  - logical_size: [33.5,33.5]
  - nominal_display_size: [51.291866029,51.291866029]
  - material: Same atlas and color regions across first-level board, carried cargo, stock, hopper and flight; native rectangular crops are mapped into square logical rectangles.
  - alpha_caveat: 33.5 describes the draw rectangle, not an exact 33.5 opaque alpha diameter; source crop padding differs per color.
  - parent_scale: Stock is an unscaled battle group; root scale only. Count text can pulse separately on delivery, not the ball.
- Semantic match: Readable live ammunition stock exists.
- Observed difference: Reference ammunition is integrated visibly inside the cannon with nearby crew. Runtime uses a separate 3-column stock display. Delivery is not feedback-free: bead_delivered creates a nest-to-stock transfer star and stock ring, rather than a33.5-unit ball unloading into the cannon. The 8-second empty hopper is state-dependent.
- Pending: Confirm stock/cannon composition and replace or explicitly accept the symbolic transfer feedback. This inventory does not equate five ball-role size checks with completed visual unloading/loading.

### Cannon hopper ball — present_candidate

- Sources: `assets/first-level/round-beads.png` crop[62, 62, 426, 413]; `assets/first-level/round-beads.png` crop[554, 62, 428, 413]; `assets/first-level/round-beads.png` crop[1047, 60, 428, 415]; `assets/first-level/round-beads.png` crop[61, 543, 429, 417]; `assets/first-level/round-beads.png` crop[553, 543, 430, 417]; `assets/first-level/round-beads.png` crop[1047, 541, 429, 420]
- Consumers: `scripts/play.gd:333` build_transport(); `scripts/play.gd:482` sync_hopper_ammo()
- Anchor:
  - kind: center
  - logical: [452,1097]
  - definition: Scene JSON logical center, independently rendered child of TransportScene, not child of recoiling Cannon.
- Sizing:
  - logical_size: [33.5,33.5]
  - nominal_display_size: [51.291866029,51.291866029]
  - material: Same atlas and color regions across first-level board, carried cargo, stock, hopper and flight; native rectangular crops are mapped into square logical rectangles.
  - alpha_caveat: 33.5 describes the draw rectangle, not an exact 33.5 opaque alpha diameter; source crop padding differs per color.
  - parent_scale: Root only. Does not inherit Cannon recoil transform.
  - visibility: Shows authoritative next-fire target color; hidden while a projectile exists or run is not ready/running.
- Semantic match: Color previews the cannon ammunition.
- Observed difference: One conditional HopperAmmo node is present; it hides while a projectile exists, outside ready/running, or when next_fire_target is empty. An empty 8-second offline hopper is therefore state-dependent, not proof that the muzzle is permanently empty. It does not recreate the reference multi-ball filled-cannon composition.
- Pending: Review actual stocked/firing/cooldown states and live hopper alignment. The five shared ball-size parameters do not establish a continuous visual unloading/loading chain.

### In-flight cannon ball — present_candidate

- Sources: `assets/first-level/round-beads.png` crop[62, 62, 426, 413]; `assets/first-level/round-beads.png` crop[554, 62, 428, 413]; `assets/first-level/round-beads.png` crop[1047, 60, 428, 415]; `assets/first-level/round-beads.png` crop[61, 543, 429, 417]; `assets/first-level/round-beads.png` crop[553, 543, 430, 417]; `assets/first-level/round-beads.png` crop[1047, 541, 429, 420]
- Consumers: `scripts/play.gd:87` _ready(); `scripts/rescue_fx.gd:872` _draw_projectile()
- Anchor:
  - kind: center
  - logical_start: [494.5,921.5]
  - logical_end: Serpent target_point(segment_id), updated from live target.
  - source: Computed center of crop; procedural FX draw at point-ball_size/2.
- Sizing:
  - logical_size: [33.5,33.5]
  - nominal_display_size: [51.291866029,51.291866029]
  - material: Same atlas and color regions across first-level board, carried cargo, stock, hopper and flight; native rectangular crops are mapped into square logical rectangles.
  - alpha_caveat: 33.5 describes the draw rectangle, not an exact 33.5 opaque alpha diameter; source crop padding differs per color.
  - parent_scale: FX is a direct battle child; no projectile-specific ball scaling. Procedural glow/trail may extend beyond the ball rectangle.
- Semantic match: A real moving colored shot connects cannon and serpent.
- Observed difference: Trail/glow are procedural; not a copied static reference shot.
- Pending: Rendered flight, timing, glow and color comparison remain pending.

### Eight-view slender ants and foot articulation — present_candidate

- Sources: `assets/first-level/slender-ants.png` crop[0, 0, 1774, 887]; `assets/first-level/slender-ants.json`; `scripts/first_level_carrier.gdshader`
- Consumers: `scripts/play.gd:504` sync_carriers(); `scripts/first_level_carrier.gd:235` _set_frame(); `scripts/first_level_carrier.gd:111` apply(); `scripts/board_plane.gd:47` depth_scale(); `scripts/main.gd:105` ground_ant(); `scripts/contact_shadow.gd:5` _draw()
- Anchor:
  - kind: per_view_ground_foot
  - formula: Ant child origin=-foot_anchor*(diameter/420). Parent actor origin is the route ground point. No whole-card rotation; selected source yaw frame remains upright.
  - annotation_status: Atlas-local feet use measured solid pixels at alpha>=128; only visible source legs are articulated. Back-contact annotations are candidates, not a reference-motion capture.
  - poses: full directional crop/anchor/size records in `asset-inventory.json`; see directional table below when applicable.
- Sizing:
  - nominal_model_width_before_depth: 62
  - source_physical_width: 420
  - source_scale: 0.147619048
  - depth_scale_range: [0.88,1]
  - nominal_model_width_after_depth_range: [54.56,62]
  - nominal_display_width_range: [83.536842105,94.928229665]
  - actual_crop_size_rule: Each orientation crop width/height * (62/420) * actor depth scale * root scale. The 62-unit nominal physical width is not a constant final sprite or opaque silhouette width.
  - ui_previews: Color-card actor nominal diameter=153.6*.78=119.808; transport preview=73. These do not inherit board depth.
  - ground_shadow: Procedural FootShadow radius=[diameter*.37,diameter*.12] at actor origin; inherits actor depth and root scale.
  - gait: Distance-driven phase; outbound stride=(33.5*2.5)/3.6, loaded stride=(33.5*2)/3.1. Visible leg capsules inverse-warped in shader. Source stride/lift 12/15 outbound, 9/11 loaded. This is candidate tuning, not measured reference cadence.
- Semantic match: Slender segmented ants, painted eight-yaw views and visible legs implement the intended carrier role.
- Observed difference: Source artwork, all directions, gait, anatomical load contact and source-vs-screen footprint are candidates. Shop uses a different legacy ant atlas, recorded separately.
- Pending: Real rendered gait/load/ground-clearance review and final visual acceptance.

### Dragon head — present_existing

- Sources: `assets/serpent/serpent-atlas.png` crop[0, 0, 1303, 1774]; `assets/serpent/serpent-atlas.json`
- Consumers: `scripts/play.gd:327` build_threat(); `scripts/serpent_view.gd:37` configure(); `scripts/serpent_view.gd:104` _set_head_heading(); `scripts/serpent_view.gd:96` _apply_region()
- Anchor:
  - kind: per_view_neck_joint
  - poses: full directional crop/anchor/size records in `asset-inventory.json`; see directional table below when applicable.
  - formula: art.position=-manifest.heads[direction].anchor*(120/420); head.position=route.point_at(max(0,head_s-pitch*.30)); heading chosen at head_s.
- Sizing:
  - nominal_physical_width: 120
  - source_physical_width: 420
  - scale: 0.285714286
  - parent_scale: Root scale; head group has contact shadow radius [35,12]. No ant board-depth scale.
- Semantic match: Red horned dragon head leads the colored chain.
- Observed difference: Existing source uses eight independent yaw regions; silhouette, size and placement are not certified identical to reference.
- Pending: Rendered route orientation and attachment comparison.

### Dragon body balls and tail — present_existing

- Sources: `assets/serpent/serpent-atlas.png` crop[0, 1530, 249, 244]; `assets/serpent/serpent-atlas.png` crop[0, 0, 1303, 1774]; `scripts/combat_tint.gdshader`
- Consumers: `scripts/serpent_view.gd:89` _make_body(); `scripts/serpent_view.gd:55` sync_snapshot(); `scripts/serpent_view.gd:96` _apply_region()
- Anchor:
  - body_anchor: [127,123]
  - body_anchor_semantic: Sphere center, crop-local; rotation held at zero to preserve lighting.
  - tails: full directional crop/anchor/size records in `asset-inventory.json`; see directional table below when applicable.
  - tail_anchor_semantic: Gold collar joint nearest final body ball.
- Sizing:
  - body_formula: clamp(pitch * route.baked_length / goal_s * 1.13,35,62)
  - body_physical_diameter_in_existing_initial_node_export: 62
  - body_crop_size_at_62: [72.478873239,71.023474178]
  - source_body_physical_width: 213
  - tail_nominal_physical_width: 72
  - parent_scale: Root scale; body nodes transient hit scale=[1+sin(t*pi)*.09,1-sin(t*pi)*.10] and removal scale. No ant board-depth scale.
  - color: Body uses combat_tint.gdshader recoloring; armor overlay metadata exists but first-level segment kinds are recorded below.
  - first_level_segment_kinds: ["normal"]
- Semantic match: Colored segmented body and gold/red tail share the reference role.
- Observed difference: These patterned serpent balls are not the plain round board/cargo atlas. Existing initial node export yields 62 physical diameter but is labeled offline composition, not a rendered GL frame.
- Pending: Review chain spacing, joints, hit poses and material against reference; do not replace serpent material with board-ball material by inference.

### Dragon movement path and painted stone lane — present_data_and_background

- Sources: `data/scenes/first-level-approved.json`; `scripts/serpent_path.gd`; `assets/serpent/environment.png` crop[0, 0, 941, 1672]
- Consumers: `scripts/scene_layout.gd:58` knots(); `scripts/serpent_path.gd:6` configure(); `scripts/serpent_path.gd:12` point_at()
- Anchor:
  - kind: Bezier_knots
  - knots: [{"position":[583,956],"out":[90,24]},{"position":[850,867],"in":[-38,85],"out":[17,-85]},{"position":[867,395],"in":[8,100],"out":[-7,-115]},{"position":[750,228],"in":[60,35],"out":[-72,-41]},{"position":[505,144],"in":[80,4],"out":[-80,-4]},{"position":[230,162],"in":[60,-18]}]
  - rule_start: 80.0
  - rule_goal: 100.0
- Sizing:
  - logical_curve: Curve2D with bake_interval=2.0; finite clamped arc-length mapping from s/goal_s; not a repeating/modulo path.
  - pitch: 4.0
  - painted_lane: Part of full background. No separate runtime path texture or explicit path-line drawing in serpent_view.gd.
  - parent_scale: Root only; world-coordinate route knots.
- Semantic match: Chain follows the outer stone lane toward princess.
- Observed difference: Data curve is tuned separately from background pixels and reference illustration.
- Pending: Check body/head/tail lane registration across the whole route.

### Nest entry hole — present_existing

- Sources: `assets/serpent/nest-entry.png` crop[0, 0, 905, 529]; `assets/serpent/nest-entry.json`
- Consumers: `scripts/scene_layout.gd:84` add_nest(); `scripts/play.gd:333` build_transport()
- Anchor:
  - source: [454,264]
  - logical_ground: [345,1095]
  - gateway: [467,940]
  - semantic: Hole center, not bottom of image.
- Sizing:
  - nominal_physical_width: 78
  - source_physical_width: 869
  - logical_crop_size: [81.231300345,47.482163406]
  - logical_rect: [304.249712313,1071.303797468,81.231300345,47.482163406]
  - parent_scale: Root only.
- Semantic match: Ground hole supports ants entering/exiting.
- Observed difference: Separate nest artwork is a gameplay role not clearly isolated in the approved full battle reference.
- Pending: Confirm nest visibility, cannon overlap and route-entry placement.

### Delivery and cannon-loading visual handoff — symbolic feedback, chain incomplete

- Source/consumers: `scripts/rescue_fx.gd` consume_event(), _flight_spark() and _draw_effect().
- On bead_delivered: travel from nest `[345,1095]` to the delivered-color stock center, not a full ball into the cannon. Duration0.42s, arc offset`[0,-sin(p*pi)*24]`.
- Primary star radius5.5 logical units, secondary star radius2.5 at offset`[5,8]`; alpha follows sin(p*pi). Stock ring radius16 lasts0.38s. Reduced motion emits3 local spark particles instead.
- No raster crop or33.5-unit ball texture is used for this handoff. It inherits root scale only.
- Feedback is present, but full visible unload-to-cannon transfer, filled-cannon states and crew remain open. Shared ball-role dimensions are not a complete-chain acceptance test.

### Bronze cannon — present_candidate

- Sources: `assets/first-level/bronze-cannon.png` crop[210, 104, 811, 1114]
- Consumers: `scripts/play.gd:333` build_transport(); `scripts/play.gd:315` tint_red(); `scripts/play.gd:596` apply_actor_poses(); `scripts/rescue_fx.gd:333` cannon_pose()
- Anchor:
  - local_pivot: [110,220]
  - world_pivot_at_rest: [465,1135]
  - muzzle_world: [494.5,921.5]
  - hopper_world: [452,1097]
  - source_pivot_computed: [440,880]
  - source_pivot_full_image_computed: [650,984]
  - definition: Source pivot computed from logical pivot / .25. Manifest muzzle/hopper absolute source [768,130]/[598,832] map to logical positions via crop origin and .25 scale.
- Sizing:
  - logical_rect: [355,915,202.75,278.5]
  - source_to_logical_scale: 0.25
  - parent_scale: Root only at rest. play.gd applies FX recoil position/rotation/scale relative to scene rect each frame. Hopper is a sibling, so it does not inherit recoil.
  - material: Approved branch intentionally skips cannon color tint, preserving bronze.
- Semantic match: Bronze cannon, barrel and ammunition hopper echo the reference.
- Observed difference: Reference cannon visibly holds ammunition in its bore/hopper; current candidate uses separate side stock and only a conditional HopperAmmo preview. The reviewed 8-second offline snapshot reads empty at the muzzle, but this can reflect the not-yet-supplied/first-fire state and does not establish that the cannon is always empty. Dedicated crew is missing. Side-stock versus filled-cannon composition is a real visual difference, not an offline shader explanation.
- Pending: Review visible ammunition across pre-supply, stocked, firing, cooldown and empty states. Verify unload-to-cannon presentation and crew independently. No complete loading-chain or final appearance acceptance is claimed.

### Cannon loading crew — missing

- Sources: None; dedicated runtime source is missing.
- Consumers: `scripts/play.gd:333` build_transport()
- Anchor:
  - source: null
  - logical: null
- Sizing:
  - logical_size: null
  - display_size: null
  - parent_scale: null
- Semantic match: Approved battle image includes nearby loading/handling ants.
- Observed difference: No dedicated cannon crew art role, crew nodes or crew animation in current first-level build_transport. Live carriers/stock/hopper do not constitute a cannon loading crew.
- Pending: Needs explicit production artwork/behavior decision and implementation if matching this reference role is required.

### Princess defense target — present_candidate

- Sources: `assets/first-level/princess.png` crop[275, 32, 722, 1219]
- Consumers: `scripts/scene_layout.gd:67` target_texture(); `scripts/scene_layout.gd:74` add_target(); `scripts/play.gd:327` build_threat()
- Anchor:
  - source: [361.0,1203]
  - logical_ground: [151,190]
  - semantic: Crop-local source foot anchor; full-image source foot is region origin + anchor = [636,1235].
  - fixed: true
- Sizing:
  - nominal_physical_width: 71
  - source_physical_width: 706
  - scale: 0.100566572
  - logical_crop_size: [72.609065156,122.590651558]
  - logical_rect: [114.695467422,69.018413598,72.609065156,122.590651558]
  - parent_scale: Root only. No contact_shadow entry in this scene target; tower platform is painted into background.
- Semantic match: Pink-dressed crowned princess is placed on the upper-left tower platform.
- Observed difference: Candidate independent princess sprite, not full reference tower/princess composite.
- Pending: Feet/platform registration, silhouette and visual identity need rendered approval.

### Fixed wooden control deck — baked_in_background

- Sources: `assets/serpent/environment.png` crop[0, 0, 941, 1672]
- Consumers: `scripts/play.gd:323` build_environment()
- Anchor:
  - kind: background_top_left
  - logical: [0,0]
  - independent_deck_anchor: null
- Sizing:
  - logical_rect: Part of background [0,0,940,1672]; lower wooden area is not an independent cropped node.
  - runtime_crop: null
  - parent_scale: Root only, same transform as Environment; fixed screen composition, not a scrolling world deck.
- Semantic match: Bottom timber area supports controls like the reference.
- Observed difference: No independent runtime wood-deck sprite, patch or panel. The source layout differs from reference deck and is not cropped from the approved composite.
- Pending: Deck texture and exact boundaries should be reviewed with actual control placement.

### Five color-selection cards — present_candidate

- Sources: `assets/first-level/color-card.png` crop[122, 120, 1049, 999]; `assets/first-level/slender-ants.png` crop[0, 0, 1774, 887]; `scripts/first_level_color.gdshader`
- Consumers: `scripts/play.gd:261` build_candidates(); `scripts/play.gd:230` approved_tint()
- Anchor:
  - kind: top_left_for_card_foot_for_ant
  - cards: [{"color":"blue","button_rect":[62.0,1342,153.6,176],"art_rect":[62.0,1353,153.6,146.278741659],"ant_foot":[132.656,1455],"ant_nominal_diameter":119.808,"count_rect":[148.016,1436,59.904,65]},{"color":"red","button_rect":[227.6,1342,153.6,176],"art_rect":[227.6,1353,153.6,146.278741659],"ant_foot":[298.256,1455],"ant_nominal_diameter":119.808,"count_rect":[313.616,1436,59.904,65]},{"color":"yellow","button_rect":[393.2,1342,153.6,176],"art_rect":[393.2,1353,153.6,146.278741659],"ant_foot":[463.856,1455],"ant_nominal_diameter":119.808,"count_rect":[479.216,1436,59.904,65]},{"color":"green","button_rect":[558.8,1342,153.6,176],"art_rect":[558.8,1353,153.6,146.278741659],"ant_foot":[629.456,1455],"ant_nominal_diameter":119.808,"count_rect":[644.816,1436,59.904,65]},{"color":"purple","button_rect":[724.4,1342,153.6,176],"art_rect":[724.4,1353,153.6,146.278741659],"ant_foot":[795.056,1455],"ant_nominal_diameter":119.808,"count_rect":[810.416,1436,59.904,65]}]
- Sizing:
  - row_rect: [62,1342,816,176]
  - gap: 12
  - card_width: 153.6
  - ant_frame: SE at direction [1,1], nominal diameter 119.808, no board depth.
  - counter_font_size: 38
  - parent_scale: Root only. Flat Button hit rectangles remain the full 153.6x176; art height is approximately146.28.
- Semantic match: Warm gold cards, colored ants and live remaining counts implement selection.
- Observed difference: Manual comparison: approved cards use large portrait-like ant faces oriented toward the viewer. Current candidate uses a smaller side-facing full-body ant. Runtime also has five unique colors blue/red/yellow/green/purple, while the approved battle illustration shows four cards with blue duplicated. These are actual composition differences, not an offline shader approximation.
- Pending: Next batch is intended to address card portrait framing. No fix is claimed in this batch; review face orientation, portrait scale, all five card proportions, tint, legibility and row alignment.

### Four transport pedestals — present_candidate

- Sources: `assets/first-level/deck-controls.png` crop[101, 163, 948, 476]; `assets/first-level/slender-ants.png` crop[0, 0, 1774, 887]
- Consumers: `scripts/play.gd:390` build_slots(); `scripts/play.gd:406` sync_approved_transport_displays()
- Anchor:
  - kind: top_left_pedestal_foot_ant
  - pedestals: [{"index":0,"art_rect":[110,1250,132,66.28],"ant_foot":[176,1287],"ant_nominal_diameter":73},{"index":1,"art_rect":[271,1250,132,66.28],"ant_foot":[337,1287],"ant_nominal_diameter":73},{"index":2,"art_rect":[432,1250,132,66.28],"ant_foot":[498,1287],"ant_nominal_diameter":73},{"index":3,"art_rect":[593,1250,132,66.28],"ant_foot":[659,1287],"ant_nominal_diameter":73}]
- Sizing:
  - art_size: [132,66.28]
  - crop_to_logical_scale_xy: [0.139240506,0.139243697]
  - count_rect: [388,1309,164,35]
  - parent_scale: Root only. Preview actors are73 nominal source-width units, hidden unless a live task fills that slot; no board depth.
  - capacity: Exactly4 preview slots, matching existing gameplay limit.
- Semantic match: Round timber staging pads and ants are present.
- Observed difference: Runtime has four transport pedestals; approved battle illustration shows five pads. Preview actors repeat the source ant views rather than baked reference figures.
- Pending: Visual layout/pad carving/occupied-vs-empty contrast need approval; no capacity change implied.

### Battle speed, pause and settings controls — present_mixed

- Sources: `assets/first-level/deck-controls.png` crop[1279, 91, 590, 581]; `scripts/ui_icon.gd`; `scripts/first_level_medallion.gd`
- Consumers: `scripts/play.gd:365` approved_medallion(); `scripts/play.gd:368` build_approved_hud(); `scripts/first_level_medallion.gd:5` _draw(); `scripts/ui_icon.gd:19` _draw()
- Anchor:
  - kind: rect_top_left_with_centered_icon
  - pause: [21,15]
  - settings: [831,15]
  - speed: [420,1530]
- Sizing:
  - pause_settings_art_size: [88,86.66]
  - pause_settings_hit_size: [88,88]
  - pause_glyph_rect: [44,36,42,44]
  - gear_draw_box: [831,15,88,88]
  - speed_art_size: [100,98.5]
  - speed_hit_size: [100,100]
  - speed_label_rect: [432,1549,76,58]
  - speed_font_size: 27
  - parent_scale: Root only; medallion art is a clipped atlas region. Pause glyph is procedural; gear_only creates a centered48-vertex gear; speed is live text ×1/×2.
- Semantic match: Top-left pause/top-right settings positions and round warm-metal controls follow the reference role.
- Observed difference: Runtime bottom center is speed, not the reference plus/return/magnifier set; build_tools is empty. Glyphs are code-drawn rather than exact reference raster icons.
- Pending: Rendered button edges, glyph weight, hit alignment, speed states and settings flow need visual review.

### Shop background and category previews — present_existing_mixed

- Sources: `assets/meta-ui/shop-workshop-background.png` crop[0, 0, 941, 1672]; `assets/meta-ui/ant-shop.png` crop[0, 0, 908, 227]; `assets/meta-ui/worker.png` crop[0, 0, 774, 214]; `assets/meta-ui/swift.png` crop[0, 0, 544, 198]; `assets/meta-ui/training.png` crop[0, 0, 845, 209]; `assets/meta-ui/swift-wing.png` crop[0, 0, 607, 610]; `assets/meta-ui/ant-coin.png` crop[0, 0, 582, 584]; `assets/motion/ant-directions.png` crop[0, 0, 1774, 887]; `assets/motion/ant-directions.json`
- Consumers: `scripts/startup.gd:415` open_shop(); `scripts/ant_shop_view.gd:33` rebuild(); `scripts/ant_shop_view.gd:49` build_type_card(); `scripts/ant_shop_view.gd:98` fixed_title(); `scripts/directional_carrier.gd:223` _set_frame()
- Anchor:
  - background: [0,0]
  - titles: Full pre-cropped PNGs keep aspect centered inside declared boxes; runtime pivot default top-left, not manifest suggested center pivot.
  - shop_title_box: [180,45,580,120]
  - category_title_boxes: [[90,347,335,88],[515,347,335,88]]
  - worker_ant_foot: [257,680]
  - swift_ant_foot: [682,680]
  - preview_poses: full directional crop/anchor/size records in `asset-inventory.json`; see directional table below when applicable.
- Sizing:
  - background_logical_rect: [0,0,940,1672]
  - type_card_rects: [[55,320,405,730],[480,320,405,730]]
  - type_ant_nominal_diameter: 220
  - type_ant_frame: SE for direction [.8,.6]
  - swift_badge_rect: [803,458,60,60]
  - parent_scale: Shop Control is a startup child sized940x1672 with scale1. Only startup root scales to viewport. Preview ant source scale220/420, no board depth.
  - preview_ball: Capacity icon uses legacy assets/ui/fusion/beads.png blue crop, 47x47, not ApprovedBead 33.5. Preview ants have no CarriedBead child in build_type_card.
- Semantic match: Worker/Swift categories, workshop backdrop, point balance, capacity1 and swift speed bonus reproduce the shop information hierarchy.
- Observed difference: Different legacy ant atlas from first-level battle; plain previews have no back baskets/carried spheres and wing is a floating badge, not anatomically attached. Existing workshop art/cards differ from full approved shop illustration.
- Pending: Shared-style art pass and real rendered shop comparison are pending. No claim of matching hero/card backdrop details.

### Shop upgrade and training cards — present_existing_mixed

- Sources: `assets/ui/v03/settings-skin-atlas.png` crop[17, 17, 664, 970]; `assets/meta-ui/training.png` crop[0, 0, 845, 209]; `assets/motion/ant-directions.png` crop[15, 13, 449, 395]; `assets/ui/fusion/beads.png` crop[584, 93, 375, 376]
- Consumers: `scripts/ant_shop_view.gd:78` build_training(); `scripts/ant_shop_view.gd:49` build_type_card(); `scripts/ui_skin.gd:34` panel()
- Anchor:
  - panel_top_left: [55,1100]
  - title_box: [235,1118,470,82]
  - training_ant_foot: [205,1394]
  - training_ant_source_anchor: [244,340]
- Sizing:
  - training_panel_rect: [55,1100,830,375]
  - type_panels: [[55,320,405,730],[480,320,405,730]]
  - nine_slice: settings/panel source region17,17,664,970; source margins100; corner34 => child.scale=.34, child.size=panel.size/.34. This nine-slice transform is not extra scale for sibling previews/text.
  - training_ant_nominal_diameter: 175
  - training_ant_frame: E
  - training_action_rect: [409,1361,386,83]
  - level_text_rect: [395,1221,410,54]
  - effect_text_rect: [425,1281,350,51]
  - parent_scale: Root only outside panel-local nine-slice.
- Semantic match: Two type cards and shared carry-training upgrade preserve functional hierarchy.
- Observed difference: Generic reused settings panels, title reads TRAINING rather than CARRY TRAINING; no reference trail illustration or integrated carry baskets. Text and progress are dynamic, not reference650/500/100 baked values.
- Pending: Visual style/card decoration/hierarchy matching remains pending; economy data is not modified by this inventory.

### Shop actions and shared pause/settings panels — present_existing_mixed

- Sources: `assets/ui/v03/game-skin-atlas.png` crop[24, 1001, 684, 227]; `assets/ui/v03/game-skin-atlas.png` crop[16, 32, 650, 624]; `assets/ui/v03/settings-skin-atlas.png` crop[858, 1039, 376, 155]; `assets/ui/v03/settings-skin-atlas.png` crop[17, 17, 664, 970]; `assets/ui/v03/settings-skin-atlas.png` crop[685, 49, 564, 192]; `assets/ui/v03/settings-skin-atlas.png` crop[681, 1029, 173, 172]; `assets/ui/v03/settings-skin-atlas.png` crop[686, 566, 552, 110]; `assets/ui/v03/settings-skin-atlas.png` crop[706, 709, 395, 67]; `assets/ui/v03/settings-skin-atlas.png` crop[1115, 691, 107, 108]; `assets/ui/fusion/audio-icons.png` crop[215, 189, 468, 509]; `assets/ui/fusion/audio-icons.png` crop[1071, 236, 530, 479]; `assets/meta-ui/ant-coin.png` crop[0, 0, 582, 584]; `scripts/ui_icon.gd`; `assets/ui/v03/title-atlas.png` crop[0, 0, 1254, 1254]; `assets/ui/v03/title-regions.json`
- Consumers: `scripts/main.gd:80` frame(); `scripts/ui_skin.gd:34` panel(); `scripts/main.gd:345` modal(); `scripts/main.gd:403` show_settings(); `scripts/ant_shop_view.gd:49` build_type_card(); `scripts/ant_shop_view.gd:78` build_training(); `scripts/ant_shop_view.gd:113` icon_action()
- Anchor:
  - kind: top_left_rects
  - shop_back_rect: [28,45,108,108]
  - shop_back_icon_rect: [51,68,62,62]
  - back_arrow_pivot: [31,31]
  - back_arrow_rotation: PI
  - type_action_rects: [[90,913,335,92],[515,913,335,92]]
  - training_action_rect: [409,1361,386,83]
  - balance_rect: [665,197,230,76]
- Sizing:
  - shared_frame_selection: main.frame uses game/row by default, settings/primary for green active states, settings/panel for ModalPanel. Shop category/training panels call settings/panel directly.
  - nine_slice_formula: margin100 for settings/panel, otherwise64; ratio=corner/margin; local child.size=bounds.size/ratio and child.scale=ratio. frame clamps corner=min(radius,height*.28), with explicit special cases (green height*.40, ModalPanel58).
  - shop_green_type_action_corner: 36.8
  - shop_green_training_action_corner: 33.2
  - pause_modal_rect: [170,520,600,620]
  - settings_modal_rect: [143,585,654,440]
  - settings_audio_icon_sizes: [82,82]
  - settings_slider_track_size: [349,57]
  - settings_slider_fill_full_size: [306,27]
  - settings_knob_size: [49,49]
  - shared_action_size: [392,76]
  - parent_scale: Root only outside nine-slice and any modal presentation transition.
  - interaction: Transparent flat buttons overlay painted art; icons/text are live. Disabled/equipped/affordable states select frame/glyph, not separate baked complete cards.
- Semantic match: Warm parchment/wood/gold surfaces, green actions and point coins share the visual family.
- Observed difference: Shared generic nine-slice kit is not the reference shop decorated frames; actions use glyphs/price without all reference OWNED/EQUIPPED/UNLOCK/UPGRADE painted labels. Back control is rectangular shared frame plus rotated arrow, not exact round reference control.
- Pending: Unify battle/shop component styling if requested, and review readable states and hitboxes in engine.

### Fonts, procedural icons and contact effects — present_existing_code

- Sources: `assets/fonts/Title.ttf`; `scripts/ui_icon.gd`; `scripts/first_level_medallion.gd`; `scripts/contact_shadow.gd`; `scripts/rescue_fx.gd`
- Consumers: `scripts/main.gd:90` text_label(); `scripts/main.gd:99` icon(); `scripts/ui_icon.gd:19` _draw(); `scripts/first_level_medallion.gd:5` _draw(); `scripts/contact_shadow.gd:5` _draw()
- Anchor:
  - font: No image crop or source pixel pivot. Label bounds and center alignment in main.text_label.
  - procedural_icons: Center=size*.5; most ui_icon geometry radius=min(size.x,size.y)*.34. Gear-only center=size*.5, outer radius23 inner18, center hole10.
  - shadow: Origin=ground foot; six nested procedural ellipses from circle draw transforms.
- Sizing:
  - source_image_size: null
  - source_alpha: Not applicable for font/code. Glyph and icon coverage is generated at runtime on transparent controls.
  - font_use: Title.ttf applied to normal labels; painted titles use image PNG/atlas separately. Boot LoadingStatus does not call text_label and therefore uses default theme font.
  - font_import: Dynamic FontFile; antialiasing1, hinting1, MSDFfalse, system fallbacktrue, oversampling0.0, generate_mipmapsfalse; exact observed parameters in file catalog.
  - battle_examples: {"level_number":32,"count_stock":23,"carrier_count":23,"color_count":38,"speed":27}
  - shop_examples: {"balance":35,"capacity":37,"speed_bonus":33,"level":31,"effect":31,"training_price":32}
  - procedural_scope: Pause, check, play, arrow/back, plus, lock, home, clock, barrier and gear are vector draw calls. Optional shuffle/recall/hint SVG textures are generated from inline code, not external image assets. First-level build_tools does not instantiate the old tool row.
  - parent_scale: Root scale plus explicit Control/rotation/transition at call site. Font sizes are logical UI units, not source-image pixel sizes.
- Semantic match: Consistent warm labels and recognizable live controls.
- Observed difference: Procedural glyphs and shared font are not exact raster lettering/icons from approved images; title art is an additional asset family.
- Pending: Typography/glyph weight/scaling and antialiasing must be visually checked at target viewport.

## Additional source-consumer details

- Runtime first-level ball colors are red, blue, yellow, green and purple. White remains an available sixth atlas crop, not an instantiated first-level color.
- Shared PAUSED title crop: `[111,45,443,119]`; SETTINGS title crop: `[693,46,489,121]`, both from `assets/ui/v03/title-atlas.png`. Display boxes are `[249,515,442,65]` and `[249,580,442,65]`, respectively, with keep-aspect-centered fitting.
- Startup preloads existing shared art. The game batch requests the play scene, current layout background and target; new first-level assets load through the actual consumers listed above rather than all being explicitly enumerated in HOME_RESOURCES.

## First-level ant directional crops and ground feet

Every crop comes from `assets/first-level/slender-ants.png` (1774×887). Scale before inherited depth is62/420. Feet, cargo anchors, hip/toe segments and solid-toe ROIs are fully preserved in JSON; only visible legs are articulated.

| View | Crop x,y,w,h | Foot anchor | Back contact | Logical crop w,h before depth | Visible legs |
|---|---|---|---|---|---|
| E | [24, 32, 438, 392] | [220, 351] | [112, 205] | [64.657142857, 57.866666667] | 4 |
| SE | [509, 72, 401, 355] | [206, 313] | [108, 115] | [59.195238095, 52.404761905] | 4 |
| S | [968, 64, 289, 373] | [147, 331] | [145, 100] | [42.661904762, 55.061904762] | 6 |
| SW | [1342, 74, 390, 358] | [203, 313] | [280, 110] | [57.571428571, 52.847619048] | 4 |
| W | [40, 446, 425, 397] | [200, 355] | [285, 205] | [62.738095238, 58.604761905] | 4 |
| NW | [521, 451, 380, 399] | [189, 354] | [255, 245] | [56.095238095, 58.9] | 3 |
| N | [963, 461, 293, 387] | [147, 344] | [147, 258] | [43.252380952, 57.128571429] | 4 |
| NE | [1346, 445, 380, 405] | [187, 357] | [110, 245] | [56.095238095, 59.785714286] | 3 |

## Texture import and sampling

No explicit CanvasItem.texture_filter override was found in scripts, scenes or project.godot. Sampling inherits Godot CanvasItem/viewport defaults. Project sets textures/default_filters/use_nearest_mipmap_filter=false but does not explicitly pin the default CanvasItem filter. AtlasTexture.filter_clip=true is set by the consumers; this is region edge clipping, not a nearest/linear choice. PNG import params below show compress/mode=0, mipmaps/generate=false, fix_alpha_border=true and premult_alpha=false. No import file is claimed to prove runtime GL behavior.

Font:dynamic FontFile, antialiasing=1, hinting=1, MSDF=false, allow_system_fallback=true, oversampling=0.0. These are source/import settings, not a rendered quality guarantee.

## Source file checksums

The JSON file catalog includes bytes, native image sizes, mode, alpha ranges/bounds and per-file `.import` settings/hash. SHA256 values below are measured from the current checkout, not copied from prior manifests.

| Repository path | Native size / type | SHA256 |
|---|---|---|
| `assets/ants-atlas.png` | 1536×1024 RGBA | `5c33da8f1ad49d075e6d653b838cd4a0c5e5a18173f888a99524d5e1ac06f383` |
| `assets/characters-atlas.png` | 1536×1024 RGBA | `623febc6b29a1d148ac72a1571ac9e4d7e98a790e689434221d66eff52443e6d` |
| `assets/first-level/bead-regions.json` | .json | `cb7c10455c73c33aabe4a9091fd4e9a474ae356dbf94b9c61ec045b5349407f7` |
| `assets/first-level/bronze-cannon.png` | 1158×1359 RGBA | `9d1e4b4c8837ab8b01d8b4526bc9fe09e118245d010020c9f9185babe45ac93a` |
| `assets/first-level/color-card.png` | 1295×1214 RGBA | `66191f770e2a0780fe626e42d3d8e57d91a5606a29734a3582bc72d05487a91e` |
| `assets/first-level/deck-controls.png` | 1983×793 RGBA | `380ec9467aa5bd9ec44caa800a1f7a7b4fdd5b6ef5252d364f6ea864dd2ea0db` |
| `assets/first-level/manifest.json` | .json | `34813714f4c73ef83320df307564e33ae9a0373947fbd19eb54d6c42ded67706` |
| `assets/first-level/princess.png` | 1216×1293 RGBA | `87e80ffc56ae742c838b1f84f648efd3508cd6ff23741b86c2a5d2fc0f40ce86` |
| `assets/first-level/round-beads.png` | 1536×1024 RGBA | `0c353fb03ed54f8f71036bb489802b026b072fd1b94e5e4a69d3a8b0c594d60b` |
| `assets/first-level/slender-ants.json` | .json | `2e1e46613d0adaa184551a217d790f692b9f15870d799ae0badd0cb7655a2133` |
| `assets/first-level/slender-ants.png` | 1774×887 RGBA | `d5cfe909930285759e1af539212f89f5dd098c041637c5c2150760f536fe127c` |
| `assets/fonts/Title.ttf` | .ttf | `21f02ebcea75529d3ed9d26e089cd1b9c59a4b784119ba3a96e9bc83cf755ec7` |
| `assets/meta-ui/ant-coin.png` | 582×584 RGBA | `68a34b6320c09ab8b4fe34d26af2cf34e8f81246fbd3b6e2c645ff1740ba7adc` |
| `assets/meta-ui/ant-shop.png` | 908×227 RGBA | `afb41258813b41580dd30567092d34aa2386c30bf9364d141ee68af1caef847c` |
| `assets/meta-ui/icons-atlas.png` | 2172×724 RGBA | `d52995231c203099a6cd961395688d0dbc974146518a14710f5d157dbedc7530` |
| `assets/meta-ui/manifest.json` | .json | `c568a960cf3da34d770b16de9b81ca12863359002c39f739a3539e95b9fe86cc` |
| `assets/meta-ui/shop-workshop-background.png` | 941×1672 RGB | `b3fc9980982e744901020b0193cc341917307a18b9647bd8b704ca53bf8d880b` |
| `assets/meta-ui/swift-wing.png` | 607×610 RGBA | `68aba534c2ed376e1b6623a1ccbc0fa09a8971c89a5b75f54373ffc4b1a99d42` |
| `assets/meta-ui/swift.png` | 544×198 RGBA | `2c708ae1276c179f2375917c67f1af91a8b9e13bca0bde0ec394841c5aeee448` |
| `assets/meta-ui/titles-atlas.png` | 1024×1536 RGBA | `3b839fc1ccbba4612c27e34e386cb7e6c1ce6a1e48febedfbdf22077170846c6` |
| `assets/meta-ui/training.png` | 845×209 RGBA | `5dd329cc0262f931cdbded1ec7267cdb845aaf4a14c1bbd7913c51e7074c818e` |
| `assets/meta-ui/worker.png` | 774×214 RGBA | `bbce5e5d2ead54a55979fd0faadaf2624b12d1c95f21d853b385910196d53e4e` |
| `assets/motion/ant-directions.json` | .json | `55f60f1e9f251c80f219c4aacc680aeca6f83820794110b16a7943e1fae46fa9` |
| `assets/motion/ant-directions.png` | 1774×887 RGBA | `84f9fae1f64cbf9003580e1ee54800078f82b8e87829ebbf9f6ae57e20e7432e` |
| `assets/serpent/environment.png` | 941×1672 RGB | `64549070c131b085178e4c6995f2964b9a04195262b73655636ed5f1423e9f9a` |
| `assets/serpent/nest-entry.json` | .json | `b8a5b11f27c5884044142f4b89604cec0bfaf6e9f621122f42591632bed1da83` |
| `assets/serpent/nest-entry.png` | 905×529 RGBA | `2bf120d083b40251e6b48a2080a286464a322c9f0a67cb57babdd1f99f919e69` |
| `assets/serpent/serpent-atlas.json` | .json | `e1c9b6d370cd3509aa2ab9f601ca0f72243b22c22cddaa747ec051ec435a3d69` |
| `assets/serpent/serpent-atlas.png` | 1303×1774 RGBA | `caf1130462c58cf121e529e60810218b2ae3d7dc3939670ebdefeb1788f9a360` |
| `assets/ui/fusion/audio-icons.png` | 1774×887 RGBA | `6cc80b566ff8fbc8c870f57783f0fee0af2f421a0ca5d73aae2ff355fe5d249b` |
| `assets/ui/fusion/audio-regions.json` | .json | `174b9ffccbf1a2bf3bb265428145e80c58fa0499caf0442b463274fe3e78e55f` |
| `assets/ui/fusion/bead-regions.json` | .json | `fb476fc6138d28481924ba0f88f063efa478e219606a5d655ef3429f2471342e` |
| `assets/ui/fusion/beads.png` | 1536×1024 RGBA | `bcff13277e0bac7cf558f97c935bb9b9c2a286e35995f44d26c37b9430d3717d` |
| `assets/ui/v03/game-skin-atlas.png` | 1254×1254 RGBA | `837deff16eded4908bb6c1801846cea395f8abba192eeeed6745adca712412af` |
| `assets/ui/v03/regions.json` | .json | `b588017706070e317fe4174e518e9a8617fa05fd1e2df3a68dcadd7861e2a29f` |
| `assets/ui/v03/settings-skin-atlas.png` | 1254×1254 RGBA | `f3caf49459a7919760779bb18311ff321f02d9c878cf1ec4204ed14f0a82dda4` |
| `assets/ui/v03/title-atlas.png` | 1254×1254 RGBA | `188dfad260a9851b6020c1bd0a2fe21ebc295212fd03775bd9bf71335ba9bbee` |
| `assets/ui/v03/title-regions.json` | .json | `62a40610fcca9d9db8c0928b70c1552a20ab117cf89c4dc543f22e2a560bf43f` |
| `data/ant-regions.json` | .json | `954b0440eb5d7649108aacd0708fcaa91ac92da96ef3f470e2607cbfd6eb22c5` |
| `data/scenes/first-level-approved.json` | .json | `78a3acdc51da5a95f66cda0df4b1fc2f44ff9aabe749fba158afb76f0ba8d957` |
| `data/serpent-levels/serpent-01.json` | .json | `bf09222005648bdc853e3fa7bab15c505dc297b0931ded1d9be3bfa0af2896b5` |
| `project.godot` | .godot | `dacfbfc62b6caf0b2cfc1c2e2b79f1655129a247bbcbdc3a044af64d32ff829d` |
| `reports/first-level/approved-battle.jpeg` | 864×1536 RGB | `2834990e47b7f1b2b1edd7242d09cb938b51eaeb64369ac821bdfe3d64735c71` |
| `reports/first-level/approved-shop.jpeg` | 864×1536 RGB | `9fc20788cf081cb1d5d00025460ee9675a1d5587e4659d58410529b8d104fa2c` |
| `scripts/ant_shop_view.gd` | .gd | `80d8de65b90401a407e7a9809d7873c1814110ab0ac22173d56f7a1f6633aab5` |
| `scripts/board_plane.gd` | .gd | `c15e73e00328af5ba6081b52a0c1bb040316f9403ff6093d28f4f8f2e51c0709` |
| `scripts/carrier_route.gd` | .gd | `9fbf2b04e64f1a94ab153fc084c87d8d096974a714f25e77bffef7fcde574622` |
| `scripts/combat_tint.gdshader` | .gdshader | `51d8640c68faee38fc3072f95053ed12f5d40e369fc4ba1d52428e5bde93d393` |
| `scripts/contact_shadow.gd` | .gd | `ef384880665827ec7bddc9954bce972f13106c74aee14b367489c48df2cbfd0c` |
| `scripts/directional_carrier.gd` | .gd | `d6f6e3c4a82978205dfb62e483839949c37b05dbd5e88ce3f87a9f755a23f16c` |
| `scripts/directional_carrier.gdshader` | .gdshader | `3f5bab577d8ed4d2dc7b0724f7cfaf9d20c0d7bc33b8a99ed7f6d1a85bbcc2a8` |
| `scripts/first_level_bead.gd` | .gd | `b15b74ad6f799565e8a0af011b02df964d46d70e439a639ea45a1893c0e582c3` |
| `scripts/first_level_carrier.gd` | .gd | `6ae9814b5cdab7891b8b38ed6ff13caa0a22ad25185a10aef900bfb0c119fd22` |
| `scripts/first_level_carrier.gdshader` | .gdshader | `b452bbc0a309fae4c1fbee790f6c8d2a9f5ba381e7f439e8af4d2032c1661779` |
| `scripts/first_level_color.gdshader` | .gdshader | `d1f526879f67f51d74650f5d178b0a377267e27da0b2dd7fea9093ddbf03df2d` |
| `scripts/first_level_medallion.gd` | .gd | `0165e31edf882d57eb818094524ec8a1cb3afefcbca0b1999dd07c2b3e30eba4` |
| `scripts/main.gd` | .gd | `7c8f7c82eaaa1ceb389bbdaa7a4e44bbae7a4238b1fd6e7f80673d1165d3cf5e` |
| `scripts/play.gd` | .gd | `81e5cc52f12f5b963f25536ce2c2b35fa20125e76b36e0c274d845b6796bcf1a` |
| `scripts/rescue_fx.gd` | .gd | `ca0ae740abf10d325e04d0b903e6c565992db24ce8b27ac56f5191c38fa499d1` |
| `scripts/scene_layout.gd` | .gd | `e0f544557962f97636690498c3e5df24a7d1475c29a3a19edc9cff2b7ee0024a` |
| `scripts/serpent_path.gd` | .gd | `09784d7fa0a7a223b89102becd789c08002a6637160195a45c1978a542c83170` |
| `scripts/serpent_view.gd` | .gd | `4d0d4949d0047e56786fccc19a490d27844dab6f94023625b5a0b3a6fa2a41f5` |
| `scripts/startup.gd` | .gd | `188cdaab8976833996a46938c775401f1559b968ca4b90f7fcb71b8b884b468f` |
| `scripts/ui_icon.gd` | .gd | `6ce842b5fd26bf5a5d61c3340094dca724b056d6166b899173d17a230dccaf75` |
| `scripts/ui_motion.gd` | .gd | `aa2163822dba6fa74293077ba2c8dc77e50cf688f4c40d48ae487d2221a35aa9` |
| `scripts/ui_skin.gd` | .gd | `7e4c3ec533912b39a8745c82d52e57f630c464a45194aa4dba574e580d7dc319` |

| `reports/first-level/layout-contract.json` | .json | `3e45e3153a503a5a2953d53496ed466c004a0491859f1703c843e490546224ea` |
| `reports/first-level/approved-reference-manifest.json` | .json | `6089dd9bb227085aa087c62372922f33afdd0a062555ce6717b02ef5a683ee9d` |

## Verification limits and next review

- This pass verifies file existence, hashes, native dimensions, alpha, crops, code consumers and transform formulas. It does not establish real GPU rendering, final image fidelity, gameplay/QA completion, or user acceptance.
- Existing `reports/first-level/batch-2/nodes-after-initial.json` is labeled OFFLINE NODE COMPOSITION and only supports structural size observations, not visual rendering claims.
- Remaining visual review:all eight ant directions and feet, back-load occlusion, clean ground/path alignment, cannon recoil/hopper placement, missing crew, princess platform placement, battle/shop art-family consistency and all action states.
- PRDs, Issues, commits and production assets/code were not modified by this inventory task.
