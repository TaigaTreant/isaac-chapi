function CustomHealthAPI.Helper.AddHeartSpikesCostCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_PICKUP_COLLISION, -1 * math.huge, CustomHealthAPI.Mod.HeartSpikesCostCallback, PickupVariant.PICKUP_HEART)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHeartSpikesCostCallback)

function CustomHealthAPI.Helper.RemoveHeartSpikesCostCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, CustomHealthAPI.Mod.HeartSpikesCostCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHeartSpikesCostCallback)

function CustomHealthAPI.Mod:HeartSpikesCostCallback(pickup, collider)
	local data = pickup:GetData()
	data.CHAPIHeartPickupSpentSpikesCostAlready = nil
end

function CustomHealthAPI.Helper.AddHeartCollisionCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_PICKUP_COLLISION, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.HeartCollisionCallback, PickupVariant.PICKUP_HEART)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHeartCollisionCallback)

function CustomHealthAPI.Helper.RemoveHeartCollisionCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, CustomHealthAPI.Mod.HeartCollisionCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHeartCollisionCallback)

function CustomHealthAPI.Helper.IsHoldingTaintedForgotten(player)
	local forgo = player:GetOtherTwin()
	return forgo and
	       math.abs(forgo.Position.X - player.Position.X) < 0.000001 and
	       math.abs(forgo.Position.Y - player.Position.Y) < 0.000001 and
	       player:IsHoldingItem() and
	       forgo:HasEntityFlags(EntityFlag.FLAG_HELD)
end

function CustomHealthAPI.Helper.CheckIfHeartShouldUseCustomLogic(player, pickup)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then 
		return false
	end
	
	if pickup.Price == PickupPrice.PRICE_SPIKES then
		return true
	end

	local hearttype = pickup.SubType
	local redIsDoubled = player:HasCollectible(CollectibleType.COLLECTIBLE_MAGGYS_BOW)
	
	if hearttype == HeartSubType.HEART_FULL then
		if redIsDoubled then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 4)
		else
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 2)
		end
	elseif hearttype == HeartSubType.HEART_HALF then
		if redIsDoubled then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 2)
		else
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 1)
		end
	elseif hearttype == HeartSubType.HEART_SOUL then
		return CustomHealthAPI.Helper.CheckIfSoulShouldUseCustomLogic(player, 2)
	elseif hearttype == HeartSubType.HEART_ETERNAL then
		return CustomHealthAPI.Helper.CheckIfEternalShouldUseCustomLogic(player, 1)
	elseif hearttype == HeartSubType.HEART_DOUBLEPACK then
		if redIsDoubled then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 8)
		else
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 4)
		end
	elseif hearttype == HeartSubType.HEART_BLACK then
		return CustomHealthAPI.Helper.CheckIfBlackShouldUseCustomLogic(player, 2)
	elseif hearttype == HeartSubType.HEART_GOLDEN then
		return CustomHealthAPI.Helper.CheckIfGoldenShouldUseCustomLogic(player)
	elseif hearttype == HeartSubType.HEART_HALF_SOUL then
		return CustomHealthAPI.Helper.CheckIfSoulShouldUseCustomLogic(player, 1)
	elseif hearttype == HeartSubType.HEART_SCARED then
		if redIsDoubled then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 4)
		else
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, 2)
		end
	elseif hearttype == HeartSubType.HEART_BONE then
		return CustomHealthAPI.Helper.CheckIfBoneShouldUseCustomLogic(player, 1)
	elseif hearttype == HeartSubType.HEART_ROTTEN then
		return CustomHealthAPI.Helper.CheckIfRottenShouldUseCustomLogic(player, 2)
	else
		return true
	end
end

function CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player, hp)
	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts(player) ~= CustomHealthAPI.Helper.CanPickKey(player, "RED_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
		if player:GetSubPlayer() ~= nil then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player:GetSubPlayer(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfRedShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	elseif CustomHealthAPI.Helper.PlayerIsRedHealthless(player, true) then
		return false
	end
	
	local basegameRedCapacity = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) + 
	                            CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player) * 2
	local basegameRedToFullHealth = basegameRedCapacity - CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	
	if basegameRedToFullHealth >= hp then
		return false
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	
	local addPriorityOfRed = CustomHealthAPI.PersistentData.HealthDefinitions["RED_HEART"].AddPriority
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if health.Key ~= "RED_HEART" and
			   addPriorityOfRed >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			then
				return true
			end
		end
	end
	
	local customUnoccupiedRedCapacity = CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) * 2
	local customMissingRed = CustomHealthAPI.Helper.GetHealableRedHP(player)
	local customRedToFullHealth = customMissingRed + customUnoccupiedRedCapacity
	
	if customRedToFullHealth <= basegameRedToFullHealth then
		return false
	end
	
	return true
end

