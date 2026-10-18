-- Rebuild compatibility follows geometry, not build-menu/material families.
-- Keys are persisted by the native type map: keep them stable across updates.
local rebuild = {}

function rebuild.groupKey(kind, cfg)
    if kind == "column" then
        return cfg.height==1 and "sp_columnHeight1" or "column"
    elseif kind == "window" then
        return "wall4x2" -- Native walls, doors and windows share this footprint.
    elseif kind == "foundation" then
        if cfg.ramp then return "sp_ramp4x4Rise1" end
        if cfg.size == 1 or cfg.size == 2 then
            return "foundation" .. cfg.size .. "x" .. cfg.size
        end
        return "sp_foundation4x4Depth2"
    elseif kind == "pool" then
        -- Water is not a solid foundation. Allow rebuilding each size in place.
        return "sp_waterBlock" .. cfg.size
    elseif kind == "triangle" then
        return (cfg.snapKey and "sp_rightTriangle" or "sp_wedge45") .. cfg.size
    elseif kind == "shortEdgeWall" then
        return "sp_wedgeWall" .. cfg.size .. "Height" .. cfg.height
    elseif kind == "curve" then
        if cfg.kind == "floor" then return "sp_curveFloor" .. cfg.size end
        return "sp_curveWall" .. cfg.size .. "Height" .. cfg.height
    elseif kind == "hypotenuse" then
        return "sp_hypotenuseWall" .. cfg.size .. "Height" .. (cfg.form == "short" and 1 or 2)
    end
    error("Unknown rebuild family: " .. tostring(kind))
end

function rebuild.indexFor(constructable, kind, cfg)
    local key = rebuild.groupKey(kind, cfg)
    local groups = constructable.rebuildGroups
    if not groups[key] then
        -- Never invent a missing native group. This flags incompatible game APIs.
        assert(key:sub(1, 3) == "sp_", "Missing native rebuild group: " .. key)
        mjrequire("common/typeMaps"):insert("constructableRebuildGroups", groups, {key=key})
    end
    return groups[key].index
end

return rebuild
