# Separate window inserts

Author: Vittorio. Introduced in 0.21.0.

## Registration and assets

`spWindowInserts` is generated configuration, appended to `spParts` to preserve
existing registration order. There are 104 buildables: the original 40 straight
inserts and 64 curved inserts for measured curved openings. Both Hypotenuse
window widths retain the matching small opening. Curved inserts follow the host
radius and use distinct keys, anchors and bent shutter hinges.

Since 0.24.0, the window group remains registered for native variation selection
but is marked `contextOnly` in `spBuildMenu`. The regular grid excludes every
member; `spWindowContext` and `buildUI:spShowWindows` expose exact host matches.
This does not remove recipes, Rebuild groups or existing saved insert types.

`spWindowInsertUtils` owns recipes, explicit material aliases, placeholders and
host anchors. Each opening has a separate snap group, so an incorrectly sized
insert cannot snap into it. The origin is the opening center, distinct from its
host origin. Anchors are added only to completed supported window walls.
Native resource handling owns delivery, construction, dismantling and refunds.
One split log renders both shutter leaves through `additionalIndexCount = 1`.
Stone Block Any maps to the `resource` placeholder prefix, including storage.

The original straight release added forty helper assemblies and fifty shared
content meshes (90 physical GLBs),
1,025,808 bytes in total. Species and rock variants use composed runtime material
aliases. The same small meshes serve all LODs. Native bounded atlas patches are
used; UVs never cross unrelated atlas regions. Ten identical frame meshes were
consolidated, and the two shutters share a single leaf mesh per opening.

`window-insert-tests/build.py` buffers all native inputs and generated outputs
before writing. It finishes with `model_assets.consolidate`, including lossless
complete-attribute vertex packing. Keep a complete source snapshot before
regeneration. Do not run historical wall generators. The bidirectional per-slot
reuse scan found no additional rigid candidates among matching ordered UV/color
attributes; it does not claim a global minimum for arbitrary remeshing.

## Operation and persistence

The two radial actions are ordinary native plans. `spShutters` validates ownership,
completed shutter type and a single bounded object ID, then passes only explicit
fields to native plan creation. There is no additional network endpoint, arbitrary
code loading, filesystem access, or global Sapien scan. A competing pending
command is removed before the new one is queued. Native cancellation, job
assignment, movement, prioritization and retry behavior remain in control.

The custom order runs `moveTo` followed by a short operation action. The client
uses the native inspection pose for that action; server timing stays custom.
Completion rechecks ownership, type, distance and the still-existing plan before
writing `sharedState.spShuttersOpen`. Missing state means closed. Save/reload and
multiplayer synchronization use the native shared-state mechanism.

`spShutterAnimation` only tracks streamed shutter objects. The two resource
submodels opt into dynamic rendering before creation and rotate about authored
hinges. Opening takes 0.55 simulation seconds. Pausing stops movement. Material
refreshes reapply the current angle; streaming in uses the saved final state.
No mesh regeneration occurs during construction, demolition or animation.
Selection collision remains in the opening, while navigation collision is
disabled; the host wall remains responsible for blocking walking through windows.

## Verification

Run `window-insert-tests/verify.py` with the selected edition's `SAPIENS_GAME_DIR`.
Public checks also use `audits/structures-plus-20261014/checks.py --child public`
to redirect native helper imports. Tests cover packed triangles, finite attributes,
preview camera frusta, exact connector heights, native placeholder expansion,
native radial-plan metadata, material aliases/LOD fallback, recipes, permissions,
cancelled and reversed commands, distance checks, saved state and animation reset.

The existing 20-suite regression matrix passed for both Beta/Unstable and Public.
These are offline tests against the installed native Lua code and assets, not a
live engine playtest. In-game acceptance should check snapping, deliveries,
opening/closing from both sides, native cancellation, reload, and multiplayer.

## Context selection and shutter refresh (0.21.1)

`spWindowContext` resolves host IDs against the same configuration used for snap
anchors. The UI-only `spBuildWindow` plan is appended after existing plan IDs.
The main-thread dispatcher intercepts it; the server rejects it as a work plan.
Only a single completed, owned host is eligible. Both Build grids are filtered
by view identity; unrelated grids and global variation registries are unchanged.
Native resource, research, preview and placement code remains in control.

`spShutterRequestedOpen` records explicit player intent on the server. Completion
requires that intent, a matching queued plan, ownership and reach. Only boolean
true renders an open saved state. Refreshing an individual leaf restores its
pose without advancing animation or changing the saved state. Existing open
states are retained. The user's intermittent opening report was not reproduced
in-engine; these are targeted guards, not a verified single-cause diagnosis.

Shutter radial actions require a full mouse click on the action, rather than a
release-only quick swipe. Native controller actions remain available. Native
quick-swipe dispatch was verified in both game editions; whether it caused the
reported intermittent opening still needs an in-game check.
