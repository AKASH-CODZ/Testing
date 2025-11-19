--[[
================================================================================
  ItemContainerManager.lua
================================================================================
  - **Purpose:** Manages the creation and rendering of inventory item UI elements.
  - **Location:** ReplicatedStorage/Modules
  - **Type:** ModuleScript
================================================================================
]]

local ItemContainerManager = {}
ItemContainerManager.__index = ItemContainerManager

-- ============================================================================
-- INITIALIZE THE CONTAINER AND LAYOUT
-- ============================================================================

function ItemContainerManager:initialize(scrollingContainer)
	local state = {
		scrollingContainer = scrollingContainer,
		renderedItems = {} -- Changed from allItems/displayedItems for clarity
	}

	-- Find or create the UIGridLayout
	local gridLayout = scrollingContainer:FindFirstChildOfClass("UIGridLayout")
	if not gridLayout then
		gridLayout = Instance.new("UIGridLayout")
		gridLayout.Name = "InventoryGridLayout"
		gridLayout.CellSize = UDim2.new(0, 100, 0, 100)
		gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
		gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		gridLayout.Parent = scrollingContainer
	end
	state.gridLayout = gridLayout

	-- Automatically adjust canvas size for scrolling content
	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollingContainer.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y)
	end)

	return state
end

-- ============================================================================
-- CREATE A SINGLE ITEM BOX (FRAME)
-- ============================================================================

function ItemContainerManager:createItemBox(itemData)
	-- The 'itemData' received here is the table with { data, count, equipped }
	local item = itemData.data -- The actual item properties are inside 'data'

	local frame = Instance.new("TextButton")
	frame.Text = ""
	frame.Name = item.id or "ItemBox" -- Use item ID for the name for easier debugging
	frame.Size = UDim2.new(0, 100, 0, 100)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	frame.BorderSizePixel = 1
	frame.BorderColor3 = Color3.fromRGB(80, 80, 90)
	frame.BackgroundTransparency = 0 -- Fully visible
	frame.Visible = true -- Explicitly visible

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, -10, 1, -30)
	icon.Position = UDim2.new(0, 5, 0, 5)
	icon.BackgroundTransparency = 1
	icon.Image = item.icon or "rbxassetid://12345" -- Default icon
	icon.Active = false
	icon.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.Position = UDim2.new(0, 0, 1, -25)
	nameLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	nameLabel.BackgroundTransparency = 0.2
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.TextSize = 14
	nameLabel.Text = item.name or "Unknown Item"
	nameLabel.Active = false
	nameLabel.Parent = frame

	return frame
end

-- ============================================================================
-- LOAD AND RENDER ITEMS
-- ============================================================================

function ItemContainerManager:loadItems(state, ownedItems)
	-- Clear any existing items first
	for _, itemBox in pairs(state.renderedItems) do
		itemBox:Destroy()
	end
	state.renderedItems = {}

	-- Render the new items
	for itemId, itemData in pairs(ownedItems) do
		local itemBox = self:createItemBox(itemData)
		itemBox.Parent = state.scrollingContainer
		state.renderedItems[itemId] = itemBox
	end
end

-- This function can be used for search results
function ItemContainerManager:renderItems(state, filteredItems)
    -- This function now just controls visibility, not creating/destroying
    for itemId, itemBox in pairs(state.renderedItems) do
        local isVisible = false
        for _, filteredItem in ipairs(filteredItems) do
            if filteredItem.id == itemId then
                isVisible = true
                break
            end
        end
        itemBox.Visible = isVisible
    end
end


return ItemContainerManager
