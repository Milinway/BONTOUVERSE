-- StarterPlayerScripts > controller(Folder) > homepage(LocalScript)
-- require (chapter_card(ModuleScript), catalog(ModuleScript), chapter_manager(ModuleScript), homepage(LocalScript), main_server(Scriot))
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")
local game_function = event_remote:WaitForChild("game_function")

local sound_service = require(
	ReplicatedStorage
		:WaitForChild("service")
		:WaitForChild("sound")
)

local chapter_card = require(
	ReplicatedStorage
		:WaitForChild("handler")
		:WaitForChild("gui")
		:WaitForChild("homepage")
		:WaitForChild("chapter_card")
)

local player_gui = player:WaitForChild("PlayerGui")
local homepage_gui = player_gui:WaitForChild("homepage", 30)

if not homepage_gui then
	warn("[homepage] homepage tidak ditemukan di PlayerGui")
	return
end

local main = homepage_gui:WaitForChild("main")
local play_frame = main:WaitForChild("play")

local card_list = play_frame:WaitForChild("card")
local card_template = card_list:WaitForChild("card_template")

local menu = play_frame:WaitForChild("menu")

local menu_image = menu:WaitForChild("img")
local menu_title = menu:WaitForChild("title")
local menu_status = menu:WaitForChild("status")
local start_button = menu:WaitForChild("start")

local selected_chapter = nil
local is_starting = false

card_template.Visible = false

local function set_menu_data(chapter_data)
	selected_chapter = chapter_data

	menu_title.Text = chapter_data.title
	menu_status.Text = "Status: " .. chapter_data.status

	if chapter_data.image and chapter_data.image ~= "" then
		menu_image.Image = chapter_data.image
	end

	if chapter_data.is_unlocked then
		start_button.Text = "Mulai"
		start_button.Active = true
		start_button.AutoButtonColor = true
	else
		start_button.Text = "Terkunci"
		start_button.Active = false
		start_button.AutoButtonColor = false
	end
end

local function clear_generated_cards()
	for _, child in ipairs(card_list:GetChildren()) do
		if child:GetAttribute("generated_chapter_card") then
			child:Destroy()
		end
	end
end

local function load_chapter_list()
	local success, response = pcall(function()
		return game_function:InvokeServer("get_homepage_chapter_list")
	end)

	if not success then
		warn("[homepage] gagal meminta data chapter:", response)
		return
	end

	if not response or response.success ~= true then
		warn("[homepage] server gagal memberi data chapter")
		return
	end

	clear_generated_cards()

	for _, chapter_data in ipairs(response.chapters) do
		chapter_card.create({
			parent = card_list,
			template = card_template,
			data = chapter_data,
			sound_service = sound_service,

			on_selected = function(selected_data)
				set_menu_data(selected_data)
			end,
		})
	end

	if response.chapters[1] then
		set_menu_data(response.chapters[1])
	end
end

start_button.MouseEnter:Connect(function()
	if selected_chapter and selected_chapter.is_unlocked then
		sound_service.Play("preview")
	end
end)

start_button.Activated:Connect(function()
	if is_starting then
		return
	end

	if not selected_chapter then
		warn("[homepage] belum ada chapter yang dipilih")
		return
	end

	if not selected_chapter.is_unlocked then
		warn("[homepage] chapter masih terkunci:", selected_chapter.chapter_id)
		return
	end

	is_starting = true

	sound_service.Play("click")

	start_button.Text = "Memulai..."
	start_button.Active = false
	start_button.AutoButtonColor = false

	game_event:FireServer(
		"start_chapter",
		selected_chapter.chapter_id
	)
end)

game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name == "chapter_start_accepted" then
		print("[homepage] chapter diterima server:", payload.chapter_id)

		is_starting = false
		start_button.Text = "Mulai"
		start_button.Active = true
		start_button.AutoButtonColor = true

		-- Sementara dimatikan dulu supaya terasa mulai chapter.
		-- Nanti bagian ini akan diganti fade_manager + story_manager.
		homepage_gui.Enabled = false

	elseif event_name == "chapter_start_rejected" then
		warn("[homepage] chapter ditolak:", payload.message)

		is_starting = false
		start_button.Text = "Mulai"
		start_button.Active = true
		start_button.AutoButtonColor = true
	end
end)

load_chapter_list()