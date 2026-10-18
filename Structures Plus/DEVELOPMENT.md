# Structures Plus maintenance

Author: Vittorio. Runtime: Sapiens 0.7.0.2, Lua 5.1. User-facing mod text is English.

## Source and installed layout

The authoring directory is `Structures Plus`, matching the installed mod folder. Local build, test and packaging tools use this source path. Install it as `Structures Plus` in the Sapiens mods directory. Do not enable a second copy under the old name. Pools are integrated from version 0.11.0; do not load the legacy standalone Pool Prototype as well. Its workspace source remains a historical comparison fixture and is not deployed.

## Runtime architecture

Version 0.16.0 consolidates identical GLB geometry through stable model aliases.
Version 0.16.1 adds static resource-node translations; 0.16.2 also supports
proper rotations, per-logical-model constraints and exact shadow-node preservation.
Version 0.16.3 adds deterministic exact-attribute vertex sharing and compact JSON
serialization at build time. This preserves triangle data and does not add a
runtime dependency. Generators must read indexed geometry correctly; array
length and array order alone do not describe triangle topology. The finalizer
updates authoring normalization hashes whenever storage bytes change.
Generators must read existing assets with `read_authoring_model` and finish with
`model_assets.consolidate(..., apply=True)`; runtime-space reads are for explicit
assembly geometry tests. Never assume every resource node remains at the origin.
See `MODEL_ASSETS.md` before adding, editing, enumerating or regenerating models.
The JSON/Lua manifests and physical GLBs form one release and must stay in sync.

The native-source and fixture audit for 0.15.2 used both local installations, `Sapiens` (Beta) and `Sapiens_NICHT_BETA` (user-designated Public). Results apply to those installed files; they do not certify every historical Public release. Test tooling uses local Windows paths and the game's Lua DLL. No additional runtime dependencies are introduced.

| Module | Responsibility |
| --- | --- |
| `common/spBuildMenu.lua`, `mainThread/ui/manageUI/buildUI.lua` | Menu grouping, variant order and native main-list extension |
| `common/spRebuild.lua` | Geometry-based Rebuild group keys and native persistent group registration |
| `common/spParts.lua` | Ordered catalog of eight part families and their data modules |
| `common/spColumns.lua`, `common/spColumnUtils.lua`, `common/spColumnMaterials.lua` | Full/short column dimensions, native connectors, recipes and resource-to-surface mappings |
| `common/spPartRegistration.lua` | Names, recipes, material costs, previews, and family-specific snap dispatch |
| `common/buildable.lua`, `common/gameObject.lua` | Native registration entry points; one expansion per native object batch |
| `common/spModelRegistration.lua` | Shared native material remapping, wooden foundation resource slots and pool content slots |
| `common/modelPlaceholder.lua` | Triangle selectors and native model initialization lifecycle |
| `common/snapGroups/snapGroup.lua` | Ordered custom snap-type registration and floor anchors |
| `common/sl*Utils.lua` | Geometry-specific transformations; no object registry imports during module load |
| `common/spValidation.lua` | Pure finite-number and position checks, including native LuaJIT vectors |
| `common/spSoil.lua` | Soil types and geometric containment |
| `server/spSoilServer.lua` | Foundation lookup, plant occupancy, server authorization and fertility persistence |
| `server/planManager.lua`, `server/serverGOM.lua`, `server/objects/serverFlora.lua` | Narrow native callbacks for planting, harvest, removal, growth and pool movement |
| `mainThread/ui/buildModeInteractUI.lua` | Planting preview adaptation; not an authority boundary |
| `common/planHelper.lua` | Explain why occupied foundations cannot be dismantled or rebuilt |
| `common/slpoolParts.lua`, `common/slpoolSnap.lua` | Pool family data and 4 m snap composition using shared helpers |
| `common/material.lua`, `common/slpoolWater.lua` | Pool material and local water height/containment calculations |
| `common/worldHelper.lua` | Pool-aware navigation target adjustment |
| `logicThread/clientSapienAnimation.lua` | Native swimming animation integration and paired cache invalidation |
| `logicThread/clientGOM.lua`, `logicThread/clientBuiltObject.lua`, `logicThread/slpoolSurface.lua` | Shared wave clock, built-object callbacks and render-cache lifecycle |
| `server/spCoveredTerrain.lua`, `server/serverTerrain.lua`, `server/serverSapien.lua` | Narrow suppression of inaccessible terrain-clearance work below completed solid foundations |
| `common/modManager.lua`, `hammerstone/ddapi/ddapiManager.lua`, `vittorioCompatibility/v1/*` | Shared, exact-source guarded compatibility support for recognized external mods |

