-- Scale native wall widths to the hypotenuse, preserving end/stack connectors.
-- Female anchors retain native groups as well as the custom floor-edge group.
local util={}
function util.points(points,cfg,male)
 local copy=mjrequire("common/sl45Util").copy
 local snap=mjrequire "common/snapGroups/snapGroup"
 local vec3=mjrequire("common/mjm").vec3
 local finish=mjrequire("common/sl90Utils").finish
 local replace={}
 for _,family in ipairs({"wall","thinWall"}) do
  for _,edge in ipairs({"Bottom","Top"}) do
   replace[snap.maleTypes[family.."Middle"..edge.."Z"].index]=snap.maleTypes["hypWall"..cfg.size..edge].index
  end
 end
 local result=copy(points)
 for _,p in ipairs(result) do
  p.point=vec3(p.point.x*cfg.factor,p.point.y,p.point.z)
  if male then p.snapGroup=replace[p.snapGroup] or p.snapGroup
  else
   local additions={}
   for _,g in ipairs(p.maleSnapGroups) do if replace[g] then table.insert(additions,replace[g]) end end
   for _,g in ipairs(additions) do table.insert(p.maleSnapGroups,g) end
  end
 end
 return finish(result,male)
end
return util
