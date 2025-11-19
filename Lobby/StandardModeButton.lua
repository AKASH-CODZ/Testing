--[[
================================================================================
  StandardModeButton.lua
================================================================================
  - **Purpose:** Handles the functionality of a UI button that initiates a teleport
    to a specific game mode.
  - **Location:** StarterPlayer/StarterPlayerScripts/UI
  - **Type:** LocalScript
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local BUTTON_MODE = "Training" -- Options: StandardMode, Training, TeamDeathmatch, HardcoreMode, SquadMission

-- ============================================================================
-- MAIN BUTTON CLICK HANDLER
-- ============================================================================

script.Parent.MouseButton1Click:Connect(function()
	local RequestTeleportToMatch = ReplicatedStorage:WaitForChild("RequestTeleportToMatch")
	RequestTeleportToMatch:FireServer(BUTTON_MODE)
end)
