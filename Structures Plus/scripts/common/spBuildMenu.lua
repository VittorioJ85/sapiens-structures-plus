-- Menu layout only. Saved object/constructable keys and registration order stay stable.
local menu = {}

menu.groups = {
    {label="Water Blocks", root="slpool_water2x2",
        members={"slpool_water2x2", "slpool_water4x4"}},
    {label="Wood Foundations", root="spf_wood_2",
        members={"spf_wood_2", "spf_wood_1", "spf_wood_4", "spf_wood_ramp4"}},
    {label="Wood Columns",root="spc_wood",members={"spc_wood","spc_cap_wood"}},
    {label="Fired Brick Columns",root="spc_brick",members={"spc_brick","spc_cap_brick"}},
}
-- Extend native column submenus without adding duplicate main entries or
-- discarding variants supplied by the game or other mods.
menu.nativeColumnGroups={
    {root="mudBrickColumn",member="spc_cap_mud",label="Mud Brick Columns"},
    {root="stoneBlockColumn",member="spc_cap_stone",label="Stone Block Columns"},
}

local function position(list, value)
    for i, entry in ipairs(list) do
        if entry == value then return i end
    end
end

function menu.configure(constructable)
    local types = constructable.types
    for _, group in ipairs(menu.groups) do
        local root = types[group.root]
        if root then
            local indexes, memberSet = {}, {}
            for _, key in ipairs(group.members) do
                local index = assert(types[key] and types[key].index, "Missing menu member: " .. key)
                table.insert(indexes, index)
                memberSet[index] = true
            end
            -- Remove only our members, retaining native and other mods' variants.
            for _, key in ipairs({"dirtFoundation2x2", "splitLogFloor"}) do
                local parent = types[key]
                if parent and parent.variations then
                    for i = #parent.variations, 1, -1 do
                        if memberSet[parent.variations[i]] then table.remove(parent.variations, i) end
                    end
                end
            end
            root.variationGroupName = group.label
            root.variations = indexes
            root.isVariationOfConstructableTypeIndex = nil
        end
    end

    for _,group in ipairs(menu.nativeColumnGroups) do
        local root,member=types[group.root],types[group.member]
        if root and member then
            root.variations=root.variations or {root.index}
            if not position(root.variations,root.index) then table.insert(root.variations,1,root.index) end
            if not position(root.variations,member.index) then table.insert(root.variations,member.index) end
            root.variationGroupName=group.label
        end
    end

    local parent, flat, ramp = types.stoneBlockFoundation2x2, types.spf_stone_4, types.spf_stone_ramp4
    if parent and parent.variations and flat and ramp then
        local flatPosition = position(parent.variations, flat.index)
        local rampPosition = position(parent.variations, ramp.index)
        if flatPosition and rampPosition and flatPosition > rampPosition then
            parent.variations[flatPosition], parent.variations[rampPosition] = ramp.index, flat.index
        end
    end
end

function menu.addMainEntries(itemList, constructable)
    local types = constructable.types
    local anchor = types.dirtFoundation2x2
    local insertAt = anchor and position(itemList, anchor.index)
    -- A filtered menu (for example Blueprints Only) must not gain normal buildings.
    if not insertAt then return end
    for _, group in ipairs(menu.groups) do
        local root = types[group.root]
        if root then
            local existing = position(itemList, root.index)
            if existing then
                insertAt = existing
            else
                insertAt = insertAt + 1
                table.insert(itemList, insertAt, root.index)
            end
        end
    end
end

return menu