The `sl*Models.lua`, `slFoundationWood.lua` and part-config tables are generated data. Do not duplicate runtime behavior in these tables. `common/model.lua` supplies required native material aliases. GLB files, model aliases, native callbacks and config entries must not be removed merely because a text search finds no literal caller: the game resolves many of them dynamically.

Columns are generated by `column-tests/build.py`, which writes only the `spc_*` GLBs and bundled material table. It reuses native atlas patches and the maintained native-material export at build time; Custom Shapes is not a runtime dependency. `column-tests/verify.py` checks the native registration and lower foundation connectors; `column-tests/preview.py` checks camera framing and produces a schematic contact sheet. Content meshes are static, with no per-frame geometry rebuilding. Keep the column family's resource slots and aliases aligned: delivery, material previews and native dismantling all use these names.

Column `placeCollide` helpers must be inset from both end planes, as in the native column GLB (80% of shaft width and height). `buildModeInteractUI` runs a placement collision test on snap candidates and may reject caps whose full-height colliders touch. Keep full-size `static` and `placeAttach` helpers separate from the inset placement helper; moving snap points to compensate would create visible gaps. Fired Brick uses a nominal 0.4m cap and 0.2m shaft, while Wood keeps its 0.5m cap and 0.36m shaft. Regression checks cover both stacking orders and both detail levels; they do not emulate the engine's full physics solver.

## Initialization and compatibility invariants

`common/spMaterialCompatibility.lua` prepares foreign material variants after the native `model:loadRemaps` and before `loadLODs`. Keep discovery out of frame callbacks, retain deterministic registration order, and compose remaps when cloning an existing alias (the native loader replaces rather than composes `materialRemap`). Generated asset tables are extended in memory only. See `MATERIAL_COMPATIBILITY.md` for provider contracts and the adapter API; `material-compat-tests/verify.py` exercises the original native model loader with synthetic providers and confirms existing indexes/materials are preserved.

Resource binding must run even when a generated model alias already exists: automatic discovery may precede an explicit adapter for that same variant. Triangle mappings retain a set of object keys per variant so an explicit key cannot displace its conventional resource key. Keep binding limited to newly generated aliases to preserve shipped native selectors.

Column selectors must tolerate foreign aliases rejected by collision checks. Require the full alias before binding either detail level, and use optional index lookup for the detail alias; the existing default callback then handles the missing variant without aborting world initialization.

Covered-terrain behavior has a separate regression fixture: `python lua_runner.py pathfinding-diagnosis/test_clearance.lua`. Embedded support is tested by `python embedded-compatibility/test_matrix.py`, including standalone providers, all provider combinations and coexistence with the legacy compatibility mod. These checks supplement `python foundation-access/check.py`; the audit runner under `audits/structures-plus-20261014` records results separately for Public and Beta. Compatibility support is generated/shared with other authored mods: update its source tooling and rerun that matrix before changing the bundled copies.

