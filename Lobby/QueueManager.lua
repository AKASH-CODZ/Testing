--[[

QueueManager.lua (UPDATED)

Location: ReplicatedStorage/Modules/QueueManager.lua

Purpose: Matchmaking queue management

]]

local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Logger = require(script.Parent:WaitForChild("Logger"))
local QueueManager = {}

local matchmakingQueues = {}

-- ============================================================================
-- QUEUE CLEANUP
-- ============================================================================

function QueueManager:CleanQueue(queue)
	local indicesToRemove = {}

	for i, plr in ipairs(queue.players) do
		if not plr.Parent then
			table.insert(indicesToRemove, i)
		end
	end

	for i = #indicesToRemove, 1, -1 do
		local index = indicesToRemove[i]
		local plr = queue.players[index]
		queue.dataPackages[plr.UserId] = nil
		table.remove(queue.players, index)
		Logger:Info("Queue", "Removed disconnected player")
	end
end

-- ============================================================================
-- GET OR CREATE QUEUE
-- ============================================================================

function QueueManager:GetOrCreateQueue(mode)
	if not matchmakingQueues[mode] then
		matchmakingQueues[mode] = {
			players = {},
			dataPackages = {}
		}
		Logger:Info("Queue", string.format("Created queue for mode: %s", mode))
	end

	return matchmakingQueues[mode]
end

-- ============================================================================
-- CHECK IF PLAYER IN QUEUE
-- ============================================================================

function QueueManager:IsPlayerInQueue(queue, player)
	for _, plr in ipairs(queue.players) do
		if plr == player then
			return true
		end
	end
	return false
end

-- ============================================================================
-- ADD PLAYER TO QUEUE
-- ============================================================================

function QueueManager:AddPlayerToQueue(mode, player, dataPackage)
	local queue = self:GetOrCreateQueue(mode)
	self:CleanQueue(queue)

	if self:IsPlayerInQueue(queue, player) then
		Logger:Warn("Queue", string.format("%s already in queue", player.Name))
		return false, "Already in queue"
	end

	table.insert(queue.players, player)
	queue.dataPackages[player.UserId] = dataPackage

	Logger:LogQueueAdd(player.Name, mode, #queue.players)
	return true, queue
end

-- ============================================================================
-- REMOVE PLAYER FROM QUEUE
-- ============================================================================

function QueueManager:RemovePlayerFromQueue(mode, player)
	local queue = matchmakingQueues[mode]
	if not queue then
		return false
	end

	for i, plr in ipairs(queue.players) do
		if plr == player then
			queue.dataPackages[player.UserId] = nil
			table.remove(queue.players, i)
			Logger:LogQueueRemove(player.Name, mode)
			return true
		end
	end

	return false
end

-- ============================================================================
-- GET QUEUE STATUS
-- ============================================================================

function QueueManager:GetQueueStatus(mode)
	local queue = matchmakingQueues[mode]
	if not queue then
		return {
			exists = false,
			playerCount = 0,
			players = {}
		}
	end

	local playerNames = {}
	for _, plr in ipairs(queue.players) do
		table.insert(playerNames, plr.Name)
	end

	return {
		exists = true,
		playerCount = #queue.players,
		players = playerNames,
		mode = mode
	}
end

-- ============================================================================
-- CHECK IF QUEUE IS FULL
-- ============================================================================

function QueueManager:IsQueueFull(queue, maxPlayers)
	return #queue.players >= maxPlayers
end

-- ============================================================================
-- START MATCH FROM QUEUE
-- ============================================================================

function QueueManager:StartMatchFromQueue(mode, modeConfig, queue, safeTeleportFunction)
	if #queue.players < modeConfig.MinPlayers then
		Logger:Info("Queue", string.format("Waiting: %d/%d players", #queue.players, modeConfig.MinPlayers))
		return false
	end

	Logger:Info("Queue", string.format("MATCH START - %s with %d players", mode, #queue.players))

	local playersInMatch = {}

	for i = 1, math.min(#queue.players, modeConfig.MaxPlayers) do
		local plr = queue.players[i]
		table.insert(playersInMatch, plr)
	end

	for i = #playersInMatch, 1, -1 do
		table.remove(queue.players, i)
	end

	if RunService:IsStudio() then
		Logger:Debug("Queue", string.format("[STUDIO] Would teleport %d players", #playersInMatch))
		return true
	end

	Logger:Info("Queue", string.format("Reserving server for PlaceID: %d", modeConfig.PlaceID))

	local success, result = pcall(function()
		return TeleportService:ReserveServer(modeConfig.PlaceID)
	end)

	if not success then
		Logger:Error("Queue", string.format("ReserveServer FAILED: %s", result))
		for _, plr in ipairs(playersInMatch) do
			table.insert(queue.players, plr)
		end
		return false
	end

	local teleportOptions = Instance.new("TeleportOptions")

	if modeConfig.RequireReserveServer then
		teleportOptions.ShouldReserveServer = true
	end

	if safeTeleportFunction then
		local teleportSuccess = safeTeleportFunction(playersInMatch, modeConfig.PlaceID, teleportOptions)
		if teleportSuccess then
			Logger:Info("Queue", string.format("Match started (%d players)", #playersInMatch))
			return true
		else
			Logger:Error("Queue", "Teleport failed")
			return false
		end
	else
		Logger:Error("Queue", "No teleport function provided")
		return false
	end
end

-- ============================================================================
-- CLEAR ALL QUEUES
-- ============================================================================

function QueueManager:ClearAllQueues()
	matchmakingQueues = {}
	Logger:Info("Queue", "Cleared all queues")
end

-- ============================================================================
-- CLEAR SPECIFIC QUEUE
-- ============================================================================

function QueueManager:ClearQueue(mode)
	matchmakingQueues[mode] = nil
	Logger:Info("Queue", string.format("Cleared queue for %s", mode))
end

-- ============================================================================
-- GET ALL QUEUE STATS
-- ============================================================================

function QueueManager:GetAllQueueStats()
	local stats = {}
	for mode, queue in pairs(matchmakingQueues) do
		stats[mode] = {
			playerCount = #queue.players,
			players = {}
		}

		for _, plr in ipairs(queue.players) do
			table.insert(stats[mode].players, plr.Name)
		end
	end

	return stats
end

return QueueManager
