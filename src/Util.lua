local Util = {}

function Util.FuzzyColorMatch(a: Color3, b: Color3, ep: number)
	if math.abs(a.R - b.R) < ep and math.abs(a.G - b.G) < ep and math.abs(a.B - b.B) < ep then
		return true
	else
		return false
	end
end

return Util
