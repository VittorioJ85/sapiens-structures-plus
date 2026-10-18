local mod = {loadOrder=70}

function mod:onload(buildUI)
    local constructable = mjrequire "common/constructable"
    local menu = mjrequire "common/spBuildMenu"
    local createItemList = buildUI.createItemList
    function buildUI.createItemList(...)
        -- Hammerstone may call predecessors without a receiver. Capture the module
        -- as vanilla does, and forward either the dot or colon calling convention.
        local result = createItemList(...)
        -- Native buildUI uses each root's in-progress object as the grid preview.
        -- Each root is a real part with its own preview camera and material slots.
        menu.addMainEntries(buildUI.itemList, constructable)
        return result
    end
end

return mod
