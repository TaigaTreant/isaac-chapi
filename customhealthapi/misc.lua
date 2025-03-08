function CustomHealthAPI.Helper.PlayerIsHealthless(player, ignoreTaintedSoul)
	if REPENTOGON then
		local playerType = player:GetPlayerType()
		local healthtype = player:GetHealthType()
		return healthtype == HealthType.LOST and not (ignoreTaintedSoul and playerType == PlayerType.PLAYER_THESOUL_B)
	else
		local playerType = player:GetPlayerType()
		return playerType == PlayerType.PLAYER_THELOST or 
		       playerType == PlayerType.PLAYER_THELOST_B or 
		       (playerType == PlayerType.PLAYER_THESOUL_B and not ignoreTaintedSoul)
	end
end

function CustomHealthAPI.Helper.PlayerHasCoinHealth(player)
	if REPENTOGON then
		local healthtype = player:GetHealthType()
		return healthtype == HealthType.COIN
	else
		local playerType = player:GetPlayerType()
		return playerType == PlayerType.PLAYER_KEEPER or playerType == PlayerType.PLAYER_KEEPER_B
	end
end

function CustomHealthAPI.Helper.PlayerIsKeeper(player)
	-- Deprecated
	return CustomHealthAPI.Helper.PlayerHasCoinHealth(player)
end

function CustomHealthAPI.Helper.PlayerIsTheForgotten(player)
	local playertype = player:GetPlayerType()
	return playertype == PlayerType.PLAYER_THEFORGOTTEN
end

function CustomHealthAPI.Helper.PlayerIsTheSoul(player)
	local playertype = player:GetPlayerType()
	return playertype == PlayerType.PLAYER_THESOUL
end

function CustomHealthAPI.Helper.PlayerIsTaintedMaggie(player)
	local playertype = player:GetPlayerType()
	return playertype == PlayerType.PLAYER_MAGDALENE_B
end

function CustomHealthAPI.Helper.PlayerIsBethany(player)
	local playertype = player:GetPlayerType()
	return playertype == PlayerType.PLAYER_BETHANY
end

function CustomHealthAPI.Helper.PlayerIsTaintedBethany(player)
	local playertype = player:GetPlayerType()
	return playertype == PlayerType.PLAYER_BETHANY_B
end

function CustomHealthAPI.Helper.IsFoundSoul(player)
	return player.Variant == 1 and player.SubType == BabySubType.BABY_FOUND_SOUL
end

function CustomHealthAPI.Helper.PlayerIsIgnored(player)
	if REPENTOGON then
		local healthtype = player:GetHealthType()
		return healthtype == HealthType.LOST or 
		       healthtype == HealthType.COIN or 
		       CustomHealthAPI.Helper.IsFoundSoul(player) or
		       player:IsCoopGhost()
	else
		local playertype = player:GetPlayerType()
		return playertype == PlayerType.PLAYER_THELOST or
		       playertype == PlayerType.PLAYER_THELOST_B or
		       playertype == PlayerType.PLAYER_KEEPER or
		       playertype == PlayerType.PLAYER_KEEPER_B or
		       playertype == PlayerType.PLAYER_THESOUL_B or
		       CustomHealthAPI.Helper.IsFoundSoul(player) or
		       player:IsCoopGhost()
	end
end

function CustomHealthAPI.Helper.PlayerIsSoulHeartOnly(player, ignoreTheSoul)
	local playertype = player:GetPlayerType()
	
	if REPENTOGON and not (ignoreTheSoul and playertype == PlayerType.PLAYER_THESOUL) then
		local healthtype = player:GetHealthType()
		if healthtype == HealthType.SOUL then
			return true
		elseif playertype < 41 then -- Basegame characters that must have had their healthtype changed
			return false
		end
	end

	return CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playertype] ~= nil
end

