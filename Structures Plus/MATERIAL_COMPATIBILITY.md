# Material compatibility

Structures Plus 0.15.2, by Vittorio.

## Automatic support

Keep the provider mod enabled in the same world. Register new building resources in the normal native resource types (`log`, `splitLog`, `mudBrickDry`, `firedBrick`, tile types, `dirt`, `sand`) or the appropriate native group such as `stoneBlockAny`. Structures Plus retains these recipe categories; it does not make arbitrary resource categories interchangeable or change harvest/crafting recipes.

Extend `model.remapModels` for the native structural sections used by those resources, with registered material names and compatible UV layouts. Structures Plus discovers sibling material variants and clones its own geometry with translated material assignments. It preserves its shape, snap points and collision helpers, rather than displaying the provider's unmodified wall/floor shape.

Generated wall/floor/foundation selectors retain native callbacks and additionally recognize conventional log, split-log, stone-block and brick variant names. Tile variants use the native tile selectors. Providers that add completely new resources must also expose them through their native selection paths or the adapter below. All material maps must exist before the actual `model:loadRemaps()` operation; ordinary `common/model.lua` onload hooks can run before or after Structures Plus.

Columns discover wood/bark through `splitLogFloor4x4FullLow` variants, stone through `stoneBlockColumnBottom`, mud through `mudBrickColumnBottom`, and fired brick through `brickWallSection`. Wood Foundations use the same discovered wood/bark palette. Soil/sand appearances come from the loose `dirt` model's remaps and are only selected for actual dirt/sand resources, excluding clay and compost.

## Adapter API

For a compatibility mod that requires Structures Plus, call `mjrequire "common/spMaterialCompatibility"` from an onload hook before models are loaded. These registrations affect new variants, not replacements of the shipped materials. Names must contain only letters, digits and underscores. No code strings, file paths or network resources are accepted.

```lua
local mod = {loadOrder=20}
function mod:onload(model)
    local compatibility = mjrequire "common/spMaterialCompatibility"

    -- Palette for custom timber columns and wooden foundations.
    -- The provider registers cedarLog and cedarSplitLog as native resources.
    compatibility.registerWood("cedar", "cedarWood", "cedarBark")

    -- Nonstandard resource naming for a short stone column.
    compatibility.registerColumnMaterial("stone", "basaltCutBlock", "basaltBlock")

    -- Relate an independently supplied structural section to a native section.
    -- Both models must be registered. Materials use the native template's
    -- channels, not arbitrary channels from the independent model's UV atlas.
    compatibility.registerModelVariant(
        "stoneBlockWallSection", "basaltWallSection",
        {rockBlock="basaltBlock"}, "basaltCutBlock")
end
return mod
```

`registerModelVariant(base, variant, materials, objectKey)` maps a loaded native structural model and a loaded provider model to the actual resource object key. Add an adapter for each structural section the provider changes (for example wall sections, door headers, floor sections and foundation content). It covers Structures Plus pieces derived from that section. It is not a universal one-call adapter for unrelated meshes. `registerWood` only supplies the palette for custom timber columns/foundations; other wooden building sections use native remaps or structural adapters. Supported `registerColumnMaterial` families are `wood`, `mud`, `stone` and `brick`.

Adapters reuse the template's UV layout. A provider using an incompatible texture atlas must supply compatible materials/UV assets; the mod cannot infer an arbitrary texture layout. Missing resource objects are ignored, and unknown generated-model outputs fall back to the part's default surface with a diagnostic logged once per missing mapping.

An explicit resource-object binding also works when the provider model is already an automatically discovered native remap. The explicit and conventional resource keys can coexist; binding a resource does not replace the generated shape or recolor a shipped surface. Keep provider model names distinct from Structures Plus' generated aliases (`__spv__`, `__spwood__`, `spcompat_fill_`).

The native loader automatically creates detail aliases when cloning a model. If one would overwrite an already registered detail model, Structures Plus rejects that generated alias and reports the collision once. Missing variants retain the normal default-surface fallback; the conflicting model's original index is preserved.

## Lifecycle and maintenance

`common/spMaterialCompatibility.lua` owns discovery and adapters. The model hook calls the native loader first, then adds clones before `loadLODs`. Registration is sorted to keep indexes consistent between game threads. It does not require `gameObject` during model initialization, rewrite game files, fetch external content, create new persistent part IDs or rebuild meshes every frame. Runtime selectors only read prepared maps.

Native placeholder initialization supplies the actual `gameObject` instance; absent resources cannot trigger recursive gameObject initialization. Only recognized dirt/sand resource types receive generic fill surfaces. Unknown sand has very poor fertility, unknown soil normal fertility, and both retain their resource identity on harvest. Custom fertility transitions and entirely new resource categories need provider-specific integration.

Run `material-compat-tests/verify.py` and `foundation-access/check.py` from the project workspace. These verify native loading and Lua behavior with synthetic providers; they do not replace an in-game render, construction and dismantling test with the intended provider mod.
