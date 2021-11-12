local Util = {}

function Util.DeltaRGB(a: Color3, b: Color3)
	local r1, g1, b1 = a.R,a.G,a.B
	local r2, g2, b2 = b.R,b.G,b.B
	local drp2 = (r1 - r2)^2
	local dgp2 = (g1 - g2)^2
	local dbp2 = (b1 - b2)^2
	local t = (r1 + r2) / 2

	return math.sqrt(2 * drp2 + 4 * dgp2 + 3 * dbp2 + t * (drp2 - dbp2) / 256) / 3
end

return Util