function CustomHealthAPI.Helper.PlayerIsRedHealthless(player, ignoreTheSoul)
	local playertype = player:GetPlayerType()
	
	if REPENTOGON and not (ignoreTheSoul and playertype == PlayerType.PLAYER_THESOUL) then
		local healthtype = player:GetHealthType()
		if healthtype == HealthType.SOUL then
			return true
		elseif playertype < 41 then -- Basegame characters that must have had their healthtype changed
			return false
		end
	end

	return CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[playertype]
end

function CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player, ignoreTheSoul)
	local playertype = player:GetPlayerType()
	
	if REPENTOGON and not (ignoreTheSoul and playertype == PlayerType.PLAYER_THESOUL) then
		local healthtype = player:GetHealthType()
		if healthtype == HealthType.BONE then
			return true
		elseif playertype < 41 then -- Basegame characters that must have had their healthtype changed
			return false
		end
	end

	return CustomHealthAPI.Helper.PlayerIsTheForgotten(player)
end

function CustomHealthAPI.Helper.GetConvertedMaxHealthType(player)
	if CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player) then
		return "BONE_HEART"
	end
	return CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playertype] or "SOUL_HEART"
end

function CustomHealthAPI.Helper.GetPlayerIndex(player)
    local rng
    if player:GetPlayerType() == PlayerType.PLAYER_LAZARUS2_B then
        rng = player:GetCollectibleRNG(2) -- flip sucks
	else
        rng = player:GetCollectibleRNG(1)
    end
    
    return tostring(rng:GetSeed())
end

function CustomHealthAPI.Helper.AddHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, amount)
	if not (CustomHealthAPI.Helper.PlayerIsTheSoul(player) or CustomHealthAPI.Helper.PlayerIsTaintedBethany(player)) then
		if amount > 0 then
			if CustomHealthAPI.Helper.PlayerIsTaintedMaggie(player) then
				local desiredRed = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) + amount
				CustomHealthAPI.Helper.AddHeartsKissesFix(player, math.ceil(amount / 2))
				local actualRed = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
				CustomHealthAPI.Helper.AddHeartsKissesFix(player, desiredRed - actualRed)
			else
				CustomHealthAPI.Helper.AddHeartsKissesFix(player, amount)
			end
		else
			CustomHealthAPI.Helper.AddHeartsKissesFix(player, amount)
		end
	end
end

function CustomHealthAPI.Helper.AddRottenHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, amount)
	if not (CustomHealthAPI.Helper.PlayerIsTheSoul(player) or CustomHealthAPI.Helper.PlayerIsTaintedBethany(player)) then
		if amount > 0 then
			if CustomHealthAPI.Helper.PlayerIsTaintedMaggie(player) then
				CustomHealthAPI.Helper.AddRottenHeartsKissesFix(player, math.ceil(amount / 2))
			else
				CustomHealthAPI.Helper.AddRottenHeartsKissesFix(player, amount)
			end
		else
			CustomHealthAPI.Helper.AddRottenHeartsKissesFix(player, amount)
		end
	end
end

function CustomHealthAPI.Helper.AddMaxHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, amount)
	CustomHealthAPI.Helper.AddMaxHeartsKissesFix(player, amount)
end

function CustomHealthAPI.Helper.AddSoulHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, amount)
	if not (CustomHealthAPI.Helper.PlayerIsTheForgotten(player) or CustomHealthAPI.Helper.PlayerIsBethany(player)) then
		CustomHealthAPI.Helper.AddSoulHeartsKissesFix(player, amount)
	end
end

function CustomHealthAPI.Helper.AddBlackHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, amount)
	if not (CustomHealthAPI.Helper.PlayerIsTheForgotten(player) or CustomHealthAPI.Helper.PlayerIsBethany(player)) then
		CustomHealthAPI.Helper.AddBlackHeartsKissesFix(player, amount)
	end
end

function CustomHealthAPI.Helper.AddBoneHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, amount)
	if not CustomHealthAPI.Helper.PlayerIsTheSoul(player) then
		CustomHealthAPI.Helper.AddBoneHeartsKissesFix(player, amount)
	end
end

function CustomHealthAPI.Helper.AddBrokenHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameBrokenHealthWithoutModifiers(player, amount)
	CustomHealthAPI.Helper.AddBrokenHeartsKissesFix(player, amount)
