local heartsDamaged = {}

function CustomHealthAPI.Helper.AddProcessTakeDamageCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_ENTITY_TAKE_DMG, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.ProcessTakeDamageCallback, EntityType.ENTITY_PLAYER)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddProcessTakeDamageCallback)

function CustomHealthAPI.Helper.RemoveProcessTakeDamageCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CustomHealthAPI.Mod.ProcessTakeDamageCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveProcessTakeDamageCallback)

function CustomHealthAPI.Helper.IsDebugThreeActive()
	local s = Isaac.ExecuteCommand("debug 3")
	Isaac.ExecuteCommand("debug 3")
	
	return s == "Disabled debug flag."
end

function CustomHealthAPI.Mod:ProcessTakeDamageCallback(ent, amount, flags, source, countdown)
	if ent.Type ~= EntityType.ENTITY_PLAYER then
		return
	end
	
	if CustomHealthAPI.Helper.IsDebugThreeActive() then
		return
	end
	
	local player = ent:ToPlayer()
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_PLAYER_DAMAGE)
	for _, callback in ipairs(callbacks) do
		local prevent = callback.Function(player, amount, flags, source, countdown)
		if prevent ~= nil then
			return false
		end
	end
	
	if not player or
	   CustomHealthAPI.Helper.PlayerIsIgnored(player) or
	   math.floor(amount + 0.5) < 1.0 or
	   player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_ASTRAL_PROJECTION) == 1 or
	   player:IsCoopGhost() or
	   CustomHealthAPI.Helper.GetTotalHP(player) <= 0
	then
		return
	end
	
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	
	if player:GetPlayerType() == PlayerType.PLAYER_JACOB2_B or
	   player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE)
	then
		CustomHealthAPI.Helper.EmptyAllHealth(player)
		return
	elseif source.Entity and source.Entity.Type == EntityType.ENTITY_DARK_ESAU then
		return
	end
	
	player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
	player:GetData().CustomHealthAPIOtherData.InDamageCallback = Isaac.GetFrameCount()
	
	if flags & DamageFlag.DAMAGE_RED_HEARTS ~= DamageFlag.DAMAGE_RED_HEARTS and 
	   flags & DamageFlag.DAMAGE_NO_PENALTIES ~= DamageFlag.DAMAGE_NO_PENALTIES
	then
		for i = 2, 0, -1 do
			if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_GLASS_CANNON then
				player:RemoveCollectible(CollectibleType.COLLECTIBLE_GLASS_CANNON, true, i, true)
				CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible(player, 
				                                                                  CollectibleType.COLLECTIBLE_BROKEN_GLASS_CANNON, 
				                                                                  0, 
				                                                                  false, 
				                                                                  i, 
				                                                                  0)
				player:GetData().CustomHealthAPISavedata.GlassCannonBroke = true
			end
		end
	end
	
	if flags & DamageFlag.DAMAGE_FAKE ~= DamageFlag.DAMAGE_FAKE then	
		local isBloodOath = source.Entity and 
		                    source.Entity.Type == EntityType.ENTITY_FAMILIAR and 
		                    source.Entity.Variant == FamiliarVariant.BLOOD_OATH
		
		if isBloodOath then
			CustomHealthAPI.Helper.HandleBloodOath(player, amount, flags, source, countdown)

			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_PLAYER_DAMAGE)
			for _, callback in ipairs(callbacks) do
				callback.Function(player, amount, flags, source, countdown)
			end
			
			player:GetData().CustomHealthAPIOtherData.InDamageCallback = nil
			return false
		else
			local didDamage = CustomHealthAPI.Helper.HandleDamage(player, amount, flags, source, countdown)
			
			player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
			player:GetData().CustomHealthAPISavedata.HandlingDamageCanShackle = not (player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_SOUL) or 
																					 player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED))
			player:GetData().CustomHealthAPISavedata.HandlingDamage = true
			player:GetData().CustomHealthAPISavedata.HandlingDamageAmount = amount
			player:GetData().CustomHealthAPISavedata.HandlingDamageFlags = flags
			player:GetData().CustomHealthAPISavedata.HandlingDamageSource = source
			player:GetData().CustomHealthAPISavedata.HandlingDamageCountdown = countdown
			
			player:GetData().CustomHealthAPIOtherData.InDamageCallback = nil
			return
		end
	end
	
	player:GetData().CustomHealthAPIOtherData.InDamageCallback = nil
end

function CustomHealthAPI.Helper.AddPreventTakeDamageCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_ENTITY_TAKE_DMG, -1 * math.huge, CustomHealthAPI.Mod.PreventTakeDamageCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreventTakeDamageCallback)

function CustomHealthAPI.Helper.RemovePreventTakeDamageCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CustomHealthAPI.Mod.PreventTakeDamageCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreventTakeDamageCallback)

function CustomHealthAPI.Mod:PreventTakeDamageCallback(ent, amount, flags, source, countdown)
	if ent:GetData().CHAPIBloodOathDamageCallback then
		if ent:GetData().CHAPIBloodOathDamageCallback ~= nil and Game():GetFrameCount() ~= ent:GetData().CHAPIBloodOathDamageCallback then
			print("Custom Health API ERROR: Blood Oath damage callback failed.")
			ent:GetData().CHAPIDamageCallback = nil
			ent:GetData().CHAPIBloodOathDamageCallback = nil
		else
			return true
		end
	end
end

