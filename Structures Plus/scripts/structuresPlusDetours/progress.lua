local progress = {states = setmetatable({}, {__mode = "k"})}
local function meters(a,b)
    local x,y,z = a.x-b.x,a.y-b.y,a.z-b.z
    return math.sqrt(x*x+y*y+z*z)*8388608
end
local function point(p) return {x=p.x,y=p.y,z=p.z} end
function progress:shouldCancel(sapien, goal, nativeCancel)
    local shared = sapien.sharedState
    local order = shared and shared.orderQueue and shared.orderQueue[1]
    local path = shared and shared.actionState and shared.actionState.path
    local types = mjrequire "common/order"
    local plan = mjrequire "common/plan"
    local context = order and order.context
    local delivery = context and context.planTypeIndex == plan.types.build.index
        and order.orderTypeIndex == types.types.deliverObjectToConstructionObject.index
    -- Removing remaining materials is a distinct suborder with the same need
    -- to follow stairs away from the destination before approaching it again.
    -- Exclude stockpile pickups and unrelated removal/logistics orders.
    local removal = context and order.objectID and context.planObjectID == order.objectID
        and (context.planTypeIndex == plan.types.rebuild.index
            or context.planTypeIndex == plan.types.deconstruct.index)
        and order.orderTypeIndex == types.types.removeObject.index
    if not (delivery or removal)
        or not path or not path.valid or path.complete or path.inaccessible then
        self.states[sapien] = nil
        return nativeCancel
    end
    local current = self.states[sapien]
    if not current or current.orderID ~= order.sapienOrderID or current.target ~= order.objectID
        or meters(current.goal,goal)>0.1 then
        current = {orderID=order.sapienOrderID, target=order.objectID, goal=point(goal),
            previous=point(path.startPos or path.nodes[1].pos), count=0, travel=0, stalled=0, visits={}}
        self.states[sapien] = current
    end
    local distance=meters(current.previous,sapien.pos)
    current.count=current.count+1
    current.travel=current.travel+distance
    current.stalled=distance<0.5 and current.stalled+1 or 0
    local visits=0
    for _,pos in ipairs(current.visits) do
        if meters(pos,sapien.pos)<2 then visits=visits+1 end
    end
    local reason
    if current.stalled>=2 then reason="no progress"
    elseif visits>=2 then reason="repeated segment endpoint"
    elseif current.count>32 or current.travel>512 then reason="continuation budget" end
    current.previous=point(sapien.pos)
    table.insert(current.visits,point(sapien.pos))
    if #current.visits>32 then table.remove(current.visits,1) end
    if reason or nativeCancel then
        mj:log("[StructuresPlusDetours] ",reason or "allow detour", " sapien:",sapien.uniqueID,
            " target:",order.objectID," segments:",current.count," travelMeters:",current.travel)
    end
    return reason ~= nil
end
return progress
