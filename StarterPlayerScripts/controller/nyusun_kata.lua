local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local sound_service = require(
	ReplicatedStorage
		:WaitForChild("service")
		:WaitForChild("sound")
)

local NotificationService = require(
	ReplicatedStorage
		:WaitForChild("service")
		:WaitForChild("notification")
)

local player_gui = player:WaitForChild("PlayerGui")
local visual_gui = player_gui:WaitForChild("visual", 30)

if not visual_gui then
	warn("[nyusun_kata_controller] ScreenGui visual tidak ditemukan")
	return
end

local notification_main = visual_gui:WaitForChild("nyusun_kata"):WaitForChild("notification")

local nyusun_kata_frame = visual_gui:WaitForChild("nyusun_kata")

-- Answer Frame
local answer = nyusun_kata_frame:WaitForChild("answer")
local scrolling_frm = answer:WaitForChild("scrolling_frm")
local answer_btn_template = scrolling_frm:WaitForChild("answer")

-- Character Frame
local character = nyusun_kata_frame:WaitForChild("character")
local character_img = character:WaitForChild("character_img")
local name_lbl = character:WaitForChild("name_lbl")
local question_img = character:WaitForChild("question_img")
local question_lbl = question_img:WaitForChild("question_lbl")


-- Question Frame (Final Answer)
local question = nyusun_kata_frame:WaitForChild("question")
local final = question:WaitForChild("final")

local current_quiz = nil
local current_index = 1
local is_playing = false
local answered_sequence = {} -- Track jawaban yang sudah dijawab dalam urutan
local finished = false

local function show_notification(message, notification_type)
	if NotificationService and typeof(NotificationService.Show) == "function" then
		NotificationService.Show(notification_main, message, notification_type or "warning")
	else
		warn("[notification]", message)
	end
end

local function set_button_text(button, text)
	if button:IsA("TextButton") then
		button.Text = text
		return
	end

	local label = button:FindFirstChildWhichIsA("TextLabel", true)

	if label then
		label.Text = text
	end
end

local function set_image(image_object, image_id)
	if not image_object then
		return
	end

	if image_id and image_id ~= "" then
		image_object.Image = image_id
		image_object.Visible = true
	else
		image_object.Visible = false
	end
end

local function clear_answer_buttons()
	for _, child in ipairs(scrolling_frm:GetChildren()) do
		if child:GetAttribute("is_word_button") then
			child:Destroy()
		end
	end
end

local function hide_all_final_slots()
	for i = 1, 6 do
		local slot = final:FindFirstChild(tostring(i))
		if slot then
			slot.Visible = false
		end
	end
end

local function show_final_slot(index, word)
	local slot = final:FindFirstChild(tostring(index))
	if slot then
		slot.Text = word
		slot.Visible = true
		print("[nyusun_kata_controller] tampil final slot:", index, word)
	end
end

-- Definisikan finish_quiz di sini, SEBELUM finish_quiz dipanggil
local function finish_quiz(success)
	if not current_quiz then
		return
	end

	nyusun_kata_frame.Visible = false
	visual_gui.Enabled = false

	game_event:FireServer("quiz_finished", {
		quiz_id = current_quiz.quiz_id,
		success = success,
	})
end

local function check_sequence_valid(word)
	-- Cek apakah kata yang dipilih adalah kata berikutnya dalam urutan yang benar
	local expected_index = #answered_sequence + 1
	local expected_word = current_quiz.correct_answer[expected_index]

	if word ~= expected_word then
		show_notification("Dimulai dari: \"" .. expected_word .. "\"!", "warning")
		return false
	end

	return true
end

local function on_word_clicked(word, button)
	if not is_playing or finished then
		return
	end

	sound_service.Play("click")

	-- Validasi urutan
	if not check_sequence_valid(word) then
		return
	end

	-- Tambah ke answered_sequence
	table.insert(answered_sequence, word)

	-- Tampilkan di final slot
	show_final_slot(#answered_sequence, word)

	-- Destroy button yang sudah diklik
	button:Destroy()

	-- Cek apakah sudah selesai
	if #answered_sequence >= #current_quiz.correct_answer then
		finished = true
		show_notification("Kalimat benar! Selesai!", "success")
		print("[nyusun_kata_controller] quiz selesai dengan benar")

		task.wait(1.5)
		finish_quiz(true)
	else
		show_notification("Benar! Lanjut ke kata berikutnya.", "success")
	end
end

local function render_word_bank(word_bank)
	clear_answer_buttons()

	local shuffled_words = {}
	for _, word in ipairs(word_bank) do
		table.insert(shuffled_words, word)
	end

	-- Shuffle words
	for i = #shuffled_words, 2, -1 do
		local j = math.random(1, i)
		shuffled_words[i], shuffled_words[j] = shuffled_words[j], shuffled_words[i]
	end

	-- Create buttons untuk setiap kata
	for _, word in ipairs(shuffled_words) do
		local button = answer_btn_template:Clone()
		button.Name = word
		button.Text = word
		button.Visible = true
		button:SetAttribute("is_word_button", true)
		button:SetAttribute("word", word)

		button.Activated:Connect(function()
			on_word_clicked(word, button)
		end)

		button.Parent = scrolling_frm
	end

	print("[nyusun_kata_controller] word bank dirender")
end

local function start_nyusun_kata(quiz_data)
	current_quiz = quiz_data
	current_index = 1
	is_playing = true
	answered_sequence = {}
	finished = false

	visual_gui.Enabled = true
	nyusun_kata_frame.Visible = true

	hide_all_final_slots()

	-- Set character image (jika ada)
	if quiz_data.character_img then
		set_image(character_img, quiz_data.character_img)
	end

	if quiz_data.character_name then
		name_lbl.Text = quiz_data.character_name
	end

	-- Set question label
	if quiz_data.question_hint then
		question_lbl.Text = quiz_data.question_hint
	end

	-- Render word bank
	render_word_bank(quiz_data.word_bank)

	print("[nyusun_kata_controller] quiz dimulai:", quiz_data.quiz_id)
end

visual_gui.Enabled = false
answer_btn_template.Visible = false

game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name ~= "quiz_play" then
		return
	end

	if payload.type == "nyusun_kata" then
		start_nyusun_kata(payload)
	end
end)