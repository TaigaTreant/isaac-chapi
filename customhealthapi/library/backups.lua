local json = require("json")

function CustomHealthAPI.Library.GetHealthBackup(p)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	
	local savetable = {}
	savetable.Mainplayers = {}
	savetable.Subplayers = {}
	
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local subplayer = player:GetSubPlayer()
		if p == nil or (player.Index == p.Index and player.InitSeed == p.InitSeed) then
			CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
			if not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
				CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
				CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
			end
			savetable.Mainplayers[CustomHealthAPI.Helper.GetPlayerIndex(player)] = {Save = player:GetData().CustomHealthAPISavedata, Persist = player:GetData().CustomHealthAPIPersistent}
			if p ~= nil then break end
		end
		if subplayer ~= nil and (p == nil or (subplayer.Index == p.Index and subplayer.InitSeed == p.InitSeed)) then
			CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(subplayer)
			if not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
				CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(subplayer)
				CustomHealthAPI.Helper.ResyncHealthOfPlayer(subplayer)
			end
			savetable.Subplayers[CustomHealthAPI.Helper.GetPlayerIndex(player)] = {Save = subplayer:GetData().CustomHealthAPISavedata, Persist = subplayer:GetData().CustomHealthAPIPersistent}
			if p ~= nil then break end
		end
	end
	
	if p == nil then
		savetable.Hidden = CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup
		savetable.HiddenSub = CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup
		savetable.RestockInfo = CustomHealthAPI.PersistentData.RestockInfo
	end
	
	local backup = json.encode(savetable)
	return backup
end

function CustomHealthAPI.Library.LoadHealthFromBackup(backup)
	if backup == nil then
		return
	end

	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	
	local savetable = json.decode(backup)
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local healthData = savetable.Mainplayers[CustomHealthAPI.Helper.GetPlayerIndex(player)]
		if healthData ~= nil then
			CustomHealthAPI.Helper.LoadHealthOfPlayerFromBackup(player, healthData)
		end
		
		local subplayer = player:GetSubPlayer()
		if subplayer ~= nil then
			local subHealthData = savetable.Subplayers[CustomHealthAPI.Helper.GetPlayerIndex(player)]
			if subHealthData ~= nil then
				CustomHealthAPI.Helper.LoadHealthOfPlayerFromBackup(subplayer, subHealthData)
			end
		end
	end
	
	CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup = savetable.Hidden or CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup
	CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup = savetable.HiddenSub or CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup
	CustomHealthAPI.PersistentData.RestockInfo = savetable.RestockInfo or CustomHealthAPI.PersistentData.RestockInfo
end

function CustomHealthAPI.Helper.LoadHealthOfPlayerFromBackup(player, healthData)
	player:GetData().CustomHealthAPISavedata = healthData["Save"]
	player:GetData().CustomHealthAPIPersistent = healthData["Persist"]
	
	if not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
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
		
		CustomHealthAPI.Helper.ClearBasegameHealth(player)
		
		for i = 2, 0, -1 do
			if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
				player:SetActiveCharge(24, i)
			end
		end
		
		local maxHearts = CustomHealthAPI.Helper.GetTotalMaxHP(player)
		local brokenHearts = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
		
		CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, maxHearts)
		CustomHealthAPI.Helper.AddBasegameBrokenHealthWithoutModifiers(player, brokenHearts)
		
		local otherMasks = player:GetData().CustomHealthAPISavedata.OtherHealthMasks
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
					CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, 1)
				elseif key == "BLACK_HEART" then
					CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, (atMax and 2) or 1)
				elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL and
					   key ~= "BLACK_HEART"
				then
					CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, (atMax and 2) or 1)
				end
			end
		end
		
		local expectedTotal = CustomHealthAPI.Helper.GetTotalRedHP(player, true)
		local expectedRotten = CustomHealthAPI.Helper.GetTotalHPOfKey(player, "ROTTEN_HEART")
		
		CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, expectedRotten * 2)
		CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, expectedTotal - expectedRotten * 2)
		
		CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, player:GetData().CustomHealthAPISavedata.Overlays["GOLDEN_HEART"])
		CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, player:GetData().CustomHealthAPISavedata.Overlays["ETERNAL_HEART"])
		
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
	
	player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | 
	                     CacheFlag.CACHE_FIREDELAY | 
	                     CacheFlag.CACHE_SPEED | 
	                     CacheFlag.CACHE_SHOTSPEED | 
	                     CacheFlag.CACHE_RANGE | 
	                     CacheFlag.CACHE_LUCK)
	
	player:EvaluateItems()
end
