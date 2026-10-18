-- Local kinematic water model. Coordinates/heights are metres in each pool's frame.
local m=mjrequire "common/mjm"
-- worldHelper is loaded by flora during gameObject initialization. Resolve the
-- object registry only at runtime to avoid a circular module load.
local physics=mjrequire "common/physics"
local physicsSets=mjrequire "common/physicsSets"
local validation=mjrequire "common/spValidation"
local parts=mjrequire "common/slpoolParts"
local water={time=0,frames=64,period=5.0,rootDepth=1.01}

function water:setTime(value)
    if validation.isFinite(value) then self.time=value end
end

function water:frame()
    local time=validation.isFinite(self.time) and self.time or 0
    return math.floor((time % self.period)/self.period*self.frames) % self.frames
end

function water:surface(x,z,animated,size)
    -- The 4 m mesh contains four 2 m tiles, shifted one metre from its center.
    -- Keep this formula synchronized with the precomputed GLB wave frames.
    if size==4 then x=x-1;z=z-1 end
    local p=animated and (2*math.pi*self:frame()/self.frames) or 0
    if not animated then return 0.03 end
    return 0.03+0.009*(math.cos(math.pi*x)+math.cos(math.pi*z))*math.cos(p)
        +0.004*(math.cos(2*math.pi*x)+math.cos(2*math.pi*z))*math.sin(2*p)
end

function water:size(object)
    if not object then return nil end
    local types=mjrequire("common/gameObject").types
    for _,cfg in ipairs(parts) do
        local objectType=types[cfg.key]
        if objectType and object.objectTypeIndex==objectType.index then return cfg.size end
    end
end

function water:isPool(object)
    return self:size(object)~=nil
end

function water:sample(gom,pos,animated,allowSurface)
    -- worldHelper can call before GOM initialization. Do not resolve gameObject then.
    if not gom or not validation.validPosition(pos) then return nil end
    local types=mjrequire("common/gameObject").types
    local indexes={}
    for _,cfg in ipairs(parts) do
        local objectType=types[cfg.key]
        if objectType then table.insert(indexes,objectType.index) end
    end
    if #indexes==0 then return nil end
    local best=nil
    for _,id in ipairs(gom:getGameObjectsOfTypesWithinRadiusOfPos(indexes,pos,mj:mToP(6.0)) or {}) do
        local object=gom:getObjectWithID(id)
        local size=self:size(object)
        if size then
            local q=m.vec3xMat3(pos-object.pos,object.rotation)
            local x,y,z=mj:pToM(q.x),mj:pToM(q.y),mj:pToM(q.z)
            -- Surface/rim walkers and seated Sapiens must not be pulled under water.
            local ceiling=allowSurface and 0.12 or -0.35
            if math.abs(x)<=size/2+0.0001 and math.abs(z)<=size/2+0.0001 and y>=-2.05 and y<=ceiling then
                local h=self:surface(x,z,animated,size)
                local up=m.mat3GetRow(object.rotation,1)
                local result={pos=pos+up*mj:mToP(h-self.rootDepth-y),surfacePos=pos+up*mj:mToP(h-y),object=object,swimming=true}
                -- A floor or terrain above the buoyancy height makes this location too shallow.
                -- Ignore this pool's navigation proxy when measuring actual solid depth.
                local hit=physics:rayTest(result.surfacePos-up*mj:mToP(0.08),result.pos-up*mj:mToP(0.08),physicsSets.walkable,object.uniqueID) or {}
                local collision=hit.hasHitObject and hit.objectCollisionPoint or (hit.hasHitTerrain and hit.terrainCollisionPoint)
                local blocked=collision and mj:pToM(m.vec3xMat3(collision-result.pos,object.rotation).y)>0.12
                if not blocked and (not best or m.length2(result.pos)>m.length2(best.pos)) then best=result end
            end
        end
    end
    return best
end
return water
