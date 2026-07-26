-- FILE 3: ServerScriptService/spawn.lua (REVISED)
--[[
    BarrierSpawner Server Script - REVISED
    Bug fix: 
    1. Decal tween issue (index mismatch)
    2. Collect decal per block, match index dengan ripple
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GridGenerator = require(ReplicatedStorage.handler.barrier.grid)
local BarrierTween = require(ReplicatedStorage.handler.barrier.tween)

local barrierEvent = ReplicatedStorage:WaitForChild("event_remote"):WaitForChild("barrier_event")
local blokTemplate = game.ServerStorage:WaitForChild("assets"):WaitForChild("BlokPart")

local RIPPLE_DELAY = 0.04
local DESTROY_RIPPLE_DELAY = 0.04

--[[
    State: Menyimpan block + decal per index untuk matching ripple
    {
        [areaName] = {
            areaRef = Part,
            gridGenerator = GridGenerator,
            frames = {CFrame},
            blocksData = {
                [1] = {block = Part, decals = {Decal array}},
                [2] = {block = Part, decals = {Decal array}},
                ...
            },
            playersInRadius = {Player array},
            isLoaded = false,
        }
    }
]]
local barrierState = {}

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
                blocksData = {},
                playersInRadius = {},
                isLoaded = false,
            }
            
            print("BarrierSpawner: Area '" .. areaName .. "' initialized")
        end
    end
end

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
        .. info.gridX .. "x" .. info.gridZ 
        .. " (" .. info.totalBlocks .. " blocks)")
end

--[[
    Spawn blocks - REVISED: Collect decal per block index
]]
local function spawnBlocks(areaName: string, playerPos: Vector3)
    local state = barrierState[areaName]
    if not state or state.isLoaded then
        return
    end
    
    generateGrid(areaName)
    
    local areaRef = state.areaRef
    local frames = state.frames
    
    print("BarrierSpawner: Spawning " .. #frames .. " blocks untuk '" .. areaName .. "'")
    
    -- Clone block dan kumpulkan decal per index
    for i, frame in ipairs(frames) do
        local newBlock = blokTemplate:Clone()
        newBlock.CFrame = frame
        newBlock.CanCollide = false  -- ✅ Tidak collision saat tween
        newBlock.Parent = areaRef
        
        -- ✅ PENTING: Kumpulkan decal dari block ini
        local blockDecals = {}
        for _, child in ipairs(newBlock:GetDescendants()) do
            if child:IsA("Decal") then
                child.Transparency = 1  -- Start hidden
                table.insert(blockDecals, child)
            end
        end
        
        -- ✅ Simpan block + decals dengan index yang sama
        state.blocksData[i] = {
            block = newBlock,
            decals = blockDecals,
        }
    end
    
    state.isLoaded = true
    
    -- ✅ Tween HANYA decals, dengan index yang tepat
    if state.gridGenerator and #state.frames > 0 then
        local sortedIndices = state.gridGenerator:sortFramesByDistance(playerPos, frames)
        
        -- Kumpulkan semua decals dalam urutan index
        local allDecals = {}
        for i, blockData in ipairs(state.blocksData) do
            for _, decal in ipairs(blockData.decals) do
                table.insert(allDecals, decal)
            end
        end
        
        if #allDecals > 0 then
            BarrierTween.fadeInRippleDecals(allDecals, sortedIndices, RIPPLE_DELAY, function()
                print("BarrierSpawner: '" .. areaName .. "' fully loaded")
            end)
        end
    end
end

--[[
    Despawn blocks - REVISED: Tween decal dengan index tepat
]]
local function despawnBlocks(areaName: string, playerPos: Vector3)
    local state = barrierState[areaName]
    if not state or not state.isLoaded then
        return
    end
    
    state.isLoaded = false
    
    local frames = state.frames
    local blocksData = state.blocksData
    
    if #blocksData == 0 then
        -- Destroy langsung jika kosong
        for _, blockData in ipairs(blocksData) do
            if blockData.block and blockData.block.Parent then
                blockData.block:Destroy()
            end
        end
        state.blocksData = {}
        return
    end
    
    -- Kumpulkan semua decals
    local allDecals = {}
    for i, blockData in ipairs(blocksData) do
        for _, decal in ipairs(blockData.decals) do
            table.insert(allDecals, decal)
        end
    end
    
    -- Fade out dengan ripple
    local sortedIndices = state.gridGenerator:sortFramesByDistance(playerPos, frames)
    BarrierTween.fadeOutRippleDecals(allDecals, sortedIndices, DESTROY_RIPPLE_DELAY, function()
        -- Destroy semua block setelah tween selesai
        for _, blockData in ipairs(blocksData) do
            if blockData.block and blockData.block.Parent then
                blockData.block:Destroy()
            end
        end
        state.blocksData = {}
        print("BarrierSpawner: '" .. areaName .. "' fully unloaded")
    end)
end

local function addPlayerToArea(player: Player, areaName: string)
    local state = barrierState[areaName]
    if not state then
        return
    end
    
    for _, p in ipairs(state.playersInRadius) do
        if p == player then
            return
        end
    end
    
    table.insert(state.playersInRadius, player)
    
    if #state.playersInRadius == 1 then
        print("BarrierSpawner: First player in '" .. areaName .. "', spawning")
        local playerCharacter = player.Character
        local playerPos = playerCharacter and playerCharacter.HumanoidRootPart.Position or Vector3.new(0, 0, 0)
        spawnBlocks(areaName, playerPos)
    end
end

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
    
    if #state.playersInRadius == 0 then
        print("BarrierSpawner: No players in '" .. areaName .. "', despawning")
        local playerCharacter = player.Character
        local playerPos = playerCharacter and playerCharacter.HumanoidRootPart.Position or Vector3.new(0, 0, 0)
        despawnBlocks(areaName, playerPos)
    end
end

local function setupEventListener()
    barrierEvent.OnServerEvent:Connect(function(player: Player, action: string, areaName: string, playerPos: Vector3)
        if action == "Load" then
            addPlayerToArea(player, areaName)
        elseif action == "Unload" then
            removePlayerFromArea(player, areaName)
        end
    end)
end

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