-- ReplicatedStorage > handler(Folder) > gui(Folder) > homepage(Folder) > frame(ModuleScript)
local TweenService = game:GetService("TweenService")

local FrameService = {}

local page_state = setmetatable({}, { __mode = "k" })
local interaction_state = setmetatable({}, { __mode = "k" })

local open_tween_info = TweenInfo.new(
	0.45,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

local close_tween_info = TweenInfo.new(
	0.35,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.In
)

local function get_page_state(frame)
	if page_state[frame] then
		return page_state[frame]
	end

	page_state[frame] = {
		open_position = frame.Position,
		open_size = frame.Size,
		is_busy = false,
	}

	return page_state[frame]
end

local function get_interaction_state(interaction)
	if interaction_state[interaction] then
		return interaction_state[interaction]
	end

	interaction_state[interaction] = {
		open_position = interaction.Position,
		open_size = interaction.Size,
	}

	return interaction_state[interaction]
end

local function get_bottom_position(position)
	return UDim2.new(
		position.X.Scale,
		position.X.Offset,
		1.4,
		0
	)
end

function FrameService.PreparePage(frame)
	if not frame or not frame:IsA("GuiObject") then
		return
	end

	local state = get_page_state(frame)

	frame.Size = state.open_size
	frame.Position = state.open_position
	frame.Visible = false
end

function FrameService.PrepareInteraction(interaction)
	if not interaction or not interaction:IsA("GuiObject") then
		return
	end

	local state = get_interaction_state(interaction)

	interaction.Size = state.open_size
	interaction.Position = state.open_position
	interaction.Visible = true
end

function FrameService.OpenMenu(frame, interaction)
	if not frame or not frame:IsA("GuiObject") then
		return false
	end

	local state = get_page_state(frame)

	if state.is_busy then
		return false
	end

	state.is_busy = true

	if interaction then
		interaction.Visible = false
	end

	frame.Visible = true
	frame.Size = state.open_size
	frame.Position = get_bottom_position(state.open_position)

	local tween = TweenService:Create(frame, open_tween_info, {
		Position = state.open_position,
	})

	tween:Play()

	tween.Completed:Connect(function()
		state.is_busy = false
	end)

	return true
end

function FrameService.CloseMenu(frame, interaction)
	if not frame or not frame:IsA("GuiObject") then
		return false
	end

	local state = get_page_state(frame)

	if state.is_busy then
		return false
	end

	state.is_busy = true

	local tween = TweenService:Create(frame, close_tween_info, {
		Position = get_bottom_position(state.open_position),
	})

	tween:Play()

	tween.Completed:Connect(function()
		frame.Visible = false
		frame.Position = state.open_position
		frame.Size = state.open_size

		state.is_busy = false

		if interaction then
			local interaction_data = get_interaction_state(interaction)

			interaction.Visible = true
			interaction.Size = interaction_data.open_size
			interaction.Position = get_bottom_position(interaction_data.open_position)

			local interaction_tween = TweenService:Create(
				interaction,
				open_tween_info,
				{
					Position = interaction_data.open_position,
				}
			)

			interaction_tween:Play()
		end
	end)

	return true
end

return FrameService