local _, AMT = ...
local API = AMT.API
local IS_TWW = AMT.IsGame_11_0_0

local tremove = table.remove

do -- Table
	local function Mixin(object, ...)
		for i = 1, select("#", ...) do
			local mixin = select(i, ...)
			for k, v in pairs(mixin) do
				object[k] = v
			end
		end
		return object
	end
	API.Mixin = Mixin

	local function CreateFromMixins(...)
		return Mixin({}, ...)
	end
	API.CreateFromMixins = CreateFromMixins

	local function RemoveValueFromList(tbl, v)
		for i = 1, #tbl do
			if tbl[i] == v then
				tremove(tbl, i)
				return true
			end
		end
	end
	API.RemoveValueFromList = RemoveValueFromList

	local function ReverseList(list)
		if not list then
			return
		end
		local tbl = {}
		local n = 0
		for i = #list, 1, -1 do
			n = n + 1
			tbl[n] = list[i]
		end
		return tbl
	end
	API.ReverseList = ReverseList
end

do --Pixel
	local GetPhysicalScreenSize = GetPhysicalScreenSize

	local function GetPixelForScale(scale, pixelSize)
		local SCREEN_WIDTH, SCREEN_HEIGHT = GetPhysicalScreenSize()
		if pixelSize then
			return pixelSize * (768 / SCREEN_HEIGHT) / scale
		else
			return (768 / SCREEN_HEIGHT) / scale
		end
	end
	API.GetPixelForScale = GetPixelForScale

	local function GetPixelForWidget(widget, pixelSize)
		local scale = widget:GetEffectiveScale()
		return GetPixelForScale(scale, pixelSize)
	end
	API.GetPixelForWidget = GetPixelForWidget
end

do --Math
	local function Clamp(value, min, max)
		if value > max then
			return max
		elseif value < min then
			return min
		end
		return value
	end
	API.Clamp = Clamp

	local function Lerp(startValue, endValue, amount)
		return (1 - amount) * startValue + amount * endValue
	end
	API.Lerp = Lerp

	local function GetPointsDistance2D(x1, y1, x2, y2)
		return sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
	end
	API.GetPointsDistance2D = GetPointsDistance2D

	local function Round(n)
		return floor(n + 0.5)
	end
	API.Round = Round
end

do --Game UI
	local function IsInEditMode()
		return EditModeManagerFrame and EditModeManagerFrame:IsShown()
	end
	API.IsInEditMode = IsInEditMode
end

do --System
	if IS_TWW then
		local GetMouseFoci = GetMouseFoci

		local function GetMouseFocus()
			local objects = GetMouseFoci()
			return objects and objects[1]
		end
		API.GetMouseFocus = GetMouseFocus
	else
		API.GetMouseFocus = GetMouseFocus
	end
end
