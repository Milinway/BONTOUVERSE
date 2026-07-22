-- ServerScriptService > manager(Folder) > teleport_manager(ModuleScript)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local teleport_manager = {}

-- Fungsi untuk freeze player (disable movement)
local function freeze_player(player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpHeight = 0
	end
end

-- Fungsi untuk unfreeze player (enable movement)
local function unfreeze_player(player)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16 -- Default walk speed
		humanoid.JumpHeight = 7.2 -- Default jump height
	end
end

-- Fungsi untuk mendapatkan chapter_id dari player
local function get_chapter_id(player)
	if player:FindFirstChild("chapter_id_tag") then
		return player:FindFirstChild("chapter_id_tag").Value
	end

	-- Default jika tidak ada tag
	return "chapter_1"
end

-- Fungsi untuk set chapter_id (dipanggil dari scene_manager)
function teleport_manager.set_chapter_id(player, chapter_id)
	local existing_tag = player:FindFirstChild("chapter_id_tag")

	if existing_tag then
		existing_tag.Value = chapter_id
	else
		local tag = Instance.new("StringValue")
		tag.Name = "chapter_id_tag"
		tag.Value = chapter_id
		tag.Parent = player
	end
end

-- Fungsi utama teleport
function teleport_manager.teleport(player, teleport_id)
	if not player then
		warn("[teleport_manager] player tidak valid")
		return false
	end

	if typeof(teleport_id) ~= "string" then
		teleport_id = tostring(teleport_id)
	end

	local character = player.Character
	if not character then
		warn("[teleport_manager] character tidak ditemukan untuk player:", player.Name)
		return false
	end

	local humanoid_root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid_root then
		warn("[teleport_manager] HumanoidRootPart tidak ditemukan")
		return false
	end

	-- Dapatkan chapter_id
	local chapter_id = get_chapter_id(player)
	print("[teleport_manager] chapter_id:", chapter_id, "teleport_id:", teleport_id)

	-- Cari folder di Workspace > teleport > chapter_X
	local teleport_folder = Workspace:FindFirstChild("teleport")
	if not teleport_folder then
		warn("[teleport_manager] Workspace > teleport folder tidak ditemukan")
		return false
	end

	local chapter_folder = teleport_folder:FindFirstChild(chapter_id)
	if not chapter_folder then
		warn("[teleport_manager] folder tidak ditemukan:", chapter_id)
		return false
	end

	-- Cari part berdasarkan teleport_id
	local teleport_part = chapter_folder:FindFirstChild(teleport_id)
	if not teleport_part then
		warn("[teleport_manager] teleport part tidak ditemukan:", teleport_id, "di", chapter_folder:GetFullName())
		return false
	end

	if not teleport_part:IsA("BasePart") then
		warn("[teleport_manager] teleport target bukan BasePart:", teleport_part:GetFullName())
		return false
	end

	-- Freeze player
	freeze_player(player)

	-- Teleport ke lokasi part
	local target_position = teleport_part.Position + Vector3.new(0, 3, 0) -- Offset agar tidak masuk part
	humanoid_root.CFrame = CFrame.new(target_position)

	print("[teleport_manager] player", player.Name, "teleported ke", teleport_part:GetFullName())

	-- Unfreeze player setelah delay kecil
	task.wait(0.5)
	unfreeze_player(player)

	return true
end

return teleport_manager
