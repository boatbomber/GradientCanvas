# GreedyCanvas
A canvas renderer using greedy gradients to draw efficiently in Roblox

![image](https://user-images.githubusercontent.com/40185666/141372376-4b093c65-546e-438c-80e6-72ce05a7c0eb.png)

## API

```Lua
GreedyCanvas.new(ResolutionX: number, ResolutionY: number)
```

returns a new canvas of the specified resolution


```Lua
GreedyCanvas:SetParent(Parent: Instance)
```

parents the canvas GUI to the passed Instance

```Lua
GreedyCanvas:SetPixel(X: number, Y: number, Color: Color3)
```

Sets the color of the canvas specified pixel

```Lua
GreedyCanvas:Render()
```

renders the canvas based on the set pixels

**(It will not automatically render, you must call this method when you've completed your pixel updates)**

```Lua
GreedyCanvas:Clear()
```

clears the canvas render


```Lua
GreedyCanvas:Destroy()
```

cleans up the canvas and its GUIs
