local util = {}
function util.copy(t)
    if type(t) ~= "table" then return t end
    local r = {}
    for k,v in pairs(t) do r[k] = util.copy(v) end
    return r
end
return util
