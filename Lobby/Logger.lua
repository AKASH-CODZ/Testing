--[[
================================================================================
  Logger.lua
================================================================================
  - **Purpose:** Provides a simple and robust logging system.
  - **Location:** ReplicatedStorage/Modules
  - **Type:** ModuleScript
================================================================================
]]

local GameConfig = require(game:GetService("ServerStorage"):WaitForChild("MyServerFolder"):WaitForChild("GameConfig"))
local Logger = {}

-- ============================================================================
-- LOGGING
-- ============================================================================

function Logger:Info(source, msg)
	print("[" .. source .. "][INFO] " .. tostring(msg))
end

function Logger:Warn(source, msg)
	warn("[" .. source .. "][WARN] " .. tostring(msg))
end

function Logger:Error(source, msg)
	warn("[" .. source .. "][ERROR] " .. tostring(msg))
end

function Logger:Debug(source, msg)
	print("[" .. source .. "][DEBUG] " .. tostring(msg))
end

function Logger:Admin(player, source, msg)
	if GameConfig:IsAdmin(player) then
		print("[" .. source .. "][ADMIN] " .. tostring(msg))
	end
end

return Logger
