-- ServerScriptService > manager(Folder) > clean_minigame_manager(ModuleScript)
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local clean_minigame_manager = {}

local pending = {}

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

-- Fungsi untuk hitung total trash dari ServerStorage
local function count_trash_items()
	local clean_folder = ServerStorage
		:FindFirstChild("assets")
		and ServerStorage:FindFirstChild("assets"):FindFirstChild("minigame")
		and ServerStorage:FindFirstChild("assets"):FindFirstChild("minigame"):FindFirstChild("clean")
	
	if not clean_folder then
		warn("[clean_minigame_manager] clean folder tidak ditemukan di ServerStorage")
		return 0
	end

	local count = 0
	for _, child in ipairs(clean_folder:GetChildren()) do
		if child:IsA("Model") or child:IsA("BasePart") then
			count = count + 1
		end
	end

	return count
end

-- Fungsi untuk setup trash dengan ProximityPrompt
local function setup_trash_items(player)
	local clean_folder = ServerStorage
		:FindFirstChild("assets")
		and ServerStorage:FindFirstChild("assets"):FindFirstChild("minigame")
		and ServerStorage:FindFirstChild("assets"):FindFirstChild("minigame"):FindFirstChild("clean")
	
	if not clean_folder then
		warn("[clean_minigame_manager] clean folder tidak ditemukan")
		return
	end

	local user_id = player.UserId
	local trash_list = {}

	for _, trash_part in ipairs(clean_folder:GetChildren()) do
		if trash_part:IsA("Model") or trash_part:IsA("BasePart") then
			table.insert(trash_list, trash_part)

			-- Cari atau buat ProximityPrompt
			local prompt = trash_part:FindFirstChild("ProximityPrompt")
			if not prompt then
				prompt = Instance.new("ProximityPrompt")
				prompt.Parent = trash_part
			end

			prompt.ActionText = "Bersihkan"
			prompt.ObjectText = "Sampah"

			-- Handle prompt interaction
			prompt.Triggered:Connect(function(player_who_triggered)
				if player_who_triggered.UserId ~= user_id then
					return
				end

				-- Fire event ke client untuk animasi/feedback
				game_event:FireClient(player_who_triggered, "trash_cleaned", {
					trash_name = trash_part.Name,
				})

				-- Simpan ke pending untuk track progress
				if not pending[user_id].cleaned_trash then
					pending[user_id].cleaned_trash = {}
				end

				if not pending[user_id].cleaned_trash[trash_part.Name] then
					pending[user_id].cleaned_trash[trash_part.Name] = true
					pending[user_id].remaining_trash = pending[user_id].remaining_trash - 1

					-- Fire event untuk update UI counter
					game_event:FireClient(player_who_triggered, "trash_count_update", {
						remaining = pending[user_id].remaining_trash,
					})

					-- Cek apakah semua trash sudah dibersihkan
					if pending[user_id].remaining_trash <= 0 then
						pending[user_id].event:Fire({
							success = true,
							finished_early = true,
						})
					end
				end
			end)
		end
	end

	return trash_list
end

function clean_minigame_manager.start(player, minigame_id)
	if not player then
		warn("[clean_minigame_manager] player tidak valid")
		return {
			success = false,
			message = "player tidak valid",
		}
	end

	local user_id = player.UserId

	if pending[user_id] then
		return {
			success = false,
			message = "player masih menjalankan clean minigame",
		}
	end

	-- Hitung total trash
	local total_trash = count_trash_items()
	if total_trash == 0 then
		warn("[clean_minigame_manager] tidak ada trash untuk di-clean")
		return {
			success = false,
			message = "tidak ada trash",
		}
	end

	local finished_event = Instance.new("BindableEvent")

	pending[user_id] = {
		minigame_id = minigame_id,
		event = finished_event,
		remaining_trash = total_trash,
		cleaned_trash = {},
		start_time = tick(),
		time_limit = 120, -- 120 detik
	}

	-- Freeze player saat minigame dimulai
	freeze_player(player)

	-- Setup trash items dengan proximity prompt
	setup_trash_items(player)

	-- Fire event ke client untuk start countdown dan tampilkan UI
	game_event:FireClient(player, "clean_minigame_start", {
		minigame_id = minigame_id,
		total_trash = total_trash,
		time_limit = 120,
	})

	-- Timer loop - cek setiap 1 detik
	local timer_thread = task.spawn(function()
		while pending[user_id] do
			task.wait(1)

			local elapsed = tick() - pending[user_id].start_time
			local remaining_time = pending[user_id].time_limit - elapsed

			if remaining_time <= 0 then
				-- Waktu habis
				if pending[user_id].event then
					pending[user_id].event:Fire({
						success = pending[user_id].remaining_trash == 0,
						time_expired = true,
					})
				end
				break
			end

			-- Update timer di client
			game_event:FireClient(player, "clean_minigame_timer_update", {
				time_remaining = remaining_time,
			})
		end
	end)

	local result = finished_event.Event:Wait()

	pending[user_id] = nil
	finished_event:Destroy()

	-- Unfreeze player setelah minigame selesai
	unfreeze_player(player)

	return result
end

game_event.OnServerEvent:Connect(function(player, event_name, payload)
	if event_name ~= "clean_minigame_finished" then
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
		warn("[clean_minigame_manager] minigame_id tidak cocok")
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

return clean_minigame_manager