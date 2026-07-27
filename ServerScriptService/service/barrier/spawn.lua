-- FILE: ServerScriptService/spawn.lua (FIXED)
--[[
    BarrierSpawner Server Script - FINAL REVISION
    Bug fix: Proper index mapping untuk ripple effect
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GridGenerator = require(ReplicatedStorage.handler.barrier.grid)
local BarrierTween = require(ReplicatedStorage.handler.barrier.tween)

local barrierEvent = ReplicatedStorage:WaitForChild("event_remote"):WaitForChild("barrier_event")
local blokTemplate = game.ServerStorage:WaitForChild("assets"):WaitForChild("BlokPart")

local RIPPLE_DELAY = 0.05
local DESTROY_RIPPLE_DELAY = 0.05

--[[
    State structure:
    {
        [areaName] = {
            areaRef = Part,
            gridGenerator = GridGenerator,
            frames = {CFrame array},
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
    ✅ FIXED: Spawn blocks dengan proper decal management
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
    
    -- Clone block dan simpan dengan index yang match
    for i, frame in ipairs(frames) do
        local newBlock = blokTemplate:Clone()
        newBlock.CFrame = frame
        newBlock.CanCollide = false
        newBlock.Parent = areaRef
        
        -- ✅ Kumpulkan decal dari block ini
        local blockDecals = {}
        for _, child in ipairs(newBlock:GetDescendants()) do
            if child:IsA("Decal") then
                child.Transparency = 1  -- Start hidden
                table.insert(blockDecals, child)
            end
        end
        
        -- ✅ Simpan dengan index yang MATCH dengan frames
        state.blocksData[i] = {
            block = newBlock,
            decals = blockDecals,
        }
    end
    
    state.isLoaded = true
    
    -- ✅ FIXED: Ripple dengan proper index mapping
    if state.gridGenerator and #state.frames > 0 then
        local sortedIndices = state.gridGenerator:sortFramesByDistance(playerPos, frames)
        
        print("BarrierSpawner: Starting ripple for '" .. areaName .. "' with " .. #sortedIndices .. " indices")
        
        -- ✅ Tween per frame index (tidak flat array)
        task.spawn(function()
            for rippleOrder, frameIndex in ipairs(sortedIndices) do
                local blockData = state.blocksData[frameIndex]
                
                if blockData then
                    local decals = blockData.decals
                    
                    -- Wait untuk ripple delay
                    local delay = (rippleOrder - 1) * RIPPLE_DELAY
                    task.wait(delay)
                    
                    -- Fade in semua decal dari block ini
                    for _, decal in ipairs(decals) do
                        if decal and decal.Parent then
                            BarrierTween.fadeInDecal(decal)
                        end
                    end
                    
                    print("BarrierSpawner: Block " .. frameIndex .. " loaded (order " .. rippleOrder .. ")")
                end
            end
            
            print("BarrierSpawner: '" .. areaName .. "' fully loaded")
        end)
    end
end

--[[
    ✅ FIXED: Despawn dengan proper index mapping
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
        state.blocksData = {}
        return
    end
    
    local sortedIndices = state.gridGenerator:sortFramesByDistance(playerPos, frames)
    
    -- ✅ Fade out per frame index
    task.spawn(function()
        for rippleOrder, frameIndex in ipairs(sortedIndices) do
            local blockData = state.blocksData[frameIndex]
            
            if blockData then
                local decals = blockData.decals
                
                local delay = (rippleOrder - 1) * DESTROY_RIPPLE_DELAY
                task.wait(delay)
                
                for _, decal in ipairs(decals) do
                    if decal and decal.Parent then
                        BarrierTween.fadeOutDecal(decal)
                    end
                end
                
                print("BarrierSpawner: Block " .. frameIndex .. " unloading (order " .. rippleOrder .. ")")
            end
        end
        
        -- Destroy semua block setelah semua decal selesai fade out
        task.wait(0.6)  -- Wait untuk fade out tween selesai
        
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
        print("BarrierSpawner: First player in '" .. areaName .. "'")
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
        print("BarrierSpawner: No players in '" .. areaName .. "'")
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