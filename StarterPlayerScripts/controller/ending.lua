-- StarterPlayer > StarterCharacterScripts > controller(Folder) > ending(LocalScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local event_remote = ReplicatedStorage:WaitForChild("event_remote")
local game_event = event_remote:WaitForChild("game_event")

local player = Players.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")

local ending_manager = {}

local function get_notification_frame()
	local notification = player_gui:FindFirstChild("notification")
	if notification then
		return notification:FindFirstChild("fade")
	end
	return nil
end

local function fade_label_in_out(label, chapter_name, duration)
	if not label then return end

	duration = duration or 1

	-- Set initial state
	label.Text = "Ending " .. chapter_name
	label.TextTransparency = 1
	label.Visible = true

	-- Fade in
	local tween_info_in = TweenInfo.new(duration * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local tween_in = TweenService:Create(label, tween_info_in, {TextTransparency = 0})
	tween_in:Play()
	tween_in.Completed:Wait()

	-- Wait di tengah
	task.wait(2)

	-- Fade out
	local tween_info_out = TweenInfo.new(duration * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local tween_out = TweenService:Create(label, tween_info_out, {TextTransparency = 1})
	tween_out:Play()
	tween_out.Completed:Wait()

	label.Visible = false
end

local function show_ending(chapter_name)
	local fade_frame = get_notification_frame()
	if not fade_frame then
		warn("[ending] notification/fade frame tidak ditemukan")
		return
	end

	local notification = fade_frame.Parent
	if not notification then return end

	-- Enable notification
	notification.Enabled = true
	fade_frame.Visible = true

	-- Cari atau buat ending_lbl
	local ending_lbl = fade_frame:FindFirstChild("ending_lbl")
	if not ending_lbl then
		ending_lbl = Instance.new("TextLabel")
		ending_lbl.Name = "ending_lbl"
		ending_lbl.Parent = fade_frame
		ending_lbl.Size = UDim2.new(1, 0, 1, 0)
		ending_lbl.Position = UDim2.new(0, 0, 0, 0)
		ending_lbl.BackgroundTransparency = 1
		ending_lbl.TextScaled = true
		ending_lbl.Font = Enum.Font.GothamBold
		ending_lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	-- Fade in/out ending text
	fade_label_in_out(ending_lbl, chapter_name, 1)

	-- Disable notification setelah selesai
	notification.Enabled = false
	fade_frame.Visible = false

	-- Fire event ke homepage untuk kembali
	game_event:FireServer("ending_completed", {
		chapter_name = chapter_name,
	})
end

-- Listen for ending event dari server
game_event.OnClientEvent:Connect(function(event_name, payload)
	if event_name == "show_ending" then
		local chapter_name = payload.chapter_name or "Chapter"
		show_ending(chapter_name)
	end
end)

return ending_manager