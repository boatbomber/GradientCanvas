local module = {}

local GuiPool = require(script.GuiPool)
local Util = require(script.Util)

local LOSSY = 0.07 -- Use fewer Frames at cost of image accuracy (Some values get funky, tweak carefully)

function module.new(ResX: number, ResY: number)
	local Canvas = {
		_ActiveFrames = 0,
	}

	local invX, invY = 1 / ResX, 1 / ResY

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

		Canvas._Pool = GuiPool.new(Pixel, 50)
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
	local function createGradient(colorData, x, pixelStart, pixelCount, colorCount)
		local Sequence = table.create(#colorData)
		for i, data in ipairs(colorData) do
			Sequence[i] = ColorSequenceKeypoint.new(data.p / colorCount, data.c)
		end

		local Frame = Canvas._Pool:Get()
		Frame.Position = UDim2.fromScale(invX * (x - 1), pixelStart * invY)
		Frame.Size = UDim2.fromScale(invX, invY * pixelCount)
		Frame.Gradient.Color = ColorSequence.new(Sequence)
		Frame.Parent = Container

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
		self._Grid[x][y] = color
	end

	function Canvas:Clear()
		for _, object in ipairs(Container:GetChildren()) do
			self._Pool:Return(object)
		end
		self._ActiveFrames = 0
	end

	function Canvas:Render()
		self:Clear()

		for x, Column in ipairs(self._Grid) do
			local Compressed = {
				{ p = 0, c = Column[1] },
			}

			local pixelStart, pixelCount, colorCount = 0, 0, 0
			local lastColor = Column[1]

			-- Compress into gradients
			for y, Color in ipairs(Column) do
				pixelCount += 1
				if lastColor ~= Color then
					colorCount += 1

					if not Util.FuzzyColorMatch(lastColor, Color, LOSSY) then
						table.insert(Compressed, { p = colorCount - 0.001, c = lastColor })
					end
					table.insert(Compressed, { p = colorCount, c = Color })

					lastColor = Color

					if #Compressed > 18 then
						createGradient(Compressed, x, pixelStart, pixelCount, colorCount)

						pixelStart = y
						pixelCount = 0
						colorCount = 0
						table.clear(Compressed)
						Compressed[1] = { p = 0, c = Color }
					end
				end
			end

			if #Compressed < 2 then
				colorCount += 1
				table.insert(Compressed, { p = colorCount, c = Column[#Column] })
			end
			createGradient(Compressed, x, pixelStart, pixelCount, colorCount)
		end
	end

	return Canvas
end

return module
