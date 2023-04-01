CustomHealthAPI.PersistentData.DoHUDPostUpdateForLivesHUD = nil

local avoidRecursive = false

function CustomHealthAPI.Helper.AddResetRecursivePreventionCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.ResetRecursivePreventionCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddResetRecursivePreventionCallback)

function CustomHealthAPI.Helper.RemoveResetRecursivePreventionCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.ResetRecursivePreventionCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveResetRecursivePreventionCallback)

function CustomHealthAPI.Mod:ResetRecursivePreventionCallback()
	if avoidRecursive then
		print("Custom Health API ERROR: Resyncing recursive prevention failed.")
		avoidRecursive = false
	end
end

function CustomHealthAPI.Helper.AddCheckIfHealthValuesChangedCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.CheckIfHealthValuesChangedCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddCheckIfHealthValuesChangedCallback)

function CustomHealthAPI.Helper.RemoveCheckIfHealthValuesChangedCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.CheckIfHealthValuesChangedCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveCheckIfHealthValuesChangedCallback)

function CustomHealthAPI.Mod:CheckIfHealthValuesChangedCallback()
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitialized()
	CustomHealthAPI.Helper.CheckSubPlayerInfo()
	CustomHealthAPI.Helper.ResyncHealth()
	CustomHealthAPI.Helper.CheckIfHealthValuesChanged()
	
	if CustomHealthAPI.PersistentData.DoHUDPostUpdateForLivesHUD == Isaac.GetFrameCount() then
		Game():GetHUD():PostUpdate()
	end
	CustomHealthAPI.PersistentData.DoHUDPostUpdateForLivesHUD = nil
end

function CustomHealthAPI.Helper.CheckIfHealthOfKeeperChanged(player)
	player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
	local data = player:GetData().CustomHealthAPIOtherData

	data.LastValues = data.LastValues or {}
	data.RedFlash = math.max(0, (data.RedFlash or 0) - 1)
	data.GoldFlash = math.max(0, (data.GoldFlash or 0) - 1)
	
	local redHp = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	if data.LastValues["COIN_HEART"] ~= nil and data.LastValues["COIN_HEART"] < redHp then
		data.RedFlash = 4
	end
	data.LastValues["COIN_HEART"] = redHp
	
	local goldHp = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	if data.LastValues["GOLDEN_HEART"] ~= nil and data.LastValues["GOLDEN_HEART"] < goldHp then
		data.GoldFlash = 3
	end
	data.LastValues["GOLDEN_HEART"] = goldHp
end

function CustomHealthAPI.Helper.CheckIfHealthOfPlayerChanged(player)
	if player:GetPlayerType() == PlayerType.PLAYER_KEEPER or player:GetPlayerType() == PlayerType.PLAYER_KEEPER_B then
		CustomHealthAPI.Helper.CheckIfHealthOfKeeperChanged(player)
		return
	end

	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then return end

	player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
	local data = player:GetData().CustomHealthAPIOtherData

	data.LastValues = data.LastValues or {}
	data.RedFlash = math.max(0, (data.RedFlash or 0) - 1)
	data.SoulFlash = math.max(0, (data.SoulFlash or 0) - 1)
	data.GoldFlash = math.max(0, (data.GoldFlash or 0) - 1)

	for key, def in pairs(CustomHealthAPI.PersistentData.HealthDefinitions) do
		if def.Type == CustomHealthAPI.Enums.HealthTypes.RED then
			local hp = CustomHealthAPI.Helper.GetTotalHPOfKey(player, key)
			if data.LastValues[key] ~= nil and data.LastValues[key] < hp then
				data.RedFlash = 4
				player:GetData().CustomHealthAPISavedata.ShardBleedTimer = nil
				player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
				player:GetData().CustomHealthAPIOtherData.BleedSpriteFrame = nil
			end
			data.LastValues[key] = hp
		elseif def.Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
			local hp = CustomHealthAPI.Helper.GetTotalHPOfKey(player, key)
			if data.LastValues[key] ~= nil and data.LastValues[key] < hp then
				data.SoulFlash = 4
			end
			data.LastValues[key] = hp
		elseif key == "GOLDEN_HEART" then
			local hp = player:GetData().CustomHealthAPISavedata.Overlays["GOLDEN_HEART"]
			if data.LastValues[key] ~= nil and data.LastValues[key] < hp then
				data.GoldFlash = 3
			end
			data.LastValues[key] = hp
		end
	end
