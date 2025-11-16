--[[
================================================================================
  InventoryDataProvider.lua - COMPLETE FIXED VERSION
================================================================================
  Location: ReplicatedStorage/Modules/Inventory_Ui/InventoryDataProvider.lua
  Type: ModuleScript (Client-side)
  
  PURPOSE:
  - Manages inventory data on client side
  - Bridges UI with server inventory system
  - Handles equipment updates
  - Provides fallback for match place (no remotes)
  
  KEY FUNCTIONS:
  1. Initialize(callbacks) - Start sync with server
  2. GetInventory() - Get all inventory data
  3. IsItemEquipped(itemId) - Check equipment status
  4. EquipItem(itemId) - Request equipment change
  5. UnequipItem(itemId) - Request unequipment
  6. WaitUntilLoaded(timeout) - Wait for data ready
  
  FIXES APPLIED:
  ✓ FIX #1: Added IsItemEquipped() function (was missing)
  ✓ FIX #2: Added EquipItem() and UnequipItem() functions
  ✓ FIX #3: Proper error handling and status checking
  ✓ FIX #4: Safe fallback for match place
  ✓ FIX #5: Organized into clear sections
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- ============================================================================
-- MODULE DEFINITION & STATE
-- ============================================================================

local InventoryDataProvider = {}

local cachedInventory = {
	owned = {},
	equipped = {},
	allItems = {}
}

local isLoaded = false

-- Remote events (may be nil on match place)
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")

-- Callbacks for UI updates
local onInventoryUpdated = nil
local onEquipmentChanged = nil
local onErrorOccurred = nil

-- ============================================================================
-- SECTION 1: INITIALIZATION
-- ============================================================================

--[[
  Initialize(onUpdateCallback, onEquipCallback, onErrorCallback)
  Start the inventory system
  
  @param onUpdateCallback: Called when inventory data received
  @param onEquipCallback: Called when equipment changes
  @param onErrorCallback: Called on errors
]]

function InventoryDataProvider:Initialize(onUpdateCallback, onEquipCallback, onErrorCallback)
	print("[InventoryDataProvider] Initializing...")

	onInventoryUpdated = onUpdateCallback
	onEquipmentChanged = onEquipCallback
	onErrorOccurred = onErrorCallback

	-- Check if Remotes exist (main place) or use fallback (match place)
	if Remotes then
		print("[InventoryDataProvider] Remotes found, connecting to server...")
		self:SetupServerListener(onUpdateCallback, onEquipCallback, onErrorCallback)
		task.wait(0.5)
		self:RequestInventoryFromServer()
	else
		print("[InventoryDataProvider] No Remotes found, using fallback inventory")
		self:UseFallbackInventory(onUpdateCallback)
	end
end

-- ============================================================================
-- SECTION 2: SERVER COMMUNICATION
-- ============================================================================

--[[
  SetupServerListener(callbacks)
  Listen for inventory updates from server
]]

function InventoryDataProvider:SetupServerListener(onUpdateCallback, onEquipCallback, onErrorCallback)
	if not Remotes then return end

	local InventoryUpdated = Remotes:WaitForChild("InventoryUpdated", 5)
	if not InventoryUpdated then
		print("[InventoryDataProvider] WARNING: InventoryUpdated remote not found")
		return
	end

	InventoryUpdated.OnClientEvent:Connect(function(data)
		if not data then return end

		-- Handle status messages
		if data.status == "synced" then
			print("[InventoryDataProvider] Server sync confirmed")
			return
		end

		if data.status == "error" then
			print("[InventoryDataProvider] Server error: " .. (data.message or "Unknown"))
			if onErrorCallback then
				onErrorCallback(data.message)
			end
			return
		end

		if data.status == "success" then
			-- Handle equipment change response
			if data.action == "equipped" and onEquipCallback then
				print("[InventoryDataProvider] Equipment update: " .. data.itemId .. " equipped")
				cachedInventory.equipped = data.equipped or {}
				onEquipCallback(data.itemId, true)

			elseif data.action == "unequipped" and onEquipCallback then
				print("[InventoryDataProvider] Equipment update: " .. data.itemId .. " unequipped")
				cachedInventory.equipped = data.equipped or {}
				onEquipCallback(data.itemId, false)
			end
			return
		end

		-- Full inventory update from server
		if data.owned and data.allItems then
			print("[InventoryDataProvider] Received inventory from server")

			cachedInventory.owned = data.owned
			cachedInventory.equipped = data.equipped or {}
			cachedInventory.allItems = data.allItems
			isLoaded = true

			if onUpdateCallback then
				onUpdateCallback(cachedInventory)
			end
		end
	end)
end

--[[
  RequestInventoryFromServer()
  Send request to server for current inventory
]]

function InventoryDataProvider:RequestInventoryFromServer()
	if not Remotes then return end

	print("[InventoryDataProvider] Requesting from server...")

	local GetPlayerInventory = Remotes:FindFirstChild("GetPlayerInventory")
	if GetPlayerInventory then
		GetPlayerInventory:FireServer()
	else
		print("[InventoryDataProvider] WARNING: GetPlayerInventory remote not found")
	end
end

-- ============================================================================
-- SECTION 3: FALLBACK INVENTORY (Match Place)
-- ============================================================================

--[[
  UseFallbackInventory(onUpdateCallback)
  Use default inventory when on match place (no remotes)
]]

function InventoryDataProvider:UseFallbackInventory(onUpdateCallback)
	print("[InventoryDataProvider] Using fallback inventory")

	cachedInventory = {
		owned = {
			["BasicSword"] = {
				data = {id = "BasicSword", name = "Basic Sword", type = "weapon", damage = 10},
				count = 1,
				equipped = true
			},
			["IronArmor"] = {
				data = {id = "IronArmor", name = "Iron Armor", type = "armor", defense = 5},
				count = 1,
				equipped = true
			},
			["HealthPotion"] = {
				data = {id = "HealthPotion", name = "Health Potion", type = "consumable", heal = 25},
				count = 5,
				equipped = false
			}
		},
		equipped = {
			["BasicSword"] = true,
			["IronArmor"] = true
		},
		allItems = {
			{id = "BasicSword", name = "Basic Sword", type = "weapon", damage = 10},
			{id = "IronArmor", name = "Iron Armor", type = "armor", defense = 5},
			{id = "FireStaff", name = "Fire Staff", type = "weapon", damage = 15},
			{id = "HealthPotion", name = "Health Potion", type = "consumable", heal = 25},
			{id = "ManaPotion", name = "Mana Potion", type = "consumable", restore = 50},
			{id = "SteelShield", name = "Steel Shield", type = "armor", defense = 8}
		}
	}

	isLoaded = true

	if onUpdateCallback then
		onUpdateCallback(cachedInventory)
	end
end

-- ============================================================================
-- SECTION 4: GETTERS - Retrieve Data
-- ============================================================================

--[[
  GetInventory()
  Returns complete cached inventory
  @returns inventory table or nil if not loaded
]]

function InventoryDataProvider:GetInventory()
	if not isLoaded then
		print("[InventoryDataProvider] Inventory not loaded yet")
		return nil
	end
	return cachedInventory
end

--[[
  IsLoaded()
  Check if inventory data is ready
  @returns boolean
]]

function InventoryDataProvider:IsLoaded()
	return isLoaded
end

--[[
  IsItemEquipped(itemId)
  Check if specific item is currently equipped
  ✓ FIX #1: This function was missing from new version
  
  @param itemId: Item ID to check
  @returns boolean (true if equipped)
]]

function InventoryDataProvider:IsItemEquipped(itemId)
	if not cachedInventory.equipped then
		return false
	end
	return cachedInventory.equipped[itemId] or false
end

--[[
  GetOwnedItems()
  Get all items player owns
  @returns array of owned items
]]

function InventoryDataProvider:GetOwnedItems()
	if not isLoaded then
		return {}
	end

	local ownedList = {}
	for itemId, itemData in pairs(cachedInventory.owned) do
		table.insert(ownedList, itemData)
	end
	return ownedList
end

--[[
  GetAllItems()
  Get all available items (for catalog/search)
  @returns array of all items
]]

function InventoryDataProvider:GetAllItems()
	if not isLoaded then
		return {}
	end
	return cachedInventory.allItems or {}
end

--[[
  GetEquippedItems()
  Get list of currently equipped items
  @returns table of equipped item IDs
]]

function InventoryDataProvider:GetEquippedItems()
	if not isLoaded then
		return {}
	end
	return cachedInventory.equipped or {}
end

--[[
  GetItemData(itemId)
  Get specific item's data
  @param itemId: Item ID to lookup
  @returns item data table or nil
]]

function InventoryDataProvider:GetItemData(itemId)
	if not isLoaded then
		return nil
	end

	if cachedInventory.owned[itemId] then
		return cachedInventory.owned[itemId].data
	end

	for _, item in ipairs(cachedInventory.allItems or {}) do
		if item.id == itemId then
			return item
		end
	end

	return nil
end

-- ============================================================================
-- SECTION 5: ACTIONS - Modify Inventory
-- ============================================================================

--[[
  EquipItem(itemId)
  Request server to equip item
  ✓ FIX #2: This function was missing from new version
  
  @param itemId: Item ID to equip
  @returns boolean (success)
]]

function InventoryDataProvider:EquipItem(itemId)
	if not Remotes then
		print("[InventoryDataProvider] Cannot equip on match place")
		return false
	end

	if not isLoaded then
		print("[InventoryDataProvider] Inventory not loaded, cannot equip")
		if onErrorOccurred then
			onErrorOccurred("Inventory not ready")
		end
		return false
	end

	if not cachedInventory.owned[itemId] then
		print("[InventoryDataProvider] Player doesn't own this item: " .. itemId)
		if onErrorOccurred then
			onErrorOccurred("You don't own this item")
		end
		return false
	end

	print("[InventoryDataProvider] Requesting to equip: " .. itemId)

	local UpdateEquippedItem = Remotes:FindFirstChild("UpdateEquippedItem")
	if UpdateEquippedItem then
		UpdateEquippedItem:FireServer(itemId, true)
		return true
	else
		print("[InventoryDataProvider] WARNING: UpdateEquippedItem remote not found")
		return false
	end
end

--[[
  UnequipItem(itemId)
  Request server to unequip item
  ✓ FIX #2: This function was missing from new version
  
  @param itemId: Item ID to unequip
  @returns boolean (success)
]]

function InventoryDataProvider:UnequipItem(itemId)
	if not Remotes then
		print("[InventoryDataProvider] Cannot unequip on match place")
		return false
	end

	if not isLoaded then
		print("[InventoryDataProvider] Inventory not loaded, cannot unequip")
		if onErrorOccurred then
			onErrorOccurred("Inventory not ready")
		end
		return false
	end

	print("[InventoryDataProvider] Requesting to unequip: " .. itemId)

	local UpdateEquippedItem = Remotes:FindFirstChild("UpdateEquippedItem")
	if UpdateEquippedItem then
		UpdateEquippedItem:FireServer(itemId, false)
		return true
	else
		print("[InventoryDataProvider] WARNING: UpdateEquippedItem remote not found")
		return false
	end
end

--[[
  SyncBeforeTeleport()
  Sync inventory state before teleporting
  @returns boolean (success)
]]

function InventoryDataProvider:SyncBeforeTeleport()
	if not Remotes then
		print("[InventoryDataProvider] Cannot sync on match place")
		return false
	end

	if not isLoaded then
		print("[InventoryDataProvider] Inventory not loaded, cannot sync")
		return false
	end

	print("[InventoryDataProvider] Syncing before teleport...")

	local SyncInventoryBeforeTeleport = Remotes:FindFirstChild("SyncInventoryBeforeTeleport")
	if SyncInventoryBeforeTeleport then
		SyncInventoryBeforeTeleport:FireServer()
		return true
	else
		print("[InventoryDataProvider] WARNING: SyncInventoryBeforeTeleport remote not found")
		return false
	end
end

-- ============================================================================
-- SECTION 6: UTILITIES - Wait and Search
-- ============================================================================

--[[
  WaitUntilLoaded(timeout)
  Wait for inventory to load or use fallback
  @param timeout: Max seconds to wait (default 30)
  @returns boolean (loaded)
]]

function InventoryDataProvider:WaitUntilLoaded(timeout)
	timeout = timeout or 30
	local startTime = tick()

	while not isLoaded do
		if tick() - startTime > timeout then
			print("[InventoryDataProvider] Timeout waiting for inventory, using fallback")
			self:UseFallbackInventory(onInventoryUpdated)
			break
		end
		task.wait(0.1)
	end

	return isLoaded
end

--[[
  SearchItems(query, searchType)
  Search owned items
  @param query: Search term
  @param searchType: "name", "category", "type", or "rarity"
  @returns array of matching items
]]

function InventoryDataProvider:SearchItems(query, searchType)
	searchType = searchType or "name"

	if not isLoaded then
		return {}
	end

	local results = {}

	for itemId, itemData in pairs(cachedInventory.owned) do
		local data = itemData.data
		local matches = false

		if searchType == "name" then
			matches = string.find((data.name or ""):lower(), query:lower(), 1, true) ~= nil
		elseif searchType == "type" then
			matches = (data.type or ""):lower() == query:lower()
		elseif searchType == "rarity" then
			matches = (data.rarity or ""):lower() == query:lower()
		end

		if matches then
			table.insert(results, itemData)
		end
	end

	return results
end

--[[
  GetInventoryStats()
  Get summary statistics
  @returns table with counts and totals
]]

function InventoryDataProvider:GetInventoryStats()
	if not isLoaded then
		return {totalItems = 0, totalWeight = 0, equipped = 0}
	end

	local totalItems = 0
	local totalWeight = 0
	local equipped = 0

	for itemId, itemData in pairs(cachedInventory.owned) do
		totalItems = totalItems + 1
		if itemData.data and itemData.data.weight then
			totalWeight = totalWeight + (itemData.data.weight * itemData.count)
		end
		if cachedInventory.equipped[itemId] then
			equipped = equipped + 1
		end
	end

	return {
		totalItems = totalItems,
		totalWeight = totalWeight,
		equipped = equipped
	}
end

-- ============================================================================
-- EXPORT MODULE
-- ============================================================================

return InventoryDataProvider
