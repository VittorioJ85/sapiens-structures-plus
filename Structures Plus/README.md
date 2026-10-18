# Structures Plus

**Version 0.17.2 - by Vittorio**

Structures Plus expands building with triangular and curved floors, matching
walls and openings, foundations, ramps, columns, plantable dirt foundations and
Water Blocks. Structural parts use original game materials and snap connections.

## Construction access correction (0.17.2)

Terrain-clearing prerequisites strictly inside a completed solid 4x4 foundation
now include its outer boundary strip. Previously a 5 cm inset left a saved tile
floor waiting for inaccessible grass approximately 2 cm inside a Stone Block
Foundation's edge. The check now retains only a 1 mm boundary tolerance. Existing
native cleanup releases the stale construction-clearing suborder on its next
path request, while the build plan and delivered resources remain intact.

Exact edges, exterior terrain, deck vegetation, suspended blocks, unfinished
foundations, wooden shells and manual clearing keep their previous behavior.
Meshes, collision, snap points and save data are not modified. Offline tests
reproduce the saved target coordinates and verify both supported editions;
live pathfinding still needs a playtest after restarting and resuming the world.

## Tile colors and binder selection (0.17.1)

The existing **Unfired Tile** recipe at the Crafting Area now requires **Clay**
and **Binder (Hay or Sand)**, using the native Mud Brick binder requirement.
Select the Binder row under Requires and choose the accepted material:

- Hay produces the original tile appearance.
- Sand, River Sand and Red Sand produce their matching new tile colors.

The actual delivered binder determines the output. Allow wet tiles to dry, then
use the existing Fired Tile recipe at a kiln; the dry tile determines the fired
color. Native tile batch sizes, pottery research, skills and drying conditions
are retained for each edition. The work-in-progress model is the native two-input
Mud Brick crafting model, so both materials have their native delivery slots.

This fixes 0.17.0's separate color recipes not appearing in the Crafting Area.
Those recipe identifiers remain registered for saved-order compatibility and now
use the same binder selection. Existing tile resource IDs and appearances are
unchanged. No GLB or texture files are added or modified.

Offline checks cover both installed editions; live crafting and rendering still
require a playtest. Restart Sapiens after updating. See [TILE_VARIANTS.md](TILE_VARIANTS.md).

## Shared water geometry (0.16.5)

The mod retains all 8,086 authored model names using 2,182 physical GLBs and
5,904 aliases. Version 0.16.5 replaces 64 large water animation models with four
native placements of each existing 2 m water tile. All tiles share one wave phase;
complete surface geometry, materials, water height and swimming remain unchanged.
Construction resources, snapping, collision and preview cameras are preserved.

The lossless vertex packing and compact JSON from 0.16.3 remain in place.
This update saves approximately 6.04 MiB of GLB data. It does not simplify
geometry or reduce texture quality. Four native tile updates replace one large
model update; file savings do not imply improved frame rate.

Geometry requiring stretching/shearing remains separate. The Beta success
reported for 0.16.1 does not certify this newer release. Offline geometry and
native-loader checks cover both installed game editions; live rendering,
construction, demolition/Rebuild and save/reload still need in-game validation.
See [MODEL_ASSETS.md](MODEL_ASSETS.md) for the authoring workflow. Close Sapiens
before updating and restart afterward. Keep only one Structures Plus installation
enabled in each world.

## Maintenance audit (0.15.2)

Explicit material adapters now retain their resource-object bindings when the same model variant was already discovered automatically. Conventional resource names remain supported, including on triangular floors. Generated material aliases also check for detail-model name collisions before cloning, preserving existing models and falling back with a diagnostic for the conflicting variant. Existing part identifiers, meshes, recipes and saved state are unchanged. Offline checks cover both local Public and Beta installations; this is not a claim of live gameplay certification.

The 0.15.1 covered-terrain correction is retained: inaccessible ground beneath completed solid 4x4 foundations no longer blocks dependent construction clearance. Accessible edges, unfinished foundations, wood shells and manually requested terrain clearing keep native behavior. The bundled compatibility support applies only to recognized versions and exact source content of supported external mods; unknown versions are skipped.

## Materials from other mods (0.15.0)

