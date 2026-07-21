-- ReplicatedStorage > handler(Folder) > gui(Folder) > homepage(Folder) > chapter_card(ModuleScript)
-- require (chapter_card(ModuleScript), catalog(ModuleScript), chapter_manager(ModuleScript), homepage(LocalScript), main_server(Scriot))
local chapter_card = {}

local function find_direct_child(parent, child_name)
	local child = parent:FindFirstChild(child_name)

	if child then
		return child
	end

	return nil
end

local function find_descendant(parent, child_name)
	return parent:FindFirstChild(child_name, true)
end

local function set_text(object, text)
	if object and object:IsA("TextLabel") or object and object:IsA("TextButton") then
		object.Text = text
	end
end

local function set_image(object, image)
	if not object then
		return
	end

	if object:IsA("ImageLabel") or object:IsA("ImageButton") then
		object.Image = image
	end
end

function chapter_card.create(config)
	local parent = config.parent
	local template = config.template
	local data = config.data
	local sound_service = config.sound_service
	local on_selected = config.on_selected

	local card = template:Clone()

	card.Name = data.chapter_id
	card.Visible = true
	card.LayoutOrder = data.order or 0
	card:SetAttribute("generated_chapter_card", true)
	card:SetAttribute("chapter_id", data.chapter_id)

	if card:IsA("TextButton") or card:IsA("ImageButton") then
		card.AutoButtonColor = data.is_unlocked == true
		card.Active = data.is_unlocked == true
	end

	local title = find_direct_child(card, "title")
	local status = find_direct_child(card, "status")
	local img = find_descendant(card, "img")
	local locked = find_descendant(card, "locked")

	if title then
		set_text(title, data.title)
	elseif card:IsA("TextButton") then
		card.Text = data.title
	end

	if status then
		set_text(status, data.status)
	end

	if img and data.image and data.image ~= "" then
		set_image(img, data.image)
	end

	if locked then
		locked.Visible = not data.is_unlocked

		local locked_title = locked:FindFirstChild("title", true)

		if locked_title then
			if data.is_unlocked then
				locked_title.Text = ""
			else
				locked_title.Text = "Terkunci"
			end
		end
	end

	if card:IsA("GuiButton") then
		card.MouseEnter:Connect(function()
			if sound_service then
				sound_service.Play("preview")
			end
		end)

		card.Activated:Connect(function()
			if sound_service then
				sound_service.Play("click")
			end

			if on_selected then
				on_selected(data)
			end
		end)
	else
		warn("[chapter_card] card_template sebaiknya berupa TextButton atau ImageButton")
	end

	card.Parent = parent

	return card
end

return chapter_card