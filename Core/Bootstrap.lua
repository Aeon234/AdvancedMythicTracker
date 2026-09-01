local AMT = select(2, ...)

local Modules = AMT.Modules

local function StartChallenge()
	AMT.State.Reset()
	AMT.State.current.inChallenge = true

	AMT.Challenge.Load()

	for module in Modules.Iterate() do
		if module.OnChallengeStart then
			module:OnChallengeStart()
		end
	end

	AMT.Render.StartTicker()
end

local function EndChallenge()
	AMT.Render.StopTicker()
	local completed = AMT.State.current.challengeCompleted

	for module in Modules.Iterate() do
		if module.OnChallengeEnd then
			module:OnChallengeEnd(completed)
		end
	end

	AMT.Events.UnregisterChallenge()
	AMT.State.Reset()
end

local function CheckForChallenge()
	local inInstance = AMT.Challenge.IsInChallengeInstance()

	if inInstance == AMT.State.current.inChallenge then
		return
	end

	if inInstance then
		StartChallenge()
	else
		EndChallenge()
	end
end

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

		AMT.DB.Initialize()
		AMT.Profiles.Initialize()
		AMT.Frames.Initialize()

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

		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		self:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
		self:RegisterEvent("CHALLENGE_MODE_START")
		self:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE")
		self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	elseif event == "CHALLENGE_MODE_MAPS_UPDATE" then
		local state = AMT.State.current

		if state.inChallenge and state.timeLimit == 0 then
			AMT.Challenge.Load()
		end
	elseif event == "CHALLENGE_MODE_COMPLETED" then
		if not AMT.State.current.inChallenge then
			return
		end

		AMT.Challenge.Complete()

		for module in Modules.Iterate() do
			if module.OnChallengeComplete then
				module:OnChallengeComplete()
			end
		end
	else
		C_MythicPlus.RequestMapInfo()
		CheckForChallenge()
	end
end)
