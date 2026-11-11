-- Narrow, guarded in-memory overlay; installed game files are never changed.
local overlay = {}
local needle = 'local nearbyCount = serverResourceManager:countOfResourcesNearPos(resourceInfo.resourceGroupTypeIndex or resourceInfo.resourceTypeIndex, object.pos, true, planTribeID, nil, nil)'
local replacement = 'local nearbyCount = mjrequire("server/spMaintain"):count(serverResourceManager, object, thisPlanState, resourceInfo, planTribeID)'

function overlay.patch(source)
    if type(source) ~= "string" then return nil end
    local first, last = source:find(needle, 1, true)
    if not first or source:find(needle, last + 1, true) then return nil end
    return source:sub(1, first - 1) .. replacement .. source:sub(last + 1)
end

function overlay:install()
    if self.installed then return end
    self.installed = true
    local root = fileUtils.getResourcePath("scripts")
    local targets = {
        ["server/planManager"] = {patch=overlay.patch, marker=replacement},
        ["mainThread/ui/inspect/inspectCraftPanel"] = {
            patch=mjrequire("structuresPlusMaintain/craftPanel").apply,
            marker='local uiSlider = mjrequire "structuresPlusMaintain/quantity"'},
    }
    local paths = {}
    for name, target in pairs(targets) do
        target.path = root .. "/" .. name .. ".lua"
        paths[target.path:gsub("\\", "/"):lower()] = target
    end
    local read = fileUtils.getFileContents
    fileUtils.getFileContents = function(file, ...)
        local source = read(file, ...)
        local target = type(file) == "string" and paths[file:gsub("\\", "/"):lower()]
        if target then
            local patched = target.patch(source)
            if not target.reported then
                mj:log("[StructuresPlusMaintain] ", target.path, patched and " overlay active" or " unsupported source; native behavior retained")
                target.reported = true
            end
            return patched or source
        end
        return source
    end
    -- Standard Lua loaders, optionally Hammerstone and the embedded detour
    -- loader. Insert before the native source loader, after mod-aware loaders.
    local count = #package.loaders
    if count >= 4 and count <= 6 then
        table.insert(package.loaders, count - 2, function(name)
            local target = targets[name]
            if not target then return nil end
            local source = fileUtils.getFileContents(target.path)
            if type(source) ~= "string" or not source:find(target.marker, 1, true) then return nil end
            local fn, err = loadstring(source, "@StructuresPlusMaintain/"..name..".lua")
            if not fn then mj:log("[StructuresPlusMaintain] compile failed: ", err) end
            return fn
        end)
    else
        mj:log("[StructuresPlusMaintain] unfamiliar loader chain; fallback loader not installed")
    end
end
return overlay
