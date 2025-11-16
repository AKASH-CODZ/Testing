--[[
================================================================================
  InventoryUIManager.lua - REFACTORED AND MODERNIZED
================================================================================
  PURPOSE:
  - Manages the inventory UI, including the search bar, item display,
    and toggle functionality.
  - Handles all user input for the inventory.
================================================================================
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================

local ItemContainerManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Inventory_Ui"):WaitForChild("ItemContainerManager"))
local ButtonAnimationController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Inventory_Ui"):WaitForChild("ButtonAnimationController"))
local SearchBarController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Inventory_Ui"):WaitForChild("SearchBarController"))
local InventoryDataProvider = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Inventory_Ui"):WaitForChild("InventoryDataProvider"))

-- ============================================================================
-- UI ELEMENT REFERENCES
-- ============================================================================

local inventoryGui = playerGui:WaitForChild("inventoryGui"):WaitForChild("MainFrame")
local closeButton = inventoryGui:WaitForChild("CloseButton")
local searchInput = inventoryGui:WaitForChild("SearchBar")
local scrollingContainer = inventoryGui:WaitForChild("scrollingContainer")

-- ============================================================================
-- INVENTORY UPDATE CALLBACK
-- ============================================================================

local function OnInventoryUpdated(inventory)
	local containerState = ItemContainerManager:initialize(scrollingContainer)
	ItemContainerManager:loadItems(containerState, inventory.owned)

	for _, itemBox in pairs(containerState.renderedItems) do
		itemBox.MouseButton1Click:Connect(function()
			local itemId = itemBox.Name
			if InventoryDataProvider:IsItemEquipped(itemId) then
				InventoryDataProvider:UnequipItem(itemId)
			else
				InventoryDataProvider:EquipItem(itemId)
			end
		end)
	end

	local allItemsList = {}
	for _, itemData in pairs(inventory.allItems) do
		table.insert(allItemsList, itemData)
	end

	local searchState = SearchBarController:initialize(searchInput, allItemsList)
	searchState.onSearchResult = function(filteredList)
		ItemContainerManager:renderItems(containerState, filteredList)
	end

	inventoryGui.Visible = false
	inventoryGui.BackgroundTransparency = 0.1
	scrollingContainer.Visible = true
	scrollingContainer.BackgroundTransparency = 1
	searchInput.Visible = true
	searchInput.BackgroundTransparency = 0.5
	searchInput.TextTransparency = 0
	searchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

InventoryDataProvider:Initialize({
	onUpdate = OnInventoryUpdated,
	onEquip = function(itemId, isEquipped)
		print("[InventoryUIManager] " .. itemId .. " " .. (isEquipped and "equipped" or "unequipped"))
	end,
	onError = function(message)
		warn("[InventoryUIManager] Error: " .. message)
	end,
})

ButtonAnimationController:setupNeonGlow(closeButton)

-- ============================================================================
-- INVENTORY TOGGLE FUNCTION
-- ============================================================================

local originalSize = inventoryGui.Size
local isOpen = false

local function ToggleInventory()
	isOpen = not isOpen
	if isOpen then
		inventoryGui.Visible = true
		inventoryGui:TweenSize(originalSize, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
	else
		inventoryGui:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true, function()
			inventoryGui.Visible = false
		end)
	end
end

closeButton.MouseButton1Click:Connect(ToggleInventory)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if input.KeyCode == Enum.KeyCode.G then
		ToggleInventory()
	end
end)
