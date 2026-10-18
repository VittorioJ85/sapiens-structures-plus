-- Shared geometry registration. Author: Vittorio.
-- Alias names remain stable; only their physical GLB path changes. Registration
-- runs before native remap enumeration and before the engine builds LOD tables.
local aliases = {}
local suffixes = {"_low", "_lowest", "_distant"}
local sharedPaths = {}

local function keys(t)
    local out = {}
    for key in pairs(t) do out[#out + 1] = key end
    table.sort(out)
    return out
end

local function compose(current, delta)
    local result = {}
    for key, value in pairs(delta) do result[key] = value end
    for original, material in pairs(current or {}) do
        result[original] = delta[material] or material
    end
    return result
end

-- Native loadRemap implicitly creates detail aliases using ONE material map.
-- Consolidated detail meshes may use different source material names. Invoke
-- the native method once per level with its own composed map instead. Hide only
-- the source's suffix lookups for that call, restoring them even on an error.
local function oneLevel(model, nativeRemap, base, name, map)
    local hidden = {}
    for _, suffix in ipairs(suffixes) do
        local key = base .. suffix
        hidden[key] = model.modelIndexesByName[key]
        model.modelIndexesByName[key] = nil
    end
    local ok, err = pcall(nativeRemap, model, base, {[name] = map})
    for key, index in pairs(hidden) do
        if model.modelIndexesByName[key] == nil then model.modelIndexesByName[key] = index end
    end
    if not ok then error(err) end
end

function aliases.cloneVariant(model, base, remaps)
    local nativeRemap = aliases.nativeRemap or model.loadRemap
    for _, name in ipairs(keys(remaps)) do
        local levels = {{base, name}}
        for _, suffix in ipairs(suffixes) do
            if model.modelIndexesByName[base .. suffix] then
                levels[#levels + 1] = {base .. suffix, name .. suffix}
            end
        end
        for _, level in ipairs(levels) do
            local index = assert(model.modelIndexesByName[level[1]], "Missing model: " .. level[1])
            local info = model.modelsByIndex[index]
            oneLevel(model, nativeRemap, level[1], level[2], compose(info.materialRemap, remaps[name]))
        end
    end
end

function aliases.register(model)
    if aliases.registered then return end
    local data = mjrequire "common/spModelAliasData"
    -- Preflight the entire static manifest before changing the registry.
    for name, entry in pairs(data) do
        assert(name:match("^[%w_%-]+$") and entry.base:match("^[%w_%-]+$"), "Invalid model alias")
        assert(not data[entry.base], "Model alias chains are not supported")
        assert(model.modelIndexesByName[entry.base], "Missing alias geometry: " .. entry.base)
    end
    for _, name in ipairs(keys(data)) do
        -- A physical model supplied by another mod takes precedence.
        if not model.modelIndexesByName[name] then
            local entry = data[name]
            local baseIndex = model.modelIndexesByName[entry.base]
            model:addModel(name .. ".glb")
            local index = model.modelIndexesByName[name]
            local info = model.modelsByIndex[index]
            info.path = model.modelsByIndex[baseIndex].path
            sharedPaths[info.path] = true
            info.materialRemap = compose(nil, entry.materials)
            model.clones[index] = baseIndex
        end
    end
    aliases.registered = true
end

function aliases.loadNativeRemaps(model, loader, ...)
    aliases.register(model)
    local previous = model.loadRemap
    aliases.nativeRemap = previous
    model.loadRemap = function(self, base, remaps)
        local relevant = false
        for _, suffix in ipairs({"", "_low", "_lowest", "_distant"}) do
            local index = self.modelIndexesByName[base .. suffix]
            if index and sharedPaths[self.modelsByIndex[index].path] then relevant = true end
        end
        if relevant then return aliases.cloneVariant(self, base, remaps) end
        -- Unrelated native/foreign geometry keeps the native remap semantics.
        return previous(self, base, remaps)
    end
    -- Restore the hook even if another provider raises an error. Only native
    -- initialization needs this adapter; do not change global runtime semantics.
    local ok, err = pcall(loader, model, ...)
    model.loadRemap = previous
    if not ok then error(err) end
end

return aliases
