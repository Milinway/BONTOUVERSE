-- ServerScriptService > manager(Folder) > scene_manager(ModuleScript)
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local scene_manager = {}

local pending_after_choice = {}

local function optional_require(module_script)
	local success, result = pcall(function()
		return require(module_script)
	end)

	if success then
		return result
	end

	warn("[scene_manager] gagal require:", module_script:GetFullName(), result)
	return nil
end

local manager_folder = ServerScriptService:WaitForChild("manager")

local dialog_manager = optional_require(manager_folder:WaitForChild("dialog_manager"))
local fade_manager = optional_require(manager_folder:WaitForChild("fade_manager"))
local teleport_manager = optional_require(manager_folder:WaitForChild("teleport_manager"))
local knowledge_manager = optional_require(manager_folder:WaitForChild("knowledge_manager"))
local minigame_manager = optional_require(manager_folder:WaitForChild("minigame_manager"))
local quiz_manager = optional_require(manager_folder:WaitForChild("quiz_manager"))

local function call_manager(manager, function_name, ...)
	if manager and typeof(manager[function_name]) == "function" then
		return true, manager[function_name](...)
	end

	warn("[scene_manager] manager belum punya fungsi:", function_name)
	return false, nil
end

local function apply_knowledge(player, value, reason)
	print("[scene_manager] knowledge:", player.Name, value, reason or "")

	if knowledge_manager and typeof(knowledge_manager.set) == "function" then
		knowledge_manager.set(player, value, reason)
	else
		warn("[scene_manager] knowledge_manager.set belum siap")
	end
end

local function find_dialog_by_id(dialog_id)
	local dialog_folder = ReplicatedStorage
		:WaitForChild("module")
		:WaitForChild("data")
		:WaitForChild("dialog")

	for _, module_script in ipairs(dialog_folder:GetChildren()) do
		if module_script:IsA("ModuleScript") then
			local success, data = pcall(function()
				return require(module_script)
			end)

			if success and data and data[dialog_id] then
				return data[dialog_id]
			end
		end
	end

	return nil
end

local function run_step(player, step)
	if step.action == "homepage_hide" then
		game_event:FireClient(player, "homepage_hide")
		return { success = true }
	end

	if step.action == "dialog" then
		print("[scene_manager] dialog:", step.dialog_id)

		local success, result = call_manager(
			dialog_manager,
			"play",
			player,
			step.dialog_id
		)

		if not success then
			warn("[scene_manager] sequence dihentikan karena dialog_manager.play belum siap")
			return { success = false, stop = true }
		end

		-- Ambil dialog data untuk akses after_choices
		local dialog_data = find_dialog_by_id(step.dialog_id)

		-- Return hasil dialog (termasuk choice_id jika ada)
		if result and result.result then
			return {
				success = true,
				choice_id = result.result.choice_id,
				is_correct = result.result.is_correct,
				dialog_data = dialog_data, -- Simpan dialog_data lengkap
			}
		end

		return { success = true, dialog_data = dialog_data }
	end

	if step.action == "after_choice_dialog" then
		print("[scene_manager] after_choice_dialog")

		-- Cek apakah ada choice_result dari step sebelumnya
		if not step.choice_result or not step.choice_result.choice_id then
			print("[scene_manager] tidak ada choice_result, skip after_choice_dialog")
			return { success = true }
		end

		local choice_id = step.choice_result.choice_id
		local dialog_data = step.choice_result.dialog_data

		if not dialog_data then
			warn("[scene_manager] dialog_data tidak ditemukan")
			return { success = true }
		end

		if not dialog_data.after_choices then
			print("[scene_manager] dialog tidak punya after_choices, skip")
			return { success = true }
		end

		local after_choice = dialog_data.after_choices[choice_id]

		if not after_choice then
			warn("[scene_manager] after_choice untuk " .. choice_id .. " tidak ditemukan")
			return { success = true }
		end

		print("[scene_manager] mainkan after_choice dialog:", after_choice.dialog_id)

		local user_id = player.UserId
		local finished_event = Instance.new("BindableEvent")

		pending_after_choice[user_id] = {
			dialog_id = after_choice.dialog_id,
			event = finished_event,
		}

		-- Siapkan after_choice_data untuk dikirim ke client
		local after_choice_data = {
			dialog_id = after_choice.dialog_id,
			mode = after_choice.mode,
			background_img = after_choice.background_img,
			lines = after_choice.lines,
		}

		-- Kirim langsung ke client
		print("[scene_manager] kirim after_choice_data ke client")
		game_event:FireClient(player, "dialog_play", after_choice_data)

		-- BLOCKING: Tunggu sampai dialog selesai
		print("[scene_manager] menunggu after_choice dialog selesai...")
		local result = finished_event.Event:Wait()
		print("[scene_manager] after_choice dialog SELESAI")

		pending_after_choice[user_id] = nil
		finished_event:Destroy()

		return { success = true }
	end

	if step.action == "fade" then
		print("[scene_manager] fade:", step.mode)

		call_manager(
			fade_manager,
			"play",
			player,
			step.mode,
			step.duration
		)

		return { success = true }
	end

	if step.action == "checkpoint" then
		print("[scene_manager] checkpoint:", step.checkpoint_id)

		game_event:FireClient(player, "checkpoint_reached", {
			checkpoint_id = step.checkpoint_id,
		})

		return { success = true }
	end

	if step.action == "teleport" then
		print("[scene_manager] teleport:", step.destination_id)

		call_manager(
			teleport_manager,
			"teleport",
			player,
			step.destination_id
		)

		return { success = true }
	end

	if step.action == "waypoint" then
		print("[scene_manager] waypoint:", step.waypoint_id)

		game_event:FireClient(player, "waypoint_show", {
			waypoint_id = step.waypoint_id,
			text = step.text,
		})

		return { success = true }
	end

	if step.action == "knowledge_set" then
		apply_knowledge(
			player,
			step.value,
			step.reason
		)

		return { success = true }
	end

	if step.action == "minigame" then
		print("[scene_manager] minigame:", step.minigame_id)

		local result = call_manager(
			minigame_manager,
			"start",
			player,
			step.minigame_id
		)

		local success = true

		if typeof(result) == "table" and result.success ~= nil then
			success = result.success == true
		end

		if success and step.on_success and step.on_success.knowledge then
			apply_knowledge(
				player,
				step.on_success.knowledge,
				"Minigame berhasil: " .. step.minigame_id
			)
		elseif not success and step.on_fail and step.on_fail.knowledge then
			apply_knowledge(
				player,
				step.on_fail.knowledge,
				"Minigame gagal: " .. step.minigame_id
			)
		end

		return { success = true }
	end

	if step.action == "quiz" then
		print("[scene_manager] quiz:", step.quiz_id)

		local result = call_manager(
			quiz_manager,
			"start",
			player,
			step.quiz_id
		)

		local success = true

		if typeof(result) == "table" and result.success ~= nil then
			success = result.success == true
		end

		if success and step.on_success and step.on_success.knowledge then
			apply_knowledge(
				player,
				step.on_success.knowledge,
				"Quiz berhasil: " .. step.quiz_id
			)
		end

		return { success = true }
	end

	if step.action == "chapter_complete" then
		print("[scene_manager] chapter complete:", player.Name, step.chapter_id)

		game_event:FireClient(player, "chapter_complete", {
			chapter_id = step.chapter_id,
		})

		return { success = true }
	end

	warn("[scene_manager] action tidak dikenal:", step.action)
	return { success = true }
