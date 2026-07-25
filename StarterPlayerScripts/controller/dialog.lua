-- StarterPlayerScripts > controller(Folder) > dialog(LocalScript)
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

local player_gui = player:WaitForChild("PlayerGui")
local dialog_gui = player_gui:WaitForChild("dialog", 30)

if not dialog_gui then
	warn("[dialog_controller] ScreenGui dialog tidak ditemukan")
	return
end

local main = dialog_gui:WaitForChild("main")
local dialoge_frame = main:WaitForChild("dialoge")
local opsi_frame = main:WaitForChild("opsi")

local character_img = dialoge_frame:WaitForChild("character_img")
local dialoge_lbl = dialoge_frame:WaitForChild("dialoge_lbl")
local name_lbl = dialoge_frame:WaitForChild("name_lbl")

local background_img = main:WaitForChild("baground_img")

local next_btn = opsi_frame:WaitForChild("next_btn")
local help_btn = opsi_frame:WaitForChild("help_btn")
local right_btn = opsi_frame:WaitForChild("right_btn")
local wrong_btn = opsi_frame:WaitForChild("wrong_btn")

local typing_speed = 0.025
local typing_sound_interval = 2
local current_voice = nil

local active_dialog = nil
local current_index = 1
local is_playing = false

local is_typing = false
local skip_typing = false
local typing_token = 0

local selected_choice_id = nil

local skip_cooldown = 5
local max_skip_spam = 5
local skip_spam_count = 0
local skip_locked = false
local skip_unlock_token = 0

-- Jarak waktu maksimum antar skip supaya masih dihitung "beruntun".
-- Kalau lewat skip_streak_timeout detik tanpa ada skip baru,
-- skip_spam_count otomatis balik ke 0.
local skip_streak_timeout = 3
local skip_streak_token = 0

local IMAGE_SKIP = "rbxassetid://118183992128466"
local IMAGE_NEXT = "rbxassetid://133433507076361"

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

-- Forward declaration. hide_choices() di bawah ini butuh
-- update_next_button_state() padahal isinya baru diisi lebih jauh ke
-- bawah. Dengan local di sini, assignment "update_next_button_state =
-- function() ... end" nanti mengisi local ini, bukan bikin global baru.
local update_next_button_state

local function hide_choices()
	help_btn.Visible = false
	right_btn.Visible = false
	wrong_btn.Visible = false

	update_next_button_state()
end

local function show_choices(choices)
	next_btn.Visible = false
	help_btn.Visible = false

	right_btn.Visible = false
	wrong_btn.Visible = false

	if choices[1] then
		right_btn.Visible = true
		right_btn.Active = true
		right_btn:SetAttribute("choice_id", choices[1].choice_id)
		right_btn:SetAttribute("is_correct", choices[1].is_correct == true)
		set_button_text(right_btn, choices[1].text)
	end

	if choices[2] then
		wrong_btn.Visible = true
		wrong_btn.Active = true
		wrong_btn:SetAttribute("choice_id", choices[2].choice_id)
		wrong_btn:SetAttribute("is_correct", choices[2].is_correct == true)
		set_button_text(wrong_btn, choices[2].text)
	end

	print("[dialog_controller] choices muncul")
end

local function count_graphemes(text)
	local count = 0

	for _ in utf8.graphemes(text) do
		count += 1
	end

	return count
end

local function get_current_line()
	if not active_dialog then
		return nil
	end

	local lines = active_dialog.lines or {}
	return lines[current_index]
end

local function is_current_line_last()
	if not active_dialog then
		return false
	end

	local lines = active_dialog.lines or {}

	return current_index >= #lines
end

update_next_button_state = function()
	if is_typing then
		next_btn.Image = IMAGE_SKIP
	else
		next_btn.Image = IMAGE_NEXT
	end

	if skip_locked and is_typing then
		next_btn.Visible = false
	else
		next_btn.Visible = true
	end
end

local function lock_skip()
	if skip_locked then
		return
	end

	skip_locked = true
	skip_unlock_token += 1

	local token = skip_unlock_token

	next_btn.Visible = false

	task.delay(skip_cooldown,function()

		if token ~= skip_unlock_token then
			return
		end

		skip_locked = false
		skip_spam_count = 0

		if is_playing and is_typing then
			next_btn.Visible = true
			update_next_button_state()
		end

	end)
end

local function finish_dialog(choice_id, is_correct)
	if not active_dialog then
		return
	end

	typing_token += 1
	is_typing = false
	skip_typing = false
	dialoge_lbl.MaxVisibleGraphemes = -1

	local dialog_id = active_dialog.dialog_id

	dialog_gui.Enabled = false
	main.Visible = false

	game_event:FireServer("dialog_finished", {
		dialog_id = dialog_id,
		choice_id = choice_id,
		is_correct = is_correct,
	})

	active_dialog = nil
	is_playing = false
	current_index = 1
	selected_choice_id = nil

	-- Reset status skip di sini supaya SEMUA jalur yang berakhir lewat
	-- finish_dialog() (line habis, next di line terakhir, atau jawab
	-- pilihan) otomatis ikut ke-reset tanpa perlu diulang di tiap tempat.
	skip_spam_count = 0
	skip_locked = false
	skip_unlock_token += 1
	skip_streak_token += 1
end

local function stop_current_voice()
	if current_voice then
		sound_service.Stop(current_voice)
		current_voice = nil
	end
end