function CustomHealthAPI.Helper.FinishDamageDesync(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.FinishDamageDesync(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	if data and not data.HandlingDamage then
		return false
	end
	
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
	
	local newMax = CustomHealthAPI.Helper.GetTotalMaxHP(player)
	local newBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
	
	CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, newMax)
	CustomHealthAPI.Helper.AddBasegameBrokenHealthWithoutModifiers(player, newBroken)
	
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
	
	player:ClearEntityFlags(EntityFlag.FLAG_BLEED_OUT)
	
	local amount = data.HandlingDamageAmount
	local flags = data.HandlingDamageFlags
	local source = data.HandlingDamageSource
	local countdown = data.HandlingDamageCountdown
	local canShackle = data.HandlingDamageCanShackle
	
	data.HandlingDamage = nil
	data.HandlingDamageAmount = nil
	data.HandlingDamageFlags = nil
	data.HandlingDamageSource = nil
	data.HandlingDamageCountdown = nil
	data.HandlingDamageCanShackle = nil
	
	if flags & DamageFlag.DAMAGE_NOKILL == DamageFlag.DAMAGE_NOKILL and CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
		local playerType = player:GetPlayerType()
		local key, hp
		if CustomHealthAPI.Helper.GetTotalMaxHP(player) > 0 then
			key = "RED_HEART"
			hp = 1
		elseif CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
			key = "BONE_HEART"
			hp = 1
		elseif playerType ~= PlayerType.PLAYER_KEEPER and playerType ~= PlayerType.PLAYER_KEEPER_B and playerType ~= PlayerType.PLAYER_BETHANY then
			key = "SOUL_HEART"
			hp = 1
		end
		
		if key ~= nil then
			local prevent = false
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_NOKILL_HEAL)
			for _, callback in ipairs(callbacks) do
				local newKey, newHP = callback.Function(player, key, hp)
				if newKey == false then
					prevent = true
					break
				elseif newKey ~= nil or newHP ~= nil then
					key = newKey or key
					hp = newHP or hp
				end
			end
			
			if not prevent then
				CustomHealthAPI.Library.AddHealth(player, key, hp, true, false, false, false, false, true, true)
			end
		end
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_HEARTBREAK) and CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
		CustomHealthAPI.Library.AddHealth(player, "BROKEN_HEART", 2)
		
		local limit = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) / 2)
		if limit > 0 then
			local playerType = player:GetPlayerType()
			local key, hp
			if CustomHealthAPI.Helper.GetTotalMaxHP(player) > 0 then
				key = "RED_HEART"
				hp = 1
			elseif CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
				key = "BONE_HEART"
				hp = 1
			elseif playerType ~= PlayerType.PLAYER_KEEPER and playerType ~= PlayerType.PLAYER_KEEPER_B and playerType ~= PlayerType.PLAYER_BETHANY then
				key = "SOUL_HEART"
				hp = 1
			end
		
			if key ~= nil then
				local prevent = false
				local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_HEARTBREAK_HEAL)
				for _, callback in ipairs(callbacks) do
					local newKey, newHP = callback.Function(player, key, hp)
					if newKey == false then
						prevent = true
						break
					elseif newKey ~= nil or newHP ~= nil then
						key = newKey or key
						hp = newHP or hp
					end
				end
				
				if not prevent then
					CustomHealthAPI.Library.AddHealth(player, key, hp, true, false, false, false, false, true, true)
				end
			end
		end
	end
	
	if canShackle and player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_SOUL) then
		local playerType = player:GetPlayerType()
		local postBrokenHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		local limit = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) + postBrokenHearts * 2
		
		if postBrokenHearts * 2 >= limit then
			if CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player) >= 1 then
				CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 1, false, false, true, false)
			end
		else
			local key, hp
			if CustomHealthAPI.Helper.GetTotalMaxHP(player) > 0 then
				key = "RED_HEART"
				hp = 1
			elseif CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
				key = "BONE_HEART"
				hp = 1
			elseif playerType ~= PlayerType.PLAYER_KEEPER and playerType ~= PlayerType.PLAYER_KEEPER_B and playerType ~= PlayerType.PLAYER_BETHANY then
				key = "SOUL_HEART"
				hp = 1
			end
		
			if key ~= nil then
				local prevent = false
				local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_SPIRIT_SHACKLES_HEAL)
				for _, callback in ipairs(callbacks) do
					local newKey, newHP = callback.Function(player, key, hp)
					if newKey == false then
						prevent = true
						break
					elseif newKey ~= nil or newHP ~= nil then
						key = newKey or key
						hp = newHP or hp
					end
				end
				
				if not prevent then
					CustomHealthAPI.Library.AddHealth(player, key, hp, true, false, false, false, false, true, true)
				end
			end
		end
		
		player:GetData().CustomHealthAPIOtherData.ShacklesDisabled = true
	end
	
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
	
	local remainingRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, true)
	local remainingSoulHP = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_SCAPULAR) and remainingRedHP + remainingSoulHP == 1 then
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		local otherdata = player:GetData().CustomHealthAPIOtherData
		
		if not otherdata.ActivatedScapular and flags & DamageFlag.DAMAGE_RED_HEARTS ~= DamageFlag.DAMAGE_RED_HEARTS then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 2)
			CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
			otherdata.ActivatedScapular = true
		end
	end
	
	if player:HasTrinket(TrinketType.TRINKET_FINGER_BONE) and not player:IsDead() then
		local fingerRNG = player:GetTrinketRNG(TrinketType.TRINKET_FINGER_BONE)
		if fingerRNG:RandomFloat() <= 0.04 then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", 1)
			CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		end
	end
	
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_PLAYER_DAMAGE)
	for _, callback in ipairs(callbacks) do
		callback.Function(player, amount, flags, source, countdown)
	end
	
	CustomHealthAPI.Helper.HandleGlassCannonOnBreaking(player)
	
	if player:GetExtraLives() > 0 then
		CustomHealthAPI.PersistentData.DoHUDPostUpdateForLivesHUD = Isaac.GetFrameCount()
	end
	
	return true
end

