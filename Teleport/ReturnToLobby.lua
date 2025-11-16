--[[
================================================================================
  ReturnToLobby.lua - REFACTORED AND MODERNIZED
================================================================================
  PURPOSE:
  - Manages the "Return to Lobby" button in the teleported place.
  - Securely requests a teleport back to the lobby.
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- CREATE UI
-- ============================================================================

local returnButton = Instance.new("TextButton")
returnButton.Size = UDim2.new(0, 200, 0, 50)
returnButton.Position = UDim2.new(0.5, -100, 0.8, 0)
returnButton.Text = "Return to Lobby"
returnButton.Parent = playerGui

-- ============================================================================
-- HANDLE CLICK
-- ============================================================================

returnButton.MouseButton1Click:Connect(function()
	local RequestTeleportToLobby = ReplicatedStorage:WaitForChild("RequestTeleportToLobby")
	RequestTeleportToLobby:FireServer()
end)
