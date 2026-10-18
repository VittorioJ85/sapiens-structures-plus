local mod={loadOrder=1}
function mod:onload(craftable)
    local original=craftable.load
    local add=craftable.addCraftable
    local registry
    local brickRecipe
    function craftable:addCraftable(key,info)
        if key=="mudBrickWet" then
            brickRecipe=mjrequire("common/sl45Util").copy(info)
        end
        if registry and (key=="mudTileWet" or key=="firedTile") then
            return mjrequire("common/spTileVariants").craftRecipe(self,registry,add,key,info,brickRecipe)
        end
        return add(self,key,info)
    end
    function craftable:load(gameObject,...)
        -- Use the supplied registry during native initialization; requiring
        -- common/gameObject here would create a circular load dependency.
        registry=gameObject
        brickRecipe=nil
        return original(self,gameObject,...)
    end
end
return mod
