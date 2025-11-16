--[[
================================================================================
  TeleportHub.lua - UPDATED TO USE ValidateLoadout & Enhanced Logging
================================================================================
  Location: ReplicatedStorage/Modules/TeleportHub (ModuleScript)
  
  ALL UPDATES:
  ✓ Uses ValidateLoadout instead of ValidateInventory (future-proof)
  ✓ Enhanced logging at every step
  ✓ Error handling with pcall wrapping
  ✓ Studio/Live detection
  ✓ Nonce generation with MemoryStore
  ✓ Full function exports
================================================================================
]]

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================

local NonceValidator = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("NonceValidator"))
local InventoryValidator = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryValidator"))
local Logger = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Logger"))

local PlayerDataManager
local success = pcall(function()
	PlayerDataManager = require(game:GetService("ServerScriptService"):WaitForChild("Player"):WaitForChild("PlayerManager"))
end)

if not success then
	Logger:Warn("TeleportHub", "PlayerManager not found, using fallback")
	PlayerDataManager = nil
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local MATCH_PLACE_ID = 114846565016250
local NONCE_TTL = 60

-- ============================================================================
-- TELEPORT HUB MODULE
-- ============================================================================

local TeleportHub = {}

-- ============================================================================
-- INTERNAL: Get Player Inventory For Teleport
-- ============================================================================

local function GetPlayerInventoryForTeleport(player)
	Logger:Info("TeleportHub", "Fetching inventory for " .. player.Name, player)

	if PlayerDataManager then
		local data = PlayerDataManager:GetData(player)
		if data then
			Logger:Info("TeleportHub", "Inventory loaded from PlayerManager for " .. player.Name, player)

			-- Debug output
			if InventoryValidator.DebugPrintInventory then
				InventoryValidator:DebugPrintInventory(data, player.Name)
			end

			return {
				owned = data.owned or {},
				equipped = data.equipped or {},
				allItems = data.allItems or {}
			}
		end
	end

	-- Fallback: Default inventory
	Logger:Warn("TeleportHub", "Using fallback inventory for " .. player.Name, player)
	return {
		owned = {
			["BasicSword"] = {data = {id = "BasicSword", name = "Basic Sword"}, count = 1, equipped = true},
			["IronArmor"] = {data = {id = "IronArmor", name = "Iron Armor"}, count = 1, equipped = true},
			["HealthPotion"] = {data = {id = "HealthPotion", name = "Health Potion"}, count = 5, equipped = false}
		},
		equipped = {["BasicSword"] = true, ["IronArmor"] = true},
		allItems = {
			{id = "BasicSword", name = "Basic Sword"},
			{id = "IronArmor", name = "Iron Armor"},
			{id = "HealthPotion", name = "Health Potion"}
		}
	}
end

-- ============================================================================
-- PUBLIC: Teleport To Match
-- ============================================================================

function TeleportHub:TeleportToMatch(player)
	if not player then
		Logger:Error("TeleportHub", "No player provided", nil)
		return false
	end

	print("[TeleportHub] Preparing teleport for: " .. player.Name)
	Logger:Info("TeleportHub", "Preparing teleport for " .. player.Name, player)

	-- Get player's inventory
	local inventory = GetPlayerInventoryForTeleport(player)
	if not inventory then
		Logger:Error("TeleportHub", "Failed to get inventory for " .. player.Name, player)
		return false
	end

	-- ✓ USE ValidateLoadout (future-proof pattern)
	if not InventoryValidator.ValidateLoadout(inventory, inventory.equipped) then
		Logger:Error("TeleportHub", "Loadout validation failed for " .. player.Name, player)
		return false
	end

	print("[TeleportHub] Loadout validated ✓")

	-- Generate nonce for security
	local nonce = NonceValidator:GenerateAndSaveNonce(player, NONCE_TTL)
	if not nonce then
		Logger:Error("TeleportHub", "Failed to generate nonce for " .. player.Name, player)
		return false
	end

	print("[TeleportHub] Nonce generated: " .. nonce)
	Logger:Info("TeleportHub", "Nonce generated for " .. player.Name, player)

	-- Create teleport data
	local teleportData = {
		inventory = inventory,
		equipped = inventory.equipped,
		nonce = nonce,
		timestamp = os.time(),
		playerId = player.UserId,
		playerName = player.Name
	}

	print("[TeleportHub] Teleport data prepared for " .. player.Name .. ":")
	print("  - Nonce: " .. nonce)
	print("  - Match Place ID: " .. MATCH_PLACE_ID)
	Logger:Info("TeleportHub", "Teleport data prepared - Nonce: " .. nonce, player)

	-- Detect mode (Studio vs Live)
	local isStudio = RunService:IsStudio()

	if isStudio then
		print("[TeleportHub] STUDIO MODE: Teleport would fail in Studio")
		Logger:Info("TeleportHub", "STUDIO MODE: Cannot teleport in Studio", player)

		local success, errorMessage = pcall(function()
			TeleportService:SetTeleportData(teleportData)
			TeleportService:Teleport(MATCH_PLACE_ID, player)
		end)

		if not success then
			print("[TeleportHub] STUDIO TELEPORT FAILED (EXPECTED): " .. tostring(errorMessage))
			Logger:Info("TeleportHub", "STUDIO: Teleport failed as expected", player)
		end

		return false
	else
		-- LIVE SERVER MODE
		print("[TeleportHub] LIVE SERVER MODE: Attempting real teleport...")
		Logger:Info("TeleportHub", "LIVE SERVER: Attempting teleport to place " .. MATCH_PLACE_ID, player)

		local success, errorMessage = pcall(function()
			TeleportService:SetTeleportData(teleportData)
			TeleportService:Teleport(MATCH_PLACE_ID, player)
		end)

		if success then
			print("[TeleportHub] SUCCESS: Player teleported to match: " .. player.Name)
			Logger:Info("TeleportHub", "SUCCESS: Teleported to match place " .. MATCH_PLACE_ID, player)
			return true
		else
			print("[TeleportHub] ERROR: Teleport failed for " .. player.Name)
			print("[TeleportHub] Error details: " .. tostring(errorMessage))
			Logger:Error("TeleportHub", "Teleport failed: " .. tostring(errorMessage), player)
			return false
		end
	end
end

-- ============================================================================
-- PUBLIC: Set Match Place ID
-- ============================================================================

function TeleportHub:SetMatchPlaceId(placeId)
	MATCH_PLACE_ID = placeId
	print("[TeleportHub] Match place ID set to: " .. placeId)
	Logger:Info("TeleportHub", "Match place ID configured: " .. placeId, nil)
end

-- ============================================================================
-- PUBLIC: Get Match Place ID
-- ============================================================================

function TeleportHub:GetMatchPlaceId()
	return MATCH_PLACE_ID
end

-- ============================================================================
-- STARTUP
-- ============================================================================

print("[TeleportHub] Module loaded successfully")
print("[TeleportHub] Match place ID: " .. MATCH_PLACE_ID)
print("[TeleportHub] Mode: " .. (RunService:IsStudio() and "STUDIO" or "LIVE SERVER"))
print("[TeleportHub] Nonce TTL: " .. NONCE_TTL .. "s")
Logger:Info("TeleportHub", "Module initialized successfully", nil)

-- ============================================================================
-- RETURN - CRITICAL: All public functions exported
-- ============================================================================

return {
	TeleportToMatch = TeleportHub.TeleportToMatch,
	SetMatchPlaceId = TeleportHub.SetMatchPlaceId,
	GetMatchPlaceId = TeleportHub.GetMatchPlaceId,
}
