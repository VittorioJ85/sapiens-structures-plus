local mod={loadOrder=50}
function mod:onload(gom)
    local water=mjrequire "common/slpoolWater"
    local surface=mjrequire "logicThread/slpoolSurface"
    local doors=mjrequire "logicThread/spDoorAnimation"
    local shutters=mjrequire "logicThread/spShutterAnimation"
    local setSubModel=gom.setSubModelForKey
    function gom:setSubModelForKey(id,key,parent,modelIndex,scale,renderType,translation,rotation,physics,nested)
        local door=not doors.reapplying and doors:prepareLeaf(self,id,key,parent,modelIndex,scale,translation,rotation,physics,nested)
        if door then renderType=RENDER_TYPE_STATIC
        elseif shutters:prepareLeaf(self,id,key) then renderType=RENDER_TYPE_DYNAMIC end
        local result=setSubModel(self,id,key,parent,modelIndex,scale,renderType,translation,rotation,physics,nested)
        if not doors.reapplying then doors:refreshLeaf(self,id,key) end
        -- Hover/LOD/resource refreshes can replace individual leaves outside the
        -- completed-object callback. Restore their pose even while paused.
        shutters:refreshLeaf(self,id,key)
        return result
    end
    local update=gom.update
    function gom:update(dt,worldTime,speedMultiplier)
        water:setTime(worldTime)
        local result=update(self,dt,worldTime,speedMultiplier)
        surface:update(self)
        doors:update(self,dt,speedMultiplier)
        shutters:update(self,dt,speedMultiplier)
        return result
    end
end
return mod
