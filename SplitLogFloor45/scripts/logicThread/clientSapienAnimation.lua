local mod={loadOrder=50}
function mod:onload(animation)
    local water=mjrequire "common/slpoolWater"
    local gom
    local init=animation.init
    function animation:init(g,...)
        gom=g
        return init(self,g,...)
    end
    local function apply(sapien,state)
        local pool
        if not sapien.sharedState.seatObjectID then pool=water:sample(gom,state.pos or sapien.pos,true,false) end
        if pool then
            state.slpoolSwimming=true
            state.swimming=true
            state.moveToPosIsSwimming=true
            state.pos=pool.pos
            if state.goalPos then
                local goal=water:sample(gom,state.goalPos,true,false)
                if goal then state.goalPos=goal.pos end
            end
        elseif state.slpoolSwimming then
            state.slpoolSwimming=nil
            state.swimming=false
            state.moveToPosIsSwimming=false
            -- Native updateMoveToPos assumes both cache entries exist together.
            -- Invalidate the target as well so it rebuilds the pair on the next move.
            state.moveToPosAvoidingObstacles=nil
            state.moveToPosAvoidingObstaclesBasePos=nil
        end
        return pool
    end
    -- Apply after native movement, before native animation selection (walk vs swim).
    local move=animation.updateMove
    function animation:updateMove(sapien,dt,speed,actionState,state,...)
        local result=move(self,sapien,dt,speed,actionState,state,...)
        apply(sapien,state)
        return result
    end
    local update=animation.update
    function animation:update(sapien,dt,speed,state)
        apply(sapien,state)
        local result=update(self,sapien,dt,speed,state)
        if apply(sapien,state) then
            gom:updateMatrix(sapien.uniqueID,state.pos,state.rotation or sapien.rotation)
        end
        return result
    end
end
return mod