Structures Plus now extends its generated floors, walls, openings, foundations, ramps and columns from compatible providers' native model/material registrations. Additional wood species, stone blocks, mud bricks, fired bricks and tiles can retain their own surfaces on Structures Plus geometry. New soil/sand appearances are also supported on Dirt Foundations. Discovery runs once after native model remaps are loaded, including providers registered later than Structures Plus, and before the engine creates its LOD tables.

The provider must register usable resources in the matching native resource types/groups and supply compatible material remaps. Construction, material filtering and dismantling continue to use the actual resources. An arbitrary new tree or standalone mesh is not enough to infer every building surface. Independent model layouts can use the documented adapter API in [MATERIAL_COMPATIBILITY.md](MATERIAL_COMPATIBILITY.md). Unsupported generated-model mappings use the default surface with a one-time diagnostic instead of crashing.

Foreign sand is treated as very poor growing medium; foreign soil defaults to normal quality. Foreign resource identities are retained on harvest and dismantling. The native Rich Soil -> Soil -> Poor Soil transitions remain unchanged; provider-specific fertility/depletion behavior needs a separate integration.

Offline tests exercise the original game model loader with synthetic providers, existing-model preservation, material selectors, LODs, missing resources and safe fallbacks. Compatibility with a specific third-party mod still requires an in-game test with that mod enabled. Restart Sapiens after updating. Existing part IDs and saved placements are retained.

## Column stacking and Fired Brick dimensions (0.14.2)

Column placement colliders now follow the native column's inset shaft convention. They leave clearance at both ends so the placement solver does not reject touching caps when stacking 1m and 2m columns. Visible geometry, physical collision and attachment surfaces still meet at the original bottom and top snap planes.

Both Fired Brick column heights now have a 0.4 x 0.4m base/top and a 0.2m shaft, matching the nominal footprint of native Mud Brick and Stone Block columns. Wood retains its existing 0.5 x 0.5m base/top, 0.36m shaft, textures and appearance. Part IDs, recipes and saved placement origins are unchanged.

Restart Sapiens to load the updated models, including already built columns. Offline checks cover endpoint registration, placement-collider separation for every column pair in both stacking orders and detail levels, geometry dimensions and unchanged preview framing. Final placement behavior still requires an in-game check.

## Columns and lower foundation connectors (0.14.1)

All flat 4x4 Dirt, Mud Brick, Fired Brick, Stone Block and Wood Foundations now have the native 4m floor connectors at their lower rim as well as their upper rim, including edge and corner connections. The lower connectors use the existing bottom datum (`-depth`); saved placement origins and previous upper connections are retained. Ramps retain their existing slope connections.

**Wood Columns** contains matching 2m and 1m timber columns, using two or one Split Logs respectively and all nine native wood species. Both retain a 0.5 x 0.5m base and top with a narrower shaft. Wood grain uses a continuous cut-face patch from the original Split Log model, oriented along the shaft instead of crossing floor-atlas regions. Construction uses the normal wood-building skill and material-selection interface.

The former capitals are now **1m-high shortened columns**, not wide plates. Mud Brick and Stone Block use the original column models and appear as variants under their native column entries. **Fired Brick Columns** contains matching 2m and 1m variants. There is no separate Column Capitals entry. Short columns cost one corresponding resource and support every native variant of their material family. Their column connectors follow the actual 1m height; normal research, resource delivery and dismantling rules apply.

The 2m Wood and Fired Brick columns join the native column Rebuild group. All four 1m variants share a separate Rebuild group. All mod columns keep `preventGrassAndSnow = false`.

Preview models now retain the native column's front/back framing helpers, TRS camera and UI view offsets, scaled for the short variants. Checking only a glTF camera frustum did not reproduce the in-game menu renderer and missed the previous cropped previews. Regression tests now also check those native framing inputs, native menu finalization, wood atlas bounds and grain direction.

Restart the game after updating. Saved IDs and origins are retained: previously placed 0.25m capitals become 1m short columns at the same position, so nearby pieces may need repositioning. Existing 4x4 foundations keep their additional lower connectors. Offline checks passed; in-game preview appearance and placement still require a playtest.

## Sand foundations (0.13.0)

Dirt Foundations 1x1, 2x2 and 4x4, and the Dirt Ramp Foundation now accept **Sand, River Sand and Red Sand**, alongside Rich Soil, Soil and Poor Soil. Choose the desired resource in the normal building material selection under **Soil or Sand**. Costs and part IDs are unchanged. Existing soil foundations keep their materials; use Rebuild to change them.