end

function CustomHealthAPI.Helper.CheckIfHealthValuesChanged()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		CustomHealthAPI.Helper.CheckIfHealthOfPlayerChanged(player)
		if player:GetSubPlayer() ~= nil then
			CustomHealthAPI.Helper.CheckIfHealthOfPlayerChanged(player:GetSubPlayer())
		end
	end
end

function CustomHealthAPI.Helper.ResyncRedHealthOfPlayer(player)
	local expectedTotal = CustomHealthAPI.Helper.GetTotalRedHP(player, true)
	local expectedRotten = CustomHealthAPI.Helper.GetTotalHPOfKey(player, "ROTTEN_HEART")
	
	local actualTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	local actualRotten = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
	
	local diffRotten = actualRotten - expectedRotten
	local diffTotal = actualTotal - expectedTotal
	local diffRed = diffTotal - (diffRotten * 2)
	
	if diffTotal == 0 and diffRotten == 0 then
		return
	end
	
	local ignoreRed = diffRotten > 0 and diffRotten >= diffTotal
	if diffRotten ~= 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "ROTTEN_HEART", diffRotten * 2, true, false, true, true)
		
		expectedTotal = CustomHealthAPI.Helper.GetTotalRedHP(player, true)
		expectedRotten = CustomHealthAPI.Helper.GetTotalHPOfKey(player, "ROTTEN_HEART")
	
		actualTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
		actualRotten = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
	
		diffRotten = actualRotten - expectedRotten
		diffTotal = actualTotal - expectedTotal
		diffRed = diffTotal - (diffRotten * 2)
	end
	if not ignoreRed and diffRed ~= 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", diffRed, true, false, true, true)
	end
	
	CustomHealthAPI.Helper.UpdateBasegameHealthStateNoOther(player)
end

