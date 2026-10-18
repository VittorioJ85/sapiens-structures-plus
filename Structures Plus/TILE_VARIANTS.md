# Tile color variants

Author: Vittorio. Added in Structures Plus 0.17.0; binder selection corrected in 0.17.1.

## Registration and compatibility

`common/spTileVariants.lua` owns the three palettes and all stage transitions.
Small lifecycle hooks extend the native model, object, recipe, evolution and
placeholder registries. Resource categories remain `mudTileWet`, `mudTileDry`
and `firedTile`, so native material filters, storage and construction refunds
continue to use the actual supplied resource objects.

Stable object identifiers are `spTileWet_<palette>`, `spTileDry_<palette>` and
`spTileFired_<palette>`, where palette is `sand`, `riverSand` or `redSand`.
The wet identifiers also retain the three legacy pottery recipe IDs. Native UI
uses the existing `mudTileWet` recipe with the Binder filter. Do not
rename these identifiers after release. No world migration is performed.

The native tile recipe retains its clay requirement, research gates, skills,
quantities and work sequence. It additionally copies the native Mud Brick binder
requirement, including count and actions, and uses its two-input in-progress
model. Hay selects the original tile; the three sands select their color. Legacy
recipe IDs use the same requirements and output routing to preserve saved orders.
Firing stays in the existing native recipe and selects the matching
color from the delivered dry tile. Public's implicit one-object output is
converted into an equivalent explicit array; Beta's explicit array length is
retained. Existing provider mappings are retained. Providers that replace the
same recipe after this hook may need a compatibility adapter.

Drying rules are inserted before native placed-resource evolution and reverse
lookup tables are derived. There is no custom drying timer or per-frame loop.
The supplied game-object instance is used during registration, avoiding circular
module initialization.

## Shared assets

The existing native tile geometry is remapped to `mudBrickWet_<palette>`,
`mudBrickDry_<palette>` and `firedBrick_<palette>`. Native colors and material
properties are reused; no texture or model file is generated. Native tile section
and path selectors gain the new fired object indices before placeholder models
are initialized. Explicit resource bindings in `spMaterialCompatibility` extend
Structures Plus generated geometry and preserve composed material mappings and
LODs. Never duplicate a GLB just to change one of these colors.

The original clay palette remains untouched and is not asserted to be identical
to the hay-brick palette. The selected sand or hay is consumed as the extra
binder ingredient.

## Verification

Run `audits/tile-variants/test.py` from the project workspace, using
`SAPIENS_GAME_DIR` to select either installed edition. Also run the maintained
regression suite and compare native model registries before packaging.

In a test world, select each of the four binders in the existing Unfired Tile
recipe, observe loose and placed tiles drying,
fire each separately using the existing kiln recipe's input filter, then build
a native tile floor/roof/path and a Structures Plus triangle/curve from each.
Check close/distant rendering, mixed-resource construction, dismantling,
Rebuild and save/reload. These live checks are separate from the offline tests.
