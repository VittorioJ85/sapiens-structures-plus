local copy = mjrequire("common/sl45Util").copy
local registration = {}

-- Keep native material selection callbacks; only translate their model results.
function registration.remap(placeholders, model, cfg, assets, gameObject)
    local sourceIndex = model:modelIndexForName(cfg.sourceModel or cfg.source)
    local sourceInfos = assert(placeholders.placeholderInfosByModelIndex[sourceIndex], cfg.source)
    local newInfos = {}
    for key, originalInfo in pairs(sourceInfos) do
        local info = copy(originalInfo)
        local names = assets[cfg.key][key]
        if names then
            local extra=mjrequire("common/spMaterialCompatibility").objectMapping(cfg,key,model,gameObject)
            local mapping = {}
            for from, to in pairs(names) do
                local index = model.modelIndexesByName[from]
                if index then mapping[index] = assert(model.modelIndexesByName[to], to) end
            end
            local function remap(index)
                if index == nil then return nil end
                -- An independent foreign mesh may have no compatible remap.
                -- Keep the build usable with its default surface, not a crash.
                if not mapping[index] then mjrequire("common/spMaterialCompatibility").warnMissing(cfg.key.."/"..key.."/"..tostring(index)) end
                return mapping[index] or mapping[originalInfo.defaultModelIndex]
            end
            info.defaultModelIndex = remap(originalInfo.defaultModelIndex)
            for level, index in ipairs(info.defaultModelIndexesByDetailLevel) do
                info.defaultModelIndexesByDetailLevel[level] = remap(index)
            end
            info.placeholderModelIndexForObjectTypeFunction = function(_, objectIndex, context)
                if extra[objectIndex] then
                    local level=model:modelLevelForSubdivLevel((context and context.subdivLevel) or mj.SUBDIVISIONS-1)
                    return model:modelIndexForDetailedModelIndexAndDetailLevel(extra[objectIndex],level)
                end
                return remap(placeholders:getPlaceholderModelIndexForObjectType(originalInfo, objectIndex,
                    context or {subdivLevel=mj.SUBDIVISIONS-1}))
            end
        end
        newInfos[key] = info
    end
    for _, suffix in ipairs({"", "_low"}) do
        local index = model:modelIndexForName(cfg.key .. suffix)
        placeholders.placeholderInfosByModelIndex[index] = newInfos
        placeholders.placeholderKeysByModelIndex[index] = copy(placeholders.placeholderKeysByModelIndex[sourceIndex])
        placeholders.resourceRemapsByModelIndex[index] = placeholders.resourceRemapsByModelIndex[sourceIndex]
    end
end

function registration.wood(placeholders, model, gameObject, cfg)
    assert(gameObject, "Foundation models require modelPlaceholder:init(gameObject)")
    local resource = mjrequire "common/resource"
    local definitions = {}
    for _, entry in ipairs(mjrequire("common/slFoundationWood")[cfg.key]) do
        local mapping = {}
        for objectKey, target in pairs(entry.modelsByObjectKey) do
            local objectType = gameObject.types[objectKey]
            if objectType then mapping[objectType.index] = assert(model.modelIndexesByName[target], target) end
        end
        table.insert(definitions, {
            key=entry.key, resourceTypeIndex=resource.types[entry.resource].index,
            defaultModelName=entry.defaultModelName,
            placeholderModelIndexForObjectTypeFunction=function(info, objectIndex)
                -- Older built foundations may lack the newly added log inventory.
                return mapping[objectIndex] or info.defaultModelIndex
            end,
        })
    end
    for _, kind in ipairs({"log", "splitLog"}) do
        table.insert(definitions, {key=kind.."_store", offsetToStorageBoxWalkableHeight=true})
    end
    placeholders:addModel(cfg.key, definitions)
    placeholders:addModel(cfg.key.."_low", definitions)
end

function registration.pool(placeholders, cfg)
    local resource = mjrequire "common/resource"
    local definitions = {}
    local count = cfg.size == 4 and 4 or 1
    for i=1,count do
        definitions[#definitions+1] = {
            key="dirt_"..i, defaultModelName=cfg.key.."Content",
            resourceTypeIndex=resource.types.dirt.index,
            defaultModelShouldOverrideResourceObject=true,
            -- One delivered resource reveals the same complete surface as before.
            -- The other tiles belong to this resource, not to extra recipe items.
            additionalIndexCount=count==4 and i==1 and 3 or nil,
        }
    end
    definitions[#definitions+1] = {key="dirt_store", offsetToStorageBoxWalkableHeight=true, hiddenOnBuildComplete=true}
    for _, suffix in ipairs({"", "_low"}) do
        placeholders:addModel(cfg.key .. suffix, definitions)
    end
end

return registration