function CustomHealthAPI.Helper.CheckIfRottenShouldUseCustomLogic(player, hp)
	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts(player) ~= CustomHealthAPI.Helper.CanPickKey(player, "ROTTEN_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
		if player:GetSubPlayer() ~= nil then
			return CustomHealthAPI.Helper.CheckIfRottenShouldUseCustomLogic(player:GetSubPlayer(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfRottenShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	elseif CustomHealthAPI.Helper.PlayerIsRedHealthless(player, true) then
		return false
	end
	
	return false
end

function CustomHealthAPI.Helper.CheckIfSoulShouldUseCustomLogic(player, hp)
	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts(player) ~= CustomHealthAPI.Helper.CanPickKey(player, "SOUL_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then
		if player:GetSubPlayer() ~= nil then
			return CustomHealthAPI.Helper.CheckIfSoulShouldUseCustomLogic(player:GetSubPlayer(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfSoulShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_BETHANY then
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	end
	
	local alabasterChargesToAdd = 0
	for i = 0, 2 do
		if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
		end
	end
	if alabasterChargesToAdd >= hp then
		return false
	end
	local hp = hp - alabasterChargesToAdd
	
	local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
	if numShacklesDisabled > 0 then
		if hp <= 2 then
			return false
		end
		hp = hp - 2
	end
	
	local basegameSoulToFullHealth = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) -
	                                 (math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2) * 2 +
	                                  CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player) * 2 +
	                                  CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player))
	
	if basegameSoulToFullHealth >= hp then
		return false
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	local addPriorityOfSoul = CustomHealthAPI.PersistentData.HealthDefinitions["SOUL_HEART"].AddPriority
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
				if health.Key ~= "SOUL_HEART" and
				   addPriorityOfSoul >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				then
					return true
				end
			end
		end
	end
	
	local customUnoccupiedSoulCapacity = CustomHealthAPI.Helper.GetRoomForOtherKeys(player) * 2
	local customMissingSoul = CustomHealthAPI.Helper.GetHealableSoulHP(player)
	local customSoulToFullHealth = customMissingSoul + customUnoccupiedSoulCapacity
	
	if customSoulToFullHealth <= basegameSoulToFullHealth then
		return false
	end
	
	return true
end

function CustomHealthAPI.Helper.CheckIfBlackShouldUseCustomLogic(player, hp)
	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts(player) ~= CustomHealthAPI.Helper.CanPickKey(player, "BLACK_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then
		if player:GetSubPlayer() ~= nil then
			return CustomHealthAPI.Helper.CheckIfBlackShouldUseCustomLogic(player:GetSubPlayer(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfBlackShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_BETHANY then
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	end
	
	local alabasterChargesToAdd = 0
	for i = 0, 2 do
		if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
		end
	end
	if alabasterChargesToAdd >= hp then
		return false
	end
	local hp = hp - alabasterChargesToAdd
	
	local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
	if numShacklesDisabled > 0 then
		if hp <= 2 then
			return false
		end
		hp = hp - 2
	end
	
	return false
end

function CustomHealthAPI.Helper.CheckIfEternalShouldUseCustomLogic(player, hp)
	if not CustomHealthAPI.Helper.CanPickKey(player, "ETERNAL_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfEternalShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	end
	
	local completedEternals = math.floor((CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player) + hp) / 2)
	if completedEternals <= 0 then
		return false
	else
		return true
	end
end

function CustomHealthAPI.Helper.CheckIfBoneShouldUseCustomLogic(player, hp)
	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts(player) ~= CustomHealthAPI.Helper.CanPickKey(player, "BONE_HEART") then
		return true
	elseif player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN then
		if player:GetSubPlayer() ~= nil then
			return CustomHealthAPI.Helper.CheckIfBoneShouldUseCustomLogic(player:GetSubPlayer(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.CheckIfBoneShouldUseCustomLogic(player:GetOtherTwin(), hp)
		end
		return false
	elseif player:GetPlayerType() == PlayerType.PLAYER_BETHANY then
		return false
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return false
	end
	
	local basegameBoneToFullHealth = math.ceil((CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) -
	                                           (math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2) * 2 +
	                                            CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player) * 2 +
	                                            CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player))) / 2)
	
	if basegameBoneToFullHealth >= hp then
		return false
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	local addPriorityOfBone = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].AddPriority
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
				return false
			end
		end
	end
	
	return true
end

function CustomHealthAPI.Helper.CheckIfGoldenShouldUseCustomLogic(player)
	return not CustomHealthAPI.Helper.CanPickKey(player, "GOLDEN_HEART")
end

function CustomHealthAPI.Library.GetRedHPToBeSpent(p, hpToAdd)
	local player = p:ToPlayer()
	if player == nil then
		return 0
	end
	
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_BETHANY_B then
		if player:CanPickRedHearts() then
			local bloodChargeToMax = 99 - player:GetBloodCharge()
			return math.min(bloodChargeToMax, hpToAdd)
		end
		
		return 0
	elseif playerType == PlayerType.PLAYER_THESOUL then
		player = player:GetSubPlayer()
		if player == nil then
			return 0
		end
	end
	
	if player:CanPickRedHearts() then
		local hpData = player:GetData().CustomHealthAPISavedata
		if hpData ~= nil then
			local redMasks = hpData.RedHealthMasks
			local addPriorityOfRed = CustomHealthAPI.PersistentData.HealthDefinitions["RED_HEART"].AddPriority
			local hpToOverwrite = 0
			local customMissingRed = 0
			for i = 1, #redMasks do
				local mask = redMasks[i]
				for j = 1, #mask do
					local health = mask[j]
					if health.Key ~= "RED_HEART" and
					   addPriorityOfRed >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
					then
						hpToOverwrite = hpToOverwrite + 2
					else
						local maxHP = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP
						customMissingRed = customMissingRed + (maxHP - health.HP)
					end
				end
			end
			
			local customUnoccupiedRedCapacity = CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) * 2
			local customRedToFullHealth = customMissingRed + customUnoccupiedRedCapacity
			
			return math.min(customRedToFullHealth + hpToOverwrite, hpToAdd)
		end
	end
	
	return 0
end

function CustomHealthAPI.Library.GetSoulHPToBeSpent(p, hpToAdd, heartKey)
	local player = p:ToPlayer()
	if player == nil then
		return 0
	end
	
	local maxHpOfSoul = math.max(2, CustomHealthAPI.Library.GetInfoOfKey(heartKey, "MaxHP"))
	
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_BETHANY then
		if player:CanPickSoulHearts() then
			local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
			local hpSpentReactivatingShackles = math.max(0, maxHpOfSoul * numShacklesDisabled)
	
			local alabasterChargesToAdd = 0
			for i = 0, 2 do
				if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
					alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
				end
			end
			
			local soulChargeToMax = 99 - player:GetSoulCharge()
			return math.min(soulChargeToMax + alabasterChargesToAdd + hpSpentReactivatingShackles, hpToAdd)
		end
		
		return 0
	elseif CustomHealthAPI.Helper.PlayerIsHealthless(player, true) or CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
		local hpSpentReactivatingShackles = math.max(0, maxHpOfSoul * numShacklesDisabled)
	
		local alabasterChargesToAdd = 0
		for i = 0, 2 do
			if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
				alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
			end
		end
		
		return alabasterChargesToAdd + hpSpentReactivatingShackles
	elseif playerType == PlayerType.PLAYER_THEFORGOTTEN then
		player = player:GetSubPlayer()
		if player == nil then
			player = p:ToPlayer()

			local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
			local hpSpentReactivatingShackles = math.max(0, maxHpOfSoul * numShacklesDisabled)
		
			local alabasterChargesToAdd = 0
			for i = 0, 2 do
				if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
					alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
				end
			end
			
			return alabasterChargesToAdd + hpSpentReactivatingShackles
		end
	end
	
	if CustomHealthAPI.Library.CanPickKey(player, heartKey) then
		local hpData = player:GetData().CustomHealthAPISavedata
		if hpData ~= nil then
			local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
			local hpSpentReactivatingShackles = math.max(0, maxHpOfSoul * numShacklesDisabled)
	
			local alabasterChargesToAdd = 0
			for i = 0, 2 do
				if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
					alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
				end
			end
			
			local otherMasks = hpData.OtherHealthMasks
			local addPriorityOfSoul = CustomHealthAPI.PersistentData.HealthDefinitions[heartKey].AddPriority
			local hpToOverwrite = 0
			local customMissingSoul = 0
			for i = 1, #otherMasks do
				local mask = otherMasks[i]
				for j = 1, #mask do
					local health = mask[j]
					if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
						if health.Key ~= heartKey and
						   addPriorityOfSoul >= CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
						then
							hpToOverwrite = hpToOverwrite + maxHpOfSoul
						else
							local maxHP = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP
							customMissingSoul = customMissingSoul + (maxHP - health.HP)
						end
					end
				end
			end
			
			local customUnoccupiedSoulCapacity = CustomHealthAPI.Helper.GetRoomForOtherKeys(player) * math.max(2, CustomHealthAPI.PersistentData.HealthDefinitions[heartKey].MaxHP)
			local customSoulToFullHealth = customMissingSoul + customUnoccupiedSoulCapacity
			
			return math.min(customSoulToFullHealth + hpToOverwrite + alabasterChargesToAdd + hpSpentReactivatingShackles, hpToAdd)
		end
	end
	
	return 0
end

function CustomHealthAPI.Library.AddCandyHeartBonus(pl, candiesToAdd, seed)
	local player = pl:ToPlayer()
	if player == nil then
		return
	end

	if player:HasCollectible(CollectibleType.COLLECTIBLE_CANDY_HEART) and candiesToAdd > 0 then
		local rng = RNG()
		rng:SetSeed(seed, 35)
		
		local p = player
		player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
		local pdata = player:GetData().CustomHealthAPIPersistent
		
		if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
			if player:GetOtherTwin() ~= nil then
				local p = player:GetOtherTwin()
				player:GetOtherTwin():GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
				pdata = player:GetOtherTwin():GetData().CustomHealthAPIPersistent
			end
		end
		
		for i = 1, candiesToAdd do
			local rand = math.random(1, 6)
			if rand == 1 then
				pdata.FakeCandyHeartDamage = (pdata.FakeCandyHeartDamage or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			elseif rand == 2 then
				pdata.FakeCandyHeartTears = (pdata.FakeCandyHeartTears or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
			elseif rand == 3 then
				pdata.FakeCandyHeartSpeed = (pdata.FakeCandyHeartSpeed or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_SPEED)
			elseif rand == 4 then
				pdata.FakeCandyHeartShotSpeed = (pdata.FakeCandyHeartShotSpeed or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
			elseif rand == 5 then
				pdata.FakeCandyHeartRange = (pdata.FakeCandyHeartRange or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_RANGE)
			else
				pdata.FakeCandyHeartLuck = (pdata.FakeCandyHeartLuck or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_LUCK)
			end
		end

		p:EvaluateItems()
	end
end

function CustomHealthAPI.Library.AddSoulLocketBonus(pl, locketsToAdd, seed)
	local player = pl:ToPlayer()
	if player == nil then
		return
	end

	if player:HasCollectible(CollectibleType.COLLECTIBLE_SOUL_LOCKET) and locketsToAdd > 0 then
		local rng = RNG()
		rng:SetSeed(seed, 40)
		
		local p = player
		player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
		local pdata = player:GetData().CustomHealthAPIPersistent
		
		if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
			if player:GetOtherTwin() ~= nil then
				local p = player:GetOtherTwin()
				player:GetOtherTwin():GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
				pdata = player:GetOtherTwin():GetData().CustomHealthAPIPersistent
			end
		end
		
		for i = 1, locketsToAdd do
			local rand = math.random(1, 6)
			if rand == 1 then
				pdata.FakeSoulLocketDamage = (pdata.FakeSoulLocketDamage or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			elseif rand == 2 then
				pdata.FakeSoulLocketTears = (pdata.FakeSoulLocketTears or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
			elseif rand == 3 then
				pdata.FakeSoulLocketSpeed = (pdata.FakeSoulLocketSpeed or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_SPEED)
			elseif rand == 4 then
				pdata.FakeSoulLocketShotSpeed = (pdata.FakeSoulLocketShotSpeed or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
			elseif rand == 5 then
				pdata.FakeSoulLocketRange = (pdata.FakeSoulLocketRange or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_RANGE)
			else
				pdata.FakeSoulLocketLuck = (pdata.FakeSoulLocketLuck or 0) + 1
				p:AddCacheFlags(CacheFlag.CACHE_LUCK)
			end
		end

		p:EvaluateItems()
	end
end

function CustomHealthAPI.Library.IncrementImmaculateConception(pl, amount, seed)
	if not REPENTOGON or amount <= 0 then
		return
	end
	
	local player = pl:ToPlayer()
	if player == nil or not player:HasCollectible(CollectibleType.COLLECTIBLE_IMMACULATE_CONCEPTION) then
		return
	end

	local heartsCollected = player:GetImmaculateConceptionState() + amount
	while heartsCollected >= 15 do
		local flags = player:GetConceptionFamiliarFlags()
		local availableFamiliars = {}
		if flags & ConceptionFamiliarFlag.GUARDIAN_ANGEL ~= ConceptionFamiliarFlag.GUARDIAN_ANGEL then
			table.insert(availableFamiliars, ConceptionFamiliarFlag.GUARDIAN_ANGEL)
		end
		if flags & ConceptionFamiliarFlag.HOLY_WATER ~= ConceptionFamiliarFlag.HOLY_WATER then
			table.insert(availableFamiliars, ConceptionFamiliarFlag.HOLY_WATER)
		end
		if flags & ConceptionFamiliarFlag.RELIC ~= ConceptionFamiliarFlag.RELIC then
			table.insert(availableFamiliars, ConceptionFamiliarFlag.RELIC)
		end
		if flags & ConceptionFamiliarFlag.SWORN_PROTECTOR ~= ConceptionFamiliarFlag.SWORN_PROTECTOR then
			table.insert(availableFamiliars, ConceptionFamiliarFlag.SWORN_PROTECTOR)
		end
		if flags & ConceptionFamiliarFlag.SERAPHIM ~= ConceptionFamiliarFlag.SERAPHIM then
			table.insert(availableFamiliars, ConceptionFamiliarFlag.SERAPHIM)
		end
		if #availableFamiliars > 0 then
			local rng = RNG()
			rng:SetSeed(seed, 40)
			
			local flag = availableFamiliars[rng:RandomInt(#availableFamiliars) + 1]
			local continue = Isaac.RunCallback(ModCallbacks.MC_PRE_PLAYER_GIVE_BIRTH_IMMACULATE, player, flag)
			if continue ~= false then
				player:SetConceptionFamiliarFlags(flags | flag)
				player:AddCacheFlags(CacheFlag.CACHE_FAMILIARS, true)
			end
		end
		
		Isaac.Spawn(5, 10, 3, Game():GetRoom():FindFreePickupSpawnPosition(player.Position), Vector.Zero, player)
		
		heartsCollected = heartsCollected - 15
	end
	player:SetImmaculateConceptionState(heartsCollected)
	player:UpdateIsaacPregnancy(false)
end

function CustomHealthAPI.Mod:HeartCollisionCallback(pickup, collider)
	if collider.Type == EntityType.ENTITY_PLAYER then
		local player = collider:ToPlayer()
		local hearttype = pickup.SubType
		local sprite = pickup:GetSprite()
		
		local redIsDoubled = player:HasCollectible(CollectibleType.COLLECTIBLE_MAGGYS_BOW)
		local canJarRedHearts = player:HasCollectible(CollectibleType.COLLECTIBLE_THE_JAR) and player:GetJarHearts() < 8
		local hasSodomApple = player:HasTrinket(TrinketType.TRINKET_APPLE_OF_SODOM)
		
		local data = pickup:GetData()
		if hearttype < 1 or hearttype > 12 or CustomHealthAPI.Helper.PlayerIsHealthless(player, true) then
			return
		elseif player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B and CustomHealthAPI.Helper.IsHoldingTaintedForgotten(player) then
			return CustomHealthAPI.Mod:HeartCollisionCallback(pickup, player:GetOtherTwin())
		elseif pickup:IsShopItem() and 
		       (pickup.Price > player:GetNumCoins() or 
			    (not player:IsExtraAnimationFinished() and not data.CHAPIHeartPickupSpentSpikesCostAlready))
		then
			return true
		elseif sprite:IsPlaying("Collect") then
			return true
		elseif pickup.Wait > 0 then
			return not (sprite:IsPlaying("Idle") or sprite:IsPlaying("IdlePanic"))
		elseif sprite:WasEventTriggered("DropSound") or sprite:IsPlaying("Idle") or sprite:IsPlaying("IdlePanic") then
			if not CustomHealthAPI.Helper.CheckIfHeartShouldUseCustomLogic(player, pickup) then
				return
			end
			
			local redHealthBefore = player:GetHearts()
			local soulHealthBefore = player:GetSoulHearts()
			
			if pickup.Price == PickupPrice.PRICE_SPIKES and 
			   not (data.CHAPIHeartPickupSpentSpikesCostAlready or 
			        player:GetPlayerType() == PlayerType.PLAYER_JACOB2_B or 
			        player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE))
			then
---@diagnostic disable-next-line: param-type-mismatch
				local tookDamage = player:TakeDamage(2.0, DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_NO_PENALTIES, EntityRef(nil), 30)
				if not tookDamage then
					return pickup:IsShopItem()
				end
			end
			
			local shouldApple = false
			if hasSodomApple then
				local applerng = RNG()
				applerng:SetSeed(pickup.InitSeed, 1)
				shouldApple = applerng:RandomInt(2) == 1
			end
			
			local removeWithNoAnim = false
			local shouldSetHeartPicked = true
			if hearttype == HeartSubType.HEART_FULL and shouldApple then
				local mod = 3
				if redIsDoubled then
					mod = mod * 2
				end
				CustomHealthAPI.Helper.HandleSodomAppleEffects(player, pickup, mod)
				removeWithNoAnim = true
				shouldSetHeartPicked = false
			elseif hearttype == HeartSubType.HEART_HALF and shouldApple then
				local mod = 1
				if redIsDoubled then
					mod = mod * 2
				end
				CustomHealthAPI.Helper.HandleSodomAppleEffects(player, pickup, mod)
				removeWithNoAnim = true
				shouldSetHeartPicked = false
			elseif hearttype == HeartSubType.HEART_DOUBLEPACK and shouldApple then
				local mod = 6
				if redIsDoubled then
					mod = mod * 2
				end
				CustomHealthAPI.Helper.HandleSodomAppleEffects(player, pickup, mod)
				removeWithNoAnim = true
				shouldSetHeartPicked = false
			elseif hearttype == HeartSubType.HEART_FULL and CustomHealthAPI.Helper.CanPickKey(player, "RED_HEART") then
				local hp = 2
				if redIsDoubled then
					hp = hp * 2
				end
				CustomHealthAPI.Library.AddHealth(player, "RED_HEART", hp, true)
				SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_HALF and CustomHealthAPI.Helper.CanPickKey(player, "RED_HEART") then
				local hp = 1
				if redIsDoubled then
					hp = hp * 2
				end
				CustomHealthAPI.Library.AddHealth(player, "RED_HEART", hp, true)
				SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_SOUL and CustomHealthAPI.Helper.CanPickKey(player, "SOUL_HEART") then
				CustomHealthAPI.Library.AddHealth(player, "SOUL_HEART", 2, true)
				SFXManager():Play(SoundEffect.SOUND_HOLY, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_ETERNAL and CustomHealthAPI.Helper.CanPickKey(player, "ETERNAL_HEART") then
				CustomHealthAPI.Library.AddHealth(player, "ETERNAL_HEART", 1, true)
				SFXManager():Play(SoundEffect.SOUND_SUPERHOLY, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_DOUBLEPACK and CustomHealthAPI.Helper.CanPickKey(player, "RED_HEART") then
				local hp = 4
				if redIsDoubled then
					hp = hp * 2
				end
				CustomHealthAPI.Library.AddHealth(player, "RED_HEART", hp, true)
				SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_BLACK and CustomHealthAPI.Helper.CanPickKey(player, "BLACK_HEART") then
				CustomHealthAPI.Library.AddHealth(player, "BLACK_HEART", 2, true)
				SFXManager():Play(SoundEffect.SOUND_UNHOLY, 1, 0, false, 1.0)
				
				if player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_REDEMPTION) == 1 and 
				   Game():GetRoom():GetType() == RoomType.ROOM_DEVIL 
				then
					for _, redemption in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.REDEMPTION)) do
						if redemption.Parent.Index == player.Index and redemption.Parent.InitSeed == redemption.Parent.InitSeed then
							redemption:GetSprite():Play("Fail", true)
							redemption:ToEffect().State = 3
						end
					end
					player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_REDEMPTION)
					SFXManager():Play(SoundEffect.SOUND_THUMBS_DOWN, 1, 0, false, 1.0)
				end
			elseif hearttype == HeartSubType.HEART_GOLDEN and CustomHealthAPI.Helper.CanPickKey(player, "GOLDEN_HEART") then
				CustomHealthAPI.Library.AddHealth(player, "GOLDEN_HEART", 1, true)
				SFXManager():Play(SoundEffect.SOUND_GOLD_HEART, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_HALF_SOUL and CustomHealthAPI.Helper.CanPickKey(player, "SOUL_HEART") then
				CustomHealthAPI.Library.AddHealth(player, "SOUL_HEART", 1, true)
				SFXManager():Play(SoundEffect.SOUND_HOLY, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_SCARED and CustomHealthAPI.Helper.CanPickKey(player, "RED_HEART") then
				local hp = 2
				if redIsDoubled then
					hp = hp * 2
				end
				CustomHealthAPI.Library.AddHealth(player, "RED_HEART", hp, true)
				SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_BLENDED and 
			       (CustomHealthAPI.Helper.CanPickKey(player, "RED_HEART") or CustomHealthAPI.Helper.CanPickKey(player, "SOUL_HEART"))
			then
				local hp = 2
				if CustomHealthAPI.Helper.CanPickKey(player, "RED_HEART") then
					if redIsDoubled then
						hp = hp * 2
					end
					local hpToSpend = CustomHealthAPI.Library.GetRedHPToBeSpent(player, hp)
					if hpToSpend > 0 then
						CustomHealthAPI.Library.AddHealth(player, "RED_HEART", hpToSpend, true)
						SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
						hp = hp - hpToSpend
					end
					if redIsDoubled then
						hp = math.floor(hp / 2)
					end
				end
				if CustomHealthAPI.Helper.CanPickKey(player, "SOUL_HEART") and hp > 0 then
					CustomHealthAPI.Library.AddHealth(player, "SOUL_HEART", hp, true)
					SFXManager():Play(SoundEffect.SOUND_HOLY, 1, 0, false, 1.0)
				end
			elseif hearttype == HeartSubType.HEART_BONE and CustomHealthAPI.Helper.CanPickKey(player, "BONE_HEART") then
				CustomHealthAPI.Library.AddHealth(player, "BONE_HEART", 1, true)
				SFXManager():Play(SoundEffect.SOUND_BONE_HEART, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_ROTTEN and CustomHealthAPI.Helper.CanPickKey(player, "ROTTEN_HEART") then
				CustomHealthAPI.Library.AddHealth(player, "ROTTEN_HEART", 2, true)
				SFXManager():Play(SoundEffect.SOUND_ROTTEN_HEART, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_FULL and canJarRedHearts then
				local hp = 2
				if redIsDoubled then
					hp = hp * 2
				end
				player:AddJarHearts(hp)
				SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_HALF and canJarRedHearts then
				local hp = 1
				if redIsDoubled then
					hp = hp * 2
				end
				player:AddJarHearts(hp)
				SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_DOUBLEPACK and canJarRedHearts then
				local hp = 4
				if redIsDoubled then
					hp = hp * 2
				end
				player:AddJarHearts(hp)
				SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_SCARED and canJarRedHearts then
				local hp = 2
				if redIsDoubled then
					hp = hp * 2
				end
				player:AddJarHearts(hp)
				SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
			elseif hearttype == HeartSubType.HEART_FULL and hasSodomApple then
				local mod = 3
				if redIsDoubled then
					mod = mod * 2
				end
				CustomHealthAPI.Helper.HandleSodomAppleEffects(player, pickup, mod)
				removeWithNoAnim = true
				shouldSetHeartPicked = false
			elseif hearttype == HeartSubType.HEART_HALF and hasSodomApple then
				local mod = 1
				if redIsDoubled then
					mod = mod * 2
				end
				CustomHealthAPI.Helper.HandleSodomAppleEffects(player, pickup, mod)
				removeWithNoAnim = true
				shouldSetHeartPicked = false
			elseif hearttype == HeartSubType.HEART_DOUBLEPACK and hasSodomApple then
				local mod = 6
				if redIsDoubled then
					mod = mod * 2
				end
				CustomHealthAPI.Helper.HandleSodomAppleEffects(player, pickup, mod)
				removeWithNoAnim = true
				shouldSetHeartPicked = false
			else
				return pickup:IsShopItem()
			end
			
			local redHealthAfter = player:GetHearts()
			local soulHealthAfter = player:GetSoulHearts()
			
			CustomHealthAPI.Library.AddCandyHeartBonus(player, redHealthAfter - redHealthBefore, pickup.InitSeed)
			CustomHealthAPI.Library.AddSoulLocketBonus(player, soulHealthAfter - soulHealthBefore, pickup.InitSeed)
			
			if hearttype ~= HeartSubType.HEART_GOLDEN and hearttype ~= HeartSubType.HEART_BLENDED then
				-- its clearly an oversight by basegame that these don't work but lol not my problem
				CustomHealthAPI.Library.IncrementImmaculateConception(collider, 1, pickup.InitSeed)
			end

			if pickup.OptionsPickupIndex ~= 0 then
				local pickups = Isaac.FindByType(EntityType.ENTITY_PICKUP)
				for _, entity in ipairs(pickups) do
					if entity:ToPickup().OptionsPickupIndex == pickup.OptionsPickupIndex and
					   (entity.Index ~= pickup.Index or entity.InitSeed ~= pickup.InitSeed)
					then
						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector.Zero, nil)
						entity:Remove()
					end
				end
			end

			if pickup:IsShopItem() then
				if not removeWithNoAnim then
					local pickupSprite = pickup:GetSprite()
					local holdSprite = Sprite()
					
					holdSprite:Load(pickupSprite:GetFilename(), true)
					holdSprite:Play(pickupSprite:GetAnimation(), true)
					holdSprite:SetFrame(pickupSprite:GetFrame())
					player:AnimatePickup(holdSprite)
				end
				
				if pickup.Price > 0 then
					player:AddCoins(-1 * pickup.Price)
				end
				
				CustomHealthAPI.Library.TriggerRestock(pickup)
				CustomHealthAPI.Helper.TryRemoveStoreCredit(player)
				
				pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				pickup:Remove()
			elseif removeWithNoAnim then
				pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				pickup:Remove()
			else
				sprite:Play("Collect", true)
				pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
				pickup:Die()
			end
			
			if shouldSetHeartPicked then
				Game():GetLevel():SetHeartPicked()
				Game():ClearStagesWithoutHeartsPicked()
				Game():SetStateFlag(GameStateFlag.STATE_HEART_BOMB_COIN_PICKED, true)
			end
			
			return true
		else
			return false
		end
	end
end

function CustomHealthAPI.Helper.HandleSodomAppleEffects(player, pickup, mod)
    -- thank you decomp
	SFXManager():Play(SoundEffect.SOUND_DEATH_BURST_SMALL, 1, 0, false, 1)
    
	local rng = RNG()
	rng:SetSeed(pickup.InitSeed, 45)
	
	local explo = Isaac.Spawn(1000, 2, 3, pickup.Position, Vector.Zero, nil)
	explo:Update()
	
	local splat = Isaac.Spawn(1000, 7, 0, pickup.Position, Vector.Zero, nil)
	splat:Update()
	
    local numGibs = rng:RandomInt(3) + mod
    for i = 1, numGibs do
		local gibpos = pickup.Position + Vector.FromAngle(rng:RandomFloat() * 360) * 0.5 * pickup.Size
		local gibvel = Vector.FromAngle(rng:RandomFloat() * 360) * (rng:RandomFloat() * 4.0 + 2.0)
		
---@diagnostic disable-next-line: param-type-mismatch
		local gib = Isaac.Spawn(1000, 5, 0, gibpos, gibvel, nil)
		gib:Update()
    end
	
    local numSpiders = rng:RandomInt(3) + mod
    for i = 1, numSpiders do
		local targetoffset = Vector.FromAngle(rng:RandomFloat() * 360) * (rng:RandomFloat() / 2 + 0.5) * 15
		player:ThrowBlueSpider(pickup.Position, pickup.Position + Vector(0, 60) + targetoffset)
    end
	
	Game():ButterBeanFart(pickup.Position, 100.0, player, true, false)
end

local function tearsUp(firedelay, val)
	local currentTears = 30 / (firedelay + 1)
	local newTears = currentTears + val
	return math.max((30 / newTears) - 1, -0.99)
end

function CustomHealthAPI.Helper.AddCandiesAndLocketsCacheCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_EVALUATE_CACHE, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.CandiesAndLocketsCacheCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddCandiesAndLocketsCacheCallback)

function CustomHealthAPI.Helper.RemoveCandiesAndLocketsCacheCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_EVALUATE_CACHE, CustomHealthAPI.Mod.CandiesAndLocketsCacheCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveCandiesAndLocketsCacheCallback)

function CustomHealthAPI.Mod:CandiesAndLocketsCacheCallback(player, flag)
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	local pdata = player:GetData().CustomHealthAPIPersistent
	
	if flag == CacheFlag.CACHE_SPEED then
		player.MoveSpeed = player.MoveSpeed + 0.02 * (pdata.FakeCandyHeartSpeed or 0)
		player.MoveSpeed = player.MoveSpeed + 0.04 * (pdata.FakeSoulLocketSpeed or 0)
	elseif flag == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage + 0.1 * (pdata.FakeCandyHeartDamage or 0)
		player.Damage = player.Damage + 0.2 * (pdata.FakeSoulLocketDamage or 0)
	elseif flag == CacheFlag.CACHE_FIREDELAY then
		player.MaxFireDelay = tearsUp(player.MaxFireDelay, 0.05 * (pdata.FakeCandyHeartTears or 0))
		player.MaxFireDelay = tearsUp(player.MaxFireDelay, 0.1 * (pdata.FakeSoulLocketTears or 0))
	elseif flag == CacheFlag.CACHE_RANGE then
		player.TearRange = player.TearRange + 6 * (pdata.FakeCandyHeartRange or 0)
		player.TearRange = player.TearRange + 12 * (pdata.FakeSoulLocketRange or 0)
	elseif flag == CacheFlag.CACHE_SHOTSPEED then
		player.ShotSpeed = player.ShotSpeed + 0.02 * (pdata.FakeCandyHeartShotSpeed or 0)
		player.ShotSpeed = player.ShotSpeed + 0.04 * (pdata.FakeSoulLocketShotSpeed or 0)
	elseif flag == CacheFlag.CACHE_LUCK then
		player.Luck = player.Luck + 0.1 * (pdata.FakeCandyHeartLuck or 0)
		player.Luck = player.Luck + 0.2 * (pdata.FakeSoulLocketLuck or 0)
	end
end

function CustomHealthAPI.Helper.AddClearCandiesAndLocketsCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.ClearCandiesAndLocketsCallback, CollectibleType.COLLECTIBLE_D4)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddClearCandiesAndLocketsCallback)

function CustomHealthAPI.Helper.RemoveClearCandiesAndLocketsCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.ClearCandiesAndLocketsCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveClearCandiesAndLocketsCallback)

function CustomHealthAPI.Mod:ClearCandiesAndLocketsCallback(id, rng, player)
	CustomHealthAPI.Helper.ClearCandiesAndLockets(player)
end

function CustomHealthAPI.Helper.ClearCandiesAndLockets(player)
	local p = player
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	local pdata = player:GetData().CustomHealthAPIPersistent
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			local p = player:GetOtherTwin()
			player:GetOtherTwin():GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
			pdata = player:GetOtherTwin():GetData().CustomHealthAPIPersistent
		end
	end
	
	pdata.FakeCandyHeartDamage = nil
	pdata.FakeCandyHeartTears = nil
	pdata.FakeCandyHeartSpeed = nil
	pdata.FakeCandyHeartShotSpeed = nil
	pdata.FakeCandyHeartRange = nil
	pdata.FakeCandyHeartLuck = nil
	
	pdata.FakeSoulLocketDamage = nil
	pdata.FakeSoulLocketTears = nil
	pdata.FakeSoulLocketSpeed = nil
	pdata.FakeSoulLocketShotSpeed = nil
	pdata.FakeSoulLocketRange = nil
	pdata.FakeSoulLocketLuck = nil
	
	player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | 
	                     CacheFlag.CACHE_FIREDELAY | 
	                     CacheFlag.CACHE_SPEED | 
	                     CacheFlag.CACHE_SHOTSPEED | 
	                     CacheFlag.CACHE_RANGE | 
	                     CacheFlag.CACHE_LUCK)
	
	player:EvaluateItems()
end
