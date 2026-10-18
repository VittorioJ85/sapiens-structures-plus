-- Shared registration policy. Geometry transforms stay in their family helpers.
local copy = mjrequire("common/sl45Util").copy
local registration = {}

function registration.snapPoints(kind, cfg, points, male)
    local snap = mjrequire "common/snapGroups/snapGroup"
    if kind == "column" then
        return mjrequire("common/spColumnUtils").points(cfg,male)
    elseif kind == "triangle" then
        local key = cfg.snapKey or ((male and "sl45Male" or "sl45Female") .. cfg.size)
        return (male and snap.malePoints or snap.femalePoints)[key]
    elseif kind == "shortEdgeWall" then
        return mjrequire("common/sl45WallUtils").scalePoints(points, cfg.factor)
    elseif kind == "curve" then
        if cfg.kind == "floor" then
            return (male and snap.malePoints or snap.femalePoints)["sl90Floor" .. cfg.size]
        end
        return mjrequire("common/sl90Utils").wallPoints(points, cfg.size, male, cfg.height, cfg.horizontalScale)
    elseif kind == "hypotenuse" then
        return mjrequire("common/slHypUtils").points(points, cfg, male)
    elseif kind == "foundation" then
        return mjrequire("common/slFoundationUtils").points(cfg, male)
    elseif kind == "pool" and cfg.size == 4 then
        return mjrequire("common/slpoolSnap").points(snap, male)
    end
    return points -- Centered windows and 2m pools retain native connectors.
end

function registration.summary(kind, cfg)
    if kind == "column" then
        return cfg.height.." m column. Original material variants and column footprint; centered stacking connections above and below."
    elseif kind == "triangle" then
        if cfg.snapKey then
            return "Right isosceles triangle: " .. cfg.size .. " m legs, 90 degrees apex, 45 degrees base angles. Snap points at all three edge centers."
        end
        return "Two " .. cfg.size .. " m edges meet at exactly 45 degrees. All standard material variants are available."
    elseif kind == "shortEdgeWall" then
        return "Wall for the short edge of the " .. cfg.size .. " m 45-degree floor triangle."
    elseif kind == "curve" then
        return "Quarter circle, radius " .. cfg.size .. " m. Original material variants."
    elseif kind == "window" then
        return "Centered, narrower window. Original sill and lintel heights; all original material variants."
    elseif kind == "hypotenuse" then
        return "Fits the long edge of a right-triangle floor with " .. cfg.size .. " m legs. Original material variants and building requirements."
    elseif kind == "pool" then
        return cfg.size .. " x " .. cfg.size .. " m water block, 2 m deep. Gentle waves and local swimming. Provide an accessible entrance below the waterline."
    elseif cfg.key == "spf_dirt_4" then
        return "Plant trees and crops on this 4 x 4 m soil foundation. One tree per foundation, including planting orders. Harvests deplete Rich Soil to Soil to Poor Soil. Dismantling returns the remaining soil quality; remove plants first."
    elseif cfg.ramp then
        return "4 x 4 m ramp foundation, rising from 0 to 1 m. Walkable slope and original material variants."
    end
    return cfg.size .. " x " .. cfg.size .. " m foundation, " .. cfg.depth .. " m deep. Original material variants."
end

local function namedCopy(source, cfg)
    local info = copy(assert(source, "Missing native source for " .. cfg.key))
    info.modelName, info.name, info.plural = cfg.key, cfg.label, cfg.label
    return info
end

function registration.buildable(buildable, constructable, kind, cfg)
    local info = namedCopy(constructable.types[cfg.recipeSource or cfg.source], cfg)
    info.inProgressGameObjectTypeKey = "build_" .. cfg.key
    info.finalGameObjectTypeKey = cfg.key
    info.summary = registration.summary(kind, cfg)
    info.rebuildGroupIndex = mjrequire("common/spRebuild").indexFor(constructable, kind, cfg)
    -- Preserve the original triangle menu inheritance for existing save compatibility.
    if kind ~= "triangle" then info.variations = nil end
    info.maleSnapPoints = registration.snapPoints(kind, cfg, info.maleSnapPoints, true)
    if kind == "column" then
        mjrequire("common/spColumnUtils").recipe(info,cfg)
    elseif kind == "foundation" or kind == "pool" then
        info.variationGroupName = nil
        info.allowYTranslation, info.allowXZRotation = true, kind ~= "pool" and not cfg.ramp
        if cfg.ramp or kind == "pool" then info.buildSequence = buildable.bringOnlySequence end
        if cfg.woodShell then
            local resource = mjrequire "common/resource"
            info.requiredResources = copy(constructable.types.splitLogWall.requiredResources)
            for _, requirement in ipairs(info.requiredResources) do
                if requirement.type == resource.types.log.index then requirement.count = cfg.logCount
                elseif requirement.type == resource.types.splitLog.index then requirement.count = cfg.splitLogCount end
            end
        else
            for _, requirement in ipairs(info.requiredResources) do
                requirement.count = math.max(1, math.ceil(requirement.count * cfg.costFactor))
            end
        end
    end
    local index = buildable:addBuildable(cfg.key, info)
    if cfg.group then table.insert(constructable.types[cfg.group].variations, index) end
end

function registration.gameObject(source, kind, cfg)
    local info = namedCopy(source, cfg)
    info.femaleSnapPoints = registration.snapPoints(kind, cfg, info.femaleSnapPoints, false)
    info.preventGrassAndSnow = false
    -- Curves keep native decal settings; all other families historically disable them.
    if kind ~= "curve" then info.decalBlockRadius2 = 0 end
    if kind == "triangle" and cfg.size == 2 and info.objectViewOffsetFunction then
        local originalOffset = info.objectViewOffsetFunction
        local vec3 = mjrequire("common/mjm").vec3
        info.objectViewOffsetFunction = function(object)
            local offset = originalOffset(object)
            return vec3(offset.x * 0.5, offset.y * 0.5, offset.z * 0.5)
        end
    elseif kind == "column" then
        local vec3=mjrequire("common/mjm").vec3
        -- GameObjectView has its own framing contract; a geometric center is
        -- not a valid replacement for the native column's view offset.
        local nativeOffset=source.objectViewOffsetFunction
        if cfg.height==1 and nativeOffset then
            info.objectViewOffsetFunction=function(object)
                local offset=nativeOffset(object)
                return vec3(offset.x*0.5,offset.y*0.5,offset.z*0.5)
            end
        end
        info.markerPositions={{worldOffset=vec3(0,mj:mToP(cfg.height/2),0)}}
    elseif kind == "pool" then
        info.blocksRain = false
        info.isPathFindingCollider, info.inProgressWalkable = true, false
        info.pathFindingDifficulty = mjrequire("common/pathFinding").pathNodeDifficulties.deepWater.index
    elseif kind == "foundation" then
        local vec3 = mjrequire("common/mjm").vec3
        info.hasPhysics, info.isPathFindingCollider, info.inProgressWalkable = true, true, false
        if cfg.size == 4 and not cfg.ramp then
            -- Match the native foundation's construction physics policy.
            -- Disabling unfinished walkable surfaces strands delivery/work
            -- targets when neighbouring foundations form a continuous deck.
            info.inProgressWalkable = source.inProgressWalkable
            info.isPathFindingCollider = source.isPathFindingCollider
        end
        info.objectViewOffsetFunction = function()
            return vec3(0, cfg.ramp and 0.5 or -cfg.depth / 2, 0)
        end
    end
    return info
end

return registration
