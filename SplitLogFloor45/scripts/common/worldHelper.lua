local mod={loadOrder=50}
function mod:onload(helper)
    local water=mjrequire "common/slpoolWater"
    local gom
    local setGOM=helper.setGOM
    function helper:setGOM(g,...)
        gom=g
        return setGOM(self,g,...)
    end
    local sanitize=helper.getSantizedMoveToPos
    -- Keep the native API's spelling; this name is called by the engine.
    function helper:getSantizedMoveToPos(pos)
        local pool=water:sample(gom,pos,false,true)
        if pool then return pool.pos end
        return sanitize(self,pos)
    end
end
return mod
