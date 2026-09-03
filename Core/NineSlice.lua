local AMT = select(2, ...)

local MEDIA_PATH = [[Interface\AddOns\AdvancedMythicTracker\Media\Frames\]]
local DEFAULT_CORNER = 16

---@alias AMTNineSliceName
---| "Control"
---| "Inset"
---| "InsetDeep"
---| "Solid"
---| "Ring"
---| "Hover"
---| "Active"
---| "ActiveThin"

---@type table<string, true>
local LAYOUTS = {
	Control = true,
	Inset = true,
	InsetDeep = true,
	Solid = true,
	Ring = true,
	Hover = true,
	Active = true,
	ActiveThin = true,
}

local CORNERS = { 1, 3, 7, 9 }

local TEXCOORDS = {
	{ 0, 0.25, 0, 0.25 },
	{ 0.25, 0.75, 0, 0.25 },
	{ 0.75, 1, 0, 0.25 },
	{ 0, 0.25, 0.25, 0.75 },
	{ 0.25, 0.75, 0.25, 0.75 },
	{ 0.75, 1, 0.25, 0.75 },
	{ 0, 0.25, 0.75, 1 },
	{ 0.25, 0.75, 0.75, 1 },
	{ 0.75, 1, 0.75, 1 },
}

---@class AMTBorder
---@field pieces Texture[]
---@field cornerSize number
local Border = {}
Border.__index = Border

---@param r number
---@param g number
---@param b number
---@param a number?
function Border:SetVertexColor(r, g, b, a)
	for index = 1, 9 do
		self.pieces[index]:SetVertexColor(r, g, b, a)
	end
end

---@param alpha number
function Border:SetAlpha(alpha)
	for index = 1, 9 do
		self.pieces[index]:SetAlpha(alpha)
	end
end

---@param shown boolean
function Border:SetShown(shown)
	for index = 1, 9 do
		self.pieces[index]:SetShown(shown)
	end
end

---Swap the art without rebuilding the slices.
---@param textureName AMTNineSliceName
function Border:SetTexture(textureName)
	if not LAYOUTS[textureName] then
		AMT.Util.Warn("unknown nineslice layout %q.", tostring(textureName))

		return
	end

	local path = MEDIA_PATH .. textureName

	for index = 1, 9 do
		self.pieces[index]:SetTexture(path)
	end
end

--@return Texture
function Border:GetCenter()
	return self.pieces[5]
end

---@param frame Frame
---@param pieces Texture[]
---@param cornerSize number
local function LayoutPieces(frame, pieces, cornerSize)
	for _, index in ipairs(CORNERS) do
		pieces[index]:SetSize(cornerSize, cornerSize)
	end

	pieces[1]:SetPoint("CENTER", frame, "TOPLEFT", 0, 0)
	pieces[3]:SetPoint("CENTER", frame, "TOPRIGHT", 0, 0)
	pieces[7]:SetPoint("CENTER", frame, "BOTTOMLEFT", 0, 0)
	pieces[9]:SetPoint("CENTER", frame, "BOTTOMRIGHT", 0, 0)

	pieces[2]:SetPoint("TOPLEFT", pieces[1], "TOPRIGHT", 0, 0)
	pieces[2]:SetPoint("BOTTOMRIGHT", pieces[3], "BOTTOMLEFT", 0, 0)
	pieces[4]:SetPoint("TOPLEFT", pieces[1], "BOTTOMLEFT", 0, 0)
	pieces[4]:SetPoint("BOTTOMRIGHT", pieces[7], "TOPRIGHT", 0, 0)
	pieces[5]:SetPoint("TOPLEFT", pieces[1], "BOTTOMRIGHT", 0, 0)
	pieces[5]:SetPoint("BOTTOMRIGHT", pieces[9], "TOPLEFT", 0, 0)
	pieces[6]:SetPoint("TOPLEFT", pieces[3], "BOTTOMLEFT", 0, 0)
	pieces[6]:SetPoint("BOTTOMRIGHT", pieces[9], "TOPRIGHT", 0, 0)
	pieces[8]:SetPoint("TOPLEFT", pieces[7], "TOPRIGHT", 0, 0)
	pieces[8]:SetPoint("BOTTOMRIGHT", pieces[9], "BOTTOMLEFT", 0, 0)

	for index = 1, 9 do
		local coords = TEXCOORDS[index]

		pieces[index]:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	end
end

---@class AMTNineSlice
local NineSlice = {}
AMT.NineSlice = NineSlice

---@param frame Frame frame to skin
---@param textureName AMTNineSliceName
---@param cornerSize number? defaults to 16
---@param layer DrawLayer? defaults to "BORDER"
---@param subLevel number?
---@return AMTBorder? border nil if the layout name is unknown
function NineSlice.Apply(frame, textureName, cornerSize, layer, subLevel)
	if not LAYOUTS[textureName] then
		AMT.Util.Warn("unknown nineslice layout %q.", tostring(textureName))

		return nil
	end

	local size = cornerSize or DEFAULT_CORNER
	local path = MEDIA_PATH .. textureName
	local pieces = {}

	for index = 1, 9 do
		local piece = frame:CreateTexture(nil, layer or "BORDER", nil, subLevel)

		piece:SetTexture(path)
		piece:SetTexelSnappingBias(0)
		piece:SetSnapToPixelGrid(false)
		piece:ClearAllPoints()

		pieces[index] = piece
	end

	LayoutPieces(frame, pieces, size)

	return setmetatable({ pieces = pieces, cornerSize = size }, Border)
end

---@param textureName string
---@return string
function NineSlice.Path(textureName)
	return MEDIA_PATH .. textureName
end
