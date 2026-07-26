-- FILE 1: ServerScriptService/spawn.lua
--[[
    BarrierSpawner Server Script
    Mengelola spawn dan despawn block dengan Decal sebagai child dari acuan.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import modules
local GridGenerator = require(ReplicatedStorage.handler.barrier.grid)
local BarrierTween = require(ReplicatedStorage.handler.barrier.tween)

-- Get event
local barrierEvent = ReplicatedStorage:WaitForChild("event_remote"):WaitForChild("barrier_event")
local blokTemplate = game.ServerStorage:WaitForChild("assets"):WaitForChild("BlokPart")

-- Config
local RIPPLE_DELAY = 0.03
local DESTROY_RIPPLE_DELAY = 0.03

--[[
    State tracking per area:
    {
        [areaName] = {
            areaRef = Part,
            gridGenerator = GridGenerator,
            frames = {CFrame array},
            spawnedBlocks = {Part array},
            spawnedDecals = {Decal array},
            playersInRadius = {Player array},
            isLoaded = false,
        }
    }
]]
local barrierState = {}

--[[
    Initialize semua area dari folder barrier
]]
local function initializeStates()
    local barrierFolder = workspace:FindFirstChild("barrier")
    
    if not barrierFolder then
        warn("BarrierSpawner: Folder 'barrier' tidak ditemukan")
        return
    end
    
    for _, areaRef in ipairs(barrierFolder:GetChildren()) do
        if areaRef:IsA("BasePart") then
            local areaName = areaRef.Name
            
            barrierState[areaName] = {
                areaRef = areaRef,
                gridGenerator = nil,
                frames = {},
                spawnedBlocks = {},
                spawnedDecals = {},
                playersInRadius = {},
                isLoaded = false,
            }
            
            print("BarrierSpawner: Area '" .. areaName .. "' initialized")
        end
    end
end

--[[
    Generate grid satu kali untuk area
]]
local function generateGrid(areaName: string)
    local state = barrierState[areaName]
    if not state or state.gridGenerator then
        return
    end
    
    local areaRef = state.areaRef
    local areaSize = areaRef.Size
    local areaPosition = areaRef.CFrame
    local blockSize = blokTemplate.Size
    
    state.gridGenerator = GridGenerator.new(areaSize, blockSize, areaPosition)
    state.frames = state.gridGenerator:generateGrid()
    
    local info = state.gridGenerator:getInfo()
    print("BarrierSpawner: Grid '" .. areaName .. "' generated - " 
        .. info.gridX .. "x" .. info.gridY .. "x" .. info.gridZ 
        .. " (" .. info.totalBlocks .. " blocks)")
end

--[[
    Spawn block di dalam acuan sebagai parent
]]
local function spawnBlocks(areaName: string, playerPos: Vector3)
    local state = barrierState[areaName]
    if not state or state.isLoaded then
        return
    end
    
    generateGrid(areaName)
    
    local areaRef = state.areaRef
    local frames = state.frames
    
    -- Clone block sesuai grid
    for i, frame in ipairs(frames) do
        local newBlock = blokTemplate:Clone()
        newBlock.CFrame = frame
        newBlock.Parent = areaRef  -- ✅ PENTING: Parent ke acuan, bukan workspace
        
        table.insert(state.spawnedBlocks, newBlock)
        
        -- Kumpulkan semua Decal dari block
        for _, decal in ipairs(newBlock:GetDescendants()) do
            if decal:IsA("Decal") then
                decal.Transparency = 1  -- Start hidden
                table.insert(state.spawnedDecals, decal)
            end
        end
    end
    
    state.isLoaded = true
    
    -- Fade in Decal dengan ripple
    if state.gridGenerator and #state.spawnedDecals > 0 then
        local sortedIndices = state.gridGenerator:sortFramesByDistance(playerPos, frames)
        BarrierTween.fadeInRippleDecals(state.spawnedDecals, sortedIndices, RIPPLE_DELAY, function()
            print("BarrierSpawner: '" .. areaName .. "' fully loaded")
        end)
    end
end

--[[
    Despawn block dari acuan
]]
local function despawnBlocks(areaName: string, playerPos: Vector3)
    local state = barrierState[areaName]
    if not state or not state.isLoaded then
        return
    end
    
    state.isLoaded = false
    
    local decals = state.spawnedDecals
    if #decals == 0 then
        -- Destroy langsung jika tidak ada decal
        for _, block in ipairs(state.spawnedBlocks) do
            if block and block.Parent then
                block:Destroy()
            end
        end
        state.spawnedBlocks = {}
        return
    end
    
    -- Fade out Decal dengan ripple
    local sortedIndices = state.gridGenerator:sortFramesByDistance(playerPos, state.frames)
    BarrierTween.fadeOutRippleDecals(decals, sortedIndices, DESTROY_RIPPLE_DELAY, function()
        -- Destroy semua block setelah fade out
        for _, block in ipairs(state.spawnedBlocks) do
            if block and block.Parent then
                block:Destroy()
            end
        end
        state.spawnedBlocks = {}
        state.spawnedDecals = {}
        print("BarrierSpawner: '" .. areaName .. "' fully unloaded")
    end)
end

--[[
    Tambah player ke area
]]
local function addPlayerToArea(player: Player, areaName: string)
    local state = barrierState[areaName]
    if not state then
        return
    end
    
    -- Cek duplikat
    for _, p in ipairs(state.playersInRadius) do
        if p == player then
            return
        end
    end
    
    table.insert(state.playersInRadius, player)
    
    -- Spawn jika player pertama
    if #state.playersInRadius == 1 then
        print("BarrierSpawner: First player in '" .. areaName .. "', spawning blocks")
        local playerCharacter = player.Character
        local playerPos = playerCharacter and playerCharacter.HumanoidRootPart.Position or Vector3.new(0, 0, 0)
        spawnBlocks(areaName, playerPos)
    end
end

--[[
    Hapus player dari area
]]
local function removePlayerFromArea(player: Player, areaName: string)
    local state = barrierState[areaName]
    if not state then
        return
    end
    
    for i, p in ipairs(state.playersInRadius) do
        if p == player then
            table.remove(state.playersInRadius, i)
            break
        end
    end
    
    -- Despawn jika tidak ada player
    if #state.playersInRadius == 0 then
        print("BarrierSpawner: No players in '" .. areaName .. "', despawning blocks")
        local playerCharacter = player.Character
        local playerPos = playerCharacter and playerCharacter.HumanoidRootPart.Position or Vector3.new(0, 0, 0)
        despawnBlocks(areaName, playerPos)
    end
end

--[[
    Setup RemoteEvent listener
]]
local function setupEventListener()
    barrierEvent.OnServerEvent:Connect(function(player: Player, action: string, areaName: string, playerPos: Vector3)
        if action == "Load" then
            addPlayerToArea(player, areaName)
        elseif action == "Unload" then
            removePlayerFromArea(player, areaName)
        end
    end)
end

--[[
    Cleanup ketika player leave
]]
local function setupPlayerRemovedListener()
    local players = game:GetService("Players")
    players.PlayerRemoving:Connect(function(player: Player)
        for areaName in pairs(barrierState) do
            removePlayerFromArea(player, areaName)
        end
    end)
end

-- Initialize
initializeStates()
setupEventListener()
setupPlayerRemovedListener()

print("BarrierSpawner: Ready")