local mod={loadOrder=70}
function mod:onload(action)
    mjrequire("common/typeMaps"):insert("action",action.types,{key="spOperateShutters",
        name="Operate Shutters",inProgress="Operating shutters",restNeedModifier=0})
end
return mod
