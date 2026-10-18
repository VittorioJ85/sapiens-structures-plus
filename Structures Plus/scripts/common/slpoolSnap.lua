local util={}
function util.points(snap,male)
    local copy=mjrequire("common/sl45Util").copy
    local vec3=mjrequire("common/mjm").vec3
    local points=copy(male and snap.malePoints.foundation2x2MaleSnapPoints or snap.femalePoints.foundation2x2FemaleSnapPoints)
    for _,p in ipairs(points) do p.point=vec3(p.point.x*2,p.point.y,p.point.z*2) end
    local floor=male and snap.malePoints.floor4x4MaleSnapPoints or snap.femalePoints.floor4x4FemaleSnapPoints
    for _,p in ipairs(copy(floor)) do table.insert(points,p) end
    return mjrequire("common/sl90Utils").finish(points,male)
end
return util
