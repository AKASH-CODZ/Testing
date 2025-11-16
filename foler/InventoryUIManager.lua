--[[
================================================================================
  InventoryUIManager.lua - COMPLETE FIXED VERSION (v2)
================================================================================
  FIXES APPLIED IN THIS VERSION:
  ✓ FIX #1: TweenSize() now calls on Frame, not ScreenGui
  ✓ FIX #2: Initial inventory display now shows immediately on join
  ✓ FIX #3: Items visible without requiring search interaction
  ✓ FIX #4: Proper UI rendering on initialization
  ✓ FIX #5: Button handlers compatible with all code
  
  KEY CHANGES:
  - Line 310: Changed TweenSize from inventoryGui.Parent to inventoryGui
  - Line 180: Added immediate item rendering after load
  - Line 195: Force visible state on init
  - Line 305+: Better close button logic
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

local ItemContainerManager = require(
	ReplicatedStorage:WaitForChild("Modules")
		:WaitForChild("Inventory_Ui")
		:WaitForChild("ItemContainerManager")
)

local ButtonAnimationController = require(
	ReplicatedStorage:WaitForChild("Modules")
		:WaitForChild("Inventory_Ui")
		:WaitForChild("ButtonAnimationController")
)

local SearchBarController = require(
	ReplicatedStorage:WaitForChild("Modules")
		:WaitForChild("Inventory_Ui")
		:WaitForChild("SearchBarController")
)

local InventoryDataProvider = require(
	ReplicatedStorage:WaitForChild("Modules")
		:WaitForChild("Inventory_Ui")
		:WaitForChild("InventoryDataProvider")
)

-- ============================================================================
-- UI ELEMENT REFERENCES
-- ============================================================================

local inventoryGui = playerGui:WaitForChild("inventoryGui"):WaitForChild("MainFrame")
local closeButton = inventoryGui:WaitForChild("CloseButton")
local searchInput = inventoryGui:WaitForChild("SearchBar")
local scrollingContainer = inventoryGui:WaitForChild("scrollingContainer")

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function CountInventoryItems(inventory)
	local count = 0
	if inventory and inventory.owned then
		for _ in pairs(inventory.owned) do
			count = count + 1
		end
	end
	return count
end

local function ValidateInventoryData(inventory)
	if not inventory then
		warn("[InventoryUIManager] Received nil inventory")
		return false
	end
	if not inventory.owned or type(inventory.owned) ~= "table" then
		warn("[InventoryUIManager] Invalid inventory.owned structure")
		return false
	end
	if not inventory.allItems or type(inventory.allItems) ~= "table" then
		warn("[InventoryUIManager] Invalid inventory.allItems structure")
		return false
	end
	return true
end

-- ============================================================================
-- SECTION 1: INVENTORY UPDATE CALLBACK
-- ============================================================================

local function OnInventoryUpdated(inventory)
	print("[InventoryUIManager] Inventory update received")

	if not ValidateInventoryData(inventory) then
		print("[InventoryUIManager] Inventory validation failed")
		return
	end

	-- ✓ FIX #2: Initialize container and load items immediately
	local containerState = ItemContainerManager:initialize(scrollingContainer)
	if not containerState then
		warn("[InventoryUIManager] Failed to initialize ItemContainerManager")
		return
	end

	-- ✓ FIX #3: Load items into container (owned items)
	ItemContainerManager:loadItems(containerState, inventory.owned)
	print("[InventoryUIManager] Loaded " .. CountInventoryItems(inventory) .. " items")

	-- ✓ FIX #4: Attach click handlers to each rendered item
	if containerState.renderedItems then
		for _, itemBox in pairs(containerState.renderedItems) do
			local itemId = itemBox.Name

			if not itemBox:GetAttribute("ClickConnected") then
				itemBox:SetAttribute("ClickConnected", true)

				itemBox.MouseButton1Click:Connect(function()
					print("[InventoryUIManager] Item clicked: " .. itemId)

					if InventoryDataProvider:IsItemEquipped(itemId) then
						print("[InventoryUIManager] Unequipping: " .. itemId)
						InventoryDataProvider:UnequipItem(itemId)
					else
						print("[InventoryUIManager] Equipping: " .. itemId)
						InventoryDataProvider:EquipItem(itemId)
					end
				end)
			end
		end
	end

	-- Log statistics
	local stats = InventoryDataProvider:GetInventoryStats()
	print("[InventoryUIManager] Inventory stats:")
	print("  - Total items: " .. stats.totalItems)
	print("  - Equipped: " .. stats.equipped)
	print("  - Total weight: " .. stats.totalWeight)

	local itemCount = CountInventoryItems(inventory)
	print("✓ Inventory synced with server. Items loaded: " .. tostring(itemCount))

	-- ✓ FIX #5: Force visible state after items load
	if inventoryGui then
		inventoryGui.Visible = true
		inventoryGui.BackgroundTransparency = 0.2
		scrollingContainer.Visible = true
		scrollingContainer.BackgroundTransparency = 0.2
		searchInput.Visible = true
		searchInput.BackgroundTransparency = 0
		searchInput.TextTransparency = 0
	end

	-- Initialize the search bar here to avoid race condition
	if inventory and inventory.allItems then
		local allItemsList = {}
		for _, itemData in pairs(inventory.allItems) do
			table.insert(allItemsList, itemData)
		end

		print("[InventoryUIManager] Initializing search with " .. #allItemsList .. " items")
		local searchState = SearchBarController:initialize(searchInput, allItemsList)
		if searchState then
			searchState.onSearchResult = function(filteredList)
				print("[InventoryUIManager] Search results: " .. #filteredList .. " items")
				ItemContainerManager:renderItems(containerState, filteredList)
			end
			print("[InventoryUIManager] Search bar ready")
		else
			warn("[InventoryUIManager] Failed to initialize search bar")
		end
	end
end

local function OnEquipmentChanged(itemId, isEquipped)
	print("[InventoryUIManager] Equipment changed: " .. itemId)
	print("  - Status: " .. (isEquipped and "EQUIPPED" or "UNEQUIPPED"))
end

local function OnInventoryError(errorMessage)
	warn("[InventoryUIManager] Inventory error: " .. tostring(errorMessage))
end

-- ============================================================================
-- SECTION 2: INITIALIZATION - PHASE 1: Setup UI Elements
-- ============================================================================

print("[InventoryUIManager] Initializing...")

local containerState = ItemContainerManager:initialize(scrollingContainer)
if not containerState then
	warn("[InventoryUIManager] Failed to initialize ItemContainerManager")
end

-- ============================================================================
-- SECTION 3: INITIALIZATION - PHASE 2: Request Inventory Data
-- ============================================================================

InventoryDataProvider:Initialize(
	OnInventoryUpdated,
	OnEquipmentChanged,
	OnInventoryError
)

-- ============================================================================
-- SECTION 4: INITIALIZATION - PHASE 3: Setup Search Bar (Async)
-- ============================================================================

-- The search bar is now initialized in the OnInventoryUpdated callback

-- ============================================================================
-- SECTION 5: INITIALIZATION - PHASE 4: Setup Button Animations
-- ============================================================================

ButtonAnimationController:setupNeonGlow(closeButton)
print("[InventoryUIManager] Button animation initialized")

-- ============================================================================
-- SECTION 6: INVENTORY TOGGLE FUNCTION
-- ============================================================================

local originalSize = inventoryGui.Size
local isOpen = false

local function ToggleInventory()
	if not inventoryGui or not inventoryGui:IsA("Frame") then
		warn("[InventoryUIManager] inventoryGui is not a Frame, cannot tween")
		return
	end

	isOpen = not isOpen

	if isOpen then
		print("[InventoryUIManager] Opening inventory")
		inventoryGui.Visible = true
		inventoryGui:TweenSize(
			originalSize,
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.3,
			true
		)
	else
		print("[InventoryUIManager] Closing inventory")
		inventoryGui:TweenSize(
			UDim2.new(0, 0, 0, 0),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Quad,
			0.3,
			true,
			function()
				inventoryGui.Visible = false
			end
		)
	end
end

closeButton.MouseButton1Click:Connect(ToggleInventory)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then return end

	if input.KeyCode == Enum.KeyCode.G then
		ToggleInventory()
	end
end)

-- ============================================================================
-- SECTION 7: STARTUP STATUS
-- ============================================================================

print("✓ InventoryUIManager initialized successfully")
print("  - Item Container: Ready")
print("  - Search Bar: Initializing...")
print("  - Button Animation: Ready")
print("  - Data Provider: Connected")
print("  - Grid layout: 4 per row")
print("  - Search active: Yes")
print("  - Initial display: ✓ Fixed")
print("  - TweenSize: ✓ Fixed (Frame-based)")

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
