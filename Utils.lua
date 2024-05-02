local addonName, AMT = ...

function AMT:Find_Table(tbl, callback)
	for i, v in ipairs(tbl) do
		if callback(v, i) then
			return v, i
		end
	end
	return nil, nil
end

function AMT:Filter_Table(tbl, callback)
	local t = {}
	for i, v in ipairs(tbl) do
		if callback(v, i) then
			table.insert(t, v)
		end
	end
	return t
end

function AMT:Get_Table(tbl, key, val)
	return AMT:Find_Table(tbl, function(elm)
		return elm[key] and elm[key] == val
	end)
end

function AMT:Table_Recall(tbl, callback)
	for ik, iv in pairs(tbl) do
		callback(iv, ik)
	end
	return tbl
end

BackdropInfo = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 40,
	edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

function GetAbbrFromChallengeModeID(id)
	for _, dungeon in ipairs(SeasonalDungeons) do
		if dungeon.challengeModeID == id then
			return dungeon.abbr
		end
	end
	return nil -- Return nil if no matching dungeon is found
end
