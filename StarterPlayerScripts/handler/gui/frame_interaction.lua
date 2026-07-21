-- StarterPLayerScripts > handler(Folder) > gui(Folder) > frame_interaction(LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local SoundGui = require(
	ReplicatedStorage:WaitForChild("service"):WaitForChild("sound")
)

local Frame = require(
	ReplicatedStorage
		:WaitForChild("handler")
		:WaitForChild("gui")
		:WaitForChild("homepage")
		:WaitForChild("frame")
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

local function require_child(parent, child_name, timeout)
	local child = find_with_timeout(parent, child_name, timeout)

	if not child then
		warn(
			"[homepage] Object tidak ditemukan:",
			child_name,
			"di",
			parent:GetFullName()
		)
	end

	return child
end

local function find_back_button(frame)
	return frame:FindFirstChild("back", true)
		or frame:FindFirstChild("BackButton", true)
end

local player_gui = require_child(player, "PlayerGui", 10)

if not player_gui then
	return
end

local gui = require_child(player_gui, "homepage", 15)

if not gui or not gui:IsA("ScreenGui") then
	warn("[homepage] ScreenGui 'homepage' tidak ditemukan atau bukan ScreenGui")
	return
end

local main_gui = require_child(gui, "main", 10)

if not main_gui then
	return
end

local interaction = require_child(main_gui, "interaction", 10)

if not interaction then
	return
end

gui.Enabled = true

Frame.PrepareInteraction(interaction)

local function connect_menu(button_name, frame_name)
	local button = require_child(interaction, button_name, 10)
	local frame = require_child(main_gui, frame_name, 10)

	if not button or not frame then
		return
	end

	Frame.PreparePage(frame)

	button.MouseEnter:Connect(function()
		SoundGui.Play("preview")
	end)

	button.Activated:Connect(function()
		local opened = Frame.OpenMenu(frame, interaction)

		if opened then
			SoundGui.Play("click")
		end
	end)

	local back_button = find_back_button(frame)

	if not back_button then
		warn(
			"[homepage] Tombol 'back' tidak ditemukan di:",
			frame:GetFullName()
		)

		return
	end

	back_button.MouseEnter:Connect(function()
		SoundGui.Play("preview")
	end)

	back_button.Activated:Connect(function()
		local closed = Frame.CloseMenu(frame, interaction)

		if closed then
			SoundGui.Play("click")
		end
	end)
end

connect_menu("play", "play")
connect_menu("knowledge", "knowledge")
connect_menu("setting", "setting")
connect_menu("credit", "credit")