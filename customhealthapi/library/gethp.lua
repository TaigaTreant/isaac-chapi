function CustomHealthAPI.Library.GetHPOfKey(player, key, byActualHP, byBasegameHP)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Library.GetHPOfKey(player:GetOtherTwin(), key, byActualHP, byBasegameHP)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if key == "RED_HEART" or 
		   (CustomHealthAPI.Helper.PlayerIsKeeper(player) and key == "COIN_HEART")
		then
			return CustomHealthAPI.OverriddenFunctions.GetHearts(player)
		elseif key == "ROTTEN_HEART" then
			return CustomHealthAPI.OverriddenFunctions.GetRottenHearts(player)
		elseif key == "SOUL_HEART" then
			return CustomHealthAPI.OverriddenFunctions.GetSoulHearts(player)
		elseif key == "BLACK_HEART" then
			return CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
		elseif key == "EMPTY_HEART" or 
		   (CustomHealthAPI.Helper.PlayerIsKeeper(player) and key == "EMPTY_COIN_HEART")
		then
			return CustomHealthAPI.OverriddenFunctions.GetMaxHearts(player)
		elseif key == "BONE_HEART" then
			return CustomHealthAPI.OverriddenFunctions.GetBoneHearts(player)
		elseif key == "ETERNAL_HEART" then
			return CustomHealthAPI.OverriddenFunctions.GetEternalHearts(player)
		elseif key == "GOLDEN_HEART" then
			return CustomHealthAPI.OverriddenFunctions.GetGoldenHearts(player)
		elseif key == "BROKEN_HEART" or 
		   (CustomHealthAPI.Helper.PlayerIsKeeper(player) and key == "BROKEN_COIN_HEART")
		then
			return CustomHealthAPI.OverriddenFunctions.GetBrokenHearts(player)
		else
			return 0
		end
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	
	local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
	if typ == CustomHealthAPI.Enums.HealthTypes.OVERLAY then
		return data.Overlays[key] or 0
	elseif typ == CustomHealthAPI.Enums.HealthTypes.RED then
		local redHealthMasks = data.RedHealthMasks
		
		local totalRedHP = 0
		for i = 1, #redHealthMasks do
			local mask = redHealthMasks[i]
			for j = 1, #mask do
				if mask[j].Key == key then
					local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(mask[j], "MaxHP")
					if byActualHP then
						totalRedHP = totalRedHP + mask[j].HP
					elseif byBasegameHP then
						if mask[j].HP >= maxHpOfHealth then
							totalRedHP = totalRedHP + 2
						else
							totalRedHP = totalRedHP + 1
						end
					else
						if maxHpOfHealth <= 1 then
							totalRedHP = totalRedHP + 2
						else
							totalRedHP = totalRedHP + mask[j].HP
						end
					end
				end
			end
		end
		
		return totalRedHP
	elseif typ == CustomHealthAPI.Enums.HealthTypes.SOUL then
		local otherHealthMasks = data.OtherHealthMasks
		
		local totalSoulHP = 0
		for i = 1, #otherHealthMasks do
			local mask = otherHealthMasks[i]
			for j = 1, #mask do
				if mask[j].Key == key then
					local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(mask[j], "MaxHP")
					if byActualHP then
						totalSoulHP = totalSoulHP + mask[j].HP
					elseif byBasegameHP then
						if mask[j].HP >= maxHpOfHealth then
							totalSoulHP = totalSoulHP + 2
						else
							totalSoulHP = totalSoulHP + 1
						end
					else
						if maxHpOfHealth <= 1 then
							totalSoulHP = totalSoulHP + 2
						else
							totalSoulHP = totalSoulHP + mask[j].HP
						end
					end
				end
			end
		end
		
		return totalSoulHP
	elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		local kindContained = CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained")
		local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
		local canHaveHalfCapacity = CustomHealthAPI.Library.GetInfoOfKey(key, "CanHaveHalfCapacity")
		
		if kindContained == CustomHealthAPI.Enums.HealthKinds.NONE then
			local otherHealthMasks = data.OtherHealthMasks
			
			local totalMaxHP = 0
			for i = 1, #otherHealthMasks do
				local mask = otherHealthMasks[i]
				for j = 1, #mask do
					if mask[j].Key == key then
						totalMaxHP = totalMaxHP + 1
					end
				end
			end
			
			return totalMaxHP
		elseif maxHP >= 1 then
			local otherHealthMasks = data.OtherHealthMasks
			
			local totalMaxHP = 0
			for i = 1, #otherHealthMasks do
				local mask = otherHealthMasks[i]
				for j = 1, #mask do
					if mask[j].Key == key then
						if byActualHP then
							totalMaxHP = totalMaxHP + mask[j].HP
						elseif byBasegameHP then
							totalMaxHP = totalMaxHP + 1
						else
							totalMaxHP = totalMaxHP + mask[j].HP
						end
					end
				end
			end
			
			return totalMaxHP
		else
			local otherHealthMasks = data.OtherHealthMasks
			
			local totalMaxHP = 0
			for i = 1, #otherHealthMasks do
				local mask = otherHealthMasks[i]
				for j = 1, #mask do
					if mask[j].Key == key then
						local hasHalfCapacity = mask[j].HalfCapacity
						if byActualHP then
							if hasHalfCapacity then
								totalMaxHP = totalMaxHP + 1
							else
								totalMaxHP = totalMaxHP + 2
							end
						elseif byBasegameHP then
							if hasHalfCapacity then
								totalMaxHP = totalMaxHP + 1
							else
								totalMaxHP = totalMaxHP + 2
							end
						else
							if canHaveHalfCapacity then
								if hasHalfCapacity then
									totalMaxHP = totalMaxHP + 1
								else
									totalMaxHP = totalMaxHP + 2
								end
							else
								totalMaxHP = totalMaxHP + 1
							end
						end
					end
				end
			end
			
			return totalMaxHP
		end
	else 
		return 0
	end
