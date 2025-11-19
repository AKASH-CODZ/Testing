--[[
================================================================================
  SecurityManager.lua
================================================================================
  - **Purpose:** Consolidates all security-related logic, including nonce validation,
    inventory validation, and rate-limiting, into a single, robust module.
  - **Location:** ReplicatedStorage/Modules
  - **Type:** ModuleScript
================================================================================
]]

local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Logger = require(Modules:WaitForChild("Logger"))
local GameStateManager = require(Modules:WaitForChild("GameStateManager"))
local SecurityManager = {}

local success, TeleportNonces = pcall(function()
	return MemoryStoreService:GetSortedMap("TeleportNonces")
end)

if not success then
	Logger:Error("SecurityManager", "Failed to get MemoryStoreService SortedMap. Nonce validation will be disabled.")
	TeleportNonces = nil
end

-- ============================================================================
-- HELPER: Retry with exponential backoff
-- ============================================================================

local function RetryWithBackoff(operation, maxRetries, initialDelay)
	maxRetries = maxRetries or 3
	initialDelay = initialDelay or 1

	for attempt = 1, maxRetries do
		local success, result = pcall(operation)
		if success then
			return true, result
		end

		if attempt < maxRetries then
			local delay = initialDelay * (2 ^ (attempt - 1))
			Logger:Debug("MemoryStore", string.format("Retry %d/%d, wait %.1fs", attempt, maxRetries, delay))
			task.wait(delay)
		end
	end

	return false, "Failed after " .. maxRetries .. " attempts"
end

-- ============================================================================
-- LAYER 1: RATE LIMITING
-- ============================================================================

local playerRequestTimestamps = {}

function SecurityManager:CheckRateLimit(player, cooldown)
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

-- ============================================================================
-- NONCE GENERATION (OUTBOUND)
-- ============================================================================

function SecurityManager:GenerateAndSaveNonce(player, ttl)
	if not TeleportNonces then return nil end
	ttl = ttl or 60
	local nonce = HttpService:GenerateGUID(false)

	local success, err = RetryWithBackoff(function()
		TeleportNonces:SetAsync(nonce, player.UserId, ttl)
	end, 3, 1)

	if not success then
		Logger:Error("Nonce", string.format("Failed to generate nonce for %s: %s", player.Name, err))
		return nil
	end

	Logger:Debug("Nonce", string.format("Generated nonce for %s (TTL: %ds)", player.Name, ttl))
	return nonce
end

-- ============================================================================
-- NONCE VALIDATION (INBOUND)
-- ============================================================================

function SecurityManager:ValidateNonce(player, nonce)
	if not TeleportNonces then return false end
	if not nonce or type(nonce) ~= "string" then
		Logger:Warn("Nonce", string.format("Invalid nonce format for %s", player.Name))
		return false
	end

	local success, storedUserId = RetryWithBackoff(function()
		return TeleportNonces:GetAsync(nonce)
	end, 3, 1)

	if not success then
		Logger:Error("Nonce", string.format("MemoryStore query failed for %s", player.Name))
		return false
	end

	if storedUserId ~= player.UserId then
		Logger:Warn("Nonce", string.format("Validation FAILED for %s (UserId mismatch)", player.Name))
		return false
	end

	RetryWithBackoff(function()
		TeleportNonces:RemoveAsync(nonce)
	end, 2, 0.5)

	Logger:Info("Nonce", string.format("Nonce validated for %s", player.Name))
	return true
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local REQUIRED_INVENTORY_KEYS = {"owned", "equipped", "allItems"}
local MAX_ITEMS_PER_PLAYER = 999
local VALID_ITEM_TYPES = {["table"] = true, ["string"] = true}

-- ============================================================================
-- VALIDATE INVENTORY STRUCTURE
-- ============================================================================
function SecurityManager:ItemExists(inventory, itemId)
	if not inventory or type(inventory) ~= "table" then
		Logger:Warn("InventoryValidator", "Cannot check ItemExists - inventory invalid")
		return false
	end
	if not itemId then
		Logger:Warn("InventoryValidator", "No itemId provided to ItemExists")
		return false
	end
	if inventory.owned and inventory.owned[itemId] then
		Logger:Info("InventoryValidator", "Item " .. tostring(itemId) .. " exists in inventory")
		return true
	end
	Logger:Info("InventoryValidator", "Item " .. tostring(itemId) .. " does NOT exist in inventory")
	return false
end