function CustomHealthAPI.Helper.HandleGlassCannonOnBreaking(player)
	if player:GetData().CustomHealthAPISavedata.GlassCannonBroke then
		player:GetData().CustomHealthAPISavedata.GlassCannonBroke = nil
		
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.IMPACT, 0, player.Position, Vector.Zero, nil):Update()
		for i = 1, 8 do
			local randvec = Vector.FromAngle(math.random() * 360):Resized(1.0 + math.random() * 3.0)
			local glassshard = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, 0, player.Position, randvec, nil):ToEffect()
			glassshard.m_Height = glassshard.FallingSpeed
		end
		SFXManager():Play(SoundEffect.SOUND_GLASS_BREAK)
		player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_ANEMIC, true)
		
		if CustomHealthAPI.Helper.GetTotalHP(player) > 0 then
			local glassFlags = DamageFlag.DAMAGE_NOKILL | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_ISSAC_HEART | DamageFlag.DAMAGE_NO_MODIFIERS
			player:ResetDamageCooldown() -- WHY IS DAMAGE_INVINCIBLE NOT WORKING
			player:TakeDamage(2, glassFlags, EntityRef(player), 30)
			CustomHealthAPI.Helper.FinishDamageDesync(player)
			player:ResetDamageCooldown() -- WHY IS DAMAGE_INVINCIBLE NOT WORKING
			player:TakeDamage(2, glassFlags, EntityRef(player), 30)
			CustomHealthAPI.Helper.FinishDamageDesync(player)
			
			local data = player:GetData().CustomHealthAPISavedata
			local redMasks = data.RedHealthMasks
			local otherMasks = data.OtherHealthMasks
			
			if CustomHealthAPI.Helper.GetTotalHP(player) <= 0 then
				local playerType = player:GetPlayerType()
				local key, hp
				if CustomHealthAPI.Helper.GetTotalMaxHP(player) > 0 then
					key = "RED_HEART"
					hp = 1
				elseif CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
					key = "BONE_HEART"
					hp = 1
				elseif playerType ~= PlayerType.PLAYER_KEEPER and playerType ~= PlayerType.PLAYER_KEEPER_B and playerType ~= PlayerType.PLAYER_BETHANY then
					key = "SOUL_HEART"
					hp = 1
				end
			
				if key ~= nil then
					local prevent = false
					local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_GLASS_CANNON_HEAL)
					for _, callback in ipairs(callbacks) do
						local newKey, newHP = callback.Function(player, key, hp)
						if newKey == false then
							prevent = true
							break
						elseif newKey ~= nil or newHP ~= nil then
							key = newKey or key
							hp = newHP or hp
						end
					end
					
					if not prevent then
						CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true, true)
						CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
					end
				end
			end
		end
	end
end

function CustomHealthAPI.Helper.AddHandleScapularOnNewRoomCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_NEW_ROOM, CustomHealthAPI.Mod.HandleScapularOnNewRoomCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHandleScapularOnNewRoomCallback)

function CustomHealthAPI.Helper.RemoveHandleScapularOnNewRoomCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, CustomHealthAPI.Mod.HandleScapularOnNewRoomCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHandleScapularOnNewRoomCallback)

function CustomHealthAPI.Mod:HandleScapularOnNewRoomCallback()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		player:GetData().CustomHealthAPIOtherData.ActivatedScapular = nil
	end
end

function CustomHealthAPI.Helper.AddHandleDebugThreeCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_EXECUTE_CMD, CustomHealthAPI.Mod.HandleDebugThreeCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHandleDebugThreeCallback)

function CustomHealthAPI.Helper.RemoveHandleDebugThreeCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_EXECUTE_CMD, CustomHealthAPI.Mod.HandleDebugThreeCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHandleDebugThreeCallback)

function CustomHealthAPI.Mod:HandleDebugThreeCallback(cmd, params)
	if cmd == "chapi" then
		if params:find("nodmg") then
			print(Isaac.ExecuteCommand("debug 3"))
		end
	end
end

function CustomHealthAPI.Helper.HandleDamageDesyncOld(player, amount, flags, source, countdown, damageFunc, compensationFunc, isBloodOath)
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
	
	local maxHearts = CustomHealthAPI.Helper.GetTotalMaxHP(player)
	local brokenHearts = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
	
	if isBloodOath then
		player:GetData().CHAPIBloodOathDamageCallback = Game():GetFrameCount()
	else
		player:GetData().CHAPIDamageCallback = Game():GetFrameCount()
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
				
	compensationFunc(player, amount, flags, source, countdown)
	
	player:GetEffects():AddNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED, true, shacklesDisabled)
	
	damageFunc(player, amount, flags, source, countdown)
	
	player:GetData().CHAPIDamageCallback = nil
	player:GetData().CHAPIBloodOathDamageCallback = nil
	
	local shacklesDisabled = player:GetEffects():GetNullEffectNum(NullItemID.ID_SPIRIT_SHACKLES_DISABLED)
	player:GetEffects():RemoveNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED, shacklesDisabled)
	
	local postBrokenHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	local limit = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) + postBrokenHearts * 2
	
	if postBrokenHearts * 2 < limit then
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
	end
	
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
	
	player:ClearEntityFlags(EntityFlag.FLAG_BLEED_OUT)
	if CustomHealthAPI.Helper.GetTotalRedHP(player, true) > 0 and CustomHealthAPI.Helper.GetTotalHP(player) > 1 and player:HasCollectible(CollectibleType.COLLECTIBLE_SHARD_OF_GLASS) then
		player:GetData().CustomHealthAPISavedata.ShardBleedTimer = 1200
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		player:GetData().CustomHealthAPIOtherData.LastBleedTick = Game():GetFrameCount()
	else
		player:GetData().CustomHealthAPISavedata.ShardBleedTimer = nil
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		player:GetData().CustomHealthAPIOtherData.BleedSpriteFrame = nil
	end
end

