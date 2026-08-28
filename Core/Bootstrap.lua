local AMT = select(2, ...)

local Modules = AMT.Modules

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addon = ...
		if addon ~= AMT.name then
			return
		end

		self:UnregisterEvent(event)

		for module in Modules.Iterate() do
			if module.OnInitialize then
				module:OnInitialize()
			end
		end
	elseif event == "PLAYER_LOGIN" then
		self:UnregisterEvent(event)

		for module in Modules.Iterate() do
			Modules.Enable(module)
		end
	end
end)
