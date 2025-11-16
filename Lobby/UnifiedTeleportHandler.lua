--[[
================================================================================
  UnifiedTeleportHandler.lua - REFACTORED AND MODERNIZED
================================================================================
  PURPOSE:
  - Handles all teleportation logic, both inbound and outbound.
  - Restores player inventory on join.
  - Manages the entire teleportation process.
================================================================================
]]

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================

local GameStateManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameStateManager"))
local SecurityManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SecurityManager"))
local PlayerDataManager = require(ServerScriptService:WaitForChild("Player"):WaitForChild("PlayerManager"))

-- ============================================================================
-- ON PLAYER JOIN
-- ============================================================================

local function OnPlayerJoined(player)
	GameStateManager:SetPlayerState(player, GameStateManager.States.LOADING)

	local teleportData = TeleportService:GetLocalPlayerTeleportData()

	if teleportData and SecurityManager:ValidateNonce(player, teleportData.nonce) and SecurityManager:ValidateInventory(teleportData.inventory) then
		PlayerDataManager:SaveData(player, teleportData.inventory)
	else
		PlayerDataManager:LoadData(player)
	end

	GameStateManager:SetPlayerState(player, GameStateManager.States.PLAYING)
end

-- ============================================================================
-- ON PLAYER LEAVING
-- ============================================================================

local function OnPlayerLeaving(player)
	PlayerDataManager:EmergencySave(player)
	GameStateManager:ClearPlayerState(player)
end

-- ============================================================================
-- TELEPORT TO MATCH
-- ============================================================================

local UnifiedTeleportHandler = {}

function UnifiedTeleportHandler:TeleportToMatch(player, placeId)
	local inventory = PlayerDataManager:GetData(player)
	if not inventory then return false end

	if not SecurityManager:ValidateLoadout(inventory, inventory.equipped) then return false end

	local nonce = SecurityManager:GenerateAndSaveNonce(player, 60)
	if not nonce then return false end

	local teleportData = {
		inventory = inventory,
		equipped = inventory.equipped,
		nonce = nonce,
	}

	TeleportService:Teleport(placeId, player, teleportData)
	return true
end

function UnifiedTeleportHandler:TeleportToLobby(player)
	local inventory = PlayerDataManager:GetData(player)
	if not inventory then return false end

	local gameConfig = require(game:GetService("ServerStorage"):WaitForChild("MyServerFolder"):WaitForChild("GameConfig"))
	local lobbyPlaceId = gameConfig.TeleportModes["Lobby"].PlaceID

	local nonce = SecurityManager:GenerateAndSaveNonce(player, 60)
	if not nonce then return false end

	local teleportData = {
		inventory = inventory,
		equipped = inventory.equipped,
		nonce = nonce,
	}

	TeleportService:Teleport(lobbyPlaceId, player, teleportData)
	return true
end

-- = '==========================================================================
-- EVENT CONNECTIONS
-- ============================================================================

Players.PlayerAdded:Connect(OnPlayerJoined)
Players.PlayerRemoving:Connect(OnPlayerLeaving)

for _, player in pairs(Players:GetPlayers()) do
	task.spawn(OnPlayerJoined, player)
end

return UnifiedTeleportHandler