function CustomHealthAPI.Helper.HandleDamageDesync(player, compensationFunc)
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
				
	compensationFunc(player)
	
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
	
	player:ClearEntityFlags(EntityFlag.FLAG_BLEED_OUT)
	if CustomHealthAPI.Helper.GetTotalRedHP(player, true) > 0 and CustomHealthAPI.Helper.GetTotalHP(player) > 1 and player:HasCollectible(CollectibleType.COLLECTIBLE_SHARD_OF_GLASS) then
		player:GetData().CustomHealthAPISavedata.ShardBleedTimer = 1200
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		player:GetData().CustomHealthAPIOtherData.LastBleedTick = Game():GetFrameCount()
	else
		player:GetData().CustomHealthAPISavedata.ShardBleedTimer = nil
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		player:GetData().CustomHealthAPIOtherData.BleedSpriteFrame = nil
	end
end

function CustomHealthAPI.Helper.HandleRedEternalDamage(player, flags, heartsBroken)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	
	if data.Overlays["ETERNAL_HEART"] > 0 and
	   (flags & DamageFlag.DAMAGE_RED_HEARTS ~= DamageFlag.DAMAGE_RED_HEARTS or
	    CustomHealthAPI.Helper.GetTotalHP(player) == 0)
	then
		local key = "RED_HEART"
		local hp = 1
		
		local prevent = false
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_ETERNAL_HEAL)
		for _, callback in ipairs(callbacks) do
			local newKey, newHP = callback.Function(player, key, hp)
			if newKey == false then
				prevent = true
				break
			elseif newKey ~= nil or newHP ~= nil then
				key = newKey or key
				hp = newHP or hp
			end
		end
				
		if not prevent then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true, true)
			
			heartsBroken["ETERNAL_HEART"] = (heartsBroken["ETERNAL_HEART"] or 0) + 1 
			data.Overlays["ETERNAL_HEART"] = 0
			
			return true
		end
	end
	
	return false
end

function CustomHealthAPI.Helper.HandleSoulEternalDamage(player, heartsBroken)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	if data.Overlays["ETERNAL_HEART"] > 0 and CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
		local key = "SOUL_HEART"
		local hp = 1
		
		local prevent = false
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_ETERNAL_HEAL)
		for _, callback in ipairs(callbacks) do
			local newKey, newHP = callback.Function(player, key, hp)
			if newKey == false then
				prevent = true
				break
			elseif newKey ~= nil or newHP ~= nil then
				key = newKey or key
				hp = newHP or hp
			end
		end
				
		if not prevent then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true, true)
			
			heartsBroken["ETERNAL_HEART"] = (heartsBroken["ETERNAL_HEART"] or 0) + 1 
			data.Overlays["ETERNAL_HEART"] = 0
			
			return true
		end
	end
	
	return false
end

function CustomHealthAPI.Helper.HandleBoneEternalDamage(player, heartsBroken, keyBroken)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	if data.Overlays["ETERNAL_HEART"] > 0 and CustomHealthAPI.Helper.GetTotalHP(player) == 0 then
		local key = keyBroken
		local hp = 1
		
		local prevent = false
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_ETERNAL_HEAL)
		for _, callback in ipairs(callbacks) do
			local newKey, newHP = callback.Function(player, key, hp)
			if newKey == false then
				prevent = true
				break
			elseif newKey ~= nil or newHP ~= nil then
				key = newKey or key
				hp = newHP or hp
			end
		end
				
		if not prevent then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true, true)
			
			heartsBroken["ETERNAL_HEART"] = (heartsBroken["ETERNAL_HEART"] or 0) + 1 
			data.Overlays["ETERNAL_HEART"] = 0
			
			return true
		end
	end
	
	return false
end

function CustomHealthAPI.Helper.HandleGoldDamage(player, heartsBroken, isGold, inNormalContainer)
	local data = player:GetData().CustomHealthAPISavedata
	
	if isGold and (inNormalContainer == nil or inNormalContainer == true) then 
		heartsBroken["GOLDEN_HEART"] = (heartsBroken["GOLDEN_HEART"] or 0) + 1 
		data.Overlays["GOLDEN_HEART"] = math.max(0, data.Overlays["GOLDEN_HEART"] - 1)
	end
end

function CustomHealthAPI.Helper.GetHealthOrder(player)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	local redOrder = {}
	local index = 1
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			table.insert(redOrder, {i, j, index})
			index = index + 1
		end
	end
		
	local healthOrder = {}
	local redIndex = 1
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				table.insert(healthOrder, {Red = redOrder[redIndex], Other = {i, j}})
				redIndex = redIndex + 1
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				table.insert(healthOrder, {Red = nil, Other = {i, j}})
			end
		end
	end
	
	--local boneRedProtection = nil
	local numGoldHearts = data.Overlays["GOLDEN_HEART"]
	for i = #healthOrder, 1, -1 do
		local redIndices = healthOrder[i].Red
		local otherIndices = healthOrder[i].Other
		
		local health = otherMasks[otherIndices[1]][otherIndices[2]]
		local key = health.Key
		
		if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
		   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
		   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP == 0 and 
		   redIndices ~= nil
		then
			if numGoldHearts > 0 then 
				healthOrder[i].IsGold = true
				numGoldHearts = numGoldHearts - 1
			end
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0 
		then
			if numGoldHearts > 0 then 
				healthOrder[i].IsGold = true
				numGoldHearts = numGoldHearts - 1
			end
			
			--if boneRedProtection == nil then
			--	boneRedProtection = redIndices ~= nil
			--end
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
			if numGoldHearts > 0 then 
				healthOrder[i].IsGold = true
				numGoldHearts = numGoldHearts - 1
			end
		end
	end
	
	return healthOrder
end

