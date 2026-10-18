-- Extend generated geometry from the final native material-remap registry.
-- Run once during model loading, before loadLODs; never require gameObject here.
local copy=mjrequire("common/sl45Util").copy
local compat={adapters={},wood={},resources={},objectModels={},fillModels={}}
local warned={}
function compat.warnMissing(key)
    if not warned[key] then
        warned[key]=true
        if mj.warn then mj:warn("Structures Plus: using default surface; material adapter required for ",key) end
    end
end
local function keys(t)
    local out={};for k in pairs(t or {}) do out[#out+1]=k end
    table.sort(out);return out
end
local function identifier(value)
    assert(type(value)=="string" and #value<240 and value:match("^[%w_]+$"),"Invalid material/model identifier")
    return value
end
local function materials(map)
    assert(type(map)=="table","Material map required")
    for a,b in pairs(map) do identifier(a);identifier(b) end
    return copy(map)
end

-- Adapter for independent meshes with a compatible native UV/material layout.
-- The provider still owns resource registration and native recipe membership.
function compat.registerModelVariant(base,variant,map,objectKey)
    assert(not compat.prepared,"Register material adapters before model:loadRemaps")
    identifier(base);identifier(variant);identifier(objectKey)
    compat.adapters[#compat.adapters+1]={base=base,variant=variant,map=materials(map),objectKey=objectKey}
end
function compat.registerWood(baseKey,wood,bark)
    assert(not compat.prepared,"Register wood before model:loadRemaps")
    compat.wood[identifier(baseKey)]={wood=identifier(wood),trunk=identifier(bark)}
end
function compat.registerColumnMaterial(family,objectKey,material)
    assert(not compat.prepared,"Register column materials before model:loadRemaps")
    assert(({wood=true,mud=true,brick=true,stone=true})[family],"Unsupported column family")
    compat.resources[family]=compat.resources[family] or {}
    compat.resources[family][identifier(objectKey)]=identifier(material)
end

local suffixes={"","_low","_lowest","_distant"}
local function unsuffix(name)
    return (name:gsub("_lowest$",""):gsub("_distant$",""):gsub("_low$",""))
end
local function objectKey(name)
    name=unsuffix(name)
    local tree=name:match("^(.-)SplitLog")
    if tree then return tree.."SplitLog" end
    tree=name:match("^(.-)Log")
    if tree then return tree.."Log" end
    local rock=name:match("^stoneBlock.-_(.+)$")
    if rock then return rock.."Block" end
    local mud=name:match("^mudBrick.-_([^_]+)$")
    if mud then return "mudBrickDry_"..mud end
    local brick=name:match("^brick.-_([^_]+)$")
    if brick then return "firedBrick_"..brick end
end

-- Translate from a baked variant's material names back through its native
-- template. Reject ambiguous maps rather than recoloring unrelated surfaces.
local function difference(old,new)
    local out,channels={},{}
    for k in pairs(old) do channels[k]=true end
    for k in pairs(new) do channels[k]=true end
    for k in pairs(channels) do
        local a,b=old[k] or k,new[k] or k
        if out[a] and out[a]~=b then return nil end
        out[a]=b
    end
    return out
end

function compat.prepare(model)
    if compat.prepared then return end
    compat.prepared=true
    local byName={}
    local function group(base,variants,objects)
        for _,suffix in ipairs(suffixes) do
            if model.modelIndexesByName[base..suffix] then
                local members={[base..suffix]={map={}}}
                for _,name in ipairs(keys(variants)) do
                    if model.modelIndexesByName[name..suffix] then
                        members[name..suffix]={map=variants[name],objectKey=objects and objects[name] or objectKey(name)}
                    end
                end
                for name in pairs(members) do
                    byName[name]=byName[name] or {};table.insert(byName[name],members)
                end
            end
        end
    end
    for _,base in ipairs(keys(model.remapModels)) do
        group(base,model.remapModels[base])
    end
    table.sort(compat.adapters,function(a,b)return a.base.."/"..a.variant<b.base.."/"..b.variant end)
    for _,a in ipairs(compat.adapters) do group(a.base,{[a.variant]=a.map},{[a.variant]=a.objectKey}) end

    local function alias(base,name,map)
        if not model.modelIndexesByName[base] then return nil end
        if not model.modelIndexesByName[name] then
            -- Native loadRemap also creates LOD aliases, without checking their
            -- names. Reject a collision before it can replace another model's
            -- index; runtime selectors already fall back for missing variants.
            for _,suffix in ipairs({"_low","_lowest","_distant"}) do
                if model.modelIndexesByName[base..suffix] and model.modelIndexesByName[name..suffix] then
                    compat.warnMissing("alias collision: "..name..suffix)
                    return nil
                end
            end
            -- Each consolidated LOD can have different source material names.
            mjrequire("common/spModelAliases").cloneVariant(model,base,{[name]=map})
        end
        return name
    end
    local function extend(names,objectNames,variantObjects)
        local originals=keys(names)
        for _,from in ipairs(originals) do
            for _,members in ipairs(byName[from] or {}) do
                for _,variant in ipairs(keys(members)) do
                    local target=names[variant]
                    if not target then
                        local delta=difference(members[from].map,members[variant].map)
                        if delta then
                            target=alias(names[from],names[from].."__spv__"..variant,delta)
                            if target then
                                names[variant]=target
                            end
                        end
                    end
                    -- Model discovery and resource binding are independent. A
                    -- later adapter can name the real resource of an existing
                    -- generated alias. Leave shipped native selectors intact.
                    if target and target:find("__spv__",1,true) then
                        local object=members[variant].objectKey
                        if object and objectNames and not objectNames[object] then objectNames[object]=target end
                        if object and variantObjects then
                            variantObjects[variant]=variantObjects[variant] or {}
                            variantObjects[variant][object]=true
                        end
                    end
                end
            end
        end
        -- Generated detailed/low sections can have unrelated hashed names.
        -- Publish the normal suffix links before the native loadLODs pass.
        for _,from in ipairs(keys(names)) do
            local target=names[from]
            if target:find("__spv__",1,true) then
                for _,suffix in ipairs({"_low","_lowest","_distant"}) do
                    if names[from..suffix] then alias(names[from..suffix],target..suffix,{}) end
                end
            end
        end
    end
    for _,family in ipairs(mjrequire "common/spParts") do
        if family.assets then
            local assets=mjrequire(family.assets)
            for _,cfg in ipairs(mjrequire(family.configs)) do
                compat.objectModels[cfg.key]={}
                for _,slot in ipairs(keys(assets[cfg.key])) do
                    local objects={};compat.objectModels[cfg.key][slot]=objects
                    extend(assets[cfg.key][slot],objects)
                end
            end
        end
    end
    -- Triangles have prefixed native sections instead of generated asset maps.
    local loaded=keys(model.modelIndexesByName)
    for _,cfg in ipairs(mjrequire "common/sl45Floors") do
        local names={}
        for _,name in ipairs(loaded) do
            if name:sub(1,#cfg.prefix)==cfg.prefix then names[name:sub(#cfg.prefix+1)]=name end
        end
        local variantObjects={}
        extend(names,nil,variantObjects)
        for _,from in ipairs(keys(names)) do
            local target=cfg.prefix..from
            if not model.modelIndexesByName[target] then alias(names[from],target,{}) end
        end
        compat.objectModels[cfg.key]={}
        for section=1,(cfg.family=="wood" and 2 or 1) do
            local objects={};compat.objectModels[cfg.key][section]=objects
            for _,name in ipairs(keys(variantObjects)) do
                if cfg.family~="wood" or name:find("SplitLogTriFloorSection"..section,1,true) then
                    for _,object in ipairs(keys(variantObjects[name])) do
                        if not objects[object] then objects[object]=cfg.prefix..name end
                    end
                end
            end
        end
    end

    -- Native floor maps provide both timber and bark without guessing shader
    -- names from a tree's display name. Explicit adapters take precedence.
    for name,map in pairs(model.remapModels.splitLogFloor4x4FullLow or {}) do
        local tree=name:match("^splitLogFloor4x4FullLow_(.+)$")
        if tree and not compat.wood[tree] then compat.wood[tree]={wood=map.wood or "wood",trunk=map.trunk or "trunk"} end
    end
    local columnMaterials=mjrequire "common/spColumnMaterials"
    local function discover(family,base,channel,pattern,transform)
        for name,map in pairs(model.remapModels[base] or {}) do
            local part=name:match(pattern)
            if part and map[channel] then
                local key=transform(part)
                if not columnMaterials[family].resources[key] then columnMaterials[family].resources[key]=map[channel] end
            end
        end
    end
    discover("stone","stoneBlockColumnBottom","rockBlock","^stoneBlockColumnBottom_(.+)$",function(s)return s.."Block" end)
    discover("mud","mudBrickColumnBottom","mudBrick","^mudBrickColumnBottom_(.+)$",function(s)return "mudBrickDry_"..s end)
    discover("brick","brickWallSection","brick","^brickWallSection_(.+)$",function(s)return "firedBrick_"..s end)
    for tree,map in pairs(compat.wood) do
        if not columnMaterials.wood.resources[tree.."SplitLog"] then columnMaterials.wood.resources[tree.."SplitLog"]=map.wood end
    end
    for family,entries in pairs(compat.resources) do
        for key,material in pairs(entries) do columnMaterials[family].resources[key]=material end
    end
    for _,cfg in ipairs(mjrequire "common/spColumns") do
        for _,object in ipairs(keys(columnMaterials[cfg.family].resources)) do
            for _,suffix in ipairs({"","_low"}) do
                alias(cfg.key.."Content"..suffix,cfg.key.."_"..object..suffix,{lightWood=columnMaterials[cfg.family].resources[object]})
            end
        end
    end
    for _,cfg in ipairs(mjrequire "common/slFoundations") do
        if cfg.woodShell then
            for _,entry in ipairs(mjrequire("common/slFoundationWood")[cfg.key]) do
                local ending=entry.resource=="log" and "Log" or "SplitLog"
                for _,tree in ipairs(keys(compat.wood)) do
                    local object=tree..ending
                    if not entry.modelsByObjectKey[object] then
                        local map=compat.wood[tree]
                        entry.modelsByObjectKey[object]=alias(entry.modelsByObjectKey["birch"..ending],
                            entry.defaultModelName.."__spwood__"..tree,{lightWood=map.wood,whiteTrunk=map.trunk})
                    end
                end
            end
        end
    end
    -- Only actual dirt/sand resources are routed to these aliases later, when
    -- gameObject is initialized. The registry also contains clay/compost.
    local fill=mjrequire "common/spFoundationFill"
    local assets=mjrequire "common/slFoundationModels"
    for _,key in ipairs(fill.keys) do
        compat.fillModels[key]={}
        for _,suffix in ipairs({"","_low"}) do
            local native=(key=="dirtFoundation1x1" and "dirtFoundation1x1Content" or "dirtFoundation2x2Content")..suffix
            local base=assets[key] and assets[key].dirt_1[native] or native
            local result={};compat.fillModels[key][suffix]=result
            for _,object in ipairs(keys(model.remapModels.dirt)) do
                local material=model.remapModels.dirt[object].dirt
                if material then result[object]=alias(base,"spcompat_fill_"..key.."_"..object..suffix,{dirt=material}) end
            end
        end
    end
end

function compat.objectMapping(cfg,slot,model,gameObject)
    local result={}
    for key,name in pairs((compat.objectModels[cfg.key] or {})[slot] or {}) do
        local object=gameObject and gameObject.types[key]
        if object and model.modelIndexesByName[name] then result[object.index]=model.modelIndexesByName[name] end
    end
    return result
end
return compat
