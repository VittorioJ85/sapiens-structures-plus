# Code review - Structures Plus 0.12.0

## Foundation boundary clearance - 0.17.2, October 18, 2026

The completed-solid-foundation clearance predicate includes points strictly
inside the outer 5 cm strip, retaining a 1 mm boundary epsilon. Eligibility,
finite-position checks, vertical limits, radius bounds and native suborder
cleanup remain unchanged. No collision bypass, manual clearing suppression,
save migration, new input or filesystem/network access is introduced. Tests
cover the saved rotated target, exterior/deck cases and excluded part families.

## Tile binder correction - 0.17.1, October 17, 2026

The existing tile recipe now copies the native brick binder requirement. Output
selection uses the server's delivered resource indices, not client color claims.
Old recipe and object IDs are retained. No new input channel, runtime file access,
network call or per-frame work is introduced. Both editions' native production
quantities and drying/firing transitions are tested separately.

## Tile palettes - 0.17.0, October 16, 2026

Three fixed palette identifiers extend native registries during initialization.
There is no new runtime file access, network access, user-supplied code execution,
per-frame polling or world migration. Native recipes, resource categories and
drying rules are cloned; model aliases use the existing validated compatibility
API. Iteration snapshots prevent table mutation during model discovery. Existing
third-party firing mappings are retained. The two inspected editions have
different output quantities, which are inherited rather than hard-coded. Offline
tests cannot establish live rendering, multiplayer or gameplay compatibility.

## Shared water tiles - 0.16.5, October 16, 2026

Water rendering uses four fixed native resource keys for the large block and
one for the small block. No dynamically supplied paths, executable manifests,
network access or saved-data migration is introduced. The existing world-reset
and unloaded-object handling remains in place. Build-time normalization accepts
only schema version 1 and verifies original triangle attributes/materials before
replacement. Shared finalization retains path/reparse-point checks and verified
asset backups; retain a complete source snapshot before normalization.

## Lossless vertex storage â€” 0.16.3, October 16, 2026

This release adds no runtime callback, network endpoint or executable manifest.
Build tooling checks buffer/accessor bounds and triangle indices before packing,
rejects external buffers, and retains unsupported layouts unchanged. Exact full
attribute bytes determine vertex sharing; no position-only welding is allowed.
Existing path, reparse-point and alias-cycle checks still apply. Normalization
hashes are updated with packed assets to prevent double transforms on rebuild.
Keep a full source snapshot before applying the optimizer; redundant-file ZIP
backups alone do not contain overwritten vertex buffers. The ordinary installer
retains its full verified backup and rollback behavior.

## Static placement sharing â€” 0.16.1, October 15, 2026

This release changes authored GLB placements and alias data without adding a
runtime hook or new runtime input. Authoring translation metadata is validated
for local identifiers, bounded finite offsets and unchained pair references.
Regeneration hashes prevent repeated translation; approximate sharing is limited
to independently checked vertex/normal roundoff, with UVs and other attributes
preserved. Variant-dependent slot conflicts remain unoptimized. Existing backup,
safe manifest deletion and installer rollback safeguards remain in force.

## Shared geometry addendum â€” 0.16.0, October 15, 2026

The runtime consumes a bundled static Lua alias table; it does not evaluate user
input, perform filesystem/network operations or add per-frame work. Registration
validates local identifiers, flat references and existing bases before mutation.
Native remap hooks and temporary LOD lookup changes are restored on errors.
Unrelated native model remapping retains the engine's original semantics.

Build tooling uses structural comparisons and validated local paths, rejects
linked paths and alias cycles, and verifies an archive before removing redundant
GLBs. Installation removes only manifest-listed files within the verified mod
root after backup; rollback covers both copied and removed files. Tests include
path rejection and a failure injected after removal. Engine rendering, live saves
and multiplayer remain outside the offline security/regression checks.

## Current audit addendum â€” 0.15.2, October 14, 2026

The historical findings below remain applicable to their stated scope. Current runtime code also includes embedded compatibility support, which intentionally reads recognized enabled-mod files and intercepts `fileUtils.getFileContents` in memory. It checks mod versions, exact normalized source content, game-source guards where provided, and the source again at interception time. The DDAPI repair additionally validates expected closure upvalues. This is a shared trusted-mod integration, not isolation from malicious mods. No new runtime shell/network calls or user-provided code evaluation were found during this audit.

The 0.15.2 change separates resource-object bindings from model-alias creation and preserves multiple triangle resource keys. It introduces no new input channel, filesystem access, persistence format or authorization bypass. Existing server planting guards, finite-value checks and bounded soil depletion remain covered by offline tests. Migration and rollback tests run in workspace-only fixtures; actual saves are not used for destructive checks.

All runtime Lua files and bundled GLB structures were checked, and native-loader/integration fixtures were run against both user-designated local game installations. This does not establish live frame performance, engine collision behavior, multiplayer correctness or save/restart correctness in a running world. No claim of complete vulnerability absence is made.

Author: Vittorio. Reviewed October 3, 2026.

## Scope

Reviewed this mod's runtime Lua entry points, registration helpers, generated configuration references, planting authority, pool movement/rendering and saved-state handling. Inspected for command execution, file/network access, dynamically evaluated input and unsafe unbounded work. No runtime shell/network calls or user-controlled code evaluation were found. Developer-side test harnesses intentionally execute fixed local Lua fixtures and are not installed in the game.

## Corrections

