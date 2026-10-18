-- Pure validation shared by farming and water; no registry or engine side effects.
local validation = {}

function validation.isFinite(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function finiteCoordinates(pos)
    return validation.isFinite(pos.x) and validation.isFinite(pos.y) and validation.isFinite(pos.z)
end

function validation.validPosition(pos)
    local kind = type(pos)
    -- mjm vectors are LuaJIT cdata; table doubles are useful in isolated tests.
    if kind ~= "table" and kind ~= "userdata" and kind ~= "cdata" then return false end
    local ok, valid = pcall(finiteCoordinates, pos)
    return ok and valid
end

return validation
