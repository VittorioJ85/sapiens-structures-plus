local mod = {loadOrder=1}

function mod:onload(gameObject)
    local registration = mjrequire "common/spPartRegistration"
    local families = mjrequire "common/spParts"
    local original = gameObject.addGameObjectsFromTable

    -- Expand each native batch once, before native types/physics sets are finalized.
    -- Never mjrequire gameObject here: this hook runs during its initialization.
    function gameObject:addGameObjectsFromTable(objects)
        local expanded = {}
        for key, value in pairs(objects) do expanded[key] = value end
        if objects.mudTileWet then mjrequire("common/spTileVariants").objects(objects,expanded) end
        for _, family in ipairs(families) do
            for _, cfg in ipairs(mjrequire(family.configs)) do
                local canRegister = family.kind ~= "triangle"
                    or (objects[cfg.source] and objects["build_" .. cfg.source])
                if canRegister then
                    for _, prefix in ipairs({"", "build_"}) do
                        local source = objects[prefix .. cfg.source]
                        if source then
                            expanded[prefix .. cfg.key] = registration.gameObject(source, family.kind, cfg)
                        end
                    end
                end
            end
        end
        return original(self, expanded)
    end
end

return mod
