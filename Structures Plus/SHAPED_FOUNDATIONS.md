# Shaped foundations

Author: Vittorio. Introduced in version 0.20.0.

The foundation submenus now include 45-degree triangles, right isosceles
triangles and quarter circles, each matching the existing 2 m and 4 m floors.
Each footprint is available in Wood, Dirt, Mud Brick, Stone Block and Fired
Brick: 30 additional buildables. A triangle's size describes its equal sides;
a quarter circle's size describes its radius. All extend 2 m below the top
connection plane. Raised decks still need an accessible approach or ramp.

Upper and lower connectors reuse the matching floor's wall and edge anchors.
Native vertical foundation anchors support stacking. Existing objects and
their saved identifiers remain unchanged. Rebuild switches materials only
within the same footprint, size and depth.

Native construction inventory controls resource selection, delivery and refunds.
Dirt accepts the existing soil/sand resource group. The 4 m Dirt footprints
support crops and at most one tree, including queued planting orders. Harvests
deplete Rich Soil to Soil to Poor Soil; dismantling returns the remaining fill.
Plants must lie inside the actual footprint, not its rectangular bounding box.
Remove plants before dismantling. Sand retains the existing poor fertility
behavior. All parts retain `preventGrassAndSnow = false`.

## Maintenance

`shaped-foundation-tests/build.py` is the reproducible generator. It reads all
native input geometry before writing output. Never run the historical foundation
generators as batch scripts. A complete source snapshot is required before
regeneration. Run the shared asset finalizer after generation; the generator
does this automatically, including lossless vertex packing.

The runtime configuration is `common/spShapedFoundations.lua`. Shared behavior
lives in `common/spShapedFoundationUtils.lua`. Material discovery runs after
provider hooks and uses the existing compatibility adapters. No species creates
a physical GLB. Material mappings compose through the shared alias helper.
No new network endpoints, per-frame callbacks or save migrations are introduced.

There are six shared helper assemblies, 24 masonry/soil meshes with distinct
native atlas coordinates, and twelve wood resource meshes. Identical assemblies
are shared across all five materials and both detail names; genuinely different
UVs and timber geometry remain separate. Total: 42 additional physical GLBs.
The native atlas is tiled within bounded panels, including along curved edges.
Timber shells use native wall and inverted floor components.

Sapiens' exposed collision helpers are boxes. Inscribed strips approximate the
curved and diagonal boundaries without an invisible rectangular obstruction.
The visible quarter-circle edge has 32 segments. Top storage helpers and
distributed walk nodes support approaches from several sides. These geometry
checks cannot prove the behavior of the engine's pathfinder.

## Verification

Since 0.24.0, each footprint/size has a centered stack connector at its top and
bottom. These keyed groups match across material families while preventing
different shapes or sizes from aligning by accident. Native stacking connectors
use horizontal normals; filtering native points by vertical normals is invalid.
The new groups are appended after all existing groups to preserve saved indexes.
Stacking translates the next top plane by the configured depth (2 m).

Run `shaped-foundation-tests/verify.py` for footprint, finite attributes,
nondegenerate geometry, native model/placeholder registration, LOD fallback,
native recipe cloning, material aliases, upper/lower snapping, Rebuild and soil
containment. Run it with both supported `SAPIENS_GAME_DIR` values. The maintained
`foundation-access/check.py` includes this test and the existing regressions.
`shaped-foundation-tests/preview.py` renders a schematic offline geometry sheet;
it does not reproduce native textures or an in-game build-menu preview.

In-engine validation should cover both sizes, all material families, adjoining
floors, stacking, wall placement, resource delivery, build/dismantle, Rebuild,
planting and save/reload. Offline checks are not an in-engine test.
