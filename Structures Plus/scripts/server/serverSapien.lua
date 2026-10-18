local mod = {loadOrder = 70}
function mod:onload(serverSapien)
    local covered = mjrequire "server/spCoveredTerrain"
    local gom
    local init = serverSapien.init
    function serverSapien:init(value, ...)
        gom = value
        return init(self, value, ...)
    end
    local requestPath = serverSapien.requestPathUpdateIfNotRequested
    function serverSapien:requestPathUpdateIfNotRequested(sapien)
        local shared = sapien.sharedState
        local current = shared and shared.orderQueue and shared.orderQueue[1]
        local context = current and current.context
        -- Release only the obsolete construction suborder using native cleanup.
        -- Manual terrain clearing, resource hauling, and the build plan survive.
        if gom and context and context.planObjectID
            and context.planTypeIndex == mjrequire("common/plan").types.build.index
            and current.orderTypeIndex == mjrequire("common/order").types.clear.index then
            local target = gom:getObjectWithID(current.objectID)
            local proxyType = mjrequire("common/gameObject").types.terrainModificationProxy
            if target and proxyType and target.objectTypeIndex == proxyType.index
                and covered:foundationAt(gom, target.pos) then
                return self:cancelOrderAtQueueIndex(sapien, 1, false)
            end
        end
        return requestPath(self, sapien)
    end
end
return mod