All three sand surfaces reuse the game's original material definitions on the existing foundation geometry, including distant models. Dismantling returns the actual construction resources. Soil still degrades from Rich Soil to Soil to Poor Soil through harvesting. Sand remains sand and gives a plantable 4x4 foundation the game's `veryPoor` soil quality; mixed fill uses its poorest constituent. The one-tree limit and plant-removal requirement still apply.

Restart Sapiens after installing. The optional Custom Shapes Prototype has a compatibility update for the sand recipes it inherits when both mods are enabled. Water Block recipes remain unchanged.

Implementation: `common/spFoundationFill.lua` owns the four-part allowlist, recipe conversion, material aliases and placeholder routing. `common/resource.lua` registers a persistent resource group without modifying global dirt/sand resources. Apply recipe conversion after cloning other parts; install placeholder selectors after generated geometry remapping to avoid sending new sand models through soil-only lookup tables. No world migration, external code, dynamic file access or per-frame polling is introduced.

Offline checks cover native resource matching, material selection at all detail levels, construction slots, sand retention through harvest and native dismantling, existing soil behavior, access, Rebuild and Water Blocks. In-game visual appearance and worker behavior require a playtest.

## Access to adjoining foundations (0.12.2)

Flat 4x4 Dirt, Mud Brick, Fired Brick, Stone Block and Wood Foundations now use the original game's construction-stage walkability and obstacle rules. Material staging points are on each foundation's own top surface, instead of outside its corner and below its deck where an adjoining foundation could enclose them. Both model detail levels are updated; shapes, snapping, recipes, resource refunds and saved object IDs are unchanged.

Restart the game to reload the corrected definitions for existing and new construction sites. Elevated foundations still need a reachable approach, such as a ramp: this change does not enable climbing vertical walls. Offline checks cover a 3x3 arrangement, rotations, native physics-group membership and the existing soil/Rebuild systems. Actual worker routes and delivery in a running world still need verification.

## Foundation alignment and preview (0.12.1)

Ramps and large foundations now use the original game's visible foundation surface height. Closed edge profiles remove the recessed joins on the 4x4 earth and masonry foundations. Ramp endpoints remain exactly 1 m apart in height. Collision surfaces and walk nodes follow the corrected top surfaces. Wood foundations retain their original wall exteriors and inverted floor caps; their smaller sizes share the corrected datum.

Existing part IDs, material choices, recipes and snap origins are unchanged. Existing objects receive the corrected models after a full game restart. Objects previously moved by hand to compensate for the old height difference may need repositioning. Native wood and mud-brick surfaces retain their intentional irregular texture/geometry.

The mod now includes an **S+** preview, configured through `modInfo.lua`: a square 1024x1024 JPEG below 1 MB, suitable for the in-game mod list and Steam Workshop. It is cover artwork rather than an in-game screenshot. Uploading or updating the Workshop listing is a separate in-game action.

## Rebuild support (0.12.0)

All 137 parts now have native Rebuild groups, including unfinished construction. Select a part and use Rebuild to choose a compatible replacement or change its selected building materials. Groups preserve the footprint, shape and height; full-height walls, doorways and windows of the same geometry share a group, while shortwalls remain separate. Matching straight windows and small wooden foundations also join the corresponding native groups.

Water Blocks can be rebuilt at their existing size. Remove plants and queued planting orders before rebuilding a planted dirt foundation. Normal research, resources, tools and construction/deconstruction rules still apply. Existing object IDs are retained. See [REBUILD.md](REBUILD.md) for compatibility details.

## Original water color (0.11.3)

Both Water Block sizes now use the game's original water color, as in the first pool prototype. The existing material key is retained for model compatibility. Waves, swimming, surface roughness and menu organization remain unchanged; the native water material itself is not modified.

## Build-menu organization (0.11.2)

The dedicated **Water Blocks** entry uses Water Block 2x2 as its preview and offers the 2x2 and 4x4 variants. The dedicated **Wood Foundations** entry uses Wood Foundation 2x2 as its preview and offers 2x2, 1x1, 4x4 and the wood ramp. These parts are removed from their previous foundation/floor variant lists. In the Stone Block Foundation group, Foundation 4x4 now comes before Ramp Foundation 4x4. Saved part keys, construction costs, materials, snapping and water behavior are unchanged.

