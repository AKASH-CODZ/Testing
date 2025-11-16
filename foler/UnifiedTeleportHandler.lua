--[[
================================================================================
  UnifiedTeleportHandler.lua - COMPLETE MATCH PLACE HANDLER (Final v3)
================================================================================
  Location: ServerScriptService/Gameplay/UnifiedTeleportHandler (ServerScript)
  
  PURPOSE:
  - Handles player join on match/training place
  - Restores inventory from teleport data OR datastore
  - Studio vs Live detection & handling
  - Persistence: saves loadout on join, loads on leave
  - Enhanced logging for debugging
  - No "No teleport data" warning (silent fallback)
  
  ALL UPDATES:
  ✓ Studio: Loads from datastore (persists loadout)
  ✓ Live with teleport: Restores from TeleportData
  ✓ Live without teleport: Loads from datastore (silent)
  ✓ No unwanted warnings
  ✓ Enhanced Logger integration
  ✓ Saves on player leave
================================================================================
]]

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================

local GameStateManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameStateManager"))
local Logger = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Logger"))
local NonceValidator = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NonceValidator"))
local InventoryValidator = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryValidator"))
local PlayerDataManager = require(ServerScriptService:WaitForChild("Player"):WaitForChild("PlayerManager"))

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

print("[UnifiedTeleportHandler] Initializing on match place...")
Logger:Info("UnifiedTeleportHandler", "Match place initialized")

-- ============================================================================
-- HELPER: Format Inventory For Display
-- ============================================================================

local function FormatInventoryStats(inventory)
	if not inventory or not inventory.owned then
		return "0 items (empty)"
	end

	local itemCount = 0
	for _ in pairs(inventory.owned) do
		itemCount = itemCount + 1
	end

	local equippedCount = 0
	if inventory.equipped then
		for _ in pairs(inventory.equipped) do
			equippedCount = equippedCount + 1
		end
	end

	return itemCount .. " items (" .. equippedCount .. " equipped)"
end

-- ============================================================================
-- RESTORE FROM TELEPORT DATA
-- ============================================================================

local function RestoreLoadoutFromTeleportData(player, teleportData)
	if not teleportData then
		return false
	end

	print("[UnifiedTeleportHandler] Restoring inventory from teleport data: " .. player.Name)
	Logger:Info("UnifiedTeleportHandler", "Restoring from teleport data", player)

	-- Parse teleport data
	local inventory = teleportData.inventory
	local equipped = teleportData.equipped
	local nonce = teleportData.nonce

	if not inventory or not equipped then
		print("[UnifiedTeleportHandler] WARNING: Invalid inventory structure in teleport data")
		Logger:Warn("UnifiedTeleportHandler", "Invalid teleport data structure", player)
		return false
	end

	-- Validate nonce for security
	if not nonce then
		print("[UnifiedTeleportHandler] WARNING: No nonce in teleport data")
		return false
	end

	if not  NonceValidator:ValidateNonce(player, nonce) then
		print("[UnifiedTeleportHandler] SECURITY: Invalid nonce for " .. player.Name)
		Logger:Warn("UnifiedTeleportHandler", "Invalid nonce", player)
		return false
	end

	-- Validate inventory structure
	if not InventoryValidator:ValidateInventory(inventory) then
		print("[UnifiedTeleportHandler] WARNING: Invalid inventory data")
		return false
	end

	-- Save inventory to persistent storage
	local playerData = {
		owned = inventory.owned or {},
		equipped = inventory.equipped or equipped or {},
		allItems = inventory.allItems or {}
	}

	PlayerDataManager:SaveData(player, playerData)

	print("[UnifiedTeleportHandler] SUCCESS: Inventory restored from teleport")
	print("[UnifiedTeleportHandler]   - " .. FormatInventoryStats(inventory))
	Logger:Info("UnifiedTeleportHandler", "Inventory restored from teleport", player)

	return true
end

-- ============================================================================
-- PLAYER JOIN HANDLER
-- ============================================================================

