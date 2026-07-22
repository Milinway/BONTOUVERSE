-- StarterPlayerScripts > controller(Folder) > clean(LocalScript)
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
	warn("[clean_controller] ScreenGui ingame tidak ditemukan")
	return
end

local minigame_frame = ingame_gui:WaitForChild("minigame", 30)
if not minigame_frame then
	warn("[clean_controller] minigame frame tidak ditemukan")
	return
end

local starter_timer = ingame_gui:WaitForChild("starter_timer", 30)
if not starter_timer then
	warn("[clean_controller] starter_timer tidak ditemukan")
	return
end

local timer_label = minigame_frame:WaitForChild("timer", 30)
local item_label = minigame_frame:WaitForChild("item", 30)

if not timer_label or not item_label then
	warn("[clean_controller] timer atau item label tidak ditemukan")
	return
end

local current_minigame = nil
local is_playing = false
local items_cleaned = 0
local total_items = 0
local countdown_finished = false

local function show_starter_countdown()
	countdown_finished = false
	starter_timer.Visible = true
	starter_timer.Text = "3"
	sound_service.Play("click")

	task.wait(1)
	starter_timer.Text = "2"
	sound_service.Play("click")

	task.wait(1)
	starter_timer.Text = "1"
	sound_service.Play("click")

	task.wait(1)
	starter_timer.Text = "CLEAN!"
	sound_service.Play("click")

	task.wait(0.5)
	starter_timer.Visible = false
	countdown_finished = true
	is_playing = true
end

local function start_clean_minigame(minigame_data)
	current_minigame = minigame_data
	is_playing = false -- Belum bermain, tunggu countdown
	items_cleaned = 0
	total_items = minigame_data.total_trash or 0
	countdown_finished = false

	ingame_gui.Enabled = true
	minigame_frame.Visible = true

	-- Update item counter - awalnya 0/3 (0 sudah dibersihkan dari 3 total)
	item_label.Text = "Sampah: " .. items_cleaned .. "/" .. total_items

	-- Reset timer display
	timer_label.Text = "02:00"
	timer_label.TextColor3 = Color3.fromRGB(255, 255, 255)

	-- Show countdown
	task.spawn(show_starter_countdown)

	print("[clean_controller] clean minigame dimulai:", minigame_data.minigame_id)
end

local function update_timer(time_remaining)
	if not countdown_finished or not timer_label then
		return
	end

	local minutes = math.floor(time_remaining / 60)
	local seconds = math.floor(time_remaining % 60)
	timer_label.Text = string.format("%02d:%02d", minutes, seconds)

	-- Ubah warna jika sisa waktu sedikit
	if time_remaining <= 10 then
		timer_label.TextColor3 = Color3.fromRGB(255, 0, 0)
	elseif time_remaining <= 30 then
		timer_label.TextColor3 = Color3.fromRGB(255, 165, 0)
	else
		timer_label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function update_trash_count(remaining)
	if not countdown_finished or not item_label then
		return
	end

	items_cleaned = total_items - remaining
	item_label.Text = "Sampah: " .. items_cleaned .. "/" .. total_items

	if remaining == 0 then
		sound_service.Play("success")
		print("[clean_controller] semua sampah sudah dibersihkan!")

		-- Selesaikan minigame
		task.wait(1)
		finish_clean_minigame(true)
	end
end

local function finish_clean_minigame(success)
	if not current_minigame then
		return
	end

	is_playing = false
	minigame_frame.Visible = false
	ingame_gui.Enabled = false

	game_event:FireServer("clean_minigame_finished", {
		minigame_id = current_minigame.minigame_id,
		success = success,
	})
end

minigame_frame.Visible = false
starter_timer.Visible = false

game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name == "clean_minigame_start" then
		start_clean_minigame(payload)
		return
	end

	if event_name == "clean_minigame_timer_update" then
		update_timer(payload.time_remaining)
		return
	end

	if event_name == "trash_count_update" then
		update_trash_count(payload.remaining)
		return
	end

	if event_name == "trash_cleaned" then
		sound_service.Play("click")
		print("[clean_controller] trash dibersihkan:", payload.trash_name)
		return
	end
	
	if event_name == "player_unfreeze" then
		-- Server signal untuk unfreeze (opsional untuk safety)
		print("[clean_controller] player unfrozen dari server signal")
		return
	end
	
	if event_name == "clean_minigame_finished_cleanup" then
		-- Pastikan UI cleanup
		minigame_frame.Visible = false
		ingame_gui.Enabled = false
		print("[clean_controller] UI cleanup selesai")
		return
	end
end)