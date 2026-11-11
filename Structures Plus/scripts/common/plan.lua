local mod={loadOrder=70}
function mod:onload(plan)
    local maps=mjrequire "common/typeMaps"
    for _,entry in ipairs({{key="spOpenShutters",name="Open Shutters"},{key="spCloseShutters",name="Close Shutters"}}) do
        entry.inProgress=entry.name;entry.icon="icon_hand";entry.priorityOffset=0
        entry.maxAssignCount=1
        entry.skipFinalReachableCollisionPathCheck=true
        maps:insert("plan",plan.types,entry)
    end
    -- Append to preserve the existing shutter plan IDs in saved worlds.
    maps:insert("plan",plan.types,{key="spBuildWindow",name="Build Window",inProgress="Build Window",
        icon="icon_hammer",priorityOffset=0,maxAssignCount=1})
    maps:insert("plan",plan.types,{key="spBuildDoor",name="Build Door",inProgress="Build Door",
        icon="icon_hammer",priorityOffset=0,maxAssignCount=1})
end
return mod
