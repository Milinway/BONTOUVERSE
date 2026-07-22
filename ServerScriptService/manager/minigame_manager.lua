-- ServerScriptService > manager(Folder) > minigame_manager(ModuleScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local minigame_folder = ReplicatedStorage
	:WaitForChild("module")
	:WaitForChild("data")
	:WaitForChild("minigame")

local minigame_manager = {}

local cache = {}
local pending = {}

-- Load clean_minigame_manager
local manager_folder = ServerScriptService:WaitForChild("manager")
local clean_minigame_manager = require(manager_folder:WaitForChild("minigame_manager"):WaitForChild("clean_minigame"))

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

local function load_module(module_script)
	if cache[module_script] then
		return cache[module_script]
	end

	local success, result = pcall(function()
		return require(module_script)
	end)

	if not success then
		warn("[minigame_manager] gagal require:", module_script:GetFullName(), result)
		return nil
	end

	cache[module_script] = result
	return result
end

local function find_minigame(minigame_id)
	for _, module_script in ipairs(minigame_folder:GetChildren()) do
		if module_script:IsA("ModuleScript") then
			local data = load_module(module_script)

			if data and data[minigame_id] then
				return data[minigame_id]
			end
		end
	end

	return nil
end

function minigame_manager.start(player, minigame_id, minigame_type)
	-- Cek apakah ini clean minigame
	if minigame_type == "clean" then
		return clean_minigame_manager.start(player, minigame_id)
	end

	-- Regular minigame
	local data = find_minigame(minigame_id)

	if not data then
		warn("[minigame_manager] minigame tidak ditemukan:", minigame_id)

		return {
			success = false,
			message = "minigame tidak ditemukan",
		}
	end

	local user_id = player.UserId

	if pending[user_id] then
		return {
			success = false,
			message = "player masih menjalankan minigame",
		}
	end

	local finished_event = Instance.new("BindableEvent")

	pending[user_id] = {
		minigame_id = minigame_id,
		event = finished_event,
	}

	-- Freeze player saat minigame dimulai
	freeze_player(player)

	game_event:FireClient(player, "minigame_play", data)

	local result = finished_event.Event:Wait()

	pending[user_id] = nil
	finished_event:Destroy()

	-- Unfreeze player setelah minigame selesai
	unfreeze_player(player)

	return result
end

game_event.OnServerEvent:Connect(function(player, event_name, payload)
	if event_name ~= "minigame_finished" then
		return
	end

	local user_id = player.UserId
	local current = pending[user_id]

	if not current then
		return
	end

	if typeof(payload) ~= "table" then
		payload = {}
	end

	if payload.minigame_id ~= current.minigame_id then
		warn("[minigame_manager] minigame_id tidak cocok")
		return
	end

	current.event:Fire({
		success = payload.success == true,
		minigame_id = current.minigame_id,
	})
end)

Players.PlayerRemoving:Connect(function(player)
	local user_id = player.UserId
	local current = pending[user_id]

	if current then
		current.event:Fire({
			success = false,
			cancelled = true,
		})

		pending[user_id] = nil
	end
end)

return minigame_manager