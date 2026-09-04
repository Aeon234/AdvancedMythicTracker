local AMT = select(2, ...)

---@class AMTQoLModule : AMTModule
local module = AMT.Modules.New("QoL")

---@return integer? bag
---@return integer? slot
local function FindKeystone()
	for bag = Enum.BagIndex.Backpack, NUM_TOTAL_BAG_FRAMES do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local itemID = C_Container.GetContainerItemID(bag, slot)

			if itemID and C_Item.IsItemKeystoneByID(itemID) then
				return bag, slot
			end
		end
	end

	return nil, nil
end

function module:SlotKeystone()
	if not AMT.DB.settings.qol.autoSlotKeystone or CursorHasItem() then
		return
	end

	if C_ChallengeMode.GetSlottedKeystoneInfo() then
		return
	end

	local bag, slot = FindKeystone()

	if not bag or not slot then
		return
	end

	C_Container.PickupContainerItem(bag, slot)

	if CursorHasItem() then
		C_ChallengeMode.SlotKeystone()
	else
		ClearCursor()
	end
end

function module:AutoGossip()
	if not AMT.DB.settings.qol.autoGossip or IsControlKeyDown() then
		return
	end

	if not C_ChallengeMode.IsChallengeModeActive() then
		return
	end

	local options = C_GossipInfo.GetOptions()

	if not options or #options ~= 1 then
		return
	end

	local optionID = options[1].gossipOptionID

	if not optionID then
		return
	end

	C_GossipInfo.SelectOption(optionID)
end

function module:OnEnable()
	AMT.Events.Register("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN", self, function()
		module:SlotKeystone()
	end)
end

function module:OnChallengeStart()
	AMT.Events.RegisterChallenge("GOSSIP_SHOW", self, function()
		module:AutoGossip()
	end)
end
