-- StarterPLayerScripts > handler(Folder) > service(Folder) > setting(LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local SettingService = require(
	ReplicatedStorage:WaitForChild("service"):WaitForChild("setting")
)

local NotificationService = require(
	ReplicatedStorage:WaitForChild("service"):WaitForChild("notification")
)

local SoundGui = require(
	ReplicatedStorage:WaitForChild("service"):WaitForChild("sound")
)

local function find_with_timeout(parent, child_name, timeout)
	local child = parent:FindFirstChild(child_name)
	local end_time = os.clock() + timeout

	while not child and os.clock() < end_time do
		task.wait(0.1)
		child = parent:FindFirstChild(child_name)
	end

	return child
end

local player_gui = find_with_timeout(player, "PlayerGui", 10)

if not player_gui then
	warn("[setting] PlayerGui tidak ditemukan")
	return
end

local homepage_gui = find_with_timeout(player_gui, "homepage", 15)

if not homepage_gui then
	warn("[setting] ScreenGui homepage tidak ditemukan")
	return
end

local main_gui = homepage_gui:FindFirstChild("main")

if not main_gui then
	warn("[setting] main tidak ditemukan di homepage")
	return
end

local setting_frame = main_gui:FindFirstChild("setting")

if not setting_frame then
	warn("[setting] Frame setting tidak ditemukan")
	return
end

local function_setting = setting_frame:FindFirstChild("function_setting")

if not function_setting then
	warn("[setting] function_setting tidak ditemukan")
	return
end

local music_button = function_setting
	:WaitForChild("music")
	:WaitForChild("toogle")

local shadow_button = function_setting
	:WaitForChild("shadow")
	:WaitForChild("toogle")

local notification_root = player_gui
	:WaitForChild("notification")
	:WaitForChild("main")

local music_enabled = true
local shadow_enabled = Lighting.GlobalShadows

local original_music_volume = setmetatable({}, {
	__mode = "k",
})

local function update_icon(button, enabled)
	if button:IsA("ImageButton") or button:IsA("ImageLabel") then
		button.Image = enabled
			and SettingService.Config.Icons.On
			or SettingService.Config.Icons.Off
	end
end

local function set_music_enabled(enabled)
	local music_folder = SoundService:FindFirstChild("music")
		or SoundService:FindFirstChild("MusicFolder")

	if not music_folder then
		warn("[setting] Folder SoundService.music belum tersedia")
		return false
	end

	for _, object in ipairs(music_folder:GetDescendants()) do
		if object:IsA("Sound") then
			if original_music_volume[object] == nil then
				original_music_volume[object] = object.Volume
			end

			object.Volume = enabled
				and original_music_volume[object]
				or 0
		end
	end

	return true
end

local function set_shadow_enabled(enabled)
	Lighting.GlobalShadows = enabled
end

local function show_setting_notification(setting_name, enabled)
	local message = enabled
		and (setting_name .. " berhasil dinyalakan")
		or (setting_name .. " berhasil dimatikan")

	NotificationService.Show(
		notification_root,
		message,
		"success"
	)
end

music_button.MouseEnter:Connect(function()
	SoundGui.Play("preview")
end)

music_button.Activated:Connect(function()
	SoundGui.Play("click")

	local next_state = not music_enabled

	if not set_music_enabled(next_state) then
		NotificationService.Show(
			notification_root,
			"Folder music belum tersedia",
			"warning"
		)

		return
	end

	music_enabled = next_state

	update_icon(music_button, music_enabled)
	show_setting_notification("Musik", music_enabled)
end)

shadow_button.MouseEnter:Connect(function()
	SoundGui.Play("preview")
end)

shadow_button.Activated:Connect(function()
	SoundGui.Play("click")

	shadow_enabled = not shadow_enabled

	set_shadow_enabled(shadow_enabled)

	update_icon(shadow_button, shadow_enabled)
	show_setting_notification("Bayangan", shadow_enabled)
end)

update_icon(music_button, music_enabled)
update_icon(shadow_button, shadow_enabled)