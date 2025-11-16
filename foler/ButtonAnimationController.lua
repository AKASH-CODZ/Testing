--[[
================================================================================
  ButtonAnimationController.lua - COMPLETE FIXED & COMPATIBLE VERSION
================================================================================
  Location: ReplicatedStorage/Modules/Inventory_Ui/ButtonAnimationController.lua
  Type: ModuleScript
  
  PURPOSE:
  - Handles all button animations and effects
  - Provides neon glow effect
  - Compatible with all UI systems
  - Modular and reusable
  
  FIXES APPLIED:
  ✓ FIX #1: Compatible with standard button handlers
  ✓ FIX #2: Works with multiple UI systems
  ✓ FIX #3: Type checking for safety
  ✓ FIX #4: No conflicts with TweenSize or other effects
================================================================================
]]

local ButtonAnimationController = {}

-- ============================================================================
-- ANIMATION CONFIGURATION
-- ============================================================================

local ANIMATION_CONFIG = {
	glowColor = Color3.fromRGB(0, 255, 150),
	glowIntensity = 0.8,
	glowDuration = 0.5,
	hoverScaleUp = 1.1,
	hoverAnimDuration = 0.2
}

-- ============================================================================
-- FUNCTION: Setup Neon Glow Effect
-- ============================================================================

--[[
  setupNeonGlow(button)
  Apply neon glow effect to a button
  
  ✓ FIX #1 & #2: Works with standard buttons
  
  @param button: GUI Button to apply effect to
]]

function ButtonAnimationController:setupNeonGlow(button)
	if not button then
		warn("[ButtonAnimationController] No button provided to setupNeonGlow")
		return false
	end

	if not button:IsA("GuiButton") then
		warn("[ButtonAnimationController] Provided object is not a GuiButton")
		return false
	end

	print("[ButtonAnimationController] Applying neon glow to: " .. button.Name)

	-- Store original color
	local originalColor = button.BackgroundColor3
	local originalTransparency = button.BackgroundTransparency

	-- Hover effect
	button.MouseEnter:Connect(function()
		-- Glow effect
		local targetColor = ANIMATION_CONFIG.glowColor
		local tweenInfo = TweenInfo.new(
			ANIMATION_CONFIG.glowDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.InOut
		)

		local tweenGoal = {BackgroundColor3 = targetColor}
		local tween = game:GetService("TweenService"):Create(button, tweenInfo, tweenGoal)
		tween:Play()

		print("[ButtonAnimationController] Hover: " .. button.Name .. " - glow ON")
	end)

	-- Mouse leave effect
	button.MouseLeave:Connect(function()
		-- Reset to original color
		local tweenInfo = TweenInfo.new(
			ANIMATION_CONFIG.glowDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.InOut
		)

		local tweenGoal = {BackgroundColor3 = originalColor}
		local tween = game:GetService("TweenService"):Create(button, tweenInfo, tweenGoal)
		tween:Play()

		print("[ButtonAnimationController] Leave: " .. button.Name .. " - glow OFF")
	end)

	-- Click effect
	button.MouseButton1Down:Connect(function()
		print("[ButtonAnimationController] Clicked: " .. button.Name)

		-- Visual feedback on click
		button.BackgroundTransparency = originalTransparency + 0.2
	end)

	button.MouseButton1Up:Connect(function()
		button.BackgroundTransparency = originalTransparency
	end)

	print("[ButtonAnimationController] Neon glow setup complete for: " .. button.Name)
	return true
end

-- ============================================================================
-- FUNCTION: Setup Hover Effect
-- ============================================================================

--[[
  addHoverEffect(button, targetSize)
  Add scale/hover effect to button
  
  @param button: GUI Button to apply effect to
  @param targetSize: Optional UDim2 size on hover
]]

