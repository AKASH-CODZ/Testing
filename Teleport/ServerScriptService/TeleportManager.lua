--[[
================================================================================
  TeleportManager.lua
================================================================================
  - **Purpose:** Handles teleportation requests from clients.
  - **Location:** ServerScriptService
  - **Type:** Script
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataManager = require(ServerScriptService:WaitForChild("PlayerManager"))

local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Remotes.Name = "Remotes"

local RequestTeleportToLobby = Remotes:FindFirstChild("RequestTeleportToLobby") or Instance.new("RemoteEvent", Remotes)
RequestTeleportToLobby.Name = "RequestTeleportToLobby"

RequestTeleportToLobby.OnServerEvent:Connect(function(player)
    local profile = PlayerDataManager:GetProfile(player)
    if profile then
        profile:ListenToHopReady(function()
            TeleportService:Teleport(1, player) -- Replace 1 with your Lobby's PlaceId
        end)
        profile:Release()
    end
end)
