function CustomHealthAPI.Helper.TryConvertingRedHP(player, key, overflowedHP, ignoreRoomForRedKeys)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
	local keyContainingMask = redMasks[maskIndex]
	
	local addPriority = CustomHealthAPI.PersistentData.HealthDefinitions[key].AddPriority
	local healthToConvert
	local healthMaskIndex
	local healthIndexInMask
	for i = #redMasks, 1, -1 do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			
			if health.Key ~= key and
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
	if (CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) > 0 or ignoreRoomForRedKeys) and 
	   maxHPOfConvert > 1 
	then
		local convertedHP = math.max(0, math.min(healthToConvert.HP, math.max(2, maxHP) - overflowedHP))
		healthToConvert.HP = healthToConvert.HP - convertedHP
		overflowedHP = overflowedHP + convertedHP
		
		if healthToConvert.HP <= 0 then
			table.remove(redMasks[healthMaskIndex], healthIndexInMask)
		end
	else
		if maxHPOfConvert <= 1 then
			overflowedHP = overflowedHP + 2
		else
			overflowedHP = overflowedHP + healthToConvert.HP
		end
		table.remove(redMasks[healthMaskIndex], healthIndexInMask)
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

function CustomHealthAPI.Helper.TryInsertingRedHP(player, key, hpAddedByKey, overflowedHP, ignoreRoomForRedKeys)
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	if (CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) > 0 or ignoreRoomForRedKeys) and 
	   (maxHP > 1 or hpAddedByKey + overflowedHP >= 2) 
	then
		local data = player:GetData().CustomHealthAPISavedata
		local redMasks = data.RedHealthMasks
		local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
		local keyContainingMask = redMasks[maskIndex]
		
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
		return CustomHealthAPI.Helper.TryConvertingRedHP(player, key, overflowedHP + hpAddedByKey, ignoreRoomForRedKeys)
	end
end
	
function CustomHealthAPI.Helper.TryHealingRedHP(player, key, hpAddedByKey, overflowedHP, ignoreRoomForRedKeys)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
	local keyContainingMask = redMasks[maskIndex]
	local prioritizeHealing = CustomHealthAPI.PersistentData.HealthDefinitions[key].PrioritizeHealing
	
	local unhealedHealth = {}
	for i = 1, #keyContainingMask do
		local health = keyContainingMask[i]
		local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
		
		local hpOfHealth = health.HP
		if hpOfHealth < maxHpOfHealth then
			table.insert(unhealedHealth, health)
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
		for i = 1, #redMasks do
			local mask = redMasks[i]
			for j = 1, #mask do
				local health = mask[j]
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
	
	if remainingHpAddedByKey > 0 then
		return CustomHealthAPI.Helper.TryInsertingRedHP(player, key, remainingHpAddedByKey, overflowedHP, ignoreRoomForRedKeys)
	elseif healedMatchingKey or prioritizeHealing then
		return overflowedHP
	else
		return CustomHealthAPI.Helper.TryConvertingRedHP(player, key, overflowedHP, ignoreRoomForRedKeys)
	end
end

function CustomHealthAPI.Helper.HealRedAnywhere(player, hp)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	
	local remainingHPToHeal = hp
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
			local hpOfHealth = health.HP
			
			if hpOfHealth < maxHpOfHealth then
				local hpToHeal = math.max(0, math.min(remainingHPToHeal, maxHpOfHealth - hpOfHealth))
				health.HP = health.HP + hpToHeal
				remainingHPToHeal = remainingHPToHeal - hpToHeal
			end
		end
		
		if remainingHPToHeal <= 0 then
			break
		end
	end
	
	return remainingHPToHeal
end

function CustomHealthAPI.Helper.HandleOddNumberedRotten(player, ignoreRoomForRedKeys)
	-- why do rotten hearts function like this in basegame why why why why why why why why why why why
	if CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) <= 0 or ignoreRoomForRedKeys then
		return false, 0
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions["ROTTEN_HEART"].MaskIndex
	local keyContainingMask = redMasks[maskIndex]
	
	local addPriority = CustomHealthAPI.PersistentData.HealthDefinitions["ROTTEN_HEART"].AddPriority
	local healthToConvert
	local healthMaskIndex
	local healthIndexInMask
	for i = #redMasks, 1, -1 do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			
			if health.Key ~= "ROTTEN_HEART" and
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
		return false, 0
	end
	
	local maxHP = 1
	local maxHPOfConvert = CustomHealthAPI.Library.GetInfoOfHealth(healthToConvert, "MaxHP")
	local overflowedHP = 1
	if maxHPOfConvert > 1 then
		healthToConvert.HP = healthToConvert.HP - 1
		overflowedHP = overflowedHP + 1
		
		if healthToConvert.HP <= 0 then
			table.remove(redMasks[healthMaskIndex], healthIndexInMask)
		end
	else
		overflowedHP = overflowedHP + 2
		table.remove(redMasks[healthMaskIndex], healthIndexInMask)
	end
	
	local overflowAdding = 2
	if maskIndex == healthMaskIndex then
		table.insert(keyContainingMask, healthIndexInMask, {Key = "ROTTEN_HEART", HP = 1})
	else
		table.insert(keyContainingMask, {Key = "ROTTEN_HEART", HP = 1})
	end
	
	return true, overflowedHP - 2
end

