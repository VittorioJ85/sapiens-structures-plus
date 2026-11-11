-- Building inventories use the construction interaction radius. Their origin
-- can be farther from a walkable edge than an ordinary loose-item pickup.
local reach = {}
function reach:distance(object, orderTypeIndex, planTypeIndex, context)
    local plan = mjrequire "common/plan"
    local order = mjrequire "common/order"
    local gameObject = mjrequire "common/gameObject"
    local inventory = mjrequire "common/objectInventory"
    local constants = mjrequire "common/gameConstants"
    local objectType = object and gameObject.types[object.objectTypeIndex]
    if objectType and objectType.isInProgressBuildObject
        and orderTypeIndex == order.types.removeObject.index
        and (planTypeIndex == plan.types.rebuild.index or planTypeIndex == plan.types.deconstruct.index)
        and context and context.inventoryLocation == inventory.locations.availableResource.index
        and not context.storageAreaTransferInfo then
        return constants.buildPathProximityDistance
    end
end
function reach:adjustCreated(info, assignment)
    if not info or not assignment then return end
    local object = info.orderObject or assignment.orderObject
    local context = info.orderContext
    if context and context.planObjectID and (not object or context.planObjectID ~= object.uniqueID) then return end
    local distance = self:distance(object, info.orderTypeIndex, assignment.planTypeIndex, context)
    if distance then
        info.pathProximityDistance = math.max(info.pathProximityDistance or 0, distance)
    end
end
function reach:adjustQueued(sapien, gom)
    local shared = sapien.sharedState
    local current = shared and shared.orderQueue and shared.orderQueue[1]
    local context = current and current.context
    local path = current and current.pathInfo
    if not (gom and context and path and current.objectID and context.planObjectID == current.objectID) then return end
    local object = gom:getObjectWithID(current.objectID)
    local distance = self:distance(object, current.orderTypeIndex, context.planTypeIndex, context)
    if distance and (path.proximityDistance or 0) < distance then
        -- Also upgrade persisted suborders; keep the native destination and all
        -- collision/proximity checks, and use the normal shared-state setter.
        shared:set("orderQueue", 1, "pathInfo", "proximityDistance", distance)
    end
end
return reach
