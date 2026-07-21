-- ReplicatedStorage > service(Folder) > sound(ModuleScript)
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local sound = {}

local warned = {}

local function normalize_sound_id(sound_id)
	if typeof(sound_id) == "number" then
		return "rbxassetid://" .. tostring(sound_id)
	end

	if typeof(sound_id) ~= "string" then
		return nil
	end

	if sound_id == "" then
		return nil
	end

	if string.find(sound_id, "rbxassetid://") == 1 then
		return sound_id
	end

	if tonumber(sound_id) then
		return "rbxassetid://" .. sound_id
	end

	return sound_id
end

function sound.Play(sound_type)
	if not RunService:IsClient() then
		warn("[sound] sound.Play() hanya boleh dipanggil dari LocalScript")
		return false
	end

	local system = SoundService:FindFirstChild("system")

	if not system then
		if not warned.system then
			warn("[sound] Folder SoundService.system tidak ditemukan")
			warned.system = true
		end

		return false
	end

	local target_sound = system:FindFirstChild(sound_type)

	if not target_sound or not target_sound:IsA("Sound") then
		if not warned[sound_type] then
			warn("[sound] Sound tidak ditemukan:", sound_type)
			warned[sound_type] = true
		end

		return false
	end

	SoundService:PlayLocalSound(target_sound)

	return true
end

function sound.PlayId(sound_id, volume)
	if not RunService:IsClient() then
		warn("[sound] sound.PlayId() hanya boleh dipanggil dari LocalScript")
		return nil
	end

	local normalized_id = normalize_sound_id(sound_id)

	if not normalized_id then
		return nil
	end

	local sound_object = Instance.new("Sound")

	sound_object.Name = "_local_voice"
	sound_object.SoundId = normalized_id
	sound_object.Volume = volume or 1
	sound_object.Looped = false
	sound_object.Parent = SoundService

	sound_object.Ended:Connect(function()
		if sound_object then
			sound_object:Destroy()
		end
	end)

	sound_object:Play()

	return sound_object
end

function sound.Stop(sound_object)
	if sound_object and sound_object:IsA("Sound") then
		sound_object:Stop()
		sound_object:Destroy()
	end
end

return sound