--[[

NonceValidator.lua (UPDATED)

Location: ReplicatedStorage/Modules/NonceValidator.lua

Purpose: Nonce generation, validation, and security

]]

local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Logger = require(script.Parent:WaitForChild("Logger"))
local NonceValidator = {}

local TeleportNonces = MemoryStoreService:GetSortedMap("TeleportNonces")

-- ============================================================================
-- HELPER: Retry with exponential backoff
-- ============================================================================

local function RetryWithBackoff(operation, maxRetries, initialDelay)
	maxRetries = maxRetries or 3
	initialDelay = initialDelay or 1

	for attempt = 1, maxRetries do
		local success, result = pcall(operation)
		if success then
			return true, result
		end

		if attempt < maxRetries then
			local delay = initialDelay * (2 ^ (attempt - 1))
			Logger:Debug("MemoryStore", string.format("Retry %d/%d, wait %.1fs", attempt, maxRetries, delay))
			task.wait(delay)
		end
	end

	return false, "Failed after " .. maxRetries .. " attempts"
end

-- ============================================================================
-- NONCE GENERATION (OUTBOUND)
-- ============================================================================

function NonceValidator:GenerateAndSaveNonce(player, ttl)
	ttl = ttl or 60
	local nonce = HttpService:GenerateGUID(false)

	local success, err = RetryWithBackoff(function()
		TeleportNonces:SetAsync(nonce, player.UserId, ttl)
	end, 3, 1)

	if not success then
		Logger:Error("Nonce", string.format("Failed to generate nonce for %s: %s", player.Name, err))
		return nil
	end

	Logger:Debug("Nonce", string.format("Generated nonce for %s (TTL: %ds)", player.Name, ttl))
	return nonce
end

-- ============================================================================
-- NONCE VALIDATION (INBOUND)
-- ============================================================================

function NonceValidator:ValidateNonce(player, nonce)
	if not nonce or type(nonce) ~= "string" then
		Logger:Warn("Nonce", string.format("Invalid nonce format for %s", player.Name))
		return false
	end

	local success, storedUserId = RetryWithBackoff(function()
		return TeleportNonces:GetAsync(nonce)
	end, 3, 1)

	if not success then
		Logger:Error("Nonce", string.format("MemoryStore query failed for %s", player.Name))
		return false
	end

	if storedUserId ~= player.UserId then
		Logger:Warn("Nonce", string.format("Validation FAILED for %s (UserId mismatch)", player.Name))
		return false
	end

	RetryWithBackoff(function()
		TeleportNonces:RemoveAsync(nonce)
	end, 2, 0.5)

	Logger:Info("Nonce", string.format("Nonce validated for %s", player.Name))
	return true
end

-- ============================================================================
-- INVALIDATE NONCE
-- ============================================================================

function NonceValidator:InvalidateNonce(nonce)
	RetryWithBackoff(function()
		TeleportNonces:RemoveAsync(nonce)
	end, 2, 0.5)

	Logger:Debug("Nonce", "Manually invalidated nonce")
end

-- ============================================================================
-- BATCH GENERATION
-- ============================================================================

function NonceValidator:GenerateNoncesForPlayers(players, ttl)
	ttl = ttl or 60
	local nonces = {}
	local failures = {}

	for _, player in ipairs(players) do
		local nonce = self:GenerateAndSaveNonce(player, ttl)
		if nonce then
			nonces[player.UserId] = nonce
		else
			table.insert(failures, player.UserId)
		end
	end

	if #failures > 0 then
		Logger:Warn("Nonce", string.format("Failed for %d/%d players", #failures, #players))
		return nonces, failures
	end

	Logger:Info("Nonce", string.format("Generated %d nonces successfully", #players))
	return nonces, {}
end

-- ============================================================================
-- BATCH VALIDATION
-- ============================================================================

function NonceValidator:ValidateNoncesForPlayers(playerNoncePairs)
	local invalidPlayers = {}

	for _, pair in ipairs(playerNoncePairs) do
		local player = pair[1]
		local nonce = pair[2]

		if not self:ValidateNonce(player, nonce) then
			table.insert(invalidPlayers, player.UserId)
		end
	end

	if #invalidPlayers > 0 then
		Logger:Warn("Nonce", string.format("%d invalid nonces", #invalidPlayers))
		return false, invalidPlayers
	end

	Logger:Info("Nonce", "All nonces validated successfully")
	return true, {}
end

return NonceValidator
