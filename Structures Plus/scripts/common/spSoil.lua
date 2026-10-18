-- Shared geometry and resource rules. Resolve gameObject only after its mjInit.
local m=mjrequire "common/mjm"
local soil={key="spf_dirt_4",margin=0.08,heightTolerance=0.18}
local qualityRanks={richDirt=3,dirt=2,poorDirt=1,sand=0,riverSand=0,redSand=0}
local depletedKeys={richDirt="dirt",dirt="poorDirt"}

local validation=mjrequire "common/spValidation"
soil.isFinite=validation.isFinite
soil.validPosition=validation.validPosition
function soil:isFoundation(object)
    local t=mjrequire("common/gameObject").types[self.key]
    return object and t and object.objectTypeIndex==t.index
end
function soil:contains(foundation,pos)
    if not foundation or not soil.validPosition(pos) or not foundation.pos or not foundation.rotation then return false end
    local q=m.vec3xMat3(pos-foundation.pos,foundation.rotation)
    return math.abs(mj:pToM(q.x))<=2-self.margin and math.abs(mj:pToM(q.z))<=2-self.margin
        and math.abs(mj:pToM(q.y))<=self.heightTolerance
end
function soil:plantInfo(typeIndex)
    local go=mjrequire "common/gameObject"
    local t=go.types[typeIndex]
    if not t or type(t.key)~="string" then return nil end
    if t.key:sub(1,6)=="plant_" then t=go.types["sapling_"..t.key:sub(7)] end
    if not t or not t.floraTypeIndex then return nil end
    return mjrequire("common/flora").types[t.floraTypeIndex]
end
function soil:isTree(typeIndex)
    local f=self:plantInfo(typeIndex)
    return f and f.requiresAxeToChop or false
end
function soil:quality(foundation)
    local go=mjrequire "common/gameObject"
    local flora=mjrequire "common/flora"
    local rank=3;local found=false
    for _,item in ipairs((foundation.sharedState or {}).constructionObjects or {}) do
        local t=go.types[item.objectTypeIndex]
        local r=t and qualityRanks[t.key]
        if t and r==nil then
            local resource=mjrequire "common/resource"
            if t.resourceTypeIndex==resource.types.sand.index then r=0
            elseif t.resourceTypeIndex==resource.types.dirt.index then r=2 end
        end
        if r then rank=math.min(rank,r);found=true end
    end
    -- Mixed fill uses its poorest constituent. Native sand is veryPoor (rank 0),
    -- remains sand on harvest, and is never converted into reclaimable dirt.
    -- Missing legacy inventories retain the normal-soil fallback.
    if not found then rank=2 end
    return ({[0]=flora.soilQualities.veryPoor,flora.soilQualities.poor,flora.soilQualities.normal,flora.soilQualities.rich})[rank]
end
function soil:degradedItems(items,steps)
    local go=mjrequire "common/gameObject"
    local copy=mjrequire("common/sl45Util").copy
    local result=copy(items or {})
    -- There are only two possible transitions, regardless of accumulated harvests.
    for _=1,math.min(steps or 1,2) do
        for _,item in ipairs(result) do
            local t=go.types[item.objectTypeIndex]
            local nextKey=t and depletedKeys[t.key]
            if nextKey then item.objectTypeIndex=go.types[nextKey].index end
        end
    end
    return result
end
return soil