## Stone foundation completion (0.11.1)

Stone Block Foundation 4x4 is available under Stone Block Foundation 2x2 variants. It has a 4x4 m footprint and 2 m depth, matching the other large foundations. All original stone material choices, research requirements and construction behavior are retained. It requires 16 Stone Blocks, four times the original 2x2 foundation resources and provides foundation/floor snap points. Like every part in this mod, it uses `preventGrassAndSnow = false`.

## Integrated pools (0.11.0)

Water Block 2x2 and Water Block 4x4 are now part of Structures Plus. Both are 2 m deep, with the original native water color, gentle waves, local swimming and snap points. Find them under Water Blocks after the normal digging research. They cost two and eight Dirt respectively. Existing pool object identifiers and models are retained, including unfinished pools.

Do not enable the old standalone Pool Prototype alongside this release. The workspace migration installer backs up Structures Plus and affected world settings, replaces the old pool entry in world mod lists, and archives the standalone mod outside the active mods directory. Worlds already using both mods retain their Structures Plus entry and the order of other mods. No object database is rewritten.

For manual installation, install this release as `Structures Plus` and replace Pool Prototype with Structures Plus in each affected world's mod settings before loading that world. Keep only one Structures Plus copy enabled. See [POOLS.md](POOLS.md) for pool placement, swimming and limitations.

## Maintenance update 0.10.1

Part registrations share one ordered family catalog and common registration helpers. Native material callbacks are preserved through one model-remapping implementation. All part IDs, model names, resources, snap coordinates and menu order are retained.

Planting and replanting now share server checks for foundation ownership, pending dismantling/rebuild orders, exposed soil and the single-tree limit. Stale plant bindings cannot deplete unrelated foundations. Non-finite fertility values are rejected or reset, and soil degradation has bounded work. These changes do not add building variants.

See [DEVELOPMENT.md](DEVELOPMENT.md) for runtime architecture and maintenance, and [SECURITY.md](SECURITY.md) for review scope and findings.

## Plantable Dirt Foundation 4x4 (0.10.0)

Use the normal planting menu to plant any native plantable species on the exposed top of a completed 4x4 Dirt Foundation, including elevated foundations. Seeds, tools, skills and research requirements remain those of the game. Each foundation allows one tree, counting queued planting orders and saplings; smaller plants use normal collision spacing. Chop-and-replant retains the same tree slot.

The soil used for construction determines growth quality. Mixed soil uses its poorest constituent. Harvesting applies the game's normal fractional fertility costs, threshold of 20 and deterministic initial offset. Each depletion step changes Rich Soil to Soil and Soil to Poor Soil; Poor Soil remains Poor Soil. Soil quality and partial depletion are saved per foundation. The terrain below is unaffected. Native growth and fruit behavior use this local quality.

Dismantling returns the original quantity of soil at its current depleted quality. Remove plants and planting orders before dismantling or rebuilding a planted foundation. Existing 4x4 dirt foundations are supported without replacing them. Dirt ramps and other foundation sizes remain unchanged.

## Included parts

- 45-degree floor wedges with 2 m and 4 m sides, plus walls and shortwalls for their short edge.
- Right-isosceles floor triangles with 2 m and 4 m legs and connectors on all three edges.
- Hypotenuse walls, doorways, small-window walls and 1 m shortwalls for both right-triangle sizes: 2.828 m and 5.657 m wide.
- Quarter-circle floors and curved walls, shortwalls, doorways and window walls for both radii. The 4 m curved window walls have two separate windows.
- Straight 4x2 walls with centered, smaller window openings.
- Dirt, Mud Brick, Brick and Stone Block foundations with a 4x4 m footprint and 2 m depth.
- Wood foundations with 1x1, 2x2 and 4x4 m footprints. The 1x1 foundation is 1 m deep; the others are 2 m deep.
- Wood, Mud Brick, Dirt, Brick and Stone Block ramp foundations: 4x4 m footprint, rising from 0 to 1 m over 4 m of horizontal length.
- Pool water with 2x2 and 4x4 m footprints, both 2 m deep, with animated waves and local swimming.

