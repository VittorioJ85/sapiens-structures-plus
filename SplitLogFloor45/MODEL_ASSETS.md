# Shared model assets

Author: Vittorio. Introduced in Structures Plus 0.16.0.

The mod exposes the same 8,086 authored model names using 2,182 physical GLBs
and 5,904 aliases in version 0.16.5. Version 0.16.1 used 2,603 GLBs.
Shape, UVs, helper geometry, camera framing, collisions and materials are
preserved. This reduces asset count and package size; it is not an FPS claim.

## Shared water tiles (0.16.5)

The 4 m Water Block uses four native `dirt_1` through `dirt_4` placements of a
2 m tile. `additionalIndexCount=3` groups these under the first resource, keeping
the recipe and construction visibility policy unchanged. Every tile receives
the same animation phase. The 2 m Water Block retains one placement.

Legacy `slpool4_waveNN` and `slpool_water4x4Content` names remain registered but
now identify a single tile; their full footprint is supplied by the four resource
nodes. Consumers rendering these internal content models directly must use all
four placements. Buildable/object IDs and saved object types are unchanged.

`waterTiles.json` enables `model_water_tiles.py` in the shared finalizer. It checks
all triangle attributes and materials before replacing any regenerated expanded
water meshes, then restores the four helper placements. Ordinary consolidation
creates flat aliases. Buffer all generator inputs before writes, take a complete
snapshot, and run `model_assets.py <mod> --apply`. Changed geometry is rejected
instead of silently normalized. Other helpers, collision and cameras are retained.

The independent tests in `pool-tests/geometry_checks.py` compare complete placed
surfaces against the original models. `audits/water-tiles` also covers native
resource consumption, both model registries and an idempotent regeneration round
trip. Live renderer performance and gameplay still require in-engine validation.

## Lossless vertex storage (0.16.3)

`model_vertices.py` shares vertices only when every attribute byte matches
within the same indexed triangle primitive. It preserves the ordered triangle
attributes exactly, including UV seams, hard normals, signed zero and unused
vertices. Index buffers are remapped without reordering triangles. Meshes are
not simplified or quantized. The same rule applies to visible and shadow meshes.

Only independently owned accessors/views are repacked. Sparse accessors, morph
targets, animation/skinning, extensions, overlapping views and unsupported
layouts remain unchanged. Buffer/view bounds and triangle indices are checked;
byte/short vertex attributes retain four-byte element alignment. All helper
nodes, material names and other scene metadata remain unchanged.

`consolidate(..., apply=True)` normalizes authoring coordinates first, packs
eligible models, updates normalization hashes, consolidates aliases, and writes
compact JSON. Existing readable/expanded input remains accepted. Do not repack
runtime files manually without updating normalization hashes: the next build
would otherwise mistake changed bytes for new authoring coordinates. A stale
hash fails explicitly. Roundoff template comparisons normalize both storage
layouts before comparing. Generators must honor accessor offsets, strides and
indices; never infer triangle topology from vertex-array length or order.

The non-applying consolidation command reports whole-model sharing only;
it does not estimate vertex-packing savings. Always use a staging copy and
retain a full snapshot before applying storage optimization. Removal backups
cover redundant whole files, not overwritten vertex buffers.

JSON compaction changes whitespace only. Runtime compatibility `.txt` files
remain intact because they contain exact source guards/replacements. The total
file count is unchanged from 0.16.2; disk savings come from smaller files.

## Runtime

Version 0.16.2 extends static resource placement sharing to proper rotations and
translations. Every material selection and LOD in a slot uses the same transform.
Existing material aliases may split when their slots need different transforms;
the build keeps only changes with a net reduction. Scale/shear candidates remain
separate. Resource positions/rotations change; helper-box scales and all
camera/collision/snap/walk/storage helpers remain unchanged. Shadow-volume meshes
receive the same rigid transform as their visible geometry.

`modelTranslations.json` records original authoring-coordinate transforms,
equivalent templates and normalized hashes. It supports legacy offset manifests.
The game does not read this tooling file or perform extra updates. Resource
placement follows the native offset/rotation contract in `common/worldHelper`.

`common/spModelAliasData.lua` is a generated, flat map from an existing model
name to a physical model and a material map. `common/spModelAliases.lua` restores
the names before native remap enumeration and LOD initialization. It uses native
model registration and clone bookkeeping, preserving each alias's own volume and
wind flags. A physical model with an alias name supplied by another mod wins.

The native loader replaces material maps and automatically clones LOD suffixes.
During native remap initialization only, the adapter composes maps for shared
mod geometry and handles each detail level separately. Unrelated native models
retain native behavior. Third-party material discovery uses the same explicit
per-level helper. No per-frame work, mesh generation or filesystem access is
added to the runtime.

