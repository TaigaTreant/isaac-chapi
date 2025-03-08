CustomHealthAPI.PersistentData.DoHUDPostUpdateForLivesHUD = nil
CustomHealthAPI.PersistentData.PreventResyncing = 0
CustomHealthAPI.PersistentData.AllowAddHeartsCallback = 0
CustomHealthAPI.PersistentData.PreventGetHPCaching = false

local avoidRecursive = false

function CustomHealthAPI.Helper.AddResetRecursiveResyncPreventionCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.ResetRecursiveResyncPreventionCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddResetRecursiveResyncPreventionCallback)

function CustomHealthAPI.Helper.RemoveResetRecursiveResyncPreventionCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.ResetRecursiveResyncPreventionCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveResetRecursiveResyncPreventionCallback)

function CustomHealthAPI.Mod:ResetRecursiveResyncPreventionCallback()
	if avoidRecursive then
		print("Custom Health API ERROR: Resyncing recursive prevention failed.")
		avoidRecursive = false
	end
	
	if CustomHealthAPI.PersistentData.PreventResyncing ~= 0 then
		print("Custom Health API ERROR: Unexpected value of PreventResyncing.")
		CustomHealthAPI.PersistentData.PreventResyncing = 0
	end
	
	if CustomHealthAPI.PersistentData.AllowAddHeartsCallback ~= 0 then
		print("Custom Health API ERROR: Unexpected value of AllowAddHeartsCallback.")
		CustomHealthAPI.PersistentData.AllowAddHeartsCallback = 0
	end
	
	if CustomHealthAPI.PersistentData.PreventGetHPCaching then
		CustomHealthAPI.PersistentData.PreventGetHPCaching = false
	end
end

if REPENTOGON then
	function CustomHealthAPI.Helper.AddPreAddHeartsCallback()
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_PLAYER_ADD_HEARTS, CustomHealthAPI.Enums.CallbackPriorities.FIRST, CustomHealthAPI.Mod.PreAddHeartsCallback, -1)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreAddHeartsCallback)

	function CustomHealthAPI.Helper.RemovePreAddHeartsCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_PLAYER_ADD_HEARTS, CustomHealthAPI.Mod.PreAddHeartsCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreAddHeartsCallback)

	function CustomHealthAPI.Helper.AddPostAddHeartsCallback()
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PLAYER_ADD_HEARTS, CustomHealthAPI.Enums.CallbackPriorities.FIRST, CustomHealthAPI.Mod.PostAddHeartsCallback, -1)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPostAddHeartsCallback)

	function CustomHealthAPI.Helper.RemovePostAddHeartsCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PLAYER_ADD_HEARTS, CustomHealthAPI.Mod.PostAddHeartsCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePostAddHeartsCallback)
end

function CustomHealthAPI.Mod:PreAddHeartsCallback(player, amount, addHealthType)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if CustomHealthAPI.PersistentData.AllowAddHeartsCallback > 0 then
			CustomHealthAPI.PersistentData.AllowAddHeartsCallback = CustomHealthAPI.PersistentData.AllowAddHeartsCallback - 1
		end
		return
	end
	if CustomHealthAPI.PersistentData.AllowAddHeartsCallback <= 0 then
		return amount
	end
	CustomHealthAPI.PersistentData.AllowAddHeartsCallback = CustomHealthAPI.PersistentData.AllowAddHeartsCallback - 1
end

function CustomHealthAPI.Mod:PostAddHeartsCallback(player, amount, addHealthType)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if CustomHealthAPI.PersistentData.AllowAddHeartsCallback > 0 then
			CustomHealthAPI.PersistentData.AllowAddHeartsCallback = CustomHealthAPI.PersistentData.AllowAddHeartsCallback - 1
		end
		return
	end
	if CustomHealthAPI.PersistentData.AllowAddHeartsCallback <= 0 then
		return false
	end
	CustomHealthAPI.PersistentData.AllowAddHeartsCallback = CustomHealthAPI.PersistentData.AllowAddHeartsCallback - 1
end

