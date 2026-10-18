-- Capture the initialized GOM through the native lifecycle, avoiding load cycles.
-- Only the growth medium changes; timing, fruit and season callbacks stay native.
local mod={loadOrder=70}
function mod:onload(flora)
    local gom
    local init=flora.init
    function flora:init(gom_,...)
        gom=gom_
        return init(self,gom_,...)
    end
    local growth=flora.getGrowthMediumQuality
    function flora:getGrowthMediumQuality(object)
        if gom then
            local foundation=mjrequire("server/spSoilServer"):forPlant(gom,object)
            if foundation then return mjrequire("common/spSoil"):quality(foundation) end
        end
        return growth(self,object)
    end
end
return mod
