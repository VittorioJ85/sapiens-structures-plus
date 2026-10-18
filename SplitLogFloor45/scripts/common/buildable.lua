local mod = {loadOrder=1}

function mod:onload(buildable)
    local constructable = mjrequire "common/constructable"
    local registration = mjrequire "common/spPartRegistration"
    for _, family in ipairs(mjrequire "common/spParts") do
        for _, cfg in ipairs(mjrequire(family.configs)) do
            registration.buildable(buildable, constructable, family.kind, cfg)
        end
    end
    -- Apply after cloning recipes, so pools keep their original dirt-only cost.
    mjrequire("common/spFoundationFill").configureBuildables(constructable)
    -- Group only after every member exists; native finalize resolves variations later.
    mjrequire("common/spBuildMenu").configure(constructable)
end

return mod
