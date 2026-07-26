--[[
    BarrierController LocalScript
    Mengecek jarak player ke seluruh acuan dan mengirim signal Load/Unload ke server.
    Berjalan di client-side hanya untuk monitoring jarak.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Get references
local barrierEvent = ReplicatedStorage:WaitForChild("event_remote"):WaitForChild("barrier_event")
local player = Players.LocalPlayer
local playerCharacter = player.Character or player.CharacterAdded:Wait()

-- Konfigurasi
local LOAD_RADIUS = 60 -- Radius untuk load block (stud)
local CHECK_INTERVAL = 0.5 -- Interval pengecekan jarak (detik)
local DEBOUNCE_TIME = 0.2 -- Debounce untuk mencegah load/unload berulang (detik)

--[[
    State tracking untuk area
    {
        [areaName] = {
            isSignaled = boolean, -- Apakah sudah mengirim signal
            lastSignalTime = number, -- Waktu terakhir mengirim signal
        }
    }
]]
local areaState: {[string]: any} = {}

--[[
    Inisialisasi state untuk semua area
]]
local function initializeAreaState()
	local barrierFolder = workspace:FindFirstChild("barrier")

	if not barrierFolder then
		warn("BarrierController: Folder 'Barier' tidak ditemukan di Workspace")
		return
	end

	for _, areaRef in ipairs(barrierFolder:GetChildren()) do
		if areaRef:IsA("BasePart") then
			local areaName = areaRef.Name

			areaState[areaName] = {
				isSignaled = false,
				lastSignalTime = 0,
			}
		end
	end
end

--[[
    Hitung jarak antara dua Vector3
    @param pos1 (Vector3)
    @param pos2 (Vector3)
    @return number - Jarak dalam stud
]]
local function calculateDistance(pos1: Vector3, pos2: Vector3): number
	return (pos1 - pos2).Magnitude
end

--[[
    Cek apakah perlu debounce
    @param areaName (string)
    @return boolean - True jika boleh signal
]]
local function shouldSignal(areaName: string): boolean
	local state = areaState[areaName]
	if not state then
		return false
	end

	local timeSinceLastSignal = tick() - state.lastSignalTime
	return timeSinceLastSignal >= DEBOUNCE_TIME
end

--[[
    Kirim signal Load ke server
    @param areaName (string) - Nama area
    @param playerPos (Vector3) - Posisi player saat ini
]]
local function sendLoadSignal(areaName: string, playerPos: Vector3)
	if not shouldSignal(areaName) then
		return
	end

	local state = areaState[areaName]

	if state.isSignaled then
		return -- Sudah di-signal
	end

	state.isSignaled = true
	state.lastSignalTime = tick()

	barrierEvent:FireServer("Load", areaName, playerPos)
	print("BarrierController: Signal LOAD untuk area '" .. areaName .. "'")
end

--[[
    Kirim signal Unload ke server
    @param areaName (string) - Nama area
    @param playerPos (Vector3) - Posisi player saat ini
]]
local function sendUnloadSignal(areaName: string, playerPos: Vector3)
	if not shouldSignal(areaName) then
		return
	end

	local state = areaState[areaName]

	if not state.isSignaled then
		return -- Belum di-signal
	end

	state.isSignaled = false
	state.lastSignalTime = tick()

	barrierEvent:FireServer("Unload", areaName, playerPos)
	print("BarrierController: Signal UNLOAD untuk area '" .. areaName .. "'")
end

--[[
    Periksa jarak player ke semua area
]]
local function checkDistancesToAreas()
	local character = player.Character

	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local playerPos = character.HumanoidRootPart.Position
	local barrierFolder = workspace:FindFirstChild("barrier")

	if not barrierFolder then
		return
	end

	for _, areaRef in ipairs(barrierFolder:GetChildren()) do
		if areaRef:IsA("BasePart") then
			local areaName = areaRef.Name
			local areaPos = areaRef.Position

			-- Hitung jarak dari player ke center area
			local distance = calculateDistance(playerPos, areaPos)

			-- Load jika dalam radius
			if distance <= LOAD_RADIUS then
				sendLoadSignal(areaName, playerPos)
			else
				-- Unload jika di luar radius
				sendUnloadSignal(areaName, playerPos)
			end
		end
	end
end

--[[
    Update reference character ketika player spawn kembali
]]
local function setupCharacterRespawnListener()
	player.CharacterAdded:Connect(function(newCharacter)
		playerCharacter = newCharacter
		print("BarrierController: Character respawned")
	end)
end

--[[
    Loop utama untuk pengecekan jarak
]]
local function startDistanceCheckLoop()
	while true do
		task.wait(CHECK_INTERVAL)

		-- Safety check: jika player tidak punya character, skip
		if player.Character then
			checkDistancesToAreas()
		end
	end
end

--[[
    Main initialization
]]
local function initialize()
	print("BarrierController: Initializing...")

	initializeAreaState()
	setupCharacterRespawnListener()

	print("BarrierController: Ready")

	-- Start main loop
	startDistanceCheckLoop()
end

initialize()
