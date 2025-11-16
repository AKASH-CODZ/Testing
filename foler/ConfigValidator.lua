--[[

ConfigValidator.lua

Location: ReplicatedStorage/Modules/ConfigValidator.lua (ModuleScript)

Purpose: Validates all configuration on server startup

]]

local Logger = require(script.Parent:WaitForChild("Logger"))
local ConfigValidator = {}

-- ============================================================================
-- VALIDATE MODE CONFIGURATION
-- ============================================================================

function ConfigValidator:ValidateMode(modeName, modeConfig)
	local issues = {}

	if not modeConfig.PlaceID or modeConfig.PlaceID == 0 then
		table.insert(issues, "Missing or invalid PlaceID")
	end

	if not modeConfig.MinPlayers or modeConfig.MinPlayers < 1 then
		table.insert(issues, "MinPlayers must be >= 1")
	end

	if not modeConfig.MaxPlayers or modeConfig.MaxPlayers < 1 then
		table.insert(issues, "MaxPlayers must be >= 1")
	end

	if modeConfig.MinPlayers and modeConfig.MaxPlayers then
		if modeConfig.MinPlayers > modeConfig.MaxPlayers then
			table.insert(issues, "MinPlayers cannot exceed MaxPlayers")
		end
	end

	if not modeConfig.Type or (modeConfig.Type ~= "Direct" and modeConfig.Type ~= "Matchmaking") then
		table.insert(issues, "Type must be 'Direct' or 'Matchmaking'")
	end

	if modeConfig.RequireReserveServer == nil then
		table.insert(issues, "RequireReserveServer not set")
	end

	if modeConfig.AllowLoadout == nil then
		table.insert(issues, "AllowLoadout not set")
	end

	return #issues == 0, issues
end

-- ============================================================================
-- VALIDATE ALL MODES
-- ============================================================================

function ConfigValidator:ValidateAllModes(configModes)
	local totalModes = 0
	local validModes = 0
	local failedModes = {}

	for modeName, modeConfig in pairs(configModes) do
		totalModes = totalModes + 1
		local isValid, issues = self:ValidateMode(modeName, modeConfig)

		if isValid then
			validModes = validModes + 1
			Logger:Info("Config", string.format("Mode '%s' validated", modeName))
		else
			table.insert(failedModes, {name = modeName, issues = issues})
			Logger:Error("Config", string.format("Mode '%s' has issues: %s", modeName, table.concat(issues, ", ")))
		end
	end

	Logger:Info("Config", string.format("Validation: %d/%d modes valid", validModes, totalModes))

	return validModes == totalModes, failedModes
end

-- ============================================================================
-- COMPREHENSIVE STARTUP CHECK
-- ============================================================================

function ConfigValidator:RunFullValidation(config)
	Logger:Info("Config", "Starting configuration validation...")

	local modesValid, failedModes = self:ValidateAllModes(config.MODES)

	if config.NONCE_TTL and config.NONCE_TTL < 30 then
		Logger:Warn("Config", "NONCE_TTL is very low (< 30s)")
	end

	if config.SECURITY_COOLDOWN and config.SECURITY_COOLDOWN < 1 then
		Logger:Warn("Config", "SECURITY_COOLDOWN is very low")
	end

	if config.ATTEMPT_LIMIT and config.ATTEMPT_LIMIT < 1 then
		Logger:Error("Config", "ATTEMPT_LIMIT must be at least 1")
		return false
	end

	if modesValid then
		Logger:Info("Config", "Configuration validation PASSED")
		return true
	else
		Logger:Error("Config", string.format("Configuration validation FAILED - %d modes have issues", #failedModes))
		return false
	end
end

return ConfigValidator
