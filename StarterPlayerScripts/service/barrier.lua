-- FILE 2: StarterPlayerScripts/service/barrier.lua
--[[
    BarrierController LocalScript
    Deteksi jarak player dan kirim signal ke server.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local barrierEvent = ReplicatedStorage:WaitForChild("event_remote"):WaitForChild("barrier_event")
local player = Players.LocalPlayer
local playerCharacter = player.Character or player.CharacterAdded:Wait()

-- Config
local LOAD_RADIUS = 60
local CHECK_INTERVAL = 0.5
local DEBOUNCE_TIME = 1.0  -- ✅ DIPERBAIKI: Dari 0.2 ke 1.0 detik

--[[
    State tracking:
    {
        [areaName] = {
            isLoaded = boolean,
            lastSignalTime = number,
        }
    }
]]
local areaState = {}

--[[
    Initialize state
]]
local function initializeAreaState()
    local barrierFolder = workspace:FindFirstChild("barrier")
    
    if not barrierFolder then
        warn("BarrierController: Folder 'barrier' tidak ditemukan")
        return
    end
    
    for _, areaRef in ipairs(barrierFolder:GetChildren()) do
        if areaRef:IsA("BasePart") then
            local areaName = areaRef.Name
            areaState[areaName] = {
                isLoaded = false,
                lastSignalTime = 0,
            }
        end
    end
end

--[[
    Hitung jarak
]]
local function calculateDistance(pos1: Vector3, pos2: Vector3): number
    return (pos1 - pos2).Magnitude
end

--[[
    Cek debounce
]]
local function canSignal(areaName: string): boolean
    local state = areaState[areaName]
    if not state then
        return false
    end
    
    local timeSinceLastSignal = tick() - state.lastSignalTime
    return timeSinceLastSignal >= DEBOUNCE_TIME
end

--[[
    Send Load Signal - PERBAIKI LOGIKA
]]
local function sendLoadSignal(areaName: string, playerPos: Vector3)
    local state = areaState[areaName]
    
    if state.isLoaded then
        return  -- Sudah loaded
    end
    
    if not canSignal(areaName) then
        return  -- Debounce aktif
    end
    
    state.isLoaded = true
    state.lastSignalTime = tick()
    barrierEvent:FireServer("Load", areaName, playerPos)
    print("BarrierController: LOAD '" .. areaName .. "'")
end

--[[
    Send Unload Signal - PERBAIKI LOGIKA
]]
local function sendUnloadSignal(areaName: string, playerPos: Vector3)
    local state = areaState[areaName]
    
    if not state.isLoaded then
        return  -- Sudah unloaded
    end
    
    if not canSignal(areaName) then
        return  -- Debounce aktif
    end
    
    state.isLoaded = false
    state.lastSignalTime = tick()
    barrierEvent:FireServer("Unload", areaName, playerPos)
    print("BarrierController: UNLOAD '" .. areaName .. "'")
end

--[[
    Check distance to all areas
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
            
            local distance = calculateDistance(playerPos, areaPos)
            
            -- ✅ PERBAIKI: Jelas logika load/unload
            if distance <= LOAD_RADIUS then
                sendLoadSignal(areaName, playerPos)
            else
                sendUnloadSignal(areaName, playerPos)
            end
        end
    end
end

--[[
    Setup respawn listener
]]
local function setupCharacterRespawnListener()
    player.CharacterAdded:Connect(function(newCharacter)
        playerCharacter = newCharacter
        print("BarrierController: Character respawned")
    end)
end

--[[
    Main loop
]]
local function startDistanceCheckLoop()
    while true do
        task.wait(CHECK_INTERVAL)
        if player.Character then
            checkDistancesToAreas()
        end
    end
end

-- Initialize
initializeAreaState()
setupCharacterRespawnListener()
print("BarrierController: Ready")
startDistanceCheckLoop()