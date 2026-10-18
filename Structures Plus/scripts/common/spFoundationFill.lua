-- Shared opt-in policy: only these foundations accept the soil/sand group.
-- Do not change the global dirt resource or extend Water Block recipes.
local copy=mjrequire("common/sl45Util").copy
local fill={groupKey="spFoundationFill",sandKeys={"sand","riverSand","redSand"},
    keys={"dirtFoundation1x1","dirtFoundation2x2","spf_dirt_4","spf_dirt_ramp4"}}

function fill.modelName(key,sandKey,low)
    return "spfill_"..key.."_"..sandKey..(low and "_low" or "")
end

function fill.configureBuildables(constructable)
    local resource=mjrequire "common/resource"
    local group=assert(resource.groups[fill.groupKey],"Foundation fill group is not registered")
    for _,key in ipairs(fill.keys) do
        local info=assert(constructable.types[key],key)
        info.requiredResources=copy(info.requiredResources)
        for _,requirement in ipairs(info.requiredResources) do
            if requirement.type==resource.types.dirt.index then
                requirement.type=nil
                requirement.group=group.index
            end
        end
    end
end

function fill.configureModels(model)
    local assets=mjrequire "common/slFoundationModels"
    for _,key in ipairs(fill.keys) do
        for _,low in ipairs({false,true}) do
            local native=(key=="dirtFoundation1x1" and "dirtFoundation1x1Content" or "dirtFoundation2x2Content")..(low and "_low" or "")
            local base=assets[key] and assert(assets[key].dirt_1[native]) or native
            local variants=model.remapModels[base] or {}
            model.remapModels[base]=variants
            for _,sandKey in ipairs(fill.sandKeys) do
                variants[fill.modelName(key,sandKey,low)]={dirt=sandKey}
            end
        end
    end
end

function fill.configurePlaceholders(placeholders,model,gameObject)
    local resource=mjrequire "common/resource"
    local group=assert(resource.groups[fill.groupKey])
    local sandByIndex={}
    for _,key in ipairs(fill.sandKeys) do sandByIndex[assert(gameObject.types[key]).index]=key end
    local extras=mjrequire("common/spMaterialCompatibility").fillModels
    for _,key in ipairs(fill.keys) do
        for _,suffix in ipairs({"","_low"}) do
            local index=model:modelIndexForName(key..suffix)
            -- Some generated LODs share a table. Copy before wrapping, so each
            -- model gets one selector and native callbacks remain untouched.
            local infos=copy(assert(placeholders.placeholderInfosByModelIndex[index],key))
            local info=assert(infos.dirt_1,key.."/dirt_1")
            local original=assert(info.placeholderModelIndexForObjectTypeFunction)
            info.resourceTypeIndex=nil
            info.resourceGroupIndex=group.index
            info.placeholderModelIndexForObjectTypeFunction=function(slot,objectIndex,context)
                local object=gameObject.types[objectIndex]
                if object and (object.resourceTypeIndex==resource.types.dirt.index or object.resourceTypeIndex==resource.types.sand.index) then
                    local low=suffix=="_low" or (context and context.subdivLevel and model:modelLevelForSubdivLevel(context.subdivLevel)>1)
                    local name=((extras[key] or {})[low and "_low" or ""] or {})[object.key]
                    if name then return model:modelIndexForName(name) end
                end
                local sand=sandByIndex[objectIndex]
                if sand then
                    local low=suffix=="_low" or (context and context.subdivLevel and model:modelLevelForSubdivLevel(context.subdivLevel)>1)
                    return model:modelIndexForName(fill.modelName(key,sand,low))
                end
                return original(slot,objectIndex,context)
            end
            placeholders.placeholderInfosByModelIndex[index]=infos
            local remaps=copy(placeholders.resourceRemapsByModelIndex[index] or {})
            remaps[fill.groupKey]="dirt" -- Preserve existing final/store GLB slots.
            placeholders.resourceRemapsByModelIndex[index]=remaps
        end
    end
end
return fill
