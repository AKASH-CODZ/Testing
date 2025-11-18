--[[
================================================================================
  GameplayManager.lua - REFACTORED AND MODERNIZED
================================================================================
  PURPOSE:
  - Manages the gameplay logic for the teleported place.
  - Creates the "Win" and "Loss" blocks.
  - Securely updates player stats and rewards.
================================================================================
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- MODULE IMPORTS
-- ============================================================================

local PlayerDataManager = require(ServerScriptService:WaitForChild("Player"):WaitForChild("PlayerManager"))
local GameConfig = require(game:GetService("ServerStorage"):WaitForChild("MyServerFolder"):WaitForChild("GameConfig"))
