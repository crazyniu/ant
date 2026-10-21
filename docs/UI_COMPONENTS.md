# Current UI contract

## Canvas and hierarchy

The logical composition is 940×1672, uniformly scaled to a 1440×2560 viewport. The desktop window starts maximized and uses keep-aspect viewport stretching; small physical screens display letterboxing rather than crop or distort. Mouse inputs use Godot transforms, not manually unscaled screen coordinates. Actual GL capture dimensions are independently verified.

Environment → route actors → independent bead nodes → transport/stock → HUD → work slots → candidate teams → skill icons → blocking modal. All decorative controls ignore mouse input. A modal shade receives pointer events and blocks the game beneath it. X and ESC use the same navigation function.

## Reusable skin

`scripts/ui_skin.gd` loads `assets/ui/v03/regions.json`. Each entry is `[x,y,width,height]` in the actual source bitmap. `AtlasTexture.filter_clip=true` prevents adjacent-region bleed. `TextureRect.EXPAND_IGNORE_SIZE` is applied before assigning a texture so atlas minimum sizes cannot expand layout.

Panels use `NinePatchRect` with source margins of 100px for settings/panel and 64px for other patches. The container and patch are uniformly inversely sized/scaled to the intended display corner: modal58 logical pixels, small plates8–18, action buttons30. Do not stretch full panel art as a single TextureRect. Plaques, icons and labels are separate children; title art keeps aspect ratio.

`title-regions.json` records alpha-measured words, not equal cell cuts. The source image is1254×1254 RGBA with49.38% fully transparent pixels. Row boundaries were detected independently on each column to avoid the top row shadow bleeding into LEVELS/SAVED. All source glyphs remain unchanged.

## Information and input

- English only in runtime. Art titles are transparent bitmap sprites. Dynamic quota/ammo/stock/level numbers remain real text and state, never baked fake numbers.
- No redundant CURRENT ARMOR, ARMOR SEQUENCE, NEXT or delivery/automatic-fire prose in the HUD. Armor separators are visible only when both adjacent icons exist; final victory clears the exhausted chain, route markers and meaningless 0/0 ammo plate.
- Inventory is bead+count with uniform dark outline, not nested cards.
- Five individual white work slots have no enclosing tray. A successful Extra Slot action relayouts six independent slots inside the same allotted area. Candidate front rows have one lightweight146×55 logical target each. Rear rows have no buttons and remain separately readable.
- Same-color20 and30 are distinct preview teams with stable IDs. A front action verifies the displayed team ID and rejects rapid replay during the180ms view transition. The play adapter preserves these checks and delegates to rules.select_front; the gallery keeps an explicitly nonplayable fixture.
- Four125×125 dimensional tool images have132×132 targets, no labels and no enclosing tray. Small remaining-use badges are dynamic decision information. Tooltip copy is English.
- Settings: music-note and speaker images, two independent real HSliders, zero means mute, one X. No percentages, labels, toggle switches or duplicate Back. Each transparent native grabber is 49×49, matching the visible pearl knob, with a 355×57 hit region and 306-pixel travel. Both endpoint knobs are fully draggable.
- Other modal text is retained only for useful action labels, tutorial rules, recovery or progress-loss warnings. Necessary loss-of-round confirmation must not consume a tool or alter quota when cancelled.

## Audio bindings

`scripts/audio_service.gd` is a single scene child. Every actual Button gets one click connection on node_added. Slider changes call apply_settings_state; modal entry/exit calls set_game_paused. Settings alone auditions the BGM at the chosen level without resuming simulation; background and SceneTree suspension still silence it. Returning to pause ends audition, and release of a changed nonzero SFX slider previews one click. Zero volume stays silent. The play adapter feeds transport, combat and actual outcomes from authoritative rules events. Confirmed tool_used events emit one mapped tool cue; scout maps to the hint cue. Rejected, cancelled and stale requests do not emit success audio or FX. Showing a specimen modal never fabricates gameplay success. The audio service owns independent AntMusic and AntSFX buses, finite voice pools, rate limits and application-focus behavior.

## FX and rules

`scripts/play.gd` binds the four icon-only tools to rule state, displays dynamic remaining-use/lock/used state, and preserves five-slot defaults on retry. Recall presents real eligible teams in a paused target modal; cancel does not charge. Scout highlights the current front team, legal exposed cells and current armor without pausing. Its single short-lived explanation derives the actual ammo shortfall, in-flight debit or cooldown from live rule state. Other-color stock remains valid; the suggestion is not a claim of the best move. Error feedback temporarily hides this explanation rather than overlapping it. Shuffle accepts only an independently replayed, timed winning permutation.

Settings preview values while dragging and commit atomically on drag end or close. First-run tutorial is skippable and persists completion. Its six short steps include five-slot waiting when no reachable matching target exists, delivery, automatic fire and final-hit rescue. Existing-profile cold entry starts a fresh round and shows one nonblocking notice until the first successful team; ordinary scene replacements do not duplicate it. Selection exposes only actual saved-unlocked content; saved victory unlocks the next entry before showing Next, and the last available entry has no missing-level button. Load/save errors are technical states, not fabricated defeats.

See `reports/rules/API.md` for authoritative microsecond simulation events. Presentation never debits quota/inventory or settles victory. Final hit only, not pickup/delivery/fire, may rescue the princess. FX integration contract belongs in `docs/FX.md`; source packaging records whether it is included. Opening a tool-info UI is not an accepted tool effect.

## Readable transport and final-hit presentation

Current transport configs use a 0.55-second minimum one-way leg and a 0.16-second pickup hold. A picked bead opens its cell immediately but only delivery credits inventory. The independent 48-pixel ant keeps its foot/shadow on the shared projected path; local original-art limb movement, finite crouch/turn and 24-pixel load distinguish walking, pickup and loaded return. The visual path holds at the target until `return_depart_us`.

Final hit locks and saves victory immediately. The 1.60-second weighted collapse then completes before the result panel/jingle; the pause button cannot obscure it, background suspension freezes it, and repeated events do not replay persistence.

## Startup and result controls

The project entry is `scenes/startup.tscn`. A native brand splash leads to a local threaded resource batch, independent Home, then a real game-scene batch. Home Play opens the saved entrance as a fresh round; Home level selection uses the existing catalog picker. Closing that picker returns Home without marking the tutorial complete. The pause Home control requires confirmation only when abandoning an active round. Validation and candidate catalogs keep their existing separate profile paths.

The Loading bar is the equal-weight aggregate of completed resources plus the current resource's actual engine progress. It is not bytes, elapsed time, a network request or a timer. There is no minimum loading duration. Failed resource batches retain an explicit Retry action; save corruption uses the existing recovery flow, not silent defaults.

Result panels use a 744×1040 logical footprint; actions are 560×118 with 24-unit separation and centered 88×88 arrow, retry and level-grid icons. Their English action names are tooltips, not persistent labels. At a 375-point portrait width the action target is approximately 223×47 points. Nine-slice scale is uniform at corners; input bounds never follow press/reveal animation. The panel is evaluated after the finite entrance animation as well as during it. Final-hit save and victory remain independent of that animation.
