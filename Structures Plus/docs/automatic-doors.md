# Automatic doors

Author: Vittorio. Introduced in 0.18.0; standalone inserts added in 0.19.0.

## Selection and shadows (0.24.0)

Use **Build Door** on a completed owned doorway. Door groups remain registered
for native variations, but `contextOnly` excludes them from the regular Build
grid. Native, Hypotenuse and both curved sizes retain their matching inserts.
The three leaf assets now expose a `shadowVolume` node sharing their existing
closed render mesh. Both maintained door generators emit this role; there are
no duplicate buffers, per-species shadow files or extra animation callbacks.
The 0.24.0 node-only fix did not restore shadows in the user's live test.

### Static shadow batching (0.24.1)

Read-only inspection of the installed Beta renderer and its shipped symbols
shows `renderToShadowBuffer` drawing each dynamic root buffer, without iterating
its dynamic submodels. A shadow node inside a dynamic leaf cannot fix that path.
Doors now retain `RENDER_TYPE_STATIC` and no longer enable the root dynamic
override. While moving, the animation removes and re-registers only its leaf at
the updated hinge pose. Calling only `setSubModelTransform` would leave the
static batch unchanged. Registrations retain the native material/LOD selection,
scale, translation and nested data; no disk model generation or physics change
occurs at runtime. Updates are capped at 30 Hz plus endpoint delivery, stop while
paused or idle, and release cached state on unload/type changes. A native leaf
refresh restores the current pose even while paused.

Offline tests exercise lifecycle, high-frame-rate update bounds, idle behavior,
material refresh, both opening directions and the native registration contract.
Live moving shadows and performance with many simultaneously moving doors still
require an in-engine acceptance check. Do not restore dynamic-only rendering
without checking the engine's submodel shadow implementation.

## Hypotenuse doorway support (0.19.4)

The same insert now fits the ten completed Hypotenuse doorways: five materials
at both 2.828 m and 5.657 m wall lengths. `attachAnchors` derives these targets
from `common/slHypWalls` entries with `form == "door"`; the batch hook calls it
after the Hypotenuse types have been expanded. Solid walls, windows, shortwalls
and unfinished doorways receive no insert anchor.

The existing wall generator preserves the centered opening while changing the
outer panels, so neither the leaf nor its placement helpers need scaling.
This reuses all geometry, previews, material aliases and animation. Geometry
checks cover the actual attachment/collision helpers and reconstructed opening
meshes; native registration checks cover all ten hosts and table isolation.

## Retired combined prototype (0.19.3)

`spDoorWood` is compatibility-only. It is absent from build variations,
Rebuild targets and resource-based placement suggestions. Native clone/Rebuild
lookup and direct placement selection redirect it to `splitLogWallDoor`.
The standalone insert is unchanged. Existing objects and saved work orders
retain the original recipe, model, placeholders and animation; these are runtime
dependencies for save compatibility, not unused assets to delete. No save
migration or forced demolition occurs.

## Registration and assets

`common/spDoors.lua` holds stable persisted identifiers `spDoorWood` and
`spDoorWoodInsert`. Preserve both when extending this feature.
The standard part registry clones `splitLogWallDoor` for both built and
in-progress objects. The retired combined recipe has no Rebuild target group;
its lookup selects the native doorway so existing walls can still be replaced.
`preventGrassAndSnow` remains false.

`common/spDoorUtils.lua` copies resolved native placeholder definitions without
mutating their source. It adds `splitLog_12` after the native six split logs'
eleven display slots. The seventh split log funds and colors the complete leaf.
No extra inventory or refund implementation is necessary.

`spDoorWood.glb` retains all native collision, path, placement, storage and
camera helpers. Its only new helper is the hinge at (-0.48, 0.04, 0) metres.
`spDoorLeaf.glb` contains five beveled boards, two braces and timber grips. Its
width is 0.96 m and height 1.84 m; vertices are authored around the hinge, so
rotation does not require per-frame geometry changes.

Species use explicit `lightWood` material remaps registered after compatible
material discovery. One low-complexity leaf serves every LOD and material.
The wall keeps its native component LODs. Do not generate animation-frame or
material-only GLBs when extending this family.

## Runtime and scope

`logicThread/spDoorAnimation.lua` tracks only completed, loaded door objects.
The existing client hooks register/reapply poses after native built-object
updates and reset the registry on world initialization. Missing objects or
changed object types are discarded on update. State is visual and client-local;
no save fields, server authority, remote messages or new path edges are added.

Since 0.18.1, the `clientGOM:setSubModelForKey` wrapper identifies only completed
door objects and their configured leaf key. Before native leaf creation it
enables `setDynamicRenderOverride` and selects `RENDER_TYPE_DYNAMIC`, following
the native moving-submodel contract used by hauling ropes. Native built-object
rendering otherwise requests `RENDER_TYPE_STATIC`; sending transforms alone is
insufficient for this moving leaf. The other submodel arguments, return value
and material selection are preserved. Type changes release the owned override;
unload/world initialization discard local tracking.

