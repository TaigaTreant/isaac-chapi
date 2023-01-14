function CustomHealthAPI.Helper.HandleTemporaryHP(player, datakey)
	local key = "EMPTY_HEART"
	
	if CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[player:GetPlayerType()] then
		key = CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[player:GetPlayerType()]
	elseif CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
		key = "BONE_HEART"
	else
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.GET_MAX_HP_CONVERSION)
		for _, callback in ipairs(callbacks) do
			local newKey = callback.Function(player, key)
			if newKey ~= nil then
				key = newKey
				break
			end
		end
	end
	
	local hp
	local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
	local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	if typ == CustomHealthAPI.Enums.HealthTypes.SOUL then
		if maxHP <= 1 then
			hp = 2
		else
			hp = maxHP
		end
	elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
		if maxHP <= 0 then
			if CustomHealthAPI.Library.GetInfoOfKey(key, "CanHaveHalfCapacity") == true then
				hp = 2
			else
				hp = 1
			end
		else
			hp = maxHP
		end
	end
	
	local hpBefore = CustomHealthAPI.Helper.GetTotalHPOfKey(player, key)
	if typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
	   maxHP <= 0 
	then
		hpBefore = CustomHealthAPI.Helper.GetTotalKeys(player, key)
		if CustomHealthAPI.Library.GetInfoOfKey(key, "CanHaveHalfCapacity") == true then
			hpBefore = hpBefore * 2
		end
	end
	
	CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp)
	if typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER and 
	   CustomHealthAPI.Library.GetInfoOfKey(key, "KindContained") ~= CustomHealthAPI.Enums.HealthKinds.NONE
	then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", 2)
	end
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	local hpAfter = CustomHealthAPI.Helper.GetTotalHPOfKey(player, key)
	if typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
	   maxHP <= 0 
	then
		hpAfter = CustomHealthAPI.Helper.GetTotalKeys(player, key)
		if CustomHealthAPI.Library.GetInfoOfKey(key, "CanHaveHalfCapacity") == true then
			hpAfter = hpAfter * 2
		end
	end
	
	player:GetData().CustomHealthAPISavedata[datakey] = player:GetData().CustomHealthAPISavedata[datakey] or {}
	table.insert(player:GetData().CustomHealthAPISavedata[datakey], {Key = key, HP = hpAfter - hpBefore})
end

function CustomHealthAPI.Helper.HandleStrength(player)
	CustomHealthAPI.Helper.HandleTemporaryHP(player, "StrengthHPToRemove")
end

function CustomHealthAPI.Helper.HandleReverseEmpress(player, doubled)
	CustomHealthAPI.Helper.HandleTemporaryHP(player, "ReverseEmpressHPToRemove")
	if not doubled then
		CustomHealthAPI.Helper.HandleTemporaryHP(player, "ReverseEmpressHPToRemove")
	end
end

function CustomHealthAPI.Helper.SubtractTemporaryHP(player, key, hpDiff)
	local strengthHP = player:GetData().CustomHealthAPISavedata.StrengthHPToRemove or {}
	local empressHP = player:GetData().CustomHealthAPISavedata.ReverseEmpressHPToRemove or {}
	
	local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
	local hpToRemove = math.abs(hpDiff)
	
	for i = #strengthHP, 1, -1 do
		local strengthKey = strengthHP[i].Key
		if typ == CustomHealthAPI.Enums.HealthTypes.SOUL then
			local hpRemoving = math.min(hpToRemove, strengthHP[i].HP)
			strengthHP[i].HP = strengthHP[i].HP - hpRemoving
			hpToRemove = hpToRemove - hpRemoving
			if strengthHP[i].HP == 0 then
				table.remove(strengthHP, i)
			end
		elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
			local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
			local strengthMaxHP = CustomHealthAPI.Library.GetInfoOfKey(strengthKey, "MaxHP")
			if (maxHP <= 0) == (strengthMaxHP <= 0) then
				local canHaveHalfCapacity = CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity
				
				local hpPer
				if maxHP >= 1 then
					hpPer = maxHP
				elseif canHaveHalfCapacity then
					hpPer = 2
				else
					hpPer = 1
				end
					
				table.remove(strengthHP, i)
				hpToRemove = hpToRemove - hpPer
			end
		end
		
		if hpToRemove <= 0 then
			break
		end
	end
	
	for i = #empressHP, 1, -1 do
		local empressKey = empressHP[i].Key
		if typ == CustomHealthAPI.Enums.HealthTypes.SOUL then
			local hpRemoving = math.min(hpToRemove, empressHP[i].HP)
			empressHP[i].HP = empressHP[i].HP - hpRemoving
			hpToRemove = hpToRemove - hpRemoving
			if empressHP[i].HP == 0 then
				table.remove(empressHP, i)
			end
		elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
			local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
			local empressMaxHP = CustomHealthAPI.Library.GetInfoOfKey(empressKey, "MaxHP")
			if (maxHP <= 0) == (empressMaxHP <= 0) then
				local canHaveHalfCapacity = CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity
				
				local hpPer
				if maxHP >= 1 then
					hpPer = maxHP
				elseif canHaveHalfCapacity then
					hpPer = 2
				else
					hpPer = 1
				end
					
				table.remove(empressHP, i)
				hpToRemove = hpToRemove - hpPer
			end
		end
		
		if hpToRemove <= 0 then
			break
		end
	end
