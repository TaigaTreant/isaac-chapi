-- NEED TO ADD STRENGTH SUPPORT TO THIS MAYBE
-- HANDLING FOR CHANGING THE PLAYER TYPE FROM FORGOTTEN'S/SOUL'S HIDDEN SUBPLAYER (PLS DONT DO THIS MODDERS)
-- HANDLING FOR THE SOUL HEART WEIRDNESS THAT HAPPENS WHEN AN OTHERTWIN TAINTED SOUL IS TURNED INTO SOMETHING ELSE
-- HANDLING FOR CHANGING FROM TAINTED LAZARUS WITH BIRTHRIGHT (THE BASEGAME BEHAVIOUR IS BROKEN SO NOT IDK)

-- default: 
--     on change from: do nothing
--     on change to: do nothing
-- soul hp characters: 
--     on change from: do nothing
--     on change to: remove all containers and red, refund half a soul heart if necessary
-- lost/Blost/Bsoul:
--     on change from: ignore routine (set hp to half a soul heart)
--     on change to: delete custom health
-- keeper/Bkeeper:
--     on change from: ignore routine (set red hp to number of filled containers * 2 and max hp to number of containers * 2)
--     on change to: delete custom health
-- forgotten:
--     on change from: append subplayer hp to end of player hp and clear subplayer hp
--     on change to: convert containers to bone hearts, refund bone if necessary, give all soul hearts to soul
-- soul:
--     on change from: append subplayer hp to end of player hp and clear subplayer hp
--     on change to: remove all containers, refund soul if necessary, give all red hearts and bone hearts + 2 to forgotten
-- bethany:
--     on change from: convert soul charges into soul hearts
--     on change to: convert soul hearts to soul charges, refund full container if necessary
-- jacob:
--     on change from: append othertwin hp to end of player hp and clear othertwin hp
--     on change to: divide health between jacob and the spawned esau

function CustomHealthAPI.Helper.PreChangePlayerType(player, playertype, dontManuallyChange)
	local oldplayertype = player:GetPlayerType()
	if oldplayertype == playertype then
		if not dontManuallyChange then 
			CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType(player, playertype)
			
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_CHANGE_PLAYER_TYPE)
			for _, callback in ipairs(callbacks) do
				callback.Function(player)
			end
		end
		
		return false
	end
	
	if CustomHealthAPI.Helper.IsFoundSoul(player) or player:IsCoopGhost() then
		if not dontManuallyChange then 
			CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType(player, playertype)
			
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_CHANGE_PLAYER_TYPE)
			for _, callback in ipairs(callbacks) do
				callback.Function(player)
			end
		end
		
		return false
	end
	
	if oldplayertype == PlayerType.PLAYER_THELOST or
	   oldplayertype == PlayerType.PLAYER_THELOST_B or
	   oldplayertype == PlayerType.PLAYER_KEEPER or
	   oldplayertype == PlayerType.PLAYER_KEEPER_B or
	   oldplayertype == PlayerType.PLAYER_THESOUL_B
	then
		if not dontManuallyChange then 
			CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType(player, playertype)
			
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_CHANGE_PLAYER_TYPE)
			for _, callback in ipairs(callbacks) do
				callback.Function(player)
			end
		end
		
		return false
	end
	
	if playertype == PlayerType.PLAYER_THELOST or
	   playertype == PlayerType.PLAYER_KEEPER or
	   playertype == PlayerType.PLAYER_THELOST_B or
	   playertype == PlayerType.PLAYER_KEEPER_B or
	   playertype == PlayerType.PLAYER_THESOUL_B
	then
		player:GetData().CustomHealthAPISavedata = nil
		if player:GetSubPlayer() ~= nil then
			player:GetSubPlayer():GetData().CustomHealthAPISavedata = nil
		end
		
		if not dontManuallyChange then 
			CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType(player, playertype)
			
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_CHANGE_PLAYER_TYPE)
			for _, callback in ipairs(callbacks) do
				callback.Function(player)
			end
		end
		
		return false
	end
	
	local soulCharges = player:GetSoulCharge()
	if oldplayertype == PlayerType.PLAYER_THEFORGOTTEN then
		CustomHealthAPI.Helper.HandleHealthOnConvertFromForgotten(player)
	elseif oldplayertype == PlayerType.PLAYER_THESOUL then
		CustomHealthAPI.Helper.HandleHealthOnConvertFromTheSoul(player)
	elseif oldplayertype == PlayerType.PLAYER_THEFORGOTTEN_B or oldplayertype == PlayerType.PLAYER_JACOB then
		CustomHealthAPI.Helper.HandleHealthOnConvertFromTwin(player)
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local eternals = data.Overlays["ETERNAL_HEART"]
	local golds = data.Overlays["GOLDEN_HEART"]
	data.Overlays["ETERNAL_HEART"] = 0
	data.Overlays["GOLDEN_HEART"] = 0
	
	--drain eternal/gold hp from player
	CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -99)
	CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, -99)
	
	player:GetData().CustomHealthAPITemp = {}
	player:GetData().CustomHealthAPITemp.SoulCharges = soulCharges 
	player:GetData().CustomHealthAPITemp.Eternals = eternals 
	player:GetData().CustomHealthAPITemp.Golds = golds 
	
	return true
end

