local module = {}

local OFF_SCREEN = UDim2.fromOffset(0, 3000)

function module.new(original: GuiObject, initSize: number?)
	local Pool = {
		_Available = table.create(initSize or 50),
		_Source = original:Clone(),
	}

	for i = 1, initSize or 50 do
		Pool._Available[i] = Pool._Source:Clone()
	end

	function Pool:Get()
		local index = #self._Available
		if index > 0 then
			local object = self._Available[index]
			table.remove(self._Available, index)
			return object
		end

		return self._Source:Clone()
	end

	function Pool:Return(object: GuiObject)
		object.Position = OFF_SCREEN
		table.insert(self._Available, object)
	end

	return Pool
end

return module
