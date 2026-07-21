-- ServerScriptService > manager(Folder) > knowledge_manager(ModuleScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local knowledge_manager = {}

local player_data = {}

local DEFAULT_MAX = 100

local function clamp(value, min_value, max_value)
	return math.clamp(value, min_value, max_value)
end

local function get_state(player)
	local user_id = player.UserId

	if not player_data[user_id] then
		player_data[user_id] = {
			chapter_id = nil,
			current = 0,
			max = DEFAULT_MAX,
			highest = 0,
		}
	end

	return player_data[user_id]
end

function knowledge_manager.reset(player, chapter_id)
	local state = get_state(player)

	state.chapter_id = chapter_id
	state.current = 0
	state.max = DEFAULT_MAX

	game_event:FireClient(player, "knowledge_update", {
		chapter_id = chapter_id,
		current = state.current,
		max = state.max,
		highest = state.highest,
		reason = "Knowledge chapter direset",
		is_reset = true,
	})

	return state
end

function knowledge_manager.set(player, value, reason)
	local state = get_state(player)

	value = tonumber(value) or 0
	value = clamp(value, 0, state.max)

	state.current = value

	if value > state.highest then
		state.highest = value
	end

	game_event:FireClient(player, "knowledge_update", {
		chapter_id = state.chapter_id,
		current = state.current,
		max = state.max,
		highest = state.highest,
		reason = reason,
		is_reset = false,
	})

	return state
end

function knowledge_manager.get(player)
	return get_state(player)
end

Players.PlayerRemoving:Connect(function(player)
	player_data[player.UserId] = nil
end)

return knowledge_manager