function CustomHealthAPI.Helper.GetDamageStreams(player)
	local data = player:GetData().CustomHealthAPISavedata
	local otherMasks = data.OtherHealthMasks
	
	local healthOrder = CustomHealthAPI.Helper.GetHealthOrder(player)
	
	local streamOfRed = {}
	local streamOfSouls = {}
	local streamOfBones = {}
	
	for i = #healthOrder, 1, -1 do
		local redIndices = healthOrder[i].Red
		local otherIndices = healthOrder[i].Other
		
		local health = otherMasks[otherIndices[1]][otherIndices[2]]
		local key = health.Key
		
		if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
		   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
		   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP == 0 and 
		   redIndices ~= nil
		then
			if #streamOfSouls == 0 and #streamOfBones == 0 then
				table.insert(streamOfRed, healthOrder[i])
			else
				break
			end
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0 
		then
			if #streamOfSouls == 0 and #streamOfRed == 0 then
				table.insert(streamOfBones, healthOrder[i])
			end
			break
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
			if #streamOfBones == 0 and #streamOfRed == 0 then
				table.insert(streamOfSouls, healthOrder[i])
			else
				break
			end
		end
	end

	return streamOfRed, streamOfSouls, streamOfBones
end

function CustomHealthAPI.Helper.GetForcedRedDamageStream(player)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	
	local normalOrder = CustomHealthAPI.Helper.GetHealthOrder(player)
	
	local forcedRedOrder = {}
	local lastMaskIndex = 0
	for i = 1, #normalOrder do
		local orderEntry = normalOrder[i]
		local redIndices = orderEntry.Red
		
		if redIndices ~= nil then
			local health = redMasks[redIndices[1]][redIndices[2]]
			local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaskIndex
			
			forcedRedOrder[maskIndex] = forcedRedOrder[maskIndex] or {}
			table.insert(forcedRedOrder[maskIndex], 1, orderEntry)
			
			lastMaskIndex = math.max(maskIndex, lastMaskIndex)
		end
	end
	
	local streamOfRed = {}
	for i = 1, lastMaskIndex do
		local mask = forcedRedOrder[i]
		if mask then
			for j = 1, #mask do
				table.insert(streamOfRed, mask[j])
			end
		end
	end
	
	return streamOfRed
end

function CustomHealthAPI.Helper.HealthHasTaintedMaggieProtection(player, redHealthIndex)
	local isTaintedMaggie = CustomHealthAPI.Helper.PlayerIsTaintedMaggie(player)
	local isBleedingContainer = (redHealthIndex > 2 and not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)) or redHealthIndex > 3
	
	return isTaintedMaggie and isBleedingContainer
end

function CustomHealthAPI.Helper.HandleForcedRedDamage(player, amount, flags, source, countdown)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	local toRemove = math.floor(amount + 0.5)
	
	local streamOfRed = CustomHealthAPI.Helper.GetForcedRedDamageStream(player)
	
	local isRedDamage = false
	local damagedDevilDeal = 0
	local heartsBroken = {}
	local didDamage = false
	if #streamOfRed > 0 then
		local amountToRemove = toRemove
		for i = 1, #streamOfRed do
			local redIndices = streamOfRed[i].Red
			local otherIndices = streamOfRed[i].Other
			local health = redMasks[redIndices[1]][redIndices[2]]
			local otherHealth = otherMasks[otherIndices[1]][otherIndices[2]]
	
			local prevent = false
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_DAMAGED)
			for _, callback in ipairs(callbacks) do
				local newAmount = callback.Function(player, 
													flags, 
													health.Key, health.HP, 
													otherHealth.Key, otherHealth.HP, 
													amountToRemove)
				if newAmount == true then
					prevent = true
					break
				elseif newAmount ~= nil then
					amountToRemove = newAmount
					break
				end
			end
			
			if prevent or amountToRemove <= 0 then
				break
			end
			
			if amountToRemove >= health.HP then
				if not CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].ProtectsDealChance and 
				   not CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key].ProtectsDealChance and
				   not CustomHealthAPI.Helper.HealthHasTaintedMaggieProtection(player, redIndices[3])
				then
					damagedDevilDeal = damagedDevilDeal + health.HP
				end
				
				CustomHealthAPI.Helper.HandleGoldDamage(player, heartsBroken, streamOfRed[i].IsGold, CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key].MaxHP <= 0)
				
				amountToRemove = amountToRemove - health.HP
				heartsBroken[health.Key] = (heartsBroken[health.Key] or 0) + 1
				table.insert(heartsDamaged, {Key = health.Key, HP = health.HP, Broken = true}) 
				table.remove(redMasks[redIndices[1]], redIndices[2])
				
				didDamage = true
			else
				if not CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].ProtectsDealChance and 
				   not CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key].ProtectsDealChance and
				   not CustomHealthAPI.Helper.HealthHasTaintedMaggieProtection(player, redIndices[3])
				then
					damagedDevilDeal = damagedDevilDeal + amountToRemove
				end
				
				health.HP = health.HP - amountToRemove
				table.insert(heartsDamaged, {Key = health.Key, HP = amountToRemove, Broken = false}) 
				amountToRemove = 0
				
				didDamage = true
			end
			
			if amountToRemove <= 0 then
				break
			end
		end
	
		if CustomHealthAPI.Helper.HandleRedEternalDamage(player, flags, heartsBroken) then
			damagedDevilDeal = damagedDevilDeal - 1
		end
		
		isRedDamage = true
	else
		print("Custom Health API ERROR: CustomHealthAPI.Helper.HandleForcedRedDamage; No hearts to damage.")
		return
	end
	
	return isRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
end

