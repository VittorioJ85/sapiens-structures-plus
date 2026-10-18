local soil=mjrequire "common/spSoil"
local service={}
function service:find(gom,pos)
    if not soil.validPosition(pos) then return nil end
    local go=mjrequire "common/gameObject"
    local t=go.types[soil.key]
    if not t then return nil end
    for _,id in ipairs(gom:getGameObjectsOfTypesWithinRadiusOfPos({t.index},pos,mj:mToP(4)) or {}) do
        local object=gom:getObjectWithID(id)
        if soil:isFoundation(object) and soil:contains(object,pos) then
            gom:ensureSharedStateLoaded(object)
            return object
        end
    end
end
function service:forPlant(gom,object)
    if not object or not soil:plantInfo(object.objectTypeIndex) then return nil end
    local id=object.privateState and object.privateState.spSoilFoundationID
    if id then
        local f=gom:getObjectWithIDLoadingAreaIfNeeded(id,object.pos)
        -- Private association is a hint, not authority: moved or stale plants must not
        -- consume soil from an unrelated foundation after loading an old save.
        if soil:isFoundation(f) and soil:contains(f,object.pos) then gom:ensureSharedStateLoaded(f);return f end
    end
    return self:find(gom,object.pos)
end
function service:plants(gom,foundation,treesOnly)
    if not self.plantIndexes then
        self.plantIndexes={}
        for _,t in ipairs(mjrequire("common/gameObject").validTypes) do
            if soil:plantInfo(t.index) then table.insert(self.plantIndexes,t.index) end
        end
    end
    local result={}
    for _,id in ipairs(gom:getGameObjectsOfTypesWithinRadiusOfPos(self.plantIndexes,foundation.pos,mj:mToP(4)) or {}) do
        local p=gom:getObjectWithID(id)
        if p and soil:contains(foundation,p.pos) and (not treesOnly or soil:isTree(p.objectTypeIndex)) then table.insert(result,p) end
    end
    return result
end
function service:refresh(gom,foundation)
    if foundation and soil:isFoundation(foundation) then
        local count=#self:plants(gom,foundation,false)
        if foundation.sharedState.spSoilPlantCount~=count then
            foundation.sharedState:set("spSoilPlantCount",count)
            gom:saveObject(foundation.uniqueID)
        end
    end
end

-- The same server authority rules apply to new plants and chop/replant orders.
-- UI collision checks are advisory; clients cannot bypass these checks.
function service:canPlant(gom,foundation,tribe,constructable,pos,ignorePlantID)
    if not tribe or foundation.sharedState.tribeID~=tribe then return false end
    local plan=mjrequire "common/plan"
    for _,plans in pairs(foundation.sharedState.planStates or {}) do
        for _,p in ipairs(plans) do
            if p.planTypeIndex==plan.types.deconstruct.index or p.planTypeIndex==plan.types.rebuild.index then return false end
        end
    end
    local final=mjrequire("common/gameObject").types[constructable.finalGameObjectTypeKey]
    if not final or not soil:plantInfo(final.index) then return false end
    if soil:isTree(final.index) then
        for _,tree in ipairs(self:plants(gom,foundation,true)) do
            if tree.uniqueID~=ignorePlantID then return false end
        end
    end
    -- Check the exposed support on the server as well as in the placement preview.
    local m=mjrequire "common/mjm"
    local up=m.mat3GetRow(foundation.rotation,1)*mj:mToP(0.1)
    local hit=mjrequire("common/physics"):rayTest(pos+up,pos-up,nil,ignorePlantID)
    return hit and hit.hasHitObject and hit.objectID==foundation.uniqueID
end

function service:harvest(gom,foundation,amount)
    local constants=mjrequire "common/gameConstants"
    local threshold=constants.harvestCountForSoilFertilityDegredation
    if not soil.isFinite(amount) or amount<=0 or not soil.isFinite(threshold) or threshold<1 then return false end
    local offset=foundation.sharedState.spSoilFertilityOffset
    if not soil.isFinite(offset) or offset<0 then
        offset=mjrequire("common/randomNumberGenerator"):integerForUniqueID(foundation.uniqueID,285,math.floor(threshold*0.75))
    end
    offset=offset+amount
    if not soil.isFinite(offset) then return false end
    -- Bounded work even if a save or another mod provides an extreme offset.
    local steps=math.floor(offset/threshold)
    offset=math.fmod(offset,threshold)
    if steps>0 then
        foundation.sharedState:set("constructionObjects",soil:degradedItems(foundation.sharedState.constructionObjects,steps))
    end
    foundation.sharedState:set("spSoilFertilityOffset",offset)
    gom:saveObject(foundation.uniqueID)
    if steps>0 then
        local flora=mjrequire "server/objects/serverFlora"
        for _,p in ipairs(self:plants(gom,foundation,false)) do
            if mjrequire("common/gameObject").types[p.objectTypeIndex].isSapling then flora:updateForChangedSoilQuality(p) end
        end
    end
end
return service
