function CustomHealthAPI.Helper.TryConvertingSoulHP(player, key, overflowedHP, ignoreRoomForOtherKeys)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
	local keyContainingMask = otherMasks[maskIndex]
	
	local addPriority = CustomHealthAPI.PersistentData.HealthDefinitions[key].AddPriority
	local healthToConvert
	local healthMaskIndex
	local healthIndexInMask
	for i = #otherMasks, 1, -1 do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL and
			   health.Key ~= key and
			   addPriorityOfHealth <= addPriority and
			   (healthToConvert == nil or addPriorityOfHealth < CustomHealthAPI.PersistentData.HealthDefinitions[healthToConvert.Key].AddPriority)
			then
				healthToConvert = health
				healthMaskIndex = i
				healthIndexInMask = j
			end
		end
	end
	
	if healthToConvert == nil then
		return overflowedHP
	end
	
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	local maxHPOfConvert = CustomHealthAPI.Library.GetInfoOfHealth(healthToConvert, "MaxHP")
	if (CustomHealthAPI.Helper.GetRoomForOtherKeys(player) > 0 or ignoreRoomForOtherKeys) and 
	   maxHPOfConvert > 1 
	then
		local convertedHP = math.max(0, math.min(healthToConvert.HP, math.max(2, maxHP) - overflowedHP))
		healthToConvert.HP = healthToConvert.HP - convertedHP
		overflowedHP = overflowedHP + convertedHP
		
		if healthToConvert.HP <= 0 then
			table.remove(otherMasks[healthMaskIndex], healthIndexInMask)
		end
	else
		if maxHPOfConvert <= 1 then
			overflowedHP = overflowedHP + 2
		else
			overflowedHP = overflowedHP + healthToConvert.HP
		end
		table.remove(otherMasks[healthMaskIndex], healthIndexInMask)
	end
	
	local overflowAdding = math.min(overflowedHP, math.max(2, maxHP))
	if maskIndex == healthMaskIndex then
		if maxHP <= 1 then
			table.insert(keyContainingMask, healthIndexInMask, {Key = key, HP = 1})
		else
			table.insert(keyContainingMask, healthIndexInMask, {Key = key, HP = overflowAdding})
		end
	else
		if maxHP <= 1 then
			table.insert(keyContainingMask, {Key = key, HP = 1})
		else
			table.insert(keyContainingMask, {Key = key, HP = overflowAdding})
		end
	end
	
	return overflowedHP - overflowAdding
end

function CustomHealthAPI.Helper.TryInsertingSoulHP(player, key, hpAddedByKey, overflowedHP, ignoreRoomForOtherKeys)
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	if (CustomHealthAPI.Helper.GetRoomForOtherKeys(player) > 0 or ignoreRoomForOtherKeys) and 
	   (maxHP > 1 or hpAddedByKey + overflowedHP >= 2) 
	then
		local data = player:GetData().CustomHealthAPISavedata
		local otherMasks = data.OtherHealthMasks
		local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
		local keyContainingMask = otherMasks[maskIndex]
		
		local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
		local overflowAdding
		if maxHP <= 1 then
			overflowAdding = math.min(overflowedHP, 2 - hpAddedByKey)
			table.insert(keyContainingMask, {Key = key, HP = 1})
		else
			overflowAdding = math.min(overflowedHP, maxHP - hpAddedByKey)
			table.insert(keyContainingMask, {Key = key, HP = hpAddedByKey + overflowAdding})
		end
		
		return overflowedHP - overflowAdding
	else
		return CustomHealthAPI.Helper.TryConvertingSoulHP(player, key, overflowedHP + hpAddedByKey, ignoreRoomForOtherKeys)
	end
end

