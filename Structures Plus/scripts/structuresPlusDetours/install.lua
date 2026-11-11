local mod = {}
function mod:install(manager)
    if self.installed then return end
    self.installed = true
    local expected = mjrequire "structuresPlusDetours/expected"
    local old = fileUtils.getFileContents
    local target = (fileUtils.getResourcePath("scripts").."/server/serverSapien.lua"):gsub("\\","/"):lower()
    local needle = "if goalDistance2 > prevGoalDistance2 then"
    local replacement = 'if mjrequire("structuresPlusDetours/progress"):shouldCancel(sapien, goalPosInfo.goalPos, goalDistance2 > prevGoalDistance2) then'
    local first,last = expected:find(needle,1,true)
    assert(first and not expected:find(needle,last+1,true))
    local patched = expected:sub(1,first-1)..replacement..expected:sub(last+1)
    local reported = false
    fileUtils.getFileContents = function(path,...)
        local text = old(path,...)
        if type(path)=="string" and path:gsub("\\","/"):lower()==target and type(text)=="string" then
            local normalized = text:gsub("\r\n","\n")
            local a,b = normalized:find(expected,1,true)
            if a and not normalized:find(expected,b+1,true) then
                if not reported then mj:log("[StructuresPlusDetours] exact-source patch active 0.20.3"); reported=true end
                return normalized:sub(1,a-1)..patched..normalized:sub(b+1)
            end
            if not reported then mj:log("[StructuresPlusDetours] unsupported source; original behavior retained"); reported=true end
        end
        return text
    end
    -- Run after Hammerstone's loader registration. Let its patches run first;
    -- otherwise load this one native module through the reviewed overlay.
    local index = #package.loaders == 5 and 3 or (#package.loaders == 4 and 2 or nil)
    if index then
        table.insert(package.loaders,index,function(name)
            if name ~= "server/serverSapien" then return nil end
            local content = fileUtils.getFileContents(fileUtils.getResourcePath("scripts").."/server/serverSapien.lua")
            if type(content) ~= "string" or not content:find(replacement,1,true) then return nil end
            local fn,err = loadstring(content,"@StructuresPlusDetours/serverSapien.lua")
            if not fn then mj:log("[StructuresPlusDetours] compile failed: ",err) end
            return fn
        end)
    else
        mj:log("[StructuresPlusDetours] unfamiliar loader chain; fallback loader not installed")
    end
end
return mod