function SecurityManager:GetAllItems(inventory)
	if not inventory or type(inventory) ~= "table" then
		Logger:Warn("InventoryValidator", "Cannot get all items - inventory invalid")
		return {}
	end
	local all = {}
	if inventory.allItems then
		all = inventory.allItems
	else
		-- Fallback: gather from owned
		for itemId, data in pairs(inventory.owned or {}) do
			table.insert(all, data)
		end
	end
	Logger:Info("InventoryValidator", "GetAllItems returned " .. tostring(#all) .. " items")
	return all
end


function SecurityManager:ValidateInventory(inventory)
	if not inventory then
		Logger:Error("InventoryValidator", "Inventory is nil")
		return false
	end

	if type(inventory) ~= "table" then
		Logger:Error("InventoryValidator", "Inventory is not a table, got: " .. type(inventory))
		return false
	end

	-- Check required keys
	for _, key in ipairs(REQUIRED_INVENTORY_KEYS) do
		if not inventory[key] then
			Logger:Warn("InventoryValidator", "Missing required key: " .. key)
			return false
		end
	end

	-- Validate owned items count
	local ownedCount = 0
	for _ in pairs(inventory.owned) do
		ownedCount = ownedCount + 1
	end

	if ownedCount > MAX_ITEMS_PER_PLAYER then
		Logger:Error("InventoryValidator", "Too many items: " .. ownedCount .. " > " .. MAX_ITEMS_PER_PLAYER)
		return false
	end

	-- Validate equipped references
	if type(inventory.equipped) ~= "table" then
		Logger:Error("InventoryValidator", "Equipped is not a table")
		return false
	end

	-- Check that all equipped items exist in owned
	for itemId, equipped in pairs(inventory.equipped) do
		if equipped and not inventory.owned[itemId] then
			Logger:Warn("InventoryValidator", "Equipped item not found in owned: " .. itemId)
			return false
		end
	end

	Logger:Info("InventoryValidator", "Inventory validation PASSED ✓ (" .. ownedCount .. " items)")
	return true
end

-- ============================================================================
-- VALIDATE LOADOUT (Preferred pattern)
-- ============================================================================

function SecurityManager:ValidateLoadout(playerInventory, loadout)
	if not playerInventory then
		Logger:Error("InventoryValidator", "PlayerInventory is nil for loadout validation")
		return false
	end

	if not loadout then
		Logger:Warn("InventoryValidator", "Loadout is nil, using empty loadout")
		loadout = {}
	end

	if type(loadout) ~= "table" then
		Logger:Error("InventoryValidator", "Loadout is not a table, got: " .. type(loadout))
		return false
	end

	-- Validate that all loadout items exist in inventory
	for itemId, equipped in pairs(loadout) do
		if equipped then  -- If item is marked equipped
			if not playerInventory.owned or not playerInventory.owned[itemId] then
				Logger:Warn("InventoryValidator", "Loadout item not found in inventory: " .. tostring(itemId))
				return false
			end
		end
	end

	Logger:Info("InventoryValidator", "Loadout validation PASSED ✓ (" .. tostring(next(loadout) ~= nil and "equipped" or "empty") .. ")")
	return true
end

-- ============================================================================
-- VALIDATE ITEM DATA
-- ============================================================================

function SecurityManager:ValidateItemData(itemId, itemData)
	if not itemId or type(itemId) ~= "string" then
		Logger:Warn("InventoryValidator", "Invalid itemId: " .. tostring(itemId))
		return false
	end

	if not itemData or type(itemData) ~= "table" then
		Logger:Error("InventoryValidator", "Invalid itemData for " .. itemId)
		return false
	end

	-- Check for required item properties
	if not itemData.id or not itemData.name then
		Logger:Warn("InventoryValidator", "Item " .. itemId .. " missing id/name")
		return false
	end

	Logger:Info("InventoryValidator", "Item data validated: " .. itemId)
	return true
end

-- ============================================================================
-- DEBUG: Print Inventory Structure
-- ============================================================================

function SecurityManager:DebugPrintInventory(inventory, playerName)
	if not inventory then
		Logger:Warn("InventoryValidator", "Cannot debug nil inventory for " .. tostring(playerName))
		return
	end

	local ownedCount = 0
	local equippedCount = 0

	if inventory.owned then
		for _ in pairs(inventory.owned) do
			ownedCount = ownedCount + 1
		end
	end

	if inventory.equipped then
		for _ in pairs(inventory.equipped) do
			equippedCount = equippedCount + 1
		end
	end

	Logger:Info("InventoryValidator", "[DEBUG] " .. tostring(playerName) .. " inventory: " .. ownedCount .. " owned, " .. equippedCount .. " equipped")
end


return SecurityManager
