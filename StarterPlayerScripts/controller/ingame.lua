-- StarterPlayerScripts > controller(Folder) > ingame(LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local sound_service = require(
	ReplicatedStorage
		:WaitForChild("service")
		:WaitForChild("sound")
)

local player_gui = player:WaitForChild("PlayerGui")

local ingame_gui = player_gui:WaitForChild("ingame", 30)

if not ingame_gui then
	warn("[ingame_controller] ScreenGui ingame tidak ditemukan")
	return
end

local main = ingame_gui:WaitForChild("main")

local knowledge_btn = main:WaitForChild("knowledge_btn")
local knowledge_frame = ingame_gui:WaitForChild("knowledge")

local current_value = knowledge_frame:WaitForChild("current")
local max_value = knowledge_frame:WaitForChild("max")

local title_lbl = knowledge_frame:WaitForChild("title")
local bar = knowledge_frame:WaitForChild("bar")
local bar_fill = bar:WaitForChild("isi")
local percent_lbl = bar_fill:WaitForChild("teks")

local current_tween = nil
local is_pinned_open = false
local auto_hide_token = 0

local function get_level_name(percent)
	if percent >= 90 then
		return "Local Tourism Expert"
	elseif percent >= 61 then
		return "Tour Guide Cakap"
	elseif percent >= 31 then
		return "Asisten Tour Guide"
	else
		return "Pemula"
	end
end

local function set_bar(value, max, instant)
	max = max or 100
	value = math.clamp(value or 0, 0, max)

	current_value.Value = value
	max_value.Value = max

	local ratio = 0

	if max > 0 then
		ratio = value / max
	end

	local percent = math.floor(ratio * 100 + 0.5)

	percent_lbl.Text = tostring(percent) .. "%"
	title_lbl.Text = "Tour Guide Knowledge"

	local target_size = UDim2.new(
		ratio,
		0,
		1,
		0
	)

	if current_tween then
		current_tween:Cancel()
		current_tween = nil
	end

	if instant then
		bar_fill.Size = target_size
	else
		current_tween = TweenService:Create(
			bar_fill,
			TweenInfo.new(
				0.45,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				Size = target_size,
			}
		)

		current_tween:Play()
	end
end

local function show_knowledge_temporarily()
	if is_pinned_open then
		return
	end

	auto_hide_token += 1

	local token = auto_hide_token

	knowledge_frame.Visible = true

	task.delay(2.5, function()
		if token ~= auto_hide_token then
			return
		end

		if is_pinned_open then
			return
		end

		knowledge_frame.Visible = false
	end)
end

knowledge_btn.MouseEnter:Connect(function()
	sound_service.Play("preview")
end)

knowledge_btn.Activated:Connect(function()
	sound_service.Play("click")

	is_pinned_open = not is_pinned_open
	knowledge_frame.Visible = is_pinned_open
end)

game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name == "homepage_hide" then
		ingame_gui.Enabled = true
		knowledge_frame.Visible = false
		is_pinned_open = false
		return
	end

	if event_name == "knowledge_update" then
		ingame_gui.Enabled = true

		local current = payload.current or 0
		local max = payload.max or 100

		set_bar(
			current,
			max,
			payload.is_reset == true
		)

		if not payload.is_reset then
			show_knowledge_temporarily()
		end

		return
	end

	if event_name == "chapter_complete" then
		-- Kasih waktu sebentar supaya player masih sempat lihat 100%.
		task.delay(2.5, function()
			ingame_gui.Enabled = false
			knowledge_frame.Visible = false
			is_pinned_open = false
			set_bar(0, 100, true)
		end)

		return
	end
end)

ingame_gui.Enabled = false
knowledge_frame.Visible = false
set_bar(0, 100, true)