function CustomHealthAPI.Helper.PostChangePlayerType(player, playertype)
	if playertype == PlayerType.PLAYER_THELOST or
	   playertype == PlayerType.PLAYER_KEEPER or
	   playertype == PlayerType.PLAYER_THELOST_B or
	   playertype == PlayerType.PLAYER_KEEPER_B or
	   playertype == PlayerType.PLAYER_THESOUL_B or
	   player:GetData().CustomHealthAPISavedata == nil
	then
		player:GetData().CustomHealthAPISavedata = nil
		
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_CHANGE_PLAYER_TYPE)
		for _, callback in ipairs(callbacks) do
			callback.Function(player)
		end
		
		return
	end
	
	local soulCharges = player:GetData().CustomHealthAPITemp.SoulCharges
	local eternals = player:GetData().CustomHealthAPITemp.Eternals
	local golds = player:GetData().CustomHealthAPITemp.Golds
	player:GetData().CustomHealthAPITemp = nil
	
	local data = player:GetData().CustomHealthAPISavedata
	player:GetData().CustomHealthAPISavedata.PlayerType = playertype
	
	if playertype == PlayerType.PLAYER_THEFORGOTTEN then
		CustomHealthAPI.Helper.HandleHealthOnConvertToForgotten(player, soulCharges)
	elseif playertype == PlayerType.PLAYER_THESOUL then
		CustomHealthAPI.Helper.HandleHealthOnConvertToTheSoul(player, soulCharges)
	elseif playertype == PlayerType.PLAYER_BETHANY then
		CustomHealthAPI.Helper.HandleHealthOnConvertToBethany(player, soulCharges)
	elseif playertype == PlayerType.PLAYER_JACOB and player:GetOtherTwin() then
		CustomHealthAPI.Helper.HandleHealthOnConvertToJacobEsau(player, soulCharges)
	elseif CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playertype] then
		CustomHealthAPI.Helper.HandleHealthOnConvertToSoulHpPlayer(player, soulCharges)
	else
		CustomHealthAPI.Helper.HandleHealthOnConvertToGeneric(player, soulCharges)
	end
	
	CustomHealthAPI.Helper.HandleEternalHeartsPostChange(player, eternals)
	CustomHealthAPI.Helper.HandleGoldenHeartsPostChange(player, playertype, golds)
	
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_CHANGE_PLAYER_TYPE)
	for _, callback in ipairs(callbacks) do
		callback.Function(player)
	end
end

function CustomHealthAPI.Helper.ChangePlayerType(player, playertype)
	if CustomHealthAPI.Helper.PreChangePlayerType(player, playertype) then
		CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType(player, playertype)
		CustomHealthAPI.Helper.PostChangePlayerType(player, playertype)
	end
end

function CustomHealthAPI.Helper.RestrictBrokenHearts(player, limit)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks

	while CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART") > limit do
		local lowestPriorityHealth
		local lowestPriority
		local maskIndexOfLowestPriority
		local indexOfLowestPriority
		for i = #otherMasks, 1, -1 do
			local mask = otherMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				
				if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
				   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained == CustomHealthAPI.Enums.HealthKinds.NONE
				then
					local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
					if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
						lowestPriorityHealth = health
						lowestPriority = removePriorityOfHealth
						maskIndexOfLowestPriority = i
						indexOfLowestPriority = j
					end
				end
			end
		end
		
		if lowestPriority ~= nil then
			table.remove(otherMasks[maskIndexOfLowestPriority], indexOfLowestPriority)
		end
	end
end

function CustomHealthAPI.Helper.RestrictBoneHearts(player)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks

	while CustomHealthAPI.Helper.GetRoomForOtherKeys(player) < 0 and 
	      CustomHealthAPI.Helper.GetTotalMaxHP(player) + CustomHealthAPI.Helper.GetTotalBoneHP(player, true) > 0 
	do
		local lowestPriorityHealth
		local lowestPriority
		local maskIndexOfLowestPriority
		local indexOfLowestPriority
		for i = #otherMasks, 1, -1 do
			local mask = otherMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				
				if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
				   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP > 0 and
				   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
				then
					local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
					if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
						lowestPriorityHealth = health
						lowestPriority = removePriorityOfHealth
						maskIndexOfLowestPriority = i
						indexOfLowestPriority = j
					end
				end
			end
		end
		
		if lowestPriority ~= nil then
			table.remove(otherMasks[maskIndexOfLowestPriority], indexOfLowestPriority)
		else
			break
		end
	end
end

function CustomHealthAPI.Helper.RestrictSoulHearts(player)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks

	while CustomHealthAPI.Helper.GetRoomForOtherKeys(player) < 0 and 
	      CustomHealthAPI.Helper.GetTotalSoulHP(player, true) > 0 
	do
		local lowestPriorityHealth
		local lowestPriority
		local maskIndexOfLowestPriority
		local indexOfLowestPriority
		for i = #otherMasks, 1, -1 do
			local mask = otherMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				
				if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
					local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
					if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
						lowestPriorityHealth = health
						lowestPriority = removePriorityOfHealth
						maskIndexOfLowestPriority = i
						indexOfLowestPriority = j
					end
				end
			end
		end
		
		if lowestPriority ~= nil then
			table.remove(otherMasks[maskIndexOfLowestPriority], indexOfLowestPriority)
		else
			break
		end
	end
end

function CustomHealthAPI.Helper.RestrictHeartContainers(player)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks

	while CustomHealthAPI.Helper.GetRoomForOtherKeys(player) < 0 and 
	      CustomHealthAPI.Helper.GetTotalMaxHP(player) + CustomHealthAPI.Helper.GetTotalBoneHP(player, true) > 0 
	do
		local lowestPriorityHealth
		local lowestPriority
		local maskIndexOfLowestPriority
		local indexOfLowestPriority
		for i = #otherMasks, 1, -1 do
			local mask = otherMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				
				if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
				   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP <= 0 and
				   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
				then
					local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
					if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
						lowestPriorityHealth = health
						lowestPriority = removePriorityOfHealth
						maskIndexOfLowestPriority = i
						indexOfLowestPriority = j
					end
				end
			end
		end
		
		if lowestPriority ~= nil then
			table.remove(otherMasks[maskIndexOfLowestPriority], indexOfLowestPriority)
		else
			break
		end
	end
