local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local scene_manager = {}

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

		-- Return hasil dialog (termasuk choice_id jika ada)
		if result and result.result then
			return {
				success = true,
				choice_id = result.result.choice_id,
				is_correct = result.result.is_correct,
			}
		end

		return { success = true }
	end

	if step.action == "after_choice_dialog" then
		print("[scene_manager] after_choice_dialog")

		-- Cek apakah ada choice_result dari step sebelumnya
		if not step.choice_result or not step.choice_result.choice_id then
			print("[scene_manager] tidak ada choice_result, skip after_choice_dialog")
			return { success = true }
		end

		local choice_id = step.choice_result.choice_id
		local dialog_data = step.dialog_data

		if not dialog_data or not dialog_data.after_choices then
			warn("[scene_manager] after_choices data tidak ditemukan")
			return { success = true }
		end

		local after_choice = dialog_data.after_choices[choice_id]

		if not after_choice then
			warn("[scene_manager] after_choice untuk " .. choice_id .. " tidak ditemukan")
			return { success = true }
		end

		-- Mainkan after-choice dialog
		local success, result = call_manager(
			dialog_manager,
			"play",
			player,
			after_choice.dialog_id
		)

		if not success then
			warn("[scene_manager] gagal memainkan after_choice_dialog")
			return { success = false, stop = true }
		end

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
	local last_dialog_step = nil

	for step_index, step in ipairs(sequence) do
		-- Jika step adalah after_choice_dialog, attach choice_result dan dialog_step ke step
		if step.action == "after_choice_dialog" then
			step.choice_result = choice_result
			step.dialog_data = last_dialog_step
		end

		local step_result = run_step(player, step)

		-- Cek apakah ada error yang menyebabkan kita harus stop
		if step_result and step_result.stop then
			break
		end

		-- Jika step adalah dialog, simpan choice_result untuk digunakan di after_choice_dialog
		if step.action == "dialog" and step_result and step_result.choice_id then
			choice_result = step_result
			last_dialog_step = step
		end

		task.wait(0.3)
	end

	return true
end

return scene_manager