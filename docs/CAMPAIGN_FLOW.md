# Opt-in campaign candidate

The default `scenes/startup.tscn` entry opens Home and uses real threaded loading to enter `scenes/play.tscn`, with the three validation levels and their original progression. No validation source, rules, formal artwork, audio,
FX, BoardPlane, save schema or independent Level Studio file is changed by this
candidate integration.

## Launch

From this project directory:

```sh
# Normal validation build: unchanged.
godot --path . --rendering-method gl_compatibility

# Explicit candidate opt-in. Starts/resumes its own saved entrance.
godot --path . --rendering-method gl_compatibility -- --campaign-drafts

# Request an already-unlocked candidate entry, never bypass saved locks.
godot --path . --rendering-method gl_compatibility -- --campaign-drafts --level=16

# Automatic proof playback: fresh isolated /tmp profile, not human playtesting.
godot --path . --rendering-method gl_compatibility -- \
  --campaign-drafts --auto-replay --level=30
```

`level_catalog.gd` explicitly maps `campaign-01` through `campaign-30` to the
corresponding actual `data/campaign-drafts/campaign-NN.json` file. It never maps
missing/invalid candidate content to a validation board. Source identity and
intended `level_number` must match the selected catalog entry. The original
`production_level_number: null`, `content_kind: authoring_draft`, and proof
metadata remain unchanged; Rules use `level_number` for unlocks 3/6/9/16.

The formal-art selector has three pages of ten entries, with sequential locks,
completion stars, bounded Previous/Next controls and real scene entry. The
unobtrusive `CAMPAIGN PREVIEW` label distinguishes the opted-in candidate. There
are no made-up buttons or level 31. Next appears only after a successful actual
final-hit completion save. Last level 30 has Play Again and Level Select, not
Next. Restart, leave, save retry, recovery and scene replacement retain the
catalog, source identity and exact isolated profile. Reopening a picker retains
its browsed page; a fresh scene opens the page containing its saved entrance.

## Profile and replay isolation

- Default validation: `user://ant-rescue`.
- Candidate: `user://ant-rescue/campaign-drafts`.
- With `ANT_RESCUE_PROFILE_DIR=/chosen/root`, validation uses `/chosen/root`
  while candidate uses `/chosen/root/campaign-drafts`. The override is always a
  root, not permission to combine catalogs. Do not append that suffix manually.
- `--auto-replay` always allocates `/tmp/ant-rescue-replay-PID-TICKS`, overriding
  the normal directory and environment setting. Scene replacements preserve
  that replay session directory. Test unlocks/tutorial bypass exist only there.
- No progress, volume or tutorial migration between validation and candidate is
  performed. No player's validation profile is rewritten to accept campaign IDs.

The launcher prints a `CAMPAIGN_PREVIEW` record with the source ID, isolated save
location, automatic replay state and acceptance boundary. This is diagnostic
output, not permanent debug text on the game screen.

## Verification and acceptance boundary

All 30 draft sources currently have paced (at least 0.75 seconds between inputs)
no-tool replay proof for the current readable-transport parameters. Full-level exact-final-hit/contact boundary certificates are NOT_RUN for this timing version; focused authoritative boundary tests remain separate. These are
machine proofs, not evidence of natural human completion, recognition of motifs,
subjective difficulty, final visual approval, actual listening or device
performance. `human_playtest` and `visual_acceptance` remain `NOT_RUN` and
`production_eligible` remains false. Do not count this preview as the formally
verified 30-level campaign until corresponding human playtests and acceptance
are completed.

The reusable finite actual-scene suite is designed to cover all 30 scenes (its previous full sweep is not current timing evidence after transport retiming): source IDs, nonempty actual
bead nodes and every color count, shared projection, five queue columns,
front-only input targets, three-row-limited rear previews, real armor/ammo,
normal tool unlock context, conserved no-tool final-hit victories, sequential
saved Next, final-level limits, paginated pointer routes, tile spacing/labels,
retry/leave Cancel, entrance/victory save failure, corrupt backup recovery,
invalid-source shell and automatic replay isolation.

```sh
export HOME=/tmp/ant-campaign-home XDG_CACHE_HOME=/tmp/ant-campaign-cache
export XDG_CONFIG_HOME=/tmp/ant-campaign-config XDG_DATA_HOME=/tmp/ant-campaign-data

godot --headless --path . --script tests/test_campaign_flow.gd
godot --headless --path . --script tests/test_p3_flow.gd
godot --headless --path . --script tests/test_play_binding.gd
godot --headless --path . --script tests/test_play_input.gd

# Each probe launches a separate process; use a different root each time.
ANT_RESCUE_PROFILE_DIR=/tmp/ant-rescue-campaign-cli-locked-$$ \
  godot --headless --path . --script tests/test_campaign_flow.gd -- \
  --probe=campaign-locked --campaign-drafts --level=30
ANT_RESCUE_PROFILE_DIR=/tmp/ant-rescue-campaign-cli-auto-$$ \
  godot --headless --path . --script tests/test_campaign_flow.gd -- \
  --probe=campaign-auto --campaign-drafts --auto-replay --level=30
ANT_RESCUE_PROFILE_DIR=/tmp/ant-rescue-campaign-cli-default-$$ \
  godot --headless --path . --script tests/test_campaign_flow.gd -- \
  --probe=validation-default --level=3
```

Current scope record: `reports/ui/campaign-flow-report.json`. The current three-validation-level actual node replay is `reports/ui/motion-binding-report.json`. Authoring proof and boundary
results remain separate in `reports/campaign/`. Graphical captures and human
playtest records are separate acceptance stages, not implied by a headless pass.