end

function CustomHealthAPI.Helper.RestrictRedHearts(player)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	
	while CustomHealthAPI.Helper.GetTotalRedHP(player, true) > CustomHealthAPI.Helper.GetRedCapacity(player) do
		local redMasks = data.RedHealthMasks
		
		local lowestPriorityHealth
		local lowestPriority
		local maskIndexOfLowestPriority
		local indexOfLowestPriority
		for i = #redMasks, 1, -1 do
			local mask = redMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				
				local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				if lowestPriorityHealth == nil or addPriorityOfHealth < lowestPriority then
					lowestPriorityHealth = health
					lowestPriority = addPriorityOfHealth
					maskIndexOfLowestPriority = i
					indexOfLowestPriority = j
				end
			end
		end
		
		if lowestPriority ~= nil then
			table.remove(redMasks[maskIndexOfLowestPriority], indexOfLowestPriority)
			
			local maxhp = CustomHealthAPI.Library.GetInfoOfHealth(lowestPriorityHealth, "MaxHP")
			if maxhp <= 1 then
				CustomHealthAPI.Helper.HealRedAnywhere(player, 2)
			else
				CustomHealthAPI.Helper.HealRedAnywhere(player, lowestPriorityHealth.HP)
			end
		end
	end
end

function CustomHealthAPI.Helper.HandleHealthOnConvertToForgotten(player, soulCharges)
	-- convert containers to bone hearts, refund bone if necessary, give all soul hearts to subplayer (if they exist)
	local data = player:GetData().CustomHealthAPISavedata
	
	-- initialize subplayer
	local subplayer = player:GetSubPlayer()
	if subplayer then
		subplayer:GetData().CustomHealthAPISavedata = {}
		local sdata = subplayer:GetData().CustomHealthAPISavedata
		
		local redorder = CustomHealthAPI.Helper.GetRedHealthOrder()
		sdata.RedHealthMasks = {}
		for i = 1, #redorder do
			sdata.RedHealthMasks[i] = {}
		end
		
		local otherorder = CustomHealthAPI.Helper.GetOtherHealthOrder()
		sdata.OtherHealthMasks = {}
		for i = 1, #otherorder do
			sdata.OtherHealthMasks[i] = {}
		end
		
		sdata.Overlays = {}
		sdata.Overlays["ETERNAL_HEART"] = 0
		sdata.Overlays["GOLDEN_HEART"] = 0
		
		sdata.PlayerType = subplayer:GetPlayerType()
	end
	
	-- give soul hearts to subplayer (or remove if no subplayer)
	local otherMasks = data.OtherHealthMasks
	for i = #otherMasks, 1, -1 do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				if subplayer then
					local sdata = subplayer:GetData().CustomHealthAPISavedata
					table.insert(sdata.OtherHealthMasks[i], 1, health)
				end
				table.remove(mask, j)
			end
		end
	end
	
	-- convert containers to bones
	local boneMaskIndex = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].MaskIndex
	local boneContainingMask = otherMasks[boneMaskIndex]
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				if maxHpOfHealth <= 0 then
					if i < boneMaskIndex then
						table.remove(mask, j)
						table.insert(boneContainingMask, 1, {Key = "BONE_HEART", HP = 1, HalfCapacity = false})
					elseif i > boneMaskIndex then
						table.remove(mask, j)
						table.insert(boneContainingMask, {Key = "BONE_HEART", HP = 1, HalfCapacity = false})
					else
						mask[j] = {Key = "BONE_HEART", HP = 1, HalfCapacity = false}
					end
				end
			end
		end
	end
	
	-- restrict hearts of player
	CustomHealthAPI.Helper.RestrictBrokenHearts(player, 6)
	CustomHealthAPI.Helper.RestrictBoneHearts(player)
	CustomHealthAPI.Helper.RestrictRedHearts(player)
	
	if subplayer then
		-- restrict soul hearts of subplayer
		CustomHealthAPI.Helper.RestrictSoulHearts(subplayer)
	end
	
	-- refund a bone heart if necessary
	if CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", 1, true, false, true, true)
	end
	
	-- add soul charges as soul hearts
	if subplayer and soulCharges > 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(subplayer, "SOUL_HEART", soulCharges, true, false, true, true)
	end
	
	-- resync basegame hp
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	if subplayer then CustomHealthAPI.Helper.UpdateBasegameHealthState(subplayer) end
end

function CustomHealthAPI.Helper.HandleHealthOnConvertToTheSoul(player, soulCharges)
	-- remove all containers, refund soul if necessary, give all red hearts and bone hearts + 2 to subplayer (if they exist)
	local data = player:GetData().CustomHealthAPISavedata
	
	-- initialize subplayer and give red hearts to them
	local subplayer = player:GetSubPlayer()
	if subplayer then
		subplayer:GetData().CustomHealthAPISavedata = {}
		local sdata = subplayer:GetData().CustomHealthAPISavedata
		
		sdata.RedHealthMasks = data.RedHealthMasks
		
		local otherorder = CustomHealthAPI.Helper.GetOtherHealthOrder()
		sdata.OtherHealthMasks = {}
		for i = 1, #otherorder do
			sdata.OtherHealthMasks[i] = {}
		end
		
		sdata.Overlays = {}
		sdata.Overlays["ETERNAL_HEART"] = 0
		sdata.Overlays["GOLDEN_HEART"] = 0
		
		sdata.PlayerType = subplayer:GetPlayerType()
	end
	
	-- clear red hearts
	local redorder = CustomHealthAPI.Helper.GetRedHealthOrder()
	data.RedHealthMasks = {}
	for i = 1, #redorder do
		data.RedHealthMasks[i] = {}
	end
	
	-- give bone hearts to subplayer (or remove if no subplayer) and remove containers
	local otherMasks = data.OtherHealthMasks
	for i = #otherMasks, 1, -1 do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				if subplayer and CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP > 0 then
					local sdata = subplayer:GetData().CustomHealthAPISavedata
					table.insert(sdata.OtherHealthMasks[i], 1, health)
				end
				table.remove(mask, j)
			end
		end
	end
	
	-- restrict hearts of player
	CustomHealthAPI.Helper.RestrictBrokenHearts(player, 5)
	CustomHealthAPI.Helper.RestrictSoulHearts(player)
	
	if subplayer then
		-- restrict bone hearts of subplayer
		CustomHealthAPI.Helper.RestrictBoneHearts(subplayer)
		
		-- give subplayer 2 bone hearts
		CustomHealthAPI.Helper.UpdateHealthMasks(subplayer, "BONE_HEART", 2, true, false, true, true)
		
		-- restrict red hearts of subplayer
		CustomHealthAPI.Helper.RestrictRedHearts(subplayer)
	end
	
	-- add soul charges as soul hearts
	if soulCharges > 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", soulCharges, true, false, true, true)
	end
	
	-- refund a half soul heart if necessary
	if CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 1, true, false, true, true)
	end
	
	-- resync basegame hp
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	if subplayer then CustomHealthAPI.Helper.UpdateBasegameHealthState(subplayer) end
end

