local mod={loadOrder=70}
function mod:onload(ai)
    local plan=mjrequire("common/plan").types
    local shutters=mjrequire "common/spShutters"
    local function create(sapien,info)
        if info.lastHeldObjectInfo or not shutters.valid(info.orderObject,sapien.sharedState.tribeID) then return nil end
        return {orderTypeIndex=mjrequire("common/order").types.spOperateShutters.index,
            -- Like native fixture operation, approach a reachable walk node but
            -- do not reject the final touch ray against the enclosing wall.
            proximityType=mjrequire("common/pathFinding").proximityTypes.reachableWithoutFinalCollisionTest,
            pathProximityDistance=mj:mToP(1.4)}
    end
    -- Use the native plan scheduler, pathfinding, job ownership and retries.
    -- No periodic global Sapien scan or additional network endpoint is needed.
    ai.creationFunctionsByPlanTypeIndex[plan.spOpenShutters.index]=create
    ai.creationFunctionsByPlanTypeIndex[plan.spCloseShutters.index]=create
end
return mod
