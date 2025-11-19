--[[
================================================================================
  LoadoutManager.lua
================================================================================
  - **Purpose:** Retrieves player loadouts from the MemoryStoreQueue.
  - **Location:** ServerScriptService
  - **Type:** ModuleScript
================================================================================
]]

local MemoryStoreService = game:GetService("MemoryStoreService")
local Logger = require(script.Parent:WaitForChild("Logger"))

local LoadoutManager = {}

local MemoryStoreQueue = MemoryStoreService:GetQueue("Loadouts", 60)
local loadouts = {}

function LoadoutManager:GetLoadout(player)
    return loadouts[tostring(player.UserId)]
end

local function retrieveLoadouts()
    local success, result = pcall(function()
        return MemoryStoreQueue:ReadAsync(game.PrivateServerId, 1, 60)
    end)

    if success and result then
        loadouts = result
        Logger:Info("LoadoutManager", "Successfully retrieved loadouts for this server.")
    else
        Logger:Error("LoadoutManager", "Failed to retrieve loadouts for this server: " .. tostring(result))
    end
end

retrieveLoadouts()

return LoadoutManager
