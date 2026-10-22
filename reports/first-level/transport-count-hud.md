# Remove only the rejected transport number

The approved correction removes the visible `x / 4` number beside the four
transport pedestals. All four pedestals, occupancy actors, internal four-carrier
limit, five color-card remaining counts, full-capacity feedback and speed control
remain. No ant/ball scale, art, route, reward or timing changed.

`test_first_level_inventory_hud.gd`: 98 checks, no failures or error/warning lines.
It verifies absence initially, during pickup/unload, firing, pause and hit; retains
all four pedestals and five real counts. The first blue pickup/unload/delivery/fire/
hit times remain 3.7 / 8.625 / 9.425 / 9.425 / 9.875 simulated seconds. This is a
finite headless production-controller test, not a GL video or whole-round run.
The preview test's count-node expectation was updated but its full suite was not
rerun in this small deletion batch. Real runtime video and ant/original-art size
comparison remain separate. The visible ant size is not claimed corrected.
