-- Keep an in-flight rebuild/deconstruction removal with its current worker.
-- Straight-line proximity cannot rank routes through multi-storey buildings.
local claim = {}
function claim.install(serverSapien, getGOM)
    local plan = mjrequire "common/plan"
    local order = mjrequire "common/order"
    local original = serverSapien.getInfoForPlanObjectSapienAssignment
    function serverSapien:getInfoForPlanObjectSapienAssignment(object, sapien, planTypeIndex)
        local info = original(self, object, sapien, planTypeIndex)
        if not (info and info.available and info.assignedSapienID
            and (planTypeIndex == plan.types.rebuild.index or planTypeIndex == plan.types.deconstruct.index)
            and sapien.sharedState.manualAssignedPlanObject ~= object.uniqueID) then
            return info
        end
        local gom = getGOM()
        local assigned = gom and gom:getObjectWithID(info.assignedSapienID)
        local shared = assigned and assigned.sharedState
        local current = shared and shared.orderQueue and shared.orderQueue[1]
        local context = current and current.context
        -- Do not retain stale claims, unrelated tasks or queued future work.
        -- Native cancellation, completion and manual reassignment remain intact.
        if current and current.orderTypeIndex == order.types.removeObject.index
            and current.objectID == object.uniqueID and context
            and context.planObjectID == object.uniqueID and context.planTypeIndex == planTypeIndex then
            info.available = false
        end
        return info
    end
end
return claim
