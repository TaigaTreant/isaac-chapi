-- ADD PROPER HALFCAPACITY CONTAINER SUPPORT (+ RED HP HANDLING OF CAPACITY)
-- ADD ACTUAL SUPPORT FOR CONTAINER HP / HEALING
-- HANDLE ETERNAL/GOLD HP WHEN RED/OTHER HP IS REMOVED
-- NEED BETTER CONTAINER CONVERSION LOGIC MAYBE
-- REVISE FOR HALFCAPACITY / CONTAINER HP

function CustomHealthAPI.Library.AddHealth(player, k, h, ignoreTaintedMaggieDoubling, ignoreBethanyCharges, avoidRemovingBone, ignoreStrength, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Library.AddHealth(player:GetOtherTwin(), k, h, ignoreTaintedMaggieDoubling, ignoreBethanyCharges, avoidRemovingBone, ignoreStrength, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
		end
	end
	
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then 
		if not (player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B or CustomHealthAPI.Helper.IsFoundSoul(player) or player:IsCoopGhost()) then
			CustomHealthAPI.Helper.UseOverriddenAddFunctionForKeeperAndLost(player, k, h)
		end
		return
	end
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	
	CustomHealthAPI.PersistentData.PreventResyncing = true
	local key = k
	local hp = h
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_ADD_HEALTH)
	for _, callback in ipairs(callbacks) do
		local returnA, returnB = callback.Function(player, key, hp)
		if returnA == true then
			CustomHealthAPI.PersistentData.PreventResyncing = false
			return
		elseif returnA ~= nil and returnB ~= nil then
			key = returnA
			hp = returnB
		end
	end
	CustomHealthAPI.PersistentData.PreventResyncing = false
	
	if math.ceil(hp) == 0 then
		return
	end
	
	local healthType = CustomHealthAPI.PersistentData.HealthDefinitions[key].Type
	local playerType = player:GetPlayerType()
	if healthType == CustomHealthAPI.Enums.HealthTypes.RED then
		if not ignoreHaveAHeart and Game().Challenge == Challenge.CHALLENGE_HAVE_A_HEART then
			return
		elseif playerType == PlayerType.PLAYER_BETHANY_B then
			if key == "RED_HEART" then
				if not ignoreBethanyCharges then
					player:AddBloodCharge(hp)
				end
			end
			return
		elseif playerType == PlayerType.PLAYER_THESOUL then
			local subplayer = player:GetSubPlayer()
			if subplayer ~= nil then
				CustomHealthAPI.Library.AddHealth(subplayer, key, hp, ignoreTaintedMaggieDoubling, ignoreBethanyCharges, avoidRemovingBone, ignoreStrength, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
			end
			return
		elseif CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[playerType] then
			return
		end
		
		local hpToAdd = math.ceil(hp)
		if playerType == PlayerType.PLAYER_MAGDALENE_B and not ignoreTaintedMaggieDoubling and hpToAdd > 0 then
			hpToAdd = hpToAdd * 2
		end
		
		CustomHealthAPI.Helper.AddRedMain(player, key, hpToAdd)
		
		if not ignoreShardOfGlass then
			player:GetData().CustomHealthAPISavedata.ShardBleedTimer = nil
		end
	elseif healthType == CustomHealthAPI.Enums.HealthTypes.SOUL then
		if playerType == PlayerType.PLAYER_BETHANY then
			local hpToAdd = math.ceil(hp)
			
			if not ignoreSpiritShackles then
				local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
				if numShacklesDisabled > 0 and hpToAdd > 0 then
					hpToAdd = math.max(0, hpToAdd - CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP"))
					player:GetEffects():RemoveNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED, numShacklesDisabled)
					player:GetData().CustomHealthAPIOtherData.ShacklesDisabled = false
				end
			end
			
			if not ignoreAlabasterBox then
				local alabasterChargesToAdd = 0
				for i = 0, 2 do
					if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
						alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
					end
				end
				if alabasterChargesToAdd > 0 and hpToAdd > 0 then
					local hpCharging = math.min(alabasterChargesToAdd, hpToAdd)
					CustomHealthAPI.Helper.AddSoulHeartsKissesFix(player, hpCharging)
					player:GetData().CustomHealthAPIOtherData.AlabasterChargesToAdd = math.max(0, alabasterChargesToAdd - hpCharging)
					hpToAdd = math.max(0, hpToAdd - hpCharging)
				end
			end
		
			if not ignoreBethanyCharges then
				if CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") <= 1 then
					player:AddSoulCharge(hpToAdd * 2)
				else
					player:AddSoulCharge(hpToAdd)
				end
			end
			return
		elseif playerType == PlayerType.PLAYER_THEFORGOTTEN then
			local subplayer = player:GetSubPlayer()
			if subplayer ~= nil then
				CustomHealthAPI.Library.AddHealth(subplayer, key, hp, ignoreTaintedMaggieDoubling, ignoreBethanyCharges, avoidRemovingBone, ignoreStrength, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
			end
			return
		end
		
		local hpToAdd = math.ceil(hp)
		
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		
		if not ignoreSpiritShackles then
			local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
			if numShacklesDisabled > 0 and hpToAdd > 0 then
				hpToAdd = math.max(0, hpToAdd - CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP"))
				player:GetEffects():RemoveNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED, numShacklesDisabled)
				player:GetData().CustomHealthAPIOtherData.ShacklesDisabled = false
			end
		end
		
		if not ignoreAlabasterBox then
			local alabasterChargesToAdd = 0
			for i = 0, 2 do
				if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
					alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
				end
			end
			if alabasterChargesToAdd > 0 and hpToAdd > 0 then
				local hpCharging = math.min(alabasterChargesToAdd, hpToAdd)
				CustomHealthAPI.Helper.AddSoulHeartsKissesFix(player, hpCharging)
				player:GetData().CustomHealthAPIOtherData.AlabasterChargesToAdd = math.max(0, alabasterChargesToAdd - hpCharging)
				hpToAdd = math.max(0, hpToAdd - hpCharging)
			end
		end
		
		local leftoverHP = 0
		if hpToAdd ~= 0 then
			leftoverHP = CustomHealthAPI.Helper.AddSoulMain(player, key, hpToAdd)
		end
		
		local hpDiff = hpToAdd - leftoverHP
		if hpDiff < 0 and not ignoreStrength then
			CustomHealthAPI.Helper.SubtractTemporaryHP(player, key, hpDiff)
		end
	elseif healthType == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		if playerType == PlayerType.PLAYER_THEFORGOTTEN and 
		   CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") <= 0 and
		   CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained") ~= CustomHealthAPI.Enums.HealthKinds.NONE
		then
			local hpToAdd = math.ceil(hp)
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity then
				hpToAdd = math.ceil(hpToAdd / 2)
			end
			CustomHealthAPI.Library.AddHealth(player, "BONE_HEART", hpToAdd, ignoreTaintedMaggieDoubling, ignoreBethanyCharges, avoidRemovingBone, ignoreStrength, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
			return
		elseif playerType == PlayerType.PLAYER_THESOUL and 
		   CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained") ~= CustomHealthAPI.Enums.HealthKinds.NONE
		then
			if CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") > 0 then
				local subplayer = player:GetSubPlayer()
				if subplayer ~= nil then
					CustomHealthAPI.Library.AddHealth(subplayer, key, hp, ignoreTaintedMaggieDoubling, ignoreBethanyCharges, avoidRemovingBone, ignoreStrength, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
				end
			else
				local hpToAdd = math.ceil(hp)
				if not CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity then
					hpToAdd = hpToAdd * 2
				end
				CustomHealthAPI.Library.AddHealth(player, "SOUL_HEART", hpToAdd, ignoreTaintedMaggieDoubling, ignoreBethanyCharges, avoidRemovingBone, ignoreStrength, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
			end
			return
		elseif CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playerType] and 
		       CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") <= 0 and
		       CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained") ~= CustomHealthAPI.Enums.HealthKinds.NONE
		then
			local hpToAdd = math.ceil(hp)
			if not CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity then
				hpToAdd = hpToAdd * 2
			end
			if playerType == PlayerType.PLAYER_BLUEBABY and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
				hpToAdd = hpToAdd * 2
			end
			CustomHealthAPI.Library.AddHealth(player, CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playerType], hpToAdd, ignoreTaintedMaggieDoubling, ignoreBethanyCharges, avoidRemovingBone, ignoreStrength, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
			return
		end
		
		local hpToAdd = math.ceil(hp)
		local leftoverHP = CustomHealthAPI.Helper.AddContainerMain(player, key, hpToAdd, avoidRemovingBone)
		
		local hpDiff = hpToAdd - leftoverHP
		if hpDiff < 0 and not ignoreStrength then
			CustomHealthAPI.Helper.SubtractTemporaryHP(player, key, hpDiff)
		end
	elseif healthType == CustomHealthAPI.Enums.HealthTypes.OVERLAY then
		local hpToAdd = math.ceil(hp)
		CustomHealthAPI.Helper.AddOverlayMain(player, key, hpToAdd)
	end
	
	CustomHealthAPI.Helper.HandleGoldenRoom(player, true)
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	CustomHealthAPI.PersistentData.PreventResyncing = true
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_ADD_HEALTH)
	for _, callback in ipairs(callbacks) do
		callback.Function(player, key, hp)
	end
	CustomHealthAPI.PersistentData.PreventResyncing = false
end

function CustomHealthAPI.Library.RemoveRedKey(player, index, ignoreResyncing)
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
			return CustomHealthAPI.Library.RemoveOtherKey(player:GetOtherTwin(), index)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return
	end
	
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
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			       CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
			then
				table.insert(healthOrder, {Red = nil, Other = {i, j}})
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				table.insert(healthOrder, {Red = nil, Other = {i, j}})
			end
		end
	end
	
	if healthOrder[index] ~= nil and healthOrder[index].Red ~= nil then
		local indices = healthOrder[index].Red
		table.remove(redMasks[indices[1]], indices[2])
	end
	
	while CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) < 0 do
		if not CustomHealthAPI.Helper.RemoveLowestPriorityRedKey(player, true) then
			break
		end
	end
	
	CustomHealthAPI.Helper.HandleGoldenRoom(player, false)
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	return healthOrder
end

function CustomHealthAPI.Library.RemoveOtherKey(player, index, ignoreResyncing)
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
			return CustomHealthAPI.Library.RemoveOtherKey(player:GetOtherTwin(), index)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
		
	local healthOrder = {}
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			
			table.insert(healthOrder, {i, j})
		end
	end
	
	if healthOrder[index] ~= nil then
		local indices = healthOrder[index]
		table.remove(otherMasks[indices[1]], indices[2])
	end
	
	while CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) < 0 do
		if not CustomHealthAPI.Helper.RemoveLowestPriorityRedKey(player, true) then
			break
		end
	end
	
	CustomHealthAPI.Helper.HandleGoldenRoom(player, false)
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	return healthOrder
end

function CustomHealthAPI.Library.TryConvertOtherKey(player, index, key, force)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Library.TryConvertOtherKey(player:GetOtherTwin(), index, key, force)
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
		
	local healthOrder = {}
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			
			table.insert(healthOrder, {i, j})
		end
	end
	
	if healthOrder[index] ~= nil then
		local indices = healthOrder[index]
		local health = otherMasks[indices[1]][indices[2]]
		
		local typOfKey = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
		local maxHpOfKey = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
		local maskIndexOfKey = CustomHealthAPI.Library.GetInfoOfKey(key, "MaskIndex")
		
		if typOfKey == CustomHealthAPI.Enums.HealthTypes.SOUL then
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL and
			   key ~= health.Key
			then
				local convertedHP = health.HP
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP") <= health.HP then
					convertedHP = 2
				end
				
				local newHP
				if maxHpOfKey <= 1 then
					newHP = 1
					convertedHP = convertedHP - 2
				else
---@diagnostic disable-next-line: param-type-mismatch
					newHP = math.min(maxHpOfKey, convertedHP)
					convertedHP = convertedHP - newHP
				end
				
				local maskIndexOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaskIndex")
				if maskIndexOfHealth < maskIndexOfKey then
					table.remove(otherMasks[indices[1]], indices[2])
					table.insert(otherMasks[maskIndexOfKey], 1, {Key = key, HP = newHP})
				elseif maskIndexOfHealth == maskIndexOfKey then
					health.Key = key
					health.HP = newHP
				else
					table.remove(otherMasks[indices[1]], indices[2])
					table.insert(otherMasks[maskIndexOfKey], {Key = key, HP = newHP})
				end
				
				if convertedHP > 0 then
					CustomHealthAPI.Library.AddHealth(player, key, convertedHP)
				end
			end
		end
	end
	
	while CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) < 0 do
		if not CustomHealthAPI.Helper.RemoveLowestPriorityRedKey(player, true) then
			break
		end
	end
	
	CustomHealthAPI.Helper.HandleGoldenRoom(player, false)
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	return healthOrder
end

function CustomHealthAPI.Helper.UpdateHealthMasks(player, k, h, ignoreTaintedMaggieDoubling, avoidRemovingBone, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.UpdateHealthMasks(player:GetOtherTwin(), k, h, ignoreTaintedMaggieDoubling, avoidRemovingBone, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
		end
	end
	
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then 
		return
	end
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.FinishDamageDesync(player)
	
	CustomHealthAPI.PersistentData.PreventResyncing = true
	local key = k
	local hp = h
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_ADD_HEALTH)
	for _, callback in ipairs(callbacks) do
		local returnA, returnB = callback.Function(player, key, hp)
		if returnA == true then
			CustomHealthAPI.PersistentData.PreventResyncing = false
			return
		elseif returnA ~= nil and returnB ~= nil then
			key = returnA
			hp = returnB
		end
	end
	CustomHealthAPI.PersistentData.PreventResyncing = false
	
	if math.ceil(hp) == 0 then
		return
	end
	
	local healthType = CustomHealthAPI.PersistentData.HealthDefinitions[key].Type
	local playerType = player:GetPlayerType()
	if healthType == CustomHealthAPI.Enums.HealthTypes.RED then
		if not ignoreHaveAHeart and Game().Challenge == Challenge.CHALLENGE_HAVE_A_HEART then
			return
		elseif playerType == PlayerType.PLAYER_BETHANY_B then
			return
		elseif playerType == PlayerType.PLAYER_THESOUL then
			local subplayer = player:GetSubPlayer()
			if subplayer ~= nil then
				CustomHealthAPI.Helper.UpdateHealthMasks(subplayer, key, hp, ignoreTaintedMaggieDoubling, avoidRemovingBone, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
			end
			return
		elseif CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[playerType] then
			return
		end
		
		local hpToAdd = math.ceil(hp)
		if playerType == PlayerType.PLAYER_MAGDALENE_B and not ignoreTaintedMaggieDoubling and hpToAdd > 0 then
			hpToAdd = hpToAdd * 2
		end
		
		CustomHealthAPI.Helper.AddRedMain(player, key, hpToAdd)
		
		if not ignoreShardOfGlass then
			player:GetData().CustomHealthAPISavedata.ShardBleedTimer = nil
		end
	elseif healthType == CustomHealthAPI.Enums.HealthTypes.SOUL then
		if playerType == PlayerType.PLAYER_BETHANY then
			return
		elseif playerType == PlayerType.PLAYER_THEFORGOTTEN then
			local subplayer = player:GetSubPlayer()
			if subplayer ~= nil then
				CustomHealthAPI.Helper.UpdateHealthMasks(subplayer, key, hp, ignoreTaintedMaggieDoubling, avoidRemovingBone, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
			end
			return
		end
			
		local hpToAdd = math.ceil(hp)
		
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		
		if not ignoreSpiritShackles then
			if player:GetData().CustomHealthAPIOtherData.ShacklesDisabled and hpToAdd > 0 then
				hpToAdd = math.max(0, hpToAdd - math.max(2, CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")))
				local numShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
				player:GetEffects():RemoveNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED, numShacklesDisabled)
				player:GetData().CustomHealthAPIOtherData.ShacklesDisabled = false
			end
		end
		
		if not ignoreAlabasterBox then
			local alabasterChargesAdded = player:GetData().CustomHealthAPIOtherData.AlabasterChargesAdded
			if alabasterChargesAdded ~= nil and alabasterChargesAdded > 0 and hpToAdd > 0 then
				player:GetData().CustomHealthAPIOtherData.AlabasterChargesAdded = math.max(0, alabasterChargesAdded - hpToAdd)
				hpToAdd = math.max(0, hpToAdd - alabasterChargesAdded)
			end
		end
		
		local leftoverHP = 0
		if hpToAdd ~= 0 then
			leftoverHP = CustomHealthAPI.Helper.AddSoulMain(player, key, hpToAdd)
		end
		
		local hpDiff = hpToAdd - leftoverHP
		if hpDiff < 0 then --and not ignoreStrength then
			CustomHealthAPI.Helper.SubtractTemporaryHP(player, key, hpDiff)
		end
	elseif healthType == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		if playerType == PlayerType.PLAYER_THEFORGOTTEN and 
		   CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") <= 0 and
		   CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained") ~= CustomHealthAPI.Enums.HealthKinds.NONE
		then
			local hpToAdd = math.ceil(hp)
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity then
				hpToAdd = math.ceil(hpToAdd / 2)
			end
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", hpToAdd, ignoreTaintedMaggieDoubling, avoidRemovingBone, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
			return
		elseif playerType == PlayerType.PLAYER_THESOUL and 
		   CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained") ~= CustomHealthAPI.Enums.HealthKinds.NONE
		then
			if CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") > 0 then
				local subplayer = player:GetSubPlayer()
				if subplayer ~= nil then
					CustomHealthAPI.Helper.UpdateHealthMasks(subplayer, key, hp, ignoreTaintedMaggieDoubling, avoidRemovingBone, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
				end
			else
				local hpToAdd = math.ceil(hp)
				if not CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity then
					hpToAdd = hpToAdd * 2
				end
				CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", hpToAdd, ignoreTaintedMaggieDoubling, avoidRemovingBone, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
			end
			return
		elseif CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playerType] and 
		       CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") <= 0 and
		       CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained") ~= CustomHealthAPI.Enums.HealthKinds.NONE
		then
			local hpToAdd = math.ceil(hp)
			if not CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity then
				hpToAdd = hpToAdd * 2
			end
			if playerType == PlayerType.PLAYER_BLUEBABY and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
				hpToAdd = hpToAdd * 2
			end
			CustomHealthAPI.Helper.UpdateHealthMasks(player, CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playerType], hpToAdd, ignoreTaintedMaggieDoubling, avoidRemovingBone, ignoreAlabasterBox, ignoreHaveAHeart, ignoreShardOfGlass, ignoreSpiritShackles)
			return
		end
		
		local hpToAdd = math.ceil(hp)
		local leftoverHP = CustomHealthAPI.Helper.AddContainerMain(player, key, hpToAdd, avoidRemovingBone)
		
		local hpDiff = hpToAdd - leftoverHP
		if hpDiff < 0 then --and not ignoreStrength then
			CustomHealthAPI.Helper.SubtractTemporaryHP(player, key, hpDiff)
		end
	elseif healthType == CustomHealthAPI.Enums.HealthTypes.OVERLAY then
		local hpToAdd = math.ceil(hp)
		CustomHealthAPI.Helper.AddOverlayMain(player, key, hpToAdd)
	end
	
	CustomHealthAPI.Helper.HandleGoldenRoom(player, false)
	if player:GetData().CustomHealthAPISavedata then
		player:GetData().CustomHealthAPISavedata.Cached = {}
	end
	
	CustomHealthAPI.PersistentData.PreventResyncing = true
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_ADD_HEALTH)
	for _, callback in ipairs(callbacks) do
		callback.Function(player, key, hp)
	end
	CustomHealthAPI.PersistentData.PreventResyncing = false
end

function CustomHealthAPI.Helper.UseOverriddenAddFunctionForKeeperAndLost(player, key, hp)
	local healthtype = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")

	if key == "RED_HEART" then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts(player, hp)
	elseif key == "ROTTEN_HEART" then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts(player, hp)
	elseif key == "EMPTY_HEART" then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts(player, hp)
	elseif key == "SOUL_HEART" then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts(player, hp)
	elseif key == "BLACK_HEART" then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts(player, hp)
	elseif key == "BONE_HEART" then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts(player, hp)
	elseif key == "ETERNAL_HEART" then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts(player, hp)
	elseif key == "GOLDEN_HEART" then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts(player, hp)
	elseif key == "BROKEN_HEART" then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts(player, hp)
	elseif healthtype == CustomHealthAPI.Enums.HealthTypes.RED then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts(player, hp)
	elseif healthtype == CustomHealthAPI.Enums.HealthTypes.SOUL then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts(player, hp)
	elseif healthtype == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		if CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP") >= 1 then
			CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts(player, hp)
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity then
			CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts(player, hp)
		else
			CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts(player, hp * 2)
		end
	end
end
