-- Tile colors use native brick materials and tile geometry. Author: Vittorio.
-- Keep native resource categories: storage, research and building requirements
-- must treat these as tiles, not as new resource groups or brick objects.
local copy=mjrequire("common/sl45Util").copy
local tiles={variants={{key="sand",label="Sand"},{key="riverSand",label="River Sand"},{key="redSand",label="Red Sand"}},sections={}}
local stages={
    {source="mudTileWet",key="spTileWet",label="Wet Unfired Tile",material="mudBrickWet_"},
    {source="mudTileDry",key="spTileDry",label="Unfired Tile",material="mudBrickDry_"},
    {source="firedTile",key="spTileFired",label="Fired Tile",material="firedBrick_"},
}

function tiles.objects(objects,expanded)
    for _,stage in ipairs(stages) do
        local source=objects[stage.source]
        if source then
            for _,variant in ipairs(tiles.variants) do
                local key=stage.key.."_"..variant.key
                if not expanded[key] then
                    local info=copy(source)
                    info.key=nil;info.index=nil
                    info.modelName=key
                    info.name=variant.label.." "..stage.label
                    info.plural=info.name.."s"
                    expanded[key]=info
                end
            end
        end
    end
end

function tiles.models(model)
    if not model.remapModels.tile then return end
    local compat=mjrequire "common/spMaterialCompatibility"
    for _,variant in ipairs(tiles.variants) do
        for _,stage in ipairs(stages) do
            model.remapModels.tile[stage.key.."_"..variant.key]={brick=stage.material..variant.key}
        end
    end
    -- Snapshot native variants before extending them; never mutate the table
    -- currently being enumerated. Adapters also recolor existing generated parts.
    local sources={}
    for base,variants in pairs(model.remapModels) do
        for name,map in pairs(variants) do
            local section=name:match("^(.*)_firedTile$")
            if section then sources[#sources+1]={base=base,name=name,section=section,map=copy(map)} end
        end
        if base:match("^pathNode_firedTile_") then
            sources[#sources+1]={base=base,name=base,section=base,map={}}
        end
    end
    table.sort(sources,function(a,b)return a.name<b.name end)
    for _,source in ipairs(sources) do
        tiles.sections[source.section]=tiles.sections[source.section] or {}
        for _,variant in ipairs(tiles.variants) do
            local name=source.name.."_sp_"..variant.key
            local map=copy(source.map)
            for channel,material in pairs(map) do
                if material=="terracottaTile" or material=="terracotta" then map[channel]="firedBrick_"..variant.key end
            end
            -- Roof/path meshes already contain this material, without a remap.
            map.terracottaTile="firedBrick_"..variant.key
            model.remapModels[source.base][name]=map
            tiles.sections[source.section][variant.key]=name
            compat.registerModelVariant(source.base,name,map,"spTileFired_"..variant.key)
        end
    end
end

function tiles.placeholders(placeholders,model,gameObject)
    for section,variants in pairs(tiles.sections) do
        local target=placeholders[section.."Remaps"]
        local pathNumber=section:match("^pathNode_firedTile_([12])$")
        if pathNumber then target=placeholders["tilePathRemaps_"..pathNumber] end
        if target then
            for _,variant in ipairs(tiles.variants) do
                local object=gameObject.types["spTileFired_"..variant.key]
                local name=variants[variant.key]
                if object and model.modelIndexesByName[name] then
                    target[object.index]=pathNumber and placeholders:getRemaps(name) or model:modelIndexForName(name)
                end
            end
        end
    end
end

function tiles.craftRecipe(craftable,gameObject,original,key,info,brickRecipe)
    local self=craftable
    if key=="mudTileWet" then
        -- Use the existing visible recipe and native Binder group. Crafting-area
        -- recipe lists do not automatically expose separately registered recipes.
        local binderGroup=mjrequire("common/resource").groups.brickBinder.index
        local binder
        for _,requirement in ipairs(assert(brickRecipe,"Missing native mud-brick recipe").requiredResources) do
            if requirement.group==binderGroup then binder=copy(requirement) end
        end
        assert(binder,"Missing native brick binder")
        info.requiredResources=copy(info.requiredResources)
        table.insert(info.requiredResources,binder)
        info.inProgressBuildModel=brickRecipe.inProgressBuildModel
        local output=copy(info.outputObjectInfo)
        local default=assert(output.objectTypesArray,"Missing native wet tile output")
        local mapping=output.outputArraysByResourceObjectType or {}
        mapping[gameObject.typeIndexMap.hay]=copy(default)
        for _,variant in ipairs(tiles.variants) do
            local result={}
            for i=1,#default do result[i]=gameObject.typeIndexMap["spTileWet_"..variant.key] end
            mapping[gameObject.typeIndexMap[variant.key]]=result
        end
        output.outputArraysByResourceObjectType=mapping
        info.outputObjectInfo=output
        info.summary="Mix clay with a binder to make tiles. Hay keeps the original color; Sand, River Sand and Red Sand select their matching colors. Dry before firing in a kiln."
    end
    if key=="firedTile" then
        -- Native firing selects its output from the delivered dry tile.
        -- Preserve existing provider entries and the original clay output.
        -- Public has no explicit output list: native crafting creates one
        -- object matching the recipe key. Beta supplies its own batch size.
        local output=copy(info.outputObjectInfo or {objectTypesArray={gameObject.typeIndexMap.firedTile}})
        local mapping=output.outputArraysByResourceObjectType or {}
        local nativeDry=gameObject.typeIndexMap.mudTileDry
        local default=assert(output.objectTypesArray or mapping[nativeDry],"Missing native tile firing output")
        mapping[nativeDry]=mapping[nativeDry] or copy(default)
        -- The formerly generic recipe also accepted other mods' dry tiles.
        -- Retain that fallback for registered resources without displacing
        -- a provider's own explicit output mapping.
        if output.objectTypesArray then
            local dryResource=gameObject.types[nativeDry].resourceTypeIndex
            for _,object in pairs(gameObject.types) do
                if object.resourceTypeIndex==dryResource and not mapping[object.index] then
                    mapping[object.index]=copy(default)
                end
            end
        end
        for _,variant in ipairs(tiles.variants) do
            local result={}
            for i=1,#default do result[i]=assert(gameObject.typeIndexMap["spTileFired_"..variant.key]) end
            mapping[assert(gameObject.typeIndexMap["spTileDry_"..variant.key])]=result
        end
        output.outputArraysByResourceObjectType=mapping
        info.outputObjectInfo=output
    end
    local index=original(self,key,info)
    if key=="mudTileWet" then
        for _,variant in ipairs(tiles.variants) do
            local recipe=copy(info)
            recipe.key=nil;recipe.index=nil;recipe.variations=nil
            -- Keep 0.17.0 recipe IDs for queued orders, but route them through
            -- the same binder recipe. Only mudTileWet is offered by native UI.
            original(self,"spTileWet_"..variant.key,recipe)
        end
    end
    return index
end

function tiles.evolutions(evolving,gameObject)
    local source=assert(evolving.evolutions[gameObject.types.mudTileWet.index],"Missing native tile drying rule")
    for _,variant in ipairs(tiles.variants) do
        local wet=assert(gameObject.types["spTileWet_"..variant.key])
        local dry=assert(gameObject.types["spTileDry_"..variant.key])
        local rule=copy(source);rule.toType=dry.index
        evolving.evolutions[wet.index]=rule
    end
end
return tiles
