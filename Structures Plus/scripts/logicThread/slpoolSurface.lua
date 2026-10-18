local water=mjrequire "common/slpoolWater"
local model=mjrequire "common/model"
local surface={objects={},lastFrame=nil,indices={}}

function surface:reset()
    -- IDs and model indices belong to the current world and cannot survive reload.
    self.objects={}
    self.lastFrame=nil
    self.indices={}
end

function surface:draw(gom,object)
    if not water:isPool(object) then self.objects[object.uniqueID]=nil;return end
    self.objects[object.uniqueID]=true
    local frame=water:frame()
    local size=water:size(object)
    local cacheKey=frame+(size==4 and water.frames or 0)
    local index=self.indices[cacheKey]
    if not index then
        index=model:modelIndexForModelNameAndDetailLevel(string.format(size==4 and "slpool4_wave%02d" or "slpool_wave%02d",frame),1)
        self.indices[cacheKey]=index
    end
    if index then
        -- Legacy slpool4_wave names now share the 2 m tile mesh. Placement comes
        -- from the same native resource nodes used by previews and construction.
        -- One phase lookup drives all four tiles; no per-tile clock or geometry.
        for i=1,(size==4 and 4 or 1) do
            local key="dirt_"..i
            local transform=gom:getSubModelTransform(object,key)
            -- Objects can unload between client callbacks. Retry next frame.
            if transform then
                gom:setSubModelForKey(object.uniqueID,key,nil,index,1,RENDER_TYPE_STATIC,transform.offsetMeters,transform.rotation,false,nil)
            end
        end
    end
end

function surface:update(gom)
    local frame=water:frame()
    if self.lastFrame==frame then return end
    self.lastFrame=frame
    for id in pairs(self.objects) do
        local object=gom:getObjectWithID(id)
        if object then self:draw(gom,object) else self.objects[id]=nil end
    end
end
return surface
