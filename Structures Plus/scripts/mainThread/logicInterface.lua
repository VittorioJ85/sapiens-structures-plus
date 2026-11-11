local mod={loadOrder=70}
function mod:onload(logic)
    local original=logic.callServerFunction
    function logic:callServerFunction(name,data,callback,...)
        local entry=mjrequire("common/plan").types.spBuildWindow
        local door=mjrequire("common/plan").types.spBuildDoor
        local isDoor=type(data)=="table" and door and data.planTypeIndex==door.index
        if name~="addPlans" or type(data)~="table" or not (isDoor or (entry and data.planTypeIndex==entry.index)) then
            return original(self,name,data,callback,...)
        end
        -- This radial action opens local UI; it must never become an AI job.
        local ids=data.objectOrVertIDs
        local ok=false
        if not data.baseVertID and type(ids)=="table" and #ids==1 and type(ids[1])=="string" then
            local inspect=mjrequire "mainThread/ui/inspect/inspectUI"
            local selected=inspect.selectedObjectOrVertInfosByID or {}
            local ui=mjrequire "mainThread/ui/manageUI/buildUI"
            if isDoor then ok=ui:spShowDoors(selected[ids[1]])
            else ok=ui:spShowWindows(selected[ids[1]]) end
        end
        if callback then callback({ok=ok}) end
        return ok
    end
end
return mod
