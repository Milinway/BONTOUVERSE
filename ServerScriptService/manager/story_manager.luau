-- ServerScriptService > manager(Folder) > story_manager(ModuleScript)
local ServerScriptService = game:GetService("ServerScriptService")

local scene_manager = require(
	ServerScriptService
		:WaitForChild("manager")
		:WaitForChild("scene_manager")
)

local knowledge_manager = require(
	ServerScriptService
		:WaitForChild("manager")
		:WaitForChild("knowledge_manager")
)

local story_manager = {}

function story_manager.start(player, chapter_id, first_sequence)
	if typeof(chapter_id) ~= "string" then
		warn("[story_manager] chapter_id tidak valid")
		return false
	end

	local scene_folder = ServerScriptService:WaitForChild("scene")
	local chapter_scene = scene_folder:FindFirstChild("1_chapter")

	if not chapter_scene then
		warn("[story_manager] scene untuk chapter tidak ditemukan:", chapter_id)
		return false
	end

	local scene_data = require(chapter_scene)

	print("[story_manager] mulai:", player.Name, chapter_id)
	
	knowledge_manager.reset(player, chapter_id)

	scene_manager.play(
		player,
		scene_data,
		first_sequence or "chapter_start"
	)

	return true
end

return story_manager