local function OnPlayerJoined(player)
	print("[UnifiedTeleportHandler] Player joined match: " .. player.Name)
	Logger:Info("UnifiedTeleportHandler", "Player joined match: " .. player.Name)

	-- Set game state
	GameStateManager:SetPlayerState(player, GameStateManager.States.LOADING)

	local isStudio = RunService:IsStudio()
	local restoredSuccessfully = false

	if isStudio then
		-- ✓ STUDIO MODE: Load from datastore (persists loadout)
		print("[UnifiedTeleportHandler] STUDIO MODE: Loading player data from datastore")
		Logger:Info("UnifiedTeleportHandler", "STUDIO: Loading from datastore", player)

		local playerData = PlayerDataManager:LoadData(player)

		if playerData and next(playerData.owned) then
			print("[UnifiedTeleportHandler] SUCCESS: Loaded existing loadout")
			print("[UnifiedTeleportHandler]   - " .. FormatInventoryStats(playerData))
			Logger:Info("UnifiedTeleportHandler", "Loaded existing loadout from datastore", player)
			restoredSuccessfully = true
		else
			print("[UnifiedTeleportHandler] No saved data found, using defaults")
			Logger:Info("UnifiedTeleportHandler", "No saved data, using defaults", player)
		end

	else
		-- ✓ LIVE SERVER MODE: Try teleport data first, then datastore
		local success, teleportData = pcall(function()
			return TeleportService:GetLocalPlayerTeleportData()
		end)

		if success and teleportData then
			-- Teleport data exists - restore from it
			print("[UnifiedTeleportHandler] LIVE SERVER: Teleport data found")
			Logger:Info("UnifiedTeleportHandler", "LIVE: Teleport data found", player)

			restoredSuccessfully = RestoreLoadoutFromTeleportData(player, teleportData)

			if not restoredSuccessfully then
				-- Teleport data invalid - fallback to datastore
				print("[UnifiedTeleportHandler] LIVE SERVER: Teleport data invalid, loading from datastore")
				Logger:Warn("UnifiedTeleportHandler", "Teleport data invalid, fallback to datastore", player)

				local playerData = PlayerDataManager:LoadData(player)
				if playerData and next(playerData.owned) then
					print("[UnifiedTeleportHandler] SUCCESS: Loaded from datastore fallback")
					print("[UnifiedTeleportHandler]   - " .. FormatInventoryStats(playerData))
					restoredSuccessfully = true
				end
			end
		else
			-- No teleport data (direct join or teleport disabled)
			-- ✓ SILENT: No warning, just load from datastore
			print("[UnifiedTeleportHandler] LIVE SERVER: Loading from datastore")
			Logger:Info("UnifiedTeleportHandler", "LIVE: Direct join, loading from datastore", player)

			local playerData = PlayerDataManager:LoadData(player)

			if playerData and next(playerData.owned) then
				print("[UnifiedTeleportHandler] SUCCESS: Loaded existing loadout")
				print("[UnifiedTeleportHandler]   - " .. FormatInventoryStats(playerData))
				Logger:Info("UnifiedTeleportHandler", "Loaded from datastore", player)
				restoredSuccessfully = true
			else
				print("[UnifiedTeleportHandler] No saved data found, using defaults")
			end
		end
	end

	GameStateManager:SetPlayerState(player, GameStateManager.States.PLAYING)

	if restoredSuccessfully then
		print("[UnifiedTeleportHandler] ✓ Ready for gameplay")
	end
end

-- ============================================================================
-- PLAYER LEAVE HANDLER
-- ============================================================================

local function OnPlayerLeaving(player)
	print("[UnifiedTeleportHandler] Player leaving: " .. player.Name)
	Logger:Info("UnifiedTeleportHandler", "Player leaving: " .. player.Name)

	-- ✓ SAVE: Emergency save of player data on leave (persistence)
	PlayerDataManager:EmergencySave(player)

	GameStateManager:ClearPlayerState(player.UserId)

	print("[UnifiedTeleportHandler] Player data saved")
end

-- ============================================================================
-- EVENT CONNECTIONS
-- ============================================================================

Players.PlayerAdded:Connect(OnPlayerJoined)
Players.PlayerRemoving:Connect(OnPlayerLeaving)

-- Handle players who join before script loads
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(OnPlayerJoined, player)
end

print("[UnifiedTeleportHandler] Event handlers connected")
print("[UnifiedTeleportHandler] Mode: " .. (RunService:IsStudio() and "STUDIO" or "LIVE SERVER"))
print("[UnifiedTeleportHandler] Ready!")

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
