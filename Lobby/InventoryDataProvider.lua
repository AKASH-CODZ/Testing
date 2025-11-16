--[[
================================================================================
  InventoryDataProvider.lua - REFACTORED AND MODERNIZED
================================================================================
  PURPOSE:
  - Manages inventory data on the client side.
  - Bridges the UI with the server's inventory system.
  - Handles equipment updates.
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
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function InventoryDataProvider:Initialize(callbacks)
	if not Remotes then
		warn("[InventoryDataProvider] Remotes folder not found!")
		return
	end

	local InventoryUpdated = Remotes:WaitForChild("InventoryUpdated")

	InventoryUpdated.OnClientEvent:Connect(function(data)
		if data.status == "synced" and callbacks.onSync then
			callbacks.onSync()
		elseif data.status == "error" and callbacks.onError then
			callbacks.onError(data.message)
		elseif data.action == "equipped" and callbacks.onEquip then
			cachedInventory.equipped = data.equipped or {}
			callbacks.onEquip(data.itemId, true)
		elseif data.action == "unequipped" and callbacks.onEquip then
			cachedInventory.equipped = data.equipped or {}
			callbacks.onEquip(data.itemId, false)
		elseif data.owned and data.allItems then
			cachedInventory.owned = data.owned
			cachedInventory.equipped = data.equipped or {}
			cachedInventory.allItems = data.allItems
			isLoaded = true
			if callbacks.onUpdate then
				callbacks.onUpdate(cachedInventory)
			end
		end
	end)

	Remotes.GetPlayerInventory:FireServer()
end

-- ============================================================================
-- GETTERS
-- ============================================================================

function InventoryDataProvider:GetInventory()
	return isLoaded and cachedInventory or nil
end

function InventoryDataProvider:IsItemEquipped(itemId)
	return cachedInventory.equipped and cachedInventory.equipped[itemId] or false
end

-- =
-- ============================================================================
-- ACTIONS
-- ============================================================================

function InventoryDataProvider:EquipItem(itemId)
	if not Remotes or not isLoaded then return false end
	if not cachedInventory.owned[itemId] then return false end
	Remotes.UpdateEquippedItem:FireServer(itemId, true)
	return true
end

function InventoryDataProvider:UnequipItem(itemId)
	if not Remotes or not isLoaded then return false end
	Remotes.UpdateEquippedItem:FireServer(itemId, false)
	return true
end

return InventoryDataProvider
