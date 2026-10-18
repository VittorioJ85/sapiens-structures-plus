-- Logical foundation snap plane is Y=0; depth extends downward.
-- Ramp snap height is (Z+2)/4 metres, rising from 0 to 1 over the 4 m span.
-- Rendered surfaces and collision tops include the native foundation lip
-- (~0.043837 m). Keep it in the models, not the connectors: native floors and
-- walls use the same zero datum, and saved placements must not be shifted.
local utils={}
function utils.points(cfg,male)
 local snap=mjrequire "common/snapGroups/snapGroup"
 local copy=mjrequire("common/sl45Util").copy
 local finish=mjrequire("common/sl90Utils").finish
 local vec3=mjrequire("common/mjm").vec3
 local baseSize=cfg.size==1 and 1 or 2
 local baseKey="foundation"..baseSize.."x"..baseSize..(male and "MaleSnapPoints" or "FemaleSnapPoints")
 local result=copy((male and snap.malePoints or snap.femalePoints)[baseKey])
 local function convert(p)
  local x,z=p.x*cfg.size/baseSize,p.z*cfg.size/baseSize
  local y=cfg.ramp and ((p.y+baseSize)/baseSize*(z+2)/4) or (p.y*cfg.depth/baseSize)
  return vec3(x,y,z)
 end
 for _,p in ipairs(result) do p.point=convert(p.point);if p.heuristicOffset then p.heuristicOffset=nil end end
 local base=(male and snap.malePoints or snap.femalePoints)["floor"..cfg.size.."x"..cfg.size..(male and "MaleSnapPoints" or "FemaleSnapPoints")]
 for _,p in ipairs(copy(base)) do
  if not cfg.ramp or math.abs(p.point.z)>1.99 then
   if cfg.ramp then p.point=vec3(p.point.x,(p.point.z+2)/4,p.point.z) end
   table.insert(result,p)
  end
 end
 if cfg.size==4 and not cfg.ramp then
  -- Mirror the native floor edge/corner connectors onto the underside.
  -- Retain the upper connectors and the foundation's saved origin unchanged.
  for _,p in ipairs(copy(base)) do
   p.point=vec3(p.point.x,p.point.y-cfg.depth,p.point.z)
   p.heuristicOffset=nil
   table.insert(result,p)
  end
 end
 if cfg.woodShell and cfg.ramp then
  local axis=cfg.size/2-cfg.wallInset
  local edge=snap.maleTypes.wallEdgeBottomX.index
  for _,sign in ipairs({-1,1}) do
   -- Both ends of the high wall (the two marked vertical edges).
   local point=vec3(sign*cfg.size/2,0,axis);local normal=vec3(sign,0,0)
   if male then table.insert(result,{point=point,normal=normal,snapGroup=edge})
   else table.insert(result,{point=point,normal=normal,maleSnapGroups={edge}}) end
   -- Side-wall continuations at the high and low ends.
   for _,endSign in ipairs({-1,1}) do
    local p=vec3(sign*axis,0,endSign*cfg.size/2);local n=vec3(0,0,endSign)
    if male then table.insert(result,{point=p,normal=n,snapGroup=edge})
    else table.insert(result,{point=p,normal=n,maleSnapGroups={edge}}) end
   end
  end
 end
 return finish(result,male)
end
return utils