- Keep all part keys, model names and custom snap-type insertion order stable. Preserve native resource selectors, research requirements and menu order.
- `gameObject:mjInit` calls `modelPlaceholder:init(gameObject)` before the mod manager caches gameObject. Capture that argument; never require gameObject again during that callback. This previously caused recursive world loading.
- Chain each native method once and retain its arguments and return value. Family-specific helpers must not register another wrapper.
- Generate both final and `build_` object types. All mod parts keep `preventGrassAndSnow = false`.
- Preview offset callbacks and physics flags are runtime entry points even if no Lua file calls them directly.
- Regular foundation origins are on their top surface, with depth below Y=0. Ramp height is `(Z+2)/4` metres across a 4 m span. Preserve native planet-unit conversions at API boundaries.
- `worldHelper` also loads during flora/gameObject initialization. Pool helpers must resolve gameObject lazily during runtime queries, after a GOM exists, rather than at module load.

## Pool lifecycle

Pool definitions use the same ordered catalog, buildable/game-object hooks and placeholder registration as other structures. Their old `slpool_`/`slpool4_` keys and all 134 logical model assets are preserved; identical GLBs may now be shared through aliases. Do not reintroduce the standalone pool registration wrappers or its duplicate copy helper.

`slpoolWater` is the shared height model. The server uses mean height to keep navigation stable; the client uses the discretized wave phase that matches the rendered meshes. Do not change the wave formula without regenerating and checking both sets of 64 frame meshes. This system is kinematic, not a fluid solver; see `POOLS.md` for gameplay limits.

Client surface caches reset when built-object handling initializes for a world. Missing objects are removed from the tracked set and a missing submodel transform is retried on a later frame. Pool exit invalidates both native obstacle-avoidance position caches together. Clearing only one previously caused a native animation crash.

## Soil state and authority

`sharedState.constructionObjects` is the source of truth for remaining soil resources. `spSoilFertilityOffset` stores partial depletion and `spSoilPlantCount` supplies the dismantle tooltip. Native dismantling consumes the updated construction inventory, so no separate refund table is needed. The saved private `spSoilFoundationID` is only a lookup hint and must still match the plant position.

Both planting entry points call `canPlant`: foundation ownership, pending demolition/rebuild, one tree including queued orders, and a server physics ray against the exposed foundation. Native skills, resources, research and order execution remain native. Other plants use ordinary collision spacing. Main-thread preview acceptance alone never authorizes a foundation planting order.

Harvest offsets use the native threshold and deterministic initial offset. Rich Soil becomes Soil, then Poor Soil. Mixed construction uses its poorest constituent for growth. Degradation is capped at two transitions per update and preserves item count and other saved item fields. Invalid numerical inputs must not enter a loop or contaminate saved state.

## Verification

For surface alignment also run `python foundation-alignment/verify.py`. It reads
the installed game's native foundation mesh as an independent height reference
and checks boundary planes, both ramp ends, all resource variants and collision
tops at both detail levels.

Run these from the workspace with the bundled Python runtime and installed Sapiens Lua DLL:

```text
python foundation-tests/verify.py
python foundation-tests/verify_integration.py
python foundation-tests/verify_soil.py
python pool-tests/verify_pool.py
python maintenance-tests/verify_refactor.py
python menu-update/verify.py
python rebuild-update/verify.py
```

The first checks geometry, materials, resources, foundation callbacks and snaps. The second registers all 137 parts without standalone Pool Prototype. The third tests planting, persistence, server guards, numeric corruption, collision isolation and the actual native deconstruction function. The fourth checks both pool sizes, all 128 wave meshes, movement/animation hooks, cache reset and the native swimming-crash regression. The fifth compares full registration snapshots and material callbacks with the frozen 0.10.0 fixture plus standalone Pool Prototype. It normalizes historical water labels and keeps the old menu/Rebuild policy for comparing unchanged behavior. The sixth executes native variation finalization and build-menu functions, checking dedicated entries, 2x2 preview objects, ordering, third-party preservation, filtered lists and receiver-free calls. The seventh checks all Rebuild memberships, native type-map registration, target lists, saved/unfinished objects, queued-order and planted-soil guards, and the native transition from deconstruction to a replacement build plan.

