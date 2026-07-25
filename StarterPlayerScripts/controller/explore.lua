-- StarterPlayer > StarterCharacterScripts > controller(Folder) > explore(LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local player = Players.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")

local explore_manager = {}

-- State
local is_exploring = false
local explore_id = nil
local remaining_time = 0
local timer_thread = nil

-- Helpers
local function get_minigame_ui()
	local ingame = player_gui:FindFirstChild("ingame")
	if not ingame then return nil end
	
	local minigame = ingame:FindFirstChild("minigame")
	if not minigame then return nil end
	
	return minigame
end

local function get_timer_label()
	local minigame = get_minigame_ui()
	if not minigame then return nil end
	
	return minigame:FindFirstChild("timer")
end

local function get_hint_label()
	local minigame = get_minigame_ui()
	if not minigame then return nil end
	
	return minigame:FindFirstChild("item")
end

local function format_time(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", minutes, secs)
end

local function update_timer_display(time_left)
	local timer_label = get_timer_label()
	if not timer_label then return end
	
	timer_label.Text = format_time(time_left)
	
	-- Change color based on time remaining
	if time_left <= 10 then
		timer_label.TextColor3 = Color3.fromRGB(255, 0, 0) -- Merah
	elseif time_left <= 30 then
		timer_label.TextColor3 = Color3.fromRGB(255, 165, 0) -- Oranye
	else
		timer_label.TextColor3 = Color3.fromRGB(255, 255, 255) -- Putih
	end
end

local function start_timer(duration)
	if timer_thread then
		task.cancel(timer_thread)
	end
	
	remaining_time = duration
	
	timer_thread = task.spawn(function()
		while is_exploring and remaining_time > 0 do
			update_timer_display(remaining_time)
			task.wait(1)
			remaining_time -= 1
		end
		
		if is_exploring then
			update_timer_display(0)
		end
	end)
end

local function stop_timer()
	is_exploring = false
	if timer_thread then
		task.cancel(timer_thread)
		timer_thread = nil
	end
end

-- Main Functions
function explore_manager:start(data)
	explore_id = data.explore_id or "unknown"
	local duration = data.duration or 120
	local hint = data.hint or "Jelajahi area ini"
	
	is_exploring = true
	
	local minigame_ui = get_minigame_ui()
	if not minigame_ui then
		warn("[explore] minigame UI tidak ditemukan")
		return
	end
	
	-- Show minigame UI
	minigame_ui.Visible = true
	
	-- Set hint
	local hint_label = get_hint_label()
	if hint_label then
		hint_label.Text = "📍 " .. hint
		hint_label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	
	-- Start timer
	start_timer(duration)
	
	print("[explore] Explore started: " .. explore_id .. " - Duration: " .. duration .. "s")
end

function explore_manager:finish()
	stop_timer()
	
	local minigame_ui = get_minigame_ui()
	if minigame_ui then
		minigame_ui.Visible = false
	end
	
	print("[explore] Explore finished: " .. explore_id)
	
	-- Fire event ke server
	game_event:FireServer("explore_finished", {
		explore_id = explore_id,
		success = true,
	})
end

function explore_manager:is_active()
	return is_exploring
end

-- Listen untuk explore_start event dari server
game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name == "explore_start" then
		explore_manager:start(payload)
	end
end)

-- Optional: Listener untuk end explore dengan button atau kondisi tertentu
-- User bisa membuat button di UI untuk "Selesai Menjelajah"
-- atau bisa juga di-trigger otomatis saat timer habis

-- Listen untuk key press (misalnya E untuk selesai)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if explore_manager:is_active() and input.KeyCode == Enum.KeyCode.E then
		explore_manager:finish()
	end
end)

return explore_manager
