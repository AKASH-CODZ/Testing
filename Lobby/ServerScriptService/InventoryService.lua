--[[
================================================================================
  InventoryService.lua
================================================================================
  - **Purpose:** Manages the player's inventory on the server.
  - **Location:** ServerScriptService
  - **Type:** Script
================================================================================
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================

local PlayerDataManager = require(ServerScriptService:WaitForChild("PlayerManager"))
local SecurityManager = require(ServerScriptService:WaitForChild("SecurityManager"))
local GameStateManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameStateManager"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Remotes.Name = "Remotes"

local GetPlayerInventory = Remotes:FindFirstChild("GetPlayerInventory") or Instance.new("RemoteEvent", Remotes)
GetPlayerInventory.Name = "GetPlayerInventory"

local UpdateEquippedItem = Remotes:FindFirstChild("UpdateEquippedItem") or Instance.new("RemoteEvent", Remotes)
UpdateEquippedItem.Name = "UpdateEquippedItem"

local InventoryUpdated = Remotes:FindFirstChild("InventoryUpdated") or Instance.new("RemoteEvent", Remotes)
InventoryUpdated.Name = "InventoryUpdated"

local RequestTeleportToMatch = Remotes:FindFirstChild("RequestTeleportToMatch") or Instance.new("RemoteEvent", Remotes)
RequestTeleportToMatch.Name = "RequestTeleportToMatch"

-- ============================================================================
-- GET INVENTORY
-- ============================================================================

GetPlayerInventory.OnServerEvent:Connect(function(player)
	local profile = PlayerDataManager:GetProfile(player)
	if not profile then return end
	local playerData = profile.Data

	local ownedItems = {}
	for itemId, count in pairs(playerData.owned) do
		local itemData = GameConfig.AllItems[itemId]
		if itemData then
			ownedItems[itemId] = {
				data = itemData,
				count = count,
				equipped = playerData.equipped[itemId] or false
			}
		end
	end

	InventoryUpdated:FireClient(player, {
		owned = ownedItems,
		equipped = playerData.equipped,
		allItems = GameConfig.AllItems
	})
end)

-- ============================================================================
-- EQUIP/UNEQUIP ITEM
-- ============================================================================

UpdateEquippedItem.OnServerEvent:Connect(function(player, itemId, shouldEquip)
	local profile = PlayerDataManager:GetProfile(player)
	if not profile then return end
	local playerData = profile.Data

	if GameStateManager:GetPlayerState(player) ~= GameStateManager.States.LOBBY then
		InventoryUpdated:FireClient(player, {status = "error", message = "Cannot equip while not in lobby"})
		return
	end

	if shouldEquip then
		if not playerData.owned[itemId] then
			InventoryUpdated:FireClient(player, {status = "error", message = "You don't own this item"})
			return
		end
		playerData.equipped[itemId] = true
	else
		playerData.equipped[itemId] = nil
	end

	InventoryUpdated:FireClient(player, {
		status = "success",
		action = shouldEquip and "equipped" or "unequipped",
		itemId = itemId,
		equipped = playerData.equipped
	})
end)
