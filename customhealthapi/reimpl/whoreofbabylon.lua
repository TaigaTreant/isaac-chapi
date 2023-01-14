function CustomHealthAPI.Helper.AddWhoreOfBabylonPrevention(player)
	if player:HasCollectible(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON) and 
	   not player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON) 
	then
		player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON, false)
		return true
	end
	return false
end

function CustomHealthAPI.Helper.AddBloodyBabylonPrevention(player)
	if player:GetPlayerType() == PlayerType.PLAYER_EVE_B and 
	   not player:GetEffects():HasNullEffect(NullItemID.ID_BLOODY_BABYLON) 
	then
		player:GetEffects():AddNullEffect(NullItemID.ID_BLOODY_BABYLON, false)
		return true
	end
	return false
end

function CustomHealthAPI.Helper.RemoveWhoreOfBabylonPrevention(player)
	player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON)
	
	-- Force game to recheck
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible(player, 
	                                                                  CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON, 
	                                                                  0, 
	                                                                  true, 
	                                                                  ActiveSlot.SLOT_PRIMARY, 
	                                                                  0)
	player:RemoveCollectible(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON)
end

function CustomHealthAPI.Helper.PlayerHasClots(player)
	local clots = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY)
	for _, c in ipairs(clots) do
		local clot = c:ToFamiliar()
		
		if clot.SubType ~= 7 and clot.Player and clot.Player.Index == player.Index and clot.Player.InitSeed == player.InitSeed then
			return true
		end
	end
	return false
end

function CustomHealthAPI.Helper.RemoveBloodyBabylonPrevention(player)
	player:GetEffects():RemoveNullEffect(NullItemID.ID_BLOODY_BABYLON)
	
	local currentRedHP = math.max(CustomHealthAPI.Helper.GetTotalRedHP(player, true), CustomHealthAPI.Helper.GetTotalRedHP(player, false))
	local currentSoulHP = math.max(CustomHealthAPI.Helper.GetTotalSoulHP(player, true), CustomHealthAPI.Helper.GetTotalSoulHP(player, false))
	local currentBoneHP = math.max(CustomHealthAPI.Helper.GetTotalBoneHP(player, true), CustomHealthAPI.Helper.GetTotalBoneHP(player, false))
	local currentEternalHP = player:GetData().CustomHealthAPISavedata.Overlays["ETERNAL_HEART"]
	local currentGoldenHP = player:GetData().CustomHealthAPISavedata.Overlays["GOLDEN_HEART"]
	
	local currentHP = currentRedHP + currentSoulHP + currentBoneHP + currentEternalHP + currentGoldenHP
	
	if currentHP == 1 and 
	   not (player:GetData().CustomHealthAPIOtherData and player:GetData().CustomHealthAPIOtherData.SpawningSumptorium) and
	   not CustomHealthAPI.Helper.PlayerHasClots(player) 
	then
		local wobNum = player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON)
		player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON, wobNum)
		
		-- Force game to play giantbook
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible(player, 
		                                                                  CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON, 
		                                                                  0, 
		                                                                  true, 
		                                                                  ActiveSlot.SLOT_PRIMARY, 
		                                                                  0)
		player:RemoveCollectible(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON)
		
		player:GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON, 
		                                            player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON))
		player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON, true, wobNum)
	end
end
