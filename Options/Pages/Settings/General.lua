local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

Options.RegisterPage({
	id = "settings.general",
	parent = "settings",
	order = 10,
	name = GENERAL,
	Build = function(page)
		page:SetHeader({
			description = L["Account-wide addon behaviour. These settings are shared by every profile."],
			divider = "thin",
		})

		page:AddWidgets({
			{
				type = "checkbox",
				label = L["Auto-Slot Keystone"],
				scope = "account",
				path = "qol.autoSlotKeystone",
			},

			{
				type = "checkbox",
				label = L["Auto-Accept Gossip"],
				scope = "account",
				path = "qol.autoGossip",
				tooltip = L["Only fires on dialogue offering a single option. Hold Ctrl to suppress it."],
			},

			{
				type = "checkbox",
				label = L["Minimap Icon"],
				get = function()
					---@type AMTMinimapIconModule?
					local minimap = AMT.Modules.Get("MinimapIcon")

					return minimap ~= nil and minimap:IsShown()
				end,
				set = function(value)
					---@type AMTMinimapIconModule?
					local minimap = AMT.Modules.Get("MinimapIcon")

					if minimap then
						minimap:SetShown(value == true)
					end
				end,
			},
		})
	end,
})
