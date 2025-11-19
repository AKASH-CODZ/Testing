--[[
================================================================================
  GameConfig.lua
================================================================================
  - **Purpose:** Single source of truth for all game configuration.
  - **Location:** ServerStorage/MyServerFolder
  - **Type:** ModuleScript
================================================================================
]]

local GameConfig = {}

-- ============================================================================
-- ADMIN LIST (Works both in Studio and in-game)
-- ============================================================================

GameConfig.Admins = {
	9131428746,   -- Example Admin 1
	1320112016    -- Example Admin 2
	-- Add your UserID here for admin access in-game
}

-- ============================================================================
-- HELPER: Check if player is admin (Studio-safe)
-- ============================================================================

function GameConfig:IsAdmin(player)
	if not player then return false end

	-- Studio mode: Allow all (for testing)
	if game:GetService("RunService"):IsStudio() then
		-- Uncomment line below to make ONLY these admins in studio
		-- return self:CheckAdminList(player)

		-- For now: All players are admins in studio
		return true
	end

	-- Production mode: Check admin list
	return self:CheckAdminList(player)
end

function GameConfig:CheckAdminList(player)
	if not player or not player.UserId then return false end
	for _, userId in ipairs(self.Admins) do
		if player.UserId == userId then return true end
	end
	return false
end

-- ============================================================================
-- ALL ITEMS CATALOG (Single source - use numbers for count, not booleans!)
-- ============================================================================

GameConfig.AllItems = {
	["BasicSword"] = {
		id = "BasicSword",
		name = "Basic Sword",
		type = "weapon",
		damage = 10,
		weight = 5,
		category = "Weapons",
		description = "A trusty, sharp piece of metal.",
		rarity = "common",
		price = 50
	},
	["IronArmor"] = {
		id = "IronArmor",
		name = "Iron Armor",
		type = "armor",
		defense = 5,
		weight = 8,
		category = "Armor",
		description = "Protects you from pointy things.",
		rarity = "common",
		price = 100
	},
	["HealthPotion"] = {
		id = "HealthPotion",
		name = "Health Potion",
		type = "consumable",
		healAmount = 25,
		weight = 1,
		category = "Potions",
		description = "Gulp.",
		rarity = "common",
		price = 20,
		stackable = true
	},
	["FireStaff"] = {
		id = "FireStaff",
		name = "Fire Staff",
		type = "weapon",
		damage = 15,
		weight = 6,
		category = "Weapons",
		description = "Deals fire damage",
		rarity = "rare",
		price = 150
	},
	["ManaPotion"] = {
		id = "ManaPotion",
		name = "Mana Potion",
		type = "consumable",
		manaRestore = 50,
		weight = 1,
		category = "Potions",
		description = "Restores mana",
		rarity = "rare",
		price = 75,
		stackable = true
	},
	["SteelShield"] = {
		id = "SteelShield",
		name = "Steel Shield",
		type = "armor",
		defense = 8,
		weight = 10,
		category = "Armor",
		description = "Reinforced steel defense",
		rarity = "uncommon",
		price = 120
	}
}

-- ============================================================================
-- TELEPORT MODES CONFIGURATION
-- ============================================================================
GameConfig.TeleportSettings = {
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
}

GameConfig.TeleportModes = {
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


-- ============================================================================
-- ASU SYSTEM CONFIGURATION
-- ============================================================================
GameConfig.ASU_SYSTEM = {
    MapData = {
        ["M1_City"] = {
            ASUDeployments = {
                {
                    Position = CFrame.new(0, 10, 0),
                    WeaponType = "Standard",
                    InitialDifficulty = "Normal",
                    ActivationRange = 100
                },
                {
                    Position = CFrame.new(50, 10, 50),
                    WeaponType = "Sniper",
                    InitialDifficulty = "Hard",
                    ActivationRange = 200
                }
            }
        }
    },
    Weapons = {
        ["Standard"] = {
            FireRate = 5, -- Shots per second
            Damage = 10,
            BaseSpread = 5, -- degrees
            Range = 500
        },
        ["Sniper"] = {
            FireRate = 1,
            Damage = 50,
            BaseSpread = 1,
            Range = 2000
        }
    },
    DifficultySettings = {
        ["Easy"] = {
            AccuracyMultiplier = 1.5
        },
        ["Normal"] = {
            AccuracyMultiplier = 1.0
        },
        ["Hard"] = {
            AccuracyMultiplier = 0.5
        }
    }
}

-- ============================================================================
-- MIGRATE: Old format (bool) to new format (count)
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

function GameConfig:MigrateOldFormat(playerData)
	if not playerData or type(playerData) ~= "table" then
		return DeepCopy(self.DefaultPlayerData)
	end

	local newData = DeepCopy(playerData)

	-- Migrate OwnedItems → owned
	if newData.OwnedItems and not newData.owned then
		newData.owned = newData.OwnedItems
		newData.OwnedItems = nil
	end

	-- Migrate Loadouts → equipped
	if newData.Loadouts and not newData.equipped then
		newData.equipped = {}
		local loadoutName = newData.EquippedLoadoutName or "Loadout1"
		local loadout = newData.Loadouts[loadoutName] or {}
		if type(loadout) == "table" then
			for _, itemId in ipairs(loadout) do
				if itemId and type(itemId) == "string" then
					newData.equipped[itemId] = true
				end
			end
		end
		newData.Loadouts = nil
		newData.EquippedLoadoutName = nil
	end

	-- FIX: Convert bool values to counts (CRITICAL!)
	if newData.owned and type(newData.owned) == "table" then
		for itemId, value in pairs(newData.owned) do
			if value == true then
				newData.owned[itemId] = 1  -- true → 1
			elseif value == false then
				newData.owned[itemId] = nil  -- false → remove
			elseif type(value) ~= "number" then
				newData.owned[itemId] = 1  -- Unknown → 1
			end
		end
	end

	-- Ensure structure
	if not newData.owned or type(newData.owned) ~= "table" then
		newData.owned = {}
	end
	if not newData.equipped or type(newData.equipped) ~= "table" then
		newData.equipped = {}
	end

	return newData
end

-- ============================================================================
-- VALIDATE: Data integrity check (SECURITY)
-- ============================================================================

function GameConfig:ValidatePlayerData(playerData)
	if not playerData then
		return false, "No player data"
	end

	-- Check owned items are numbers
	if playerData.owned then
		for itemId, count in pairs(playerData.owned) do
			if type(count) ~= "number" then
				return false, "Invalid count for " .. itemId
			end
		end
	end

	return true
end

-- ============================================================================
-- GET: All items
-- ============================================================================

function GameConfig:GetAllItems()
	local items = {}
	for itemId, itemData in pairs(self.AllItems) do
		table.insert(items, itemData)
	end
	return items
end

return GameConfig
