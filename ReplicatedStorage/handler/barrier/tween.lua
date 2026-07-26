-- FILE 2: ReplicatedStorage/handler/barrier/tween.lua
--[[
    BarrierTween Module - REVISED for Decal
    Handle transparency animation untuk Decal objects
]]

local TweenService = game:GetService("TweenService")
local BarrierTween = {}

local FADE_IN_DURATION = 0.5
local FADE_OUT_DURATION = 0.6
local TWEEN_EASING_STYLE = Enum.EasingStyle.Quad
local TWEEN_EASING_DIRECTION_IN = Enum.EasingDirection.Out
local TWEEN_EASING_DIRECTION_OUT = Enum.EasingDirection.In

local function createFadeInTweenInfo(): TweenInfo
    return TweenInfo.new(
        FADE_IN_DURATION,
        TWEEN_EASING_STYLE,
        TWEEN_EASING_DIRECTION_IN,
        0, false, 0
    )
end

local function createFadeOutTweenInfo(): TweenInfo
    return TweenInfo.new(
        FADE_OUT_DURATION,
        TWEEN_EASING_STYLE,
        TWEEN_EASING_DIRECTION_OUT,
        0, false, 0
    )
end

--[[
    Fade in single Decal
    @param decal (Decal) - Decal untuk di-fade in
    @param callback (function?) - Callback saat selesai
]]
function BarrierTween.fadeInDecal(decal: Decal, callback: ((boolean) -> ())?)
    if not decal or not decal.Parent then
        warn("BarrierTween.fadeInDecal: Decal tidak valid")
        return nil
    end
    
    decal.Transparency = 1
    
    local tweenInfo = createFadeInTweenInfo()
    local tweenGoal = {Transparency = 0}
    
    local tween = TweenService:Create(decal, tweenInfo, tweenGoal)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

--[[
    Fade out single Decal
]]
function BarrierTween.fadeOutDecal(decal: Decal, callback: ((boolean) -> ())?)
    if not decal or not decal.Parent then
        warn("BarrierTween.fadeOutDecal: Decal tidak valid")
        return nil
    end
    
    decal.Transparency = 0
    
    local tweenInfo = createFadeOutTweenInfo()
    local tweenGoal = {Transparency = 1}
    
    local tween = TweenService:Create(decal, tweenInfo, tweenGoal)
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    tween:Play()
    return tween
end

--[[
    Fade in multiple Decals dengan ripple
    @param decals (table) - Array of Decal
    @param sortedIndices (table) - Indices sorted by distance
    @param rippleDelay (number) - Delay antar decal
    @param callback (function?) - Callback saat semua selesai
]]
function BarrierTween.fadeInRippleDecals(decals: {Decal}, sortedIndices: {number}, rippleDelay: number, callback: ((boolean) -> ())?)
    if #decals == 0 then
        if callback then callback(true) end
        return
    end
    
    local completedCount = 0
    local totalCount = #decals
    
    task.spawn(function()
        for i, index in ipairs(sortedIndices) do
            local decal = decals[index]
            
            if decal and decal.Parent then
                local delay = (i - 1) * rippleDelay
                task.wait(delay)
                
                BarrierTween.fadeInDecal(decal, function()
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
    Fade out multiple Decals dengan ripple
]]
function BarrierTween.fadeOutRippleDecals(decals: {Decal}, sortedIndices: {number}, rippleDelay: number, callback: ((boolean) -> ())?)
    if #decals == 0 then
        if callback then callback(true) end
        return
    end
    
    local completedCount = 0
    local totalCount = #decals
    
    task.spawn(function()
        for i, index in ipairs(sortedIndices) do
            local decal = decals[index]
            
            if decal and decal.Parent then
                local delay = (i - 1) * rippleDelay
                task.wait(delay)
                
                BarrierTween.fadeOutDecal(decal, function()
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

function BarrierTween.setConfig(config: {[string]: any})
    if config.fadeInDuration then FADE_IN_DURATION = config.fadeInDuration end
    if config.fadeOutDuration then FADE_OUT_DURATION = config.fadeOutDuration end
    if config.easingStyle then TWEEN_EASING_STYLE = config.easingStyle end
    if config.easingDirectionIn then TWEEN_EASING_DIRECTION_IN = config.easingDirectionIn end
    if config.easingDirectionOut then TWEEN_EASING_DIRECTION_OUT = config.easingDirectionOut end
end

return BarrierTween