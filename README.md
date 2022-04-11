!! **Deprecated in favor of [ViewportCanvas](https://github.com/boatbomber/ViewportCanvas) due to hitting Roblox UIGradient cap. If you are doing animations, however, it is still recommended to use GradientCanvas since Roblox takes too long to render ViewportCanvas and can't do animated images.**

# GradientCanvas
A canvas renderer using greedy gradients to draw efficiently in Roblox

![image](https://user-images.githubusercontent.com/40185666/141671225-96d248d2-3795-4411-8ec6-e74a7c3157e3.png)

![image](https://user-images.githubusercontent.com/40185666/141671239-566f17bb-0378-4e21-b819-b8f949e9dfcf.png)


## API

```Lua
GradientCanvas.new(ResolutionX: number, ResolutionY: number)
```

returns a new canvas of the specified resolution


```Lua
GradientCanvas:SetParent(Parent: Instance)
```

parents the canvas GUI to the passed Instance

```Lua
GradientCanvas:SetPixel(X: number, Y: number, Color: Color3)
```

Sets the color of the canvas specified pixel

```Lua
GradientCanvas:Render()
```

renders the canvas based on the set pixels

**(It will not automatically render, you must call this method when you've completed your pixel updates)**

```Lua
GradientCanvas:Clear()
```

clears the canvas render


```Lua
GradientCanvas:Destroy()
```

cleans up the canvas and its GUIs


----------------------

## Demonstration

```Lua
-- Frames
local Demo = script.Parent.Demo
local Ref = script.Parent.Ref

-- Resolution
local ResX, ResY = 16*6, 9*6

-- Create Canvas
local Canvas = require(script.GradientCanvas).new(ResX, ResY)
Canvas:SetParent(Demo)

-- Draw pixels
for x=1, ResX do
	for y=1, ResY do
		-- Define color
		local v = math.sin(x/ResX) * math.cos(y/ResY)
		local c = Color3.fromHSV(v, 0.9, 0.9)

		-- Set in canvas
		Canvas:SetPixel(x, y, c)

		-- Draw naively for reference
		local pixel = Instance.new("Frame")
		pixel.BorderSizePixel = 0
		pixel.BackgroundColor3 = c
		pixel.Size = UDim2.fromScale(1/ResX, 1/ResY)
		pixel.Position = UDim2.fromScale((1/ResX)*(x-1), (1/ResY)*(y-1))
		pixel.Parent = Ref.Canvas
	end
end

-- Render canvas
Canvas:Render()

-- Expose counts
Demo.TextLabel.Text = string.format("Frames Instances: %d", Canvas._ActiveFrames)
Ref.TextLabel.Text = string.format("Frames Instances: %d", ResX*ResY)
```