function CustomHealthAPI.Helper.HandleHealthOnConvertToBethany(player, soulCharges)
	-- convert soul hearts to soul charges, refund full container if necessary
	local data = player:GetData().CustomHealthAPISavedata
	
	-- clear current soul charge
	player:AddSoulCharge(-1 * player:GetSoulCharge())
	
	-- convert soul hearts to soul charges
	local otherMasks = data.OtherHealthMasks
	for i = #otherMasks, 1, -1 do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP") <= 1 then
					player:AddSoulCharge(2)
				else
					player:AddSoulCharge(health.HP)
				end
				
				table.remove(mask, j)
			end
		end
	end
	
	-- restrict hearts
	CustomHealthAPI.Helper.RestrictBrokenHearts(player, 12)
	CustomHealthAPI.Helper.RestrictBoneHearts(player)
	CustomHealthAPI.Helper.RestrictHeartContainers(player)
	CustomHealthAPI.Helper.RestrictRedHearts(player)
	
	-- refund a full heart container if necessary
	if CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", 2, true, false, true, true)
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", 2, true, false, true, true)
	end
	
	-- resync basegame hp
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
end

function CustomHealthAPI.Helper.HandleHealthOnConvertToJacobEsau(player, soulCharges)
	-- divide health between player and the othertwin
	local twin = player:GetOtherTwin()
	if twin then
		local rng = RNG()
		rng:SetSeed(twin.InitSeed, 5)
		
		local data = player:GetData().CustomHealthAPISavedata
		local redMasks = data.RedHealthMasks
		local otherMasks = data.OtherHealthMasks
		
		-- initialize other twin
		twin:GetData().CustomHealthAPISavedata = {}
		local tdata = twin:GetData().CustomHealthAPISavedata
		
		local redorder = CustomHealthAPI.Helper.GetRedHealthOrder()
		tdata.RedHealthMasks = {}
		for i = 1, #redorder do
			tdata.RedHealthMasks[i] = {}
		end
		local twinRedMasks = tdata.RedHealthMasks
		
		local otherorder = CustomHealthAPI.Helper.GetOtherHealthOrder()
		tdata.OtherHealthMasks = {}
		for i = 1, #otherorder do
			tdata.OtherHealthMasks[i] = {}
		end
		local twinOtherMasks = tdata.OtherHealthMasks
		
		tdata.Overlays = {}
		tdata.Overlays["ETERNAL_HEART"] = 0
		tdata.Overlays["GOLDEN_HEART"] = 0
		
		tdata.PlayerType = twin:GetPlayerType()
		
		-- duplicate broken hearts to other twin
		CustomHealthAPI.Helper.UpdateHealthMasks(twin, "BROKEN_HEART", 
		                                         CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART"), 
		                                         true, false, true, true)
		
		-- for each other mask
			-- give half of containers (starting with lowest priority) to other twin, if odd randomly decide who gets the remainder
			-- give half of souls (starting with lowest priority) to other twin, if odd randomly decide who gets the remainder
			-- give half of bones (starting with lowest priority) to other twin, if odd randomly decide who gets the remainder
		local remainingSoulToRemove = {}
		for i = #otherMasks, 1, -1 do
			local mask = otherMasks[i]
			
			local numContainers = 0
			local numSouls = 0
			local numBones = 0
			
			local heartsToTransfer = {}
			for j = #mask, 1, -1 do
				local health = mask[j]
				local typ = CustomHealthAPI.Library.GetInfoOfHealth(health, "Type")
				local maxHP = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				
				if typ == CustomHealthAPI.Enums.HealthTypes.SOUL then
					if health.HP < maxHP then
						numSouls = numSouls + 1
					else
						numSouls = numSouls + 2
					end
				else
					local kindContained = CustomHealthAPI.Library.GetInfoOfHealth(health, "KindContained")
					if kindContained == CustomHealthAPI.Enums.HealthKinds.NONE then
						-- do nothing
					elseif maxHP > 0 then
						numBones = numBones + 1
					else
						numContainers = numContainers + 1
					end
				end
				
				heartsToTransfer[j] = false
			end
			
			local containersToTransfer = numContainers / 2
			if rng:RandomFloat() > 0.5 then
				containersToTransfer = math.ceil(containersToTransfer)
			else
				containersToTransfer = math.floor(containersToTransfer)
			end
			
			local soulsToTransfer = numSouls / 2
			if rng:RandomFloat() > 0.5 then
				soulsToTransfer = math.ceil(soulsToTransfer)
			else
				soulsToTransfer = math.floor(soulsToTransfer)
			end
			
			local bonesToTransfer = numBones / 2
			if rng:RandomFloat() > 0.5 then
				bonesToTransfer = math.ceil(bonesToTransfer)
			else
				bonesToTransfer = math.floor(bonesToTransfer)
			end
			
			while containersToTransfer > 0 do
				local lowestPriorityHealth
				local lowestPriority
				local indexOfLowestPriority
				for j = #mask, 1, -1 do
					local health = mask[j]
					local typ = CustomHealthAPI.Library.GetInfoOfHealth(health, "Type")
					local maxHP = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
					local kindContained = CustomHealthAPI.Library.GetInfoOfHealth(health, "KindContained")
					
					if typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER and 
					   kindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
					   maxHP <= 0 and
					   not heartsToTransfer[j]
					then
						local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
						if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
							lowestPriorityHealth = health
							lowestPriority = removePriorityOfHealth
							indexOfLowestPriority = j
						end
					end
				end
				
				if indexOfLowestPriority ~= nil then
					heartsToTransfer[indexOfLowestPriority] = true
				end
				
				containersToTransfer = containersToTransfer - 1
			end
			
			while soulsToTransfer > 1 do
				local lowestPriorityHealth
				local lowestPriority
				local indexOfLowestPriority
				for j = #mask, 1, -1 do
					local health = mask[j]
					local typ = CustomHealthAPI.Library.GetInfoOfHealth(health, "Type")
					local maxHP = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
					
					if typ == CustomHealthAPI.Enums.HealthTypes.SOUL and 
					   not heartsToTransfer[j]
					then
						local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
						if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
							lowestPriorityHealth = health
							lowestPriority = removePriorityOfHealth
							indexOfLowestPriority = j
						end
					end
				end
				
				if indexOfLowestPriority ~= nil then
					heartsToTransfer[indexOfLowestPriority] = true
				
					if lowestPriorityHealth.HP < CustomHealthAPI.Library.GetInfoOfHealth(lowestPriorityHealth, "MaxHP") then
						soulsToTransfer = soulsToTransfer - 1
					else
						soulsToTransfer = soulsToTransfer - 2
					end
				else
					break
				end
			end
			
			while bonesToTransfer > 0 do
				local lowestPriorityHealth
				local lowestPriority
				local indexOfLowestPriority
				for j = #mask, 1, -1 do
					local health = mask[j]
					local typ = CustomHealthAPI.Library.GetInfoOfHealth(health, "Type")
					local maxHP = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
					
					if typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER and 
					   kindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
					   maxHP > 0 and
					   not heartsToTransfer[j]
					then
						local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
						if lowestPriorityHealth == nil or removePriorityOfHealth < lowestPriority then
							lowestPriorityHealth = health
							lowestPriority = removePriorityOfHealth
							indexOfLowestPriority = j
						end
					end
				end
				
				if indexOfLowestPriority ~= nil then
					heartsToTransfer[indexOfLowestPriority] = true
				end
				
				bonesToTransfer = bonesToTransfer - 1
			end
			
			for j = #mask, 1, -1 do
				if heartsToTransfer[j] then
					table.insert(twinOtherMasks[i], 1, mask[j])
					table.remove(mask, j)
				end
			end
			
			remainingSoulToRemove[i] = soulsToTransfer
		end
		
		for i = #otherMasks, 1, -1 do
			if remainingSoulToRemove[i] == 1 then
				local hpRemoved, keyRemoved = CustomHealthAPI.Helper.TryRemoveLowPrioritySoulFromMask(player, i, 1)
				if keyRemoved ~= nil and hpRemoved > 0 then
					CustomHealthAPI.Helper.UpdateHealthMasks(twin, keyRemoved, hpRemoved, true, false, true, true)
				end
			end
		end
		
		-- for each red mask
			-- give half of hearts (starting with lowest priority) to other twin, if odd randomly decide who gets the remainder
		local redHeartsToTransfer = CustomHealthAPI.Helper.GetTotalRedHP(player, true) / 2
		if rng:RandomFloat() > 0.5 then
			redHeartsToTransfer = math.ceil(redHeartsToTransfer)
		else
			redHeartsToTransfer = math.floor(redHeartsToTransfer)
		end
		
		while ((redHeartsToTransfer > 0 or CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) < 0) 
		       and CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(twin) > 0)
		do
			local lowestPriorityHealth
			local lowestPriority
			local maskIndexOfLowestPriority
			local indexOfLowestPriority
			
			local lowestPriorityHealthIgnoreMax
			local lowestPriorityIgnoreMax
			local maskIndexOfLowestPriorityIgnoreMax
			local indexOfLowestPriorityIgnoreMax
			
			for i = #redMasks, 1, -1 do
				local mask = redMasks[i]
				for j = #mask, 1, -1 do
					local health = mask[j]
					local maxHP = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP
					local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
					
					if (lowestPriorityHealth == nil or addPriorityOfHealth < lowestPriority) and 
					   not (maxHP <= 1 and redHeartsToTransfer <= 1 and CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) >= 0)
					then
						lowestPriorityHealth = health
						lowestPriority = addPriorityOfHealth
						maskIndexOfLowestPriority = i
						indexOfLowestPriority = j
					end
					
					if lowestPriorityHealthIgnoreMax == nil or addPriorityOfHealth < lowestPriorityIgnoreMax then
						lowestPriorityHealthIgnoreMax = health
						lowestPriorityIgnoreMax = addPriorityOfHealth
						maskIndexOfLowestPriorityIgnoreMax = i
						indexOfLowestPriorityIgnoreMax = j
					end
				end
			end
			
			if lowestPriorityHealth ~= nil then
				local maxHP = CustomHealthAPI.PersistentData.HealthDefinitions[lowestPriorityHealth.Key].MaxHP
				if redHeartsToTransfer > 1 or 
				   lowestPriorityHealth.HP < maxHP or 
				   maxHP <= 1 or 
				   CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) < 0 
				then
					table.insert(twinRedMasks[maskIndexOfLowestPriority], lowestPriorityHealth)
					table.remove(redMasks[maskIndexOfLowestPriority], indexOfLowestPriority)
					
					if lowestPriorityHealth.HP < maxHP then
						redHeartsToTransfer = redHeartsToTransfer - 1
					else
						redHeartsToTransfer = redHeartsToTransfer - 2
					end
				else
					lowestPriorityHealth.HP = lowestPriorityHealth.HP - 1
					CustomHealthAPI.Helper.UpdateHealthMasks(twin, lowestPriorityHealth.Key, 1, true, false, true, true)
					redHeartsToTransfer = redHeartsToTransfer - 1
				end
			elseif lowestPriorityHealthIgnoreMax ~= nil then
				local maxHP = CustomHealthAPI.PersistentData.HealthDefinitions[lowestPriorityHealthIgnoreMax.Key].MaxHP
				if redHeartsToTransfer > 1 or 
				   lowestPriorityHealthIgnoreMax.HP < maxHP or 
				   maxHP <= 1 or 
				   CustomHealthAPI.Helper.GetAmountUnoccupiedContainers(player) < 0 
				then
					table.insert(twinRedMasks[maskIndexOfLowestPriorityIgnoreMax], lowestPriorityHealthIgnoreMax)
					table.remove(redMasks[maskIndexOfLowestPriorityIgnoreMax], indexOfLowestPriorityIgnoreMax)
					
					if lowestPriorityHealthIgnoreMax.HP < maxHP then
						redHeartsToTransfer = redHeartsToTransfer - 1
					else
						redHeartsToTransfer = redHeartsToTransfer - 2
					end
				else
					lowestPriorityHealthIgnoreMax.HP = lowestPriorityHealthIgnoreMax.HP - 1
					CustomHealthAPI.Helper.UpdateHealthMasks(twin, lowestPriorityHealthIgnoreMax.Key, 1, true, false, true, true)
					redHeartsToTransfer = redHeartsToTransfer - 1
				end
			else
				break
			end
		end
		
		-- restrict hearts of player
		CustomHealthAPI.Helper.RestrictBrokenHearts(player, 12)
		CustomHealthAPI.Helper.RestrictBoneHearts(player)
		CustomHealthAPI.Helper.RestrictSoulHearts(player)
		CustomHealthAPI.Helper.RestrictHeartContainers(player)
		CustomHealthAPI.Helper.RestrictRedHearts(player)
		
		-- restrict hearts of twin
		CustomHealthAPI.Helper.RestrictBrokenHearts(twin, 12)
		CustomHealthAPI.Helper.RestrictBoneHearts(twin)
		CustomHealthAPI.Helper.RestrictSoulHearts(twin)
		CustomHealthAPI.Helper.RestrictHeartContainers(twin)
		CustomHealthAPI.Helper.RestrictRedHearts(twin)
		
		-- add soul charges as soul hearts
		if soulCharges > 0 then
			local soulChargesToSpend = soulCharges
			
			local playA = player
			local playB = twin
			if rng:RandomFloat() > 0.5 then
				playA = twin
				playB = player
			end
			
			while soulChargesToSpend > 0 do
				local hasSpent = false
				
				if CustomHealthAPI.Helper.GetHealableSoulHP(playA) + CustomHealthAPI.Helper.GetRoomForOtherKeys(playA) * 2 > 0 and 
				   soulChargesToSpend > 0
				then
					CustomHealthAPI.Helper.UpdateHealthMasks(playA, "SOUL_HEART", 1, true, false, true, true)
					soulChargesToSpend = soulChargesToSpend - 1
					hasSpent = true
				end
				
				if CustomHealthAPI.Helper.GetHealableSoulHP(playB) + CustomHealthAPI.Helper.GetRoomForOtherKeys(playB) * 2 > 0 and 
				   soulChargesToSpend > 0 
				then
					CustomHealthAPI.Helper.UpdateHealthMasks(playB, "SOUL_HEART", 1, true, false, true, true)
					soulChargesToSpend = soulChargesToSpend - 1
					hasSpent = true
				end
				
				if not hasSpent then
					break
				end
			end
		end
		
		-- refund a half soul heart to player if necessary
		if CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 1, true, false, true, true)
		end
		
		-- refund a half soul heart to twin if necessary
		if CustomHealthAPI.Helper.GetTotalHP(twin) == 0 then
			CustomHealthAPI.Helper.UpdateHealthMasks(twin, "SOUL_HEART", 1, true, false, true, true)
		end
		
		-- resync basegame hp
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(twin)
	else
		CustomHealthAPI.Helper.HandleHealthOnConvertToGeneric(player, soulCharges)
	end
