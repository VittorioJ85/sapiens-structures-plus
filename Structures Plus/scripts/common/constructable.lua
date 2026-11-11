-- Compatibility-only parts must not reappear through native duplication.
local mod={loadOrder=70}
function mod:onload(constructable)
    local doors=mjrequire "common/spDoorUtils"
    local lookup=constructable.getConstructableTypeIndexForCloneOrRebuild
    function constructable:getConstructableTypeIndexForCloneOrRebuild(...)
        return doors.availableIndex(self,lookup(self,...))
    end
    local createMap=constructable.createGameObjectTypeIndexMap
    function constructable:createGameObjectTypeIndexMap(...)
        local result=createMap(self,...)
        -- Do not set disallowsDecorationPlacing on a saved build recipe:
        -- native mapping then resets requiredResourceTotalCount to zero.
        -- Filter only the completed suggestion lists, retaining all accounting.
        for _,indexes in pairs(self.constructablesByResourceObjectTypeIndexes) do
            for i=#indexes,1,-1 do
                if doors.availableIndex(self,indexes[i])~=indexes[i] then table.remove(indexes,i) end
            end
        end
        return result
    end
end
return mod
