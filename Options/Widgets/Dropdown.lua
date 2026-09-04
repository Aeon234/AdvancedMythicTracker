local AMT = select(2, ...)

local Options = AMT.Options

local DROPDOWN_WIDTH = 200
local DROPDOWN_HEIGHT = 22

---@class AMTDropdownWidget : AMTOptionWidget
---@field control DropdownButton
local Dropdown = Options.NewWidgetPrototype("dropdown")

---@return number
function Dropdown:GetControlHeight()
	return DROPDOWN_HEIGHT
end

---@param parent Frame
function Dropdown:Create(parent)
	Options.Widget.Create(self, parent)

	local control = CreateFrame("DropdownButton", nil, self.frame, "WowStyle1DropdownTemplate")

	control:SetSize(DROPDOWN_WIDTH, DROPDOWN_HEIGHT)
	control:SetPoint("LEFT", self.frame, "LEFT", self:GetControlOffset(), 0)
	control:SetupMenu(function(_, rootDescription)
		local info = self.info

		local values = info and (info.GetValues and info.GetValues() or info.values)

		if not values then
			return
		end

		for _, entry in ipairs(values) do
			local key = entry[1]

			rootDescription:CreateRadio(entry[2], function()
				return self:GetValue() == key
			end, function()
				self:SetValue(key)
			end)
		end
	end)

	self.control = control
end

function Dropdown:Update()
	if not Options.Widget.Update(self) then
		return
	end

	self.control:SetDefaultText(tostring(self:GetValue()))
	self.control:SetEnabled(not self.disabled)
	self.control:GenerateMenu()
end
