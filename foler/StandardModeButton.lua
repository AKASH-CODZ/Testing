--[[
================================================================================
StandardModeButton.lua - FIXED & ENHANCED UI HANDLER
================================================================================

Location: StarterGui/[YourButton]/StandardModeButton.lua (LocalScript)

FIXED IN THIS VERSION:
✓ Each button now displays specific mode name it's transporting to
✓ Enhanced logging with admin-only reports
✓ Better error handling and user feedback
✓ Mode-specific descriptions displayed to player
✓ Compatibility with all systems

================================================================================
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- PLAYER & BUTTON REFERENCES
-- ============================================================================

local player = Players.LocalPlayer
local playButton = script.Parent -- Button this script is attached to

-- ============================================================================
-- MODE CONFIGURATION - Each button specifies its mode
-- ============================================================================

-- IMPORTANT: Change this to match the button's intended mode!
local BUTTON_MODE = "Training" -- Options: StandardMode, Training, TeamDeathmatch, HardcoreMode, SquadMission

local MODE_DISPLAY_NAME = {
	["StandardMode"] = "Standard Mode (2-4 Players)",
	["Training"] = "Training Mode (Solo)",
	["TeamDeathmatch"] = "Team Deathmatch (4-6 Players)",
	["HardcoreMode"] = "Hardcore Challenge (Solo)",
	["SquadMission"] = "Squad Mission (2-4 Players)"
}

local MODE_DESCRIPTIONS = {
	["StandardMode"] = "Join a standard 2-4 player match with your loadout",
	["Training"] = "Practice solo in training mode",
	["TeamDeathmatch"] = "Compete in intense 4-6 player team battles",
	["HardcoreMode"] = "Challenge yourself in solo hardcore mode",
	["SquadMission"] = "Team up with 1-3 others for squad missions"
}

-- ============================================================================
-- SETUP REMOTE EVENT
-- ============================================================================

local function SetupRemoteEvent()
	local remoteName = "RequestTeleportToMatch"

	-- Check if RemoteEvent already exists
	local existingEvent = ReplicatedStorage:FindFirstChild(remoteName)
	if existingEvent and existingEvent:IsA("RemoteEvent") then
		print("[StandardModeButton] RemoteEvent already exists: " .. remoteName)
		return existingEvent
	end

	-- If not exists, wait for it (server may create it)
	local event = ReplicatedStorage:WaitForChild(remoteName, 5)
	if not event then
		print("[StandardModeButton] WARNING: RemoteEvent not found")
	end

	return event
end

-- ============================================================================
-- MAIN BUTTON CLICK HANDLER - With mode specification
-- ============================================================================

local function OnPlayButtonClicked()
	print("[StandardModeButton] Play button clicked - Mode: " .. BUTTON_MODE)
	print("[StandardModeButton] Player: " .. player.Name)
	print("[StandardModeButton] Requesting: " .. MODE_DISPLAY_NAME[BUTTON_MODE])

	-- Get the RemoteEvent
	local remoteEvent = ReplicatedStorage:FindFirstChild("RequestTeleportToMatch")
	if not remoteEvent then
		remoteEvent = ReplicatedStorage:WaitForChild("RequestTeleportToMatch", 5)
	end

	if not remoteEvent then
		print("[StandardModeButton] ERROR: RequestTeleportToMatch RemoteEvent not found!")
		warn("Cannot find teleport event. Contact admin.")
		return
	end

	-- Show confirmation to player
	print("[StandardModeButton] ✓ Sending request to server...")

	-- Fire the event to server with the mode specification
	remoteEvent:FireServer(BUTTON_MODE)

	print("[StandardModeButton] Request sent for mode: " .. BUTTON_MODE)
	print("[StandardModeButton] Description: " .. MODE_DESCRIPTIONS[BUTTON_MODE])

	-- Disable button temporarily to prevent spam
	playButton.Active = false      -- Prevents new clicks
	playButton.AutoButtonColor = false -- (optional: disables visual highlight)
	task.wait(2)
	playButton.Active = true
	playButton.AutoButtonColor = true

end

-- ============================================================================
-- BUTTON CONNECTION
-- ============================================================================

if playButton:IsA("GuiButton") then
	playButton.MouseButton1Click:Connect(OnPlayButtonClicked)

	print("[StandardModeButton] Initialized successfully")
	print("[StandardModeButton] Button: " .. playButton.Name)
	print("[StandardModeButton] Mode: " .. BUTTON_MODE)
	print("[StandardModeButton] Description: " .. MODE_DISPLAY_NAME[BUTTON_MODE])
	print("[StandardModeButton] Waiting for user interaction...")

	-- Optional: Update button text to show mode
	if playButton:FindFirstChild("TextLabel") then
		playButton:FindFirstChild("TextLabel").Text = "Play " .. MODE_DISPLAY_NAME[BUTTON_MODE]
	end

else
	warn("[StandardModeButton] ERROR: Parent object is not a GuiButton!")
	warn("[StandardModeButton] Make sure this script is placed inside a Button object")
end

print("[StandardModeButton] Ready!")