end

function CustomHealthAPI.Helper.GetTotalHP(player)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalHP = 0
	
	local redHealthMasks = data.RedHealthMasks
	local otherHealthMasks = data.OtherHealthMasks
	
	for i = 1, #redHealthMasks do
		local mask = redHealthMasks[i]
		for j = 1, #mask do
			totalHP = totalHP + mask[j].HP
		end
	end
	
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			totalHP = totalHP + mask[j].HP
		end
	end
	
	return totalHP
end

function CustomHealthAPI.Helper.GetTotalRedHP(player, basegameFormat, getFormat)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalRedHP = 0
	
	local redHealthMasks = data.RedHealthMasks
	for i = 1, #redHealthMasks do
		local mask = redHealthMasks[i]
		for j = 1, #mask do
			if basegameFormat then
				if mask[j].HP >= CustomHealthAPI.PersistentData.HealthDefinitions[mask[j].Key].MaxHP then
					totalRedHP = totalRedHP + 2
				else
					totalRedHP = totalRedHP + 1
				end
			elseif getFormat then
				if CustomHealthAPI.Library.GetInfoOfHealth(mask[j], "MaxHP") <= 1 then
					totalRedHP = totalRedHP + 2
				else
					totalRedHP = totalRedHP + mask[j].HP
				end
			else
				totalRedHP = totalRedHP + mask[j].HP
			end
		end
	end
	
	return totalRedHP
end

function CustomHealthAPI.Helper.GetTotalSoulHP(player, basegameFormat, getFormat)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalSoulHP = 0
	
	local otherHealthMasks = data.OtherHealthMasks
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				if basegameFormat then
					if health.HP >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP then
						totalSoulHP = totalSoulHP + 2
					else
						totalSoulHP = totalSoulHP + 1
					end
				elseif getFormat then
					if CustomHealthAPI.Library.GetInfoOfHealth(mask[j], "MaxHP") <= 1 then
						totalSoulHP = totalSoulHP + 2
					else
						totalSoulHP = totalSoulHP + health.HP
					end
				else
					totalSoulHP = totalSoulHP + health.HP
				end
			end
		end
	end
	
	return totalSoulHP
end

function CustomHealthAPI.Helper.GetTotalMaxHP(player)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalMaxHP = 0
	
	local otherHealthMasks = data.OtherHealthMasks
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and 
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP == 0
			then
				if health.HalfCapacity then
					totalMaxHP = totalMaxHP + 1
				else
					totalMaxHP = totalMaxHP + 2
				end
			end
		end
	end
	
	return totalMaxHP
end

function CustomHealthAPI.Helper.GetTotalBoneHP(player, basegameFormat)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalBoneHP = 0
	
	local otherHealthMasks = data.OtherHealthMasks
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and 
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0
			then
				if basegameFormat then
					totalBoneHP = totalBoneHP + 1
				else
					totalBoneHP = totalBoneHP + health.HP
				end
			end
		end
	end
	
	return totalBoneHP
end

