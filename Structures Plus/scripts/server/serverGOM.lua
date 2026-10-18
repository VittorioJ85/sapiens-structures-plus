-- Engine callbacks: keep these wrappers even when static reference scans find
-- no Lua callers. Do not import serverGOM from inside its own onload hook.
local mod={loadOrder=70}
function mod:onload(gom)
    local soil=mjrequire "common/spSoil"
    local service=mjrequire "server/spSoilServer"
    local harvest=gom.decreaseSoilFertilityForObjectHarvest
    function gom:decreaseSoilFertilityForObjectHarvest(object,amount)
        local foundation=service:forPlant(self,object)
        if foundation then return service:harvest(self,foundation,amount) end
        return harvest(self,object,amount)
    end
    local create=gom.createGameObject
    function gom:createGameObject(info)
        local foundation=soil:plantInfo(info.objectTypeIndex) and service:find(self,info.pos)
        if foundation then
            info.privateState=info.privateState or {}
            info.privateState.spSoilFoundationID=foundation.uniqueID
            info.privateState.attachedToTerrain=nil
        end
        local id=create(self,info)
        if id and foundation then service:refresh(self,foundation) end
        return id
    end
    local remove=gom.removeGameObject
    function gom:removeGameObject(id)
        local object=self:getObjectWithID(id)
        local foundation=object and service:forPlant(self,object)
        local result=remove(self,id)
        if foundation then service:refresh(self,foundation) end
        return result
    end

    -- Integrated pool movement shares this entry point with soil callbacks.
    -- Resolve the object registry at runtime, never while gameObject is loading.
    local water=mjrequire "common/slpoolWater"
    local setPos=gom.setPos
    function gom:setPos(id,pos,updatePhysics)
        local object=self:getObjectWithID(id)
        local sapienType=mjrequire("common/gameObject").types.sapien
        if object and sapienType and object.objectTypeIndex==sapienType.index
            and not (object.sharedState and object.sharedState.seatObjectID) then
            local pool=water:sample(self,pos,false,false)
            if pool then pos=pool.pos end
        end
        return setPos(self,id,pos,updatePhysics)
    end
end
return mod
