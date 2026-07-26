--[[
    GridGenerator Module
    Menghasilkan grid CFrame berdasarkan ukuran acuan dan template block.
    Menghitung jumlah block dan posisinya menggunakan math.ceil untuk fleksibilitas.
]]

local GridGenerator = {}
GridGenerator.__index = GridGenerator

--[[
    Membuat instance GridGenerator baru
    @param areaSize (Vector3) - Ukuran area acuan
    @param blockSize (Vector3) - Ukuran template block
    @param areaPosition (CFrame) - Posisi center area
    @return GridGenerator instance
]]
function GridGenerator.new(areaSize: Vector3, blockSize: Vector3, areaPosition: CFrame)
	local self = setmetatable({}, GridGenerator)

	self.areaSize = areaSize
	self.blockSize = blockSize
	self.areaPosition = areaPosition

	-- Hitung grid dimensions
	self.gridX = math.ceil(areaSize.X / blockSize.X)
	self.gridY = math.ceil(areaSize.Y / blockSize.Y)
	self.gridZ = math.ceil(areaSize.Z / blockSize.Z)

	self.totalBlocks = self.gridX * self.gridY * self.gridZ

	return self
end

--[[
    Menghasilkan daftar CFrame untuk setiap block dalam grid
    @return table - Array of CFrame untuk setiap block
]]
function GridGenerator:generateGrid(): {CFrame}
	local frames: {CFrame} = {}

	-- Hitung offset dari center area ke corner minimal
	local halfAreaSize = self.areaSize / 2
	local startOffset = CFrame.new(-halfAreaSize.X + self.blockSize.X / 2, 
		-halfAreaSize.Y + self.blockSize.Y / 2,
		-halfAreaSize.Z + self.blockSize.Z / 2)

	local blockIndex = 1

	-- Iterate melalui grid 3D
	for x = 0, self.gridX - 1 do
		for y = 0, self.gridY - 1 do
			for z = 0, self.gridZ - 1 do
				-- Hitung offset block dari start point
				local offsetX = x * self.blockSize.X
				local offsetY = y * self.blockSize.Y
				local offsetZ = z * self.blockSize.Z

				-- Gabungkan area position dengan offset
				local blockFrame = self.areaPosition * startOffset * CFrame.new(offsetX, offsetY, offsetZ)

				frames[blockIndex] = blockFrame
				blockIndex += 1
			end
		end
	end

	return frames
end

--[[
    Mengembalikan informasi grid
    @return table - Info grid (dimensions, totalBlocks, areaSize, blockSize)
]]
function GridGenerator:getInfo(): {[string]: any}
	return {
		gridX = self.gridX,
		gridY = self.gridY,
		gridZ = self.gridZ,
		totalBlocks = self.totalBlocks,
		areaSize = self.areaSize,
		blockSize = self.blockSize,
	}
end

--[[
    Mencari block terdekat ke posisi player
    @param playerPosition (Vector3) - Posisi player
    @param frames (table) - Array of CFrame dari generateGrid()
    @return number - Index block terdekat (1-indexed)
]]
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

--[[
    Mengurutkan block berdasarkan jarak ke player (untuk ripple effect)
    @param playerPosition (Vector3) - Posisi player
    @param frames (table) - Array of CFrame
    @return table - Array of indices yang sudah diurutkan berdasarkan jarak
]]
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