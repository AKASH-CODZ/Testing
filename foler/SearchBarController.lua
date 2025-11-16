local SearchBarController = {}

-- Configuration
local SEARCH_CONFIG = {
	debounceTime = 0.3,
	maxResults = 50,
	highlightColor = Color3.fromRGB(0, 255, 150),
	normalColor = Color3.fromRGB(200, 200, 200),
	fuzzyMatchWeight = 0.8,
	exactMatchWeight = 1.0
}

--- Initialize SearchBarController
-- @param searchInputGui: TextBox for search input
-- @param allItemsData: Array of item data {id, name, category, description}
-- @returns state table with search functionality
function SearchBarController:initialize(searchInputGui, allItemsData)
	if not searchInputGui or not allItemsData then
		warn("SearchBarController: Invalid parameters provided")
		return nil
	end

	local state = {
		searchInput = searchInputGui,
		allItems = allItemsData or {},
		lastQuery = "",
		debounceThread = nil,
		onSearchResult = nil -- Callback to render filtered items
	}

	-- Setup input field connections
	self:setupSearchInput(searchInputGui, state)

	return state
end

--- Setup search input field listeners
function SearchBarController:setupSearchInput(searchInput, state)
	-- Real-time search on text change with debouncing
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		self:debounceSearch(state)
	end)

	-- Search on Enter key
	searchInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			self:performSearch(state)
		end
	end)
end

--- Debounce search to prevent rapid filtering
function SearchBarController:debounceSearch(state)
	if state.debounceThread then
		task.cancel(state.debounceThread)
	end

	state.debounceThread = task.delay(SEARCH_CONFIG.debounceTime, function()
		self:performSearch(state)
	end)
end

--- Main search algorithm: fuzzy + exact match hybrid
function SearchBarController:performSearch(state)
	local query = state.searchInput.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")

	-- Empty query shows all items
	if query == "" then
		if state.onSearchResult then
			state.onSearchResult(state.allItems)
		end
		state.lastQuery = ""
		return
	end

	-- Don't re-search same query
	if query == state.lastQuery then
		return
	end
	state.lastQuery = query

	-- Filter using hybrid algorithm
	local filtered = self:filterItems(state.allItems, query)

	-- Call the render callback
	if state.onSearchResult then
		state.onSearchResult(filtered)
	end
end

--- Hybrid filtering: Exact match first, then fuzzy match
-- @param items: Array of items to filter
-- @param query: Search query string
-- @returns filtered array, ordered by relevance
function SearchBarController:filterItems(items, query)
	local exactMatches = {}
	local fuzzyMatches = {}

	for _, item in ipairs(items) do
		local score = self:calculateMatchScore(item, query)

		if score > 0 then
			if score == SEARCH_CONFIG.exactMatchWeight then
				table.insert(exactMatches, {item = item, score = score})
			else
				table.insert(fuzzyMatches, {item = item, score = score})
			end
		end
	end

	-- Sort fuzzy matches by score (highest first)
	table.sort(fuzzyMatches, function(a, b)
		return a.score > b.score
	end)

	-- Combine: exact matches first, then fuzzy
	local result = {}
	for _, match in ipairs(exactMatches) do
		table.insert(result, match.item)
	end
	for _, match in ipairs(fuzzyMatches) do
		table.insert(result, match.item)
		if #result >= SEARCH_CONFIG.maxResults then
			break
		end
	end

	return result
end

--- Calculate match score for an item against query
-- Perfect algorithm: name match weighted highest
-- @param item: Item to check
-- @param query: Search query
-- @returns score (0 = no match, 1.0 = exact match, 0.5-0.9 = fuzzy match)
function SearchBarController:calculateMatchScore(item, query)
	local itemName = (item.name or ""):lower()
	local itemCategory = (item.category or ""):lower()
	local itemDescription = (item.description or ""):lower()

	-- Exact name match (highest priority)
	if itemName == query then
		return SEARCH_CONFIG.exactMatchWeight
	end

	-- Name starts with query (high priority)
	if itemName:sub(1, #query) == query then
		return 0.95
	end

	-- Name contains query as substring
	if itemName:find(query, 1, true) then
		return 0.85
	end

	-- Category exact match
	if itemCategory == query then
		return 0.75
	end

	-- Category contains query
	if itemCategory:find(query, 1, true) then
		return 0.65
	end

	-- Description contains query
	if itemDescription:find(query, 1, true) then
		return 0.50
	end

	-- Fuzzy matching: count character matches
	local fuzzyScore = self:calculateFuzzyScore(itemName, query)
	if fuzzyScore > 0 then
		return fuzzyScore
	end

	return 0
end

--- Fuzzy matching algorithm: Levenshtein-like distance
-- @param text: Text to match
-- @param query: Query to match against
-- @returns score between 0 and 1
function SearchBarController:calculateFuzzyScore(text, query)
	if #text == 0 or #query == 0 then
		return 0
	end

	local matches = 0
	local textIndex = 1

	for i = 1, #query do
		local char = query:sub(i, i)
		local found = false

		for j = textIndex, #text do
			if text:sub(j, j) == char then
				matches = matches + 1
				textIndex = j + 1
				found = true
				break
			end
		end

		if not found then
			return 0
		end
	end

	-- Score: ratio of matched chars to query length
	local score = matches / #query
	return score * SEARCH_CONFIG.fuzzyMatchWeight
end

--- Load items from server (optional)
function SearchBarController:loadItemsFromServer(state, itemsData)
	state.allItems = itemsData or {}
	print("✓ SearchBarController: Loaded " .. #state.allItems .. " items")
end

--- Update item list dynamically
function SearchBarController:updateItems(state, newItems)
	state.allItems = newItems
	-- Re-perform search if there's an active query
	if state.lastQuery ~= "" then
		self:performSearch(state)
	end
end

return SearchBarController