function CustomHealthAPI.Helper.HandleRegularDamage(player, amount, flags, source, countdown)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	local toRemove = math.floor(amount + 0.5)
	
	local streamOfRed, streamOfSouls, streamOfBones = CustomHealthAPI.Helper.GetDamageStreams(player)
	
	local isRedDamage = false
	local damagedDevilDeal = 0
	local heartsBroken = {}
	local didDamage = false
	if #streamOfRed > 0 then
		local amountToRemove = toRemove
		for i = 1, #streamOfRed do
			local redIndices = streamOfRed[i].Red
			local otherIndices = streamOfRed[i].Other
			local health = redMasks[redIndices[1]][redIndices[2]]
			local otherHealth = otherMasks[otherIndices[1]][otherIndices[2]]
	
			local prevent = false
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_DAMAGED)
			for _, callback in ipairs(callbacks) do
				local newAmount = callback.Function(player, 
													flags, 
													health.Key, health.HP, 
													otherHealth.Key, otherHealth.HP, 
													amountToRemove)
				if newAmount == true then
					prevent = true
					break
				elseif newAmount ~= nil then
					amountToRemove = newAmount
					break
				end
			end
			
			if prevent or amountToRemove <= 0 then
				break
			end
			
			if amountToRemove >= health.HP then
				if not CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].ProtectsDealChance and 
				   not CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key].ProtectsDealChance and
				   not CustomHealthAPI.Helper.HealthHasTaintedMaggieProtection(player, redIndices[3])
				then
					damagedDevilDeal = damagedDevilDeal + health.HP
				end
				
				CustomHealthAPI.Helper.HandleGoldDamage(player, heartsBroken, streamOfRed[i].IsGold, CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key].MaxHP <= 0)
				
				amountToRemove = amountToRemove - health.HP
				heartsBroken[health.Key] = (heartsBroken[health.Key] or 0) + 1
				table.insert(heartsDamaged, {Key = health.Key, HP = health.HP, Broken = true}) 
				table.remove(redMasks[redIndices[1]], redIndices[2])
				
				didDamage = true
			else
				if not CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].ProtectsDealChance and 
				   not CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key].ProtectsDealChance and
				   not CustomHealthAPI.Helper.HealthHasTaintedMaggieProtection(player, redIndices[3])
				then
					damagedDevilDeal = damagedDevilDeal + amountToRemove
				end
				
				health.HP = health.HP - amountToRemove
				table.insert(heartsDamaged, {Key = health.Key, HP = amountToRemove, Broken = false}) 
				amountToRemove = 0
				
				didDamage = true
			end
			
			if amountToRemove <= 0 then
				break
			end
		end
	
		if CustomHealthAPI.Helper.HandleRedEternalDamage(player, flags, heartsBroken) then
			damagedDevilDeal = damagedDevilDeal - 1
		end
		
		isRedDamage = true
	elseif #streamOfSouls > 0 then
		local amountToRemove = toRemove
		for i = 1, #streamOfSouls do
			local otherIndices = streamOfSouls[i].Other
			local health = otherMasks[otherIndices[1]][otherIndices[2]]
	
			local prevent = false
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_DAMAGED)
			for _, callback in ipairs(callbacks) do
				local newAmount = callback.Function(player, 
													flags, 
													nil, nil, 
													health.Key, health.HP, 
													amountToRemove)
				if newAmount == true then
					prevent = true
					break
				elseif newAmount ~= nil then
					amountToRemove = newAmount
					break
				end
			end
			
			if prevent or amountToRemove <= 0 then
				break
			end
			
			if amountToRemove >= health.HP then
				CustomHealthAPI.Helper.HandleGoldDamage(player, heartsBroken, streamOfSouls[i].IsGold, nil)
				
				amountToRemove = amountToRemove - health.HP
				heartsBroken[health.Key] = (heartsBroken[health.Key] or 0) + 1
				table.insert(heartsDamaged, {Key = health.Key, HP = health.HP, Broken = true}) 
				table.remove(otherMasks[otherIndices[1]], otherIndices[2])
				
				didDamage = true
			else
				health.HP = health.HP - amountToRemove
				table.insert(heartsDamaged, {Key = health.Key, HP = amountToRemove, Broken = false}) 
				amountToRemove = 0
				
				didDamage = true
			end
			
			if amountToRemove <= 0 then
				break
			end
		end
	
		if CustomHealthAPI.Helper.HandleSoulEternalDamage(player, heartsBroken) then
			damagedDevilDeal = damagedDevilDeal - 1
		end
	elseif #streamOfBones > 0 then
		local redIndices = streamOfBones[1].Red
		local otherIndices = streamOfBones[1].Other
		local amountToRemove = toRemove
		
		if redIndices ~= nil then
			local health = redMasks[redIndices[1]][redIndices[2]]
			local otherHealth = otherMasks[otherIndices[1]][otherIndices[2]]
	
			local prevent = false
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_DAMAGED)
			for _, callback in ipairs(callbacks) do
				local newAmount = callback.Function(player, 
													flags, 
													health.Key, health.HP, 
													otherHealth.Key, otherHealth.HP, 
													amountToRemove)
				if newAmount == true then
					prevent = true
					break
				elseif newAmount ~= nil then
					amountToRemove = newAmount
					break
				end
			end
			
			if not (prevent or amountToRemove <= 0) then
				if amountToRemove >= health.HP then
					if not CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].ProtectsDealChance and 
					   not CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key].ProtectsDealChance and
					   not CustomHealthAPI.Helper.HealthHasTaintedMaggieProtection(player, redIndices[3])
					then
						damagedDevilDeal = damagedDevilDeal + health.HP
					end
					
					amountToRemove = amountToRemove - health.HP
					heartsBroken[health.Key] = (heartsBroken[health.Key] or 0) + 1
					table.insert(heartsDamaged, {Key = health.Key, HP = health.HP, Broken = true}) 
					table.remove(redMasks[redIndices[1]], redIndices[2])
					
					didDamage = true
				else
					if not CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].ProtectsDealChance and 
					   not CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key].ProtectsDealChance and
					   not CustomHealthAPI.Helper.HealthHasTaintedMaggieProtection(player, redIndices[3])
					then
						damagedDevilDeal = damagedDevilDeal + amountToRemove
					end
					
					health.HP = health.HP - amountToRemove
					table.insert(heartsDamaged, {Key = health.Key, HP = amountToRemove, Broken = false})
					
					didDamage = true
				end
				
				if CustomHealthAPI.Helper.HandleRedEternalDamage(player, flags, heartsBroken) then
					damagedDevilDeal = damagedDevilDeal - 1
				end
				
				isRedDamage = true
			end
		else
			local otherHealth = otherMasks[otherIndices[1]][otherIndices[2]]
	
			local prevent = false
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_DAMAGED)
			for _, callback in ipairs(callbacks) do
				local newAmount = callback.Function(player, 
													flags, 
													nil, nil, 
													otherHealth.Key, otherHealth.HP, 
													amountToRemove)
				if newAmount == true then
					prevent = true
					break
				elseif newAmount ~= nil then
					amountToRemove = newAmount
					break
				end
			end
			
			if not (prevent or amountToRemove <= 0) then
				if amountToRemove >= otherHealth.HP then
					CustomHealthAPI.Helper.HandleGoldDamage(player, heartsBroken, streamOfBones[1].IsGold, nil)
					
					amountToRemove = amountToRemove - otherHealth.HP
					heartsBroken[otherHealth.Key] = (heartsBroken[otherHealth.Key] or 0) + 1
					table.insert(heartsDamaged, {Key = otherHealth.Key, HP = otherHealth.HP, Broken = true}) 
					table.remove(otherMasks[otherIndices[1]], otherIndices[2])
					
					didDamage = true
				else
					otherHealth.HP = otherHealth.HP - amountToRemove
					table.insert(heartsDamaged, {Key = otherHealth.Key, HP = amountToRemove, Broken = false})
					amountToRemove = 0
					
					didDamage = true
				end
				
				if CustomHealthAPI.Helper.HandleBoneEternalDamage(player, heartsBroken, otherHealth.Key) then
					damagedDevilDeal = damagedDevilDeal - 1
				end
			end
		end
	else
		print("Custom Health API ERROR: CustomHealthAPI.Helper.HandleRegularDamage; No hearts to damage.")
		return
	end
	
	return isRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
