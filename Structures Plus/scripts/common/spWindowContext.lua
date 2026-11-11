-- Match registered host IDs, never dimensions guessed from a rendered model.
local context={}
function context.options(object,tribe,kind)
    local state=object and object.sharedState
    if not tribe or not state or state.tribeID~=tribe or state.inProgressConstructableTypeIndex
        or state.deconstructConstructableTypeIndex then return {} end
    local types=mjrequire("common/gameObject").types
    local result={}
    if kind=="door" then
        local target
        local function matches(key) return types[key] and types[key].index==object.objectTypeIndex end
        for _,key in ipairs({"thatchWallDoor","splitLogWallDoor","mudBrickWallDoor","stoneBlockWallDoor","brickWallDoor"}) do
            if matches(key) then target="spDoorWoodInsert" end
        end
        for _,cfg in ipairs(mjrequire "common/slHypWalls") do
            if cfg.form=="door" and matches(cfg.key) then target="spDoorWoodInsert" end
        end
        for _,cfg in ipairs(mjrequire "common/sl90Parts") do
            if cfg.form=="door" and matches(cfg.key) then target="spDoorCurve"..cfg.size end
        end
        for _,cfg in ipairs(mjrequire "common/spDoors") do
            if cfg.key==target and not cfg.retired then result[#result+1]=cfg end
        end
        return result
    end
    for _,cfg in ipairs(mjrequire "common/spWindowInserts") do
        for _,key in ipairs(cfg.hosts) do
            if types[key] and types[key].index==object.objectTypeIndex then
                result[#result+1]=cfg
                break
            end
        end
    end
    return result
end
function context.menu(helper,plans,objects,tribe)
    if not objects or #objects~=1 then return plans end
    local key
    if #context.options(objects[1],tribe)>0 then key="spBuildWindow"
    elseif #context.options(objects[1],tribe,"door")>0 then key="spBuildDoor" end
    if not key then return plans end
    local result={}
    for _,entry in ipairs(plans or {}) do result[#result+1]=entry end
    local entry={planTypeIndex=mjrequire("common/plan").types[key].index}
    helper:addPlanExtraInfo(entry,{}, {[helper:getPlanHash(entry)]=1})
    result[#result+1]=entry
    return result
end
return context
