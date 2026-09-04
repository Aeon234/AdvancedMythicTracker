local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

StaticPopupDialogs["AMT_PROFILE_OVERWRITE"] = {
	text = L["A profile named %q already exists. Replace it with the imported one?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(_, payload)
		AMT.Profiles.ApplyImport(payload)
		AMT.Util.Print("%s", L["Profile imported."])
		Options.NotifyValueChanged()
	end,
	hideOnEscape = true,
	whileDead = true,
	timeout = 0,
}

Options.RegisterPage({
	id = "profiles.importexport",
	parent = "profiles",
	order = 20,
	name = L["Import / Export"],
	Build = function(page)
		page:SetHeader({
			description = L["Share a profile, or take a snapshot before changing style."],
			divider = "thin",
		})

		page:AddWidgets({
			{
				type = "textarea",
				label = L["Export"],
				readOnly = true,
				get = function()
					return AMT.Profiles.Export(AMT.Profiles.activeName) or ""
				end,
			},

			{
				type = "note",
				label = "",
				text = L["Click the box to select the string, then copy it. It encodes the active profile only."],
			},
		})

		local input = page:AddWidget({ type = "textarea", label = L["Import"] })

		page:AddWidgets({
			{
				type = "button",
				label = "",
				text = L["Import Profile"],
				set = function()
					if not input then
						return
					end

					local payload = AMT.Profiles.Decode(input:GetText())

					if not payload then
						return
					end

					if AMT.Profiles.Exists(payload.name) then
						StaticPopup_Show("AMT_PROFILE_OVERWRITE", payload.name, nil, payload)

						return
					end

					AMT.Profiles.ApplyImport(payload)
					AMT.Util.Print("%s", L["Profile imported."])
				end,
				disabled = function()
					return input == nil or input:GetText():trim() == ""
				end,
			},
		})
	end,
})
