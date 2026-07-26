--[[
    BarrierSpawner Server Script
    Mengelola spawn dan despawn block berdasarkan signal dari client.
    Mendukung multiplayer dengan tracking jumlah player per area.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Import modules
local GridGenerator = require(ReplicatedStorage.handler.barrier.grid)
local BarrierTween = require(ReplicatedStorage.handler.barrier.tween)

-- Get services
local barrierEvent = ReplicatedStorage:WaitForChild("event_remote"):WaitForChild("barrier_event")
local blokTemplate = game.ServerStorage:WaitForChild("assets"):WaitForChild("BlockPart")

-- Konfigurasi
local RIPPLE_DELAY = 0.02 -- Delay antar block saat spawn ripple
local DESTROY_RIPPLE_DELAY = 0.02 -- Delay antar block saat destroy ripple

--[[
    Data structure untuk menyimpan state barrier:
    {
        [areaName] = {
            areaReference = Part,
            gridGenerator = GridGenerator instance,
            frames = {CFrame array},
            spawnedBlocks = {BasePart array},
            playersInRadius = {Player array},
            isLoaded = boolean,
            lastNearestIndex = number,
        }
    }
]]
local barrierState: {[string]: any} = {}

--[[
    Inisialisasi state untuk semua area acuan di workspace
]]
local function initializeBarrierStates()
	local barrierFolder = workspace:FindFirstChild("barrier")

	if not barrierFolder then
		warn("BarrierSpawner: Folder 'Barier' tidak ditemukan di Workspace")
		return
	end

	for _, areaRef in ipairs(barrierFolder:GetChildren()) do
		if areaRef:IsA("BasePart") then
			local areaName = areaRef.Name

			barrierState[areaName] = {
				areaReference = areaRef,
				gridGenerator = nil,
				frames = {},
				spawnedBlocks = {},
				playersInRadius = {},
				isLoaded = false,
				lastNearestIndex = 1,
			}

			print("BarrierSpawner: Area '" .. areaName .. "' diinisialisasi")
		end
	end
end

--[[
    Generate grid untuk area tertentu (dipanggil sekali saja)
    @param areaName (string) - Nama area
]]
local function generateAreaGrid(areaName: string)
	local state = barrierState[areaName]

	if not state then
		warn("BarrierSpawner.generateAreaGrid: Area '" .. areaName .. "' tidak ditemukan")
		return
	end

	if state.gridGenerator then
		return -- Sudah di-generate
	end

	local areaRef = state.areaReference
	local areaSize = areaRef.Size
	local areaPosition = areaRef.CFrame

	local blockSize = blokTemplate.Size

	-- Create GridGenerator
	state.gridGenerator = GridGenerator.new(areaSize, blockSize, areaPosition)
	state.frames = state.gridGenerator:generateGrid()

	local info = state.gridGenerator:getInfo()
	print("BarrierSpawner: Grid untuk '" .. areaName .. "' di-generate - "
		.. info.gridX .. "x" .. info.gridY .. "x" .. info.gridZ 
		.. " (" .. info.totalBlocks .. " blocks)")
end

--[[
    Spawn block untuk area tertentu
    @param areaName (string) - Nama area
    @param playerPosition (Vector3) - Posisi player untuk ripple effect
]]
local function spawnAreaBlocks(areaName: string, playerPosition: Vector3)
	local state = barrierState[areaName]

	if not state then
		warn("BarrierSpawner.spawnAreaBlocks: Area '" .. areaName .. "' tidak ditemukan")
		return
	end

	if state.isLoaded then
		return -- Sudah di-load
	end

	-- Generate grid jika belum
	generateAreaGrid(areaName)

	local frames = state.frames
	local spawnedBlocks = state.spawnedBlocks

	-- Clone block sesuai grid
	for i, frame in ipairs(frames) do
		local newBlock = blokTemplate:Clone()
		newBlock.CFrame = frame
		newBlock.Transparency = 1 -- Mulai dari transparent
		newBlock.Parent = workspace

		table.insert(spawnedBlocks, newBlock)
	end

	state.isLoaded = true

	-- Fade in dengan ripple effect
	if state.gridGenerator then
		local sortedIndices = state.gridGenerator:sortFramesByDistance(playerPosition, frames)
		BarrierTween.fadeInRipple(spawnedBlocks, sortedIndices, RIPPLE_DELAY, function()
			print("BarrierSpawner: Block untuk '" .. areaName .. "' fully loaded")
		end)
	else
		BarrierTween.fadeInMultiple(spawnedBlocks)
	end
end

--[[
    Despawn block untuk area tertentu
    @param areaName (string) - Nama area
    @param playerPosition (Vector3) - Posisi player untuk ripple effect
]]
local function despawnAreaBlocks(areaName: string, playerPosition: Vector3)
	local state = barrierState[areaName]

	if not state then
		warn("BarrierSpawner.despawnAreaBlocks: Area '" .. areaName .. "' tidak ditemukan")
		return
	end

	if not state.isLoaded then
		return -- Belum di-load
	end

	local spawnedBlocks = state.spawnedBlocks

	if #spawnedBlocks == 0 then
		return
	end

	state.isLoaded = false

	-- Fade out dengan ripple effect
	if state.gridGenerator then
		local sortedIndices = state.gridGenerator:sortFramesByDistance(playerPosition, state.frames)
		BarrierTween.fadeOutRipple(spawnedBlocks, sortedIndices, DESTROY_RIPPLE_DELAY, function()
			-- Destroy semua block setelah fade out
			for _, block in ipairs(spawnedBlocks) do
				if block and block.Parent then
					block:Destroy()
				end
			end

			state.spawnedBlocks = {}
			print("BarrierSpawner: Block untuk '" .. areaName .. "' fully unloaded")
		end)
	else
		-- Fallback: destroy langsung
		for _, block in ipairs(spawnedBlocks) do
			if block and block.Parent then
				block:Destroy()
			end
		end
		state.spawnedBlocks = {}
	end
end

--[[
    Tambah player ke radius area
    Jika belum ada player, spawn block
    @param player (Player) - Player yang masuk radius
    @param areaName (string) - Nama area
]]
local function addPlayerToArea(player: Player, areaName: string)
	local state = barrierState[areaName]

	if not state then
		warn("BarrierSpawner.addPlayerToArea: Area '" .. areaName .. "' tidak ditemukan")
		return
	end

	-- Cek apakah player sudah ada
	for _, p in ipairs(state.playersInRadius) do
		if p == player then
			return -- Sudah ada
		end
	end

	table.insert(state.playersInRadius, player)

	-- Jika ini player pertama, spawn block
	if #state.playersInRadius == 1 then
		print("BarrierSpawner: Player pertama masuk area '" .. areaName .. "', spawn block")

		local playerCharacter = player.Character
		local playerPosition = playerCharacter and playerCharacter.HumanoidRootPart.Position or Vector3.new(0, 0, 0)

		spawnAreaBlocks(areaName, playerPosition)
	end
end

--[[
    Hapus player dari radius area
    Jika tidak ada player lagi, despawn block
    @param player (Player) - Player yang keluar radius
    @param areaName (string) - Nama area
]]
local function removePlayerFromArea(player: Player, areaName: string)
	local state = barrierState[areaName]

	if not state then
		return
	end

	local playersInRadius = state.playersInRadius

	-- Cari dan hapus player
	for i, p in ipairs(playersInRadius) do
		if p == player then
			table.remove(playersInRadius, i)
			break
		end
	end

	-- Jika tidak ada player lagi, despawn block
	if #playersInRadius == 0 then
		print("BarrierSpawner: Tidak ada player lagi di area '" .. areaName .. "', despawn block")

		local playerCharacter = player.Character
		local playerPosition = playerCharacter and playerCharacter.HumanoidRootPart.Position or Vector3.new(0, 0, 0)

		despawnAreaBlocks(areaName, playerPosition)
	end
end

--[[
    Handle remoteEvent dari client
]]
local function setupRemoteEventListeners()
	barrierEvent.OnServerEvent:Connect(function(player: Player, action: string, areaName: string, playerPos: Vector3)
		if action == "Load" then
			addPlayerToArea(player, areaName)
		elseif action == "Unload" then
			removePlayerFromArea(player, areaName)
		end
	end)
end

--[[
    Bersihkan block ketika player meninggalkan game
]]
local function setupPlayerRemovedListener()
	local players = game:GetService("Players")

	players.PlayerRemoving:Connect(function(player: Player)
		-- Hapus player dari semua area
		for areaName, state in pairs(barrierState) do
			removePlayerFromArea(player, areaName)
		end
	end)
end

--[[
    Main initialization
]]
local function initialize()
	print("BarrierSpawner: Initializing...")

	initializeBarrierStates()
	setupRemoteEventListeners()
	setupPlayerRemovedListener()

	print("BarrierSpawner: Ready")
end

initialize()
