local ItemContainerManager = {}
ItemContainerManager.__index = ItemContainerManager

local CONTAINER_CONFIG = {
	animationSpeed = 0.5,
	itemsPerRow = 4
}

function ItemContainerManager:initialize(scrollingContainer)
	local state = {
		scrollingContainer = scrollingContainer,
		allItems = {},
		displayedItems = {},
		totalRows = 0
	}
	
	local grid = Instance.new("UIGridLayout")
	-- CellSize, CellPadding, etc.
	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollingContainer.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y)
	end)
	grid.Parent = scrollingContainer
	
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 22.6)
	padding.PaddingRight = UDim.new(0, 22.6)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	grid.CellPadding = UDim2.new(0, 22.6, 0, 22.6)

	padding.Parent = scrollingContainer
	
	-- Fix: Insert UIGridLayout if not present
	local existingGrid = scrollingContainer:FindFirstChildOfClass("UIGridLayout")
	if not existingGrid then
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0, 100, 0, 100) -- Match your box size!
		grid.CellPadding = UDim2.new(0, 10, 0, 10) -- Adjust as needed
		grid.FillDirection = Enum.FillDirection.Horizontal
		grid.FillDirectionMaxCells = 3 -- 3 per row
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
		grid.VerticalAlignment = Enum.VerticalAlignment.Top
		grid.Parent = scrollingContainer
		-- Automatically size canvas for scrolling
		grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scrollingContainer.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y)
		end)
	end
	return state
end

function ItemContainerManager:renderItems(state, listOverride)
	local list = listOverride or state.allItems
	-- Clear old
	for _, child in ipairs(state.scrollingContainer:GetChildren()) do
		if child.Name == "ItemBox" then child:Destroy() end
	end
	state.displayedItems = {}
	for index, item in ipairs(list) do
		local itemBox = self:createItemBox(item, index, list)
		itemBox.Parent = state.scrollingContainer
		table.insert(state.displayedItems, itemBox)
	end
	state.totalRows = math.ceil(#list / 3)
end


function ItemContainerManager:loadItems(state, items)
	state.allItems = items
	self:renderItems(state)
end

function ItemContainerManager:addItem(state, item)
	table.insert(state.allItems, item)
	self:renderItems(state)
end

function ItemContainerManager:createItemBox(item, index, totalItems)
	local frame = Instance.new("Frame")
	frame.Name = "ItemBox"
	frame.Size = UDim2.new(0, 100, 0, 100)
	frame.BackgroundColor3 = Color3.fromRGB(30, 40, 50) -- match your UI
	frame.BorderSizePixel = 2
	frame.BorderColor3 = Color3.fromRGB(20, 110, 180)
	frame.BackgroundTransparency = 0

	-- Add Item Image/Icon
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0.6, 0, 0.6, 0)
	icon.Position = UDim2.new(0.2, 0, 0.1, 0)
	icon.BackgroundTransparency = 1
	icon.Image = item.icon or "" -- If you have asset IDs, put here
	icon.Parent = frame

	-- Add Item Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = UDim2.new(1, 0, 0.2, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.8, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = item.name or "Item"
	nameLabel.Parent = frame

	return frame
end


return ItemContainerManager

