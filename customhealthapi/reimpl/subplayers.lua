function CustomHealthAPI.Helper.SplitSubPlayerInfo(player)
	-- THIS FUNCTION HAS BEEN WRITTEN ASSUMING THE PLAYER IS THE FORGOTTEN
	-- IF THEY ARE NOT, WELL FUCK
	
	--[[local maindata = player:GetData().CustomHealthAPISavedata
	maindata.SubPlayerInfo = {}
	local subdata = maindata.SubPlayerInfo
	
	local mainRedMasks = maindata.RedHealthMasks
	local subRedMasks = subdata.RedHealthMasks
	for i = #subRedMasks, 1, -1 do
		local mask = subRedMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			table.insert(mainRedMasks[i], 1, health)
		end
	end
	
	local mainOtherMasks = maindata.OtherHealthMasks
	local subOtherMasks = subdata.OtherHealthMasks
	for i = #subOtherMasks, 1, -1 do
		local mask = subOtherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			table.insert(mainOtherMasks[i], 1, health)
		end
	end
	
	local mainOverlays = maindata.Overlays
	local subOverlays = subdata.Overlays
	for k,v in subOverlays do
		mainOverlays[k] = mainOverlays[k] + v
		if k == "ETERNAL_HEART" then
			mainOverlays[k] = mainOverlays[k] % 2
		end
	end]]--
end

function CustomHealthAPI.Helper.CollapseSubPlayerInfo(player)
	-- THIS FUNCTION HAS BEEN WRITTEN ASSUMING THE PLAYER WAS THE FORGOTTEN
	-- IF THEY ARE NOT, WELL FUCK
	
	--[[local maindata = player:GetData().CustomHealthAPISavedata
	local subdata = maindata.SubPlayerInfo
	
	if maindata.MainPlayerType == PlayerType.PLAYER_THESOUL then
		local temp = maindata
		maindata = subdata
		subdata = temp
	end
	
	local mainRedMasks = maindata.RedHealthMasks
	local subRedMasks = subdata.RedHealthMasks
	for i = #subRedMasks, 1, -1 do
		local mask = subRedMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			table.insert(mainRedMasks[i], 1, health)
		end
	end
	
	local mainOtherMasks = maindata.OtherHealthMasks
	local subOtherMasks = subdata.OtherHealthMasks
	for i = #subOtherMasks, 1, -1 do
		local mask = subOtherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			table.insert(mainOtherMasks[i], 1, health)
		end
	end
	
	local mainOverlays = maindata.Overlays
	local subOverlays = subdata.Overlays
	for k, v in pairs(subOverlays) do
		mainOverlays[k] = mainOverlays[k] + v
		if k == "ETERNAL_HEART" then
			mainOverlays[k] = mainOverlays[k] % 2
		end
	end
	
	player:GetData().CustomHealthAPISavedata = maindata
	maindata.SubPlayerInfo = nil
	maindata.MainPlayerIndex = nil
	maindata.SubPlayerIndex = nil
	maindata.MainPlayerType = nil
	maindata.SubPlayerType = nil]]--
end

function CustomHealthAPI.Helper.CheckIfSwapSubPlayerInfo(player)
	local maindata = player:GetData().CustomHealthAPISavedata
	local subdata = player:GetSubPlayer():GetData().CustomHealthAPISavedata
	
	local expectedPlayerType = maindata.PlayerType
	local expectedSubplayerType = subdata.PlayerType
	
	local actualPlayerType = player:GetPlayerType()
	local actualSubplayerType = player:GetSubPlayer():GetPlayerType()
	
	if expectedPlayerType == actualSubplayerType and expectedSubplayerType == actualPlayerType then
		player:GetData().CustomHealthAPISavedata = subdata
		player:GetSubPlayer():GetData().CustomHealthAPISavedata = maindata
		
		local mainqueued = maindata.CurrentQueuedItem
		local subqueued = subdata.CurrentQueuedItem
		
		maindata.CurrentQueuedItem = subqueued
		subdata.CurrentQueuedItem = mainqueued
		
		local mainotherdata = player:GetData().CustomHealthAPIOtherData
		local subotherdata = player:GetSubPlayer():GetData().CustomHealthAPIOtherData
		
		player:GetData().CustomHealthAPIOtherData = subotherdata
		player:GetSubPlayer():GetData().CustomHealthAPIOtherData = mainotherdata
	end
end

function CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then return end

	local data = player:GetData().CustomHealthAPISavedata
	if player:GetSubPlayer() ~= nil and data.SubPlayerInfo == nil then
		CustomHealthAPI.Helper.SplitSubPlayerInfo(player)
	elseif player:GetSubPlayer() == nil and data.SubPlayerInfo ~= nil then
		CustomHealthAPI.Helper.CollapseSubPlayerInfo(player)
	end
	
	if player:GetSubPlayer() ~= nil then
		CustomHealthAPI.Helper.CheckIfSwapSubPlayerInfo(player)
	end
end

function CustomHealthAPI.Helper.CheckSubPlayerInfo()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	end
end