if ModCallbacks.MC_PLAYER_HEALTH_TYPE_CHANGE then
	function CustomHealthAPI.Helper.AddHealthTypeChangeEarlyCallback()
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PLAYER_HEALTH_TYPE_CHANGE, CustomHealthAPI.Enums.CallbackPriorities.EARLY, CustomHealthAPI.Mod.HealthTypeChangeEarlyCallback, -1)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHealthTypeChangeEarlyCallback)

	function CustomHealthAPI.Helper.RemoveHealthTypeChangeEarlyCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_HEALTH_TYPE_CHANGE, CustomHealthAPI.Mod.HealthTypeChangeEarlyCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHealthTypeChangeEarlyCallback)

	function CustomHealthAPI.Helper.AddHealthTypeChangeLateCallback()
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PLAYER_HEALTH_TYPE_CHANGE, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.HealthTypeChangeLateCallback, -1)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHealthTypeChangeLateCallback)

	function CustomHealthAPI.Helper.RemoveHealthTypeChangeLateCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PLAYER_HEALTH_TYPE_CHANGE, CustomHealthAPI.Mod.HealthTypeChangeLateCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHealthTypeChangeLateCallback)
end

function CustomHealthAPI.Mod:HealthTypeChangeEarlyCallback(player)
	local data = player:GetData()
	data.CustomHealthAPIOtherData = data.CustomHealthAPIOtherData or {}
	data.CustomHealthAPIOtherData.InHealthTypeChangeCallback = Isaac.GetFrameCount()
end

function CustomHealthAPI.Mod:HealthTypeChangeLateCallback(player)
	player:GetData().CustomHealthAPIOtherData.InHealthTypeChangeCallback = nil

	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.FinishDamageDesync(player)

	CustomHealthAPI.Helper.HandleUnexpectedMax(player)
end

