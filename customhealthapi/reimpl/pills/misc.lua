-- Thanks Xalum for Horse Pill detection
-- nvm this broke in rep patch 1.7.9
--[[function CustomHealthAPI.Helper.IsPlayerUsingHorsePill(player, useflags)
	local pillColour = player:GetPill(0)

	local holdingHorsePill = pillColour & PillColor.PILL_GIANT_FLAG > 0
	local proccedByEchoChamber = useflags & (1 << 11) > 0 -- UseFlag.USE_NOHUD i hate basegame enums all my homies hate basegame enums

	return holdingHorsePill and not proccedByEchoChamber
end]]--

function CustomHealthAPI.Helper.IsPlayerUsingHorsePill(player, pillEffect, useflags)
	local proccedByEchoChamber = useflags & (1 << 11) > 0 -- UseFlag.USE_NOHUD i hate basegame enums all my homies hate basegame enums
	if proccedByEchoChamber then
		-- need to add actual support eventually
		return false
	end

	-- now we borrow from rep+ instead weeeee
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	local pillColor = player:GetData().CustomHealthAPIPersistent.CurrentlyHeldPill
	
	if pillColor and pillColor >= PillColor.PILL_GIANT_FLAG then
		local isHorsePillForThisEffect = (Game():GetItemPool():GetPillEffect(pillColor, player) == pillEffect)
		local isGoldHorsePill = (pillColor == PillColor.PILL_GOLD + PillColor.PILL_GIANT_FLAG)

		return isHorsePillForThisEffect or isGoldHorsePill
	end

	return false
end

function CustomHealthAPI.Helper.AddCurrentlyHeldPillCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PLAYER_UPDATE, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.CurrentlyHeldPillCallback)
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PEFFECT_UPDATE, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.CurrentlyHeldPillCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddCurrentlyHeldPillCallback)

function CustomHealthAPI.Helper.RemoveCurrentlyHeldPillCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, CustomHealthAPI.Mod.CurrentlyHeldPillCallback)
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, CustomHealthAPI.Mod.CurrentlyHeldPillCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveCurrentlyHeldPillCallback)

function CustomHealthAPI.Mod:CurrentlyHeldPillCallback(player)
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	player:GetData().CustomHealthAPIPersistent.CurrentlyHeldPill = player:GetPill(0)
end

function CustomHealthAPI.Helper.AddCurrentlyHeldPillForAllCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.CurrentlyHeldPillForAllCallback)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddCurrentlyHeldPillForAllCallback)

function CustomHealthAPI.Helper.RemoveCurrentlyHeldPillForAllCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.CurrentlyHeldPillForAllCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveCurrentlyHeldPillForAllCallback)

function CustomHealthAPI.Mod:CurrentlyHeldPillForAllCallback()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		CustomHealthAPI.Mod:CurrentlyHeldPillCallback(player)
	end
end

function CustomHealthAPI.Helper.AddUsePillCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_USE_PILL, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.UsePillCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddUsePillCallback)

function CustomHealthAPI.Helper.RemoveUsePillCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_USE_PILL, CustomHealthAPI.Mod.UsePillCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveUsePillCallback)

function CustomHealthAPI.Mod:UsePillCallback(pill, player, useflags)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Mod:UsePillCallback(pill, player:GetOtherTwin(), useflags)
		end
	end
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then 
		return
	end
	
	local doubled = CustomHealthAPI.Helper.IsPlayerUsingHorsePill(player, pill, useflags)
	if pill == PillEffect.PILLEFFECT_BALLS_OF_STEEL then
		-- adds two soul hearts
		local hp = 4
		if doubled then 
			hp = hp * 2
		end
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", hp)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif pill == PillEffect.PILLEFFECT_FULL_HEALTH then
		-- full heal
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", 99, true, false, false, true)
		if doubled then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 6)
		end
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif pill == PillEffect.PILLEFFECT_HEALTH_DOWN then
		-- removes a heart container
		-- adds a heart container
		if CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
			local hp = -1
			if doubled then 
				hp = hp * 2
			end
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", hp)
		else
			local hp = -2
			if doubled then 
				hp = hp * 2
			end
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", hp, false, true)
		end
		if CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
			if CustomHealthAPI.Helper.PlayerIsBethany(player) then
				CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", 2)
				CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", 1, false, false, false, true, true)
			elseif CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
				CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", 1)
			else
				local key = "SOUL_HEART"
				local hp = 1
				
				--[[local prevent = false
				local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_HORSE_HEALTH_DOWN_HEAL)
				for _, callback in ipairs(callbacks) do
					local newKey, newHP = callback.Function(player, key, hp)
					if newKey ~= nil or newHP ~= nil then
						key = newKey or key
						hp = newHP or hp
					end
				end]]--
				
				CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp)
			end
		end
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif pill == PillEffect.PILLEFFECT_HEALTH_UP then
		-- adds a heart container
		local hp = 2
		if doubled then 
			hp = hp * 2
		end
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", hp)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif pill == PillEffect.PILLEFFECT_HEMATEMESIS then
		-- sets red health to 1 red heart of the highest priority key
		CustomHealthAPI.Helper.HandleHematemesis(player)
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	elseif pill == PillEffect.PILLEFFECT_EXPERIMENTAL then
		-- not implemented; no way to discern what stats were changed
	end
end