-- StarterPlayerScripts > controller(Folder) > visual_packing_souvenir(LocalScript)
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
	warn("[visual_controller] ScreenGui visual tidak ditemukan")
	return
end

local notification_main = player_gui:WaitForChild("visual"):WaitForChild("packing_souvenir"):waitForChild("notification")

local packing_frame = visual_gui:WaitForChild("packing_souvenir")
local main = packing_frame:WaitForChild("main")

local answer = main:WaitForChild("answer")
local deskripsi_list = answer:WaitForChild("deskripsi")
local deskripsi_template = deskripsi_list:WaitForChild("deskripsi_card")

local final = answer:WaitForChild("final")
local submit_btn = final:WaitForChild("submit")
local final_img = final:WaitForChild("img")

local product_frame = main:WaitForChild("product")
local product_img = product_frame:WaitForChild("img")
local isi_produk = product_img:WaitForChild("isi_produk")

-- Ambil template stroke dari ReplicatedStorage
local template_stroke = ReplicatedStorage
	:WaitForChild("assets")
	:WaitForChild("template_stroke")

local selected_product = nil
local current_minigame = nil
local matched_count = 0
local final_index = 1
local finished = false

local product_by_id = {}
local description_by_id = {}
local used_descriptions = {} -- Track deskripsi yang sudah dipakai

local function show_notification(message, notification_type)
	if NotificationService and typeof(NotificationService.Show) == "function" then
		NotificationService.Show(notification_main, message, notification_type or "warning")
	else
		warn("[notification]", message)
	end
end

local function shuffle(list)
	local result = table.clone(list)

	for i = #result, 2, -1 do
		local j = math.random(1, i)
		result[i], result[j] = result[j], result[i]
	end

	return result
end

local function clear_generated_descriptions()
	for _, child in ipairs(deskripsi_list:GetChildren()) do
		if child:GetAttribute("generated_description") then
			child:Destroy()
		end
	end
end

local function remove_stroke_from_all_products()
	for i = 1, 12 do
		local slot = isi_produk:FindFirstChild(tostring(i))

		if slot then
			-- Hapus stroke jika ada
			local existing_stroke = slot:FindFirstChild("template_stroke")
			if existing_stroke then
				existing_stroke:Destroy()
			end
		end
	end
end

local function add_stroke_to_product(slot)
	-- Hapus stroke lama jika ada
		local existing_stroke = slot:FindFirstChild("template_stroke")
	if existing_stroke then
		existing_stroke:Destroy()
	end

	-- Clone dan attach template_stroke
	local new_stroke = template_stroke:Clone()
	new_stroke.Parent = slot

	print("[visual_controller] stroke ditambahkan ke:", slot.Name)
end

local function reset_final_slots()
	for i = 1, 3 do
		local slot = final_img:FindFirstChild(tostring(i))

		if slot and (slot:IsA("ImageLabel") or slot:IsA("ImageButton")) then
			slot.Image = ""
			slot.Visible = false
		end
	end
end

local function reset_product_slots()
	for i = 1, 12 do
		local slot = isi_produk:FindFirstChild(tostring(i))

		if slot and (slot:IsA("ImageLabel") or slot:IsA("ImageButton")) then
			slot.Image = ""
			slot.Visible = false
			slot:SetAttribute("product_id", nil)

			-- Hapus stroke
			local existing_stroke = slot:FindFirstChild("template_stroke")
			if existing_stroke then
				existing_stroke:Destroy()
			end
		end
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

local function set_submit_enabled(enabled)
	submit_btn.Active = enabled
	submit_btn.AutoButtonColor = enabled

	if enabled then
		set_button_text(submit_btn, "SUBMIT")
	else
		set_button_text(submit_btn, "ISI KOPER")
	end
end

local function put_product_to_final(product_data)
	local slot = final_img:FindFirstChild(tostring(final_index))

	if slot and (slot:IsA("ImageLabel") or slot:IsA("ImageButton")) then
		slot.Image = product_data.image
		slot.Visible = true
	end

	final_index += 1
end

local function select_product(slot)
	local product_id = slot:GetAttribute("product_id")

	if not product_id then
		return
	end

	local product_data = product_by_id[product_id]

	if not product_data then
		return
	end

	-- Hapus stroke dari product sebelumnya
	if selected_product and selected_product.slot then
		local old_stroke = selected_product.slot:FindFirstChild("template_stroke")
		if old_stroke then
			old_stroke:Destroy()
		end
	end

	-- Set product baru dengan stroke
	selected_product = {
		data = product_data,
		slot = slot,
	}

	add_stroke_to_product(slot)
	sound_service.Play("click")

	print("[visual_controller] produk dipilih:", product_id)
end