function CustomHealthAPI.Helper.AddCheckIfHealthValuesChangedCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Enums.CallbackPriorities.EARLY, CustomHealthAPI.Mod.CheckIfHealthValuesChangedCallback, -1)
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
	if CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
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
	
	CustomHealthAPI.PersistentData.PreventGetHPCaching = true
	CustomHealthAPI.Library.ClearHPCache(player)
	
	local ignoreRed = diffRotten > 0 and diffRotten >= diffTotal
	if diffRotten ~= 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "ROTTEN_HEART", diffRotten * 2, true, false, true, true)
		
		expectedTotal = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true)
		expectedRotten = CustomHealthAPI.Helper.GetTotalHPOfKey(player, "ROTTEN_HEART", true)
	
		actualTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
		actualRotten = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
	
		if diffRed ~= 0 then
			diffRotten = actualRotten - expectedRotten
			diffTotal = actualTotal - expectedTotal
			diffRed = diffTotal - (diffRotten * 2)
		end
	end
	if not ignoreRed and diffRed ~= 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", diffRed, true, false, true, true)
	end
	
	CustomHealthAPI.Helper.UpdateBasegameHealthStateNoOther(player)
	
	CustomHealthAPI.PersistentData.PreventGetHPCaching = false
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

	CustomHealthAPI.PersistentData.PreventGetHPCaching = true
	CustomHealthAPI.Library.ClearHPCache(player)
	
	-- **************************************************
	-- * Update masks
	-- **************************************************
	
	if diffBroken < 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BROKEN_HEART", diffBroken, true, false, true, true)
		
		expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
		expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART", true)
		expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
		expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
		expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
	
		actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
		actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
		if diffSoulTotal ~= 0 then diffSoulTotal = actualSoulTotal - expectedSoulTotal end
		if diffBlack ~= 0 then diffBlack = actualBlack - expectedBlack end
		if diffMax ~= 0 then diffMax = actualMax - expectedMax end
		if diffBone ~= 0 then diffBone = actualBone - expectedBone end
		if diffBroken ~= 0 then diffBroken = actualBroken - expectedBroken end
	end
	
	if diffMax < 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", diffMax, true, false, true, true)
		
		expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
		expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART", true)
		expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
		expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
		expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
	
		actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
		actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
		if diffSoulTotal ~= 0 then diffSoulTotal = actualSoulTotal - expectedSoulTotal end
		if diffBlack ~= 0 then diffBlack = actualBlack - expectedBlack end
		if diffMax ~= 0 then diffMax = actualMax - expectedMax end
		if diffBone ~= 0 then diffBone = actualBone - expectedBone end
		if diffBroken ~= 0 then diffBroken = actualBroken - expectedBroken end
	end
	
	if diffSoulTotal ~= 0 or diffBlack ~= 0 or diffBone ~= 0 then
		local ignoreSoul = diffBlack > 0 and diffBlack * 2 >= diffSoulTotal
		if not ignoreSoul and diffSoulTotal > 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", diffSoulTotal, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART", true)
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
			if diffSoulTotal ~= 0 then diffSoulTotal = actualSoulTotal - expectedSoulTotal end
			if diffBlack ~= 0 then diffBlack = actualBlack - expectedBlack end
			if diffMax ~= 0 then diffMax = actualMax - expectedMax end
			if diffBone ~= 0 then diffBone = actualBone - expectedBone end
			if diffBroken ~= 0 then diffBroken = actualBroken - expectedBroken end
		end
		
		if diffBlack > 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BLACK_HEART", diffBlack * 2, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART", true)
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
			if diffSoulTotal ~= 0 then diffSoulTotal = actualSoulTotal - expectedSoulTotal end
			if diffBlack ~= 0 then diffBlack = actualBlack - expectedBlack end
			if diffMax ~= 0 then diffMax = actualMax - expectedMax end
			if diffBone ~= 0 then diffBone = actualBone - expectedBone end
			if diffBroken ~= 0 then diffBroken = actualBroken - expectedBroken end
		end
		
		if diffBone > 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", diffBone, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART", true)
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
			if diffSoulTotal ~= 0 then diffSoulTotal = actualSoulTotal - expectedSoulTotal end
			if diffBlack ~= 0 then diffBlack = actualBlack - expectedBlack end
			if diffMax ~= 0 then diffMax = actualMax - expectedMax end
			if diffBone ~= 0 then diffBone = actualBone - expectedBone end
			if diffBroken ~= 0 then diffBroken = actualBroken - expectedBroken end
		end
		
		if diffBone < 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", diffBone, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART", true)
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
			if diffSoulTotal ~= 0 then diffSoulTotal = actualSoulTotal - expectedSoulTotal end
			if diffBlack ~= 0 then diffBlack = actualBlack - expectedBlack end
			if diffMax ~= 0 then diffMax = actualMax - expectedMax end
			if diffBone ~= 0 then diffBone = actualBone - expectedBone end
			if diffBroken ~= 0 then diffBroken = actualBroken - expectedBroken end
		end
		
		--[[if diffBlack < 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BLACK_HEART", diffBlack, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART", true)
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
			if diffSoulTotal ~= 0 then diffSoulTotal = actualSoulTotal - expectedSoulTotal end
			if diffBlack ~= 0 then diffBlack = actualBlack - expectedBlack end
			if diffMax ~= 0 then diffMax = actualMax - expectedMax end
			if diffBone ~= 0 then diffBone = actualBone - expectedBone end
			if diffBroken ~= 0 then diffBroken = actualBroken - expectedBroken end
		end]]--
		
		if not ignoreSoul and diffSoulTotal < 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", diffSoulTotal, true, false, true, true)
			
			expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
			expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART", true)
			expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
			expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
			expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
		
			actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
			actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
			if diffSoulTotal ~= 0 then diffSoulTotal = actualSoulTotal - expectedSoulTotal end
			if diffBlack ~= 0 then diffBlack = actualBlack - expectedBlack end
			if diffMax ~= 0 then diffMax = actualMax - expectedMax end
			if diffBone ~= 0 then diffBone = actualBone - expectedBone end
			if diffBroken ~= 0 then diffBroken = actualBroken - expectedBroken end
		end
	end
	
	if diffMax > 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", diffMax, true, false, true, true)
		
		expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
		expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART", true)
		expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
		expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
		expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
	
		actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
		actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
		if diffSoulTotal ~= 0 then diffSoulTotal = actualSoulTotal - expectedSoulTotal end
		if diffBlack ~= 0 then diffBlack = actualBlack - expectedBlack end
		if diffMax ~= 0 then diffMax = actualMax - expectedMax end
		if diffBone ~= 0 then diffBone = actualBone - expectedBone end
		if diffBroken ~= 0 then diffBroken = actualBroken - expectedBroken end
	end
	
	if diffBroken > 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BROKEN_HEART", diffBroken, true, false, true, true)
		
		expectedSoulTotal = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
		expectedBlack = CustomHealthAPI.Helper.GetTotalKeys(player, "BLACK_HEART", true)
		expectedMax = CustomHealthAPI.Helper.GetTotalMaxHP(player, true)
		expectedBone = CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true)
		expectedBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART", true)
	
		actualSoulTotal = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
		actualBlack = CustomHealthAPI.Helper.GetBasegameBlackHeartsNum(player)
		actualMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
		actualBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
		actualBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
		if diffSoulTotal ~= 0 then diffSoulTotal = actualSoulTotal - expectedSoulTotal end
		if diffBlack ~= 0 then diffBlack = actualBlack - expectedBlack end
		if diffMax ~= 0 then diffMax = actualMax - expectedMax end
		if diffBone ~= 0 then diffBone = actualBone - expectedBone end
		if diffBroken ~= 0 then diffBroken = actualBroken - expectedBroken end
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
	local rottenAfter = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
	local redAfter = redTotalAfter - rottenAfter * 2
	local eternalAfter = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	local goldenAfter = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	
	if rottenBefore == rottenAfter and redBefore == redAfter and eternalBefore == eternalAfter and goldenBefore == goldenAfter then
		CustomHealthAPI.PersistentData.PreventGetHPCaching = false
		return
	end
	
	local addedWhoreOfBabylonPrevention = CustomHealthAPI.Helper.AddWhoreOfBabylonPrevention(player)
	local addedBloodyBabylonPrevention = CustomHealthAPI.Helper.AddBloodyBabylonPrevention(player)
	
	local challengeIsHaveAHeart = Game().Challenge == Challenge.CHALLENGE_HAVE_A_HEART
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_NULL
	end
	
	--CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -1 * goldenAfter)
	--CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, -1 * eternalAfter)
	--CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, -1 * redTotalAfter)
	--
	--CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, rottenBefore * 2)
	--CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, redBefore)
	--CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, eternalBefore)
	--CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, goldenBefore)
	
	local rottenDiff = rottenBefore - rottenAfter
	if rottenDiff ~= 0 then
		CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, rottenDiff * 2)
	end
	
	local redDiff = redBefore - (CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) - (CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player) * 2))
	if redDiff ~= 0 then
		CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, redDiff)
	end
	
	local goldenDiff = goldenBefore - goldenAfter
	if goldenDiff ~= 0 then
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, goldenDiff)
	end
	
	local eternalDiff = eternalBefore - eternalAfter
	if eternalDiff ~= 0 then
		CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, eternalDiff)
	end
	
	if addedWhoreOfBabylonPrevention then CustomHealthAPI.Helper.RemoveWhoreOfBabylonPrevention(player) end
	if addedBloodyBabylonPrevention then CustomHealthAPI.Helper.RemoveBloodyBabylonPrevention(player) end
	
	if challengeIsHaveAHeart then
		Game().Challenge = Challenge.CHALLENGE_HAVE_A_HEART
	end
	
	CustomHealthAPI.PersistentData.PreventGetHPCaching = false
