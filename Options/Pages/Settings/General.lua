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
				tooltip = L["Automatically slot in your key into the Keystone Interface."],
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
				tooltip = L["Shows the minimap button for Advanced Mythic Tracker."],
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

			{
				type = "checkbox",
				label = L["Addon Compartment Icon"],
				tooltip = L["Shows the addon compartment entry for Advanced Mythic Tracker."],
				get = function()
					---@type AMTAddonCompartmentModule?
					local compartment = AMT.Modules.Get("AddonCompartment")

					return compartment ~= nil and compartment:IsShown()
				end,
				set = function(value)
					---@type AMTAddonCompartmentModule?
					local compartment = AMT.Modules.Get("AddonCompartment")

					if compartment then
						compartment:SetShown(value == true)
					end
				end,
			},
		})
	end,
})
