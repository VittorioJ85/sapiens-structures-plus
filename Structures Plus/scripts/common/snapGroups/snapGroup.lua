local function addWedgeFloors(snapGroup)
    local vec3=mjrequire("common/mjm").vec3
    for _,size in ipairs({4,2}) do
        local s,c=math.sin(math.pi/8),math.cos(math.pi/8)
        local h,w=size*c,size*s
        local male,female={},{}
        for _,sign in ipairs({-1,1}) do
            local point,normal=vec3(sign*w/2,0,-h/6),vec3(sign*c,0,-s)
            table.insert(male,{point=point,normal=normal,snapGroup=snapGroup.maleTypes["floor"..size.."x"..size].index})
            table.insert(female,{point=point,normal=normal,maleSnapGroups={
                snapGroup.maleTypes.floor4x4.index,snapGroup.maleTypes.floor2x2.index,
                snapGroup.maleTypes.floor1x1.index,snapGroup.maleTypes.floorTri2.index}})
        end
        if size==4 then
            -- Same wall anchors as an outer edge of floor4x4FemaleSnapPoints:
            -- centered full walls, short walls at +/-1m, and inward-facing
            -- bottom anchors for thin walls at each of those positions.
            for _,sign in ipairs({-1,1}) do
                for _,offset in ipairs({-1,0,1}) do
                    local point=vec3(sign*w/2+offset*sign*s,0,-h/6+offset*c)
                    local groups={snapGroup.maleTypes.thinWallMiddleBottomZ.index,
                        snapGroup.maleTypes.thinWallMiddleTopZ.index}
                    if offset==0 then
                        table.insert(groups,snapGroup.maleTypes.wallMiddleBottomZ.index)
                        table.insert(groups,snapGroup.maleTypes.wallMiddleTopZ.index)
                    end
                    table.insert(female,{point=point,normal=vec3(sign*c,0,-s),maleSnapGroups=groups})
                    table.insert(female,{point=point,normal=vec3(-sign*c,0,s),
                        maleSnapGroups={snapGroup.maleTypes.thinWallMiddleBottomZ.index}})
                end
            end
        end
        male.maleSnapGroupSet={}
        for _,entry in ipairs(male) do male.maleSnapGroupSet[entry.snapGroup]=true end
        female.allowedMaleSnapGroupSet={}
        for _,entry in ipairs(female) do
            entry.allowedMaleSnapGroupSet={}
            for _,group in ipairs(entry.maleSnapGroups) do
                female.allowedMaleSnapGroupSet[group]=true
                entry.allowedMaleSnapGroupSet[group]=true
            end
        end
        snapGroup.malePoints["sl45Male"..size]=male
        snapGroup.femalePoints["sl45Female"..size]=female
    end
    snapGroup.malePoints.sl45Male=snapGroup.malePoints.sl45Male4
    snapGroup.femalePoints.sl45Female=snapGroup.femalePoints.sl45Female4
end

local function addWedgeWallAnchors(snapGroup)
    local vec3=mjrequire("common/mjm").vec3
    for _,size in ipairs({4,2}) do
        local female=snapGroup.femalePoints["sl45Female"..size]
        for _,sign in ipairs({-1,1}) do
            local entry={point=vec3(0,0,size*math.cos(math.pi/8)/3),normal=vec3(0,0,sign),maleSnapGroups={
                snapGroup.maleTypes.wallMiddleBottomZ.index,snapGroup.maleTypes.wallMiddleTopZ.index,
                snapGroup.maleTypes.thinWallMiddleBottomZ.index,snapGroup.maleTypes.thinWallMiddleTopZ.index},allowedMaleSnapGroupSet={}}
            for _,group in ipairs(entry.maleSnapGroups) do female.allowedMaleSnapGroupSet[group]=true;entry.allowedMaleSnapGroupSet[group]=true end
            table.insert(female,entry)
        end
    end
end

