-- ReplicatedStorage > service(Folder) > notification(ModuleScript)
local TweenService = game:GetService("TweenService")

local NotificationService = {}

NotificationService.Config = {
	Duration = 2,
	FadeOutDuration = 0.35,

	Types = {
		success = {
			TextColor = Color3.fromRGB(90, 255, 120),
		},

		error = {
			TextColor = Color3.fromRGB(255, 100, 100),
		},

		warning = {
			TextColor = Color3.fromRGB(255, 220, 80),
		},
	},
}

local function ensure_layout(parent)
	local layout = parent:FindFirstChildOfClass("UIListLayout")

	if layout then
		return layout
	end

	layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(0, 6)
	layout.Parent = parent

	return layout
end

function NotificationService.Show(parent, message, notification_type)
	if not parent then
		return
	end

	ensure_layout(parent)

	local selected_type =
		NotificationService.Config.Types[notification_type]
		or NotificationService.Config.Types.success

	local notification = Instance.new("TextLabel")

	notification.Name = "notification"
	notification.BackgroundTransparency = 1
	notification.Size = UDim2.new(0.85, 0, 0, 34)
	notification.Font = Enum.Font.GothamBold
	notification.Text = message
	notification.TextColor3 = selected_type.TextColor
	notification.TextScaled = true
	notification.TextStrokeTransparency = 0.6
	notification.TextTransparency = 0
	notification.TextWrapped = true
	notification.ZIndex = 1000
	notification.Parent = parent

	task.delay(NotificationService.Config.Duration, function()
		if not notification.Parent then
			return
		end

		local tween = TweenService:Create(
			notification,
			TweenInfo.new(NotificationService.Config.FadeOutDuration),
			{
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}
		)

		tween:Play()
		tween.Completed:Wait()

		if notification then
			notification:Destroy()
		end
	end)
end

return NotificationService