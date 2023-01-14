function CustomHealthAPI.Helper.HandleHematemesis(player)
	if CustomHealthAPI.Helper.GetRedCapacity(player) > 0 and not CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[player:GetPlayerType()] then
		local data = player:GetData().CustomHealthAPISavedata
		local redMasks = data.RedHealthMasks
		
		local highestPriorityHealth
		local healthMaskIndex
		local healthIndexInMask
		for i = #redMasks, 1, -1 do
			local mask = redMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				
				if highestPriorityHealth == nil or 
				   addPriorityOfHealth > CustomHealthAPI.PersistentData.HealthDefinitions[highestPriorityHealth.Key].AddPriority
				then
					highestPriorityHealth = health
					healthMaskIndex = i
					healthIndexInMask = j
				end
			end
		end
		
		local hemaKey = "RED_HEART"
		if highestPriorityHealth ~= nil then
			hemaKey = highestPriorityHealth.Key
		end
		
		for i = #redMasks, 1, -1 do
			local mask = redMasks[i]
			for k in pairs(mask) do
				mask[k] = nil
			end
		end
		
		local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[hemaKey].MaskIndex
		local keyContainingMask = redMasks[maskIndex]
		local maxHP = CustomHealthAPI.Library.GetInfoOfKey(hemaKey, "MaxHP")
		table.insert(keyContainingMask, {Key = hemaKey, HP = maxHP})
	end
end
