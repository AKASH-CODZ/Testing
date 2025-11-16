--[[
Logger.lua
Location: ReplicatedStorage/Modules/Logger.lua (ModuleScript)
PURPOSE: Admin-only logging that works in Studio and in-game
FIXES: Uses GameConfig admin check, studio mode support
]]

local GameConfig = require(game:GetService("ServerStorage"):WaitForChild("MyServerFolder"):WaitForChild("GameConfig"))
local Logger = {}

-- ============================================================================
-- LOGGING (Admin-only - studio-safe)
-- ============================================================================

function Logger:Info(source, msg, player)
	if player and not GameConfig:IsAdmin(player) then return end
	print("[" .. source .. "][INFO] " .. tostring(msg))
end

function Logger:Warn(source, msg, player)
	if player and not GameConfig:IsAdmin(player) then return end
	warn("[" .. source .. "][WARN] " .. tostring(msg))
end

function Logger:Error(source, msg, player)
	if player and not GameConfig:IsAdmin(player) then return end
	warn("[" .. source .. "][ERROR] " .. tostring(msg))
end

function Logger:Debug(source, msg, player)
	if player and not GameConfig:IsAdmin(player) then return end
	print("[" .. source .. "][DEBUG] " .. tostring(msg))
end

return Logger
