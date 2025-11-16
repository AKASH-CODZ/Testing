--[[
================================================================================
  SearchBarController.lua - REFACTORED AND MODERNIZED
================================================================================
  PURPOSE:
  - Manages the search bar functionality, including filtering and debouncing.
  - Provides a better search algorithm.
================================================================================
]]

local SearchBarController = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local SEARCH_CONFIG = {
	debounceTime = 0.2,
}

-- ============================================================================
-- INITIALIZE
-- ============================================================================

function SearchBarController:initialize(searchInputGui, allItemsData)
	if not searchInputGui or not allItemsData then
		warn("SearchBarController: Invalid parameters provided")
		return nil
	end

	local state = {
		searchInput = searchInputGui,
		allItems = allItemsData or {},
		debounceThread = nil,
		onSearchResult = nil
	}

	searchInputGui.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			self:performSearch(state)
		end
	end)

	searchInputGui:GetPropertyChangedSignal("Text"):Connect(function()
		self:debounceSearch(state)
	end)

	return state
end

-- ============================================================================
-- SEARCH ALGORITHM
-- ============================================================================

function SearchBarController:debounceSearch(state)
	if state.debounceThread then
		task.cancel(state.debounceThread)
	end

	state.debounceThread = task.delay(SEARCH_CONFIG.debounceTime, function()
		self:performSearch(state)
	end)
end

function SearchBarController:performSearch(state)
	local query = state.searchInput.Text:lower()

	if query == "" then
		if state.onSearchResult then
			state.onSearchResult(state.allItems)
		end
		return
	end

	local filtered = {}
	for _, item in ipairs(state.allItems) do
		if item.name:lower():find(query, 1, true) then
			table.insert(filtered, item)
		end
	end

	if state.onSearchResult then
		state.onSearchResult(filtered)
	end
end

return SearchBarController