end

function CustomHealthAPI.Helper.RemoveTemporaryHP(player, datakey)
	local strengthHP = player:GetData().CustomHealthAPISavedata[datakey]
	
	for i = 1, #strengthHP do
		local key = strengthHP[i].Key
		
		local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
		local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
	
		local hpPer
		local hpRemainingOfKey
		local hpRemainingOtherwise
		if typ == CustomHealthAPI.Enums.HealthTypes.SOUL then
			hpPer = maxHP
			hpRemainingOfKey = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
			hpRemainingOtherwise = CustomHealthAPI.Helper.GetTotalRedHP(player, true) + CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
		elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
			local canHaveHalfCapacity = CustomHealthAPI.PersistentData.HealthDefinitions[key].CanHaveHalfCapacity
			
			if maxHP >= 1 then
				hpPer = maxHP
				hpRemainingOfKey = CustomHealthAPI.Helper.GetTotalBoneHP(player, true) * 2
				hpRemainingOtherwise = CustomHealthAPI.Helper.GetTotalSoulHP(player, true) + 
				                       math.min(CustomHealthAPI.Helper.GetTotalRedHP(player, true), CustomHealthAPI.Helper.GetTotalMaxHP(player))
			elseif canHaveHalfCapacity then
				hpPer = 2
				hpRemainingOfKey = CustomHealthAPI.Helper.GetTotalMaxHP(player)
				hpRemainingOtherwise = CustomHealthAPI.Helper.GetTotalSoulHP(player, true) + CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
			else
				hpPer = 1
				hpRemainingOfKey = CustomHealthAPI.Helper.GetTotalMaxHP(player)
				hpRemainingOtherwise = CustomHealthAPI.Helper.GetTotalSoulHP(player, true) + CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
			end
		end
		
		if hpRemainingOfKey <= 2 and hpRemainingOtherwise == 0 then
			--do nothing
		else
			CustomHealthAPI.Library.AddHealth(player, key, hpPer * -1, false, false, false, true)
		end
	end
	
	player:GetData().CustomHealthAPISavedata[datakey] = nil
end

function CustomHealthAPI.Helper.AddHandleStrengthOnNewRoomCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_NEW_ROOM, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.HandleStrengthOnNewRoomCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHandleStrengthOnNewRoomCallback)

function CustomHealthAPI.Helper.RemoveHandleStrengthOnNewRoomCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, CustomHealthAPI.Mod.HandleStrengthOnNewRoomCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHandleStrengthOnNewRoomCallback)

function CustomHealthAPI.Mod:HandleStrengthOnNewRoomCallback()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		
		if player:GetData().CustomHealthAPISavedata and 
		   #(player:GetData().CustomHealthAPISavedata.StrengthHPToRemove or {}) > 0 and
		   not player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM)
		then
			CustomHealthAPI.Helper.RemoveTemporaryHP(player, "StrengthHPToRemove")
		end
		
		if player:GetSubPlayer() and player:GetSubPlayer():GetData().CustomHealthAPISavedata and 
		   #(player:GetSubPlayer():GetData().CustomHealthAPISavedata.StrengthHPToRemove or {}) > 0 and
		   not player:GetSubPlayer():GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM)
		then
			CustomHealthAPI.Helper.RemoveTemporaryHP(player:GetSubPlayer(), "StrengthHPToRemove")
		end
		
		if player:GetOtherTwin() and player:GetOtherTwin():GetData().CustomHealthAPISavedata and 
		   #(player:GetOtherTwin():GetData().CustomHealthAPISavedata.StrengthHPToRemove or {}) > 0 and
		   not player:GetOtherTwin():GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM)
		then
			CustomHealthAPI.Helper.RemoveTemporaryHP(player:GetOtherTwin(), "StrengthHPToRemove")
		end
	end
end

function CustomHealthAPI.Helper.HandleReverseEmpressOnRemove(player)
	if player:GetData().CustomHealthAPISavedata and 
	   #(player:GetData().CustomHealthAPISavedata.ReverseEmpressHPToRemove or {}) > 0 and
	   not player:GetEffects():HasNullEffect(NullItemID.ID_REVERSE_EMPRESS)
	then
		CustomHealthAPI.Helper.RemoveTemporaryHP(player, "ReverseEmpressHPToRemove")
	end
	
	if player:GetSubPlayer() and player:GetSubPlayer():GetData().CustomHealthAPISavedata and 
	   #(player:GetSubPlayer():GetData().CustomHealthAPISavedata.ReverseEmpressHPToRemove or {}) > 0 and
	   not player:GetSubPlayer():GetEffects():HasNullEffect(NullItemID.ID_REVERSE_EMPRESS)
	then
		CustomHealthAPI.Helper.RemoveTemporaryHP(player:GetSubPlayer(), "ReverseEmpressHPToRemove")
	end
	
	if player:GetOtherTwin() and player:GetOtherTwin():GetData().CustomHealthAPISavedata and 
	   #(player:GetOtherTwin():GetData().CustomHealthAPISavedata.ReverseEmpressHPToRemove or {}) > 0 and
	   not player:GetOtherTwin():GetEffects():HasNullEffect(NullItemID.ID_REVERSE_EMPRESS)
	then
		CustomHealthAPI.Helper.RemoveTemporaryHP(player:GetOtherTwin(), "ReverseEmpressHPToRemove")
	end
end
