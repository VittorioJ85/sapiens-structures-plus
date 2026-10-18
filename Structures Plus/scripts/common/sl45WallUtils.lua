
local util=mjrequire "common/sl45Util"
local vec3=mjrequire("common/mjm").vec3
local result={}
function result.scalePoints(points,factor)
    local new=util.copy(points)
    for _,entry in ipairs(new) do entry.point=vec3(entry.point.x*factor,entry.point.y,entry.point.z) end
    return new
end
return result