function ButtonAnimationController:addHoverEffect(button, targetSize)
	if not button then
		warn("[ButtonAnimationController] No button provided to addHoverEffect")
		return false
	end

	if not button:IsA("GuiObject") then
		warn("[ButtonAnimationController] Provided object is not a GuiObject")
		return false
	end

	print("[ButtonAnimationController] Adding hover effect to: " .. button.Name)

	local originalSize = button.Size
	targetSize = targetSize or UDim2.new(
		originalSize.X.Scale * ANIMATION_CONFIG.hoverScaleUp,
		originalSize.X.Offset,
		originalSize.Y.Scale * ANIMATION_CONFIG.hoverScaleUp,
		originalSize.Y.Offset
	)

	button.MouseEnter:Connect(function()
		local tweenInfo = TweenInfo.new(
			ANIMATION_CONFIG.hoverAnimDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)

		local tweenGoal = {Size = targetSize}
		local tween = game:GetService("TweenService"):Create(button, tweenInfo, tweenGoal)
		tween:Play()
	end)

	button.MouseLeave:Connect(function()
		local tweenInfo = TweenInfo.new(
			ANIMATION_CONFIG.hoverAnimDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)

		local tweenGoal = {Size = originalSize}
		local tween = game:GetService("TweenService"):Create(button, tweenInfo, tweenGoal)
		tween:Play()
	end)

	return true
end

-- ============================================================================
-- FUNCTION: Setup Fade Effect
-- ============================================================================

--[[
  addFadeEffect(uiElement, duration)
  Add fade in/out effect to UI element
  
  @param uiElement: UI object to affect
  @param duration: Duration of fade
]]

function ButtonAnimationController:addFadeEffect(uiElement, duration)
	if not uiElement then
		warn("[ButtonAnimationController] No UI element provided to addFadeEffect")
		return false
	end

	if not uiElement:IsA("GuiObject") then
		warn("[ButtonAnimationController] Provided object is not a GuiObject")
		return false
	end

	duration = duration or 0.3

	print("[ButtonAnimationController] Adding fade effect to: " .. uiElement.Name)

	local function fadeIn()
		local tweenInfo = TweenInfo.new(duration)
		local tweenGoal = {BackgroundTransparency = 0}
		local tween = game:GetService("TweenService"):Create(uiElement, tweenInfo, tweenGoal)
		tween:Play()
		return tween
	end

	local function fadeOut()
		local tweenInfo = TweenInfo.new(duration)
		local tweenGoal = {BackgroundTransparency = 1}
		local tween = game:GetService("TweenService"):Create(uiElement, tweenInfo, tweenGoal)
		tween:Play()
		return tween
	end

	-- Return functions for external use
	uiElement.FadeIn = fadeIn
	uiElement.FadeOut = fadeOut

	return true
end

-- ============================================================================
-- FUNCTION: Setup Pulse Effect
-- ============================================================================

--[[
  addPulseEffect(uiElement)
  Add pulsing animation to UI element
  
  @param uiElement: UI object to pulse
]]

function ButtonAnimationController:addPulseEffect(uiElement)
	if not uiElement then
		warn("[ButtonAnimationController] No UI element provided to addPulseEffect")
		return false
	end

	print("[ButtonAnimationController] Adding pulse effect to: " .. uiElement.Name)

	task.spawn(function()
		while uiElement and uiElement.Parent do
			-- Pulse animation
			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			local tweenGoal = {BackgroundTransparency = 0.5}
			local tween = game:GetService("TweenService"):Create(uiElement, tweenInfo, tweenGoal)
			tween:Play()
			tween.Completed:Wait()

			local tweenInfo2 = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			local tweenGoal2 = {BackgroundTransparency = 0.2}
			local tween2 = game:GetService("TweenService"):Create(uiElement, tweenInfo2, tweenGoal2)
			tween2:Play()
			tween2.Completed:Wait()
		end
	end)

	return true
end

-- ============================================================================
-- FUNCTION: Setup Click Sound
-- ============================================================================

--[[
  addClickSound(button, soundId)
  Play sound effect on button click
  
  @param button: Button to attach sound to
  @param soundId: Roblox sound ID or asset ID
]]

function ButtonAnimationController:addClickSound(button, soundId)
	if not button then
		warn("[ButtonAnimationController] No button provided to addClickSound")
		return false
	end

	soundId = soundId or "rbxassetid://12221967"  -- Default click sound

	print("[ButtonAnimationController] Adding click sound to: " .. button.Name)

	button.MouseButton1Click:Connect(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = 0.5
		sound.Parent = button
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 0.5)
	end)

	return true
end

-- ============================================================================
-- EXPORT MODULE
-- ============================================================================

return ButtonAnimationController
