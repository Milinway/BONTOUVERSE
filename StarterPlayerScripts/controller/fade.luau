-- StarterPlayerScripts > controller(Folder) > fade(LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local player_gui = player:WaitForChild("PlayerGui")

local notification_gui = player_gui:WaitForChild("notification", 30)

if not notification_gui then
	warn("[fade_controller] notification ScreenGui tidak ditemukan")
	return
end

local fade_frame = notification_gui:WaitForChild("fade", 30)

if not fade_frame then
	warn("[fade_controller] fade frame tidak ditemukan")
	return
end

local active_tween = nil

local function set_fade_transparency(value)
	if fade_frame:IsA("Frame") then
		fade_frame.BackgroundTransparency = value
	elseif fade_frame:IsA("ImageLabel") or fade_frame:IsA("ImageButton") then
		fade_frame.ImageTransparency = value
	end
end

local function get_fade_property(value)
	if fade_frame:IsA("Frame") then
		return {
			BackgroundTransparency = value,
		}
	end

	if fade_frame:IsA("ImageLabel") or fade_frame:IsA("ImageButton") then
		return {
			ImageTransparency = value,
		}
	end

	return nil
end

local function play_fade(mode, duration)
	mode = mode or "out"
	duration = duration or 0.8

	if active_tween then
		active_tween:Cancel()
		active_tween = nil
	end

	fade_frame.Visible = true
	fade_frame.Active = true
	fade_frame.ZIndex = 999

	local start_transparency
	local target_transparency

	if mode == "out" then
		-- Fade out: layar menjadi gelap.
		start_transparency = 1
		target_transparency = 0
	elseif mode == "in" then
		-- Fade in: layar gelap menghilang.
		start_transparency = 0
		target_transparency = 1
	else
		warn("[fade_controller] mode fade tidak dikenal:", mode)
		return
	end

	set_fade_transparency(start_transparency)

	local tween_goal = get_fade_property(target_transparency)

	if not tween_goal then
		warn("[fade_controller] fade harus berupa Frame / ImageLabel / ImageButton")
		return
	end

	active_tween = TweenService:Create(
		fade_frame,
		TweenInfo.new(
			duration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.InOut
		),
		tween_goal
	)

	active_tween:Play()
	active_tween.Completed:Wait()

	if mode == "in" then
		fade_frame.Visible = false
		fade_frame.Active = false
	end

	active_tween = nil
end

-- Initial state supaya fade tidak nutup layar saat awal game.
fade_frame.Visible = false
fade_frame.Active = false
set_fade_transparency(1)

game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name ~= "fade_play" then
		return
	end

	play_fade(
		payload.mode,
		payload.duration
	)
end)