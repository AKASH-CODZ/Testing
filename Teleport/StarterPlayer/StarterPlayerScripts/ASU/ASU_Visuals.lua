--[[
================================================================================
  ASU_Visuals.lua
================================================================================
  - **Purpose:** Handles all client-side visual and audio effects for the ASU.
  - **Location:** StarterPlayer/StarterPlayerScripts/ASU
  - **Type:** LocalScript
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local ASU_Fire_Replicate = ReplicatedStorage.RemoteEvents.ASU_Fire_Replicate

local TRACER_COLOR = Color3.fromRGB(255, 100, 100)
local COVER_HIT_SOUND_ID = "rbxassetid://123456789" -- Placeholder
local PLAYER_HIT_SOUND_ID = "rbxassetid://987654321" -- Placeholder
local NEAR_MISS_SOUND_ID = "rbxassetid://112233445" -- Placeholder

local function drawTracer(startPosition, endPosition)
    local distance = (startPosition - endPosition).Magnitude
    local tracer = Instance.new("Part")
    tracer.BrickColor = BrickColor.new(TRACER_COLOR)
    tracer.Material = Enum.Material.Neon
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.Size = Vector3.new(0.1, 0.1, distance)
    tracer.CFrame = CFrame.new(startPosition, endPosition) * CFrame.new(0, 0, -distance / 2)
    tracer.Parent = workspace
    Debris:AddItem(tracer, 0.1)
end

local function createBlackHole(position, normal)
    local mark = Instance.new("Part")
    mark.BrickColor = BrickColor.new("Dark stone grey")
    mark.Material = Enum.Material.SmoothPlastic -- Using SmoothPlastic as a substitute for Air
    mark.Size = Vector3.new(0.5, 0.5, 0.1)
    mark.Anchored = true
    mark.CanCollide = false
    mark.CFrame = CFrame.lookAt(position, position + normal)
    mark.Parent = workspace
    Debris:AddItem(mark, 10)
end

local function playSound(soundId, parent)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Parent = parent
    sound:Play()
    Debris:AddItem(sound, 2)
end

local function onFire(turretModel, raycastResult, isPlayerHit, isNearMiss, direction)
    if not turretModel or not turretModel.PrimaryPart then return end

    local startPosition = turretModel.PrimaryPart.Position
    local endPosition = raycastResult and raycastResult.Position or (startPosition + (direction * 1000))

    drawTracer(startPosition, endPosition)

    if isPlayerHit then
        playSound(PLAYER_HIT_SOUND_ID, turretModel)
    elseif isNearMiss then
        playSound(NEAR_MISS_SOUND_ID, turretModel)
        if raycastResult then
            createBlackHole(raycastResult.Position, raycastResult.Normal)
        end
    elseif raycastResult then
        playSound(COVER_HIT_SOUND_ID, turretModel)
        createBlackHole(raycastResult.Position, raycastResult.Normal)
    end
end

ASU_Fire_Replicate.OnClientEvent:Connect(onFire)
