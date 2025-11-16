--[[
================================================================================
  InventoryValidator.lua - ENHANCED WITH LOGGING & FUTURE-PROOFING
================================================================================
  Location: ReplicatedStorage/Modules/InventoryValidator
  
  PURPOSE:
  - Validate inventory structure and loadouts
  - Enhanced logging with Logger integration
  - Future-proof with full function exports
  - Supports both ValidateInventory and ValidateLoadout patterns
  
  ALL UPDATES:
  ✓ ValidateLoadout function added (preferred pattern)
  ✓ ValidateInventory function (compatibility)
  ✓ Enhanced Logger output at all steps
  ✓ All functions exported in return table
  ✓ Type checking & error handling
  ✓ Future-proof architecture
================================================================================
]]

local Logger = require(script.Parent:WaitForChild("Logger"))
local InventoryValidator = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local REQUIRED_INVENTORY_KEYS = {"owned", "equipped", "allItems"}
local MAX_ITEMS_PER_PLAYER = 999
local VALID_ITEM_TYPES = {["table"] = true, ["string"] = true}

-- ============================================================================
-- VALIDATE INVENTORY STRUCTURE
-- ============================================================================
function InventoryValidator:ItemExists(inventory, itemId)
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

function InventoryValidator:GetAllItems(inventory)
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


function InventoryValidator:ValidateInventory(inventory)
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

function InventoryValidator:ValidateLoadout(playerInventory, loadout)
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

function InventoryValidator:ValidateItemData(itemId, itemData)
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
-- VALIDATE INVENTORY SCHEMA (For strict mode)
-- ============================================================================

function InventoryValidator:ValidateSchema(inventory, schema)
	if not schema then
		Logger:Info("InventoryValidator", "No schema provided, using basic validation")
		return self:ValidateInventory(inventory)
	end

	for key, expectedType in pairs(schema) do
		if not inventory[key] then
			Logger:Error("InventoryValidator", "Schema violation: Missing key " .. key)
			return false
		end

		if type(inventory[key]) ~= expectedType then
			Logger:Error("InventoryValidator", "Schema violation: " .. key .. " is " .. type(inventory[key]) .. ", expected " .. expectedType)
			return false
		end
	end

	Logger:Info("InventoryValidator", "Schema validation PASSED ✓")
	return true
end

-- ============================================================================
-- DEBUG: Print Inventory Structure
-- ============================================================================

function InventoryValidator:DebugPrintInventory(inventory, playerName)
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

-- ============================================================================
-- STARTUP & EXPORT
-- ============================================================================

print("[InventoryValidator] Module loaded successfully")
print("[InventoryValidator] Available functions:")
print("  - ValidateInventory(inventory)")
print("  - ValidateLoadout(playerInventory, loadout)")
print("  - ValidateItemData(itemId, itemData)")
print("  - ValidateSchema(inventory, schema)")
print("  - DebugPrintInventory(inventory, playerName)")

-- ============================================================================
-- RETURN - CRITICAL: All functions must be exported
-- ============================================================================

return {
	ValidateInventory = InventoryValidator.ValidateInventory,
	ValidateLoadout = InventoryValidator.ValidateLoadout,
	ValidateItemData = InventoryValidator.ValidateItemData,
	ValidateSchema = InventoryValidator.ValidateSchema,
	DebugPrintInventory = InventoryValidator.DebugPrintInventory,
	ItemExists        = InventoryValidator.ItemExists,
	GetAllItems       = InventoryValidator.GetAllItems,
}