end

function CustomHealthAPI.Helper.HandleDamage(player, amount, flags, source, countdown)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	local toRemove = math.floor(amount + 0.5)
	
	local currentCustomRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, false)
	local currentBasegameRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, true)
	local currentRedHP = math.max(CustomHealthAPI.Helper.GetTotalRedHP(player, false), CustomHealthAPI.Helper.GetTotalRedHP(player, true))
	local forcedRedDamage = currentRedHP >= toRemove and 
	                        (flags & DamageFlag.DAMAGE_RED_HEARTS == DamageFlag.DAMAGE_RED_HEARTS or player:HasTrinket(TrinketType.TRINKET_CROW_HEART))
	
	local handleFunc = CustomHealthAPI.Helper.HandleRegularDamage
	if forcedRedDamage then
		handleFunc = CustomHealthAPI.Helper.HandleForcedRedDamage
	end
	local isRedDamage, damagedDevilDeal, heartsBroken, didDamage = handleFunc(player, amount, flags, source, countdown)
	
	if heartsBroken == nil then
		return false
	elseif not didDamage then
		return false
	end
	
	for i = 1, #heartsDamaged do
		local health = heartsDamaged[i]
		
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_HEALTH_DAMAGED)
		for _, callback in ipairs(callbacks) do
			callback.Function(player, flags, health.Key, health.HP, health.Broken, i == #heartsDamaged)
		end
	end
	heartsDamaged = {}
	
	--handle desync
	
	local remainingRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, true)
	local remainingSoulHP = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
	local remainingBoneHP = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
	local redHeartLimit = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) / 2) - (math.ceil(remainingSoulHP / 2) + remainingBoneHP + 1)
	local numBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
	
	local compensationFunc = function(player)
		CustomHealthAPI.Helper.AddBasegameBrokenHealthWithoutModifiers(player, numBroken)
		if isRedDamage then
			if CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
				CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, math.ceil((remainingRedHP + toRemove) / 2))
				CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, remainingRedHP + toRemove)
			elseif forcedRedDamage or CustomHealthAPI.Helper.PlayerIsBethany(player) then
				if damagedDevilDeal then
					CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, remainingRedHP + toRemove)
					CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, remainingRedHP + toRemove)
					CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, remainingSoulHP)
					CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, remainingBoneHP)
				else
					local redHPToAdd = remainingRedHP
					local isHalfHeart = false
					if redHPToAdd % 2 == 1 then
						isHalfHeart = true
						redHPToAdd = redHPToAdd - 1
					end
					redHPToAdd = redHPToAdd + toRemove * 2
					
					CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, redHPToAdd)
					CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, redHPToAdd)
					if isHalfHeart then
						CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, 1)
					end
					
					CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, remainingSoulHP)
					CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, remainingBoneHP)
				end
			else
				local numLimit = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) / 2)
				local numNonRed = remainingBoneHP + math.ceil((remainingSoulHP + toRemove) / 2)
				local redLimit = numLimit - numNonRed
				
				CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, remainingBoneHP)
				CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, remainingSoulHP + toRemove)
				CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, math.min(remainingRedHP, redLimit * 2))
				CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, math.min(remainingRedHP, redLimit * 2))
			end
		elseif (heartsBroken["BONE_HEART"] or 0) > 0 then
			local hpToAdd = 1
			if (heartsBroken["ETERNAL_HEART"] or 0) > 0 then
				CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, 1)
				hpToAdd = 0
			end
			
			local numLimit = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) / 2)
			local numNonRed = remainingBoneHP + 1 + math.ceil(remainingSoulHP / 2)
			local redLimit = numLimit - numNonRed
			
			CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, remainingSoulHP)
			CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, remainingBoneHP + hpToAdd)
			CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, math.min(remainingRedHP, redLimit * 2))
			CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, math.min(remainingRedHP, redLimit * 2))
		elseif (heartsBroken["BLACK_HEART"] or 0) > 0 then
			if (heartsBroken["ETERNAL_HEART"] or 0) > 0 then
				local blackToAdd = math.max(0, (heartsBroken["BLACK_HEART"] or 0) * 2 - 1)
				CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, blackToAdd)
				CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, 1)
			else
				local blackToAdd = math.max(0, (heartsBroken["BLACK_HEART"] or 0) * 2 - 1)
				local soulToAdd = math.max(0, (remainingSoulHP + toRemove) - blackToAdd)
				
				local numLimit = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) / 2)
				local numNonRed = remainingBoneHP + math.ceil((remainingSoulHP + toRemove) / 2)
				local redLimit = numLimit - numNonRed
				
				CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, remainingBoneHP)
				CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, soulToAdd)
				CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, blackToAdd)
				CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, math.min(remainingRedHP, redLimit * 2))
				CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, math.min(remainingRedHP, redLimit * 2))
			end
		else
			local numLimit = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) / 2)
			local numNonRed = remainingBoneHP + math.ceil((remainingSoulHP + toRemove) / 2)
			local redLimit = numLimit - numNonRed
			
			CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, remainingBoneHP)
			CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, remainingSoulHP + toRemove)
			CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, math.min(remainingRedHP, redLimit * 2))
			CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, math.min(remainingRedHP, redLimit * 2))
		end
		
		if (heartsBroken["GOLDEN_HEART"] or 0) > 0 then
			CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, heartsBroken["GOLDEN_HEART"])
		end
	end
	
	CustomHealthAPI.Helper.HandleDamageDesync(player, compensationFunc)
	
	if damagedDevilDeal and
	   flags & DamageFlag.DAMAGE_RED_HEARTS == 0 and
	   flags & DamageFlag.DAMAGE_FAKE == 0 and
	   flags & DamageFlag.DAMAGE_NO_PENALTIES == 0
	then
		Game():GetRoom():SetRedHeartDamage()
		Game():GetLevel():SetRedHeartDamage()
	end
	
	return true
