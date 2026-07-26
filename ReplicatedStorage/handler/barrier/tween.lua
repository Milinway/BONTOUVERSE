--[[
    BarrierTween Module
    Mengelola animasi fade in dan fade out untuk block menggunakan TweenService.
]]

local TweenService = game:GetService("TweenService")
local BarrierTween = {}

-- Konfigurasi Tween
local FADE_IN_DURATION = 0.3
local FADE_OUT_DURATION = 0.5
local TWEEN_EASING_STYLE = Enum.EasingStyle.Quad
local TWEEN_EASING_DIRECTION_IN = Enum.EasingDirection.Out
local TWEEN_EASING_DIRECTION_OUT = Enum.EasingDirection.In

--[[
    Membuat TweenInfo untuk fade in
    @return TweenInfo - Info tween untuk fade in
]]
local function createFadeInTweenInfo(): TweenInfo
	return TweenInfo.new(
		FADE_IN_DURATION,
		TWEEN_EASING_STYLE,
		TWEEN_EASING_DIRECTION_IN,
		0, -- repeatCount
		false, -- reverse
		0 -- delayTime
	)
end

--[[
    Membuat TweenInfo untuk fade out
    @return TweenInfo - Info tween untuk fade out
]]
local function createFadeOutTweenInfo(): TweenInfo
	return TweenInfo.new(
		FADE_OUT_DURATION,
		TWEEN_EASING_STYLE,
		TWEEN_EASING_DIRECTION_OUT,
		0,
		false,
		0
	)
end

--[[
    Fade in part (Transparency 1 -> 0)
    @param part (BasePart) - Part yang akan di-fade in
    @param callback (function?) - Callback saat tween selesai
    @return Tween - Instance tween
]]
function BarrierTween.fadeIn(part: BasePart, callback: ((boolean) -> ())?)
	if not part or not part.Parent then
		warn("BarrierTween.fadeIn: Part tidak valid atau sudah dihapus")
		return nil
	end

	-- Set initial transparency
	part.Transparency = 1

	local tweenInfo = createFadeInTweenInfo()
	local tweenGoal = {Transparency = 0}

	local tween = TweenService:Create(part, tweenInfo, tweenGoal)

	if callback then
		tween.Completed:Connect(callback)
	end

	tween:Play()

	return tween
end

--[[
    Fade out part (Transparency 0 -> 1)
    @param part (BasePart) - Part yang akan di-fade out
    @param callback (function?) - Callback saat tween selesai
    @return Tween - Instance tween
]]
function BarrierTween.fadeOut(part: BasePart, callback: ((boolean) -> ())?)
	if not part or not part.Parent then
		warn("BarrierTween.fadeOut: Part tidak valid atau sudah dihapus")
		return nil
	end

	-- Set initial transparency
	part.Transparency = 0

	local tweenInfo = createFadeOutTweenInfo()
	local tweenGoal = {Transparency = 1}

	local tween = TweenService:Create(part, tweenInfo, tweenGoal)

	if callback then
		tween.Completed:Connect(callback)
	end

	tween:Play()

	return tween
end

--[[
    Fade in multiple parts sekaligus
    @param parts (table) - Array of BasePart
    @param callback (function?) - Callback saat semua tween selesai
]]
function BarrierTween.fadeInMultiple(parts: {BasePart}, callback: ((boolean) -> ())?)
	if #parts == 0 then
		if callback then
			callback(true)
		end
		return
	end
    
	local completedCount = 0
	local totalCount = #parts

	for _, part in ipairs(parts) do
		BarrierTween.fadeIn(part, function()
			completedCount += 1
			if completedCount == totalCount and callback then
				callback(true)
			end
		end)
	end
end

