-- ServerScriptService > manager(Folder) > fade_manager(ModuleScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local fade_manager = {}

function fade_manager.play(player, mode, duration)
	if not player then
		return false
	end

	mode = mode or "out"
	duration = duration or 0.8

	game_event:FireClient(player, "fade_play", {
		mode = mode,
		duration = duration,
	})

	-- Sementara server menunggu durasi fade.
	-- Nanti bisa dibuat lebih presisi pakai callback dari client.
	task.wait(duration + 0.05)

	return true
end

return fade_manager