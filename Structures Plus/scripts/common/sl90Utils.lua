-- Wrap native wall X coordinates around a quarter-circle in the XZ plane.
-- Recompute membership sets after transforming/removing snap groups.
local util=mjrequire "common/sl45Util"
local vec3=mjrequire("common/mjm").vec3
local result={}
function result.finish(points,male)
    if male then points.maleSnapGroupSet={} else points.allowedMaleSnapGroupSet={} end
    for _,e in ipairs(points) do
        if male then points.maleSnapGroupSet[e.snapGroup]=true
        else
            e.allowedMaleSnapGroupSet={}
            for _,g in ipairs(e.maleSnapGroups) do e.allowedMaleSnapGroupSet[g]=true;points.allowedMaleSnapGroupSet[g]=true end
        end
    end
    return points
end
function result.wallPoints(points,r,male,height,horizontalScale)
    local snap=mjrequire "common/snapGroups/snapGroup"
    local replace={}
    for _,prefix in ipairs({"wall","thinWall"}) do
        for _,edge in ipairs({"Bottom","Top"}) do
            replace[snap.maleTypes[prefix.."Middle"..edge.."Z"].index]=snap.maleTypes["sl90Wall"..r..edge].index
        end
    end
    local new={}
    for _,e in ipairs(util.copy(points or {})) do
        local p=e.point;local theta=(p.x*(horizontalScale or 1)/r+0.5)*math.pi/2;local s,c=math.sin(theta),math.cos(theta)
        e.point=vec3((r+p.z)*s-r/2,p.y,(r+p.z)*c-r/2)
        if e.normal then
            local n=e.normal;e.normal=vec3(n.x*c+n.z*s,n.y,-n.x*s+n.z*c)
        end
        if male then
            if not replace[e.snapGroup] then table.insert(new,e) end
        else
            local groups={}
            for _,g in ipairs(e.maleSnapGroups) do if not replace[g] then table.insert(groups,g) end end
            e.maleSnapGroups=groups
            if #groups>0 then table.insert(new,e) end
        end
    end
    local mid=r/math.sqrt(2)-r/2;local n=1/math.sqrt(2)
    for _,edge in ipairs({"Bottom","Top"}) do
        local group=snap.maleTypes["sl90Wall"..r..edge].index
        local y=edge=="Bottom" and 0 or height
        if male then table.insert(new,{point=vec3(mid,y,mid),normal=vec3(-n,0,-n),snapGroup=group})
        else
            table.insert(new,{point=vec3(mid,edge=="Bottom" and height or 0,mid),normal=vec3(n,0,n),maleSnapGroups={group}})
        end
    end
    return result.finish(new,male)
end
return result
