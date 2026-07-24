-- StarterPlayerScripts > controller(Folder) > quiz(LocalScript)
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
local current_questions = {}
local current_quiz_id = nil
local score = 0
local answering = false
local visual_gui = nil
local randomized_options = {} -- Simpan urutan opsi yang sudah di-randomize

-- Helpers
local function get_visual_gui()
	return player_gui:FindFirstChild("visual")
end

local function get_refleksi_frame()
	visual_gui = get_visual_gui()
	if not visual_gui then return nil end

	local refleksi = visual_gui:FindFirstChild("refleksi")
	if not refleksi then return nil end

	return refleksi
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

local function randomize_options(options)
	-- Create indexed table dari options
	local indexed_options = {}
	for i, option in ipairs(options) do
		table.insert(indexed_options, {text = option, original_index = i})
	end

	-- Fisher-Yates shuffle
	for i = #indexed_options, 2, -1 do
		local j = math.random(1, i)
		indexed_options[i], indexed_options[j] = indexed_options[j], indexed_options[i]
	end

	return indexed_options
end

-- Main Functions
function quiz_manager:start(quiz_data, quiz_id)
	-- Support kedua format: Quiz array (lama) dan questions array (baru)
	if quiz_data.questions then
		current_questions = quiz_data.questions
	elseif quiz_data.Quiz then
		current_questions = quiz_data.Quiz
	else
		warn("[quiz] Tidak ada pertanyaan di quiz_data!")
		return
	end

	current_quiz_id = quiz_id or "unknown"
	current_question_index = 1
	score = 0
	answering = false
	randomized_options = {}

	if #current_questions == 0 then
		warn("[quiz] Tidak ada pertanyaan di quiz_data!")
		return
	end

	visual_gui = get_visual_gui()
	if not visual_gui then
		warn("[quiz] visual GUI tidak ditemukan di PlayerGui")
		return
	end

	local refleksi = get_refleksi_frame()
	if not refleksi then
		warn("[quiz] refleksi frame tidak ditemukan")
		return
	end

	visual_gui.Enabled = true
	refleksi.Visible = true

	-- Delay untuk memastikan UI siap
	task.wait(0.2)

	-- Bind buttons setelah UI siap
	self:bind_buttons()

	fade_ui("in", function()
		task.wait(0.2)
		self:display_question(true)
	end)
end

function quiz_manager:display_question(is_first)
	if not current_questions or current_question_index > #current_questions then
		self:finish()
		return
	end

	visual_gui = get_visual_gui()
	if not visual_gui then return end

	local refleksi = visual_gui:FindFirstChild("refleksi")
	if not refleksi then return end

	local main_frame = refleksi:FindFirstChild("main")
	if not main_frame then return end

	local quiz_frame = main_frame:FindFirstChild("quizFrame")
	local image_frame = main_frame:FindFirstChild("imageFrame")

	if not quiz_frame or not image_frame then return end

	answering = false

	-- Tampilkan tombol opsi
	quiz_frame.A.Visible = true
	quiz_frame.B.Visible = true

	-- Ambil data pertanyaan saat ini
	local question = current_questions[current_question_index] or {}

	-- Set text pertanyaan
	quiz_frame.quizText.Text = question.Question or "Tidak ada pertanyaan"
	quiz_frame.quizHint.Text = question.Hint or ""
	image_frame.image.Image = question.image or ""

	-- Randomize options - cek apakah Options array atau object A/B
	local options_to_randomize = {}
	if question.Options and type(question.Options) == "table" then
		-- Format baru: array of strings
		if question.Options[1] then
			options_to_randomize = question.Options
		else
			-- Format lama: {A = "...", B = "..."}
			options_to_randomize = {question.Options.A or "", question.Options.B or ""}
		end
	end

	local shuffled_options = randomize_options(options_to_randomize)
	randomized_options[current_question_index] = shuffled_options

	-- Set tombol dengan opsi yang sudah di-randomize
	quiz_frame.A.Text = shuffled_options[1].text
	quiz_frame.B.Text = shuffled_options[2].text

	-- Reset visual feedback
	quiz_frame.quizText.TextColor3 = Color3.fromRGB(255, 255, 255) -- Warna normal
end

