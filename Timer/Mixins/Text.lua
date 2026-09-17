local AMT = select(2, ...)

---@alias AMTFontOutline
---| ""
---| "OUTLINE"
---| "THICKOUTLINE"
---| "MONOCHROME"
---| "MONOCHROME, OUTLINE"
---| "MONOCHROME, THICKOUTLINE"
---| "SLUG"
---| "SLUG, OUTLINE"
---| "SLUG, THICKOUTLINE"

---@class AMTTextStyle
---@field font string LSM font name
---@field size number
---@field outline AMTFontOutline
---@field color number[] {r, g, b, a}
---@field shadowColor number[]?
---@field shadowOffset number[]? {x, y}
---@field justify "LEFT"|"CENTER"|"RIGHT"?

---@class AMTTextMixin : FontString
local Text = {}
AMT.Mixins.Text = Text

---@param style AMTTextStyle
function Text:ApplyStyle(style)
	local font = AMT.Media.Font(style.font)

	if font then
		self:SetFont(font, style.size, style.outline) ---@diagnostic disable-line: type-mismatch
	end

	local color = style.color
	self:SetTextColor(color[1], color[2], color[3], color[4])

	local shadow = style.shadowColor

	if shadow then
		local offset = style.shadowOffset

		self:SetShadowColor(shadow[1], shadow[2], shadow[3], shadow[4])
		self:SetShadowOffset(offset and offset[1] or 0, offset and offset[2] or 0)
	else
		self:SetShadowColor(0, 0, 0, 0)
	end

	if style.justify then
		self:SetJustifyH(style.justify)
	end
end

---@param format string
---@param ... any
function Text:SetFormatted(format, ...)
	self:SetText(format:format(...))
end

---@param parent Frame
---@param layer DrawLayer?
---@return AMTTextMixin
function AMT.Mixins.NewText(parent, layer)
	local text = parent:CreateFontString(nil, layer or "OVERLAY")

	Mixin(text, Text)

	return text
end

---@param color number[]
function Text:SetColor(color)
	self:SetTextColor(color[1], color[2], color[3], color[4])
end
