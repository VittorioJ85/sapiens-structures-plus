local mod={loadOrder=1}
function mod:onload(resource)
    local typeMaps=mjrequire "common/typeMaps"
    local key="spFoundationFill"
    if not resource.groups[key] then
        typeMaps:insert("resourceGroup",resource.groups,{
            key=key,name="Soil or Sand",plural="Soil or Sand",
            resourceTypes={resource.types.dirt.index,resource.types.sand.index},
            displayGameObjectTypeIndex=typeMaps.types.gameObject.dirt,
        })
    end
    resource:updateGroupContainedTypesHashForAddition(resource.groups[key].index)
end
return mod
