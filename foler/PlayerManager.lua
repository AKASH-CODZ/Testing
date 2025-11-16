--[[
PlayerManager.lua
Location: ServerScriptService/Player/PlayerManager.lua (ModuleScript)
PURPOSE: Load/save player data with error recovery
FIXES: Data backup prevents wipes, error protection, count validation
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ServerStorage:WaitForChild("MyServerFolder"):WaitForChild("GameConfig"))
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Logger"))

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v2")
local BackupDataStore = DataStoreService:GetDataStore("PlayerData_Backup")  -- BACKUP STORE

local sessionData = {}
local PlayerDataManager = {}

-- ============================================================================
-- DEEP COPY
-- ============================================================================

local function DeepCopy(original)
	if type(original) ~= "table" then return original end
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			copy[k] = DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- ============================================================================
-- VALIDATE & NORMALIZE: Ensure counts are numbers
-- ============================================================================

local function NormalizePlayerData(data)
	if not data then return nil end

	if data.owned then
		for itemId, count in pairs(data.owned) do
			if type(count) == "boolean" then
				data.owned[itemId] = count and 1 or nil
			elseif type(count) ~= "number" then
				data.owned[itemId] = 1
			end
		end
	end

	return data
end

-- ============================================================================
-- LOAD DATA (With backup recovery)
-- ============================================================================

function PlayerDataManager:LoadData(player)
	local userId = player.UserId
	local data = nil

	-- Try primary store
	local success, result = pcall(function()
		return PlayerDataStore:GetAsync("Player_" .. userId)
	end)

	if success and result then
		Logger:Info("PlayerManager", "Loaded primary: " .. player.Name, player)
		data = GameConfig:MigrateOldFormat(result)
	else
		-- Primary failed, try backup
		local backupSuccess, backupResult = pcall(function()
			return BackupDataStore:GetAsync("Player_" .. userId)
		end)

		if backupSuccess and backupResult then
			Logger:Warn("PlayerManager", "Primary failed, restored from backup: " .. player.Name, player)
			data = GameConfig:MigrateOldFormat(backupResult)
		else
			-- Both failed, use defaults
			Logger:Info("PlayerManager", "No data, using defaults: " .. player.Name, player)
			data = DeepCopy(GameConfig.DefaultPlayerData)
		end
	end

	-- Normalize & validate
	data = NormalizePlayerData(data)

	-- Ensure structure
	if not data.owned or type(data.owned) ~= "table" then
		data.owned = DeepCopy(GameConfig.DefaultPlayerData.owned)
	end
	if not data.equipped or type(data.equipped) ~= "table" then
		data.equipped = DeepCopy(GameConfig.DefaultPlayerData.equipped)
	end

	-- Fallback to defaults if empty
	if not next(data.owned) then
		Logger:Info("PlayerManager", "Empty inventory, using defaults: " .. player.Name, player)
		data.owned = DeepCopy(GameConfig.DefaultPlayerData.owned)
		data.equipped = DeepCopy(GameConfig.DefaultPlayerData.equipped)
	end

	-- Validate
	local isValid, reason = GameConfig:ValidatePlayerData(data)
	if not isValid then
		Logger:Warn("PlayerManager", "Data validation failed: " .. reason .. " for " .. player.Name, player)
		data = DeepCopy(GameConfig.DefaultPlayerData)
	end

	sessionData[userId] = data
	return data
end

-- ============================================================================
-- GET DATA
-- ============================================================================

function PlayerDataManager:GetData(player)
	if not player then return nil end

	local userId = player.UserId

	if not sessionData[userId] then
		self:LoadData(player)
	end

	return sessionData[userId]
end

-- ============================================================================
-- SAVE DATA (With backup protection)
-- ============================================================================

function PlayerDataManager:SaveData(player, data)
	if not player then return false end

	local userId = player.UserId

	-- Normalize before save
	data = NormalizePlayerData(data)

	-- Try primary save
	local success, err = pcall(function()
		PlayerDataStore:SetAsync("Player_" .. userId, data)
	end)

	if success then
		-- Also save to backup for recovery
		pcall(function()
			BackupDataStore:SetAsync("Player_" .. userId, data)
		end)

		sessionData[userId] = data
		Logger:Info("PlayerManager", "Saved: " .. player.Name, player)
		return true
	else
		-- Save failed: Keep in session (DON'T WIPE!)
		Logger:Error("PlayerManager", "Save failed for " .. player.Name .. ": " .. tostring(err), player)
		sessionData[userId] = data  -- Keep data in memory
		return false  -- Failed but data not lost
	end
end

-- ============================================================================
-- EMERGENCY SAVE: Before disconnect (Critical)
-- ============================================================================

function PlayerDataManager:EmergencySave(player)
	if not player then return end

	local userId = player.UserId
	local data = sessionData[userId]

	if data then
		-- Try both stores
		pcall(function()
			PlayerDataStore:SetAsync("Player_" .. userId, data)
		end)

		pcall(function()
			BackupDataStore:SetAsync("Player_" .. userId, data)
		end)
	end
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

Players.PlayerRemoving:Connect(function(player)
	PlayerDataManager:EmergencySave(player)
	local userId = player.UserId
	sessionData[userId] = nil
end)

Logger:Info("PlayerManager", "Initialized (with backup)", nil)

return PlayerDataManager
