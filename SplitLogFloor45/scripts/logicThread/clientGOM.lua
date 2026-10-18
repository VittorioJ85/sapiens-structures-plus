local mod={loadOrder=50}
function mod:onload(gom)
    local water=mjrequire "common/slpoolWater"
    local surface=mjrequire "logicThread/slpoolSurface"
    local update=gom.update
    function gom:update(dt,worldTime,speedMultiplier)
        water:setTime(worldTime)
        local result=update(self,dt,worldTime,speedMultiplier)
        surface:update(self)
        return result
    end
end
return mod
