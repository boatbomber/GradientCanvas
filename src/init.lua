local module = {}

local GuiPool = require(script.GuiPool)
local Util = require(script.Util)

local EMPTY_TABLE = {}

function module.new(ResX: number, ResY: number)
	local Canvas = {
		_ActiveFrames = 0,
		_ColumnFrames = {},
		_UpdatedColumns = {},
	}

	local invX, invY = 1 / ResX, 1 / ResY
	local diff = 0.015
	local lossy = math.clamp(diff + ResY / 250, 0.02, 1)

	-- Generate initial grid of color data
	local Grid = table.create(ResX)
	for x = 1, ResX do
		local Col = table.create(ResY)
		for y = 1, ResY do
			Col[y] = Color3.new(1, 1, 1)
		end
		Grid[x] = Col
	end
	Canvas._Grid = Grid

	-- Create a pool of Frame instances with Gradients
	do
		local Pixel = Instance.new("Frame")
		Pixel.BackgroundColor3 = Color3.new(1, 1, 1)
		Pixel.BorderSizePixel = 0
		Pixel.Name = "Pixel"
		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Parent = Pixel

		Canvas._Pool = GuiPool.new(Pixel, ResX)
		Pixel:Destroy()
	end

	-- Create GUIs
	local Gui = Instance.new("Frame")
	Gui.Name = "GreedyCanvas"
	Gui.BackgroundTransparency = 1
	Gui.ClipsDescendants = true
	Gui.Size = UDim2.fromScale(1, 1)
	Gui.Position = UDim2.fromScale(0.5, 0.5)
	Gui.AnchorPoint = Vector2.new(0.5, 0.5)

	local AspectRatio = Instance.new("UIAspectRatioConstraint")
	AspectRatio.AspectRatio = ResX / ResY
	AspectRatio.Parent = Gui

	local Container = Instance.new("Folder")
	Container.Name = "FrameContainer"
	Container.Parent = Gui

	-- Define API
	local function createGradient(colorData, x, pixelStart, pixelCount)
		local Sequence = table.create(#colorData)
		for i, data in ipairs(colorData) do
			Sequence[i] = ColorSequenceKeypoint.new(data.p / pixelCount, data.c)
		end

		local Frame = Canvas._Pool:Get()
		Frame.Position = UDim2.fromScale(invX * (x - 1), pixelStart * invY)
		Frame.Size = UDim2.fromScale(invX, invY * pixelCount)
		Frame.Gradient.Color = ColorSequence.new(Sequence)
		Frame.Parent = Container

		if Canvas._ColumnFrames[x] == nil then
			Canvas._ColumnFrames[x] = { Frame }
		else
			table.insert(Canvas._ColumnFrames[x], Frame)
		end

		Canvas._ActiveFrames += 1
	end

	function Canvas:Destroy()
		table.clear(Canvas._Grid)
		table.clear(Canvas)
		Gui:Destroy()
	end

	function Canvas:SetParent(parent: Instance)
		Gui.Parent = parent
	end

	function Canvas:SetPixel(x: number, y: number, color: Color3)
		local Col = self._Grid[x]

		if Col[y] ~= color then
			Col[y] = color
			self._UpdatedColumns[x] = Col
		end
	end

	function Canvas:Clear(x: number?)
		if x then
			for _, object in ipairs(self._ColumnFrames[x] or EMPTY_TABLE) do
				self._Pool:Return(object)
				self._ActiveFrames -= 1
			end
			table.clear(self._ColumnFrames[x] or EMPTY_TABLE)
		else
			for _, object in ipairs(Container:GetChildren()) do
				self._Pool:Return(object)
			end
			self._ActiveFrames = 0
			table.clear(self._ColumnFrames)
		end
	end

	function Canvas:Render()
		for x, Column in pairs(self._UpdatedColumns) do
			self:Clear(x)

			local Compressed = {
				{ p = 0, c = Column[1] },
			}

			local pixelStart, pixelCount = 0, 0
			local lastColor = Column[1]

			-- Compress into gradients
			for y, Color in ipairs(Column) do
				pixelCount += 1
				local delta = Util.DeltaRGB(lastColor, Color)
				if delta > diff then
					local offset = y - pixelStart - 1

					if delta > lossy then
						table.insert(Compressed, { p = offset - 0.02, c = lastColor })
					end
					table.insert(Compressed, { p = offset, c = Color })

					lastColor = Color

					if #Compressed > 17 then
						table.insert(Compressed, { p = pixelCount, c = Color })
						createGradient(Compressed, x, pixelStart, pixelCount)

						pixelStart = y - 1
						pixelCount = 0
						table.clear(Compressed)
						Compressed[1] = { p = 0, c = Color }
					end
				end
			end

			if pixelCount + pixelStart ~= ResY then
				pixelCount += 1
			end
			table.insert(Compressed, { p = pixelCount, c = lastColor })
			createGradient(Compressed, x, pixelStart, pixelCount)
		end

		table.clear(self._UpdatedColumns)
	end

	return Canvas
end

return module