Names and game-object/buildable IDs remain stable. Numeric model registry
indexes are transient and can change; every thread and multiplayer participant
must run the same mod version. Do not rename source models to optimize indexes.
Direct third-party replacement of a shared physical GLB affects its aliases;
providers should use material registration or the documented adapter API.

## Authoring and regeneration

From the workspace root:

```text
python model_assets.py SplitLogFloor45
python model_assets.py SplitLogFloor45 --apply
```

The first command reports proposed consolidation. The second writes both the
tooling JSON manifest (`modelAliases.json`) and static Lua data, verifies a ZIP
backup, then removes only the redundant physical files. Running it again must
make no changes. The original physical assets are retained in workspace backups.

Before strict deduplication, explicitly transformed content may use a common
template only when all structural metadata and other binary attributes match,
with position error below 2e-6 m and normal component error below 2e-5. This
removes float32 rotation/translation roundoff; it does not approximate shapes.
The independent assembly test checks composed world-space geometry afterward.

Strict comparison removes only material names from JSON and requires all other JSON
and binary data to match. A material map must reproduce every slot, including
repeated material names. Different geometry, helpers or UVs remain separate.
Alias chains and external buffers are rejected. Model paths are restricted to
local identifiers; no manifest values are evaluated as executable code.

To edit one logical model independently, read it with
`model_translations.read_authoring_model(path)`, write the edited GLB under that original name,
then consolidate again. Physical overrides take precedence during regeneration.
Editing a shared canonical file directly deliberately affects every alias using
it. Use `model_assets.model_names(mod, pattern)` when iterating logical assets;
filesystem globbing alone omits aliases. `read_model` expands materials in memory
for runtime-space geometry tests without writing redundant files. Generators
must instead use `read_authoring_model`, which restores original baked positions
and removes the matching assembly transforms in memory. `consolidate(...,
apply=True)` then normalizes regenerated files before deduplication. Hashes prevent
applying transforms twice. A regenerated pair that no longer matches retains
separate geometry. Do not edit optimized vertex coordinates directly: use the
authoring reader and finalize after writing. Both manifests must ship together.

The maintained column, foundation-access and alignment generators finish with
consolidation. Historical generators that rewrite runtime hooks remain disabled.
Any new generator must follow this workflow before packaging or installation.
For other mods, use a unique Lua data-module name (`--module`) and a corresponding
mod-specific runtime adapter to avoid cross-mod module-name collisions. Do not
install Structures Plus' module names unchanged into a different mod.

## Verification and deployment

- Check every logical asset against the pre-consolidation snapshot, including
  every material slot. For static placement sharing, compare the composed mesh
  and resource-node transform, allowing only float32 roundoff. Unrelated assets
  and non-resource helpers must remain unchanged.
- Compare actual Public/Beta native model registries, material results and LOD
  selections by stable name, including synthetic third-party material providers.
- Run the existing construction, preview, snapping, soil, Rebuild, water and
  compatibility regression suites plus GLB/Lua integrity checks.
- Test invalid identifiers, installer removal/rollback and repeat generation.
- Test previews, existing saves, build/demolish/Rebuild and distant rendering in
  the actual game. Offline Lua checks do not emulate the renderer or certify
  multiplayer/save loading.

The normal installer backs up and verifies the current mod first. It copies
the new release, removes only GLBs explicitly listed as aliases, and rolls back
both writes and removals on failure. It does not modify worlds or unrelated mods.

## Profitable rigid subsets (0.16.4)

Evaluate candidate transforms per independent resource-slot component and in
both directions, including the cost of splitting existing material aliases.
Accept only a positive net reduction; a whole-family trial can hide profitable
subsets. The 0.16.4 planner accepts two nine-variant slot groups in the 2m and
4m wooden hypotenuse window walls, eliminating eight physical resource files.
Both full and low-detail assemblies receive the matching placement changes.

The existing proper-rotation/translation helper and alias loader are reused.
No native scale/shear assumption is introduced. Authoring metadata composes
new transforms with all older transforms; it must not reset earlier sharing.
Roundoff templates retain the existing 2e-6 m position / 2e-5 normal-component
limits. Verify composed placement for every material and LOD independently.
The workspace planner/build/check evidence is in `audits/rigid-subsets`.

Batch generators must read all logical inputs from an immutable snapshot or
buffer them before writing any shared canonical file. Otherwise later aliases
can resolve to a partly regenerated mix of authoring and runtime coordinates.
Normalization hashes for absent physical alias files are obsolete and may be
pruned; preserve the transforms and flat template mappings for those names.
