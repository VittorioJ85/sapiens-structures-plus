-- Native construction owns delivery, material selection, refunds and Rebuild.
local copy=mjrequire("common/sl45Util").copy
local doors={}

function doors.availableIndex(constructable,index)
    -- Copying a legacy combined wall creates its ordinary native doorway.
    -- Never rewrite saved objects or change their original refund recipe.
    for _,cfg in ipairs(mjrequire "common/spDoors") do
        local legacy=cfg.retired and constructable.types[cfg.key]
        if legacy and index==legacy.index then
            return assert(constructable.types[cfg.source],"Missing legacy door replacement").index
        end
    end
    return index
end

function doors.recipe(info,cfg,buildable)
    local resource=mjrequire "common/resource"
    for _,requirement in ipairs(info.requiredResources) do
        if requirement.type==resource.types.splitLog.index then
            if cfg and cfg.standalone then
                requirement.count=1
                info.requiredResources={requirement}
                info.buildSequence=buildable.bringOnlySequence
                info.checkObjectCollisions=false
                info.snapToWalkableHeight=nil
                info.countsAsSplitLogWallForTutorial=nil
                return
            end
            -- Native six split logs occupy slots 1..11 (paired wall panels).
            -- The seventh is the complete hinged leaf in slot 12.
            assert(requirement.count==6,"Automatic door requires the native six-log doorway")
            requirement.count=7
            return
        end
    end
    error("Automatic door requires split logs")
end

function doors.models(model)
    -- Called after material discovery, so compatible foreign timber is included.
    -- All species share one leaf mesh, including distant rendering.
    local materials=mjrequire("common/spColumnMaterials").wood.resources
    local names={}
    for key in pairs(materials) do names[#names+1]=key end
    table.sort(names) -- Model indices must agree across client/server threads.
    for _,base in ipairs({"spDoorLeaf","spDoorLeafCurve4","spDoorLeafCurve2"}) do
    for _,key in ipairs(names) do
        assert(key:match("^[%w_]+$") and #key<240,"Invalid door material identifier")
        local name=base.."_"..key
        if not model.modelIndexesByName[name] then
            mjrequire("common/spModelAliases").cloneVariant(model,base,
                {[name]={lightWood=materials[key]}})
        end
    end
    end
end

function doors.placeholders(placeholders,model,gameObject,cfg)
    local resource=mjrequire "common/resource"
    local mapping={}
    local base=cfg.leafModel or "spDoorLeaf"
    for key in pairs(mjrequire("common/spColumnMaterials").wood.resources) do
        local object=gameObject.types[key]
        local index=model.modelIndexesByName[base.."_"..key]
        if object and index then mapping[object.index]=index end
    end
    local definitions={
        {key=cfg.leafKey,defaultModelName=base.."_birchSplitLog",
         resourceTypeIndex=resource.types.splitLog.index,
         placeholderModelIndexForObjectTypeFunction=function(info,index)
             return mapping[index] or info.defaultModelIndex
         end},
    }
    if cfg.standalone then
        -- The insert has one resource and no wall/post placeholders to inherit.
        definitions[#definitions+1]={key="splitLog_store",offsetToStorageBoxWalkableHeight=true}
        placeholders:addModel(cfg.key,definitions)
        return
    end
    placeholders:addModel(cfg.key,definitions)
    local source=model:modelIndexForName(cfg.source)
    local target=model:modelIndexForName(cfg.key)
    local infos=placeholders.placeholderInfosByModelIndex
    local keys=placeholders.placeholderKeysByModelIndex
    local leaf=infos[target][cfg.leafKey]
    -- Copy the resolved native contract, preserving callbacks and LOD choices;
    -- never append to tables shared with the original doorway.
    infos[target]=copy(assert(infos[source],"Native doorway placeholders missing"))
    keys[target]=copy(assert(keys[source],"Native doorway keys missing"))
    assert(not infos[target][cfg.leafKey],"Native doorway now uses the door leaf slot")
    infos[target][cfg.leafKey]=leaf
    keys[target][#keys[target]+1]=cfg.leafKey
    if placeholders.resourceRemapsByModelIndex[source] then
        placeholders.resourceRemapsByModelIndex[target]=copy(placeholders.resourceRemapsByModelIndex[source])
    end
end

function doors.addSnaps(snap)
    local vec3=mjrequire("common/mjm").vec3
    local typeMaps=mjrequire "common/typeMaps"
    if not snap.maleTypes.spDoorInsert then
        typeMaps:insert("snapGroupMaleType",snap.maleTypes,{key="spDoorInsert"})
    end
    local finish=mjrequire("common/sl90Utils").finish
    for _,key in ipairs({"spDoorCurve4","spDoorCurve2"}) do
        if not snap.maleTypes[key] then typeMaps:insert("snapGroupMaleType",snap.maleTypes,{key=key}) end
        snap.malePoints[key]=finish({{point=vec3(0,-1,0),normal=vec3(0,0,1),snapGroup=snap.maleTypes[key].index}},true)
    end
    snap.malePoints.spDoorInsert=finish({{point=vec3(0,-1,0),normal=vec3(0,0,1),
        snapGroup=snap.maleTypes.spDoorInsert.index}},true)
end

function doors.attachAnchors(objects)
    -- Restrict anchors to completed compatible doorways, not every wall sharing
    -- native snap tables. Hypotenuse walls preserve the original centered door
    -- opening; only their outer panels change width. Both sizes use one insert.
    local targets={"thatchWallDoor","splitLogWallDoor","mudBrickWallDoor","stoneBlockWallDoor","brickWallDoor"}
    for _,cfg in ipairs(mjrequire "common/slHypWalls") do
        if cfg.form=="door" then targets[#targets+1]=cfg.key end
    end
    for _,key in ipairs(targets) do
        local original=objects[key]
        if original then
            local snap=mjrequire "common/snapGroups/snapGroup"
            local group=snap.maleTypes.spDoorInsert.index
            local vec3=mjrequire("common/mjm").vec3
            local info=copy(original)
            local points=info.femaleSnapPoints or {}
            if not (points.allowedMaleSnapGroupSet and points.allowedMaleSnapGroupSet[group]) then
                for _,sign in ipairs({-1,1}) do
                    points[#points+1]={point=vec3(0,0,0),normal=vec3(0,0,sign),maleSnapGroups={group}}
                end
            end
            info.femaleSnapPoints=mjrequire("common/sl90Utils").finish(points,false)
            objects[key]=info
        end
    end
    -- The flat leaf spans the chord between curved jambs. Both radii have
    -- the same half-angle because the 2 m wall scales its native opening by 1/2.
    local snap=mjrequire "common/snapGroups/snapGroup"
    local vec3=mjrequire("common/mjm").vec3
    local n=1/math.sqrt(2)
    for _,cfg in ipairs(mjrequire "common/sl90Parts") do
        if cfg.form=="door" and objects[cfg.key] then
            local info=copy(objects[cfg.key])
            local points=info.femaleSnapPoints or {}
            local group=snap.maleTypes["spDoorCurve"..cfg.size].index
            if not (points.allowedMaleSnapGroupSet and points.allowedMaleSnapGroupSet[group]) then
                local mid=cfg.size*math.cos(math.pi/16)*n-cfg.size/2
                for _,sign in ipairs({-1,1}) do
                    points[#points+1]={point=vec3(mid,0,mid),normal=vec3(sign*n,0,sign*n),maleSnapGroups={group}}
                end
            end
            info.femaleSnapPoints=mjrequire("common/sl90Utils").finish(points,false)
            objects[cfg.key]=info
        end
    end
end

return doors