end

function CustomHealthAPI.Helper.AddEternalHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, amount)
	CustomHealthAPI.Helper.AddEternalHeartsKissesFix(player, amount)
end

function CustomHealthAPI.Helper.AddGoldenHeartsKissesFix(player, amount)
	local queuedTrinket = nil
	local queuedTouched = false
	if player.QueuedItem.Item and 
	   player.QueuedItem.Item:IsTrinket() and 
	   player.QueuedItem.Item.ID & TrinketType.TRINKET_ID_MASK == TrinketType.TRINKET_MOTHERS_KISS
	then
		local queuedItem = player.QueuedItem
		
		queuedTrinket = player.QueuedItem.Item
		queuedTouched = queuedItem.Touched
		
		queuedItem.Item = nil
		queuedItem.Touched = false
		
		player.QueuedItem = queuedItem
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts(player, amount)
	
	if queuedTrinket ~= nil then
		local queuedItem = player.QueuedItem
		queuedItem.Item = queuedTrinket
		queuedItem.Touched = queuedTouched
		player.QueuedItem = queuedItem
	end
end

function CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, amount)
	CustomHealthAPI.Helper.AddGoldenHeartsKissesFix(player, amount)
end

function CustomHealthAPI.Helper.GetGreedAndMotherContainers(player)
	local containers = 0

	if player:HasCollectible(CollectibleType.COLLECTIBLE_GREEDS_GULLET) then
		local coins = player:GetNumCoins()
		
		if coins > 99 then
			containers = containers + math.floor(coins / 100) + 3
		elseif coins == 99 then
			containers = containers + 4
		else
			containers = containers + math.max(0, math.floor(coins / 25))
		end
	end
	
	local numKisses = player:GetTrinketMultiplier(TrinketType.TRINKET_MOTHERS_KISS)
	containers = containers + numKisses
	
	return containers
end

function CustomHealthAPI.Helper.ClearBasegameHealth(player)
	local isTheForgotten = CustomHealthAPI.Helper.PlayerIsTheForgotten(player)
	local isTheSoul = CustomHealthAPI.Helper.PlayerIsTheSoul(player)
	local isBethany = CustomHealthAPI.Helper.PlayerIsBethany(player)
	local isTaintedBethany = CustomHealthAPI.Helper.PlayerIsTaintedBethany(player)
	local isSoulHeartOnly = CustomHealthAPI.Helper.PlayerIsSoulHeartOnly(player, true)

	local goldenTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	CustomHealthAPI.Helper.AddGoldenHeartsKissesFix(player, -1 * goldenTotal)
	
	local eternalTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	CustomHealthAPI.Helper.AddEternalHeartsKissesFix(player, -1 * eternalTotal)
	
	if not isTheSoul then
		if not isTaintedBethany then
			local redTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
			CustomHealthAPI.Helper.AddHeartsKissesFix(player, -1 * redTotal)
		end
		
		local maxTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		if not (isTheForgotten or isTheSoul or isSoulHeartOnly) then
			local greedAndMotherContainers = CustomHealthAPI.Helper.GetGreedAndMotherContainers(player)
			CustomHealthAPI.Helper.AddMaxHeartsKissesFix(player, -1 * math.max(0, maxTotal - (greedAndMotherContainers * 2)))
		else
			CustomHealthAPI.Helper.AddMaxHeartsKissesFix(player, -1 * maxTotal)
		end
	end
	
	local brokenTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	CustomHealthAPI.Helper.AddBrokenHeartsKissesFix(player, -1 * brokenTotal)
	
	if not isTheSoul then
		local boneTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		if isTheForgotten then
			local greedAndMotherContainers = CustomHealthAPI.Helper.GetGreedAndMotherContainers(player)
			CustomHealthAPI.Helper.AddBoneHeartsKissesFix(player, -1 * math.max(0, boneTotal - greedAndMotherContainers))
		else
			CustomHealthAPI.Helper.AddBoneHeartsKissesFix(player, -1 * boneTotal)
		end
	end
	
	if not (isTheForgotten or isBethany) then
		local soulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		CustomHealthAPI.Helper.AddSoulHeartsKissesFix(player, -1 * soulTotal)
	end
