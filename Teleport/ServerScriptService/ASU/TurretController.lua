--[[
================================================================================
  TurretController.lua
================================================================================
  - **Purpose:** Core logic for the ASU, including the FSM and combat mechanics.
  - **Location:** ServerScriptService/ASU
  - **Type:** ModuleScript
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Parent.GameConfig)
local ASU_Fire_Replicate = ReplicatedStorage.RemoteEvents.ASU_Fire_Replicate

local TurretController = {}
TurretController.__index = TurretController

function TurretController.new(turretModel)
    local self = setmetatable({}, TurretController)
    self.TurretModel = turretModel
    self.State = "Idle"
    self.SuppressionAccumulator = 1.0
    self.Config = {}
    self.lastFireTime = 0
    self.missStreak = 0
    return self
end

function TurretController:SetConfig(config)
    self.Config = config
end

function TurretController:Start()
    -- The main loop is now managed by the service that spawns this
    self:Run()
end

function TurretController:Run()
    local deltaTime = 0
    while self.TurretModel and self.TurretModel.Parent do
        local target = self:FindClosestTarget()
        local waitTime = 1.0 -- Default wait time for Idle/Suppressing

        if target then
            local hasLOS = self:CheckLOS(target)
            if hasLOS then
                self.State = "Engaged"
                self:EngageTarget(target)
                waitTime = 0.1 -- Engaged state, check more frequently
            else
                self.State = "Suppressing"
                self:SuppressTarget(target)
            end
        else
            self.State = "Idle"
        end

        -- Suppression decay
        if self.State ~= "Engaged" then
            self.SuppressionAccumulator = math.max(1.0, self.SuppressionAccumulator - (0.05 * deltaTime))
        end

        deltaTime = task.wait(waitTime)
    end
end

function TurretController:FindClosestTarget()
    -- Placeholder for target finding logic
    local players = game:GetService("Players"):GetPlayers()
    local closestTarget = nil
    local minDistance = self.Config.ActivationRange

    for _, player in ipairs(players) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (self.TurretModel.PrimaryPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                closestTarget = player.Character
            end
        end
    end
    return closestTarget
end

function TurretController:CheckLOS(target)
    local origin = self.TurretModel.PrimaryPart.Position
    local direction = (target.HumanoidRootPart.Position - origin).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {self.TurretModel, target}

    local result = workspace:Raycast(origin + direction, direction * self.Config.ActivationRange, raycastParams)
    return not result
end

function TurretController:EngageTarget(target)
    local weaponStats = GameConfig.Weapons[self.Config.WeaponType]
    if not weaponStats then return end

    if (tick() - self.lastFireTime) > (1 / weaponStats.FireRate) then
        self.lastFireTime = tick()

        local direction = self:CalculateConeSpreadDirection(target)
        local origin = self.TurretModel.PrimaryPart.Position + direction -- Offset origin

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {self.TurretModel}

        local result = workspace:Raycast(origin, direction * weaponStats.Range, raycastParams)

        local isPlayerHit = false
        if result and result.Instance and result.Instance:IsDescendantOf(target) then
            -- Apply damage
            isPlayerHit = true
            self.SuppressionAccumulator = 1.0 -- Reset on hit
            self.missStreak = 0
        else
            self.missStreak = self.missStreak + 1
            if self.missStreak >= 3 then
                self.SuppressionAccumulator = 1.0
                self.missStreak = 0
            end
        end
        ASU_Fire_Replicate:FireAllClients(self.TurretModel, result, isPlayerHit, false, direction)
    end
end

function TurretController:SuppressTarget(target)
    local weaponStats = GameConfig.Weapons[self.Config.WeaponType]
    if not weaponStats then return end

    if (tick() - self.lastFireTime) > (1 / weaponStats.FireRate) then
        self.lastFireTime = tick()

        -- Forced Near Miss Logic
        local targetPart = math.random(1, 2) == 1 and "Head" or "HumanoidRootPart"
        local targetPosition = target[targetPart].Position
        local offset = Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
        local nearMissPosition = targetPosition + offset

        local direction = (nearMissPosition - self.TurretModel.PrimaryPart.Position).Unit
        local origin = self.TurretModel.PrimaryPart.Position + direction -- Offset origin

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {self.TurretModel, target}

        local result = workspace:Raycast(origin, direction * weaponStats.Range, raycastParams)

        if result then
            self.SuppressionAccumulator = math.min(2.0, self.SuppressionAccumulator + 0.1)
            ASU_Fire_Replicate:FireAllClients(self.TurretModel, result, false, true, direction)
        end
    end
end

function TurretController:CalculateConeSpreadDirection(target)
    local weaponStats = GameConfig.Weapons[self.Config.WeaponType]
    local difficulty = GameConfig.DifficultySettings[self.Config.InitialDifficulty]
    local spreadAngle = weaponStats.BaseSpread * difficulty.AccuracyMultiplier * (1 / self.SuppressionAccumulator)

    local direction = (target.HumanoidRootPart.Position - self.TurretModel.PrimaryPart.Position).Unit

    local axis1 = direction:Cross(Vector3.new(0, 1, 0))
    if axis1.Magnitude < 1e-6 then axis1 = direction:Cross(Vector3.new(1, 0, 0)) end
    axis1 = axis1.Unit
    local axis2 = direction:Cross(axis1).Unit

    local angle = math.rad(spreadAngle) * math.sqrt(math.random())
    local randomAngle = math.random() * 2 * math.pi

    local spreadDirection = CFrame.fromAxisAngle(axis1, angle) * direction
    spreadDirection = CFrame.fromAxisAngle(direction, randomAngle) * spreadDirection

    return spreadDirection
end


return TurretController
