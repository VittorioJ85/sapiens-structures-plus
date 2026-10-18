local mod = {loadOrder=1}

function mod:onload(placeholders)
    local resource = mjrequire "common/resource"
    local flora = mjrequire "common/flora"
    local typeMaps = mjrequire "common/typeMaps"
    local model = mjrequire "common/model"
    local registration = mjrequire "common/spModelRegistration"
    local families = mjrequire "common/spParts"
    local gameObject
    local originalInitRemaps=placeholders.initRemaps
    if originalInitRemaps then
        function placeholders:initRemaps(...)
            local result=originalInitRemaps(self,...)
            mjrequire("common/spTileVariants").placeholders(self,model,gameObject)
            return result
        end
    end
    local originalInit = placeholders.init
    function placeholders:init(gameObject_, ...)
        -- Native gameObject:mjInit calls this before modManager caches gameObject.
        -- Use its supplied instance; requiring the module here causes recursion.
        gameObject = gameObject_
        return originalInit(self, gameObject_, ...)
    end
    local originalAddModels = placeholders.addModels
    function placeholders:addModels()
        originalAddModels(self)
        local namesByIndex={}
        for name,index in pairs(model.modelIndexesByName) do namesByIndex[index]=name end
        for _,cfg in ipairs(mjrequire "common/sl45Floors") do
            local definitions={}
            local count=cfg.family=="wood" and 2 or 1
            for i=1,count do
                local section=i
                local remaps={}
                local defaultName
                if cfg.family=="wood" then
                    defaultName=cfg.prefix.."birchSplitLogTriFloorSection"..section
                    for _,wood in ipairs(flora.logTypeBaseKeys) do
                        local name=cfg.prefix..wood.."SplitLogTriFloorSection"..section
                        local objectIndex=typeMaps.types.gameObject[wood.."SplitLog"]
                        if objectIndex and model.modelIndexesByName[name] then
                            remaps[objectIndex]=self:getRemaps(name)
                        else mjrequire("common/spMaterialCompatibility").warnMissing(name) end
                    end
                else
                    local source=cfg.family=="mud" and self.mudBrickFloorTriSection2Remaps or self.tileFloorTriSection2Remaps
                    defaultName=cfg.prefix..(cfg.family=="mud" and "mudBrickFloorTriSection2_sand" or "tileFloorTriSection2_firedTile")
                    for objectIndex,originalModelIndex in pairs(source) do
                        local name=namesByIndex[originalModelIndex]
                        if name and model.modelIndexesByName[cfg.prefix..name] then
                            remaps[objectIndex]=self:getRemaps(cfg.prefix..name)
                        else mjrequire("common/spMaterialCompatibility").warnMissing(cfg.key.."/"..tostring(originalModelIndex)) end
                    end
                end
                definitions[i]={
                    key=cfg.resource.."_"..section,defaultModelName=defaultName,
                    resourceTypeIndex=resource.types[cfg.resource].index,
                    placeholderModelIndexForObjectTypeFunction=function(info,objectIndex,context)
                        return self:getModelIndexForStandardRemaps(info,remaps[objectIndex],context or {subdivLevel=mj.SUBDIVISIONS-1})
                    end,
                }
                local extra=mjrequire("common/spMaterialCompatibility").objectMapping(cfg,section,model,gameObject)
                for objectIndex,modelIndex in pairs(extra) do
                    remaps[objectIndex]=self:getRemaps(assert(namesByIndex[modelIndex],"Missing compatibility model"))
                end
            end
            table.insert(definitions,{key=cfg.resource.."_store",offsetToStorageBoxWalkableHeight=true})
            self:addModel(cfg.key,definitions)
            self:addModel(cfg.key.."_low",definitions)
        end
        for _, family in ipairs(families) do
            if family.kind == "column" then
                for _,cfg in ipairs(mjrequire(family.configs)) do
                    mjrequire("common/spColumnUtils").placeholders(self,model,gameObject,cfg)
                end
            elseif family.kind == "pool" then
                for _, cfg in ipairs(mjrequire(family.configs)) do registration.pool(self, cfg) end
            elseif family.assets then
                local assets = mjrequire(family.assets)
                for _, cfg in ipairs(mjrequire(family.configs)) do
                    if cfg.woodShell then
                        registration.wood(self, model, gameObject, cfg)
                    else
                        registration.remap(self, model, cfg, assets, gameObject)
                    end
                end
            end
        end
        -- Native and generated dirt selectors must already exist before these
        -- per-model wrappers are installed; avoids remapping sand through the
        -- older generated soil-only lookup tables.
        mjrequire("common/spFoundationFill").configurePlaceholders(self,model,gameObject)
    end
end

return mod