function CustomHealthAPI.Helper.ResyncOtherHealthOfPlayer(player)
	local expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
	local expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
	local expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
	local expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
	local expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
	
	local actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
	local actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
	local actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
	local actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
	local actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
	local diffSoulTotal = actualSoulTotal - expectedSoulTotal
	local diffBlack = actualBlack - expectedBlack
	local diffMax = actualMax - expectedMax
	local diffBone = actualBone - expectedBone
	local diffBroken = actualBroken - expectedBroken
	
	if diffMax == 0 and diffBroken == 0 and diffSoulTotal == 0 and diffBlack == 0 and diffBone == 0 then
		return
	end

	-- **************************************************
	-- * Update masks
	-- **************************************************
	
	if diffBroken < 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BROKEN_HEART", diffBroken, true, false, true, true)
		
		expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
		expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
		expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
		expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
		expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
	
		actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
		actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
		diffSoulTotal = actualSoulTotal - expectedSoulTotal
		diffBlack = actualBlack - expectedBlack
		diffMax = actualMax - expectedMax
		diffBone = actualBone - expectedBone
		diffBroken = actualBroken - expectedBroken
	end
	
	if diffMax < 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", diffMax, true, false, true, true)
		
		expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
		expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
		expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
		expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
		expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
	
		actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
		actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
		diffSoulTotal = actualSoulTotal - expectedSoulTotal
		diffBlack = actualBlack - expectedBlack
		diffMax = actualMax - expectedMax
		diffBone = actualBone - expectedBone
		diffBroken = actualBroken - expectedBroken
	end
	
	if diffSoulTotal ~= 0 or diffBlack ~= 0 or diffBone ~= 0 then
		local ignoreSoul = diffBlack > 0 and diffBlack * 2 >= diffSoulTotal
		if not ignoreSoul and diffSoulTotal > 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", diffSoulTotal, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		
			diffSoulTotal = actualSoulTotal - expectedSoulTotal
			diffBlack = actualBlack - expectedBlack
			diffMax = actualMax - expectedMax
			diffBone = actualBone - expectedBone
			diffBroken = actualBroken - expectedBroken
		end
		
		if diffBlack > 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BLACK_HEART", diffBlack * 2, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		
			diffSoulTotal = actualSoulTotal - expectedSoulTotal
			diffBlack = actualBlack - expectedBlack
			diffMax = actualMax - expectedMax
			diffBone = actualBone - expectedBone
			diffBroken = actualBroken - expectedBroken
		end
		
		if diffBone > 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", diffBone, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		
			diffSoulTotal = actualSoulTotal - expectedSoulTotal
			diffBlack = actualBlack - expectedBlack
			diffMax = actualMax - expectedMax
			diffBone = actualBone - expectedBone
			diffBroken = actualBroken - expectedBroken
		end
		
		if diffBone < 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", diffBone, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		
			diffSoulTotal = actualSoulTotal - expectedSoulTotal
			diffBlack = actualBlack - expectedBlack
			diffMax = actualMax - expectedMax
			diffBone = actualBone - expectedBone
			diffBroken = actualBroken - expectedBroken
		end
		
		--[[if diffBlack < 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BLACK_HEART", diffBlack, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		
			diffSoulTotal = actualSoulTotal - expectedSoulTotal
			diffBlack = actualBlack - expectedBlack
			diffMax = actualMax - expectedMax
			diffBone = actualBone - expectedBone
			diffBroken = actualBroken - expectedBroken
		end]]--
		
		if not ignoreSoul and diffSoulTotal < 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", diffSoulTotal, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		
			diffSoulTotal = actualSoulTotal - expectedSoulTotal
			diffBlack = actualBlack - expectedBlack
			diffMax = actualMax - expectedMax
			diffBone = actualBone - expectedBone
			diffBroken = actualBroken - expectedBroken
		end
	end
	
	if diffMax > 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", diffMax, true, false, true, true)
		
		expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
		expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
		expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
		expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
		expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
	
		actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
		actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
		diffSoulTotal = actualSoulTotal - expectedSoulTotal
		diffBlack = actualBlack - expectedBlack
		diffMax = actualMax - expectedMax
		diffBone = actualBone - expectedBone
		diffBroken = actualBroken - expectedBroken
	end
	
	if diffBroken > 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BROKEN_HEART", diffBroken, true, false, true, true)
		
		expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
		expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART")
		expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
		expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
		expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
	
		actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
		actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
		diffSoulTotal = actualSoulTotal - expectedSoulTotal
		diffBlack = actualBlack - expectedBlack
		diffMax = actualMax - expectedMax
		diffBone = actualBone - expectedBone
		diffBroken = actualBroken - expectedBroken
	end
	
	-- **************************************************
	-- * Resync health
	-- **************************************************
	
	local redTotalBefore = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	local rottenBefore = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
	local redBefore = redTotalBefore - rottenBefore * 2
	local eternalBefore = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	local goldenBefore = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	local redTotalAfter = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	local eternalAfter = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	local goldenAfter = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	
	local addedWhoreOfBabylonPrevention = CustomHealthAPI.Helper.AddWhoreOfBabylonPrevention(player)
	local addedBloodyBabylonPrevention = CustomHealthAPI.Helper.AddBloodyBabylonPrevention(player)
	
	local challengeIsHaveAHeart = Game().Challenge == Challenge.CHALLENGE_HAVE_A_HEART
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_NULL
	end
	
	CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -1 * goldenAfter)
	CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, -1 * eternalAfter)
	CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, -1 * redTotalAfter)
	
	CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, rottenBefore * 2)
	CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, redBefore)
	CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, eternalBefore)
	CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, goldenBefore)
	
	if addedWhoreOfBabylonPrevention then CustomHealthAPI.Helper.RemoveWhoreOfBabylonPrevention(player) end
	if addedBloodyBabylonPrevention then CustomHealthAPI.Helper.RemoveBloodyBabylonPrevention(player) end
	
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_HAVE_A_HEART
	end
end

function CustomHealthAPI.Helper.ResyncOverlays(player)
	local data = player:GetData().CustomHealthAPISavedata
	data.Overlays["ETERNAL_HEART"] = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	data.Overlays["GOLDEN_HEART"] = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
