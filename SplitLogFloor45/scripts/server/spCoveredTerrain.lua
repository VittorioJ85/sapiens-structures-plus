-- Construction clearance can include a terrain vertex beyond the new piece's
-- footprint. Do not demand access to grass buried under an existing solid block.
local m = mjrequire "common/mjm"
local validation = mjrequire "common/spValidation"
local configs = mjrequire "common/slFoundations"
local covered = {}

function covered:foundationAt(gom, pos)
    if not gom or not validation.validPosition(pos) then return nil end
    -- Resolve after gameObject initialization; only finished solid 4 m blocks.
    -- Wooden shells can have accessible space underneath and are excluded.
    local types = mjrequire("common/gameObject").types
    local indexes, eligible = {}, {}
    for _, cfg in ipairs(configs) do
        local objectType = types[cfg.key]
        if cfg.size == 4 and cfg.depth == 2 and not cfg.ramp and not cfg.woodShell and objectType then
            indexes[#indexes + 1] = objectType.index
            eligible[objectType.index] = true
        end
    end
    if #indexes == 0 then return nil end
    for _, id in ipairs(gom:getGameObjectsOfTypesWithinRadiusOfPos(indexes, pos, mj:mToP(4)) or {}) do
        local object = gom:getObjectWithID(id)
        if object and eligible[object.objectTypeIndex] and object.scale == 1 then
            local q = m.vec3xMat3(pos - object.pos, object.rotation)
            local x, y, z = mj:pToM(q.x), mj:pToM(q.y), mj:pToM(q.z)
            -- A vertex strictly inside the solid footprint is blocked even in
            -- its outer 5 cm strip (saved case: 2.12 cm inside). Retain only a
            -- 1 mm boundary epsilon; exact edges and exterior points stay native.
            -- Keep deck vegetation native. The 5 cm base tolerance
            -- covers placement offsets (the reproduced base is 1.05 cm up).
            -- Suspended blocks with a larger gap must not suppress clearance.
            if math.abs(x) < 1.999 and math.abs(z) < 1.999 and y >= -2.05 and y <= -0.25 then
                return object
            end
        end
    end
    return nil
end

return covered
