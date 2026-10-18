local mod={loadOrder=70}
function mod:onload(helper)
    -- Both operations remove the growing medium. Match the server's existing guard
    -- while retaining native queued-order checks and availability calculations.
    for _,name in ipairs({"getDeconstructionPlanInfo", "getRebuildPlanInfo"}) do
        local original=helper[name]
        helper[name]=function(self,objects,tribe,disabled,reason,...)
            for _,object in ipairs(objects) do
                if mjrequire("common/spSoil"):isFoundation(object) and object.sharedState and (object.sharedState.spSoilPlantCount or 0)>0 then
                    disabled=true;reason="Remove plants and planting orders from this foundation first."
                end
            end
            return original(self,objects,tribe,disabled,reason,...)
        end
    end
end
return mod