Nearby Sapiens are queried through the engine's spatial set within 4.5 metres.
The local trigger box spans X ±1.5 m, Z ±3.5 m and Y -0.65 to +1.1 m relative
to the doorway's ground origin. Its width also covers the leaf's swept region.
Other-storey root positions are excluded. Idle proximity queries are limited
to one per 0.15 real seconds per loaded door. Closing steps check occupancy
again before changing the pose; idle doors do not submit render transforms.

The leaf opens through 90 degrees in 0.35 simulation seconds using a smooth
interpolation, then waits 1.25 simulation seconds after the trigger becomes
empty before closing. An open leaf never reverses hinge direction. Pause
freezes movement and timers; game speed scales both.

This is proximity animation over a permanently navigable native passage.
The shared leaf mesh has no collision helpers. The separate assembly has a
slim selection box at the closed position, excluded from pathfinding and
walkable physics sets; selection does not follow the visible swing. Doors provide neither a lock nor
security, room-sealing or dynamic path-blocking semantics. Each client animates
from its locally loaded Sapiens; multiplayer timing can differ with streaming
or latency. Strict synchronized physical gates would require separate server
state, collision/path lifecycle work and multiplayer validation.

## Standalone door placement

The five native straight doorway models (`thatchWallDoor`, `splitLogWallDoor`,
`mudBrickWallDoor`, `stoneBlockWallDoor`, `brickWallDoor`) were inspected in both
installations. Their side collision boxes leave a one-metre central opening.
The native wall snap definitions do not provide a dedicated door-insert group.
`spDoorInsert` adds a stable door-specific snap group and two opposing centered
anchors to these completed doorway types and, since 0.19.4, the ten Hypotenuse
doorway types through the mod.
The original GLBs need not be overwritten; existing walls can obtain the type
definition's new anchors after loading.

The insert's origin is one metre above the host origin; its male anchor is at
local (0, -1, 0), with the hinge at (-0.48, -0.96, 0). This retains the same
visible leaf position as the combined doorway. The offset matters: native
placement rejects overlapping objects with identical origins, even when a
recipe permits ordinary object overlap. The insert permits overlap with the
host's whole-wall placement box, while its `disallowAnyCollisionsOnPlacement`
flag rejects another insert occupying the same space. Attachment overlaps the
jambs; selection/collision boxes are inset from both jambs and the floor.

`spDoorWoodInsert.glb` contains only helpers, including native column camera
framing translated to the centered origin, a resource store and worker targets
at floor height on either side. Its one `splitLog_1` placeholder shares the
existing timber leaf and aliases. The bring-only construction sequence avoids
clearing the host or floor. Native refund accounting returns the delivered
split log; the dedicated `sp_doorInsert1x2` Rebuild group preserves its footprint.
Proximity height compensates for the one-metre origin offset.

Native snap tables are copied before augmentation, preserving solid walls,
unfinished hosts and the combined doorway. No native asset is overwritten.
Snapping is placement assistance, not persistent parenting: remove the insert
before replacing its host. Curved doorways need separately measured anchors
and are not included. Hypotenuse doorways use the existing centered anchors.
Visual fit across material variants and
the actual placement solver must still be checked in-game.

## Reproduction and validation

Workspace tools:

- `door-tests/build.py`: regenerate the three assets from the selected installation.
  Read every native input before writing; retain a complete mod snapshot first.
  Finalization uses `model_assets.py`, including lossless complete-attribute
  vertex packing and existing alias/placement metadata maintenance.
- `door-tests/verify.py`: execute native model, recipe and placeholder contracts
  plus the animation lifecycle fixture through the installation's Lua DLL.
  Set `SAPIENS_GAME_DIR` to select Beta or Public. Geometry checks compare all
  ordered triangle attributes before/after lossless packing.
- Run the maintained full regression suite in each supported edition as well.

Offline tests cannot certify live engine rendering, path execution or multiplayer.
Playtest existing saved combined walls and the separate insert:

1. Confirm the combined prototype is absent from Build and Rebuild. Inspect the
   separate door's menu/placement preview; copying an old wall selects the native doorway.
2. Build with different wood species; check native delivery and leaf material.
3. Route Sapiens through from both sides, including a group, at normal and fast speed.
4. Keep a Sapien in the passage and verify it stays open; test pause/resume.
5. Save/reload near an occupied doorway; move far away and return to test streaming.
6. Rebuild into/from a native wall and dismantle; verify material recovery.
7. Test the same scenarios independently in Public and Beta; report edition.
8. Snap the insert into all five completed native doorway families, including
   existing saved walls and both facing directions. Check icon, ground clearance,
   delivery from either side, duplicate rejection and upper-floor exclusion.
9. Dismantle the insert, check its refund, then replace the host. Confirm the
   original combined doorway has no extra insert snap point.