end

function CustomHealthAPI.Helper.HandleHealthOnConvertToSoulHpPlayer(player, soulCharges)
	-- remove all containers and red, refund half a soul heart if necessary
	local data = player:GetData().CustomHealthAPISavedata
	
	-- clear red hearts
	local redMasks = data.RedHealthMasks
	for i = #redMasks, 1, -1 do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			table.remove(mask, j)
		end
	end
	
	-- remove all containers
	local otherMasks = data.OtherHealthMasks
	for i = #otherMasks, 1, -1 do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP <= 0 and
			   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				table.remove(mask, j)
			end
		end
	end
	
	-- restrict hearts
	CustomHealthAPI.Helper.RestrictBrokenHearts(player, 12)
	CustomHealthAPI.Helper.RestrictBoneHearts(player)
	CustomHealthAPI.Helper.RestrictSoulHearts(player)
	
	-- add soul charges as soul hearts
	if soulCharges > 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", soulCharges, true, false, true, true)
	end
	
	-- refund a half soul heart if necessary
	if CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 1, true, false, true, true)
	end
	
	-- resync basegame hp
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
end

function CustomHealthAPI.Helper.HandleHealthOnConvertToGeneric(player, soulCharges)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	-- restrict hearts
	CustomHealthAPI.Helper.RestrictBrokenHearts(player, 12)
	CustomHealthAPI.Helper.RestrictBoneHearts(player)
	CustomHealthAPI.Helper.RestrictSoulHearts(player)
	CustomHealthAPI.Helper.RestrictHeartContainers(player)
	CustomHealthAPI.Helper.RestrictRedHearts(player)
	
	-- add soul charges as soul hearts
	if soulCharges > 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", soulCharges, true, false, true, true)
	end
	
	-- refund a half soul heart if necessary
	if CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 1, true, false, true, true)
	end
	
	-- resync basegame hp
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	if subplayer then CustomHealthAPI.Helper.UpdateBasegameHealthState(subplayer) end
end