function CustomHealthAPI.Helper.TryHealingSoulHP(player, key, hpAddedByKey, overflowedHP, ignoreRoomForOtherKeys)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
	local keyContainingMask = otherMasks[maskIndex]
	local prioritizeHealing = CustomHealthAPI.PersistentData.HealthDefinitions[key].PrioritizeHealing
	
	local unhealedHealth = {}
	for i = 1, #keyContainingMask do
		local health = keyContainingMask[i]
		if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
			local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
			
			local hpOfHealth = health.HP
			if hpOfHealth < maxHpOfHealth then
				table.insert(unhealedHealth, health)
			end
		end
	end
	
	-- first heal matching keys (so no need to backfill later)
	local remainingHpAddedByKey = hpAddedByKey
	local healedMatchingKey = false
	for i = 1, #unhealedHealth do
		local health = unhealedHealth[i]
		local hpOfHealth = health.HP
		local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
		
		if health.Key == key then
			local hpToHeal = math.max(0, math.min(remainingHpAddedByKey, maxHpOfHealth - hpOfHealth))
			health.HP = health.HP + hpToHeal
			remainingHpAddedByKey = remainingHpAddedByKey - hpToHeal
			
			if hpToHeal > 0 then
				healedMatchingKey = true
			end
		end
	end
	-- then heal everything else in its mask
	for i = 1, #unhealedHealth do
		local health = unhealedHealth[i]
		local hpOfHealth = health.HP
		local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
		
		local hpToHeal = math.max(0, math.min(remainingHpAddedByKey, maxHpOfHealth - hpOfHealth))
		health.HP = health.HP + hpToHeal
		remainingHpAddedByKey = remainingHpAddedByKey - hpToHeal
		
		if hpToHeal > 0 and health.Key == key then
			healedMatchingKey = true
		end
	end
	-- then, if prioritizing healing, everything else everywhere
	if prioritizeHealing then
		for i = 1, #otherMasks do
			local mask = otherMasks[i]
			for j = 1, #mask do
				local health = mask[j]
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
					local hpOfHealth = health.HP
					local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
					
					local hpToHeal = math.max(0, math.min(remainingHpAddedByKey, maxHpOfHealth - hpOfHealth))
					health.HP = health.HP + hpToHeal
					remainingHpAddedByKey = remainingHpAddedByKey - hpToHeal
					
					if hpToHeal > 0 and health.Key == key then
						healedMatchingKey = true
					end
				end
			end
		end
	end
	
	if remainingHpAddedByKey > 0 then
		return CustomHealthAPI.Helper.TryInsertingSoulHP(player, key, remainingHpAddedByKey, overflowedHP, ignoreRoomForOtherKeys)
	elseif healedMatchingKey or prioritizeHealing then
		return overflowedHP
	else
		return CustomHealthAPI.Helper.TryConvertingSoulHP(player, key, overflowedHP, ignoreRoomForOtherKeys)
	end
end

function CustomHealthAPI.Helper.HealSoulAnywhere(player, hp)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	local remainingHPToHeal = hp
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
				local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				local hpOfHealth = health.HP
				
				if hpOfHealth < maxHpOfHealth then
					local hpToHeal = math.max(0, math.min(remainingHPToHeal, maxHpOfHealth - hpOfHealth))
					health.HP = health.HP + hpToHeal
					remainingHPToHeal = remainingHPToHeal - hpToHeal
				end
			end
		end
		
		if remainingHPToHeal <= 0 then
			break
		end
	end
	
	return remainingHPToHeal
end

function CustomHealthAPI.Helper.PlusSoulMain(player, key, hp, ignoreRoomForOtherKeys)
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	local hpToAdd = hp
	
	local keysToAdd
	if maxHP <= 1 then
		keysToAdd = math.floor(hp / 2)
	else
		keysToAdd = math.ceil(hp / maxHP)
	end
	
	local overflowedHP = 0
	while keysToAdd > 0 do
		local hpAddedByKey = math.min(hpToAdd, maxHP)
		if maxHP <= 1 then
			hpAddedByKey = math.min(hpToAdd, 2)
		end
		
		overflowedHP = CustomHealthAPI.Helper.TryHealingSoulHP(player, key, hpAddedByKey, overflowedHP, ignoreRoomForOtherKeys)
		overflowedHP = CustomHealthAPI.Helper.HealSoulAnywhere(player, overflowedHP)
		
		hpToAdd = hpToAdd - hpAddedByKey
		keysToAdd = keysToAdd - 1
	end
	overflowedHP = overflowedHP + hpToAdd
	
	overflowedHP = CustomHealthAPI.Helper.HealSoulAnywhere(player, overflowedHP)
	
	return math.max(0, overflowedHP)
end

function CustomHealthAPI.Helper.OtherMaskHasSoul(player, maskIndex)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	local mask = otherMasks[maskIndex]
	
	for j = 1, #mask do
		local health = mask[j]
		if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
			return true
		end
	end
	return false
end

