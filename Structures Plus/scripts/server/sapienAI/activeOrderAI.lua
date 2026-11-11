local mod={loadOrder=70}
function mod:onload(ai)
    ai.updateInfos[mjrequire("common/action").types.spOperateShutters.index]={
        checkFrequency=1.2,allowCompletionWithoutSkill=true,
        completionFunction=function(allowed,sapien,object,state)
            if allowed then mjrequire("common/spShutters").complete(sapien,object,state) end
        end,
    }
end
return mod