- Replanting previously checked tree capacity but did not repeat foundation ownership or pending demolition/rebuild checks. Both planting paths now use one server-side validation function.
- Placement previews checked exposed soil only on the client. The server now verifies the actual supporting foundation with a short physics ray as well.
- A stale saved plant-to-foundation ID could apply harvest costs to the wrong foundation after movement. Position containment is now checked before trusting that association.
- Fertility degradation previously looped until the offset fell below the threshold. An infinite or extreme value from corrupt state or another mod could stall the server. Inputs are checked for finiteness and degradation work is bounded to the two possible soil transitions.
- Invalid planting coordinates are rejected before the mod issues spatial queries. Foundation occupancy is saved only when its value changes.
- Soil and pool queries share finite-number and position validation. Native LuaJIT vector coordinates are read under a protected call; invalid positions do not enter pool spatial queries. Invalid wave-clock values are ignored.
- Pool helpers defer object-registry lookup until runtime, preventing recursive initialization. Client caches reset on world initialization; missing render transforms are skipped until a later update.
- The pool swimming fix preserves paired native movement-cache invalidation on exit. Server pool movement excludes seated Sapiens; shallow solid surfaces and unfinished pools do not activate swimming.

## Migration tooling

The one-time migration uses fixed workspace/game roots and staged world configs. Before installation it checks SHA-256 hashes of source files, both installed mods and affected world configs. Only enabledMods entries change; staged configs are parsed in a restricted Lua environment and all unrelated settings are compared. Relative paths are constrained to their roots and world-config paths to the expected player/world layout. Reparse points are rejected for migration paths. Installation refuses to proceed while Sapiens is running.

Structures Plus and affected configs are backed up before changes. The standalone Pool Prototype directory is moved into the backup after replacement files and configs have been verified. Installation failures trigger rollback. These protections address accidental stale writes and path mistakes; they do not defend against an administrator or another process deliberately modifying files during installation.

## Limits and assumptions

These are source-level findings and defensive corrections, not evidence that an external attack occurred. A finite automated review does not guarantee the absence of every vulnerability. Sapiens and other installed mods share the runtime; this mod cannot sandbox code loaded by other mods or replace the engine's authentication, transport and general ownership checks.

No new network endpoints, external services, credentials or filesystem privileges are introduced. Preserve the server checks when changing the UI. The test fixture covers unauthorized replants, blocked surfaces, demolition conflicts, queued/mature tree limits, non-finite values, large offsets and stale associations. Live engine behavior remains a separate verification step.

## 0.11.1 addition review

The flat Stone Block Foundation 4x4 adds only generated assets and a catalog entry using existing registration helpers. No new runtime hooks, input handlers, file/network access or permissions are introduced. The asset generator reads fixed local native model data, excludes internal shadow meshes and writes to the workspace; it does not execute legacy generator entry points. Existing material selectors, research requirements and grass/snow policy are inherited.

## 0.11.2 menu review â€” October 3, 2026

Menu changes use fixed part keys and mutate only the intended variation memberships/order and two main-menu entries. They introduce no external input, filesystem/network access or code evaluation. Existing registration IDs and server authorization remain unchanged. Native callbacks are chained once; the wrapper accepts receiver-free calls used by Hammerstone. Native/third-party list entries and filtered Blueprint views are preserved. Repeated initialization and the native finalize/UI paths are covered by the dedicated menu regression check.

## 0.11.3 color review

The Water Block material copies the native water color into its own vector. It does not mutate the native material, add runtime entry points or introduce external input. The existing material key and mesh references remain stable.

## 0.12.0 Rebuild review

The asset-only 0.12.1 update retains these runtime guarantees; see its review below.

Compatibility groups are derived only from the fixed part catalog and stored through the game's existing type-map API. No network handlers, filesystem access, input evaluation or custom construction shortcuts are introduced. The native Rebuild panel remains responsible for available-research/resource/tool checks, and the native server queue and deconstruction/replacement pipeline remain in use. Separate shape/size/height groups avoid offering incompatible replacements.

Rebuilding occupied soil foundations was already rejected by the server. The UI now reports the same reason as deconstruction, using a shared wrapper that retains the native queued-order restriction. Regression checks cover this guard, existing and unfinished objects, native target-list construction and preserved material/tool restrictions through the native replacement function. These offline checks do not replace live gameplay verification.

## 0.12.1 asset and installer review

Surface alignment changes only model assets, descriptive comments and metadata;
there are no new runtime input handlers, network calls, file access or privileges.
Saved IDs and server guards are unchanged. Generation uses trusted workspace code
and native local meshes; it excludes shadow helpers, validates finite geometry,
recalculates mesh bounds/normals and verifies its frozen inputs before reuse.
The preview is a local JPEG. The update installer rejects linked paths, checks
source hashes, backs up the installed mod and verifies copied files. It does not
publish to Steam or alter world data.

## 0.16.2 rigid sharing review

This release adds no runtime callbacks, filesystem access, networking or input
evaluation. Authoring matrices must be finite proper rigid transforms with
bounded translations; scale, mirroring, shear and projective rows are rejected.
Legacy offsets and rigid transforms cannot overlap for one model. Paths and flat
alias targets retain existing validation. Regeneration must use the authoring
reader and finalize through consolidation; normalized hashes prevent repeated
transforms. Material, topology, UV and shadow-node semantics remain explicit.
Installed assets are backed up and individually hash-verified by the installer.

## Profitable rigid subsets â€” 0.16.4, October 16, 2026

This asset-only update reuses validated proper rigid transforms and flat aliases.
No new runtime callback, input or native scaling assumption is introduced.
Planned mesh bytes are hash-checked and compared against the requested transform
before staging. Previous transform metadata is retained and composed rather than
overwritten. Existing path checks, model backups and installer rollback apply.
