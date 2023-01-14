function CustomHealthAPI.Helper.InitializeRedHealthMasks(player)
	local total = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	local rotten = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
	local red = total - (rotten * 2)
	
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "ROTTEN_HEART", rotten, true, false, false, true, true)
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", red, true, false, false, true, true)
	
	--[[player:GetData().CustomHealthAPISavedata = player:GetData().CustomHealthAPISavedata or {}
	local data = player:GetData().CustomHealthAPISavedata
	
	local order = CustomHealthAPI.Helper.GetRedHealthOrder()
	data.RedHealthMasks = {}
	
	local isKeeper = CustomHealthAPI.Helper.PlayerIsKeeper(player)
	for i = 1, #order do
		local sort = order[i]
		data.RedHealthMasks[i] = {}

		for j = 1, #sort do
			if sort[j] == "RED_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) - CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player) * 2
				while numHearts > 0 do
					table.insert(data.RedHealthMasks[i], {Key = "RED_HEART", HP = (numHearts >= 2 and 2) or 1})
					numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
				end
			elseif sort[j] == "COIN_HEART" and isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
				while numHearts > 0 do
					table.insert(data.RedHealthMasks[i], {Key = "COIN_HEART", HP = (numHearts >= 2 and 2) or 1})
					numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
				end
			elseif sort[j] == "ROTTEN_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
				while numHearts > 0 do
					table.insert(data.RedHealthMasks[i], {Key = "ROTTEN_HEART", HP = 1})
					numHearts = numHearts - 1
				end
			end
		end
	end]]--
end

function CustomHealthAPI.Helper.InitializeOtherHealthMasks(player)
	local totalSoul = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
	local bone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
	
	local soulIndex = 0
	local soulSkippedIndices = 0
	while totalSoul > 0 or bone > 0 do
		if CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart(player, soulIndex) then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", 1)
			bone = bone - 1
			soulSkippedIndices = soulSkippedIndices + 1
		elseif CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart(player, (soulIndex - soulSkippedIndices) * 2 + 1) then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BLACK_HEART", math.min(2, totalSoul), false, false, true)
			totalSoul = totalSoul - 2
		else
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", math.min(2, totalSoul), false, false, true)
			totalSoul = totalSoul - 2
		end
		soulIndex = soulIndex + 1
	end
	
	local empty = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
	local broken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", math.ceil(empty / 2) * 2)
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "BROKEN_HEART", broken)
	
	--[[player:GetData().CustomHealthAPISavedata = player:GetData().CustomHealthAPISavedata or {}
	local data = player:GetData().CustomHealthAPISavedata
	
	local order = CustomHealthAPI.Helper.GetOtherHealthOrder()
	data.OtherHealthMasks = {}
	
	local isKeeper = CustomHealthAPI.Helper.PlayerIsKeeper(player)
	for i = 1, #order do
		local sort = order[i]
		data.OtherHealthMasks[i] = {}
		for j = 1, #sort do
			if sort[j] == "EMPTY_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
				while numHearts > 0 do
					table.insert(data.OtherHealthMasks[i], {Key = "EMPTY_HEART", HP = 0, HalfCapacity = false}) --numHearts == 1})
					numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
				end
			elseif sort[j] == "EMPTY_COIN_HEART" and isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
				while numHearts > 0 do
					table.insert(data.OtherHealthMasks[i], {Key = "EMPTY_COIN_HEART", HP = 0, HalfCapacity = false}) --numHearts == 1})
					numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
				end
			elseif sort[j] == "SOUL_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
				local soulIndex = 0
				local soulSkippedIndices = 0
				while numHearts > 0 do
					if not CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart(player, soulIndex) then
						if not CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart(player, (soulIndex - soulSkippedIndices) * 2 + 1) then
							data.OtherHealthMasks[i][soulIndex+1] = {Key = "SOUL_HEART", HP = (numHearts >= 2 and 2) or 1}
						end
						numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
					else
						soulSkippedIndices = soulSkippedIndices + 1
					end
					soulIndex = soulIndex + 1
				end
			elseif sort[j] == "BLACK_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
				local soulIndex = 0
				local soulSkippedIndices = 0
				while numHearts > 0 do
					if not CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart(player, soulIndex) then
						if CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart(player, (soulIndex - soulSkippedIndices) * 2 + 1) then
							data.OtherHealthMasks[i][soulIndex+1] = {Key = "BLACK_HEART", HP = (numHearts >= 2 and 2) or 1}
						end
						numHearts = numHearts - ((numHearts >= 2 and 2) or 1)
					else
						soulSkippedIndices = soulSkippedIndices + 1
					end
					soulIndex = soulIndex + 1
				end
			elseif sort[j] == "BONE_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
				local soulIndex = 0
				while numHearts > 0 do
					if CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart(player, soulIndex) then
						data.OtherHealthMasks[i][soulIndex+1] = {Key = "BONE_HEART", HP = 1, HalfCapacity = false}
						numHearts = numHearts - 1
					end
					soulIndex = soulIndex + 1
				end
			elseif sort[j] == "BROKEN_HEART" and not isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
				while numHearts > 0 do
					table.insert(data.OtherHealthMasks[i], {Key = "BROKEN_HEART", HP = 0, HalfCapacity = false})
					numHearts = numHearts - 1
				end
			elseif sort[j] == "BROKEN_COIN_HEART" and isKeeper then
				local numHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
				while numHearts > 0 do
					table.insert(data.OtherHealthMasks[i], {Key = "BROKEN_COIN_HEART", HP = 0, HalfCapacity = false})
					numHearts = numHearts - 1
				end
			end
		end
	end]]--
