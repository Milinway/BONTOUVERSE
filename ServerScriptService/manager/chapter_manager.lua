-- ServerScriptService > manager(Folder) > chapter_manager(ModuleScript)
-- require (chapter_card(ModuleScript), catalog(ModuleScript), chapter_manager(ModuleScript), homepage(LocalScript), main_server(Scriot))
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local catalog = require(
	ReplicatedStorage
		:WaitForChild("module")
		:WaitForChild("data")
		:WaitForChild("chapter")
		:WaitForChild("catalog")
)

local chapter_manager = {}

local function get_player_progress(player)
	return {
		chapter_1 = {
			is_unlocked = true,
			is_completed = false,
			knowledge = 0,
		},
	}
end

function chapter_manager.get_menu_data(player)
	local progress = get_player_progress(player)
	local result = {}

	for _, chapter_data in pairs(catalog) do
		local chapter_progress = progress[chapter_data.chapter_id] or {}

		local is_unlocked = chapter_progress.is_unlocked == true
		local is_completed = chapter_progress.is_completed == true
		local knowledge = chapter_progress.knowledge or 0

		local status = "Terkunci"

		if is_unlocked and is_completed then
			status = "Selesai"
		elseif is_unlocked then
			status = "Tersedia"
		end

		table.insert(result, {
			chapter_id = chapter_data.chapter_id,
			order = chapter_data.order,

			title = chapter_data.title,
			subtitle = chapter_data.subtitle,
			image = chapter_data.image,

			status = status,
			is_unlocked = is_unlocked,
			is_completed = is_completed,
			knowledge = knowledge,

			first_sequence = chapter_data.first_sequence,
		})
	end

	table.sort(result, function(a, b)
		return a.order < b.order
	end)

	return result
end

function chapter_manager.request_start(player, chapter_id)
	if typeof(chapter_id) ~= "string" then
		return false, "chapter_id tidak valid"
	end

	local chapter_data = catalog[chapter_id]

	if not chapter_data then
		return false, "chapter tidak ditemukan"
	end

	local progress = get_player_progress(player)
	local chapter_progress = progress[chapter_id]

	if not chapter_progress or not chapter_progress.is_unlocked then
		return false, "chapter masih terkunci"
	end

	return true, {
		chapter_id = chapter_data.chapter_id,
		first_sequence = chapter_data.first_sequence,
	}
end

return chapter_manager