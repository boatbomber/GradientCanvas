local module = {}

local GuiPool = require(script.GuiPool)
local Util = require(script.Util)

function module.new(ResX: number, ResY: number)
	local Canvas = {
		_Active = 0,
		_ColumnFrames = {},
		_UpdatedColumns = {},

		Threshold = 2,
		LossyThreshold = 4,
	}

	local invX, invY = 1 / ResX, 1 / ResY
	local dist = ResY * 0.03

	-- Generate initial grid of color data
	local Grid = table.create(ResX)
	for x = 1, ResX do
		Grid[x] = table.create(ResY, Color3.new(1, 1, 1))
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
	Gui.Name = "GradientCanvas"
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

		Canvas._Active += 1
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
			local column = self._ColumnFrames[x]
			if column == nil then return end

			for _, object in ipairs(column) do
				self._Pool:Return(object)
				self._Active -= 1
			end
			table.clear(column)
		else
			for _, object in ipairs(Container:GetChildren()) do
				self._Pool:Return(object)
			end
			self._Active = 0
			table.clear(self._ColumnFrames)
		end
	end

	function Canvas:Render()
		for x, column in pairs(self._UpdatedColumns) do
			self:Clear(x)

			local colorCount, colorData = 1, {
				{ p = 0, c = column[1] },
			}

			local pixelStart, lastPixel, pixelCount = 0, 0, 0
			local lastColor = column[1]

			-- Compress into gradients
			for y, color in ipairs(column) do
				pixelCount += 1

				-- Early exit to avoid the delta check on direct equality
				if lastColor == color then
					continue
				end

				local delta = Util.DeltaRGB(lastColor, color)
				if delta > self.Threshold then
					local offset = y - pixelStart - 1

					if (delta > self.LossyThreshold) or (y-lastPixel > dist) then
						table.insert(colorData, { p = offset - 0.08, c = lastColor })
						colorCount += 1
					end
					table.insert(colorData, { p = offset, c = color })
					colorCount += 1

					lastColor = color
					lastPixel = y

					if colorCount > 17 then
						table.insert(colorData, { p = pixelCount, c = color })
						createGradient(colorData, x, pixelStart, pixelCount)

						pixelStart = y - 1
						pixelCount = 0
						colorCount = 1
						table.clear(colorData)
						colorData[1] = { p = 0, c = color }
					end
				end
			end

			if pixelCount + pixelStart ~= ResY then
				pixelCount += 1
			end
			table.insert(colorData, { p = pixelCount, c = lastColor })
			createGradient(colorData, x, pixelStart, pixelCount)
		end

		table.clear(self._UpdatedColumns)
	end

	return Canvas
end

return module
