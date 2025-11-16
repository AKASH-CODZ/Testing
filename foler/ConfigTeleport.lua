--[[
	ConfigTeleport.luau
	Location: ReplicatedStorage/Modules/ConfigTeleport.luau
	Purpose: Centralized teleport configuration for all modes
]]

local ConfigTeleport = {
	-- Teleport retry logic
	ATTEMPT_LIMIT = 3,
	RETRY_DELAY = 3,
	FLOOD_DELAY = 15,

	-- Layer 1 Security: Rate limit
	SECURITY_COOLDOWN = 5,

	-- Nonce validation
	NONCE_TTL = 60,

	-- Valid game states for teleporting
	VALID_TELEPORT_STATES = {
		["Lobby"] = true,
		["Idle"] = true,
		["MainMenu"] = true,
	},

	-- =========================================================================
	-- TELEPORT MODES CONFIGURATION
	-- =========================================================================
	-- Structure: ModeName = {
	--   PlaceID (required): Destination place ID
	--   MinPlayers (required): Minimum players needed
	--   MaxPlayers (required): Maximum players allowed
	--   Type (required): "Direct" or "Matchmaking"
	--   RequireReserveServer (required): true/false for private servers
	--   AllowLoadout (required): true/false for item transfer
	-- }

	MODES = {
		-- ===== DIRECT TELEPORT MODES (Solo - 1 player) =====
		["HardcoreMode"] = {
			PlaceID = 114846565016250,
			MinPlayers = 1,
			MaxPlayers = 1,
			Type = "Direct",
			RequireReserveServer = false,
			AllowLoadout = true,
			Description = "Solo hardcore challenge"
		},

		["Training"] = {
			PlaceID = 114846565016250, -- CHANGE THIS TO YOUR TRAINING PLACE ID
			MinPlayers = 1,
			MaxPlayers = 1,
			Type = "Direct",
			RequireReserveServer = false,
			AllowLoadout = true,
			Description = "Solo training mode"
		},

		-- ===== MATCHMAKING MODES (2-6 players) =====
		["StandardMode"] = {
			PlaceID = 114846565016250, -- CHANGE THIS TO YOUR STANDARD MODE PLACE ID
			MinPlayers = 2,
			MaxPlayers = 4,
			Type = "Matchmaking",
			RequireReserveServer = true,
			AllowLoadout = true,
			Description = "2-4 player matches"
		},

		["TeamDeathmatch"] = {
			PlaceID = 114846565016250, -- CHANGE THIS TO YOUR TDM PLACE ID
			MinPlayers = 4,
			MaxPlayers = 6,
			Type = "Matchmaking",
			RequireReserveServer = true,
			AllowLoadout = true,
			Description = "4-6 player team match"
		},

		["SquadMission"] = {
			PlaceID = 114846565016250, -- CHANGE THIS TO YOUR SQUAD PLACE ID
			MinPlayers = 2,
			MaxPlayers = 4,
			Type = "Matchmaking",
			RequireReserveServer = true,
			AllowLoadout = true,
			Description = "2-4 player squad"
		},
	}
}

-- Helper function to validate mode exists
function ConfigTeleport:GetMode(modeName)
	return self.MODES[modeName]
end

-- Helper function to get all mode names
function ConfigTeleport:GetModeNames()
	local names = {}
	for modeName, _ in pairs(self.MODES) do
		table.insert(names, modeName)
	end
	return names
end

-- Helper function to validate mode configuration
function ConfigTeleport:ValidateMode(modeName)
	local mode = self.MODES[modeName]
	if not mode then return false, "Mode not found" end

	if not mode.PlaceID or mode.PlaceID == 0 then
		return false, "Invalid PlaceID"
	end

	if not mode.MinPlayers or not mode.MaxPlayers then
		return false, "Missing player limits"
	end

	if mode.MinPlayers > mode.MaxPlayers then
		return false, "MinPlayers cannot exceed MaxPlayers"
	end

	if mode.Type ~= "Direct" and mode.Type ~= "Matchmaking" then
		return false, "Invalid Type"
	end

	return true
end

return ConfigTeleport
