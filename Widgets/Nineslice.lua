local AMT = select(2, ...) ---@class AMT
local API = AMT.API ---@class API

local function DisableSharpening(texture)
	texture:SetTexelSnappingBias(0)
	texture:SetSnapToPixelGrid(false)
end
API.DisableSharpening = DisableSharpening

local TEXTURE_ROOT = "Interface/AddOns/" .. AMT.addonName .. "/Media/Textures/"

---Grabs the texture based on provided type and texture
---@param texture string Texture name
---@return string
local function GetTexturePath(texture)
	return TEXTURE_ROOT .. texture
end
API.GetTexturePath = GetTexturePath

---@alias NineSliceLayoutName "Brown"|"Clear"|"Transparent"|"Highlight"
---@class NineSliceLayouts : table<NineSliceLayoutName, string>
local NineSliceLayouts = {
	Brown = "Frame_Brown",
	Clear = "Frame_Clear",
	Transparent = "Frame_Transparent",
	Highlight = "Frame_Highlight",
}

---@class SliceFrame : Frame  A Frame whose background is drawn from 3 or 9 tiled texture pieces.
local SliceFrameMixin = {}

---Create the slice texture pieces and lay them out. Called once during construction.
---@param n integer Number of slices: 3 (horizontal capsule) or 9 (box).
function SliceFrameMixin:CreatePieces(n)
	if self.pieces then
		return
	end
	self.pieces = {}
	self.numSlices = n

	-- 1 2 3
	-- 4 5 6
	-- 7 8 9

	for i = 1, n do
		self.pieces[i] = self:CreateTexture(nil, "BORDER")
		DisableSharpening(self.pieces[i])
		self.pieces[i]:ClearAllPoints()
	end

	self:SetCornerSize(16)

	if n == 3 then
		self.pieces[1]:SetPoint("CENTER", self, "LEFT", 0, 0)
		self.pieces[3]:SetPoint("CENTER", self, "RIGHT", 0, 0)
		self.pieces[2]:SetPoint("TOPLEFT", self.pieces[1], "TOPRIGHT", 0, 0)
		self.pieces[2]:SetPoint("BOTTOMRIGHT", self.pieces[3], "BOTTOMLEFT", 0, 0)

		self.pieces[1]:SetTexCoord(0, 0.25, 0, 1)
		self.pieces[2]:SetTexCoord(0.25, 0.75, 0, 1)
		self.pieces[3]:SetTexCoord(0.75, 1, 0, 1)
		return
	end

	self.pieces[1]:SetPoint("CENTER", self, "TOPLEFT", 0, 0)
	self.pieces[3]:SetPoint("CENTER", self, "TOPRIGHT", 0, 0)
	self.pieces[7]:SetPoint("CENTER", self, "BOTTOMLEFT", 0, 0)
	self.pieces[9]:SetPoint("CENTER", self, "BOTTOMRIGHT", 0, 0)
	self.pieces[2]:SetPoint("TOPLEFT", self.pieces[1], "TOPRIGHT", 0, 0)
	self.pieces[2]:SetPoint("BOTTOMRIGHT", self.pieces[3], "BOTTOMLEFT", 0, 0)
	self.pieces[4]:SetPoint("TOPLEFT", self.pieces[1], "BOTTOMLEFT", 0, 0)
	self.pieces[4]:SetPoint("BOTTOMRIGHT", self.pieces[7], "TOPRIGHT", 0, 0)
	self.pieces[5]:SetPoint("TOPLEFT", self.pieces[1], "BOTTOMRIGHT", 0, 0)
	self.pieces[5]:SetPoint("BOTTOMRIGHT", self.pieces[9], "TOPLEFT", 0, 0)
	self.pieces[6]:SetPoint("TOPLEFT", self.pieces[3], "BOTTOMLEFT", 0, 0)
	self.pieces[6]:SetPoint("BOTTOMRIGHT", self.pieces[9], "TOPRIGHT", 0, 0)
	self.pieces[8]:SetPoint("TOPLEFT", self.pieces[7], "TOPRIGHT", 0, 0)
	self.pieces[8]:SetPoint("BOTTOMRIGHT", self.pieces[9], "BOTTOMLEFT", 0, 0)

	self.pieces[1]:SetTexCoord(0, 0.25, 0, 0.25)
	self.pieces[2]:SetTexCoord(0.25, 0.75, 0, 0.25)
	self.pieces[3]:SetTexCoord(0.75, 1, 0, 0.25)
	self.pieces[4]:SetTexCoord(0, 0.25, 0.25, 0.75)
	self.pieces[5]:SetTexCoord(0.25, 0.75, 0.25, 0.75)
	self.pieces[6]:SetTexCoord(0.75, 1, 0.25, 0.75)
	self.pieces[7]:SetTexCoord(0, 0.25, 0.75, 1)
	self.pieces[8]:SetTexCoord(0.25, 0.75, 0.75, 1)
	self.pieces[9]:SetTexCoord(0.75, 1, 0.75, 1)