end

function CustomHealthAPI.Helper.HandleUnexpectedRed(player)
	local playerType = player:GetPlayerType()
	if CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[playerType] and CustomHealthAPI.Helper.GetTotalRedHP(player) > 0 then
		local data = player:GetData().CustomHealthAPISavedata
		local redMasks = data.RedHealthMasks
		
		for i = 1, #redMasks do
			local mask = redMasks[i]
			for j = #mask, 1, -1 do
				table.remove(mask, j)
			end
		end
		
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	end
end

function CustomHealthAPI.Helper.HandleUnexpectedMax(player)
	local playerType = player:GetPlayerType()
	if (CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playerType] or
	    playerType == PlayerType.PLAYER_THEFORGOTTEN or
	    playerType == PlayerType.PLAYER_THESOUL) and
	   CustomHealthAPI.Helper.GetTotalMaxHP(player) > 0
	then
		local data = player:GetData().CustomHealthAPISavedata
		local otherMasks = data.OtherHealthMasks

		local numMax = math.ceil(CustomHealthAPI.Helper.GetTotalMaxHP(player) / 2)

		for i = 1, #otherMasks do
			local mask = otherMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				local key = health.Key
				if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
				   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
				   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP == 0
				then
					table.remove(mask, j)
				end
			end
		end

		local newKey = CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playerType]
		local newHp = numMax * 2
		if playerType == PlayerType.PLAYER_THEFORGOTTEN then
			newKey = "BONE_HEART"
			newHp = numMax
		elseif playerType == PlayerType.PLAYER_THESOUL then
			newKey = "SOUL_HEART"
		end

		CustomHealthAPI.Helper.UpdateHealthMasks(player, newKey, newHp, true, false, true, true)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	end
end

function CustomHealthAPI.Helper.ResyncHealthOfPlayer(player, isSubPlayer)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then return end
	
	if player:GetData().CustomHealthAPIOtherData and player:GetData().CustomHealthAPIOtherData.InDamageCallback == Isaac.GetFrameCount() then return end
	
	player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
	player:GetData().CustomHealthAPIOtherData.InDamageCallback = nil
	player:GetData().CustomHealthAPIOtherData.DoNotUpdateBasegameHealthState = nil
	
	if not avoidRecursive then
		avoidRecursive = true
		
		player:GetData().CustomHealthAPIOtherData.ShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED) >= 1
		
		local alabasterChargesToAdd = 0
		for i = 2, 0, -1 do
			if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
				alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
			end
		end
		player:GetData().CustomHealthAPIOtherData.AlabasterChargesAdded = math.max(0, (player:GetData().CustomHealthAPIOtherData.AlabasterChargesToAdd or alabasterChargesToAdd) - alabasterChargesToAdd)
		player:GetData().CustomHealthAPIOtherData.AlabasterChargesToAdd = alabasterChargesToAdd
		
		CustomHealthAPI.Helper.FinishDamageDesync(player)

		CustomHealthAPI.Helper.HandleReverseSunSyncing(player)
		CustomHealthAPI.Helper.HandleReverseEmpressOnRemove(player)
		CustomHealthAPI.Helper.HandleCollectiblePickup(player)

		CustomHealthAPI.Helper.ResyncOverlays(player)
		CustomHealthAPI.Helper.ResyncOtherHealthOfPlayer(player)
		CustomHealthAPI.Helper.ResyncRedHealthOfPlayer(player)
		
		CustomHealthAPI.Helper.HandleUnexpectedRed(player)
		CustomHealthAPI.Helper.HandleUnexpectedMax(player)
		
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RESYNC_PLAYER)
		for _, callback in ipairs(callbacks) do
			callback.Function(player, isSubPlayer)
		end
		
		player:GetData().CustomHealthAPIOtherData.AlabasterChargesAdded = 0
		
		avoidRecursive = false
	end
	
	if player:GetSubPlayer() ~= nil and not isSubPlayer then
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player:GetSubPlayer(), true)
	end
end

function CustomHealthAPI.Helper.ResyncHealth()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	end
end
