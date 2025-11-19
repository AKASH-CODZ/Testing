--[[
================================================================================
  ASU_SpawnService.lua
================================================================================
  - **Purpose:** Manages the instantiation and initialization of all ASU units.
  - **Location:** ReplicatedStorage/Spawn/Modules
  - **Type:** ModuleScript
================================================================================
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Parent.GameConfig)
local TurretController = require(ServerScriptService.ASU.TurretController)

local ASU_SpawnService = {}

function ASU_SpawnService:Init()
    local mapId = "M1_City" -- Example Map ID
    local mapData = GameConfig.MapData[mapId]

    if not mapData then
        warn("ASU_SpawnService: No map data found for MapID:", mapId)
        return
    end

    for _, deployment in ipairs(mapData.ASUDeployments) do
        task.spawn(function()
            local asuTemplate = ReplicatedStorage.ASU_Template -- Assuming a template model exists
            if not asuTemplate then
                warn("ASU_SpawnService: ASU_Template not found in ReplicatedStorage.")
                return
            end

            local newASU = asuTemplate:Clone()
            newASU.PrimaryPart.CFrame = deployment.Position
            newASU.Parent = workspace

            local controller = TurretController.new(newASU)
            controller:SetConfig({
                WeaponType = deployment.WeaponType,
                InitialDifficulty = deployment.InitialDifficulty,
                ActivationRange = deployment.ActivationRange
            })
            controller:Start()
        end)
    end
end

return ASU_SpawnService
