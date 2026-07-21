--ServerScriptService > main_server(Script)
-- require (chapter_card(ModuleScript), catalog(ModuleScript), chapter_manager(ModuleScript), homepage(LocalScript), main_server(Scriot))
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")

local game_event = event_remote:WaitForChild("game_event")
local game_function = event_remote:WaitForChild("game_function")

local chapter_manager = require(
	script.Parent
		:WaitForChild("manager")
		:WaitForChild("chapter_manager")
)

local story_manager = require(
	script.Parent
		:WaitForChild("manager")
		:WaitForChild("story_manager")
)

game_function.OnServerInvoke = function(player, request_name)
	if request_name == "get_homepage_chapter_list" then
		return {
			success = true,
			chapters = chapter_manager.get_menu_data(player),
		}
	end

	return {
		success = false,
		message = "request tidak dikenal: " .. tostring(request_name),
	}
end

game_event.OnServerEvent:Connect(function(player, event_name, payload)
	if event_name ~= "start_chapter" then
		return
	end

	local success, result = chapter_manager.request_start(player, payload)

	if not success then
		game_event:FireClient(player, "chapter_start_rejected", {
			message = result,
		})

		return
	end

	game_event:FireClient(player, "chapter_start_accepted", result)

	task.spawn(function()
		story_manager.start(
			player,
			result.chapter_id,
			result.first_sequence
		)
	end)
end)