function CustomHealthAPI.Helper.HandleHealthOnConvertFromForgotten(player)
	local subplayer = player:GetSubPlayer()
	if subplayer then
		local data = player:GetData().CustomHealthAPISavedata
		local sdata = subplayer:GetData().CustomHealthAPISavedata
		local otherMasksOfPlayer = data.OtherHealthMasks
		local otherMasksOfSubplayer = sdata.OtherHealthMasks
		
		--append subplayer soul hp to end of player hp (broken hearts are ignored)
		for i = #otherMasksOfSubplayer, 1, -1 do
			local maskOfPlayer = otherMasksOfPlayer[i]
			local maskOfSubplayer = otherMasksOfSubplayer[i]
			
			local index = 1
			while index <= #maskOfSubplayer do
				local health = maskOfSubplayer[index]
				if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
					table.insert(maskOfPlayer, health)
					table.remove(maskOfSubplayer, index)
				else
					index = index + 1
				end
			end
		end
		
		--transfer over subplayer eternal and gold hp
		data.Overlays["ETERNAL_HEART"] = data.Overlays["ETERNAL_HEART"] + sdata.Overlays["ETERNAL_HEART"]
		data.Overlays["GOLDEN_HEART"] = data.Overlays["GOLDEN_HEART"] + sdata.Overlays["GOLDEN_HEART"]
		
		--delete subplayer hp
		subplayer:GetData().CustomHealthAPISavedata = nil
		
		--drain eternal/gold hp from subplayer
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(subplayer, -99)
		CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(subplayer, -99)
	end
