-- ServerScriptService > manager > minigame_manager(Folder) > clean_minigame(ModuleScript)
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
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

-- Fungsi untuk clone trash dari ServerStorage ke Workspace
local function spawn_trash_items()
	local clean_folder = ServerStorage
		:FindFirstChild("assets")
		and ServerStorage:FindFirstChild("assets"):FindFirstChild("minigame")
		and ServerStorage:FindFirstChild("assets"):FindFirstChild("minigame"):FindFirstChild("clean")

	if not clean_folder then
		warn("[clean_minigame] clean folder tidak ditemukan di ServerStorage")
		return {}
	end

	-- Cari atau buat Workspace > minigame_trash folder
	local workspace_trash_folder = Workspace:FindFirstChild("minigame_trash")
	if not workspace_trash_folder then
		workspace_trash_folder = Instance.new("Folder")
		workspace_trash_folder.Name = "minigame_trash"
		workspace_trash_folder.Parent = Workspace
	else
		-- Bersihkan trash lama
		workspace_trash_folder:ClearAllChildren()
	end

	local spawned_trash = {}

	for _, trash_part in ipairs(clean_folder:GetChildren()) do
		if trash_part:IsA("Model") or trash_part:IsA("BasePart") then
			local cloned_trash = trash_part:Clone()
			cloned_trash.Parent = workspace_trash_folder
			table.insert(spawned_trash, cloned_trash)

			print("[clean_minigame] trash spawned:", cloned_trash.Name)
		end
	end

	return spawned_trash
end

-- Fungsi untuk setup trash dengan ProximityPrompt
local function setup_trash_items(player, trash_list)
	local user_id = player.UserId

	for _, trash_part in ipairs(trash_list) do
		-- Cari primary part atau gunakan part itu sendiri
		local interact_part = trash_part
		if trash_part:IsA("Model") then
			interact_part = trash_part.PrimaryPart or trash_part:FindFirstChildWhichIsA("BasePart")
		end

		if not interact_part then
			warn("[clean_minigame] tidak bisa menemukan BasePart di:", trash_part.Name)
			continue
		end

		-- Cari atau buat ProximityPrompt
		local prompt = interact_part:FindFirstChild("ProximityPrompt")
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.Parent = interact_part
		end

		prompt.ActionText = "Bersihkan"
		prompt.ObjectText = "Sampah"

		-- Handle prompt interaction - gunakan closure untuk capture trash_part
		local function on_trash_triggered(player_who_triggered)
			if player_who_triggered.UserId ~= user_id then
				return
			end

			if not pending[user_id] then
				return
			end

			-- Cek apakah trash ini sudah dibersihkan
			local trash_name = trash_part.Name
			if pending[user_id].cleaned_trash[trash_name] then
				return -- Sudah dibersihkan, skip
			end

			-- Tandai sebagai sudah dibersihkan
			pending[user_id].cleaned_trash[trash_name] = true
			pending[user_id].remaining_trash = pending[user_id].remaining_trash - 1

			-- Fire event ke client untuk animasi/feedback
			game_event:FireClient(player_who_triggered, "trash_cleaned", {
				trash_name = trash_name,
			})

			-- Fire event untuk update UI counter
			game_event:FireClient(player_who_triggered, "trash_count_update", {
				remaining = pending[user_id].remaining_trash,
			})

			print("[clean_minigame] trash dibersihkan:", trash_name, "sisa:", pending[user_id].remaining_trash)

			-- Destroy trash dari workspace setelah diambil
			task.wait(0.1) -- Delay kecil agar animasi client sempat render
			trash_part:Destroy()
			print("[clean_minigame] trash destroyed dari workspace:", trash_name)

			-- Cek apakah semua trash sudah dibersihkan
			if pending[user_id].remaining_trash <= 0 then
				if pending[user_id].event and not pending[user_id].finished then
					pending[user_id].finished = true
					pending[user_id].event:Fire({
						success = true,
						finished_early = true,
					})
				end
			end
		end

		prompt.Triggered:Connect(on_trash_triggered)
	end
end

function clean_minigame_manager.start(player, minigame_id)
	if not player then
		warn("[clean_minigame] player tidak valid")
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

	-- Spawn trash items ke Workspace
	local trash_list = spawn_trash_items()
	local total_trash = #trash_list

	if total_trash == 0 then
		warn("[clean_minigame] tidak ada trash untuk di-clean")
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
		start_time = nil,
		time_limit = 120, -- 120 detik
		finished = false,
	}

	-- Freeze player saat minigame dimulai
	freeze_player(player)

	-- Setup trash items dengan proximity prompt
	setup_trash_items(player, trash_list)

	-- Fire event ke client untuk start countdown dan tampilkan UI
	game_event:FireClient(player, "clean_minigame_start", {
		minigame_id = minigame_id,
		total_trash = total_trash,
		time_limit = 120,
	})

	-- Timer loop - tunggu sampai starter_timer selesai, BARU dimulai (4.5 detik: 3-2-1-CLEAN!)
	task.wait(4.5)

	-- Unfreeze player SETELAH countdown selesai, jadi player bisa bermain
	unfreeze_player(player)

	-- Fire event ke client untuk unfreeze signal
	game_event:FireClient(player, "player_unfreeze")

	-- Cek apakah pending masih ada (keamanan)
	if not pending[user_id] then
		return {
			success = false,
			message = "minigame dibatalkan",
		}
	end

	-- Sekarang set start_time setelah countdown selesai
	pending[user_id].start_time = tick()

	-- Timer loop - cek setiap 1 detik
	local timer_thread = task.spawn(function()
		while pending[user_id] and not pending[user_id].finished do
			task.wait(1)

			-- Tambahkan cek apakah pending[user_id] masih ada
			if not pending[user_id] then
				break
			end

			local elapsed = tick() - pending[user_id].start_time
			local remaining_time = pending[user_id].time_limit - elapsed

			if remaining_time <= 0 then
				-- Waktu habis
				if pending[user_id] and pending[user_id].event and not pending[user_id].finished then
					pending[user_id].finished = true
					pending[user_id].event:Fire({
						success = pending[user_id].remaining_trash == 0,
						time_expired = true,
					})
				end
				break
			end

			-- Update timer di client
			if pending[user_id] then
				game_event:FireClient(player, "clean_minigame_timer_update", {
					time_remaining = remaining_time,
				})
			end
		end
	end)

	local result = finished_event.Event:Wait()

	pending[user_id] = nil
	finished_event:Destroy()

	-- Unfreeze player setelah minigame selesai (safety check)
	unfreeze_player(player)

	-- Fire event ke client untuk close UI dan unfreeze
	game_event:FireClient(player, "clean_minigame_finished_cleanup")

	-- Cleanup trash
	local workspace_trash_folder = Workspace:FindFirstChild("minigame_trash")
	if workspace_trash_folder then
		workspace_trash_folder:Destroy()
	end

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
		warn("[clean_minigame] minigame_id tidak cocok")
		return
	end

	if not current.finished then
		current.finished = true
		current.event:Fire({
			success = payload.success == true,
			minigame_id = current.minigame_id,
		})
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local user_id = player.UserId
	local current = pending[user_id]

	if current then
		if not current.finished then
			current.finished = true
			current.event:Fire({
				success = false,
				cancelled = true,
			})
		end

		pending[user_id] = nil
	end

	-- Cleanup trash
	local workspace_trash_folder = Workspace:FindFirstChild("minigame_trash")
	if workspace_trash_folder then
		workspace_trash_folder:Destroy()
	end
end)

return clean_minigame_manager