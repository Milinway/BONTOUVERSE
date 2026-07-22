local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local dialog_folder = ReplicatedStorage
	:WaitForChild("module")
	:WaitForChild("data")
	:WaitForChild("dialog")

local dialog_manager = {}

local dialog_cache = {}
local pending_dialog = {}

-- Fungsi untuk freeze player (disable movement)
local function freeze_player(player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
	end
end

-- Fungsi untuk unfreeze player (enable movement)
local function unfreeze_player(player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16 -- Default walk speed
		humanoid.JumpHeight = 7.2 -- Default jump height
	end
end

local function load_dialog_module(module_script)
	if dialog_cache[module_script] then
		return dialog_cache[module_script]
	end

	local success, result = pcall(function()
		return require(module_script)
	end)

	if not success then
		warn("[dialog_manager] gagal require:", module_script:GetFullName(), result)
		return nil
	end

	dialog_cache[module_script] = result

	return result
end

local function find_dialog(dialog_id)
	for _, module_script in ipairs(dialog_folder:GetChildren()) do
		if module_script:IsA("ModuleScript") then
			local data = load_dialog_module(module_script)

			if data and data[dialog_id] then
				return data[dialog_id]
			end
		end
	end

	return nil
end

local function build_full_dialog(dialog_data, choice_response)
	-- Clone dialog_data agar tidak memodifikasi original
	local new_dialog = {
		dialog_id = dialog_data.dialog_id,
		mode = dialog_data.mode,
		background_img = dialog_data.background_img,
		lines = table.clone(dialog_data.lines),
	}

	-- Jika ada choice_response, tambahkan ke lines
	if choice_response then
		for _, response_line in ipairs(choice_response) do
			table.insert(new_dialog.lines, response_line)
		end
	end

	return new_dialog
end

function dialog_manager.play(player, dialog_id, choice_response)
	if not player then
		return {
			success = false,
			message = "player tidak valid",
		}
	end

	if typeof(dialog_id) ~= "string" then
		return {
			success = false,
			message = "dialog_id tidak valid",
		}
	end

	local dialog_data = find_dialog(dialog_id)

	if not dialog_data then
		warn("[dialog_manager] dialog tidak ditemukan:", dialog_id)

		return {
			success = false,
			message = "dialog tidak ditemukan",
		}
	end

	local user_id = player.UserId

	if pending_dialog[user_id] then
		warn("[dialog_manager] player masih punya dialog aktif:", player.Name)

		return {
			success = false,
			message = "dialog masih aktif",
		}
	end

	local finished_event = Instance.new("BindableEvent")

	pending_dialog[user_id] = {
		dialog_id = dialog_id,
		event = finished_event,
	}

	-- Freeze player saat dialog dimulai
	freeze_player(player)

	-- Build dialog lengkap dengan choice_response jika ada
	local full_dialog = build_full_dialog(dialog_data, choice_response)

	game_event:FireClient(player, "dialog_play", full_dialog)

	local result = finished_event.Event:Wait()

	pending_dialog[user_id] = nil
	finished_event:Destroy()

	-- Unfreeze player setelah dialog selesai
	unfreeze_player(player)
	
	-- Signal ke client untuk unfreeze (untuk keamanan double-check)
	game_event:FireClient(player, "player_unfreeze")

	return {
		success = true,
		dialog_id = dialog_id,
		result = result,
	}
end

game_event.OnServerEvent:Connect(function(player, event_name, payload)
	if event_name ~= "dialog_finished" then
		return
	end

	print("[dialog_manager] menerima dialog_finished dari:", player.Name)

	local user_id = player.UserId
	local pending = pending_dialog[user_id]

	if not pending then
		return
	end

	if typeof(payload) ~= "table" then
		payload = {}
	end

	print(
		"[dialog_manager] payload:",
		payload.dialog_id,
		payload.choice_id,
		payload.is_correct
	)

	if payload.dialog_id ~= pending.dialog_id then
		warn(
			"[dialog_manager] dialog_id tidak cocok:",
			payload.dialog_id,
			pending.dialog_id
		)

		return
	end

	pending.event:Fire(payload)
end)

Players.PlayerRemoving:Connect(function(player)
	local user_id = player.UserId
	local pending = pending_dialog[user_id]

	if pending then
		pending.event:Fire({
			cancelled = true,
		})

		pending_dialog[user_id] = nil
	end
end)

return dialog_manager