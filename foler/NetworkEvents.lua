local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Pre-placed RemoteEvents in ReplicatedStorage
local teleportRequestEvent = ReplicatedStorage:WaitForChild("TeleportRequest")
-- ADD THIS NEW LINE:
local statusUpdateEvent = ReplicatedStorage:WaitForChild("MatchmakingStatusUpdate")

local NetworkEvents = {
	TeleportRequest = teleportRequestEvent,
	-- ADD THIS NEW LINE:
	MatchmakingStatusUpdate = statusUpdateEvent
}

return NetworkEvents