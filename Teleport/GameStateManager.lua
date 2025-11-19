--[[
================================================================================
  GameStateManager.lua
================================================================================
  - **Purpose:** Manages the state of each player (e.g., Lobby, Playing, Dead).
  - **Location:** ReplicatedStorage/Modules
  - **Type:** ModuleScript
================================================================================
]]

local Players = game:GetService("Players")
local GameStateManager = {}

-- ============================================================================
-- PLAYER STATE STORAGE
-- ============================================================================

local playerStates = {} -- { [userId] = "Lobby" | "Playing" | "Dead" | "Loading" }

-- ============================================================================
-- STATE CONSTANTS
-- ============================================================================

GameStateManager.States = {
	LOBBY = "Lobby",
	PLAYING = "Playing",
	DEAD = "Dead",
	LOADING = "Loading"
}

-- ============================================================================
-- HELPER: GET USER ID
-- ============================================================================

local function GetUserId(playerOrUserId)
	if typeof(playerOrUserId) == "Instance" then
		return playerOrUserId.UserId
	elseif typeof(playerOrUserId) == "number" then
		return playerOrUserId
	end
	return nil
end

-- ============================================================================
-- SET AND GET PLAYER STATE
-- ============================================================================

function GameStateManager:SetPlayerState(playerOrUserId, newState)
	local userId = GetUserId(playerOrUserId)
	if not userId or not self.States[newState] then
		return false
	end

	playerStates[userId] = newState
	return true
end

function GameStateManager:GetPlayerState(playerOrUserId)
	local userId = GetUserId(playerOrUserId)
	return playerStates[userId] or self.States.LOBBY
end

-- ============================================================================
-- CLEANUP ON DISCONNECT
-- ============================================================================

function GameStateManager:ClearPlayerState(playerOrUserId)
	local userId = GetUserId(playerOrUserId)
	if userId then
		playerStates[userId] = nil
	end
end

-- ============================================================================
-- AUTO-CLEANUP ON PLAYER LEAVING
-- ============================================================================

Players.PlayerRemoving:Connect(function(player)
	GameStateManager:ClearPlayerState(player)
end)

return GameStateManager
