local Players = game:GetService("Players")
local GameStateManager = {}

-- ============================================================================
-- PLAYER STATE STORAGE
-- ============================================================================

local playerStates = {} -- {UserId = "Lobby" | "Playing" | "Dead" | "Loading"}

-- ============================================================================
-- STATE CONSTANTS
-- ============================================================================

GameStateManager.States = {
	LOBBY = "Lobby",
	PLAYING = "Playing",
	DEAD = "Dead",
	LOADING = "Loading"
}

-- (Optimization) Define valid states once
local VALID_STATES = {
	[GameStateManager.States.LOBBY] = true,
	[GameStateManager.States.PLAYING] = true,
	[GameStateManager.States.DEAD] = true,
	[GameStateManager.States.LOADING] = true
}

-- ============================================================================
-- PRIVATE HELPER FUNCTION (NEW)
-- ============================================================================

--[[\
	Handles the bug where a function might receive a Player Instance
	or a UserId (number). This helper always returns the UserId.
]]
local function GetUserId(playerOrUserId)
	if typeof(playerOrUserId) == "Instance" then
		return playerOrUserId.UserId
	elseif typeof(playerOrUserId) == "number" then
		return playerOrUserId
	end
	return nil -- Invalid input
end

-- ============================================================================
-- SET PLAYER STATE (FIXED)
-- ============================================================================

function GameStateManager:SetPlayerState(playerOrUserId, newState)
	local userId = GetUserId(playerOrUserId) --- FIXED

	if not userId or not newState then --- FIXED (check userId)
		return false
	end

	if not VALID_STATES[newState] then
		return false, "Invalid state: " .. tostring(newState)
	end

	local oldState = playerStates[userId] --- FIXED
	playerStates[userId] = newState --- FIXED

	return true, oldState
end

-- ============================================================================
-- GET PLAYER STATE (FIXED)
-- ============================================================================

function GameStateManager:GetPlayerState(playerOrUserId)
	local userId = GetUserId(playerOrUserId) --- FIXED

	if not userId then --- FIXED
		return nil
	end

	return playerStates[userId] or self.States.LOBBY --- FIXED
end

-- ============================================================================
-- CHECK IF PLAYER CAN TELEPORT (No change needed)
-- ============================================================================

-- This function works as-is because it calls GetPlayerState, which we fixed.
function GameStateManager:CanPlayerTeleport(playerOrUserId, allowDeadPlayers)
	allowDeadPlayers = allowDeadPlayers or false

	local currentState = self:GetPlayerState(playerOrUserId)

	-- Using a lookup table for cleaner logic
	local teleportRules = {
		[self.States.LOBBY] = true,
		[self.States.PLAYING] = false,
		[self.States.DEAD] = allowDeadPlayers,
		[self.States.LOADING] = false
	}

	return teleportRules[currentState] or false
end

-- ============================================================================
-- MARK AS LOADING (No change needed)
-- ============================================================================

function GameStateManager:MarkAsLoading(playerOrUserId)
	return self:SetPlayerState(playerOrUserId, self.States.LOADING)
end

-- ============================================================================
-- MARK AS PLAYING (No change needed)
-- ============================================================================

function GameStateManager:MarkAsPlaying(playerOrUserId)
	return self:SetPlayerState(playerOrUserId, self.States.PLAYING)
end

-- ============================================================================
-- MARK AS DEAD (No change needed)
-- ============================================================================

function GameStateManager:MarkAsDead(playerOrUserId)
	return self:SetPlayerState(playerOrUserId, self.States.DEAD)
end

-- ============================================================================
-- MARK AS LOBBY (RETURN TO LOBBY) (No change needed)
-- ============================================================================

function GameStateManager:MarkAsLobby(playerOrUserId)
	return self:SetPlayerState(playerOrUserId, self.States.LOBBY)
end

-- ============================================================================
-- CLEANUP ON DISCONNECT (FIXED)
-- ============================================================================

function GameStateManager:ClearPlayerState(playerOrUserId)
	local userId = GetUserId(playerOrUserId) --- FIXED
	if userId then
		playerStates[userId] = nil --- FIXED
	end
end

-- ============================================================================
-- AUTO-CLEANUP ON PLAYER LEAVING
-- ============================================================================

Players.PlayerRemoving:Connect(function(player)
	-- This works because the 'player' from PlayerRemoving is always an instance
	GameStateManager:ClearPlayerState(player)
end)

return GameStateManager