function quiz_manager:select_answer(button_index)
	if answering then return end
	answering = true

	visual_gui = get_visual_gui()
	if not visual_gui then return end

	local refleksi = visual_gui:FindFirstChild("refleksi")
	if not refleksi then return end

	local main_frame = refleksi:FindFirstChild("main")
	if not main_frame then return end

	local quiz_frame = main_frame:FindFirstChild("quizFrame")
	if not quiz_frame then return end

	local quiz_text = quiz_frame.quizText
	local question = current_questions[current_question_index] or {}

	-- Ambil opsi yang sudah di-randomize
	local shuffled = randomized_options[current_question_index]
	if not shuffled then
		warn("[quiz] randomized options tidak ditemukan untuk pertanyaan " .. current_question_index)
		answering = false
		return
	end

	local selected_original_index = shuffled[button_index].original_index
	local correct_original_index = question.CorrectOption

	local is_correct = selected_original_index == correct_original_index

	if is_correct then
		score += 1
		quiz_text.Text = "✅"
		quiz_text.TextColor3 = Color3.fromRGB(0, 255, 0) -- Hijau
		local sfx = quiz_frame:FindFirstChild("Right")
		if sfx then sfx:Play() end
	else
		quiz_text.Text = "❌"
		quiz_text.TextColor3 = Color3.fromRGB(255, 0, 0) -- Merah
		local sfx = quiz_frame:FindFirstChild("Wrong")
		if sfx then sfx:Play() end
	end

	task.wait(0.8)

	-- Slide current frame ke bawah (fade out)
	local tween_info_down = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween_down = TweenService:Create(main_frame, tween_info_down, {Position = UDim2.new(0, 0, 1.5, 0)})
	tween_down:Play()
	tween_down.Completed:Wait()

	current_question_index += 1

	-- Slide new frame dari atas (fade in)
	if current_question_index <= #current_questions then
		main_frame.Position = UDim2.new(0, 0, -1, 0)
		self:display_question()
		
		local tween_info_up = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween_up = TweenService:Create(main_frame, tween_info_up, {Position = UDim2.new(0, 0, 0.5, 0)})
		tween_up:Play()
		tween_up.Completed:Wait()
	else
		self:finish()
	end
end

function quiz_manager:finish()
	visual_gui = get_visual_gui()
	if not visual_gui then return end

	local refleksi = visual_gui:FindFirstChild("refleksi")
	if not refleksi then return end

	local main_frame = refleksi:FindFirstChild("main")
	if not main_frame then return end

	local quiz_frame = main_frame:FindFirstChild("quizFrame")
	if not quiz_frame then return end

	local quiz_text = quiz_frame.quizText
	local total_questions = #current_questions

	-- Sembunyikan tombol
	quiz_frame.A.Visible = false
	quiz_frame.B.Visible = false

	-- Tampilkan skor
	quiz_text.Text = string.format("Skor %d/%d", score, total_questions)
	quiz_text.TextColor3 = Color3.fromRGB(255, 255, 255)
	task.wait(2.5)

	-- Cek apakah semua jawaban benar
	if score == total_questions then
		-- Quiz berhasil
		fade_ui("out", function()
			task.wait(0.2)
			visual_gui.Enabled = false
			refleksi.Visible = false
			game_event:FireServer("quiz_finished", {
				quiz_id = current_quiz_id,
				success = true,
				score = score,
				total_questions = total_questions,
			})
		end)
	else
		-- Quiz gagal, ulangi dari awal dengan pertanyaan acak
		print(string.format("[quiz] Player gagal: %d/%d. Mengulang quiz...", score, total_questions))
		task.wait(1)
		current_question_index = 1
		score = 0
		answering = false
		randomized_options = {}
		main_frame.Position = UDim2.new(0, 0, 0.5, 0)
		self:display_question(false)
	end
end

function quiz_manager:bind_buttons()
	visual_gui = get_visual_gui()
	if not visual_gui then return end

	local refleksi = visual_gui:FindFirstChild("refleksi")
	if not refleksi then return end

	local main_frame = refleksi:FindFirstChild("main")
	if not main_frame then return end

	local quiz_frame = main_frame:FindFirstChild("quizFrame")
	if not quiz_frame then return end

	local btn_a = quiz_frame:FindFirstChild("A")
	local btn_b = quiz_frame:FindFirstChild("B")

	-- Disconnect jika sudah ada connection
	if btn_a then
		-- Hapus connection lama
		btn_a.MouseButton1Click:Connect(function()
			self:select_answer(1)
		end)
	end

	if btn_b then
		btn_b.MouseButton1Click:Connect(function()
			self:select_answer(2)
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

return quiz_manager
