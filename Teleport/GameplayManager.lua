--[[
================================================================================
  GameplayManager.lua - REFACTORED AND MODERNIZED
================================================================================
  PURPOSE:
  - Manages the gameplay logic for the teleported place.
  - Creates the "Win" and "Loss" blocks.
  - Securely updates player stats and rewards.
================================================================================
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================

local PlayerDataManager = require(ServerScriptService:WaitForChild("Player"):WaitForChild("PlayerManager"))
local GameConfig = require(game:GetService("ServerStorage"):WaitForChild("MyServerFolder"):WaitForChild("GameConfig"))

-- ============================================================================
-- CREATE WIN/LOSS BLOCKS
-- ============================================================================

local function CreateWinBlock()
	local part = Instance.new("Part")
	part.Size = Vector3.new(10, 1, 10)
	part.Position = Vector3.new(0, 0.5, 0)
	part.Color = Color3.fromRGB(0, 255, 0)
	part.Anchored = true
	part.Parent = workspace

	part.Touched:Connect(function(otherPart)
		local player = Players:GetPlayerFromCharacter(otherPart.Parent)
		if not player then return end

		local playerData = PlayerDataManager:GetData(player)
		if not playerData then return end

		playerData.stats.totalWins = (playerData.stats.totalWins or 0) + 1
		playerData.stats.StandardModePlays = (playerData.stats.StandardModePlays or 0) + 1
		playerData.coins = (playerData.coins or 0) + 100

		PlayerDataManager:SaveData(player, playerData)
	end)
end

local function CreateLossBlock()
	local part = Instance.new("Part")
	part.Size = Vector3.new(10, 1, 10)
	part.Position = Vector3.new(20, 0.5, 0)
	part.Color = Color3.fromRGB(255, 0, 0)
	part.Anchored = true
	part.Parent = workspace

	part.Touched:Connect(function(otherPart)
		local player = Players:GetPlayerFromCharacter(otherPart.Parent)
		if not player then return end

		local playerData = PlayerDataManager:GetData(player)
		if not playerData then return end

		playerData.stats.totalLosses = (playerData.stats.totalLosses or 0) + 1
		playerData.stats.StandardModePlays = (playerData.stats.StandardModePlays or 0) + 1

		PlayerDataManager:SaveData(player, playerData)
	end)
end

CreateWinBlock()
CreateLossBlock()
