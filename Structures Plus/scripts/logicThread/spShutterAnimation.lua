-- Only loaded shutters are tracked. Persisted state comes from the server;
-- animation never runs AI, generates meshes, or searches for nearby Sapiens.
local animation={objects={}}
local m=mjrequire "common/mjm"
local util=mjrequire "common/spWindowInsertUtils"
local function config(object)
    local cfg=util.config(object)
    return cfg and cfg.style=="shutters" and cfg
end
function animation:reset() self.objects={} end
function animation:prepareLeaf(gom,id,key)
    if key~="splitLog_1" and key~="splitLog_2" then return false end
    if not config(gom:getObjectWithID(id)) then return false end
    gom:setDynamicRenderOverride(id,true)
    return true
end
local function apply(gom,object,progress,onlyKey)
    local eased=progress*progress*(3-2*progress)
    for i=1,2 do
        local key="splitLog_"..i
        local transform=(not onlyKey or key==onlyKey) and gom:getSubModelTransform(object,key)
        if transform then
            gom:setSubModelTransform(object.uniqueID,key,transform.offsetMeters,m.vec3(1,1,1),
                m.mat3Rotate(transform.rotation,(i==1 and -1 or 1)*math.pi*.52*eased,m.vec3(0,1,0)))
        end
    end
end
function animation:draw(gom,object)
    if not config(object) then return end
    local state=self.objects[object.uniqueID]
    if not state then state={progress=object.sharedState.spShuttersOpen==true and 1 or 0};self.objects[object.uniqueID]=state end
    apply(gom,object,state.progress)
end
function animation:refreshLeaf(gom,id,key)
    if key=="splitLog_1" or key=="splitLog_2" then
        local object=gom:getObjectWithID(id)
        if config(object) then
            local state=self.objects[id]
            if not state then
                state={progress=object.sharedState.spShuttersOpen==true and 1 or 0}
                self.objects[id]=state
            end
            -- The other leaf may not have been created yet.
            apply(gom,object,state.progress,key)
        end
    end
end
function animation:update(gom,dt,speed)
    local valid=mjrequire "common/spValidation"
    if not valid.isFinite(dt) or not valid.isFinite(speed) or dt<=0 or speed<=0 then return end
    local step=dt*speed/.55
    if not valid.isFinite(step) then return end
    for id,state in pairs(self.objects) do
        local object=gom:getObjectWithID(id)
        if not config(object) then
            self.objects[id]=nil
            if object then gom:setDynamicRenderOverride(id,false) end
        else
            local target=object.sharedState.spShuttersOpen==true and 1 or 0
            local old=state.progress
            state.progress=target==1 and math.min(1,old+step) or math.max(0,old-step)
            if state.progress~=old then apply(gom,object,state.progress) end
        end
    end
end
return animation