function CustomHealthAPI.Helper.TryRemoveLowPrioritySoulFromMask(player, maskIndex, hpToRemove)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	local mask = otherMasks[maskIndex]
	
	local lastHealth
	local indexOfLast
	
	local lowestPriorityHealth
	local lowestPriority
	local indexOfLowestPriority
	for i = #mask, 1, -1 do
		local health = mask[i]
		if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
			local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			
			if lowestPriorityHealth == nil or addPriorityOfHealth < lowestPriority then
				lowestPriorityHealth = health
				lowestPriority = addPriorityOfHealth
				indexOfLowestPriority = i
			end
			
			if lastHealth == nil then
				lastHealth = health
				indexOfLast = i
			end
		end
	end
	
	if lastHealth.HP > hpToRemove then
		lastHealth.HP = lastHealth.HP - hpToRemove
		return hpToRemove, lastHealth.Key
	end
	local maxHpOfLast = CustomHealthAPI.Library.GetInfoOfHealth(lastHealth, "MaxHP")
	
	if lowestPriorityHealth and indexOfLowestPriority == indexOfLast then
		local maxHpOfLowestPriority = CustomHealthAPI.Library.GetInfoOfHealth(lowestPriorityHealth, "MaxHP")
		local removableHP = math.min(lowestPriorityHealth.HP, hpToRemove)
		lowestPriorityHealth.HP = lowestPriorityHealth.HP - removableHP
		
		if lowestPriorityHealth.HP <= 0 then
			table.remove(mask, indexOfLowestPriority)
		end
		
		if maxHpOfLowestPriority <= 1 then
			return 2, lowestPriorityHealth.Key
		else
			return removableHP, lowestPriorityHealth.Key
		end
	elseif lowestPriorityHealth then
		local maxHpOfLowestPriority = CustomHealthAPI.Library.GetInfoOfHealth(lowestPriorityHealth, "MaxHP")
		local removableHP
		if maxHpOfLast <= 1 then
			removableHP = math.min(lowestPriorityHealth.HP, hpToRemove)
		else
			removableHP = math.min(lowestPriorityHealth.HP, maxHpOfLast)
		end
		lowestPriorityHealth.HP = lowestPriorityHealth.HP - removableHP
		
		if lowestPriorityHealth.HP <= 0 then
			table.remove(mask, indexOfLowestPriority)
		end
		
		local healableHP
		if maxHpOfLowestPriority <= 1 then
			healableHP = math.min(math.max(0, 2 - hpToRemove), maxHpOfLast - lastHealth.HP)
		else
			healableHP = math.min(math.max(0, removableHP - hpToRemove), maxHpOfLast - lastHealth.HP)
		end
		lastHealth.HP = lastHealth.HP + healableHP
		
		if maxHpOfLowestPriority <= 1 then
			return 2 - healableHP, lowestPriorityHealth.Key
		else
			return removableHP - healableHP, lowestPriorityHealth.Key
		end
	end
	
	return 0, nil
end

function CustomHealthAPI.Helper.TryRemoveLowPrioritySoulFromAnywhere(player, hpToRemove)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	local lowestPriorityHealth
	local lowestPriority
	local maskIndexOfLowestPriority
	for i = #otherMasks, 1, -1 do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				if lowestPriorityHealth == nil or addPriorityOfHealth < lowestPriority then
					lowestPriorityHealth = health
					lowestPriority = addPriorityOfHealth
					maskIndexOfLowestPriority = i
				end
			end
		end
	end
	
	return CustomHealthAPI.Helper.TryRemoveLowPrioritySoulFromMask(player, maskIndexOfLowestPriority, hpToRemove)
end

function CustomHealthAPI.Helper.MinusSoulMain(player, key, hp)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
	
	local hpToRemove = hp
	while hpToRemove > 0 do
		if CustomHealthAPI.Helper.GetTotalSoulHP(player) <= 0 then
			return math.max(0, hpToRemove) * -1
		end
	
		if CustomHealthAPI.Helper.OtherMaskHasSoul(player, maskIndex) then
			hpToRemove = hpToRemove - CustomHealthAPI.Helper.TryRemoveLowPrioritySoulFromMask(player, maskIndex, hpToRemove)
		else
			hpToRemove = hpToRemove - CustomHealthAPI.Helper.TryRemoveLowPrioritySoulFromAnywhere(player, hpToRemove)
		end
	end
	
	if hpToRemove < 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", math.abs(hpToRemove), false, false, true)
	end
	
	return math.max(0, hpToRemove) * -1
end

function CustomHealthAPI.Helper.AddSoulMain(player, key, hp)
	if hp > 0 then
		return CustomHealthAPI.Helper.PlusSoulMain(player, key, hp)
	elseif hp < 0 then
		return CustomHealthAPI.Helper.MinusSoulMain(player, key, math.abs(hp))
	end
	return 0
end