function CustomHealthAPI.Helper.PlusRedMain(player, key, hp, ignoreRoomForRedKeys)
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	local hpToAdd = hp
	
	local overflowedHP = 0
	if key == "ROTTEN_HEART" and hpToAdd % 2 == 1 then
		-- dumb odd number rotten heart bullshit
		local addedHeart, overflowHP = CustomHealthAPI.Helper.HandleOddNumberedRotten(player, ignoreRoomForRedKeys)
		
		overflowedHP = overflowedHP + overflowHP
		if addedHeart then
			hpToAdd = hpToAdd - 1
		else
			hpToAdd = hpToAdd + 1
		end
	end
	
	local keysToAdd
	if maxHP <= 1 then
		keysToAdd = math.floor(hpToAdd / 2)
	else
		keysToAdd = math.ceil(hpToAdd / maxHP)
	end
	
	while keysToAdd > 0 do
		local hpAddedByKey = math.min(hpToAdd, maxHP)
		if maxHP <= 1 then
			hpAddedByKey = math.min(hpToAdd, 2)
		end
		
		overflowedHP = CustomHealthAPI.Helper.TryHealingRedHP(player, key, hpAddedByKey, overflowedHP, ignoreRoomForRedKeys)
		overflowedHP = CustomHealthAPI.Helper.HealRedAnywhere(player, overflowedHP)
		
		hpToAdd = hpToAdd - hpAddedByKey
		keysToAdd = keysToAdd - 1
	end
	overflowedHP = overflowedHP + hpToAdd
	
	-- TODO: Deal with handling half-capacity containers
	
	overflowedHP = CustomHealthAPI.Helper.HealRedAnywhere(player, overflowedHP)
end

function CustomHealthAPI.Helper.TryRemoveLowPriorityRedFromMask(player, maskIndex, hpToRemove)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local mask = redMasks[maskIndex]
	
	local lastHealth = mask[#mask]
	
	if lastHealth and lastHealth.HP > hpToRemove then
		lastHealth.HP = lastHealth.HP - hpToRemove
		return hpToRemove, lastHealth.Key
	end
	local maxHpOfLast = CustomHealthAPI.Library.GetInfoOfHealth(lastHealth, "MaxHP")
	
	local lowestPriorityHealth
	local lowestPriority
	local indexOfLowestPriority
	for i = #mask, 1, -1 do
		local health = mask[i]
		local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
		
		if lowestPriorityHealth == nil or addPriorityOfHealth < lowestPriority then
			lowestPriorityHealth = health
			lowestPriority = addPriorityOfHealth
			indexOfLowestPriority = i
		end
	end
	
	if lowestPriorityHealth and indexOfLowestPriority == #mask then
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

function CustomHealthAPI.Helper.TryRemoveLowPriorityRedFromAnywhere(player, hpToRemove)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	
	local lowestPriorityHealth
	local lowestPriority
	local maskIndexOfLowestPriority
	for i = #redMasks, 1, -1 do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			
			if lowestPriorityHealth == nil or addPriorityOfHealth < lowestPriority then
				lowestPriorityHealth = health
				lowestPriority = addPriorityOfHealth
				maskIndexOfLowestPriority = i
			end
		end
	end
	
	return CustomHealthAPI.Helper.TryRemoveLowPriorityRedFromMask(player, maskIndexOfLowestPriority, hpToRemove)
end

function CustomHealthAPI.Helper.MinusRedMain(player, key, hp)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
	local keyContainingMask = redMasks[maskIndex]
	
	local hpToRemove = hp
	while hpToRemove > 0 do
		if CustomHealthAPI.Helper.GetTotalRedHP(player) <= 0 then
			return
		end
	
		if #keyContainingMask > 0 then
			hpToRemove = hpToRemove - CustomHealthAPI.Helper.TryRemoveLowPriorityRedFromMask(player, maskIndex, hpToRemove)
		else
			hpToRemove = hpToRemove - CustomHealthAPI.Helper.TryRemoveLowPriorityRedFromAnywhere(player, hpToRemove)
		end
	end
	
	if hpToRemove < 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", math.abs(hpToRemove), false, false, false, true, true)
	end
end

function CustomHealthAPI.Helper.AddRedMain(player, key, hp)
	if hp > 0 then
		CustomHealthAPI.Helper.PlusRedMain(player, key, hp)
	elseif hp < 0 then
		CustomHealthAPI.Helper.MinusRedMain(player, key, math.abs(hp))
	end
end

function CustomHealthAPI.Helper.RemoveLowestPriorityRedKey(player, healingOverflow)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	
	local healthToRemove
	local healthMaskIndex
	local healthIndexInMask
	for i = #redMasks, 1, -1 do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			
			if healthToRemove == nil or addPriorityOfHealth < CustomHealthAPI.PersistentData.HealthDefinitions[healthToRemove.Key].AddPriority then
				healthToRemove = health
				healthMaskIndex = i
				healthIndexInMask = j
			end
		end
	end
	
	if not healthToRemove then
		return false
	end
	
	local removedHP = healthToRemove.HP
	if CustomHealthAPI.Library.GetInfoOfHealth(healthToRemove, "MaxHP") <= 1 then
		removedHP = 2
	end
	table.remove(redMasks[healthMaskIndex], healthIndexInMask)
	if healingOverflow then
		CustomHealthAPI.Helper.HealRedAnywhere(player, removedHP)
	end
	
	return true
end

