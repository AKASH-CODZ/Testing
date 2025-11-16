--[[
================================================================================
  LogPlayerStats.lua - REFACTORED AND MODERNIZED
================================================================================
  PURPOSE:
  - Logs the player's stats to the console when they join the lobby.
================================================================================
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================

local PlayerDataManager = require(ServerScriptService:WaitForChild("Player"):WaitForChild("PlayerManager"))
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Logger"))

-- ============================================================================
-- ON PLAYER JOIN
-- ============================================================================

local function OnPlayerJoined(player)
	local playerData = PlayerDataManager:GetData(player)
	if not playerData or not playerData.stats then return end

	Logger:Admin(player, "PlayerStats", "Total Wins: " .. playerData.stats.totalWins)
	Logger:Admin(player, "PlayerStats", "Total Losses: " .. playerData.stats.totalLosses)
	Logger:Admin(player, "PlayerStats", "Standard Mode Plays: " .. playerData.stats.StandardModePlays)
end

Players.PlayerAdded:Connect(OnPlayerJoined)

for _, player in pairs(Players:GetPlayers()) do
	task.spawn(OnPlayerJoined, player)
end
