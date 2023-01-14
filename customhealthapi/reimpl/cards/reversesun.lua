function CustomHealthAPI.Helper.HandleReverseSun(player)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].MaskIndex
	local boneContainingMask = otherMasks[maskIndex]
	local bonePriority = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].RemovePriority
	
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
				local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				
				if maxHpOfHealth <= 0 or removePriorityOfHealth <= bonePriority then
					if i < maskIndex then
						table.remove(mask, j)
						table.insert(boneContainingMask, 1, {Key = "BONE_HEART", HP = 1, HalfCapacity = false})
					elseif i > maskIndex then
						table.remove(mask, j)
						table.insert(boneContainingMask, {Key = "BONE_HEART", HP = 1, HalfCapacity = false})
					else
						mask[j] = {Key = "BONE_HEART", HP = 1, HalfCapacity = false}
					end
				end
			end
		end
	end
end

function CustomHealthAPI.Helper.HandleReverseSunSyncing(player)
	
end

