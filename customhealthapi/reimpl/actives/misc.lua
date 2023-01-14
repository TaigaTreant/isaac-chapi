function CustomHealthAPI.Helper.AddGenesisAndGlowingHourglassOnNewRoomCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_NEW_ROOM, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.GenesisAndGlowingHourglassOnNewRoomCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddGenesisAndGlowingHourglassOnNewRoomCallback)

function CustomHealthAPI.Helper.RemoveGenesisAndGlowingHourglassOnNewRoomCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, CustomHealthAPI.Mod.GenesisAndGlowingHourglassOnNewRoomCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveGenesisAndGlowingHourglassOnNewRoomCallback)

function CustomHealthAPI.Mod:GenesisAndGlowingHourglassOnNewRoomCallback()
	if CustomHealthAPI.PersistentData.UsingGenesis then
		CustomHealthAPI.Helper.ClearHealthForGenesis()
	elseif CustomHealthAPI.PersistentData.UsingGlowingHourglass then
		CustomHealthAPI.Helper.LoadHealthForGlowingHourglass()
	else
		CustomHealthAPI.Helper.BackupHealthForGlowingHourglass()
	end
	
	CustomHealthAPI.PersistentData.UsingGlowingHourglass = false
	CustomHealthAPI.PersistentData.UsingGenesis = false
end

function CustomHealthAPI.Helper.AddUseItemCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_USE_ITEM, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.UseItemCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddUseItemCallback)

function CustomHealthAPI.Helper.RemoveUseItemCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_USE_ITEM, CustomHealthAPI.Mod.UseItemCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveUseItemCallback)

function CustomHealthAPI.Mod:UseItemCallback(collectible, rng, player, useflags)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Mod:UseItemCallback(collectible, rng, player:GetOtherTwin(), useflags)
		end
	end
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then 
		return
	end
	
	--local doubled = useflags & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY
	if collectible == CollectibleType.COLLECTIBLE_BOOK_OF_REVELATIONS then
		-- adds a soul heart
		local hp = 2
		--if doubled then 
		--	hp = hp * 2
		--end
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", hp)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif collectible == CollectibleType.COLLECTIBLE_CONVERTER then
		-- removes 1 soul heart; adds a heart container and heals a red heart
		if CustomHealthAPI.Helper.GetTotalSoulHP(player, true) >= 2 then
			local hp = 2
			--if doubled then 
			--	hp = hp * 2
			--end
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", -1 * hp)
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", hp)
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", hp)
		end
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif collectible == CollectibleType.COLLECTIBLE_GUPPYS_PAW then
		-- removes 1 non-bone container; adds 3 soul hearts
		if CustomHealthAPI.Helper.GetTotalMaxHP(player) >= 2 then
			--if doubled then
			--	CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", -4, false, true)
			--	CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 12)
			--else
				CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", -2, false, true)
				CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 6)
			--end
		end
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif collectible == CollectibleType.COLLECTIBLE_PRAYER_CARD then
		-- adds 1 eternal heart
		local hp = 1
		--if doubled then 
		--	hp = hp * 2
		--end
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "ETERNAL_HEART", hp)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif collectible == CollectibleType.COLLECTIBLE_SATANIC_BIBLE then
		-- adds 1 black heart
		local hp = 2
		--if doubled then 
		--	hp = hp * 2
		--end
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BLACK_HEART", hp)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif collectible == CollectibleType.COLLECTIBLE_THE_NAIL then
		-- adds 1/2 black heart
		local hp = 1
		--if doubled then 
		--	hp = hp * 2
		--end
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BLACK_HEART", hp)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif collectible == CollectibleType.COLLECTIBLE_YUM_HEART then
		-- heals 1 red heart for the user and 1/2 red heart for everyone else
		for i = 0, Game():GetNumPlayers() - 1 do
			local otherplayer = Isaac.GetPlayer(i)
			local hp = 1
			if otherplayer.Index == player.Index and otherplayer.InitSeed == player.InitSeed then
				hp = 2
			end
			--if doubled then 
			--	hp = hp * 2
			--end
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", hp)
			CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		end			
	elseif collectible == CollectibleType.COLLECTIBLE_POTATO_PEELER then
		-- removes 1 non-bone container
		if CustomHealthAPI.Helper.GetTotalMaxHP(player) >= 2 then
			local hp = -2
			--if doubled then 
			--	hp = hp * 2
			--end
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", hp, false, true)
		end
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif collectible == CollectibleType.COLLECTIBLE_MAGIC_SKIN then
		-- gives a broken heart in exchange for 1 container, or if no containers two souls
		if math.ceil(CustomHealthAPI.Helper.GetTotalMaxHP(player) / 2) + CustomHealthAPI.Helper.GetTotalBoneHP(player, true) > 0 then
			local hp = -2
			--if doubled then 
			--	hp = hp * 2
			--end
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", hp)
		else
			local hp = -4
			--if doubled then 
			--	hp = hp * 2
			--end
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", hp)
		end
		
		local hp = 1
		--if doubled then 
		--	hp = hp * 2
		--end
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BROKEN_HEART", hp)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif collectible == CollectibleType.COLLECTIBLE_YUCK_HEART then
		-- adds 1 rotten heart
		local hp = 2
		--if doubled then 
		--	hp = hp * 2
		--end
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "ROTTEN_HEART", hp)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	end
end

function CustomHealthAPI.Helper.AddPreUseItemCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.PreUseItemCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreUseItemCallback)

function CustomHealthAPI.Helper.RemovePreUseItemCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.PreUseItemCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreUseItemCallback)

function CustomHealthAPI.Mod:PreUseItemCallback(collectible, rng, player)
	if collectible == CollectibleType.COLLECTIBLE_BOOK_OF_REVELATIONS or
	   collectible == CollectibleType.COLLECTIBLE_CONVERTER or
	   collectible == CollectibleType.COLLECTIBLE_GUPPYS_PAW or
	   collectible == CollectibleType.COLLECTIBLE_PRAYER_CARD or
	   collectible == CollectibleType.COLLECTIBLE_SATANIC_BIBLE or
	   collectible == CollectibleType.COLLECTIBLE_THE_NAIL or
	   collectible == CollectibleType.COLLECTIBLE_YUM_HEART or
	   collectible == CollectibleType.COLLECTIBLE_POTATO_PEELER or
	   collectible == CollectibleType.COLLECTIBLE_MAGIC_SKIN or
	   collectible == CollectibleType.COLLECTIBLE_YUCK_HEART or
	   collectible == CollectibleType.COLLECTIBLE_BLANK_CARD or
	   collectible == CollectibleType.COLLECTIBLE_PLACEBO or
	   collectible == CollectibleType.COLLECTIBLE_CLEAR_RUNE or
	   collectible == CollectibleType.COLLECTIBLE_ABYSS or
	   collectible == CollectibleType.COLLECTIBLE_VOID
	then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	end
end
