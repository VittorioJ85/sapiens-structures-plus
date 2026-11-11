-- Server-authoritative desired states; saved plans retain native cancellation.
local shutters={}
function shutters.desired(planIndex)
    local types=mjrequire("common/plan").types
    if planIndex==types.spOpenShutters.index then return true end
    if planIndex==types.spCloseShutters.index then return false end
end
function shutters.valid(object,tribe)
    local cfg=mjrequire("common/spWindowInsertUtils").config(object)
    return tribe~=nil and cfg and cfg.style=="shutters" and object.sharedState and
        object.sharedState.tribeID==tribe and
        not object.sharedState.inProgressConstructableTypeIndex and
        not object.sharedState.deconstructConstructableTypeIndex
end
function shutters.menu(helper,plans,objects,tribe)
    if not objects or #objects~=1 or not shutters.valid(objects[1],tribe) then return plans end
    -- Native placed-object menus may already include a cancel-only fallback for
    -- our queued plan. Replace that fallback instead of displaying it twice.
    local result={}
    for _,entry in ipairs(plans or {}) do
        if shutters.desired(entry.planTypeIndex)==nil then result[#result+1]=entry end
    end
    local queued=helper:getQueuedPlanInfos(objects,tribe,false)
    for _,key in ipairs({"spOpenShutters","spCloseShutters"}) do
        local entry={planTypeIndex=mjrequire("common/plan").types[key].index}
        local available=(objects[1].sharedState.spShuttersOpen==true)~=shutters.desired(entry.planTypeIndex)
        helper:addPlanExtraInfo(entry,queued,{[helper:getPlanHash(entry)]=available and 1 or 0})
        result[#result+1]=entry
    end
    return result
end
function shutters.installPlans(manager)
    local remove=manager.removePlanStateForObject
    function manager:removePlanStateForObject(object,index,objectType,research,tribe,...)
        local result=remove(self,object,index,objectType,research,tribe,...)
        local desired=shutters.desired(index)
        if desired~=nil and shutters.valid(object,tribe) and object.sharedState.spShutterRequestedOpen==desired then
            object.sharedState:set("spShutterRequestedOpen",nil)
            mjrequire("server/serverGOM"):saveObject(object.uniqueID)
        end
        return result
    end
    local original=manager.addPlans
    function manager:addPlans(tribe,data,...)
        if type(data)~="table" then return false end
        local windowPlan=mjrequire("common/plan").types.spBuildWindow
        if windowPlan and data.planTypeIndex==windowPlan.index then return false end
        local doorPlan=mjrequire("common/plan").types.spBuildDoor
        if doorPlan and data.planTypeIndex==doorPlan.index then return false end
        local desired=shutters.desired(data.planTypeIndex)
        if desired==nil then return original(self,tribe,data,...) end
        -- Never forward user-controlled extra plan fields to the native state.
        local ids=data.objectOrVertIDs
        if data.baseVertID or type(ids)~="table" or #ids~=1 or type(ids[1])~="string"
            or #ids[1]==0 or #ids[1]>128 or ids[1]:find("[:%c%s]") then return false end
        local object=mjrequire("server/serverGOM"):getObjectWithID(ids[1])
        if not shutters.valid(object,tribe) then return false end
        local types=mjrequire("common/plan").types
        local opposite=desired and types.spCloseShutters.index or types.spOpenShutters.index
        self:removePlanStateForObject(object,opposite,nil,nil,tribe)
        -- Persist explicit player intent. Availability queries, proximity and
        -- stale saved jobs cannot authorize a new shutter movement.
        local alreadySet=(object.sharedState.spShuttersOpen==true)==desired
        if alreadySet then
            object.sharedState:set("spShutterRequestedOpen",nil)
        else
            object.sharedState:set("spShutterRequestedOpen",desired)
        end
        mjrequire("server/serverGOM"):saveObject(object.uniqueID)
        if alreadySet then return true end
        self:addStandardPlan(tribe,data.planTypeIndex,object.uniqueID)
        return true
    end
end
function shutters.complete(sapien,object,state)
    local tribe=sapien.sharedState.tribeID
    local index=state.context and state.context.planTypeIndex
    local desired=shutters.desired(index)
    if desired==nil or not shutters.valid(object,tribe) then return false end
    if object.sharedState.spShutterRequestedOpen~=desired then return false end
    local manager=mjrequire "server/planManager"
    -- A cancelled/replaced job must not apply its old state on the last frame.
    local found=false
    for _,p in pairs((object.sharedState.planStates or {})[tribe] or {}) do
        if p.planTypeIndex==index then found=true end
    end
    if not found then return false end
    local m=mjrequire "common/mjm"
    if m.length2(sapien.pos-object.pos)>mj:mToP(2.5)^2 then return false end
    object.sharedState:set("spShuttersOpen",desired)
    object.sharedState:set("spShutterRequestedOpen",nil)
    mjrequire("server/serverGOM"):saveObject(object.uniqueID)
    manager:removePlanStateForObject(object,index,nil,nil,tribe)
    return true
end
return shutters