Baselines in `maintenance-tests/baseline`, `pool-merge/baseline` and the old `PoolPrototype` source are retained as fixtures and are never installed. Snapshot files are test outputs. These are offline checks; verify world loading, existing/new pools, swimming, menu previews, planting/replanting, harvesting, demolition and save/reload in the running game before describing a release as playtested.

## Generated assets and historical tools

Earlier scripts in `foundation-tests`, `wall-window-tests`, `right-triangle-tests` and `hypotenuse-wall-tests` mixed geometry generation with string-based patches to runtime hooks. Those direct writer entry points are retired and fail before writing. Pure geometry helpers remain because current mesh tests use them. Historical release-specific tests that extract old comment-delimited hook blocks are superseded by the seven maintained checks above. Older scripts in `pool-tests` generate the standalone prototype; do not use them to overwrite the merged runtime or reinstall the legacy mod.

For future asset work, use a separate staging directory and port the required geometry function into a data-only generator. Validate generated GLBs and config tables, then copy only those artifacts. Do not append Lua hook strings or regenerate metadata/docs from historical release templates. No model files are deleted in this maintenance release: indirect model references and saved-world compatibility require a dedicated asset audit.

For this merge, run `python pool-merge/prepare.py`, then `pool-merge/install.ps1` with Sapiens closed. Preparation stages only enabled-mod-list edits, validates their Lua semantics, and records source, installed and staged hashes. Installation rejects stale files, backs up Structures Plus and affected configs, copies verified changed files, updates those mod lists, and moves standalone Pool Prototype outside the active mods folder. Failure triggers restoration of changed files and configs. The original pool directory itself becomes part of the backup. Object/save databases are not edited.

Migration checks: `python pool-merge/verify.py` covers list changes, unchanged settings, duplicate/ambiguous input rejection, pool asset hashes and metadata. Run `pool-merge/verify_install.ps1` in PowerShell to exercise the actual installer with isolated workspace fixtures, including a failure after pool archival that must restore both mods and the world config. Neither test writes to the live game directories.

For later updates after migration, `wall-window-tests/install_windows.ps1` remains the ordinary installer. It backs up the existing installation, copies changed files and verifies their hashes. It does not migrate world mod lists or retire the standalone Pool Prototype and must not replace the merge installer for the initial transition.

## Stone foundation addition (0.11.1)

`spf_stone_4` appends the missing flat stone foundation to the existing foundation catalog. It uses the common registration, material remapping and snapping paths without new runtime wrappers. `stone-foundation-update/generate.py` stages only this part's native visible geometry and updates generated foundation data; legacy runtime-writing entry points remain disabled. The historical snapshot comparison excludes this new key and its assets, while the foundation and integration suites test the full current catalog.

## Build-menu layout (0.11.2)

Keep `cfg.group` as the original registration destination. Once all part types exist, `spBuildMenu.configure` removes only the explicitly listed Water Block and Wood Foundation members from native lists and assigns them to real 2x2 base parts. Native `constructable:finalize` then establishes variation ownership. Do not introduce synthetic recipes or change saved IDs just to add menu headings.

The native main menu is an explicit list. The buildUI hook chains `createItemList` and inserts the two base types near Dirt Foundations. Their native in-progress objects supply the desired 2x2 previews. Both dot and colon calls are supported because Hammerstone can invoke its predecessor without a receiver. Lists without the native dirt-foundation anchor, such as Blueprint-only views, are left unchanged. Repeated list creation must not duplicate entries. The stone variant swap changes only the two requested positions, preserving registration order and unrelated variants.

## Rebuild groups (0.12.0)

`spPartRegistration` assigns `rebuildGroupIndex` through `spRebuild.indexFor`. Custom keys are registered through native `typeMaps:insert` in `constructableRebuildGroups` and reused on repeated lookup. Do not use array positions or runtime-only counters as saved group IDs. Keep these group keys stable. Missing native groups fail explicitly rather than silently creating incompatible replacements.