The mod contains 137 building variants. Floors support Split Log, Mud Brick and Tile. Walls support Thatch, Split Log, Mud Brick, Stone Block and Brick. Foundations and ramps retain the material subtypes available through their original resource selectors, including wood species and dirt/brick subtypes. Water Blocks use a dedicated material with the native water color.

## Foundation appearance update (0.9.1)

Dirt, Mud Brick and Brick ramps now retain their own visible materials. An internal native shadow-volume mesh was previously baked as a visible stone surface. That mesh is excluded from all newly generated foundation geometry. A Stone Block Ramp Foundation 4x4 is now available in the stone foundation family.

Wood foundations have four native wall exteriors and an inverted floor cap, with the rounded bark side facing upward. The ramp has shortwall exteriors at its high end and along the slope; the side logs remain horizontal and are cut to the incline. Its two high-end corners and side continuations have wall-edge snap connectors for native halfwalls.

Wood species remain selectable separately for Logs and Split Logs. New building costs match the wall-and-deck construction:

| Part | Logs | Split Logs |
| --- | ---: | ---: |
| Wood Foundation 1x1 | 4 | 5 |
| Wood Foundation 2x2 | 8 | 15 |
| Wood Foundation 4x4 | 8 | 36 |
| Wood Ramp Foundation 4x4 | 2 | 18 |

Existing object identifiers are retained. Completed older wood foundations can display default supports where their saved resource list contains no Logs. Select the desired Log and Split Log types when building a new part. 

## Added in 0.9.0

Ten hypotenuse shortwalls use the native 1 m wall height and its natural material overhangs. Their lower connectors match the triangle size; side and upper connectors support neighboring and stacked walls.

Six foundation variants and five ramps use the native construction resources and research restrictions. Quantities scale with size. Wood foundations use native wooden wall exteriors and an upside-down split-log floor as the top cap. The wood ramp has a normal floor deck and horizontal shortwall panels cut to the slope. Ramps have a sloping collision surface and walk nodes, with level connections at the 0 m and 1 m ends. They can rotate horizontally, but cannot tilt. Their slope is approximately 14.04 degrees.

Flat foundations extend downward from the placement origin. Ramps start at the origin's height and rise to 1 m above it. Use vertical placement adjustment when joining them. Normal foundations retain terrain clearance during construction; ramps do not excavate terrain automatically.

## Finding the parts

- Hypotenuse shortwalls: the corresponding original wall family's variants, named "Hypotenuse Shortwall" and the matching width.
- Dirt, Mud Brick and Brick foundations and ramps: the corresponding Foundation 2x2 variants.
- Stone Block Foundation 4x4 and ramp: the Stone Block Foundation 2x2 variants, including granite, marble, limestone and the other native stone subtypes.
- Wood foundations and the wood ramp: the dedicated "Wood Foundations" entry, using the 2x2 foundation preview.
- Water blocks: the dedicated "Water Blocks" entry, using the 2x2 water block preview.

Restart Sapiens completely after updating. Check version 0.16.4 in the world's mod settings and update it if offered. The installed folder is `Structures Plus`; do not install a duplicate under the old `SplitLogFloor45` name. Existing object identifiers are preserved.

All parts, including pools, use `preventGrassAndSnow = false`. Terrain, weather and other buildings still affect grass and snow.

## Validation and backup

Offline checks use the game's Lua 5.1 runtime: script syntax, material mappings and mesh indices, model dimensions and normals, ramp collision planes and walk nodes, snap coordinates, construction states, costs/research inheritance, menu registration and the grass/snow setting. All 137 parts register without the standalone pool mod. Pool tests cover both sizes, all 128 wave frames, swimming boundaries, world reload state and the previous swimming-cache crash.

These checks do not replace testing in the running game. Check world loading, existing and new pools, swimming, menu previews, planting, construction, ramp traversal, snapping and save/reload after updating. Registration snapshots compare the merged mod with the original Structures Plus baseline plus standalone Pool Prototype; historical pool labels and menu layout are normalized for that comparison. A separate check exercises the current menu groups and previews through native finalize/build UI functions.

The migration creates `backups/StructuresPlus-pool-merge-<timestamp>` in the workspace. For rollback with Sapiens closed, replace the merged installed folder with the saved `Structures Plus` folder, restore the archived `PoolPrototype` folder to `mods`, and restore the backed-up world `config.lua` files to their matching player/world paths. Restore all three together; do not leave both pool implementations active.
