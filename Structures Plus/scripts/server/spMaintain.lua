-- Material-aware Maintain counts. Author: Vittorio.
local maintain = {}

-- Resolve the union of actual output types for the currently permitted inputs.
-- Recompute on each availability update: restrictions and mod recipes can change.
function maintain.outputTypes(recipe, blocked, gameObject)
    if not recipe then return nil end
    local result = {}
    local function add(outputs)
        for _, index in ipairs(outputs or {}) do result[index] = true end
    end
    local info = recipe.outputObjectInfo
    if info and info.outputArraysByResourceObjectType then
        for _, requirement in ipairs(recipe.requiredResources or {}) do
            local inputs = gameObject:getAvailableGameObjectTypeIndexesForRestrictedResource(requirement, blocked, nil)
            for _, input in ipairs(inputs or {}) do
                if not blocked or not blocked[input] then
                    add(info.outputArraysByResourceObjectType[input])
                end
            end
        end
    elseif info and info.objectTypesArray then
        add(info.objectTypesArray)
    elseif not info and gameObject.types[recipe.key] then
        result[gameObject.types[recipe.key].index] = true
    else
        -- Unknown third-party output schema: preserve native counting.
        return nil
    end
    return result
end

function maintain:count(resourceManager, object, state, resourceInfo, tribeID)
    local gameObject = mjrequire "common/gameObject"
    local recipe = mjrequire("common/constructable").types[state.constructableTypeIndex]
    local allowed = self.outputTypes(recipe, object.sharedState.restrictedResourceObjectTypes, gameObject)
    if allowed then
        -- Pottery and bricks can maintain the dry result rather than the wet
        -- crafting output. Follow only drying, never rot/despawn, and retain
        -- the exact material variant. The native resource query still selects
        -- which stages the recipe actually counts.
        local evolving = mjrequire "common/evolvingObject"
        local pending = {}
        for index in pairs(allowed) do pending[#pending + 1] = index end
        local i = 1
        while i <= #pending do
            local evolution = (evolving.evolutions or {})[pending[i]]
            if evolution and evolution.categoryIndex == evolving.categories.dry.index
                and evolution.toType and not allowed[evolution.toType] then
                allowed[evolution.toType] = true
                pending[#pending + 1] = evolution.toType
            end
            i = i + 1
        end
    end
    local counts = allowed and {} or nil
    -- Native enumeration retains distance, ownership, storage permissions,
    -- queued-plan and held-resource rules. Never stop before all types are counted.
    local total = resourceManager:countOfResourcesNearPos(
        resourceInfo.resourceGroupTypeIndex or resourceInfo.resourceTypeIndex,
        object.pos, true, tribeID, nil, counts)
    if not allowed then return total end
    total = 0
    for index, count in pairs(counts) do
        if allowed[index] then total = total + count end
    end
    return total
end

return maintain