end

function CustomHealthAPI.Helper.ClearBasegameHealthNoOther(player)
	local isTheSoul = CustomHealthAPI.Helper.PlayerIsTheSoul(player)

	local goldenTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	CustomHealthAPI.Helper.AddGoldenHeartsKissesFix(player, -1 * goldenTotal)
	
	local eternalTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	CustomHealthAPI.Helper.AddEternalHeartsKissesFix(player, -1 * eternalTotal)
	
	if not isTheSoul then
		local redTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
		CustomHealthAPI.Helper.AddHeartsKissesFix(player, -1 * redTotal)
	end
end

function CustomHealthAPI.Helper.ClearBasegameSoulHealth(player)
	local isTheForgotten = CustomHealthAPI.Helper.PlayerIsTheForgotten(player)
	local isBethany = CustomHealthAPI.Helper.PlayerIsBethany(player)

	local goldenTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	CustomHealthAPI.Helper.AddGoldenHeartsKissesFix(player, -1 * goldenTotal)
	
	if not (isTheForgotten or isBethany) then
		local soulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		if soulTotal ~= 0 then
			CustomHealthAPI.Helper.AddSoulHeartsKissesFix(player, -1 * soulTotal)
		end
	end
end

function CustomHealthAPI.Helper.HandleBasegameHealthStateUpdate(player, updateFunc)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	-- before update
	local addedWhoreOfBabylonPrevention = CustomHealthAPI.Helper.AddWhoreOfBabylonPrevention(player)
	local addedBloodyBabylonPrevention = CustomHealthAPI.Helper.AddBloodyBabylonPrevention(player)
	
	local alabasterSlots = {[0] = false, [1] = false, [2] = false}
	local alabasterCharges = {[0] = 0, [1] = 0, [2] = 0}
	for i = 2, 0, -1 do
		if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			alabasterSlots[i] = true
			alabasterCharges[i] = player:GetActiveCharge(i)
		end
	end
	
	local shacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
	player:GetEffects():RemoveNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED, shacklesDisabled)
	
	local challengeIsHaveAHeart = Game().Challenge == Challenge.CHALLENGE_HAVE_A_HEART
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_NULL
	end
	
	for i = 2, 0, -1 do
		if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			player:SetActiveCharge(0, i)
		end
	end
	
	--CustomHealthAPI.Helper.ClearBasegameHealth(player)
	CustomHealthAPI.Helper.ClearBasegameSoulHealth(player) -- Temporary handling of soul HP until something can be figured out in regards to soul/black health order
	                                                       -- that is compatible with the ADD_HEARTS functions; will probably be permanent for the non-REPENTOGON
	                                                       -- version of the code as well
	
	for i = 2, 0, -1 do
		if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
			player:SetActiveCharge(24, i)
		end
	end
	
	-- update
	updateFunc(player)
	
	-- after update
	player:GetEffects():AddNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED, true, shacklesDisabled)
		
	for i = 2, 0, -1 do
		if alabasterSlots[i] then
			player:SetActiveCharge(alabasterCharges[i], i)
		end
	end
	
	if addedWhoreOfBabylonPrevention then CustomHealthAPI.Helper.RemoveWhoreOfBabylonPrevention(player) end
	if addedBloodyBabylonPrevention then CustomHealthAPI.Helper.RemoveBloodyBabylonPrevention(player) end
	
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_HAVE_A_HEART
	end
end

function CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.UpdateBasegameHealthState(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return
	end
	
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	data.Cached = {}
	
	local maxHealth = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
	local brokenHealth = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
	
	local redHealthTotal = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true)
	local rottenHealth = CustomHealthAPI.Helper.GetTotalHPOfKey(player, "ROTTEN_HEART", true)
	local redHealth = redHealthTotal - (rottenHealth * 2)
	
	local updateFunc = function(player)
		local brokenDiff = brokenHealth - CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		if brokenDiff ~= 0 then
			CustomHealthAPI.Helper.AddBasegameBrokenHealthWithoutModifiers(player, brokenDiff)
		end
		
		local maxDiff = maxHealth - CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		if REPENTOGON and not REPENTANCE_PLUS and maxDiff < 0 and (CustomHealthAPI.Helper.PlayerIsSoulHeartOnly(player) or CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player)) then
			-- Incredibly niche fix for an oversight in early repentogon that can result in unremovable heart containers. Irrelevant as of repentogon+.
			local hash = GetPtrHash(player)
			local frame = Isaac.GetFrameCount()
			local callbackfn
			callbackfn = function(_, p)
				if Isaac.GetFrameCount() ~= frame then
					CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_GET_HEALTH_TYPE, callbackfn)
				elseif GetPtrHash(p) == hash then
					return HealthType.RED
				end
			end
			CustomHealthAPI.Mod:AddPriorityCallback(ModCallbacks.MC_PLAYER_GET_HEALTH_TYPE, CustomHealthAPI.Enums.CallbackPriorities.FIRST, callbackfn, -1)
			CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts(player, maxDiff)
			CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_GET_HEALTH_TYPE, callbackfn)
			maxDiff = 0
		end
		if maxDiff ~= 0 then
			CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, maxDiff)
		end
		
		--local soulToAdd = 0
		--local soulIndex = 0
		--local blackIndices = {}
		local bonesToAdd = 0
		for i = 1, #otherMasks do
			local mask = otherMasks[i]
			for j = 1, #mask do
				local health = mask[j]
				local key = health.Key
				local atMax = health.HP >= CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP
				
				if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
				   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and 
				   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0
				then
					bonesToAdd = bonesToAdd + 1
				elseif key == "BLACK_HEART" then
					CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, (atMax and 2) or 1)
					--table.insert(blackIndices, soulIndex)
					
					--soulToAdd = soulToAdd + ((atMax and 2) or 1)
					--soulIndex = soulIndex + 1
				elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL and
					   key ~= "BLACK_HEART"
				then
					CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, (atMax and 2) or 1)
					--soulToAdd = soulToAdd + ((atMax and 2) or 1)
					--soulIndex = soulIndex + 1
				end
			end
		end
		
		local boneDiff = bonesToAdd - CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		if boneDiff ~= 0 then
			CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, boneDiff)
		end
		
		local rottenDiff = rottenHealth - CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
		if rottenDiff ~= 0 then
			CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, rottenDiff * 2)
		end
		
		local redDiff = redHealth - (CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) - (CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player) * 2))
		if redDiff ~= 0 then
			CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, redDiff)
		end
		
		local goldenDiff = data.Overlays["GOLDEN_HEART"] - CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
		if goldenDiff ~= 0 then
			CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, goldenDiff)
		end
		
		local eternalDiff = data.Overlays["ETERNAL_HEART"] - CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
		if eternalDiff ~= 0 then
			CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, eternalDiff)
		end
	end
	
	CustomHealthAPI.Helper.HandleBasegameHealthStateUpdate(player, updateFunc)
	
	data.Cached = {}
	
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_UPDATE_HEALTH_STATE)
	for _, callback in ipairs(callbacks) do
		callback.Function(player, key, hp)
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
end