end

function CustomHealthAPI.Helper.HandleBloodOath(player, amount, flags, source, countdown)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	local toRemove = math.floor(amount + 0.5)
	
	local streamOfRed = CustomHealthAPI.Helper.GetForcedRedDamageStream(player)
	
	local remainingSoulHP = CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
	local remainingBoneHP = CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
	local numBroken = CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
	
	local redToDamageDownTo = ((remainingSoulHP + remainingBoneHP == 0) and 1) or 0
	local damageTaken = 0
	while CustomHealthAPI.Helper.GetTotalRedHP(player, true) > redToDamageDownTo or CustomHealthAPI.Helper.GetTotalRedHP(player, false) > redToDamageDownTo do
		local redIndices = streamOfRed[1].Red
		local otherIndices = streamOfRed[1].Other
		
		local redHealth = redMasks[redIndices[1]][redIndices[2]]
		local otherHealth = otherMasks[otherIndices[1]][otherIndices[2]]
		
		local brokeGold = 0
	
		local amountToDamage = 1
		local prevent = false
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_BLOOD_OATH_DAMAGE)
		for _, callback in ipairs(callbacks) do
			local newAmount = callback.Function(player, 
			                                    flags, 
			                                    redHealth.Key, redHealth.HP, 
			                                    otherHealth.Key, otherHealth.HP, 
			                                    amountToDamage)
			if newAmount == true then
				prevent = true
				break
			elseif newAmount ~= nil then
				amountToDamage = newAmount
				break
			end
		end
		
		if prevent or amountToDamage <= 0 then
			break
		end
		
		redHealth.HP = math.max(0, redHealth.HP - amountToDamage)
		if redHealth.HP == 0 then
			if streamOfRed.IsGold and CustomHealthAPI.PersistentData.HealthDefinitions[otherHealth.Key].MaxHP == 0 then
				brokeGold = 1
				data.Overlays["GOLDEN_HEART"] = math.max(0, data.Overlays["GOLDEN_HEART"] - 1)
			end
			
			table.remove(redMasks[redIndices[1]], redIndices[2])
			table.remove(streamOfRed, 1)
		end
	
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_HEALTH_DAMAGED)
		for _, callback in ipairs(callbacks) do
			callback.Function(player, 
			                  flags, 
			                  redHealth.Key, amountToDamage, 
			                  redHealth.HP == 0, 
			                  not (CustomHealthAPI.Helper.GetTotalRedHP(player, true) > redToDamageDownTo or 
			                       CustomHealthAPI.Helper.GetTotalRedHP(player, false) > redToDamageDownTo))
		end
		
		local remainingRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, true)
		
		local compensationFunc = function(player)
			CustomHealthAPI.Helper.AddBasegameBrokenHealthWithoutModifiers(player, numBroken)
			
			CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, remainingRedHP + 1)
			CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, remainingRedHP + 1)
			CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, remainingSoulHP)
			CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, remainingBoneHP)
			
			if brokeGold > 0 then
				CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, brokeGold)
			end
		end
		
		local damageFunc = function(player, amount, flags, source, countdown)
			player:TakeDamage(1, 33826849, source, countdown)
		end
		
		CustomHealthAPI.Helper.HandleDamageDesyncOld(player, amount, flags, source, countdown, damageFunc, compensationFunc, true)
		
		damageTaken = damageTaken + 1
	end
	
	if CustomHealthAPI.Helper.GetTotalRedHP(player, false) == 0 and redToDamageDownTo == 1 then
		local redContainingMask = data.RedHealthMasks[CustomHealthAPI.PersistentData.HealthDefinitions["RED_HEART"].MaskIndex]
		table.insert(redContainingMask, {Key = "RED_HEART", HP = 1})
		CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, 1)
	end
	
	local bloodOath = source.Entity:ToFamiliar()
	bloodOath.Hearts = damageTaken
end
