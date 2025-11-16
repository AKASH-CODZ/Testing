--[[

SecurityLayers.lua (UPDATED)

Location: ReplicatedStorage/Modules/SecurityLayers.lua

Purpose: 3-layer security for teleport requests

]]

local GameStateManager = require(script.Parent:WaitForChild("GameStateManager"))
local Logger = require(script.Parent:WaitForChild("Logger"))
local SecurityLayers = {}

-- ============================================================================
-- LAYER 1: RATE LIMITING
-- ============================================================================

local playerRequestTimestamps = {}

function SecurityLayers:CheckRateLimit(player, cooldown)
	cooldown = cooldown or 5
	local now = tick()
	local lastRequest = playerRequestTimestamps[player]

	if lastRequest and (now - lastRequest < cooldown) then
		Logger:Warn("Security-Layer1", string.format("Rate limit rejected for %s", player.Name))
		return false, "Please wait before teleporting"
	end

	playerRequestTimestamps[player] = now
	return true
end

function SecurityLayers:ClearPlayerRateLimit(player)
	playerRequestTimestamps[player] = nil
end

-- ============================================================================
-- LAYER 2: WHITELIST VALIDATION
-- ============================================================================

function SecurityLayers:CheckWhitelistValidation(mode, validModes)
	if not validModes then
		Logger:Error("Security-Layer2", "No valid modes provided")
		return false, "System error"
	end

	if not validModes[mode] then
		Logger:Warn("Security-Layer2", string.format("Invalid mode: %s", mode))
		return false, "Invalid teleport mode"
	end

	return true
end

-- ============================================================================
-- LAYER 3: GAME STATE VALIDATION
-- ============================================================================

function SecurityLayers:CheckGameStateValidation(player, allowDeadPlayers)
	allowDeadPlayers = allowDeadPlayers or false

	local canTeleport = GameStateManager:CanPlayerTeleport(player, allowDeadPlayers)
	local playerState = GameStateManager:GetPlayerState(player)

	if not canTeleport then
		Logger:Warn("Security-Layer3", string.format("Cannot teleport %s from state: %s", player.Name, playerState))
		return false, string.format("Cannot teleport from %s state", playerState)
	end

	return true
end

-- ============================================================================
-- COMBINED: All Three Layers
-- ============================================================================

function SecurityLayers:ValidateTeleportRequest(player, mode, validModes, allowDeadPlayers, cooldown)
	local rateOk, rateMsg = self:CheckRateLimit(player, cooldown)
	if not rateOk then
		return false, rateMsg
	end

	local whitelistOk, whitelistMsg = self:CheckWhitelistValidation(mode, validModes)
	if not whitelistOk then
		return false, whitelistMsg
	end

	local stateOk, stateMsg = self:CheckGameStateValidation(player, allowDeadPlayers)
	if not stateOk then
		return false, stateMsg
	end

	Logger:Info("Security", string.format("%s passed all checks", player.Name))
	return true
end

function SecurityLayers:ClearAllPlayerLimits()
	playerRequestTimestamps = {}
end

return SecurityLayers
