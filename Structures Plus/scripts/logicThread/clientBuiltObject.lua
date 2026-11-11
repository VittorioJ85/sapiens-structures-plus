local mod={loadOrder=50}
function mod:onload(built)
    local surface=mjrequire "logicThread/slpoolSurface"
    local doors=mjrequire "logicThread/spDoorAnimation"
    local shutters=mjrequire "logicThread/spShutterAnimation"
    local gom
    local init=built.init
    function built:init(g,...)
        gom=g
        surface:reset()
        doors:reset()
        shutters:reset()
        return init(self,g,...)
    end
    local update=built.updateBuiltObjectSubModels
    function built:updateBuiltObjectSubModels(object,...)
        local result=update(self,object,...)
        if gom then
            surface:draw(gom,object)
            doors:draw(gom,object)
            shutters:draw(gom,object)
        end
        return result
    end
end
return mod
