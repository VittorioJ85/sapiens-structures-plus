local mod={loadOrder=70}
function mod:onload(sequence)
    local action=mjrequire("common/action").types
    mjrequire("common/typeMaps"):insert("actionSequence",sequence.types,{key="spOperateShutters",
        actions={action.moveTo.index,action.spOperateShutters.index},assignedTriggerIndex=2})
end
return mod