end

---Set the pixel size of the corner (9-slice) or end-cap (3-slice) pieces.
---@param a number Corner size in pixels.
function SliceFrameMixin:SetCornerSize(a)
	self.cornerSize = a
	if self.numSlices == 3 then
		self.pieces[1]:SetSize(a, 2 * a)
		self.pieces[3]:SetSize(a, 2 * a)
	else
		self.pieces[1]:SetSize(a, a)
		self.pieces[3]:SetSize(a, a)
		self.pieces[7]:SetSize(a, a)
		self.pieces[9]:SetSize(a, a)
	end
end

---Set the corner size as a multiple of the default 16px.
---@param scale number Multiplier applied to the 16px base corner size.
function SliceFrameMixin:SetCornerSizeByScale(scale)
	self:SetCornerSize(16 * scale)
end

---Set the texture file used by every slice piece.
---@param tex string|integer Texture file path or fileID.
function SliceFrameMixin:SetTexture(tex)
	for i = 1, #self.pieces do
		self.pieces[i]:SetTexture(tex)
	end
end

---Toggle texture sharpening (pixel-grid snapping) on every slice piece.
---@param state boolean true to disable sharpening, false to enable.
function SliceFrameMixin:SetDisableSharpening(state)
	for i = 1, #self.pieces do
		self.pieces[i]:SetSnapToPixelGrid(not state)
	end
end

---Tint every slice piece with a vertex color.
---@param r number Red, 0-1.
---@param g number Green, 0-1.
---@param b number Blue, 0-1.
function SliceFrameMixin:SetColor(r, g, b)
	for i = 1, #self.pieces do
		self.pieces[i]:SetVertexColor(r, g, b)
	end
end

---Anchor this frame to fully cover its parent, optionally with extra padding.
---@param padding? number Pixels to extend beyond the parent on each side (default 0).
function SliceFrameMixin:CoverParent(padding)
	padding = padding or 0
	local parent = self:GetParent()
	if parent then
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", parent, "TOPLEFT", -padding, padding)
		self:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", padding, -padding)
	end
end

---Show or hide every slice piece (the background).
---@param state boolean
function SliceFrameMixin:ShowBackground(state)
	for _, piece in ipairs(self.pieces) do
		piece:SetShown(state)
	end
end

---Create a 9-slice background frame.
---@param parent Frame Parent frame.
---@param layoutName NineSliceLayoutName Border/background art layout (falls back to "WhiteBorder").
---@param frameName? string Global frame name (default nil/anonymous).
---@param frameType? string CreateFrame frame type, e.g. "Frame" (default) or "Button".
---@return SliceFrame
local function CreateNineSliceFrame(parent, layoutName, frameName, frameType)
	local texFile = NineSliceLayouts[layoutName] or NineSliceLayouts.Brown

	frameType = frameType or "Frame"

	local f = CreateFrame(frameType, frameName, parent)
	Mixin(f, SliceFrameMixin)
	f:CreatePieces(9)
	f:SetTexture(GetTexturePath(texFile))
	f:ClearAllPoints()
	return f
end

API.CreateNineSliceFrame = CreateNineSliceFrame
