-- FILE 1: ReplicatedStorage/handler/barrier/grid.lua
--[[
    GridGenerator Module - REVISED
    Hanya generate grid di X dan Z (horizontal)
    Tidak generate ke atas (Y)
]]

local GridGenerator = {}
GridGenerator.__index = GridGenerator

function GridGenerator.new(areaSize: Vector3, blockSize: Vector3, areaPosition: CFrame)
    local self = setmetatable({}, GridGenerator)
    
    self.areaSize = areaSize
    self.blockSize = blockSize
    self.areaPosition = areaPosition
    
    -- Hitung grid dimensions - HANYA X dan Z (horizontal)
    self.gridX = math.ceil(areaSize.X / blockSize.X)
    self.gridZ = math.ceil(areaSize.Z / blockSize.Z)
    self.gridY = 1  -- ✅ PERBAIKAN: Hanya 1 layer (tidak ke atas)
    
    self.totalBlocks = self.gridX * self.gridZ
    
    return self
end

function GridGenerator:generateGrid(): {CFrame}
    local frames: {CFrame} = {}
    
    -- Hitung offset dari center area ke corner minimal
    local halfAreaSize = self.areaSize / 2
    -- ✅ PERBAIKAN: Offset Y = 0 (biar di tengah vertical)
    local startOffset = CFrame.new(-halfAreaSize.X + self.blockSize.X / 2, 
        0,
        -halfAreaSize.Z + self.blockSize.Z / 2)
    
    local blockIndex = 1
    
    -- ✅ PERBAIKAN: Loop HANYA X dan Z (horizontal), Y fixed di 1
    for x = 0, self.gridX - 1 do
        for z = 0, self.gridZ - 1 do
            local offsetX = x * self.blockSize.X
            local offsetZ = z * self.blockSize.Z
            
            local blockFrame = self.areaPosition * startOffset * CFrame.new(offsetX, 0, offsetZ)
            
            frames[blockIndex] = blockFrame
            blockIndex += 1
        end
    end
    
    return frames
end

function GridGenerator:getInfo(): {[string]: any}
    return {
        gridX = self.gridX,
        gridZ = self.gridZ,
        gridY = self.gridY,
        totalBlocks = self.totalBlocks,
        areaSize = self.areaSize,
        blockSize = self.blockSize,
    }
end

function GridGenerator:findNearestBlockIndex(playerPosition: Vector3, frames: {CFrame}): number
    local nearestIndex = 1
    local nearestDistance = math.huge
    
    for i, frame in ipairs(frames) do
        local blockPos = frame.Position
        local distance = (blockPos - playerPosition).Magnitude
        
        if distance < nearestDistance then
            nearestDistance = distance
            nearestIndex = i
        end
    end
    
    return nearestIndex
end

function GridGenerator:sortFramesByDistance(playerPosition: Vector3, frames: {CFrame}): {number}
    local indexed: {[number]: {index: number, distance: number}} = {}
    
    for i, frame in ipairs(frames) do
        local distance = (frame.Position - playerPosition).Magnitude
        table.insert(indexed, {index = i, distance = distance})
    end
    
    table.sort(indexed, function(a, b)
        return a.distance < b.distance
    end)
    
    local result: {number} = {}
    for _, item in ipairs(indexed) do
        table.insert(result, item.index)
    end
    
    return result
end

return GridGenerator