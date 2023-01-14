function CustomHealthAPI.Helper.HandleBrittleBones(player)
	-- convert up to 6 maxhp 0 containers to bone hearts, remove any extra, add more bone hearts if necessary to reach 6 added total
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			table.remove(mask, j)
		end
	end
	
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].MaskIndex
	local boneContainingMask = otherMasks[maskIndex]
	local bonePriority = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].RemovePriority
	
	local bonesAdded = 0
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
				local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				
				if (maxHpOfHealth <= 0 or removePriorityOfHealth <= bonePriority) and health.Key ~= "BONE_HEART" then
					if i < maskIndex then
						table.remove(mask, j)
						table.insert(boneContainingMask, 1, {Key = "BONE_HEART", HP = 1, HalfCapacity = false})
						bonesAdded = bonesAdded + 1
					elseif i > maskIndex then
						table.remove(mask, j)
						table.insert(boneContainingMask, {Key = "BONE_HEART", HP = 1, HalfCapacity = false})
						bonesAdded = bonesAdded + 1
					else
						mask[j] = {Key = "BONE_HEART", HP = 1, HalfCapacity = false}
						bonesAdded = bonesAdded + 1
					end
				end
			end
		end
	end
	
	if bonesAdded ~= 6 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", 6 - bonesAdded)
	end
end