end

function CustomHealthAPI.Helper.HandleHealthOnConvertFromTheSoul(player)
	local subplayer = player:GetSubPlayer()
	if subplayer then
		local data = player:GetData().CustomHealthAPISavedata
		local sdata = subplayer:GetData().CustomHealthAPISavedata
		local otherMasksOfPlayer = data.OtherHealthMasks
		local otherMasksOfSubplayer = sdata.OtherHealthMasks
		
		--append subplayer bone hp to end of player hp (broken hearts are ignored)
		for i = #otherMasksOfSubplayer, 1, -1 do
			local maskOfPlayer = otherMasksOfPlayer[i]
			local maskOfSubplayer = otherMasksOfSubplayer[i]
			
			local index = 1
			while index <= #maskOfSubplayer do
				local health = maskOfSubplayer[index]
				local typ = CustomHealthAPI.Library.GetInfoOfHealth(health, "Type")
				local maxHP = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				local kindContained = CustomHealthAPI.Library.GetInfoOfHealth(health, "KindContained")
				
				if typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER and 
				   kindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
				   maxHP > 0
				then
					table.insert(maskOfPlayer, health)
					table.remove(maskOfSubplayer, index)
				else
					index = index + 1
				end
			end
		end
		
		--transfer over subplayer red hp to player hp
		data.RedHealthMasks = sdata.RedHealthMasks
		
		--transfer over subplayer eternal and gold hp
		data.Overlays["ETERNAL_HEART"] = data.Overlays["ETERNAL_HEART"] + sdata.Overlays["ETERNAL_HEART"]
		data.Overlays["GOLDEN_HEART"] = data.Overlays["GOLDEN_HEART"] + sdata.Overlays["GOLDEN_HEART"]
		
		--delete subplayer hp
		subplayer:GetData().CustomHealthAPISavedata = nil
		
		--drain eternal/gold hp from subplayer
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(subplayer, -99)
		CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(subplayer, -99)
	end
end

