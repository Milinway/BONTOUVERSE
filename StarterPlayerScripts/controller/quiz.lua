-- StarterPlayer > StarterCharacterScripts > controller(Folder) > quiz(LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local player = Players.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")

local quiz_manager = {}

-- State
local current_question_index = 1
local current_data = {}
local current_quiz_id = nil
local score = 0
local answering = false
local quiz_gui = nil

-- Helpers
local function get_quiz_gui()
	return player_gui:FindFirstChild("visual")
end

local function get_notification_frame()
	local notification = player_gui:FindFirstChild("notification")
	if notification then
		return notification:FindFirstChild("fade")
	end
	return nil
end

local function fade_ui(mode, callback, duration)
	duration = duration or 0.5

	local ui_fade = player_gui:FindFirstChild("notification")
	if not ui_fade then 
		if callback then callback() end
		return 
	end

	local fade_frame = ui_fade:FindFirstChild("fade")
	if not fade_frame then 
		if callback then callback() end
		return 
	end

	ui_fade.Enabled = true
	fade_frame.Visible = true

	local tween_info = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tween

	if mode == "in" then
		fade_frame.BackgroundTransparency = 0
		tween = TweenService:Create(fade_frame, tween_info, {BackgroundTransparency = 1})
	elseif mode == "out" then
		fade_frame.BackgroundTransparency = 1
		tween = TweenService:Create(fade_frame, tween_info, {BackgroundTransparency = 0})
	end

	if tween then
		tween:Play()
		tween.Completed:Wait()
		if mode == "in" then
			ui_fade.Enabled = false
			fade_frame.Visible = false
		end
	end

	if callback then callback() end
end

local function slide_frame(frame, end_pos, duration)
	if not frame then return end

	local tween_info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(frame, tween_info, {Position = end_pos})
	tween:Play()
	tween.Completed:Wait()
end

-- Main Functions
function quiz_manager:start(quiz_data, quiz_id)
	current_data = quiz_data.Quiz or {}
	current_quiz_id = quiz_id or "unknown"
	current_question_index = 1
	score = 0
	answering = false

	if #current_data == 0 then
		warn("[quiz] Tidak ada pertanyaan di quiz_data!")
		return
	end

	quiz_gui = get_quiz_gui()
	if not quiz_gui then
		warn("[quiz] ui_Quiz tidak ditemukan di PlayerGui")
		return
	end

	quiz_gui.Enabled = true

	-- Delay kecil untuk memastikan UI siap
	task.wait(0.1)

	fade_ui("in", function()
		task.wait(0.1) -- Delay tambahan sebelum display question
		self:display_question(true)
	end)
end

function quiz_manager:display_question(is_first)
	if not current_data or current_question_index > #current_data then
		self:finish()
		return
	end

	quiz_gui = get_quiz_gui()
	if not quiz_gui then return end

	local back_frame = quiz_gui:FindFirstChild("refleksi")
	local main_frame = back_frame and back_frame:FindFirstChild("main")
	local quiz_frame = main_frame and main_frame:FindFirstChild("quizFrame")
	local image_frame = main_frame and main_frame:FindFirstChild("imageFrame")

	if not quiz_frame or not image_frame then return end

	answering = false

	quiz_frame.A.Visible = true
	quiz_frame.B.Visible = true

	if not is_first then
		slide_frame(main_frame, UDim2.new(main_frame.Position.X.Scale, 0, 2.2, 0), 0.4)
	end

	local question = current_data[current_question_index] or {}
	quiz_frame.quizText.Text = question.Question or "Tidak ada pertanyaan"
	quiz_frame.quizHint.Text = question.Hint or ""
	image_frame.image.Image = question.image or ""

	quiz_frame.A.Text = (question.Options and question.Options.A) or "Opsi A kosong"
	quiz_frame.B.Text = (question.Options and question.Options.B) or "Opsi B kosong"

	if not is_first then
		slide_frame(main_frame, UDim2.new(main_frame.Position.X.Scale, 0, 0.5, 0), 0.4)
	end
end

function quiz_manager:select_answer(option)
	if answering then return end
	answering = true

	quiz_gui = get_quiz_gui()
	if not quiz_gui then return end

	local main_frame = quiz_gui.backFrame.mainFrame
	local quiz_frame = main_frame.quizFrame
	local quiz_text = quiz_frame.quizText

	local question = current_data[current_question_index] or {}
	local is_correct = option == question.CorrectOption

	if is_correct then
		score += 1
		quiz_text.Text = "✅"
		local sfx = quiz_frame:FindFirstChild("Right")
		if sfx then sfx:Play() end
	else
		quiz_text.Text = "❌"
		local sfx = quiz_frame:FindFirstChild("Wrong")
		if sfx then sfx:Play() end
	end

	task.wait(0.5)
	current_question_index += 1
	self:display_question()
end

function quiz_manager:finish()
	quiz_gui = get_quiz_gui()
	if not quiz_gui then return end

	local quiz_frame = quiz_gui.refleksi.main.quizFrame
	local quiz_text = quiz_frame.quizText
	local total_questions = #current_data

	quiz_frame.A.Visible = false
	quiz_frame.B.Visible = false

	quiz_text.Text = string.format("Skor %d/%d", score, total_questions)
	task.wait(2)

	if score == total_questions then
		fade_ui("out", function()
			task.wait(0.1)
			quiz_gui.Enabled = false
			game_event:FireServer("quiz_finished", {
				quiz_id = current_quiz_id,
				success = true,
				score = score,
				total_questions = total_questions,
			})
		end)
	else
		-- Ulangi quiz
		current_question_index = 1
		score = 0
		answering = false
		self:display_question(false)
	end
end

function quiz_manager:bind_buttons()
	quiz_gui = get_quiz_gui()
	if not quiz_gui then return end

	local quiz_frame = quiz_gui.refleksi.main.quizFrame
	if not quiz_frame then return end

	local btn_a = quiz_frame:FindFirstChild("A")
	local btn_b = quiz_frame:FindFirstChild("B")

	if btn_a then
		btn_a.MouseButton1Click:Connect(function()
			self:select_answer("A")
		end)
	end

	if btn_b then
		btn_b.MouseButton1Click:Connect(function()
			self:select_answer("B")
		end)
	end
end

-- Listen for quiz start event
game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name == "quiz_play" then
		local quiz_data = payload
		local quiz_id = quiz_data.quiz_id or "unknown"
		quiz_manager:start(quiz_data, quiz_id)
	end
end)

-- Setup
quiz_manager:bind_buttons()

return quiz_manager
