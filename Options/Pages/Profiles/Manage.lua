local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

local ACTION_NEW = "NEW"
local ACTION_DUPLICATE = "DUPLICATE"
local ACTION_RENAME = "RENAME"

StaticPopupDialogs["AMT_PROFILE_NAME"] = {
	text = "%s",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 32,
	OnAccept = function(dialog, action)
		local name = dialog:GetEditBox():GetText()

		if action == ACTION_NEW then
			AMT.Profiles.New(name)
		elseif action == ACTION_DUPLICATE then
			AMT.Profiles.Duplicate(AMT.Profiles.activeName, name)
		elseif action == ACTION_RENAME then
			AMT.Profiles.Rename(AMT.Profiles.activeName, name)
		end

		Options.NotifyValueChanged()
	end,
	EditBoxOnTextChanged = StaticPopup_StandardNonEmptyTextHandler,
	EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
	EditBoxOnEnterPressed = function(editBox)
		editBox:GetParent():GetButton1():Click()
	end,
	hideOnEscape = true,
	whileDead = true,
	timeout = 0,
}

StaticPopupDialogs["AMT_PROFILE_DELETE"] = {
	text = L["Delete the profile %q? This cannot be undone."],
	button1 = DELETE,
	button2 = CANCEL,
	OnAccept = function(_, name)
		AMT.Profiles.Delete(name)
		Options.NotifyValueChanged()
	end,
	hideOnEscape = true,
	whileDead = true,
	timeout = 0,
}

StaticPopupDialogs["AMT_PROFILE_DEFAULT"] = {
	text = L["Use %q for characters that have not chosen a profile? Characters with a profile already set keep it."],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function(_, name)
		AMT.Profiles.SetDefaultForNewCharacters(name)
		Options.NotifyValueChanged()
	end,
	hideOnEscape = true,
	whileDead = true,
	timeout = 0,
}

---@return table[]
local function ProfileValues()
	local values = {}

	for _, name in ipairs(AMT.Profiles.List()) do
		values[#values + 1] = { name, name }
	end

	return values
end

---@param action string
---@param prompt string
local function AskForName(action, prompt)
	StaticPopup_Show("AMT_PROFILE_NAME", prompt, nil, action)
end

Options.RegisterPage({
	id = "profiles.manage",
	parent = "profiles",
	order = 10,
	name = L["Manage"],
	Build = function(page)
		page:SetHeader({
			description = L["Profiles hold every Timer setting. Records and account behaviour are shared."],
			divider = "thin",
		})

		page:AddWidgets({
			{
				type = "dropdown",
				label = L["Active Profile"],
				tooltip = L["The profile this character uses. Switching applies its Timer settings immediately."],
				GetValues = ProfileValues,
				get = function()
					return AMT.Profiles.activeName
				end,
				set = function(value)
					AMT.Profiles.Activate(value)
				end,
			},

			{
				type = "button",
				label = L["Create"],
				text = L["New Profile…"],
				tooltip = L["Starts a profile at the default settings and switches this character to it."],
				set = function()
					AskForName(ACTION_NEW, L["Name for the new profile:"])
				end,
			},

			{
				type = "button",
				label = L["Duplicate"],
				text = L["Copy Current…"],
				tooltip = L["Copies the active profile under a new name and switches to it."],
				set = function()
					AskForName(ACTION_DUPLICATE, L["Name for the copy:"])
				end,
			},

			{
				type = "button",
				label = L["Rename"],
				text = L["Rename Current…"],
				tooltip = L["Renames the active profile. Characters using it follow the new name."],
				set = function()
					AskForName(ACTION_RENAME, L["New name for this profile:"])
				end,
			},

			{
				type = "button",
				label = L["Delete"],
				text = L["Delete Current…"],
				tooltip = L["Deletes the active profile. This cannot be undone, and the last profile cannot be deleted."],
				set = function()
					StaticPopup_Show("AMT_PROFILE_DELETE", AMT.Profiles.activeName, nil, AMT.Profiles.activeName)
				end,
				disabled = function()
					return #AMT.Profiles.List() <= 1
				end,
			},

			{
				type = "button",
				label = L["New Characters"],
				text = L["Use This Profile"],
				set = function()
					StaticPopup_Show("AMT_PROFILE_DEFAULT", AMT.Profiles.activeName, nil, AMT.Profiles.activeName)
				end,
				disabled = function()
					return AMT.DB.settings.defaultProfile == AMT.Profiles.activeName
				end,
			},

			{
				type = "note",
				label = "",
				get = function()
					return L["Characters without a profile currently use %q."]:format(AMT.DB.settings.defaultProfile)
				end,
			},
		})
	end,
})
