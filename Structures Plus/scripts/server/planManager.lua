local mod={loadOrder=70}
function mod:onload(manager)
    local soil=mjrequire "common/spSoil"
    local service=mjrequire "server/spSoilServer"
    local add=manager.addBuildOrPlantPlan
    function manager:addBuildOrPlantPlan(tribe,planIndex,constructableIndex,research,pos,rotation,sapien,models,attached,...)
        local c=mjrequire("common/constructable").types[constructableIndex]
        if c and c.requiredMediumTypes and not soil.validPosition(pos) then return nil end
        if c and c.requiredMediumTypes and pos then
            local gom=mjrequire "server/serverGOM"
            local foundation=service:find(gom,pos)
            if foundation then
                if not service:canPlant(gom,foundation,tribe,c,pos) then return nil end
                attached=nil
            end
        end
        return add(self,tribe,planIndex,constructableIndex,research,pos,rotation,sapien,models,attached,...)
    end
    local rebuildPlant=manager.addBuildOrPlantPlanForRebuild
    function manager:addBuildOrPlantPlanForRebuild(id,tribe,index,...)
        local gom=mjrequire "server/serverGOM"
        local object=gom:getObjectWithID(id)
        local c=mjrequire("common/constructable").types[index]
        if object and c and c.requiredMediumTypes then
            local foundation=service:find(gom,object.pos)
            if foundation and not service:canPlant(gom,foundation,tribe,c,object.pos,id) then return nil end
        end
        return rebuildPlant(self,id,tribe,index,...)
    end
    -- Remove plants before dismantling their growing medium; no floating flora or lost seed inventory.
    for _,name in ipairs({"addDeconstructPlan","addRebuildPlan"}) do
        local original=manager[name]
        manager[name]=function(self,tribe,id,...)
            local gom=mjrequire "server/serverGOM"
            local f=gom:getObjectWithID(id)
            if soil:isFoundation(f) and #service:plants(gom,f,false)>0 then return false end
            return original(self,tribe,id,...)
        end
    end
end
return mod
