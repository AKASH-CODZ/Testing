--[[
================================================================================
  TeleportRequestHandler.lua - REFACTORED AND MODERNIZED
================================================================================
  PURPOSE:
  - Listens for teleport requests from the client and initiates the
    teleport process.
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================

local UnifiedTeleportHandler = require(game:GetService("ServerScriptService"):WaitForChild("Gameplay"):WaitForChild("UnifiedTeleportHandler"))
local GameConfig = require(game:GetService("ServerStorage"):WaitForChild("MyServerFolder"):WaitForChild("GameConfig"))

-- ============================================================================
-- REMOTE EVENT
-- ============================================================================

local RequestTeleportToMatch = ReplicatedStorage:FindFirstChild("RequestTeleportToMatch") or Instance.new("RemoteEvent", ReplicatedStorage)
RequestTeleportToMatch.Name = "RequestTeleportToMatch"

-- ============================================================================
-- HANDLE TELEPORT REQUEST
-- ============================================================================

RequestTeleportToMatch.OnServerEvent:Connect(function(player, mode)
	local modeConfig = GameConfig.TeleportModes[mode]
	if not modeConfig then return end

	UnifiedTeleportHandler:TeleportToMatch(player, modeConfig.PlaceID)
end)
