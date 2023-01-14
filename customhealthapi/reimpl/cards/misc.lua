function CustomHealthAPI.Helper.AddUseCardCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_USE_CARD, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.UseCardCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddUseCardCallback)

function CustomHealthAPI.Helper.RemoveUseCardCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_USE_CARD, CustomHealthAPI.Mod.UseCardCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveUseCardCallback)

function CustomHealthAPI.Mod:UseCardCallback(card, player, useflags)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Mod:UseCardCallback(card, player:GetOtherTwin(), useflags)
		end
	end
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then 
		return
	end
	
	local doubled = useflags & UseFlag.USE_CARBATTERY == UseFlag.USE_CARBATTERY
	if card == Card.CARD_STRENGTH then
		-- adds a heart container and heals a red heart
		CustomHealthAPI.Helper.HandleStrength(player)
	elseif card == Card.CARD_SUN then
		-- full heal
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", 99, true, false, false, true)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif card == Card.CARD_HEARTS_2 then
		-- adds red hp equal to the basegame amount
		local hp = CustomHealthAPI.Helper.GetTotalRedHP(player, true)
		--if doubled then 
		--	hp = hp * 2
		--end
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", hp)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif card == Card.RUNE_DAGAZ then
		-- adds a soul heart
		local hp = 2
		--if doubled then 
		--	hp = hp * 2
		--end
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", hp)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif card == Card.RUNE_SHARD then
		-- not implemented; no way to discern which effect triggered
	elseif card == Card.CARD_REVERSE_FOOL then
		-- convert spawned hearts as necessary
		if not doubled then
			CustomHealthAPI.Helper.HandleReverseFool(player)
			CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		end
	elseif card == Card.CARD_REVERSE_EMPRESS then
		-- adds two heart containers and heals 2 red hearts
		CustomHealthAPI.Helper.HandleReverseEmpress(player, doubled)
	elseif card == Card.CARD_REVERSE_SUN then
		-- converts all containers to bone hearts (in place, if possible, so earlier keys at front, later keys at back)
		CustomHealthAPI.Helper.HandleReverseSun(player)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif card == Card.CARD_REVERSE_LOVERS then
		-- gives a broken heart in exchange for 1 container, or if no containers two souls
		
		-- why does tarot cloth not actually trigger this twice unlike literally every other card
		local times = 1
		if player:HasCollectible(CollectibleType.COLLECTIBLE_TAROT_CLOTH) then
			times = 2
		end
		
		for i = 1, times do
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
		end
	end
end