end

function CustomHealthAPI.Helper.InitializeOverlays(player)
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "ETERNAL_HEART", CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player))
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "GOLDEN_HEART", CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player))
end

function CustomHealthAPI.Helper.GetRedHealthMask(player, i)
	local data = player:GetData().CustomHealthAPISavedata
	return data.RedHealthMasks[i]
end

function CustomHealthAPI.Helper.GetOtherHealthMask(player, i)
	local data = player:GetData().CustomHealthAPISavedata
	return data.OtherHealthMasks[i]
end

function CustomHealthAPI.Helper.CheckIfPlayerRespawned(player)
	local revived = false
	
	local data = player:GetData().CustomHealthAPISavedata
	
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	local pdata = player:GetData().CustomHealthAPIPersistent
	
	if player:IsDead() then
		pdata.IsDead = true
	elseif pdata.IsDead then
		player:GetData().CustomHealthAPISavedata = nil
		if player:GetSubPlayer() ~= nil then
			player:GetSubPlayer():GetData().CustomHealthAPISavedata = nil
		end
		pdata.IsDead = nil
		revived = true
	end
	
	if player:GetSubPlayer() ~= nil then
		local subdata = player:GetSubPlayer():GetData().CustomHealthAPISavedata
		
		player:GetSubPlayer():GetData().CustomHealthAPIPersistent = player:GetSubPlayer():GetData().CustomHealthAPIPersistent or {}
		local subpdata = player:GetSubPlayer():GetData().CustomHealthAPIPersistent
		
		if player:GetSubPlayer():IsDead() then
			subpdata.IsDead = true
		elseif subpdata.IsDead then
			player:GetData().CustomHealthAPISavedata = nil
			player:GetSubPlayer():GetData().CustomHealthAPISavedata = nil
			subpdata.IsDead = nil
			revived = true
		end
	end
	
	return revived
end

function CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player, isSubPlayer)
	local revived = false
	if not isSubPlayer then
		revived = CustomHealthAPI.Helper.CheckIfPlayerRespawned(player)
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	
	local callCache = false
	local callSubCache = false
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		player:GetData().CustomHealthAPISavedata = nil
		
		if revived then
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_PLAYER_REVIVED)
			for _, callback in ipairs(callbacks) do
				callback.Function(player)
			end
		end
		
		local i = CustomHealthAPI.Helper.GetPlayerIndex(player)
		if CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i] ~= nil and player:GetData().CustomHealthAPIPersistent == nil then
			player:GetData().CustomHealthAPIPersistent = CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i]["Persist"]
			
			player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | 
								 CacheFlag.CACHE_FIREDELAY | 
								 CacheFlag.CACHE_SPEED | 
								 CacheFlag.CACHE_SHOTSPEED | 
								 CacheFlag.CACHE_RANGE | 
								 CacheFlag.CACHE_LUCK)
			
			player:EvaluateItems()
		end
		
		return
	elseif data == nil then
		local i = CustomHealthAPI.Helper.GetPlayerIndex(player)
		if CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i] ~= nil then
			player:GetData().CustomHealthAPISavedata = CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i]["Save"]
			player:GetData().CustomHealthAPIPersistent = CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i]["Persist"]
			data = player:GetData().CustomHealthAPISavedata
			
			callCache = true
		end
	end
	
	if player:GetSubPlayer() ~= nil and not isSubPlayer then
		local subdata = player:GetSubPlayer():GetData().CustomHealthAPISavedata
		if subdata == nil then
			local i = CustomHealthAPI.Helper.GetPlayerIndex(player)
			if CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup[i] ~= nil then
				player:GetSubPlayer():GetData().CustomHealthAPISavedata = CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup[i]["Save"]
				player:GetSubPlayer():GetData().CustomHealthAPIPersistent = CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup[i]["Persist"]
				CustomHealthAPI.Helper.CheckIfSwapSubPlayerInfo(player)
			
				callSubCache = true
			end
		end
	end
	
	local callCallbacks = false
	if data == nil then
		player:GetData().CustomHealthAPISavedata = {}
		data = player:GetData().CustomHealthAPISavedata
		
		local redorder = CustomHealthAPI.Helper.GetRedHealthOrder()
		data.RedHealthMasks = {}
		for i = 1, #redorder do
			data.RedHealthMasks[i] = {}
		end
		
		local otherorder = CustomHealthAPI.Helper.GetOtherHealthOrder()
		data.OtherHealthMasks = {}
		for i = 1, #otherorder do
			data.OtherHealthMasks[i] = {}
		end
		
		data.Overlays = {}
		data.Overlays["ETERNAL_HEART"] = 0
		data.Overlays["GOLDEN_HEART"] = 0
		
		CustomHealthAPI.Helper.InitializeOtherHealthMasks(player)
		CustomHealthAPI.Helper.InitializeRedHealthMasks(player)
		CustomHealthAPI.Helper.InitializeOverlays(player)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		
		data.PlayerType = player:GetPlayerType()
		
		callCallbacks = true
	end
	
	if player:GetSubPlayer() ~= nil and not isSubPlayer then
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player:GetSubPlayer(), true)
	end
	
	if callCallbacks then
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_PLAYER_INITIALIZE)
		for _, callback in ipairs(callbacks) do
			callback.Function(player, isSubPlayer)
		end
	end
	
	if revived then
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_PLAYER_REVIVED)
		for _, callback in ipairs(callbacks) do
			callback.Function(player)
		end
	end
	
	if callCache then
		player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | 
							 CacheFlag.CACHE_FIREDELAY | 
							 CacheFlag.CACHE_SPEED | 
							 CacheFlag.CACHE_SHOTSPEED | 
							 CacheFlag.CACHE_RANGE | 
							 CacheFlag.CACHE_LUCK)
		
		player:EvaluateItems()
	end
	
	if callSubCache then
		player:GetSubPlayer():AddCacheFlags(CacheFlag.CACHE_DAMAGE | 
							 CacheFlag.CACHE_FIREDELAY | 
							 CacheFlag.CACHE_SPEED | 
							 CacheFlag.CACHE_SHOTSPEED | 
							 CacheFlag.CACHE_RANGE | 
							 CacheFlag.CACHE_LUCK)
		
		player:GetSubPlayer():EvaluateItems()
	end
end

function CustomHealthAPI.Helper.CheckHealthIsInitialized()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	end
end
