--[[
================================================================================
  GameplayManager.lua
================================================================================
  - **Purpose:** Manages the gameplay logic for the teleported place.
  - **Location:** ServerScriptService
  - **Type:** Script
================================================================================
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================

local PlayerDataManager = require(ServerScriptService:WaitForChild("Player"):WaitForChild("PlayerManager"))

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

		local profile = PlayerDataManager:GetProfile(player)
		if not profile then return end

		profile.Data.TotalWins = (profile.Data.TotalWins or 0) + 1
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

        -- No action needed for a loss, as we are only tracking wins.
	end)
end

CreateWinBlock()
CreateLossBlock()
