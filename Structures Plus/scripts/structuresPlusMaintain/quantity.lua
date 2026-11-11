-- Native text-entry replacement for the crafting quantity slider. Vittorio.
local entry = mjrequire "mainThread/ui/uiCommon/uiTextEntry"
local mjm = mjrequire "common/mjm"
local quantity = {}

function quantity.parse(text, maximum)
    if type(text) ~= "string" or not text:match("^%d+$") or #text > 6 then return nil end
    local value = tonumber(text)
    if not value or value >= maximum then return nil end
    return value == 0 and maximum or value
end

function quantity:create(parent, size, minimum, maximum, initial, options, changed)
    local view = entry:create(parent, mjm.vec2(size.x, 30), nil, nil,
        "Crafting batches (1-999999). Enter 0 for continuous crafting. Item totals are shown beside the field.")
    local state = {value=initial, maximum=maximum, changed=changed}
    view.userData.spCraftQuantity = state
    entry:setMaxChars(view, 6)
    entry:setAllowsEmpty(view, true)
    entry:setText(view, tostring(initial))
    -- Commit only complete digit strings. Invalid or cancelled edits restore
    -- the previous quantity; no fractional, negative or exponent input reaches
    -- the crafting order. Native editing consumes keyboard shortcuts.
    entry:setFunction(view, function(text, confirmed)
        local value = confirmed ~= false and quantity.parse(text, maximum) or nil
        if value then state.value=value;changed(value) end
        entry:setText(view, state.value == maximum and "0" or tostring(state.value))
    end)
    local tooltip = mjrequire "mainThread/ui/uiCommon/uiToolTip"
    tooltip:add(view, ViewPosition(MJPositionCenter, MJPositionBelow),
        "Enter crafting batches (1-999999), then press Enter. Item totals are shown beside the field. 0 = continuous crafting.",
        nil, mjm.vec3(0,-8,10), nil, view, nil)
    return view
end

function quantity:setValue(view, value)
    if entry:isEditing(view) then entry:finishEditing(view, false) end
    view.userData.spCraftQuantity.value = value
    entry:setText(view, tostring(value))
end

function quantity:finishEditing(view, confirmed)
    if view and entry:isEditing(view) then
        entry:finishEditing(view, confirmed)
        return true
    end
    return false
end
return quantity
