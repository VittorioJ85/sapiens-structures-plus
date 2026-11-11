-- Shape geometry is generated once. Resource variants only remap materials.
local copy=mjrequire("common/sl45Util").copy
local configs=mjrequire "common/spShapedFoundations"
local utils={}
function utils.addStackGroups(snap)
    local maps=mjrequire "common/typeMaps"
    for _,cfg in ipairs(configs) do
        local key="sp_stack_"..cfg.shape..cfg.size
        if not snap.maleTypes[key] then maps:insert("snapGroupMaleType",snap.maleTypes,{key=key}) end
    end
end

function utils.contains(cfg,x,z,margin)
    margin=margin or 0
    local polygon=cfg.footprint
    for i,a in ipairs(polygon) do
        local b=polygon[i % #polygon+1]
        local dx,dz=b[1]-a[1],b[2]-a[2]
        if dx*(z-a[2])-dz*(x-a[1]) < margin*math.sqrt(dx*dx+dz*dz) then return false end
    end
    return true
end

function utils.points(cfg,male)
    local snap=mjrequire "common/snapGroups/snapGroup"
    local vec3=mjrequire("common/mjm").vec3
    local key=cfg.shape=="quarter" and "sl90Floor" or (cfg.shape=="right90" and "rt90Floor" or (male and "sl45Male" or "sl45Female"))
    local source=assert((male and snap.malePoints or snap.femalePoints)[key..cfg.size])
    local points=copy(source)
    for _,p in ipairs(copy(source)) do
        p.point=vec3(p.point.x,p.point.y-cfg.depth,p.point.z)
        p.heuristicOffset=nil
        points[#points+1]=p
    end
    -- Native foundations use horizontal normals even for stacking. Filtering
    -- their normals by Y therefore added no anchors. Use one centered, keyed
    -- connector so the next identical footprint is translated exactly by depth.
    local group=assert(snap.maleTypes["sp_stack_"..cfg.shape..cfg.size]).index
    points[#points+1]=male and {point=vec3(0,-cfg.depth,0),normal=vec3(0,0,1),snapGroup=group}
        or {point=vec3(0,0,0),normal=vec3(0,0,-1),maleSnapGroups={group}}
    return mjrequire("common/sl90Utils").finish(points,male)
end

local function variants(model,cfg,logs)
    local result={}
    if cfg.family=="dirt" then
        for _,key in ipairs({"dirt","richDirt","poorDirt","sand","riverSand","redSand"}) do result[key]={lightWood=key} end
        for key,map in pairs(model.remapModels.dirt or {}) do
            if type(map)=="table" and type(map.dirt)=="string" then result[key]={lightWood=map.dirt} end
        end
    else
        local family=mjrequire("common/spColumnMaterials")[cfg.family]
        for key,material in pairs(family.resources) do
            local objectKey=key
            local bark="whiteTrunk"
            if cfg.family=="wood" then
                local tree=key:match("^(.*)SplitLog$")
                local map=tree and mjrequire("common/spMaterialCompatibility").wood[tree]
                bark=map and map.trunk or bark
                if logs then objectKey=tree and tree.."Log" or nil end
            end
            if objectKey then result[objectKey]={lightWood=material,trunk=bark} end
        end
    end
    return result
end

local function base(cfg,logs)
    return cfg.key..(logs and "_log" or (cfg.family=="wood" and "_splitLog" or "_resource"))
end

function utils.models(model)
    -- Runs after all providers' onload hooks and compatibility discovery.
    -- Sorted, validated names keep deterministic indexes across game threads.
    for _,cfg in ipairs(configs) do
        for i=1,(cfg.woodShell and 2 or 1) do
            local logs=i==2
            local values=variants(model,cfg,logs)
            local keys={};for key in pairs(values) do keys[#keys+1]=key end;table.sort(keys)
            for _,key in ipairs(keys) do
                assert(key:match("^[%w_]+$") and #key<200,"Invalid shaped foundation material key")
                local name=base(cfg,logs).."_"..key
                if not model.modelIndexesByName[name] then
                    mjrequire("common/spModelAliases").cloneVariant(model,base(cfg,logs),{[name]=values[key]})
                end
            end
        end
    end
end

function utils.placeholders(p,model,gameObject,cfg)
    local resource=mjrequire "common/resource"
    local definitions={}
    for i=1,(cfg.woodShell and 2 or 1) do
        local logs=i==2
        local typeKey=logs and "log" or ({wood="splitLog",mud="mudBrickDry",brick="firedBrick"})[cfg.family]
        local groupKey=cfg.family=="dirt" and "spFoundationFill" or (cfg.family=="stone" and "stoneBlockAny" or nil)
        local mapping={}
        for key in pairs(variants(model,cfg,logs)) do
            local object=gameObject.types[key]
            local index=model.modelIndexesByName[base(cfg,logs).."_"..key]
            if object and index and (cfg.family~="dirt" or object.resourceTypeIndex==resource.types.dirt.index or object.resourceTypeIndex==resource.types.sand.index) then mapping[object.index]=index end
        end
        local default=cfg.family=="dirt" and "dirt" or mjrequire("common/spColumnMaterials")[cfg.family].default
        if logs then default="birchLog" end
        definitions[#definitions+1]={key=logs and "log_1" or "resource_1",
            defaultModelName=base(cfg,logs).."_"..default,
            resourceTypeIndex=typeKey and resource.types[typeKey].index,
            resourceGroupIndex=groupKey and resource.groups[groupKey].index,
            placeholderModelIndexForObjectTypeFunction=function(info,index) return mapping[index] or info.defaultModelIndex end}
        definitions[#definitions+1]={key=logs and "log_store" or "resource_store",offsetToStorageBoxWalkableHeight=true}
    end
    local remaps={splitLog="resource",mudBrickDry="resource",firedBrick="resource",stoneBlockAny="resource",spFoundationFill="resource"}
    p:addModel(cfg.key,definitions,remaps)
    p:addModel(cfg.key.."_low",definitions,remaps)
end
return utils
