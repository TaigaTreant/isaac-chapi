function CustomHealthAPI.Library.CanPickKey(player, key)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	return CustomHealthAPI.Helper.CanPickKey(player, key)
end

function CustomHealthAPI.Helper.CanPickKey(player, key)
	local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
	
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.CAN_PICK_HEALTH)
	for _, callback in ipairs(callbacks) do
		local canpick = callback.Function(player, key)
		if canpick ~= nil then
			return canpick
		end
	end
	
	if typ == CustomHealthAPI.Enums.HealthTypes.RED then
		return CustomHealthAPI.Helper.CanPickRed(player, key)
	elseif typ == CustomHealthAPI.Enums.HealthTypes.SOUL then
		return CustomHealthAPI.Helper.CanPickSoul(player, key)
	elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		return CustomHealthAPI.Helper.CanPickContainer(player, key)
	elseif key == "ETERNAL_HEART" then
		return true
	elseif key == "GOLDEN_HEART" then
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickGoldenHearts(player)
	end
end

function CustomHealthAPI.Helper.CanPickRed(player, key)
	if player:GetPlayerType() == PlayerType.PLAYER_BETHANY_B then
		return player:GetBloodCharge() < 99 and key == "RED_HEART"
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CanPickRed(player:GetOtherTwin(), key)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if key == "ROTTEN_HEART" then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts(player)
		else
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts(player)
		end
	end
	
	if CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[player:GetPlayerType()] then
		return false
	end
	
	if CustomHealthAPI.Helper.PlayerIsTheSoul(player) then
		local subplayer = player:GetSubPlayer()
		if subplayer ~= nil then
			return CustomHealthAPI.Helper.CanPickRed(subplayer, key)
		else
			return false
		end
	end
	
	if CustomHealthAPI.Helper.GetRedCapacity(player) > CustomHealthAPI.Helper.GetTotalRedHP(player, true) then
		return true
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	
	local addPriorityOfKey = CustomHealthAPI.PersistentData.HealthDefinitions[key].AddPriority
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if health.Key ~= key and
			   addPriorityOfKey >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			then
				return true
			elseif health.HP < CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP") then
				return true
			end
		end
	end

	return false
end

function CustomHealthAPI.Helper.CanPickSoul(player, key)
	if player:GetPlayerType() == PlayerType.PLAYER_BETHANY then
		return player:GetSoulCharge() < 99
	end
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CanPickSoul(player:GetOtherTwin(), key)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if key == "BLACK_HEART" then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts(player)
		else
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts(player)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
		local subplayer = player:GetSubPlayer()
		if subplayer ~= nil then
			return CustomHealthAPI.Helper.CanPickSoul(subplayer, key)
		else
			return false
		end
	end
	
	local alabasterChargesToAdd = 0
	for i = 0, 2 do
		if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
		end
	end
	if alabasterChargesToAdd > 0 then
		return true
	end
	
	if CustomHealthAPI.Helper.GetRoomForOtherKeys(player) > 0 then
		return true
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	local addPriorityOfKey = CustomHealthAPI.PersistentData.HealthDefinitions[key].AddPriority
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
				if health.Key ~= key and
				   addPriorityOfKey >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				then
					return true
				elseif health.HP < CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP") then
					return true
				end
			end
		end
	end

	return false
end

function CustomHealthAPI.Helper.CanPickContainer(player, key)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CanPickContainer(player:GetOtherTwin(), key)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") >= 1 and not CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE then
			return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts(player)
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE then
			return CustomHealthAPI.PersistentData.GetHeartLimit(player) > 0
		elseif CustomHealthAPI.Helper.PlayerIsKeeper(player) then
			return CustomHealthAPI.PersistentData.GetHeartLimit(player) - math.ceil(CustomHealthAPI.PersistentData.GetMaxHearts / 2) > 0
		else
			return false
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsTheSoul(player) then
		local subplayer = player:GetSubPlayer()
		if subplayer ~= nil then
			return CustomHealthAPI.Helper.CanPickContainer(subplayer, key)
		else
			return false
		end
	elseif CustomHealthAPI.Helper.PlayerIsTheForgotten(player) and
	       CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") <= 0
	then
		return false
	end
	
	if CustomHealthAPI.Helper.GetRoomForOtherKeys(player) > 0 then
		return true
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	local addPriorityOfKey = CustomHealthAPI.PersistentData.HealthDefinitions[key].AddPriority
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
				return true
			elseif CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
				if health.Key ~= key and
				   addPriorityOfKey >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				then
					return true
				end
			end
		end
	end

	return false
end
