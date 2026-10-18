local mod = {loadOrder = 70}
function mod:onload(terrain)
    local covered = mjrequire "server/spCoveredTerrain"
    local gom
    local setServerGOM = terrain.setServerGOM
    function terrain:setServerGOM(value, ...)
        gom = value
        return setServerGOM(self, value, ...)
    end
    local needsCleared = terrain.vertNeedsClearedForBuildingPlacement
    function terrain:vertNeedsClearedForBuildingPlacement(vertID)
        local needed = needsCleared(self, vertID)
        if not needed or not gom then return needed end
        local vert = self:getVertWithID(vertID)
        if vert and covered:foundationAt(gom, vert.pos) then return false end
        return needed
    end
end
return mod