function CustomHealthAPI.Helper.GetTotalHPOfKey(player, key)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalHP = 0
	
	local redHealthMasks = data.RedHealthMasks
	local otherHealthMasks = data.OtherHealthMasks
	
	for i = 1, #redHealthMasks do
		local mask = redHealthMasks[i]
		for j = 1, #mask do
			if mask[j].Key == key then
				totalHP = totalHP + mask[j].HP
			end
		end
	end
	
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			if mask[j].Key == key then
				totalHP = totalHP + mask[j].HP
			end
		end
	end
	
	return totalHP
end

function CustomHealthAPI.Helper.GetTotalKeys(player, key)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalHealth = 0
	
	local redHealthMasks = data.RedHealthMasks
	local otherHealthMasks = data.OtherHealthMasks
	
	for i = 1, #redHealthMasks do
		local mask = redHealthMasks[i]
		for j = 1, #mask do
			if mask[j].Key == key then
				totalHealth = totalHealth + 1
			end
		end
	end
	
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			if mask[j].Key == key then
				totalHealth = totalHealth + 1
			end
		end
	end
	
	return totalHealth
end

function CustomHealthAPI.Helper.GetRedCapacity(player)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalCapacity = 0
	local otherHealthMasks = data.OtherHealthMasks
	
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
			if healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and healthDefinition.KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE then
				totalCapacity = totalCapacity + ((health.HalfCapacity and 1) or 2)
			end
		end
	end
	
	return totalCapacity
end

function CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalContainers = 0
	local otherHealthMasks = data.OtherHealthMasks
	
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
			if healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and healthDefinition.KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE then
				totalContainers = totalContainers + 1
			end
		end
	end
	
	local totalRed = 0
	local redHealthMasks = data.RedHealthMasks
	
	for i = 1, #redHealthMasks do
		local mask = redHealthMasks[i]
		for j = 1, #mask do
			totalRed = totalRed + 1
		end
	end
	
	return totalContainers - totalRed
end

function CustomHealthAPI.Helper.GetHealableRedHP(player)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalHealableRedHP = 0
	
	local redHealthMasks = data.RedHealthMasks
	for i = 1, #redHealthMasks do
		local mask = redHealthMasks[i]
		for j = 1, #mask do
			totalHealableRedHP = totalHealableRedHP + (CustomHealthAPI.PersistentData.HealthDefinitions[mask[j].Key].MaxHP - mask[j].HP)
		end
	end
	
	return totalHealableRedHP
end

function CustomHealthAPI.Helper.GetHealableSoulHP(player)
	local data = player:GetData().CustomHealthAPISavedata
	
	local totalHealableSoulHP = 0
	
	local otherHealthMasks = data.OtherHealthMasks
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				totalHealableSoulHP = totalHealableSoulHP + (CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP - health.HP)
			end
		end
	end
	
	return totalHealableSoulHP
end

function CustomHealthAPI.Helper.GetTrueHeartLimit(player)
	local limit = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player)
	local brokenHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
	return limit + brokenHearts * 2
end

function CustomHealthAPI.Helper.GetRoomForOtherKeys(player)
	local limit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
	
	local data = player:GetData().CustomHealthAPISavedata
	local otherHealthMasks = data.OtherHealthMasks
	
	local totalOther = 0
	for i = 1, #otherHealthMasks do
		local mask = otherHealthMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
			totalOther = totalOther + 1
		end
	end
	
	return limit - totalOther
end

function CustomHealthAPI.Helper.GetNumOverlayableHearts(player)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	local redOrder = {}
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			table.insert(redOrder, {i, j})
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
				table.insert(healthOrder, {Red = redOrder[redIndex], Other = {i, j}})
				redIndex = redIndex + 1
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				table.insert(healthOrder, {Red = nil, Other = {i, j}})
			end
		end
	end
	
	local numOverlayable = 0
	for i = 1, #healthOrder do
		local redIndices = healthOrder[i].Red
		local otherIndices = healthOrder[i].Other
		
		local health = otherMasks[otherIndices[1]][otherIndices[2]]
		local key = health.Key
		
		if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
		   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
		   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP == 0 and 
		   redIndices ~= nil
		then
			numOverlayable = numOverlayable + 1
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0 
		then
			numOverlayable = numOverlayable + 1
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
			numOverlayable = numOverlayable + 1
		end
	end
	
	return numOverlayable
end

function CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
	local blackNum = 0
	local blackMask = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts(player)
	while blackMask > 0 do
		if blackMask % 2 == 1 then
			blackNum = blackNum + 1
		end
		blackMask = blackMask >> 1
	end
	return blackNum
end
