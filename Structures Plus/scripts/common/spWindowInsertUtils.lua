-- Separate inserts: recipes/materials, exact opening anchors and shared assets.
local util={}
local configs=mjrequire "common/spWindowInserts"
local copy=mjrequire("common/sl45Util").copy
function util.config(object)
    if not object then return nil end
    local types=mjrequire("common/gameObject").types
    for _,cfg in ipairs(configs) do
        if types[cfg.key] and object.objectTypeIndex==types[cfg.key].index then return cfg end
    end
end
function util.materials(family)
    local materials=mjrequire "common/spColumnMaterials"
    if family~="branch" then return materials[family].resources,materials[family].default end
    local result={}
    -- Branches use the same cut-timber finish as their corresponding species.
    for key,value in pairs(materials.wood.resources) do
        local name,count=key:gsub("SplitLog$","Branch")
        if count==1 then result[name]=value end
    end
    return result,"birchBranch"
end
function util.models(model)
    for _,cfg in ipairs(configs) do
        for _,part in ipairs(cfg.parts) do
            local materials=util.materials(part.family)
            local names={};for name in pairs(materials) do names[#names+1]=name end;table.sort(names)
            for _,name in ipairs(names) do
                assert(name:match("^[%w_]+$") and #name<240,"Invalid window material identifier")
                local target=part.mesh.."_"..name
                if not model.modelIndexesByName[target] then
                    mjrequire("common/spModelAliases").cloneVariant(model,part.mesh,
                        {[target]={[part.family=="stone" and "rockBlock" or "lightWood"]=materials[name]}})
                end
            end
        end
    end
end
function util.recipe(info,cfg,buildable)
    local resource=mjrequire "common/resource"
    if cfg.style=="stone" then
        local native=assert(mjrequire("common/constructable").types.stoneBlockColumn,"Missing native stone column recipe")
        info.skills=copy(native.skills)
        info.disabledUntilAdditionalResearchDiscovered=native.disabledUntilAdditionalResearchDiscovered
    end
    local afterAction=info.requiredResources[1] and info.requiredResources[1].afterAction
    info.requiredResources={}
    if cfg.style=="stone" then
        info.requiredResources[1]={group=resource.groups.stoneBlockAny.index,count=1}
    elseif cfg.style=="shutters" or cfg.style=="bars" then
        info.requiredResources[1]={type=resource.types.splitLog.index,count=1}
    end
    if cfg.style~="bars" then info.requiredResources[#info.requiredResources+1]={type=resource.types.branch.index,count=1} end
    for _,requirement in ipairs(info.requiredResources) do requirement.afterAction=copy(afterAction) end
    info.buildSequence=buildable.bringOnlySequence
    info.checkObjectCollisions=false;info.snapToWalkableHeight=nil
    info.countsAsSplitLogWallForTutorial=nil;info.variationGroupName=nil
end
function util.placeholders(placeholders,model,objects,cfg)
    local resource=mjrequire "common/resource"
    local definitions,stores={},{}
    for _,part in ipairs(cfg.parts) do
        local materials,default=util.materials(part.family)
        local mapping={}
        for key in pairs(materials) do
            if objects.types[key] then mapping[objects.types[key].index]=model.modelIndexesByName[part.mesh.."_"..key] end
        end
        local entry={key=part.slot,defaultModelName=part.mesh.."_"..default,
            placeholderModelIndexForObjectTypeFunction=function(info,index)return mapping[index] or info.defaultModelIndex end}
        if part.resource=="stone" then entry.resourceGroupIndex=resource.groups.stoneBlockAny.index
        else entry.resourceTypeIndex=resource.types[part.resource].index end
        if cfg.style=="shutters" and part.slot=="splitLog_1" then entry.additionalIndexCount=1 end
        definitions[#definitions+1]=entry
        local store=(part.resource=="stone" and "resource" or part.resource).."_store"
        if not stores[store] then definitions[#definitions+1]={key=store,offsetToStorageBoxWalkableHeight=true};stores[store]=true end
    end
    placeholders:addModel(cfg.key,definitions,{stoneBlockAny="resource"})
end
function util.addSnaps(snap)
    local maps=mjrequire "common/typeMaps"
    local vec3=mjrequire("common/mjm").vec3
    local finish=mjrequire("common/sl90Utils").finish
    for _,cfg in ipairs(configs) do
        local key="spwi_"..cfg.fit
        if not snap.maleTypes[key] then maps:insert("snapGroupMaleType",snap.maleTypes,{key=key}) end
        snap.malePoints[key]=finish({{point=vec3(0,0,0),normal=vec3(0,0,1),snapGroup=snap.maleTypes[key].index}},true)
    end
end
function util.attachAnchors(objects)
    local snap=mjrequire "common/snapGroups/snapGroup"
    local vec3=mjrequire("common/mjm").vec3
    for _,cfg in ipairs(configs) do
        for _,key in ipairs(cfg.hosts) do
            if objects[key] then
                local group=assert(snap.maleTypes["spwi_"..cfg.fit],"Window snap groups must initialize before window walls").index
                local info=copy(objects[key]);local points=info.femaleSnapPoints or {}
                if not (points.allowedMaleSnapGroupSet and points.allowedMaleSnapGroupSet[group]) then
                    local anchors=cfg.anchors or {{point={cfg.centerX,cfg.center,0},normal={0,0,1}}}
                    for _,anchor in ipairs(anchors) do
                    for _,sign in ipairs({-1,1}) do
                        local p,n=anchor.point,anchor.normal
                        points[#points+1]={point=vec3(p[1],p[2],p[3]),normal=vec3(sign*n[1],sign*n[2],sign*n[3]),maleSnapGroups={group}}
                    end
                    end
                    info.femaleSnapPoints=mjrequire("common/sl90Utils").finish(points,false)
                    objects[key]=info
                end
            end
        end
    end
end
return util