function CustomHealthAPI.Helper.UpdateBasegameHealthStateNoOther(player)
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	
	local data = player:GetData().CustomHealthAPISavedata
	data.Cached = {}
	
	local addedWhoreOfBabylonPrevention = CustomHealthAPI.Helper.AddWhoreOfBabylonPrevention(player)
	local addedBloodyBabylonPrevention = CustomHealthAPI.Helper.AddBloodyBabylonPrevention(player)
	
	local challengeIsHaveAHeart = Game().Challenge == Challenge.CHALLENGE_HAVE_A_HEART
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_NULL
	end
	
	--CustomHealthAPI.Helper.ClearBasegameHealthNoOther(player)
	
	local newTotal = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true)
	local newRotten = CustomHealthAPI.Helper.GetTotalHPOfKey(player, "ROTTEN_HEART", true)
	local newRed = newTotal - (newRotten * 2)
	
	local rottenDiff = newRotten - CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
	if rottenDiff ~= 0 then
		CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, rottenDiff * 2)
	end
	
	local redDiff = newRed - (CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) - (CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player) * 2))
	if redDiff ~= 0 then
		CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, redDiff)
	end
	
	local goldenDiff = data.Overlays["GOLDEN_HEART"] - CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	if goldenDiff ~= 0 then
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, goldenDiff)
	end
	
	local eternalDiff = data.Overlays["ETERNAL_HEART"] - CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	if eternalDiff ~= 0 then
		CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, eternalDiff)
	end
	
	if addedWhoreOfBabylonPrevention then CustomHealthAPI.Helper.RemoveWhoreOfBabylonPrevention(player) end
	if addedBloodyBabylonPrevention then CustomHealthAPI.Helper.RemoveBloodyBabylonPrevention(player) end
	
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_HAVE_A_HEART
	end
	
	data.Cached = {}
	
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_UPDATE_HEALTH_STATE)
	for _, callback in ipairs(callbacks) do
		callback.Function(player, key, hp)
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
end

function CustomHealthAPI.Helper.CanAffordPickup(player, pickup)
	local playerType = player:GetPlayerType()
	if pickup.Price > 0 then
		return player:GetNumCoins() >= pickup.Price
	elseif CustomHealthAPI.Helper.PlayerIsHealthless(player, true) then
		return true
	elseif pickup.Price == -1 then
		--1 Red
		return math.ceil(player:GetMaxHearts() / 2) + player:GetBoneHearts() >= 1
	elseif pickup.Price == -2 then
		--2 Red
		return math.ceil(player:GetMaxHearts() / 2) + player:GetBoneHearts() >= 1
	elseif pickup.Price == -3 then
		--3 soul
		return math.ceil(player:GetSoulHearts() / 2) >= 1
	elseif pickup.Price == -4 then
		--1 Red, 2 Soul
		return math.ceil(player:GetMaxHearts() / 2) + player:GetBoneHearts() >= 1
	elseif pickup.Price == -7 then
		--1 Soul
		return math.ceil(player:GetSoulHearts() / 2) >= 1
	elseif pickup.Price == -8 then
		--2 Souls
		return math.ceil(player:GetSoulHearts() / 2) >= 1
	elseif pickup.Price == -9 then
		--1 Red, 1 Soul
		return math.ceil(player:GetMaxHearts() / 2) + player:GetBoneHearts() >= 1
	else
		return true
	end
end

function CustomHealthAPI.Helper.EmptyAllHealth(player)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			table.remove(mask, j)
		end
	end
	
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			local key = health.Key
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				table.remove(mask, j)
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			       CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
			       CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0 
			then
				table.remove(mask, j)
			end
		end
	end
end

function CustomHealthAPI.Helper.GetRepentogonAddHealthType(key)
	if not REPENTOGON then return end
	local healthDef = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	local chapiHealthType = healthDef.Type
	if chapiHealthType == CustomHealthAPI.Enums.HealthTypes.RED then
		if key == "ROTTEN_HEART" then
			return AddHealthType.ROTTEN
		end
		return AddHealthType.RED
	elseif chapiHealthType == CustomHealthAPI.Enums.HealthTypes.SOUL then
		if key == "BLACK_HEART" then
			return AddHealthType.BLACK
		end
		return AddHealthType.SOUL
	elseif chapiHealthType == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		if healthDef.MaxHP > 0 then
			return AddHealthType.BONE
		elseif healthDef.KindContained == CustomHealthAPI.Enums.HealthKinds.NONE then
			return AddHealthType.BROKEN
		end
		return AddHealthType.MAX
	elseif key == "GOLDEN_HEART" then
		return AddHealthType.GOLDEN
	elseif key == "ETERNAL_HEART" then
		return AddHealthType.ETERNAL
	end
end
