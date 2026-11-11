local mod = {loadOrder = 70}
function mod:onload(clientSapien)
    local rng = mjrequire "common/randomNumberGenerator"
    local gom
    local init = clientSapien.init
    function clientSapien:init(value, ...)
        gom = value
        return init(self, value, ...)
    end
    local update = clientSapien.update
    local reported = false
    function clientSapien:update(sapien, ...)
        -- getClientState can create a default state without the timers normally
        -- set by objectWasLoaded. Repair only missing timers, never replay the
        -- load callback (which also changes animation and follower state).
        local state = gom and gom:getClientState(sapien)
        if state then
            local repaired = false
            if state.infrequentUpdateTimer == nil then
                state.infrequentUpdateTimer = 0.0
                repaired = true
            end
            if state.infrequentUpdateRandomWait == nil then
                state.infrequentUpdateRandomWait = 0.5 + rng:randomValue() * 1.0
                repaired = true
            end
            if repaired and not reported then
                reported = true
                mj:log("[StructuresPlus] initialized missing client sapien timers; sapien:", sapien.uniqueID)
            end
        end
        -- Do not suppress unrelated failures or skip the native update.
        return update(self, sapien, ...)
    end
end
return mod