local function addCurves(snap)
    local typeMaps=mjrequire "common/typeMaps"
    local vec3=mjrequire("common/mjm").vec3
    local utils=mjrequire "common/sl90Utils"
    for _,r in ipairs({4,2}) do
        for _,edge in ipairs({"Bottom","Top"}) do
            typeMaps:insert("snapGroupMaleType",snap.maleTypes,{key="sl90Wall"..r..edge})
        end
        local male,female={},{}
        local floor=snap.maleTypes["floor"..r.."x"..r].index
        for _,side in ipairs({1,2}) do
            local function point(t) if side==1 then return vec3(t,0,-r/2) end return vec3(-r/2,0,t) end
            local normal=side==1 and vec3(0,0,-1) or vec3(-1,0,0)
            table.insert(male,{point=point(0),normal=normal,snapGroup=floor})
            table.insert(female,{point=point(0),normal=normal,maleSnapGroups={floor}})
            local positions=r==4 and {-1,0,1} or {0}
            for _,t in ipairs(positions) do
                local groups={snap.maleTypes.thinWallMiddleBottomZ.index,snap.maleTypes.thinWallMiddleTopZ.index}
                if r==4 and t==0 then table.insert(groups,snap.maleTypes.wallMiddleBottomZ.index);table.insert(groups,snap.maleTypes.wallMiddleTopZ.index) end
                table.insert(female,{point=point(t),normal=normal,maleSnapGroups=groups})
                table.insert(female,{point=point(t),normal=vec3(-normal.x,0,-normal.z),maleSnapGroups={snap.maleTypes.thinWallMiddleBottomZ.index}})
            end
        end
        local mid=r/math.sqrt(2)-r/2
        table.insert(female,{point=vec3(mid,0,mid),normal=vec3(1/math.sqrt(2),0,1/math.sqrt(2)),maleSnapGroups={snap.maleTypes["sl90Wall"..r.."Bottom"].index,snap.maleTypes["sl90Wall"..r.."Top"].index}})
        snap.malePoints["sl90Floor"..r]=utils.finish(male,true)
        snap.femalePoints["sl90Floor"..r]=utils.finish(female,false)
    end
end

-- Both right-triangle sizes use the same geometry rule.

local function addRightTriangles(snap)
 local vec3=mjrequire("common/mjm").vec3
 for _,size in ipairs({4,2}) do
 local h=size/math.sqrt(2)
 local male,female={},{}
 local floors={snap.maleTypes.floor4x4.index,snap.maleTypes.floor2x2.index,snap.maleTypes.floor1x1.index,snap.maleTypes.floorTri2.index}
 local edges={
  {vec3(-h/2,0,-h/6),vec3(-1/math.sqrt(2),0,-1/math.sqrt(2)),vec3(-1/math.sqrt(2),0,1/math.sqrt(2))},
  {vec3(h/2,0,-h/6),vec3(1/math.sqrt(2),0,-1/math.sqrt(2)),vec3(1/math.sqrt(2),0,1/math.sqrt(2))},
  {vec3(0,0,h/3),vec3(0,0,1),vec3(1,0,0)}
 }
 for _,edge in ipairs(edges) do
  local p,n,t=edge[1],edge[2],edge[3]
  table.insert(male,{point=p,normal=n,snapGroup=snap.maleTypes["floor"..size.."x"..size].index})
  table.insert(female,{point=p,normal=n,maleSnapGroups=floors})
  for _,offset in ipairs(size==4 and {-1,0,1} or {0}) do
   local point=vec3(p.x+offset*t.x,0,p.z+offset*t.z)
   local groups={snap.maleTypes.thinWallMiddleBottomZ.index,snap.maleTypes.thinWallMiddleTopZ.index}
   if size==4 and offset==0 then table.insert(groups,snap.maleTypes.wallMiddleBottomZ.index);table.insert(groups,snap.maleTypes.wallMiddleTopZ.index) end
   table.insert(female,{point=point,normal=n,maleSnapGroups=groups})
   table.insert(female,{point=point,normal=vec3(-n.x,0,-n.z),maleSnapGroups={snap.maleTypes.thinWallMiddleBottomZ.index}})
  end
 end
 local finish=mjrequire("common/sl90Utils").finish
 snap.malePoints["rt90Floor"..size]=finish(male,true)
 snap.femalePoints["rt90Floor"..size]=finish(female,false)
 end
end

-- Hypotenuse walls extension

local function addHypotenuseWalls(snap)
 local typeMaps=mjrequire "common/typeMaps"
 local vec3=mjrequire("common/mjm").vec3
 local finish=mjrequire("common/sl90Utils").finish
 for _,size in ipairs({4,2}) do
  for _,edge in ipairs({"Bottom","Top"}) do
   typeMaps:insert("snapGroupMaleType",snap.maleTypes,{key="hypWall"..size..edge})
  end
  local points=snap.femalePoints["rt90Floor"..size]
  for _,sign in ipairs({-1,1}) do
   table.insert(points,{point=vec3(0,0,size/math.sqrt(2)/3),normal=vec3(0,0,sign),maleSnapGroups={snap.maleTypes["hypWall"..size.."Bottom"].index,snap.maleTypes["hypWall"..size.."Top"].index}})
  end
  finish(points,false)
 end
end

local mod = {loadOrder=1}
function mod:onload(snap)
    -- Preserve type-map insertion order for existing worlds.
    addWedgeFloors(snap)
    addWedgeWallAnchors(snap)
    addCurves(snap)
    addRightTriangles(snap)
    addHypotenuseWalls(snap)
end
return mod
