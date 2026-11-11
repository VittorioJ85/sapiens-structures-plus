-- Cosmetic hinged doors over native, permanently navigable door openings.
-- No server AI/path graph changes, persistent state or per-frame mesh rebuilds.
local m=mjrequire "common/mjm"
local valid=mjrequire "common/spValidation"
local configs=mjrequire "common/spDoors"
local doors={objects={},leaves={}}
local interval=0.15 -- Spatial queries are throttled in real time.
local holdTime=1.25 -- Simulation seconds after the approach zone becomes empty.
local duration=0.35
local angle=math.pi/2
local axis=m.vec3(0,1,0)
local renderInterval=1/30 -- Bound native static-buffer updates while swinging.

function doors:reset()
    self.objects={}
    self.leaves={}
    self.reapplying=false
end

local function config(object)
    if not object then return nil end
    local types=mjrequire("common/gameObject").types
    for _,cfg in ipairs(configs) do
        local t=types[cfg.key]
        if t and object.objectTypeIndex==t.index then return cfg end
    end
end

function doors:prepareLeaf(gom,id,key,parent,modelIndex,scale,translation,rotation,physics,nested)
    -- Cache only our completed door leaf. Native callbacks retain ownership of
    -- material selection and LOD changes; construction/frame slots pass through.
    local possible=false
    for _,cfg in ipairs(configs) do
        if cfg.leafKey==key then possible=true;break end
    end
    if not possible then return false end
    local cfg=config(gom:getObjectWithID(id))
    if not cfg or cfg.leafKey~=key then return false end
    if modelIndex then
        self.leaves[id]={key=key,parent=parent,modelIndex=modelIndex,scale=scale,
            translation=translation,rotation=rotation,physics=physics,nested=nested}
    end
    return true
end

function doors:release(gom,id,object)
    self.objects[id]=nil
    self.leaves[id]=nil
end

local function nearby(gom,object)
    local side,nearest=nil,math.huge
    local originHeight=config(object).originHeight or 0
    for _,info in ipairs(gom:getGameObjectsInSetWithinRadiusOfPos(
        gom.objectSets.sapiens,object.pos,mj:mToP(4.5)) or {}) do
        local sapien=gom:getObjectWithID(info.objectID)
        if sapien and valid.validPosition(sapien.pos) then
            local q=m.vec3xMat3(sapien.pos-object.pos,object.rotation)
            local x,y,z=mj:pToM(q.x),mj:pToM(q.y)+originHeight,mj:pToM(q.z)
            -- Include the whole leaf sweep and both approaches. Exclude Sapiens
            -- on another storey; their root position is at walking height.
            if y>=-0.65 and y<=1.1 and math.abs(x)<=1.5 and math.abs(z)<=3.5 then
                local distance=x*x+z*z
                if distance<nearest then nearest,side=distance,z>=0 and 1 or -1 end
            end
        end
    end
    return side
end

local function apply(gom,object,state)
    local leaf=doors.leaves[object.uniqueID]
    if leaf then
        if state.appliedLeaf==leaf and state.renderedProgress==state.progress then return end
        -- Native dynamic shadows omit submodels. Static batches cast shadows,
        -- but transform-only calls do not move their baked vertices. Replace
        -- just this leaf's registration, at most 30 times/s while moving.
        -- Preserve its selected timber/LOD, hinge, scale and nested metadata.
        local eased=state.progress*state.progress*(3-2*state.progress)
        gom:removeSubModelForKey(object.uniqueID,state.key)
        doors.reapplying=true
        local ok,err=pcall(gom.setSubModelForKey,gom,object.uniqueID,state.key,leaf.parent,
            leaf.modelIndex,leaf.scale,RENDER_TYPE_STATIC,leaf.translation,
            m.mat3Rotate(leaf.rotation,state.side*angle*eased,axis),leaf.physics,leaf.nested)
        doors.reapplying=false
        if not ok then error(err) end
        state.renderedProgress=state.progress
        state.appliedLeaf=leaf
        state.renderTimer=0
    end
end

function doors:refreshLeaf(gom,id,key)
    local state=self.objects[id]
    local object=state and gom:getObjectWithID(id)
    if object and config(object) and state.key==key then apply(gom,object,state) end
end

function doors:draw(gom,object)
    local cfg=config(object)
    if not cfg then self:release(gom,object.uniqueID,object);return end
    local state=self.objects[object.uniqueID]
    if not state then
        local side=nearby(gom,object)
        -- A newly streamed door must not appear closed around an occupant.
        state={key=cfg.leafKey,progress=side and 1 or 0,side=side or 1,
            occupied=side~=nil,hold=side and holdTime or 0,timer=0}
        self.objects[object.uniqueID]=state
    end
    -- Native material/LOD refreshes recreate submodels; reapply the hinge.
    apply(gom,object,state)
end

function doors:update(gom,dt,speedMultiplier)
    if not valid.isFinite(dt) or dt<=0 or not valid.isFinite(speedMultiplier)
        or speedMultiplier<=0 then return end
    local elapsed=dt*speedMultiplier
    if not valid.isFinite(elapsed) then return end
    for id,state in pairs(self.objects) do
        local object=gom:getObjectWithID(id)
        if not config(object) then
            self:release(gom,id,object)
        else
            state.timer=state.timer+dt
            if state.timer>=interval then
                state.timer=0
                local side=nearby(gom,object)
                state.occupied=side~=nil
                if side then
                    state.hold=holdTime
                    -- Never flip the hinge direction partway through a swing.
                    if state.progress==0 then state.side=side end
                end
            end
            if not state.occupied then state.hold=math.max(0,state.hold-elapsed) end
            local opening=state.occupied or state.hold>0
            -- Recheck before every closing step, including the intervening
            -- query frames. This prevents closing around a newly arrived Sapien.
            if not opening and state.progress>0 then
                local side=nearby(gom,object)
                if side then state.occupied=true;state.hold=holdTime;opening=true end
            end
            local previous=state.progress
            local step=elapsed/duration
            state.progress=opening and math.min(1,previous+step) or math.max(0,previous-step)
            state.renderTimer=(state.renderTimer or 0)+dt
            if state.progress~=state.renderedProgress and
                (state.renderTimer>=renderInterval or state.progress==0 or state.progress==1) then
                apply(gom,object,state)
            end
        end
    end
end

return doors