Compatibility is geometry-based and independent of menu groups or material families. Standard straight windows use `wall4x2`; 1x1 and 2x2 wooden foundations use native foundation groups. All other shapes have namespaced groups separated by size and height. Water Blocks have separate groups per size. Native finalization builds `typesByRebuildGroup`, so no Rebuild-panel patch is needed.

The native Rebuild queue and construction pipeline handle resources, tools, research, deconstruction and object replacement. The soil plan-helper hook supplies the same occupied-foundation reason for both removal and Rebuild, matching the existing server guard. Preserve that guard when adding further foundation types.

## Surface datum (0.12.1)

`foundation-alignment/build.py` is the maintained alignment generator. It reads
native visible resource meshes and the existing resource maps, closes the native
bevel at the new join planes, and measures the original visible foundation lip
(currently 0.04383695125579834 m above the logical snap plane). Models retain their
existing names, resource selectors and material variants. Normals and accessor
bounds are recalculated; internal shadow nodes are excluded. Real native resource
names ending in `_low` must be rebuilt too, not mistaken for generated aliases.

The ramp surface is `(z+2)/4 + lip`; the flat surface is `lip`. Collision tops and
walk nodes follow these surfaces, while logical connectors stay at 0/1 m, just
like the native snap convention. Masonry ramps have a closed thin toe instead of
translating a zero-thickness tip into the air. Wood keeps its native textured wall
and inverted deck geometry, with matching datum correction and small toe faces.
Uneven bark surfaces intentionally retain their profile.

The generator freezes and hashes its version-0.12.0 model inputs in
`foundation-alignment/baseline` before its first run and validates them thereafter.
This prevents cumulative offsets and preserves the original wood geometry.
Never run a historical generator afterward: it would restore the previous datum.
Geometry helpers load only local trusted helper definitions, not legacy entry
points. No extra runtime callbacks are needed for this correction.

`preview.jpg` is a 1024x1024 JPEG below 1 MB, referenced by the native `preview`
metadata field. Its source image and English generation prompt are retained in
`deliverables/structures-plus-preview` outside the installed mod. Publication is
not performed by the installer.

## Adjoining foundation access (0.12.2)

The previous flat 4m assembly models placed every `*_store` at `(2.3, -2, -2.3)`. This is outside the owning footprint and below its surface; adjoining tiles can enclose that staging point. The registration helper also forced `inProgressWalkable=false` and `isPathFindingCollider=true` on both construction and completed objects, contrary to the native foundation policy.

For the five flat 4m foundation families, `spPartRegistration.gameObject` now retains these two flags from the native source object. Native `physicsSets:init` consequently includes construction sites in `walkableOrInProgressWalkable`, without adding them to `pathColliders`, while completed parts remain ordinary walkable colliders. No global navigation hooks or changes to Sapiens movement are introduced. Other sizes, ramps, pools and unrelated mods retain their previous policy.

`foundation-access/access_geometry.py` places staging helpers at `(0, surfaceDatum, 0)` on the owning deck. It is shared by the targeted `foundation-access/build.py` updater and the maintained alignment generator. Both full and low-detail assemblies are updated. Visible resource meshes, final-slot transforms, connectors, costs and object keys are untouched. The updater backs up modified source assemblies and preserves their binary chunks; repeated runs are idempotent. Do not regenerate these assemblies with a historical generator that restores below-deck storage points.

Run `python foundation-access/check.py` for the dedicated checks plus the existing foundation, alignment, integration, soil, snapshot, Rebuild and pool suites. The new test evaluates actual native object definitions and `physicsSets:init`, then checks own-deck storage, all eight neighbours in a 3x3 layout, four orientations and seam helper distances. These are geometric/registration preconditions, not a simulation of the C++ pathfinder. The old registration snapshot normalizes only the two intentionally changed flags for the affected legacy keys; the new native-physics test verifies their current values independently.

There is no save/database migration, added network endpoint or per-frame access hook. Restart and test adjacent mixed-material foundations, resource delivery, construction, dismantling and reload in-game. Provide a reachable ramp/approach for a raised deck; this fix does not make a two-metre vertical edge climbable.
