--[[
================================================================================
  TeleportRequestHandler.lua - SERVER SCRIPT (Hub Place)
================================================================================
  Location: ServerScriptService/TeleportRequestHandler (ServerScript)
  
  PURPOSE:
  - Listens to UI teleport requests via RemoteEvent
  - Creates RemoteEvent if it doesn't exist
  - Calls TeleportHub module to handle teleport
  - Full logging integration
  
  SETUP:
  1. Place this script in ServerScriptService of your HUB place
  2. It automatically creates the RemoteEvent
  3. When StandardModeButton fires the event, this handles it
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ============================================================================
-- CREATE OR GET REMOTE EVENT
-- ============================================================================

local function SetupRemoteEvent()
	local remoteName = "RequestTeleportToMatch"

	-- Check if RemoteEvent already exists
	local existingEvent = ReplicatedStorage:FindFirstChild(remoteName)

	if existingEvent and existingEvent:IsA("RemoteEvent") then
		print("[TeleportRequestHandler] RemoteEvent already exists: " .. remoteName)
		return existingEvent
	end

	-- Create new RemoteEvent
	local newEvent = Instance.new("RemoteEvent")
	newEvent.Name = remoteName
	newEvent.Parent = ReplicatedStorage

	print("[TeleportRequestHandler] Created RemoteEvent: " .. remoteName)
	return newEvent
end

-- ============================================================================
-- GET TELEPORT HUB MODULE
-- ============================================================================

local function GetTeleportHub()
	local modulePath = ReplicatedStorage:FindFirstChild("Modules")
	if not modulePath then
		warn("[TeleportRequestHandler] ERROR: Modules folder not found in ReplicatedStorage")
		return nil
	end

	local teleportHubModule = modulePath:FindFirstChild("TeleportHub")
	if not teleportHubModule then
		warn("[TeleportRequestHandler] ERROR: TeleportHub module not found")
		return nil
	end

	local success, TeleportHub = pcall(function()
		return require(teleportHubModule)
	end)

	if not success then
		warn("[TeleportRequestHandler] ERROR: Failed to load TeleportHub module: " .. tostring(TeleportHub))
		return nil
	end

	print("[TeleportRequestHandler] TeleportHub module loaded successfully")
	return TeleportHub
end

-- ============================================================================
-- INITIALIZE
-- ============================================================================

print("[TeleportRequestHandler] Initializing...")

local remoteEvent = SetupRemoteEvent()
local TeleportHub = GetTeleportHub()

if not TeleportHub then
	warn("[TeleportRequestHandler] FATAL: Could not load TeleportHub module!")
	warn("[TeleportRequestHandler] Make sure TeleportHub.lua is in ReplicatedStorage/Modules/")
end

-- ============================================================================
-- HANDLE TELEPORT REQUEST
-- ============================================================================

local function OnTeleportRequest(player)
	print("[TeleportRequestHandler] Teleport request received from: " .. player.Name)

	if not TeleportHub then
		print("[TeleportRequestHandler] ERROR: TeleportHub not available")
		return
	end

	-- Call TeleportHub to handle the teleport
	local success = TeleportHub:TeleportToMatch(player)

	if success then
		print("[TeleportRequestHandler] Teleport initiated for: " .. player.Name)
	else
		print("[TeleportRequestHandler] Teleport failed or blocked for: " .. player.Name)
	end
end

-- ============================================================================
-- CONNECT REMOTE EVENT
-- ============================================================================

if remoteEvent then
	remoteEvent.OnServerEvent:Connect(OnTeleportRequest)
	print("[TeleportRequestHandler] Listening for teleport requests...")
else
	warn("[TeleportRequestHandler] ERROR: RemoteEvent not available")
end

print("[TeleportRequestHandler] Ready!")

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
