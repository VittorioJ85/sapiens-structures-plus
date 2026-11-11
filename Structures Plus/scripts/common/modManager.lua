-- All providers run before Hammerstone builds its patch catalog (loadOrder 0).
-- mjrequire shares the versioned support instance across enabled providers.
local mod = {loadOrder = -100}
function mod:onload(manager)
    (mjrequire "vittorioCompatibility/v1/state"):install(manager)
    -- mjInit runs after all modManager onload hooks, including Hammerstone.
    -- Keep compatibility registration early and defer the path loader overlay.
    local previousInit = manager.mjInit
    manager.mjInit = function(self, ...)
        local maintainInstaller = mjrequire "structuresPlusMaintain/install"
        for _, entries in pairs(self.enabledModDirNamesAndVersionsByType or {}) do
            for _, entry in ipairs(entries) do
                if entry.name == "ConstructionDetours" then
                    mj:log("[StructuresPlusDetours] standalone Construction Detours enabled; embedded copy skipped")
                    maintainInstaller:install()
                    if previousInit then return previousInit(self, ...) end
                    return
                end
            end
        end
        (mjrequire "structuresPlusDetours/install"):install(self)
        maintainInstaller:install()
        if previousInit then return previousInit(self, ...) end
    end
end
return mod
