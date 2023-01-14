local redHealthOrder = nil
local otherHealthOrder = nil

function CustomHealthAPI.Library.GetHealthInOrder(player, ignoreResyncing)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	if ignoreResyncing then
		CustomHealthAPI.Helper.FinishDamageDesync(player)
	else
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Library.GetHealthInOrder(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return {}
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	local redOrder = {}
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			table.insert(redOrder, mask[j])
		end
	end
		
	local healthOrder = {}
	local redIndex = 1
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				table.insert(healthOrder, {Red = redOrder[redIndex], Other = mask[j]})
				redIndex = redIndex + 1
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			       CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
			then
				table.insert(healthOrder, {Red = nil, Other = mask[j]})
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				table.insert(healthOrder, {Red = nil, Other = mask[j]})
			end
		end
	end
	
	local numGoldHearts = data.Overlays["GOLDEN_HEART"]
	for i = #healthOrder, 1, -1 do
		local health = healthOrder[i].Other
		local key = health.Key
		
		if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
		   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
		   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP == 0 and 
		   healthOrder[i].Red ~= nil
		then
			if numGoldHearts > 0 then 
				healthOrder[i].IsGold = true
				numGoldHearts = numGoldHearts - 1
			end
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0 
		then
			if numGoldHearts > 0 then 
				healthOrder[i].IsGold = true
				numGoldHearts = numGoldHearts - 1
			end
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
			if numGoldHearts > 0 then 
				healthOrder[i].IsGold = true
				numGoldHearts = numGoldHearts - 1
			end
		end
	end
	
	return healthOrder
end

function CustomHealthAPI.Helper.InitializeRedHealthOrder()
	redHealthOrder = {}
	for key, health in pairs(CustomHealthAPI.PersistentData.HealthDefinitions) do
		if health.Type == CustomHealthAPI.Enums.HealthTypes.RED then
			local index = 1
			while redHealthOrder[index] ~= nil do
				local compareKeys = redHealthOrder[index]
				
				if CustomHealthAPI.PersistentData.HealthDefinitions[key].SortOrder < CustomHealthAPI.PersistentData.HealthDefinitions[compareKeys[1]].SortOrder then
					table.insert(redHealthOrder, index, {key})
					break
				elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].SortOrder == CustomHealthAPI.PersistentData.HealthDefinitions[compareKeys[1]].SortOrder then
					table.insert(compareKeys, key)
					break
				end
				
				index = index + 1
			end
			
			if redHealthOrder[index] == nil then
				table.insert(redHealthOrder, index, {key})
			end
		end
	end
	
	for i = 1, #redHealthOrder do
		local order = redHealthOrder[i]
		for j = 1, #order do
			CustomHealthAPI.PersistentData.HealthDefinitions[order[j]].MaskIndex = i
		end
	end
	
	return redHealthOrder
end

function CustomHealthAPI.Helper.InitializeOtherHealthOrder()	
	otherHealthOrder = {}
	for key, health in pairs(CustomHealthAPI.PersistentData.HealthDefinitions) do
		if health.Type == CustomHealthAPI.Enums.HealthTypes.SOUL or health.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
			local index = 1
			while otherHealthOrder[index] ~= nil do
				local compareKeys = otherHealthOrder[index]
				
				if CustomHealthAPI.PersistentData.HealthDefinitions[key].SortOrder < CustomHealthAPI.PersistentData.HealthDefinitions[compareKeys[1]].SortOrder then
					table.insert(otherHealthOrder, index, {key})
					break
				elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].SortOrder == CustomHealthAPI.PersistentData.HealthDefinitions[compareKeys[1]].SortOrder then
					table.insert(compareKeys, key)
					break
				end
				
				index = index + 1
			end
			
			if otherHealthOrder[index] == nil then
				table.insert(otherHealthOrder, index, {key})
			end
		end
	end
	
	for i = 1, #otherHealthOrder do
		local order = otherHealthOrder[i]
		for j = 1, #order do
			CustomHealthAPI.PersistentData.HealthDefinitions[order[j]].MaskIndex = i
		end
	end
	
	return otherHealthOrder
end

function CustomHealthAPI.Helper.GetRedHealthOrder()
	return redHealthOrder
end	

function CustomHealthAPI.Helper.GetOtherHealthOrder()
	return otherHealthOrder
end

function CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	if redHealthOrder == nil then
		CustomHealthAPI.Helper.InitializeRedHealthOrder()
	end
	
	if otherHealthOrder == nil then
		CustomHealthAPI.Helper.InitializeOtherHealthOrder()
	end
end
