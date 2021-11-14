local Util = {}

-- D65/2°
local Xr = 95.047
local Yr = 100.0
local Zr = 108.883
local labCache = {}
function Util.RGBtoLAB(c)
	if labCache[c] then
		return table.unpack(labCache[c])
	end

	local X, Y, Z
	do -- Convert RGB to XYZ
		local r, g, b = c.R, c.G, c.B

		if r > 0.04045 then
			r = ((r + 0.055) / 1.055) ^ 2.4
		else
			r /= 12.92
		end

		if g > 0.04045 then
			g = ((g + 0.055) / 1.055) ^ 2.4
		else
			g /= 12.92
		end

		if b > 0.04045 then
			b = ((b + 0.055) / 1.055) ^ 2.4
		else
			b /= 12.92
		end

		r *= 100
		g *= 100
		b *= 100

		X = 0.4124 * r + 0.3576 * g + 0.1805 * b
		Y = 0.2126 * r + 0.7152 * g + 0.0722 * b
		Z = 0.0193 * r + 0.1192 * g + 0.9505 * b
	end

	local l, a, b
	do -- Convert XYZ to LAB
		local xr, yr, zr = X / Xr, Y / Yr, Z / Zr

		if xr > 0.008856 then
			xr = xr ^ (1 / 3)
		else
			xr = ((7.787 * xr) + 16 / 116.0)
		end

		if yr > 0.008856 then
			yr = yr ^ (1 / 3)
		else
			yr = ((7.787 * yr) + 16 / 116.0)
		end

		if zr > 0.008856 then
			zr = zr ^ (1 / 3)
		else
			zr = ((7.787 * zr) + 16 / 116.0)
		end

		l, a, b = (116 * yr) - 16, 500 * (xr - yr), 200 * (yr - zr)
	end

	labCache[c] = { l, a, b }

	return l, a, b
end

function Util.DeltaRGB(a: Color3, b: Color3)
	local l1, a1, b1 = Util.RGBtoLAB(a)
	local l2, a2, b2 = Util.RGBtoLAB(b)

	local delta = (l2 - l1) ^ 2 + (a2 - a1) ^ 2 + (b2 - b1) ^ 2
	if delta < 900 then
		return 0.03
	else
		return delta / 40000
	end
end

return Util