end

-- LISTENER: Terima dialog_finished event dari client
game_event.OnServerEvent:Connect(function(player, event_name, payload)
	if event_name ~= "dialog_finished" then
		return
	end

	local user_id = player.UserId

	-- Cek apakah ini after_choice_dialog yang sedang pending
	if pending_after_choice[user_id] then
		local pending = pending_after_choice[user_id]

		if payload and payload.dialog_id == pending.dialog_id then
			print("[scene_manager] after_choice dialog_finished diterima:", payload.dialog_id)
			pending.event:Fire()
			return
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local user_id = player.UserId
	if pending_after_choice[user_id] then
		pending_after_choice[user_id].event:Destroy()
		pending_after_choice[user_id] = nil
	end
end)

function scene_manager.play(player, scene_data, sequence_id)
	if typeof(scene_data) ~= "table" then
		warn("[scene_manager] scene_data harus table")
		return false
	end

	if typeof(scene_data.sequences) ~= "table" then
		warn("[scene_manager] scene_data.sequences tidak ditemukan")
		warn("[scene_manager] cek ModuleScript scene, harus punya: chapter.sequences = {...}")
		return false
	end

	sequence_id = sequence_id or "chapter_start"

	local sequence = scene_data.sequences[sequence_id]

	if typeof(sequence) ~= "table" then
		warn("[scene_manager] sequence tidak ditemukan:", sequence_id)
		return false
	end

	print("[scene_manager] play sequence:", sequence_id)

	local choice_result = nil

	for step_index, step in ipairs(sequence) do
		-- Jika step adalah after_choice_dialog, attach choice_result ke step
		if step.action == "after_choice_dialog" then
			step.choice_result = choice_result
		end

		local step_result = run_step(player, step)

		-- Cek apakah ada error yang menyebabkan kita harus stop
		if step_result and step_result.stop then
			break
		end

		-- Jika step adalah dialog, simpan choice_result dan dialog_data untuk digunakan di after_choice_dialog
		if step.action == "dialog" and step_result then
			if step_result.choice_id then
				choice_result = {
					choice_id = step_result.choice_id,
					is_correct = step_result.is_correct,
					dialog_data = step_result.dialog_data,
				}

				print("[scene_manager] choice_result disimpan:", choice_result.choice_id)
			end
		end

		task.wait(0.3)
	end

	return true
end

return scene_manager