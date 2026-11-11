local mod = {loadOrder=70}

function mod:onload(buildUI)
    local constructable = mjrequire "common/constructable"
    local menu = mjrequire "common/spBuildMenu"
    local createItemList = buildUI.createItemList
    function buildUI.createItemList(...)
        -- Hammerstone may call predecessors without a receiver. Capture the module
        -- as vanilla does, and forward either the dot or colon calling convention.
        local result = createItemList(...)
        -- Native buildUI uses each root's in-progress object as the grid preview.
        -- Each root is a real part with its own preview camera and material slots.
        menu.addMainEntries(buildUI.itemList, constructable)
        return result
    end
    local world,manage,allowed,normalItems
    local grids={}
    local grid=mjrequire "mainThread/ui/uiCommon/uiObjectGrid"
    local updateButtons=grid.updateButtons
    function grid:updateButtons(view,data,selection,...)
        if allowed and grids[view] then
            local filtered={}
            for _,entry in ipairs(data) do
                if allowed[entry.constructableTypeIndex] and not entry.randomVariation then
                    local copy={}
                    for k,v in pairs(entry) do copy[k]=v end
                    copy.name=constructable.types[entry.constructableTypeIndex].name
                    filtered[#filtered+1]=copy
                end
            end
            data=filtered
            -- Native variation indices refer to the unfiltered forty-item list.
            selection=1
        end
        return updateButtons(self,view,data,selection,...)
    end
    local init=buildUI.init
    function buildUI:init(gameUI,world_,manage_,...)
        world,manage=world_,manage_
        grids={}
        local create=grid.create
        function grid:create(...)
            local view=create(self,...)
            grids[view]=true
            return view
        end
        -- Capture only grids belonging to this view; always restore the factory.
        local result={pcall(init,self,gameUI,world_,manage_,...)}
        grid.create=create
        if not result[1] then error(result[2]) end
        return unpack(result,2)
    end
    local hide=buildUI.hide
    function buildUI:hide(...)
        local result=hide(self,...)
        if normalItems then self.itemList=normalItems end
        allowed,normalItems=nil,nil
        return result
    end
    local function showInserts(self,object,kind)
        if not world or not manage then return false end
        local options=mjrequire("common/spWindowContext").options(object,world:getTribeID(),kind)
        if #options==0 then return false end
        -- Finish the previous menu lifecycle before setting a new filter.
        manage:hide()
        normalItems=self.itemList
        self.itemList={};allowed={}
        for _,cfg in ipairs(options) do
            local entry=constructable.types[cfg.key]
            if entry then
                self.itemList[#self.itemList+1]=entry.index
                allowed[entry.index]=true
            end
        end
        local collection=mjrequire "mainThread/ui/manageUI/buildCollection"
        collection:tabSelectionShortcut(collection.modeTypes.build)
        manage:show(manage.modeTypes.build)
        return true
    end
    function buildUI:spShowWindows(object) return showInserts(self,object) end
    function buildUI:spShowDoors(object) return showInserts(self,object,"door") end
end

return mod