function CustomHealthAPI.Helper.HandleHealthOnConvertFromTwin(player)
	local twin = player:GetOtherTwin()
	if twin then
		local data = player:GetData().CustomHealthAPISavedata
		
		local twintype = twin:GetPlayerType()
		if twintype == PlayerType.PLAYER_KEEPER or twintype == PlayerType.PLAYER_KEEPER_B then
			--add heart containers to player hp
			local otherMasksOfPlayer = data.OtherHealthMasks
			local emptyContainingMask = otherMasksOfPlayer[CustomHealthAPI.PersistentData.HealthDefinitions["EMPTY_HEART"].MaskIndex]
			
			local heartContainersToAdd = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(twin)
			while heartContainersToAdd > 0 do
				table.insert(emptyContainingMask, {Key = "EMPTY_HEART", HP = 0, HalfCapacity = false})
				heartContainersToAdd = heartContainersToAdd - 2
			end
			
			--add red hearts to player hp
			local redMasksOfPlayer = data.RedHealthMasks
			local redContainingMask = redMasksOfPlayer[CustomHealthAPI.PersistentData.HealthDefinitions["RED_HEART"].MaskIndex]
			
			local redHeartsToAdd = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(twin)
			redHeartsToAdd = CustomHealthAPI.Helper.HealRedAnywhere(player, redHeartsToAdd)
			while redHeartsToAdd > 0 do
				table.insert(redContainingMask, {Key = "RED_HEART", HP = math.min(redHeartsToAdd, 2)})
				redHeartsToAdd = redHeartsToAdd - 2
			end
			
			--add gold hearts to player hp
			local goldenHeartsToAdd = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(twin)
			data.Overlays["GOLDEN_HEART"] = data.Overlays["GOLDEN_HEART"] + goldenHeartsToAdd
		elseif twintype == PlayerType.PLAYER_THELOST or twintype == PlayerType.PLAYER_THELOST_B or twintype == PlayerType.PLAYER_THESOUL_B then
			--add a half soul heart to player hp
			local remainingSoul = CustomHealthAPI.Helper.HealSoulAnywhere(player, 1)
			if remainingSoul > 0 then
				local otherMasksOfPlayer = data.OtherHealthMasks
				local soulContainingMask = otherMasksOfPlayer[CustomHealthAPI.PersistentData.HealthDefinitions["SOUL_HEART"].MaskIndex]
				table.insert(soulContainingMask, {Key = "SOUL_HEART", HP = 1})
			end
		else
			local tdata = twin:GetData().CustomHealthAPISavedata
			local redMasksOfTwin = tdata.RedHealthMasks
			local otherMasksOfTwin = tdata.OtherHealthMasks
			
			--append twin other hp to end of player other hp
			for i = 1, #otherMasksOfTwin do
				local mask = otherMasksOfTwin[i]
				for j = 1, #mask do
					local health = mask[j]
					
					if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
						CustomHealthAPI.Helper.PlusSoulMain(player, health.Key, health.HP, true)
					else
						local maxHP = CustomHealthAPI.Library.GetInfoOfKey(health.Key, "MaxHP")
						local canHaveHalfCapacity = CustomHealthAPI.Library.GetInfoOfKey(health.Key, "CanHaveHalfCapacity")
						
						if maxHP >= 1 then
							CustomHealthAPI.Helper.PlusContainerMain(player, health.Key, maxHP, true)
						elseif canHaveHalfCapacity then
							CustomHealthAPI.Helper.PlusContainerMain(player, health.Key, 2, true)
						else
							CustomHealthAPI.Helper.PlusContainerMain(player, health.Key, 1, true)
						end
					end
				end
			end
			
			--append twin red hp to end of player red hp
			for i = 1, #redMasksOfTwin do
				local mask = redMasksOfTwin[i]
				for j = 1, #mask do
					local health = mask[j]
					CustomHealthAPI.Helper.PlusRedMain(player, health.Key, health.HP, true)
				end
			end
		
			--transfer over twin eternal and gold hp
			data.Overlays["ETERNAL_HEART"] = data.Overlays["ETERNAL_HEART"] + tdata.Overlays["ETERNAL_HEART"]
			data.Overlays["GOLDEN_HEART"] = data.Overlays["GOLDEN_HEART"] + tdata.Overlays["GOLDEN_HEART"]
		end
		
		--delete twin hp
		twin:GetData().CustomHealthAPISavedata = nil
		
		--drain eternal/gold hp from twin
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(twin, -99)
		CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(twin, -99)
	end
end

function CustomHealthAPI.Helper.HandleEternalHeartsPostChange(player, eternals)
	local data = player:GetData().CustomHealthAPISavedata
	data.Overlays["ETERNAL_HEART"] = eternals
	
	if data.Overlays["ETERNAL_HEART"] >= 2 then
		CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, 2) -- Play eternal heart animation
		
		local hpToAdd = data.Overlays["ETERNAL_HEART"] - (data.Overlays["ETERNAL_HEART"] % 2)
		if player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", hpToAdd)
		else
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", hpToAdd)
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", hpToAdd)
		end
		
		data.Overlays["ETERNAL_HEART"] = data.Overlays["ETERNAL_HEART"] % 2
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	end
end

function CustomHealthAPI.Helper.HandleGoldenHeartsPostChange(player, playertype, golds)
	if playertype == PlayerType.PLAYER_JACOB and player:GetOtherTwin() then
		-- give half of golden hearts to other twin, if odd randomly decide who gets the remainder, account for golden room
		local data = player:GetData().CustomHealthAPISavedata
		data.Overlays["GOLDEN_HEART"] = golds
		
		local twin = player:GetOtherTwin()
		local tdata = twin:GetData().CustomHealthAPISavedata
		
		local rng = RNG()
		rng:SetSeed(twin.InitSeed, 6)
		
		local goldToTransfer = golds / 2
		if rng:RandomFloat() > 0.5 then
			goldToTransfer = math.ceil(goldToTransfer)
		else
			goldToTransfer = math.floor(goldToTransfer)
		end
		
		while (goldToTransfer > 0 or CustomHealthAPI.Helper.GetNumOverlayableHearts(player) < data.Overlays["GOLDEN_HEART"]) and
		      CustomHealthAPI.Helper.GetNumOverlayableHearts(twin) > tdata.Overlays["GOLDEN_HEART"]
		do
			data.Overlays["GOLDEN_HEART"] = data.Overlays["GOLDEN_HEART"] - 1
			tdata.Overlays["GOLDEN_HEART"] = (tdata.Overlays["GOLDEN_HEART"] or 0) + 1
			goldToTransfer = goldToTransfer - 1
		end
		
		CustomHealthAPI.Helper.HandleGoldenRoom(player, true)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		
		CustomHealthAPI.Helper.HandleGoldenRoom(twin, true)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(twin)
	else
		local data = player:GetData().CustomHealthAPISavedata
		data.Overlays["GOLDEN_HEART"] = golds
		CustomHealthAPI.Helper.HandleGoldenRoom(player, true)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	end
end
