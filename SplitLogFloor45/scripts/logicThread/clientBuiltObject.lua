local mod={loadOrder=50}
function mod:onload(built)
    local surface=mjrequire "logicThread/slpoolSurface"
    local gom
    local init=built.init
    function built:init(g,...)
        gom=g
        surface:reset()
        return init(self,g,...)
    end
    local update=built.updateBuiltObjectSubModels
    function built:updateBuiltObjectSubModels(object,...)
        local result=update(self,object,...)
        if gom then surface:draw(gom,object) end
        return result
    end
end
return mod
