--[[
================================================================================
  PlayerDataHandler.lua
================================================================================
  - **Purpose:** Defines the data structure for player profiles.
  - **Location:** ServerScriptService/Modules
  - **Type:** ModuleScript
================================================================================
]]

local PlayerDataHandler = {}

PlayerDataHandler.ProfileTemplate = {
    TotalWins = 0,
    owned = {},
    equipped = {},
}

return PlayerDataHandler
