--[[
PlayerManager.lua (Lobby)
Location: ServerScriptService/Player/PlayerManager.lua (ModuleScript)
PURPOSE: Load/save player data using ProfileService for session-locking and data integrity.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local PlayerDataHandler = require(script.Parent:WaitForChild("PlayerDataHandler"))
local Logger = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Logger"))

local PlayerDataManager = {}

local ProfileStore = ProfileService.GetProfileStore(
    "PlayerData",
    PlayerDataHandler.ProfileTemplate
)

local Profiles = {} -- {player = profile}

function PlayerDataManager:LoadProfile(player)
    local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)

    if profile then
        profile:Reconcile() -- Fill in missing (nil) values from the template
        profile:ListenToRelease(function()
            Profiles[player] = nil
            player:Kick("Your profile has been loaded from another session.")
        end)

        Profiles[player] = profile
        Logger:Info("PlayerManager", "Loaded profile for " .. player.Name, player)
    else
        player:Kick("Failed to load your profile. Please rejoin.")
    end
end

function PlayerDataManager:GetProfile(player)
    return Profiles[player]
end

function PlayerDataManager:ReleaseProfile(player)
    local profile = Profiles[player]
    if profile then
        profile:Release()
        Logger:Info("PlayerManager", "Released profile for " .. player.Name, player)
    end
end

Players.PlayerAdded:Connect(function(player)
    PlayerDataManager:LoadProfile(player)
end)

Players.PlayerRemoving:Connect(function(player)
    PlayerDataManager:ReleaseProfile(player)
end)

return PlayerDataManager
