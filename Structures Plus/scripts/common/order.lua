local mod={loadOrder=70}
function mod:onload(order)
    mjrequire("common/typeMaps"):insert("order",order.types,{key="spOperateShutters",
        name="Operate Shutters",inProgressName="Operating shutters",icon="icon_hand"})
end
return mod
