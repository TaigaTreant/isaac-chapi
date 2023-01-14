function CustomHealthAPI.Helper.HandleReverseFool(player)
	local room = Game():GetRoom()
	
	local hearts = Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART)
	
	local redHearts = {}
	local halfRedHearts = {}
	local doubleRedHearts = {}
	local rottenHearts = {}
	local soulHearts = {}
	local halfSoulHearts = {}
	local blackHearts = {}
	local boneHearts = {}
	
	for _, heart in ipairs(hearts) do
		if heart.FrameCount == 0 and
		   heart.SpawnerEntity and
		   heart.SpawnerEntity.Index == player.Index and
		   heart.SpawnerEntity.InitSeed == player.InitSeed
		then
			if heart.SubType == HeartSubType.HEART_FULL then
				table.insert(redHearts, heart)
			elseif heart.SubType == HeartSubType.HEART_HALF then
				table.insert(halfRedHearts, heart)
			elseif heart.SubType == HeartSubType.HEART_DOUBLEPACK then
				table.insert(doubleRedHearts, heart)
			elseif heart.SubType == HeartSubType.HEART_ROTTEN then
				table.insert(rottenHearts, heart)
			elseif heart.SubType == HeartSubType.HEART_SOUL then
				table.insert(soulHearts, heart)
			elseif heart.SubType == HeartSubType.HEART_HALF_SOUL then
				table.insert(halfSoulHearts, heart)
			elseif heart.SubType == HeartSubType.HEART_BLACK then
				table.insert(blackHearts, heart)
			elseif heart.SubType == HeartSubType.HEART_BONE then
				table.insert(boneHearts, heart)
			end
		end
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	local redTotals = {}
	local highestPriorityRedKey
	for i = #redMasks, 1, -1 do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
			
			redTotals[health.Key] = (redTotals[health.Key] or 0) + health.HP
			if highestPriorityRedKey == nil or 
			   addPriorityOfHealth > CustomHealthAPI.PersistentData.HealthDefinitions[highestPriorityRedKey].AddPriority 
			then
				highestPriorityRedKey = health.Key
			end
			
			table.remove(mask, j)
		end
	end
	
	local soulTotals = {}
	local boneTotals = {}
	local hasMax = false
	local highestPrioritySoulKey
	local highestPriorityBoneKey
	for i = #otherMasks, 1, -1 do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				soulTotals[health.Key] = (soulTotals[health.Key] or 0) + health.HP
				
				local addPriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].AddPriority
				if highestPrioritySoulKey == nil or 
				   addPriorityOfHealth > CustomHealthAPI.PersistentData.HealthDefinitions[highestPrioritySoulKey].AddPriority
				then
					highestPrioritySoulKey = health.Key
				end
				
				table.remove(mask, j)
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			       CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				if CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP <= 0 then
					hasMax = true
				else
					boneTotals[health.Key] = (boneTotals[health.Key] or 0) + 1
					
					local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
					if highestPriorityBoneKey == nil or 
					   removePriorityOfHealth > CustomHealthAPI.PersistentData.HealthDefinitions[highestPriorityBoneKey].RemovePriority
					then
						highestPriorityBoneKey = health.Key
					end
					
					table.remove(mask, j)
				end
			end
		end
	end
	
	if hasMax and highestPriorityRedKey ~= nil then
		if CustomHealthAPI.Library.GetInfoOfKey(highestPriorityRedKey, "MaxHP") <= 1 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, highestPriorityRedKey, 2, true, false, true, true, true)
		else
			CustomHealthAPI.Helper.UpdateHealthMasks(player, highestPriorityRedKey, 1, true, false, true, true, true)
		end
		redTotals[highestPriorityRedKey] = redTotals[highestPriorityRedKey] - 1
	elseif highestPriorityBoneKey ~= nil then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, highestPriorityBoneKey, 1, true, false, true, true, true)
		boneTotals[highestPriorityBoneKey] = boneTotals[highestPriorityBoneKey] - 1
	elseif highestPrioritySoulKey ~= nil then
		if CustomHealthAPI.Library.GetInfoOfKey(highestPrioritySoulKey, "MaxHP") <= 1 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, highestPrioritySoulKey, 2, true, false, true, true, true)
		else
			CustomHealthAPI.Helper.UpdateHealthMasks(player, highestPrioritySoulKey, 1, true, false, true, true, true)
		end
		soulTotals[highestPrioritySoulKey] = soulTotals[highestPrioritySoulKey] - 1
	end
	
	data.Overlays["ETERNAL_HEART"] = 0
	data.Overlays["GOLDEN_HEART"] = 0
	
	if redTotals["RED_HEART"] ~= nil then
		while redTotals["RED_HEART"] > 0 do
			if redTotals["RED_HEART"] >= 4 then
				if #doubleRedHearts > 0 then
					table.remove(doubleRedHearts)
				else
					Isaac.Spawn(EntityType.ENTITY_PICKUP, 
					            PickupVariant.PICKUP_HEART, 
					            HeartSubType.HEART_DOUBLEPACK, 
					            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
					            Vector.Zero, 
					            player)
				end
				redTotals["RED_HEART"] = redTotals["RED_HEART"] - 4
			elseif redTotals["RED_HEART"] >= 2 then
				if #redHearts > 0 then
					table.remove(redHearts)
				else
					Isaac.Spawn(EntityType.ENTITY_PICKUP, 
					            PickupVariant.PICKUP_HEART, 
					            HeartSubType.HEART_FULL, 
					            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
					            Vector.Zero, 
					            player)
				end
				redTotals["RED_HEART"] = redTotals["RED_HEART"] - 2
			elseif redTotals["RED_HEART"] >= 1 then
				if #halfRedHearts > 0 then
					table.remove(halfRedHearts)
				else
					Isaac.Spawn(EntityType.ENTITY_PICKUP, 
					            PickupVariant.PICKUP_HEART,  
					            HeartSubType.HEART_HALF, 
					            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
					            Vector.Zero, 
					            player)
				end
				redTotals["RED_HEART"] = redTotals["RED_HEART"] - 1
			end
		end
		redTotals["RED_HEART"] = nil
	end
	
	if redTotals["ROTTEN_HEART"] ~= nil then
		while redTotals["ROTTEN_HEART"] > 0 do
			if redTotals["ROTTEN_HEART"] >= 1 then
				if #rottenHearts > 0 then
					table.remove(rottenHearts)
				else
					Isaac.Spawn(EntityType.ENTITY_PICKUP, 
					            PickupVariant.PICKUP_HEART, 
					            HeartSubType.HEART_ROTTEN, 
					            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
					            Vector.Zero, 
					            player)
				end
				redTotals["ROTTEN_HEART"] = redTotals["ROTTEN_HEART"] - 1
			end
		end
		redTotals["ROTTEN_HEART"] = nil
	end
	
	if soulTotals["SOUL_HEART"] ~= nil then
		while soulTotals["SOUL_HEART"] > 0 do
			if soulTotals["SOUL_HEART"] >= 2 then
				if #soulHearts > 0 then
					table.remove(soulHearts)
				else
					Isaac.Spawn(EntityType.ENTITY_PICKUP, 
					            PickupVariant.PICKUP_HEART, 
					            HeartSubType.HEART_SOUL, 
					            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
					            Vector.Zero, 
					            player)
				end
				soulTotals["SOUL_HEART"] = soulTotals["SOUL_HEART"] - 2
			elseif soulTotals["SOUL_HEART"] >= 1 then
				if #halfSoulHearts > 0 then
					table.remove(halfSoulHearts)
				else
					Isaac.Spawn(EntityType.ENTITY_PICKUP, 
					            PickupVariant.PICKUP_HEART, 
					            HeartSubType.HEART_HALF_SOUL, 
					            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
					            Vector.Zero, 
					            player)
				end
				soulTotals["SOUL_HEART"] = soulTotals["SOUL_HEART"] - 1
			end
		end
		soulTotals["SOUL_HEART"] = nil
	end
	
	if soulTotals["BLACK_HEART"] ~= nil then
		while soulTotals["BLACK_HEART"] > 0 do
			if soulTotals["BLACK_HEART"] >= 2 then
				if #blackHearts > 0 then
					table.remove(blackHearts)
				else
					Isaac.Spawn(EntityType.ENTITY_PICKUP, 
					            PickupVariant.PICKUP_HEART, 
					            HeartSubType.HEART_BLACK, 
					            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
					            Vector.Zero, 
					            player)
				end
				soulTotals["BLACK_HEART"] = soulTotals["BLACK_HEART"] - 2
			elseif soulTotals["BLACK_HEART"] >= 1 then
				if #halfSoulHearts > 0 then
					table.remove(halfSoulHearts)
				else
					Isaac.Spawn(EntityType.ENTITY_PICKUP, 
					            PickupVariant.PICKUP_HEART, 
					            HeartSubType.HEART_HALF_SOUL, 
					            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
					            Vector.Zero, 
					            player)
				end
				soulTotals["BLACK_HEART"] = soulTotals["BLACK_HEART"] - 1
			end
		end
		soulTotals["BLACK_HEART"] = nil
	end
	
	if boneTotals["BONE_HEART"] ~= nil then
		while boneTotals["BONE_HEART"] > 0 do
			if #boneHearts > 0 then
				table.remove(boneHearts)
			else
				Isaac.Spawn(EntityType.ENTITY_PICKUP, 
				            PickupVariant.PICKUP_HEART, 
				            HeartSubType.HEART_BONE, 
				            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
				            Vector.Zero, 
				            player)
			end
			boneTotals["BONE_HEART"] = boneTotals["BONE_HEART"] - 1
		end
		boneTotals["BONE_HEART"] = nil
	end
	
	-- get rid of leftovers
	for i = 1, #redHearts do
		redHearts[i]:Remove()
	end
	for i = 1, #halfRedHearts do
		halfRedHearts[i]:Remove()
	end
	for i = 1, #doubleRedHearts do
		doubleRedHearts[i]:Remove()
	end
	for i = 1, #rottenHearts do
		rottenHearts[i]:Remove()
	end
	for i = 1, #soulHearts do
		soulHearts[i]:Remove()
	end
	for i = 1, #halfSoulHearts do
		halfSoulHearts[i]:Remove()
	end
	for i = 1, #blackHearts do
		blackHearts[i]:Remove()
	end
	for i = 1, #boneHearts do
		boneHearts[i]:Remove()
	end
	
	for key, hp in pairs(redTotals) do
		local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
		local pickups = CustomHealthAPI.PersistentData.HealthDefinitions[key].PickupEntities
		
		local hpToSpawn = hp
		while hpToSpawn > 0 do
			for i = maxHP, 1, -1 do
				if hpToSpawn >= i then
					for j = i, 1, -1 do
						if pickups[j] ~= nil then
							Isaac.Spawn(pickups[j].ID, 
							            pickups[j].Var, 
							            pickups[j].Sub, 
							            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
							            Vector.Zero, 
							            player)
							break
						end
					end
					
					hpToSpawn = hpToSpawn - i
					break
				end
			end
		end
	end
	
	for key, hp in pairs(soulTotals) do
		local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
		local pickups = CustomHealthAPI.PersistentData.HealthDefinitions[key].PickupEntities
		
		local hpToSpawn = hp
		while hpToSpawn > 0 do
			for i = maxHP, 1, -1 do
				if hpToSpawn >= i then
					for j = i, 1, -1 do
						if pickups[j] ~= nil then
							Isaac.Spawn(pickups[j].ID, 
							            pickups[j].Var, 
							            pickups[j].Sub, 
							            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
							            Vector.Zero, 
							            player)
							break
						end
					end
					
					hpToSpawn = hpToSpawn - i
					break
				end
			end
		end
	end
	
	for key, hp in pairs(boneTotals) do
		local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
		local pickups = CustomHealthAPI.PersistentData.HealthDefinitions[key].PickupEntities
		
		local hpToSpawn = hp
		while hpToSpawn > 0 do
			for i = maxHP, 1, -1 do
				if pickups[i] ~= nil then
					Isaac.Spawn(pickups[i].ID, 
					            pickups[i].Var, 
					            pickups[i].Sub, 
					            room:FindFreePickupSpawnPosition(player.Position, 40, true), 
					            Vector.Zero, 
					            player)
					break
				end
			end
			
			hpToSpawn = hpToSpawn - 1
		end
	end
end