local function resolve_description(description_id, description_card)
	if finished then
		return
	end

	if not selected_product then
		show_notification("Pilih produk terlebih dahulu!", "warning")
		return
	end

	local product_data = selected_product.data
	local product_slot = selected_product.slot

	if not product_data.is_correct_product then
		show_notification("Produk yang anda pilih salah!", "error")
		selected_product = nil
	
		-- Hapus stroke
		local stroke = product_slot:FindFirstChild("template_stroke")
		if stroke then
			stroke:Destroy()
		end
		return
	end

	if product_data.description_id ~= description_id then
		show_notification("Deskripsi yang anda pilih salah!", "error")
		selected_product = nil
	
		-- Hapus stroke
		local stroke = product_slot:FindFirstChild("template_stroke")
		if stroke then
			stroke:Destroy()
		end
		return
	end

	-- Jawaban BENAR - Hide product dari isi_produk
	product_slot.Visible = false

	-- Hapus stroke
	local stroke = product_slot:FindFirstChild("template_stroke")
	if stroke then
		stroke:Destroy()
	end

	-- Masukkan ke final
	put_product_to_final(product_data)

	-- Hapus description card dari deskripsi_list
	description_card:Destroy()

	-- Mark sebagai used
	used_descriptions[description_id] = true

	matched_count += 1
	selected_product = nil

	show_notification("Produk berhasil dimasukkan ke koper!", "success")

	if matched_count >= current_minigame.required_correct then
		finished = true
		set_submit_enabled(true)
		show_notification("Telah mengisi koper, submit untuk melanjutkan!", "success")
	end
end

local function render_descriptions(descriptions)
	clear_generated_descriptions()
	used_descriptions = {}

	for _, description_data in ipairs(descriptions) do
		local card = deskripsi_template:Clone()

		card.Name = description_data.description_id
		card.Visible = true
		card:SetAttribute("generated_description", true)
		card:SetAttribute("description_id", description_data.description_id)

		local name_product = card:FindFirstChild("name_product", true)
		local deskripsi_product = card:FindFirstChild("deskripsi_product", true)

		if name_product then
			name_product.Text = description_data.name
		end

		if deskripsi_product then
			deskripsi_product.Text = description_data.text
		end

		if card:IsA("GuiButton") then
			card.MouseEnter:Connect(function()
				if not used_descriptions[description_data.description_id] then
					sound_service.Play("preview")
				end
			end)

			card.Activated:Connect(function()
				if used_descriptions[description_data.description_id] then
					show_notification("Deskripsi ini sudah dipakai!", "warning")
					return
				end

				sound_service.Play("click")
				resolve_description(description_data.description_id, card)
			end)
		else
			warn("[visual_controller] deskripsi_card sebaiknya TextButton/ImageButton agar bisa diklik")
		end

		card.Parent = deskripsi_list
	end
end

local function render_products(products)
	reset_product_slots()

	local shuffled_products = shuffle(products)

	for index, product_data in ipairs(shuffled_products) do
		local slot = isi_produk:FindFirstChild(tostring(index))

		if slot and (slot:IsA("ImageLabel") or slot:IsA("ImageButton")) then
			slot.Image = product_data.image
			slot.Visible = true
			slot:SetAttribute("product_id", product_data.product_id)

			if slot:IsA("GuiButton") then
				slot.MouseEnter:Connect(function()
					sound_service.Play("preview")
				end)

				slot.Activated:Connect(function()
					select_product(slot)
				end)
			else
				warn("[visual_controller] product slot harus ImageButton agar bisa diklik:", slot.Name)
			end
		end
	end
end

local function start_packing_souvenir(data)
	current_minigame = data
	selected_product = nil
	matched_count = 0
	final_index = 1
	finished = false
	used_descriptions = {}

	product_by_id = {}
	description_by_id = {}

	for _, product_data in ipairs(data.products) do
		product_by_id[product_data.product_id] = product_data
	end

	for _, description_data in ipairs(data.descriptions) do
		description_by_id[description_data.description_id] = description_data
	end

	visual_gui.Enabled = true
	packing_frame.Visible = true
	main.Visible = true

	deskripsi_template.Visible = false

	reset_final_slots()
	set_submit_enabled(false)

	render_descriptions(data.descriptions)
	render_products(data.products)
end

submit_btn.MouseEnter:Connect(function()
	if finished then
		sound_service.Play("preview")
	end
end)

submit_btn.Activated:Connect(function()
	if not finished then
		show_notification("Koper belum lengkap!", "warning")
		return
	end

	sound_service.Play("click")

	visual_gui.Enabled = false
	packing_frame.Visible = false

	game_event:FireServer("minigame_finished", {
		minigame_id = current_minigame.minigame_id,
		success = true,
	})
end)

visual_gui.Enabled = false
packing_frame.Visible = false
deskripsi_template.Visible = false

game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name ~= "minigame_play" then
		return
	end

	if payload.type == "packing_souvenir" then
		start_packing_souvenir(payload)
	end
end)