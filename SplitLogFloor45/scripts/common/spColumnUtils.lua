local copy=mjrequire("common/sl45Util").copy
local columns={}

function columns.points(cfg,male)
    local snap=mjrequire "common/snapGroups/snapGroup"
    local vec3=mjrequire("common/mjm").vec3
    local points=copy((male and snap.malePoints or snap.femalePoints)[male and "verticalColumnMaleSnapPoints" or "verticalColumnFemaleSnapPoints"])
    for _,entry in ipairs(points) do
        entry.point=vec3(entry.point.x,entry.point.y*cfg.height/2,entry.point.z)
        entry.heuristicOffset=nil
    end
    return mjrequire("common/sl90Utils").finish(points,male)
end

function columns.recipe(info,cfg)
    -- One native material family per part keeps filtering, delivery and refunds
    -- on the game's normal inventory path. Never invent substitute resources.
    assert(#info.requiredResources==1,"Column recipe requires one material family")
    info.requiredResources[1].count=cfg.count
    info.allowYTranslation,info.allowXZRotation=true,true
    info.snapToWalkableHeight=nil
    info.variationGroupName=nil
end

function columns.models(model)
    local materials=mjrequire "common/spColumnMaterials"
    for _,cfg in ipairs(mjrequire "common/spColumns") do
        for _,suffix in ipairs({"","_low"}) do
            local variants={}
            for objectKey,material in pairs(materials[cfg.family].resources) do
                variants[cfg.key.."_"..objectKey..suffix]={lightWood=material}
            end
            model.remapModels[cfg.key.."Content"..suffix]=variants
        end
    end
end

function columns.placeholders(placeholders,model,gameObject,cfg)
    local resource=mjrequire "common/resource"
    local family=mjrequire("common/spColumnMaterials")[cfg.family]
    local typeIndex=cfg.family~="stone" and resource.types[({wood="splitLog",mud="mudBrickDry",brick="firedBrick"})[cfg.family]].index or nil
    local groupIndex=cfg.family=="stone" and resource.groups.stoneBlockAny.index or nil
    for _,suffix in ipairs({"","_low"}) do
        local mapping={}
        for key in pairs(family.resources) do
            local object=gameObject.types[key]
            local name=cfg.key.."_"..key
            -- A foreign alias can be rejected for a detail-name collision.
            -- Only bind complete variants; both LODs must then use the native
            -- default instead of raising during placeholder initialization.
            if object and model.modelIndexesByName[name] then
                mapping[object.index]=model.modelIndexesByName[name..suffix]
            end
        end
        placeholders:addModel(cfg.key..suffix,{
            {key="resource_1",defaultModelName=cfg.key.."_"..family.default..suffix,
             resourceTypeIndex=typeIndex,resourceGroupIndex=groupIndex,
             placeholderModelIndexForObjectTypeFunction=function(info,index)
                 return mapping[index] or info.defaultModelIndex
             end},
            {key="resource_store",offsetToStorageBoxWalkableHeight=true},
        },{splitLog="resource",mudBrickDry="resource",stoneBlockAny="resource",firedBrick="resource"})
    end
end
return columns