end

function CustomHealthAPI.Helper.ResyncEternalHearts(player)
	local data = player:GetData().CustomHealthAPISavedata
	
	local key = "ETERNAL_HEART"
	local hp = CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player) - data.Overlays["ETERNAL_HEART"]
	if hp == 0 then return end
	
	CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true)
end

function CustomHealthAPI.Helper.ResyncGoldHearts(player)
	local data = player:GetData().CustomHealthAPISavedata
	
	local key = "GOLDEN_HEART"
	local hp = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player) - data.Overlays["GOLDEN_HEART"]
	if hp == 0 then return end
	
	CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true)
end

function CustomHealthAPI.Helper.ResyncOverlays(player)
	CustomHealthAPI.Helper.ResyncEternalHearts(player)
	CustomHealthAPI.Helper.ResyncGoldHearts(player)
end

function CustomHealthAPI.Helper.HandleUnexpectedRed(player)
	local playerType = player:GetPlayerType()
	if CustomHealthAPI.Helper.PlayerIsRedHealthless(player, true) and CustomHealthAPI.Helper.GetTotalRedHP(player) > 0 then
		CustomHealthAPI.PersistentData.PreventGetHPCaching = true
		CustomHealthAPI.Library.ClearHPCache(player)
		
		local data = player:GetData().CustomHealthAPISavedata
		local redMasks = data.RedHealthMasks
		
		for i = 1, #redMasks do
			local mask = redMasks[i]
			for j = #mask, 1, -1 do
				table.remove(mask, j)
			end
		end
		
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		
		CustomHealthAPI.PersistentData.PreventGetHPCaching = false
	end