--[[
    Fade out multiple parts sekaligus
    @param parts (table) - Array of BasePart
    @param callback (function?) - Callback saat semua tween selesai
]]
function BarrierTween.fadeOutMultiple(parts: {BasePart}, callback: ((boolean) -> ())?)
	if #parts == 0 then
		if callback then
			callback(true)
		end
		return
	end

	local completedCount = 0
	local totalCount = #parts

	for _, part in ipairs(parts) do
		BarrierTween.fadeOut(part, function()
			completedCount += 1
			if completedCount == totalCount and callback then
				callback(true)
			end
		end)
	end
end

--[[
    Fade in dengan ripple effect (spawn dari block terdekat ke terjauh)
    @param parts (table) - Array of BasePart
    @param sortedIndices (table) - Array of indices yang sudah diurutkan berdasarkan jarak
    @param rippleDelay (number) - Delay antar block dalam detik
    @param callback (function?) - Callback saat semua tween selesai
]]
function BarrierTween.fadeInRipple(parts: {BasePart}, sortedIndices: {number}, rippleDelay: number, callback: ((boolean) -> ())?)
	if #parts == 0 then
		if callback then
			callback(true)
		end
		return
	end

	local completedCount = 0
	local totalCount = #parts

	task.spawn(function()
		for i, index in ipairs(sortedIndices) do
			local part = parts[index]

			if part and part.Parent then
				local delay = (i - 1) * rippleDelay

				task.wait(delay)

				BarrierTween.fadeIn(part, function()
					completedCount += 1
					if completedCount == totalCount and callback then
						callback(true)
					end
				end)
			else
				completedCount += 1
				if completedCount == totalCount and callback then
					callback(true)
				end
			end
		end
	end)
end

--[[
    Fade out dengan ripple effect (destroy dari block terdekat ke terjauh)
    @param parts (table) - Array of BasePart
    @param sortedIndices (table) - Array of indices yang sudah diurutkan berdasarkan jarak
    @param rippleDelay (number) - Delay antar block dalam detik
    @param callback (function?) - Callback saat semua tween selesai
]]
function BarrierTween.fadeOutRipple(parts: {BasePart}, sortedIndices: {number}, rippleDelay: number, callback: ((boolean) -> ())?)
	if #parts == 0 then
		if callback then
			callback(true)
		end
		return
	end

	local completedCount = 0
	local totalCount = #parts

	task.spawn(function()
		for i, index in ipairs(sortedIndices) do
			local part = parts[index]

			if part and part.Parent then
				local delay = (i - 1) * rippleDelay

				task.wait(delay)

				BarrierTween.fadeOut(part, function()
					completedCount += 1
					if completedCount == totalCount and callback then
						callback(true)
					end
				end)
			else
				completedCount += 1
				if completedCount == totalCount and callback then
					callback(true)
				end
			end
		end
	end)
end

--[[
    Cancel tween dan reset transparency
    @param part (BasePart) - Part yang akan di-cancel
    @param targetTransparency (number) - Transparency target
]]
function BarrierTween.cancelTween(part: BasePart, targetTransparency: number?)
	if not part then return end

	local activeTweens = TweenService:GetPlayingTweens()

	for _, tween in ipairs(activeTweens) do
		if tween.Instance == part then
			tween:Cancel()
		end
	end

	if targetTransparency then
		part.Transparency = targetTransparency
	end
end

--[[
    Set konfigurasi tween (opsional)
    @param config (table) - {fadeInDuration, fadeOutDuration, easingStyle, easingDirectionIn, easingDirectionOut}
]]
function BarrierTween.setConfig(config: {[string]: any})
	if config.fadeInDuration then
		FADE_IN_DURATION = config.fadeInDuration
	end
	if config.fadeOutDuration then
		FADE_OUT_DURATION = config.fadeOutDuration
	end
	if config.easingStyle then
		TWEEN_EASING_STYLE = config.easingStyle
	end
	if config.easingDirectionIn then
		TWEEN_EASING_DIRECTION_IN = config.easingDirectionIn
	end
	if config.easingDirectionOut then
		TWEEN_EASING_DIRECTION_OUT = config.easingDirectionOut
	end
end

return BarrierTween