local function play_typing_text(text, voice_id, voice_volume)
	typing_token += 1

	local current_token = typing_token

	is_typing = true
	skip_typing = false

	update_next_button_state()
	stop_current_voice()

	local has_voice = voice_id ~= nil and voice_id ~= ""

	if has_voice then
		current_voice = sound_service.PlayId(voice_id, voice_volume or 1)
	end

	dialoge_lbl.Text = text or ""
	dialoge_lbl.TextWrapped = true
	dialoge_lbl.MaxVisibleGraphemes = 0

	local total_graphemes = count_graphemes(dialoge_lbl.Text)

	for index = 1, total_graphemes do
		if current_token ~= typing_token then
			return
		end

		if skip_typing then
			break
		end

		dialoge_lbl.MaxVisibleGraphemes = index

		if not has_voice and index % typing_sound_interval == 0 then
			sound_service.Play("typing")
		end

		task.wait(typing_speed)
	end

	if current_token ~= typing_token then
		return
	end

	dialoge_lbl.MaxVisibleGraphemes = -1

	is_typing = false
	skip_typing = false

	update_next_button_state()

	-- Cek apakah line saat ini punya choices
	local current_line = get_current_line()
	if current_line and current_line.choices then
		print("[dialog_controller] current_line punya choices, tampil")
		show_choices(current_line.choices)
	end
end

local function render_line()
	if not active_dialog then
		return
	end

	local lines = active_dialog.lines or {}
	local line = lines[current_index]

	if not line then
		-- finish_dialog() sudah menghandle reset skip_spam_count,
		-- skip_locked, dkk, jadi tidak perlu diulang di sini.
		finish_dialog()
		stop_current_voice()
		return
	end

	hide_choices()

	name_lbl.Text = line.speaker or ""

	set_image(character_img, line.character_img)

	if active_dialog.background_img and active_dialog.background_img ~= "" then
		background_img.Image = active_dialog.background_img
		background_img.Visible = true
	else
		background_img.Visible = false
	end

	task.spawn(function()
		play_typing_text(
			line.text or "",
			line.voice_id,
			line.voice_volume
		)
	end)
end

local function start_dialog(dialog_data)
	active_dialog = dialog_data
	current_index = 1
	is_playing = true
	selected_choice_id = nil

	-- Reset status skip supaya lock/cooldown dari dialog sebelumnya
	-- tidak ikut terbawa ke dialog baru ini.
	skip_spam_count = 0
	skip_locked = false
	skip_unlock_token += 1
	skip_streak_token += 1

	dialog_gui.Enabled = true
	main.Visible = true
	dialoge_frame.Visible = true
	opsi_frame.Visible = true

	hide_choices()
	render_line()
end

next_btn.MouseEnter:Connect(function()
	if next_btn.Visible then
		sound_service.Play("preview")
	end
end)

next_btn.Activated:Connect(function()
	if not is_playing then
		return
	end

	if not active_dialog then
		return
	end

	sound_service.Play("click")

	if is_typing then
		if skip_locked then
			return
		end

		skip_spam_count += 1

		-- Hitung mundur "beruntun": kalau tidak ada skip baru dalam
		-- skip_streak_timeout detik, skip_spam_count balik ke 0.
		-- Jadi yang kena lock cuma skip yang beneran spam beruntun,
		-- bukan pola skip-next-skip-next yang jaraknya renggang.
		skip_streak_token += 1
		local streak_token = skip_streak_token

		task.delay(skip_streak_timeout, function()
			if streak_token ~= skip_streak_token then
				return
			end

			skip_spam_count = 0
		end)

		if skip_spam_count >= max_skip_spam then
			lock_skip()
		end

		skip_typing = true

		stop_current_voice()

		dialoge_lbl.MaxVisibleGraphemes = -1

		update_next_button_state()

		return
	end

	local lines = active_dialog.lines or {}
	local is_last_line = current_index >= #lines

	if is_last_line then
		-- finish_dialog() sudah reset skip_spam_count, skip_locked, dkk.
		finish_dialog()
		stop_current_voice()
		return
	end

	current_index += 1
	render_line()
end)

right_btn.MouseEnter:Connect(function()
	if right_btn.Visible then
		sound_service.Play("preview")
	end
end)

wrong_btn.MouseEnter:Connect(function()
	if wrong_btn.Visible then
		sound_service.Play("preview")
	end
end)

local function choose_answer(button)
	if not is_playing then
		return
	end

	if not active_dialog then
		return
	end

	if not button.Visible then
		return
	end

	sound_service.Play("click")

	local choice_id = button:GetAttribute("choice_id")
	local is_correct = button:GetAttribute("is_correct")

	print("[dialog_controller] choice dipilih:", choice_id, is_correct)

	-- Simpan choice_id untuk referensi
	selected_choice_id = choice_id

	-- Get current line yang punya choices
	local current_line = get_current_line()
	if not current_line or not current_line.choices then
		finish_dialog(choice_id, is_correct)
		return
	end

	-- Cari choice yang dipilih
	local selected_choice = nil
	for _, choice in ipairs(current_line.choices) do
		if choice.choice_id == choice_id then
			selected_choice = choice
			break
		end
	end

	if not selected_choice or not selected_choice.choice_response then
		finish_dialog(choice_id, is_correct)
		return
	end

	-- Append choice_response ke active_dialog.lines
	print("[dialog_controller] menambahkan choice_response ke lines")
	for _, response_line in ipairs(selected_choice.choice_response) do
		table.insert(active_dialog.lines, response_line)
	end

	hide_choices()
	current_index += 1
	render_line()
end

right_btn.Activated:Connect(function()
	choose_answer(right_btn)
end)

wrong_btn.Activated:Connect(function()
	choose_answer(wrong_btn)
end)

dialog_gui.Enabled = false
main.Visible = false
dialoge_lbl.MaxVisibleGraphemes = -1

game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name ~= "dialog_play" then
		return
	end

	start_dialog(payload)
end)