end

function CustomHealthAPI.Helper.HandleUnexpectedMax(player)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) or player:GetData().CustomHealthAPIOtherData.InHealthTypeChangeCallback == Isaac.GetFrameCount() then 
		return
	end

	player:GetData().CustomHealthAPIOtherData.InHealthTypeChangeCallback = nil

	local playerType = player:GetPlayerType()
	local isSoulHeartOnly = CustomHealthAPI.Helper.PlayerIsSoulHeartOnly(player)
	local isBoneHeartOnly = CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player)
	if (isSoulHeartOnly or isBoneHeartOnly) and
	   CustomHealthAPI.Helper.GetTotalMaxHP(player) > 0
	then
		CustomHealthAPI.PersistentData.PreventGetHPCaching = true
		CustomHealthAPI.Library.ClearHPCache(player)

		local data = player:GetData().CustomHealthAPISavedata
		local otherMasks = data.OtherHealthMasks

		local newKey = CustomHealthAPI.Helper.GetConvertedMaxHealthType(player)
		if not newKey or not CustomHealthAPI.PersistentData.HealthDefinitions[newKey] then
			newKey = isBoneHeartOnly and "BONE_HEART" or "SOUL_HEART"
		end
		local newType = CustomHealthAPI.PersistentData.HealthDefinitions[newKey].Type
		local newMask = CustomHealthAPI.PersistentData.HealthDefinitions[newKey].MaskIndex
		local newMaxHP = CustomHealthAPI.PersistentData.HealthDefinitions[newKey].MaxHP
		local canConvert = newMaxHP > 0 and (newType == CustomHealthAPI.Enums.HealthTypes.SOUL or newType == CustomHealthAPI.Enums.HealthTypes.CONTAINER)

		local numInsert = 0
		local numHeal = 0

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
					if canConvert then
						if i <= newMask then
							numInsert = numInsert + 1
						else
							numHeal = numHeal + 1
						end
					end
				end
			end
		end

		if numInsert > 0 then
			-- When converting heart containers in the same (or prior) mask, insert the new hearts at the front of the mask
			-- to make it seem like the hearts were converted "in place".
			-- For consistency with how REPENTOGON will handle such conversions, and also visually pleasing.
			CustomHealthAPI.Helper.UpdateHealthMasks(player, newKey, numInsert * newMaxHP, true, false, true, true, false, false, true)
		end
		if numHeal > 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, newKey, numHeal * newMaxHP, true, false, true, true, false, false, false)
		end

		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		CustomHealthAPI.PersistentData.PreventGetHPCaching = false
	end
end

function CustomHealthAPI.Helper.ResyncHealthOfPlayer(player, isSubPlayer)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then return end
	if CustomHealthAPI.PersistentData.PreventResyncing > 0 then return end
	if player:GetData().CustomHealthAPIOtherData and player:GetData().CustomHealthAPIOtherData.InDamageCallback == Isaac.GetFrameCount() then return end
	
	player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
	player:GetData().CustomHealthAPIOtherData.InDamageCallback = nil
	player:GetData().CustomHealthAPIOtherData.DoNotUpdateBasegameHealthState = nil
	
	if not avoidRecursive then
		avoidRecursive = true
		
		player:GetData().CustomHealthAPIOtherData.ShacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED) >= 1
		
		local alabasterChargesToAdd = 0
		if player:HasCollectible(CollectibleType.COLLECTIBLE_ALABASTER_BOX) then
			for i = 2, 0, -1 do
				if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
					alabasterChargesToAdd = alabasterChargesToAdd + (12 - player:GetActiveCharge(i))
				end
			end
		end
		player:GetData().CustomHealthAPIOtherData.AlabasterChargesAdded = math.max(0, (player:GetData().CustomHealthAPIOtherData.AlabasterChargesToAdd or alabasterChargesToAdd) - alabasterChargesToAdd)
		player:GetData().CustomHealthAPIOtherData.AlabasterChargesToAdd = alabasterChargesToAdd
		
		if not REPENTOGON then
			CustomHealthAPI.Helper.FinishDamageDesync(player)
		end

		CustomHealthAPI.Helper.HandleReverseSunSyncing(player)
		CustomHealthAPI.Helper.HandleReverseEmpressOnRemove(player)
		if not REPENTOGON then
			CustomHealthAPI.Helper.HandleCollectiblePickup(player)
		end

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
