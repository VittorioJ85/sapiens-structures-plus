local mod={loadOrder=1}
function mod:onload(model)
    local additions={}
    for _,cfg in ipairs(mjrequire "common/sl45Floors") do
        for name,variants in pairs(model.remapModels) do
            local relevant=(cfg.family=="wood" and string.find(name,"SplitLogTriFloorSection",1,true))
                or (cfg.family=="mud" and name=="mudBrickFloorTriSection2")
                or (cfg.family=="tile" and name=="tileFloorTriSection2")
            if relevant then
                local newVariants={}
                for variant,materials in pairs(variants) do newVariants[cfg.prefix..variant]=materials end
                additions[cfg.prefix..name]=newVariants
            end
        end
        if cfg.family=="wood" then
            for i=1,2 do
                local birch=cfg.prefix.."birchSplitLogTriFloorSection"..i
                additions[birch]=additions[birch] or {}
                additions[birch][cfg.prefix.."aspenSplitLogTriFloorSection"..i]={}
                local pine=cfg.prefix.."pineSplitLogTriFloorSection"..i
                additions[pine]=additions[pine] or {}
                additions[pine][cfg.prefix.."coconutSplitLogTriFloorSection"..i]={wood="coconutWood",trunk="coconutBark"}
            end
        end
    end
    for name,variants in pairs(additions) do model.remapModels[name]=variants end
    if model.remapModels.tile then mjrequire("common/spTileVariants").models(model) end
    mjrequire("common/spFoundationFill").configureModels(model)
    mjrequire("common/spColumnUtils").models(model)
    local originalLoadRemaps=model.loadRemaps
    function model:loadRemaps(...)
        mjrequire("common/spModelAliases").loadNativeRemaps(self,originalLoadRemaps,...)
        -- All providers' onload hooks have run, including later load orders.
        -- Add clones before the engine builds its LOD and renderer tables.
        mjrequire("common/spMaterialCompatibility").prepare(self)
    end
end
return mod
