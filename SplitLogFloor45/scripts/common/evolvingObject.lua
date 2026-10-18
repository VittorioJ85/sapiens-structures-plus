local mod={loadOrder=1}
function mod:onload(evolving)
    local original=evolving.loadDerivedEvolutions
    function evolving:loadDerivedEvolutions(...)
        -- Insert before native placed-object rules and inverse lookup tables.
        mjrequire("common/spTileVariants").evolutions(self,mjrequire "common/gameObject")
        return original(self,...)
    end
end
return mod
