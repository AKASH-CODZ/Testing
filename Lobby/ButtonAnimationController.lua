--[[
================================================================================
  ButtonAnimationController.lua - REFACTORED AND MODERNIZED
================================================================================
  PURPOSE:
  - Handles all button animations and effects.
  - Provides a simple and reusable way to add visual feedback to UI elements.
================================================================================
]]

local ButtonAnimationController = {}

-- ============================================================================
-- ANIMATION CONFIGURATION
-- ============================================================================

local ANIMATION_CONFIG = {
	glowColor = Color3.fromRGB(0, 255, 150),
	glowDuration = 0.5,
}

-- ============================================================================
-- FUNCTION: Setup Neon Glow Effect
-- ============================================================================

function ButtonAnimationController:setupNeonGlow(button)
	if not button or not button:IsA("GuiButton") then
		warn("[ButtonAnimationController] Invalid button provided to setupNeonGlow")
		return false
	end

	local originalColor = button.BackgroundColor3

	button.MouseEnter:Connect(function()
		local tweenInfo = TweenInfo.new(
			ANIMATION_CONFIG.glowDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.InOut
		)
		local tween = game:GetService("TweenService"):Create(button, tweenInfo, {BackgroundColor3 = ANIMATION_CONFIG.glowColor})
		tween:Play()
	end)

	button.MouseLeave:Connect(function()
		local tweenInfo = TweenInfo.new(
			ANIMATION_CONFIG.glowDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.InOut
		)
		local tween = game:GetService("TweenService"):Create(button, tweenInfo, {BackgroundColor3 = originalColor})
		tween:Play()
	end)

	button.MouseButton1Click:Connect(function()
		-- Send data to UI manager to handle the animation
		-- This is a placeholder for the actual implementation
		print("[ButtonAnimationController] Clicked: " .. button.Name)
	end)

	return true
end

return ButtonAnimationController
