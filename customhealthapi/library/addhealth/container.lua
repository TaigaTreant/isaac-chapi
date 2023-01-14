function CustomHealthAPI.Helper.TryConvertingContainerHP(player, key)
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
			   (healthToConvert == nil or addPriorityOfHealth < CustomHealthAPI.PersistentData.HealthDefinitions[healthToConvert.Key].AddPriority)
			then
				healthToConvert = health
				healthMaskIndex = i
				healthIndexInMask = j
			end
		end
	end
	if healthToConvert == nil then
		for i = #otherMasks, 1, -1 do
			local mask = otherMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
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
	end
	
	if healthToConvert == nil then
		return
	end
	local healthWasContainer = CustomHealthAPI.Library.GetInfoOfHealth(healthToConvert, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER
	table.remove(otherMasks[healthMaskIndex], healthIndexInMask)
	
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	if maskIndex == healthMaskIndex and healthWasContainer then
		if maxHP >= 1 then
			table.insert(keyContainingMask, healthIndexInMask, {Key = key, HP = 1, HalfCapacity = false})
		else
			table.insert(keyContainingMask, healthIndexInMask, {Key = key, HP = 0, HalfCapacity = false})
		end
	else
		if maxHP >= 1 then
			table.insert(keyContainingMask, {Key = key, HP = 1, HalfCapacity = false})
		else
			table.insert(keyContainingMask, {Key = key, HP = 0, HalfCapacity = false})
		end
	end
	
	if CustomHealthAPI.Library.GetInfoOfHealth(healthToConvert, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
		if CustomHealthAPI.Library.GetInfoOfHealth(healthToConvert, "MaxHP") <= 1 then
			CustomHealthAPI.Helper.HealSoulAnywhere(player, 2)
		else
			CustomHealthAPI.Helper.HealSoulAnywhere(player, healthToConvert.HP)
		end
	end
end

function CustomHealthAPI.Helper.TryInsertingContainerHP(player, key, ignoreRoomForOtherKeys)
	if CustomHealthAPI.Helper.GetRoomForOtherKeys(player) > 0 or ignoreRoomForOtherKeys then
		local data = player:GetData().CustomHealthAPISavedata
		local otherMasks = data.OtherHealthMasks
		local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
		local keyContainingMask = otherMasks[maskIndex]
		
		local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
		if maxHP >= 1 then
			table.insert(keyContainingMask, {Key = key, HP = 1, HalfCapacity = false})
		else
			table.insert(keyContainingMask, {Key = key, HP = 0, HalfCapacity = false})
		end
	else
		CustomHealthAPI.Helper.TryConvertingContainerHP(player, key)
	end
end

function CustomHealthAPI.Helper.PlusContainerMain(player, key, hp, ignoreRoomForOtherKeys)
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	local canHaveHalfCapacity = CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity
	
	local hpToAdd = hp
	local hpPer
	local keysToAdd
	if maxHP >= 1 then
		keysToAdd = math.ceil(hp / maxHP)
		hpPer = maxHP
	elseif canHaveHalfCapacity then
		keysToAdd = math.ceil(hp / 2)
		hpPer = 2
	else
		keysToAdd = hp
		hpPer = 1
	end
	
	while keysToAdd > 0 do
		CustomHealthAPI.Helper.TryInsertingContainerHP(player, key, ignoreRoomForOtherKeys)
		keysToAdd = keysToAdd - 1
		hpToAdd = hpToAdd - hpPer
	end
	
	return math.max(0, hpToAdd)
end

function CustomHealthAPI.Helper.TryRemoveLowPriorityMaxFromMask(player, maskIndex, removingBone, removingBroken, avoidRemovingBone)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	local mask = otherMasks[maskIndex]
	
	local lowestPriorityHealth
	local lowestPriority
	local indexOfLowestPriority
	for i = #mask, 1, -1 do
		local health = mask[i]
		if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
			local isBroken = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
			local maxHP = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
			
			local checkForRemoval = false
			if isBroken then
				if removingBroken then
					checkForRemoval = true
				end
			elseif maxHP == 0 then
				if not (removingBone or removingBroken) then
					checkForRemoval = true
				end
			else
				if not (removingBroken or avoidRemovingBone) then
					checkForRemoval = true
				end
			end
			
			if checkForRemoval then
				local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
				if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
					lowestPriorityHealth = health
					lowestPriority = removePriorityOfHealth
					indexOfLowestPriority = i
				end
			end
		end
	end
	
	if lowestPriority ~= nil then
		table.remove(mask, indexOfLowestPriority)
	end
end

function CustomHealthAPI.Helper.TryRemoveLowPriorityMaxFromAnywhere(player, removingBone, removingBroken, avoidRemovingBone)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	local lowestPriorityHealth
	local lowestPriority
	local maskIndexOfLowestPriority
	for i = #otherMasks, 1, -1 do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
				local isBroken = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
				local maxHP = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				
				local checkForRemoval = false
				if isBroken then
					if removingBroken then
						checkForRemoval = true
					end
				elseif maxHP == 0 then
					if not (removingBone or removingBroken) then
						checkForRemoval = true
					end
				else
					if not (removingBroken or avoidRemovingBone) then
						checkForRemoval = true
					end
				end
				
				if checkForRemoval then
					local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
					if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
						lowestPriorityHealth = health
						lowestPriority = removePriorityOfHealth
						maskIndexOfLowestPriority = i
					end
				end
			end
		end
	end
	
	return CustomHealthAPI.Helper.TryRemoveLowPriorityMaxFromMask(player, maskIndexOfLowestPriority, removingBone, removingBroken, avoidRemovingBone)
end

function CustomHealthAPI.Helper.HasRemovableMaxHP(player, key, avoidRemovingBone)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	local removingBone = maxHP > 0
	local removingBroken = CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
	
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
				local isBroken = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
				local maxHP = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				
				if isBroken then
					if removingBroken then
						return true
					end
				elseif maxHP == 0 then
					if not (removingBone or removingBroken) then
						return true
					end
				else
					if not (removingBroken or avoidRemovingBone) then
						return true
					end
				end
			end
		end
	end
	
	return false
end

function CustomHealthAPI.Helper.OtherMaskHasMaxForRemoval(player, maskIndex, key, avoidRemovingBone)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	local mask = otherMasks[maskIndex]
	
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	local removingBone = maxHP > 0
	local removingBroken = CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
	
	for i = 1, #mask do
		local health = mask[i]
		if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
			local isBroken = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
			local maxHP = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
			
			if isBroken then
				if removingBroken then
					return true
				end
			elseif maxHP == 0 then
				if not (removingBone or removingBroken) then
					return true
				end
			else
				if not (removingBroken or avoidRemovingBone) then
					return true
				end
			end
		end
	end
	
	return false
end

function CustomHealthAPI.Helper.MinusContainerMain(player, key, hp, avoidRemovingBone)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[key].MaskIndex
	
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	local canHaveHalfCapacity = CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity
	
	local hpToRemove = hp
	local hpPer
	local keysToRemove
	if maxHP >= 1 then
		keysToRemove = math.ceil(hp / maxHP)
		hpPer = maxHP
	elseif canHaveHalfCapacity then
		keysToRemove = math.ceil(hp / 2)
		hpPer = 2
	else
		keysToRemove = hp
		hpPer = 1
	end
	
	local removingBone = maxHP > 0
	local removingBroken = CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
	while keysToRemove > 0 do
		if not CustomHealthAPI.Helper.HasRemovableMaxHP(player, key, avoidRemovingBone) then
			return math.max(0, hpToRemove) * -1
		end
		
		if CustomHealthAPI.Helper.OtherMaskHasMaxForRemoval(player, maskIndex, key, avoidRemovingBone) then
			CustomHealthAPI.Helper.TryRemoveLowPriorityMaxFromMask(player, maskIndex, removingBone, removingBroken, avoidRemovingBone)
		else
			CustomHealthAPI.Helper.TryRemoveLowPriorityMaxFromAnywhere(player, removingBone, removingBroken, avoidRemovingBone)
		end
		
		keysToRemove = keysToRemove - 1
		hpToRemove = hpToRemove - hpPer
	end
	
	while CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) < 0 do
		if not CustomHealthAPI.Helper.RemoveLowestPriorityRedKey(player, true) then
			break
		end
	end
	
	return math.max(0, hpToRemove) * -1
end

function CustomHealthAPI.Helper.AddContainerMain(player, key, hp, avoidRemovingBone)
	if hp > 0 then
		return CustomHealthAPI.Helper.PlusContainerMain(player, key, hp)
	elseif hp < 0 then
		return CustomHealthAPI.Helper.MinusContainerMain(player, key, math.abs(hp), avoidRemovingBone)
	end
	return 0
end

