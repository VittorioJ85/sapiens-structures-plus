-- Preview-only adaptation: vanilla planting expects a terrain growMedium hit.
-- Server placement independently verifies ownership, support and tree capacity.
-- Other ray queries and collisions with objects besides the support stay native.
local mod={loadOrder=70}
function mod:onload(ui)
    local m=mjrequire "common/mjm"
    local soil=mjrequire "common/spSoil"
    local constructable=mjrequire "common/constructable"
    local selected
    local show=ui.show
    function ui:show(index,...)
        selected=constructable.types[index]
        return show(self,index,...)
    end
    local hide=ui.hide
    function ui:hide(...)
        selected=nil
        return hide(self,...)
    end
    local function planting() return selected and selected.requiredMediumTypes end
    local init=ui.init
    function ui:init(gameUI,world,...)
        if not world.spSoilInstalled then
            world.spSoilInstalled=true
            local function nearby(pos)
                return world:boxTest(pos,m.mat3Identity,m.vec3(4,4,4)*mj:mToP(1),nil,nil).objectHits or {}
            end
            local function support(pos,hits)
                for _,f in ipairs(hits or nearby(pos)) do
                    if soil:isFoundation(f) and soil:contains(f,pos) then return f end
                end
            end
            local ray=world.rayTest
            function world:rayTest(startPos,endPos,key,...)
                local result=ray(self,startPos,endPos,key,...)
                if key=="growMedium" and planting() then
                    local pos=(startPos+endPos)*0.5
                    local hits=nearby(pos)
                    local f=support(pos,hits)
                    if f then
                        -- An actual surface hit is required: planting through another floor is forbidden.
                        local surface=ray(self,startPos,endPos,nil,nil,false)
                        if surface.hasHitObject and surface.objectID==f.uniqueID then
                            local go=mjrequire "common/gameObject"
                            local final=go.types[selected.finalGameObjectTypeKey]
                            if final and soil:isTree(final.index) then
                                for _,p in ipairs(hits) do
                                    if soil:isTree(p.objectTypeIndex) and soil:contains(f,p.pos) then
                                        return {hasHitObject=true,hasHitTerrain=false}
                                    end
                                end
                            end
                            local base=mjrequire("common/terrainTypes").baseTypes.dirt.index
                            -- All native plantable species are supported. Growth uses the real soil on the server.
                            if not selected.requiredMediumTypes[base] then
                                for index,allowed in pairs(selected.requiredMediumTypes) do if allowed then base=index;break end end
                            end
                            return {hasHitTerrain=true,hasHitObject=false,minLevel=mj.SUBDIVISIONS-1,baseType=base,
                                terrainCollisionPoint=surface.objectCollisionPoint}
                        end
                    end
                end
                return result
            end
            local test=world.modelTest
            function world:modelTest(pos,rotation,scale,index,key,...)
                local result=test(self,pos,rotation,scale,index,key,...)
                if planting() and key=="placeCollide" and result.hasHitObject then
                    local f=support(pos)
                    if f then
                        local hits={}
                        for _,hit in ipairs(result.objectHits or {}) do if hit.uniqueID~=f.uniqueID then table.insert(hits,hit) end end
                        result.objectHits=hits;result.hasHitObject=#hits>0
                    end
                end
                return result
            end
        end
        return init(self,gameUI,world,...)
    end
end
return mod
