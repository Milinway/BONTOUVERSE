-- ServerScriptService > manager > quiz_manager(ModuleScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local quiz_folder = ReplicatedStorage
	:WaitForChild("module")
	:WaitForChild("data")
	:WaitForChild("quiz")

local quiz_manager = {}

local cache = {}
local pending = {}

local function load_module(module_script)
	if cache[module_script] then
		return cache[module_script]
	end

	local success, result = pcall(function()
		return require(module_script)
	end)

	if not success then
		warn("[quiz_manager] gagal require:", module_script:GetFullName(), result)
		return nil
	end

	cache[module_script] = result
	return result
end

local function find_quiz(quiz_id)
	for _, module_script in ipairs(quiz_folder:GetChildren()) do
		if module_script:IsA("ModuleScript") then
			local data = load_module(module_script)

			if data and data[quiz_id] then
				return data[quiz_id]
			end
		end
	end

	return nil
end

function quiz_manager.start(player, quiz_id)
	local data = find_quiz(quiz_id)

	if not data then
		warn("[quiz_manager] quiz tidak ditemukan:", quiz_id)

		return {
			success = false,
			message = "quiz tidak ditemukan",
		}
	end

	local user_id = player.UserId

	if pending[user_id] then
		return {
			success = false,
			message = "player masih menjalankan quiz",
		}
	end

	local finished_event = Instance.new("BindableEvent")

	pending[user_id] = {
		quiz_id = quiz_id,
		event = finished_event,
	}

	game_event:FireClient(player, "quiz_play", data)

	local result = finished_event.Event:Wait()

	pending[user_id] = nil
	finished_event:Destroy()

	return result
end

-- Fungsi untuk handle answer dari client
function quiz_manager.check_answer(player, quiz_id, question_index, selected_option)
	local user_id = player.UserId
	local current = pending[user_id]

	if not current then
		return {
			success = false,
			message = "quiz session tidak ditemukan",
		}
	end

	local data = find_quiz(quiz_id)
	if not data then
		return {
			success = false,
			message = "quiz tidak ditemukan",
		}
	end

	-- Validasi question index
	if not data.Quiz or not data.Quiz[question_index] then
		return {
			success = false,
			message = "pertanyaan tidak ditemukan",
		}
	end

	local question_data = data.Quiz[question_index]
	local is_correct = selected_option == question_data.CorrectOption

	return {
		success = true,
		is_correct = is_correct,
		correct_option = question_data.CorrectOption,
	}
end

game_event.OnServerEvent:Connect(function(player, event_name, payload)
	if event_name ~= "quiz_finished" then
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

	if payload.quiz_id ~= current.quiz_id then
		warn("[quiz_manager] quiz_id tidak cocok")
		return
	end

	if current.event and not current.finished then
		current.finished = true
		current.event:Fire({
			success = payload.success == true,
			score = payload.score,
			total_questions = payload.total_questions,
			quiz_id = current.quiz_id,
		})
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local user_id = player.UserId
	local current = pending[user_id]

	if current then
		if current.event and not current.finished then
			current.finished = true
			current.event:Fire({
				success = false,
				cancelled = true,
			})
		end

		pending[user_id] = nil
	end
end)

return quiz_manager