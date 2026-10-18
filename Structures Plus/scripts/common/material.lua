local mod={loadOrder=10}
function mod:onload(material)
    if material.types.slpool_waterBlue then return end
    local vec3=mjrequire("common/mjm").vec3
    local nativeWater=assert(material.types.water, "Native water material is required")
    -- Keep the existing mesh material key, but copy the game's original water color.
    -- Do not mutate native water or share its mutable color vector.
    mj:insertIndexed(material.types,{
        key="slpool_waterBlue",color=vec3(nativeWater.color.x,nativeWater.color.y,nativeWater.color.z),
        roughness=0.23,metal=0.0
    })
end
return mod
