local heartsDamaged = {}

function CustomHealthAPI.Helper.AddProcessTakeDamageCallback()
---@diagnostic disable-next-line: param-type-mismatch
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
	
	local player = ent:ToPlayer()
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	if player:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage then
		local s = ""
		repeat
			s = Isaac.ExecuteCommand("debug 3")
		until s == "Disabled debug flag."
		player:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage = nil
	elseif CustomHealthAPI.Helper.IsDebugThreeActive() then
		return
	end
	
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_PLAYER_DAMAGE)
	for _, callback in ipairs(callbacks) do
		local returnTable = callback.Function(player, amount, flags, source, countdown)
		if type(returnTable) == "table" then
			if returnTable.Amount ~= nil then
				amount = returnTable.Amount
			end
			if returnTable.Flags ~= nil then
				flags = returnTable.Flags
			end
			if returnTable.Prevent ~= nil then
				return false
			end
		elseif returnTable ~= nil then
			return false
		end
	end
	
	if not player or
	   CustomHealthAPI.Helper.PlayerIsIgnored(player) or
	   math.floor(amount + 0.5) < 1.0 or
	   player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_ASTRAL_PROJECTION) == 1 or
	   player:IsCoopGhost() or
	   CustomHealthAPI.Helper.GetTotalHP(player, true) <= 0
	then
		return
	end
	
	player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
	player:GetData().CustomHealthAPIOtherData.InDamageCallback = nil
	
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
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_GLASS_CANNON) and
	   flags & DamageFlag.DAMAGE_RED_HEARTS ~= DamageFlag.DAMAGE_RED_HEARTS and 
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
				                                                                  0,
				                                                                  ItemPoolType.POOL_TREASURE)
				player:GetData().CustomHealthAPISavedata.GlassCannonBroke = true
			end
		end
	end
	
	if flags & DamageFlag.DAMAGE_FAKE ~= DamageFlag.DAMAGE_FAKE then	
		local didDamage = CustomHealthAPI.Helper.HandleDamage(player, amount, flags, source, countdown)
		
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		player:GetData().CustomHealthAPISavedata.HandlingDamageCanShackle = not (player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_SOUL) or 
																				 player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED))
		player:GetData().CustomHealthAPISavedata.HandlingDamage = true
		player:GetData().CustomHealthAPISavedata.HandlingDamageAmount = amount
		player:GetData().CustomHealthAPISavedata.HandlingDamageFlags = flags
		player:GetData().CustomHealthAPISavedata.HandlingDamageSource = source
		player:GetData().CustomHealthAPISavedata.HandlingDamageCountdown = countdown
		
		player:GetData().CustomHealthAPIOtherData.ShouldActivateScapular = player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_SCAPULAR)
		
		return
	else
		player:GetData().CustomHealthAPIOtherData.InDamageCallback = nil
		return
	end
end

function CustomHealthAPI.Helper.AddHandleBloodOathCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_ENTITY_TAKE_DMG, -1 * math.huge, CustomHealthAPI.Mod.HandleBloodOathCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHandleBloodOathCallback)

function CustomHealthAPI.Helper.RemoveHandleBloodOathCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CustomHealthAPI.Mod.HandleBloodOathCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHandleBloodOathCallback)

local isCustomBloodOath = false
CustomHealthAPI.PersistentData.OverrideCustomBloodOathHandling = CustomHealthAPI.PersistentData.OverrideCustomBloodOathHandling or false
function CustomHealthAPI.Mod:HandleBloodOathCallback(ent, amount, flags, source, countdown)
	if CustomHealthAPI.PersistentData.OverrideCustomBloodOathHandling then
		return
	end

	local isBloodOath = source.Entity and 
	                    source.Entity.Type == EntityType.ENTITY_FAMILIAR and 
	                    source.Entity.Variant == FamiliarVariant.BLOOD_OATH
	
	if isBloodOath and not isCustomBloodOath then
		if ent.Type ~= EntityType.ENTITY_PLAYER then
			return
		end
		
		if CustomHealthAPI.Helper.IsDebugThreeActive() then
			-- NOTE: Probably needs special handling but for now it's at least functional
			return
		end
		
		local player = ent:ToPlayer()
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_BLOOD_OATH_DAMAGE)
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
		   CustomHealthAPI.Helper.GetTotalHP(player, true) <= 0
		then
			return
		end
		
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		
		local data = player:GetData().CustomHealthAPISavedata
		local numEternal = data.Overlays["ETERNAL_HEART"]
		data.Overlays["ETERNAL_HEART"] = 0
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		
		local bloodOath = source.Entity:ToFamiliar()
		bloodOath.Hearts = 0
		
		repeat
			CustomHealthAPI.Helper.FinishDamageDesync(player)
			
			if player:GetDamageCooldown() > 0 then
				player:ResetDamageCooldown() -- WHY IS DAMAGE INVINCIBLE NOT WORKING
			end
			
			isCustomBloodOath = true
			local tookDamage = CustomHealthAPI.Helper.HookFunctions.TakeDamage(player,
			                                                                   1, 
			                                                                   DamageFlag.DAMAGE_NOKILL + 
			                                                                   DamageFlag.DAMAGE_RED_HEARTS +
			                                                                   DamageFlag.DAMAGE_ISSAC_HEART + 
			                                                                   DamageFlag.DAMAGE_INVINCIBLE + 
			                                                                   DamageFlag.DAMAGE_IV_BAG +
			                                                                   DamageFlag.DAMAGE_NO_MODIFIERS, 
			                                                                   source, 
			                                                                   countdown,
			                                                                   CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamagePlayer,
			                                                                   true)
			isCustomBloodOath = false
			
			if not tookDamage then
				break
			end
			
			bloodOath.Hearts = bloodOath.Hearts + 1
		until ( CustomHealthAPI.Helper.GetTotalRedHP(player, nil, nil, true) <= 0 or
		         (CustomHealthAPI.Helper.GetTotalRedHP(player, false, true, true) == 1 and
		          CustomHealthAPI.Helper.GetTotalSoulHP(player, nil, nil, true) <= 0 and
				  CustomHealthAPI.Helper.GetTotalBoneHP(player, nil, true) <= 0))
		
		CustomHealthAPI.Helper.FinishDamageDesync(player)
		data.Overlays["ETERNAL_HEART"] = numEternal
		CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		
		return false
	elseif not isBloodOath then
		isCustomBloodOath = false
	end
end

function CustomHealthAPI.Helper.AddEndTakeDamageCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_ENTITY_TAKE_DMG, math.huge, CustomHealthAPI.Mod.EndTakeDamageCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddEndTakeDamageCallback)

function CustomHealthAPI.Helper.RemoveEndTakeDamageCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CustomHealthAPI.Mod.EndTakeDamageCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveEndTakeDamageCallback)

function CustomHealthAPI.Mod:EndTakeDamageCallback(ent, amount, flags, source, countdown)
	if ent:GetData().CustomHealthAPIOtherData and ent:GetData().CustomHealthAPIOtherData.InDamageCallback then
		ent:GetData().CustomHealthAPIOtherData.InDamageCallback = nil
	end
	
	if ent:GetData().CustomHealthAPIPersistent and ent:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage then
		local s = ""
		repeat
			s = Isaac.ExecuteCommand("debug 3")
		until s == "Enabled debug flag."
	end
end

function CustomHealthAPI.Helper.FinishDamageDesync(ent)
	local player = ent:ToPlayer()
	if not player then return end

	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.FinishDamageDesync(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		return
	end
	
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	if player:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage ~= nil and 
	   player:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage ~= Isaac.GetFrameCount() 
	then
		local s = ""
		repeat
			s = Isaac.ExecuteCommand("debug 3")
		until s == "Disabled debug flag."
		player:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage = nil
	end
	
	local data = player:GetData().CustomHealthAPISavedata
	if data and not data.HandlingDamage then
		CustomHealthAPI.Helper.HandleGlassCannonOnBreaking(player)
		
		if player:GetExtraLives() > 0 then
			CustomHealthAPI.PersistentData.DoHUDPostUpdateForLivesHUD = Isaac.GetFrameCount()
		end
		
		return false
	end
	
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
	
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	player:ClearEntityFlags(EntityFlag.FLAG_BLEED_OUT)
	
	if flags & DamageFlag.DAMAGE_NOKILL == DamageFlag.DAMAGE_NOKILL and CustomHealthAPI.Helper.GetTotalHP(player, true) == 0 then
		local playerType = player:GetPlayerType()
		local key, hp
		if CustomHealthAPI.Helper.GetTotalMaxHP(player, true) > 0 then
			key = "RED_HEART"
			hp = 1
		elseif CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player) then
			key = "BONE_HEART"
			hp = 1
		elseif not (CustomHealthAPI.Helper.PlayerHasCoinHealth(player)) and playerType ~= PlayerType.PLAYER_BETHANY then
			key = "SOUL_HEART"
			hp = 1
		end
		
		if key ~= nil then
			CustomHealthAPI.PersistentData.PreventGetHPCaching = true
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
			CustomHealthAPI.PersistentData.PreventGetHPCaching = false
			
			if not prevent then
				CustomHealthAPI.Library.AddHealth(player, key, hp, true, false, false, false, false, true, true, true)
			end
		end
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_HEARTBREAK) and CustomHealthAPI.Helper.GetTotalHP(player, true) == 0 then
		CustomHealthAPI.Library.AddHealth(player, "BROKEN_HEART", 2)
		
		local limit = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player) / 2)
		if limit > 0 then
			local playerType = player:GetPlayerType()
			local key, hp
			if CustomHealthAPI.Helper.GetTotalMaxHP(player, true) > 0 then
				key = "RED_HEART"
				hp = 1
			elseif CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player) then
				key = "BONE_HEART"
				hp = 1
			elseif not (CustomHealthAPI.Helper.PlayerHasCoinHealth(player)) and playerType ~= PlayerType.PLAYER_BETHANY then
				key = "SOUL_HEART"
				hp = 1
			end
		
			if key ~= nil then
				CustomHealthAPI.PersistentData.PreventGetHPCaching = true
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
				CustomHealthAPI.PersistentData.PreventGetHPCaching = false
				
				if not prevent then
					CustomHealthAPI.Library.AddHealth(player, key, hp, true, false, false, false, false, true, true, true)
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
			if CustomHealthAPI.Helper.GetTotalMaxHP(player, true) > 0 then
				key = "RED_HEART"
				hp = 1
			elseif CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player) then
				key = "BONE_HEART"
				hp = 1
			elseif not (CustomHealthAPI.Helper.PlayerHasCoinHealth(player)) and playerType ~= PlayerType.PLAYER_BETHANY then
				key = "SOUL_HEART"
				hp = 1
			end
		
			if key ~= nil then
				CustomHealthAPI.PersistentData.PreventGetHPCaching = true
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
				CustomHealthAPI.PersistentData.PreventGetHPCaching = false
				
				if not prevent then
					CustomHealthAPI.Library.AddHealth(player, key, hp, true, false, false, false, false, true, true, true)
				end
			end
		end
		
		player:GetData().CustomHealthAPIOtherData.ShacklesDisabled = true
	end
	
	local remainingRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true)
	local remainingSoulHP = CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true)
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_SCAPULAR) and remainingRedHP + remainingSoulHP == 1 then
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		local otherdata = player:GetData().CustomHealthAPIOtherData
		
		if otherdata.ShouldActivateScapular and flags & DamageFlag.DAMAGE_RED_HEARTS ~= DamageFlag.DAMAGE_RED_HEARTS then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", 2)
			CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
		end
		
		otherdata.ShouldActivateScapular = nil
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
	
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	if player:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage ~= nil then
		local s = ""
		repeat
			s = Isaac.ExecuteCommand("debug 3")
		until s == "Disabled debug flag."
		player:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage = nil
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
		
		if CustomHealthAPI.Helper.GetTotalHP(player, true) > 0 then
			local glassFlags = DamageFlag.DAMAGE_NOKILL | DamageFlag.DAMAGE_INVINCIBLE | DamageFlag.DAMAGE_ISSAC_HEART | DamageFlag.DAMAGE_NO_MODIFIERS
			player:ResetDamageCooldown() -- WHY IS DAMAGE_INVINCIBLE NOT WORKING
			player:TakeDamage(2, glassFlags, EntityRef(player), 30)
			--CustomHealthAPI.Helper.FinishDamageDesync(player)
			player:ResetDamageCooldown() -- WHY IS DAMAGE_INVINCIBLE NOT WORKING
			player:TakeDamage(2, glassFlags, EntityRef(player), 30)
			--CustomHealthAPI.Helper.FinishDamageDesync(player)
			
			local data = player:GetData().CustomHealthAPISavedata
			local redMasks = data.RedHealthMasks
			local otherMasks = data.OtherHealthMasks
			
			if CustomHealthAPI.Helper.GetTotalHP(player, true) <= 0 then
				local playerType = player:GetPlayerType()
				local key, hp
				if CustomHealthAPI.Helper.GetTotalMaxHP(player, true) > 0 then
					key = "RED_HEART"
					hp = 1
				elseif CustomHealthAPI.Helper.PlayerIsBoneHeartOnly(player) then
					key = "BONE_HEART"
					hp = 1
				elseif not (CustomHealthAPI.Helper.PlayerHasCoinHealth(player)) and playerType ~= PlayerType.PLAYER_BETHANY then
					key = "SOUL_HEART"
					hp = 1
				end
			
				if key ~= nil then
					CustomHealthAPI.PersistentData.PreventGetHPCaching = true
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
					CustomHealthAPI.PersistentData.PreventGetHPCaching = false
					
					if not prevent then
						CustomHealthAPI.Helper.UpdateHealthMasks(player, key, hp, true, false, true, true, true)
						CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
					end
				end
			end
		end
	end
end

if REPENTOGON then

function CustomHealthAPI.Helper.AddPostTakeDamageCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_ENTITY_TAKE_DMG, CustomHealthAPI.Enums.CallbackPriorities.EARLY, CustomHealthAPI.Mod.PostTakeDamageCallback, EntityType.ENTITY_PLAYER)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPostTakeDamageCallback)

function CustomHealthAPI.Helper.RemovePostTakeDamageCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, CustomHealthAPI.Mod.PostTakeDamageCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePostTakeDamageCallback)

function CustomHealthAPI.Mod:PostTakeDamageCallback(ent, damage, flags, source, countdown)
	local player = ent:ToPlayer()
	if not player then return end

	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.FinishDamageDesync(player)
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

function CustomHealthAPI.Helper.HandleDamageDesync(player) --, compensationFunc)
	--CustomHealthAPI.Helper.HandleBasegameHealthStateUpdate(player, compensationFunc)
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	local s = ""
	repeat
		s = Isaac.ExecuteCommand("debug 3")
	until s == "Enabled debug flag."
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	player:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage = Isaac.GetFrameCount()
	
	player:ClearEntityFlags(EntityFlag.FLAG_BLEED_OUT)
	if CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true) > 0 and 
	   CustomHealthAPI.Helper.GetTotalHP(player, true) > 1 and 
	   not player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) and
	   player:HasCollectible(CollectibleType.COLLECTIBLE_SHARD_OF_GLASS)
	then
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
	    CustomHealthAPI.Helper.GetTotalHP(player, true) == 0)
	then
		CustomHealthAPI.PersistentData.PreventGetHPCaching = true
		
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
		
		CustomHealthAPI.PersistentData.PreventGetHPCaching = false
				
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
	
	if data.Overlays["ETERNAL_HEART"] > 0 and CustomHealthAPI.Helper.GetTotalHP(player, true) == 0 then
		CustomHealthAPI.PersistentData.PreventGetHPCaching = true
		
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
		
		CustomHealthAPI.PersistentData.PreventGetHPCaching = false
				
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
	
	if data.Overlays["ETERNAL_HEART"] > 0 and CustomHealthAPI.Helper.GetTotalHP(player, true) == 0 then
		CustomHealthAPI.PersistentData.PreventGetHPCaching = true
		
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
		
		CustomHealthAPI.PersistentData.PreventGetHPCaching = false
				
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

function CustomHealthAPI.Helper.HandleForcedRedDamage(player, amount, flags, source, countdown, prioritizeEternal)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	local toRemove = math.floor(amount + 0.5)
	
	local streamOfRed = CustomHealthAPI.Helper.GetForcedRedDamageStream(player)
	
	local isRedDamage = false
	local damagedDevilDeal = 0
	local heartsBroken = {}
	local didDamage = false
	
	if prioritizeEternal and data.Overlays["ETERNAL_HEART"] > 0 then
		while toRemove > 0 and data.Overlays["ETERNAL_HEART"] > 0 do
			data.Overlays["ETERNAL_HEART"] = math.max(0, data.Overlays["ETERNAL_HEART"] - 1)
			toRemove = toRemove - 1
			
			heartsBroken["ETERNAL_HEART"] = (heartsBroken["ETERNAL_HEART"] or 0) + 1
			table.insert(heartsDamaged, {Key = "ETERNAL_HEART", HP = 1, Broken = true})
			
			damagedDevilDeal = damagedDevilDeal - 1
			didDamage = true
		end
	end
	
	if toRemove <= 0 then
		return isRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
	end
	
	if #streamOfRed > 0 then
		if REPENTOGON then
			-- Red health damage is the ONLY one that actually calls the corresponding AddHearts function internally, and in turn triggers this callback. Cool!
			CustomHealthAPI.PersistentData.AllowAddHeartsCallback = CustomHealthAPI.PersistentData.AllowAddHeartsCallback + 1
			local result = Isaac.RunCallbackWithParam(ModCallbacks.MC_PRE_PLAYER_ADD_HEARTS, AddHealthType.RED, player, -toRemove, AddHealthType.RED, false)
			if result then
				if result >= 0 then
					if result > 0 then  -- Yeah, this can happen
						CustomHealthAPI.Library.AddHealth(player, "RED_HEART", result, nil, nil, nil, nil, nil, nil, nil, nil, true)
					end
					return isRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
				end
				toRemove = -result
			end
		end
		
		local amountToRemove = toRemove
		for i = 1, #streamOfRed do
			local redIndices = streamOfRed[i].Red
			local otherIndices = streamOfRed[i].Other
			local health = redMasks[redIndices[1]][redIndices[2]]
			local otherHealth = otherMasks[otherIndices[1]][otherIndices[2]]
	
			CustomHealthAPI.PersistentData.PreventGetHPCaching = true
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
			CustomHealthAPI.PersistentData.PreventGetHPCaching = false
			
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
		
		if REPENTOGON then
			-- Red health damage is the ONLY one that actually calls the corresponding AddHearts function internally, and in turn triggers this callback. Cool!
			CustomHealthAPI.PersistentData.AllowAddHeartsCallback = CustomHealthAPI.PersistentData.AllowAddHeartsCallback + 1
			Isaac.RunCallbackWithParam(ModCallbacks.MC_POST_PLAYER_ADD_HEARTS, AddHealthType.RED, player, -toRemove, AddHealthType.RED, false)
		end
		
		isRedDamage = true
	else
		print("Custom Health API ERROR: CustomHealthAPI.Helper.HandleForcedRedDamage; No hearts to damage.")
		return
	end
	
	return isRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
end

function CustomHealthAPI.Helper.HandleRegularDamage(player, amount, flags, source, countdown, prioritizeEternal)
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
		if prioritizeEternal and data.Overlays["ETERNAL_HEART"] > 0 then
			while toRemove > 0 and data.Overlays["ETERNAL_HEART"] > 0 do
				data.Overlays["ETERNAL_HEART"] = math.max(0, data.Overlays["ETERNAL_HEART"] - 1)
				toRemove = toRemove - 1
				
				heartsBroken["ETERNAL_HEART"] = (heartsBroken["ETERNAL_HEART"] or 0) + 1
				table.insert(heartsDamaged, {Key = "ETERNAL_HEART", HP = 1, Broken = true})
				
				damagedDevilDeal = damagedDevilDeal - 1
				didDamage = true
			end
		end
		
		if toRemove <= 0 then
			return isRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
		end
		
		if REPENTOGON then
			-- Red health damage is the ONLY one that actually calls the corresponding AddHearts function internally, and in turn triggers this callback. Cool!
			CustomHealthAPI.PersistentData.AllowAddHeartsCallback = CustomHealthAPI.PersistentData.AllowAddHeartsCallback + 1
			local result = Isaac.RunCallbackWithParam(ModCallbacks.MC_PRE_PLAYER_ADD_HEARTS, AddHealthType.RED, player, -toRemove, AddHealthType.RED, false)
			if result then
				if result >= 0 then
					if result > 0 then  -- Yeah, this can happen
						CustomHealthAPI.Library.AddHealth(player, "RED_HEART", result, nil, nil, nil, nil, nil, nil, nil, nil, true)
					end
					return isRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
				end
				toRemove = -result
			end
		end
		
		local amountToRemove = toRemove
		for i = 1, #streamOfRed do
			local redIndices = streamOfRed[i].Red
			local otherIndices = streamOfRed[i].Other
			local health = redMasks[redIndices[1]][redIndices[2]]
			local otherHealth = otherMasks[otherIndices[1]][otherIndices[2]]
	
			CustomHealthAPI.PersistentData.PreventGetHPCaching = true
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
			CustomHealthAPI.PersistentData.PreventGetHPCaching = false
			
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
		
		if REPENTOGON then
			-- Red health damage is the ONLY one that actually calls the corresponding AddHearts function internally, and in turn triggers this callback. Cool!
			CustomHealthAPI.PersistentData.AllowAddHeartsCallback = CustomHealthAPI.PersistentData.AllowAddHeartsCallback + 1
			Isaac.RunCallbackWithParam(ModCallbacks.MC_POST_PLAYER_ADD_HEARTS, AddHealthType.RED, player, -toRemove, AddHealthType.RED, false)
		end
		
		isRedDamage = true
	elseif #streamOfSouls > 0 then
		local amountToRemove = toRemove
		for i = 1, #streamOfSouls do
			if prioritizeEternal and data.Overlays["ETERNAL_HEART"] > 0 and
			   CustomHealthAPI.Helper.GetTotalRedHP(player, nil, nil, true) + CustomHealthAPI.Helper.GetTotalBoneHP(player, nil, true) <= 0 and 
			   CustomHealthAPI.Helper.GetTotalSoulHP(player, true, nil, true) <= 2 and
			   CustomHealthAPI.Helper.GetTotalSoulHP(player, nil, nil, true) <= amountToRemove
			then
				while amountToRemove > 0 and data.Overlays["ETERNAL_HEART"] > 0 do
					data.Overlays["ETERNAL_HEART"] = math.max(0, data.Overlays["ETERNAL_HEART"] - 1)
					amountToRemove = amountToRemove - 1
					
					heartsBroken["ETERNAL_HEART"] = (heartsBroken["ETERNAL_HEART"] or 0) + 1
					table.insert(heartsDamaged, {Key = "ETERNAL_HEART", HP = 1, Broken = true})
					
					damagedDevilDeal = damagedDevilDeal - 1
					didDamage = true
				end
			end
			
			if amountToRemove <= 0 then
				return isRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
			end
			
			local otherIndices = streamOfSouls[i].Other
			local health = otherMasks[otherIndices[1]][otherIndices[2]]
	
			CustomHealthAPI.PersistentData.PreventGetHPCaching = true
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
			CustomHealthAPI.PersistentData.PreventGetHPCaching = false
			
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
			if prioritizeEternal and data.Overlays["ETERNAL_HEART"] > 0 then
				while toRemove > 0 and data.Overlays["ETERNAL_HEART"] > 0 do
					data.Overlays["ETERNAL_HEART"] = math.max(0, data.Overlays["ETERNAL_HEART"] - 1)
					toRemove = toRemove - 1
					
					heartsBroken["ETERNAL_HEART"] = (heartsBroken["ETERNAL_HEART"] or 0) + 1
					table.insert(heartsDamaged, {Key = "ETERNAL_HEART", HP = 1, Broken = true})
					
					damagedDevilDeal = damagedDevilDeal - 1
					didDamage = true
				end
			end
			
			if toRemove <= 0 then
				return isRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
			end
			
			local health = redMasks[redIndices[1]][redIndices[2]]
			local otherHealth = otherMasks[otherIndices[1]][otherIndices[2]]
	
			CustomHealthAPI.PersistentData.PreventGetHPCaching = true
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
			CustomHealthAPI.PersistentData.PreventGetHPCaching = false
			
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
			if prioritizeEternal and data.Overlays["ETERNAL_HEART"] > 0 and
			   CustomHealthAPI.Helper.GetTotalRedHP(player, nil, nil, true) + CustomHealthAPI.Helper.GetTotalSoulHP(player, nil, nil, true) <= 0 and 
			   CustomHealthAPI.Helper.GetTotalBoneHP(player, true, true) <= 1
			then
				while amountToRemove > 0 and data.Overlays["ETERNAL_HEART"] > 0 do
					data.Overlays["ETERNAL_HEART"] = math.max(0, data.Overlays["ETERNAL_HEART"] - 1)
					amountToRemove = amountToRemove - 1
					
					heartsBroken["ETERNAL_HEART"] = (heartsBroken["ETERNAL_HEART"] or 0) + 1
					table.insert(heartsDamaged, {Key = "ETERNAL_HEART", HP = 1, Broken = true})
					
					damagedDevilDeal = damagedDevilDeal - 1
					didDamage = true
				end
			end
			
			if amountToRemove <= 0 then
				return isRedDamage, damagedDevilDeal > 0, heartsBroken, didDamage
			end
			
			local otherHealth = otherMasks[otherIndices[1]][otherIndices[2]]
	
			CustomHealthAPI.PersistentData.PreventGetHPCaching = true
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
			CustomHealthAPI.PersistentData.PreventGetHPCaching = false
			
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
	
	local currentCustomRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, false, nil, true)
	local currentBasegameRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true)
	local currentRedHP = math.max(CustomHealthAPI.Helper.GetTotalRedHP(player, false, nil, true), CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true))
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
	
	CustomHealthAPI.PersistentData.PreventGetHPCaching = true
	for i = 1, #heartsDamaged do
		local health = heartsDamaged[i]
		
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_HEALTH_DAMAGED)
		for _, callback in ipairs(callbacks) do
			callback.Function(player, flags, health.Key, health.HP, health.Broken, i == #heartsDamaged)
		end
	end
	CustomHealthAPI.PersistentData.PreventGetHPCaching = false
	heartsDamaged = {}
	
	--handle desync
	CustomHealthAPI.Helper.HandleDamageDesync(player) --, compensationFunc)
	
	--handle heart effects
	for i = 1, heartsBroken["BLACK_HEART"] or 0 do
		player:UseActiveItem(CollectibleType.COLLECTIBLE_NECRONOMICON) -- this is literally how it works in basegame dont @ me
	end
	
	if (heartsBroken["GOLDEN_HEART"] or 0) > 0 then
		CustomHealthAPI.Helper.TriggerGoldHearts(player, heartsBroken["GOLDEN_HEART"])
	end
	
	local processedBrittleBones = false
	for i = 1, heartsBroken["BONE_HEART"] or 0 do
		for i = 1, 8 do
			local randvec = Vector.FromAngle(math.random() * 360):Resized(1.0 + math.random() * 3.0)
			local boneshard = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TOOTH_PARTICLE, 0, player.Position, randvec, nil):ToEffect()
			boneshard.FallingSpeed = (3.0 + 9.0 * math.random()) * -1
			boneshard.m_Height = boneshard.FallingSpeed
			boneshard.FallingAcceleration = 1.3
			boneshard.Color = Color(0.7, 0.7, 0.65, 1.0, 0.0, 0.0, 0.0)
		end
		SFXManager():Play(SoundEffect.SOUND_BONE_SNAP)
		
		if player:HasCollectible(CollectibleType.COLLECTIBLE_BRITTLE_BONES) then
			CustomHealthAPI.Helper.HandleBrittleBonesOnBreak(player)
			processedBrittleBones = true
		end
		
		if CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
			-- you'd think this would be tied to the healthtype but it's not in basegame
			-- still tempted to change that
			damagedDevilDeal = true
		end
	end
	
	if processedBrittleBones then
		player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
		player:EvaluateItems()
	end
	
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

function CustomHealthAPI.Library.RemoveHealthInDamageOrder(player, amount, tryForceRedDamage, prioritizeEternal)
	if not (player and player:ToPlayer()) then
		return {}
	end
	
	if player:IsCoopGhost() then
		return {}
	end
	
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_THESOUL_B and player:GetOtherTwin() then
		return CustomHealthAPI.Library.RemoveHealthInDamageOrder(player:GetOtherTwin(), amount, tryForceRedDamage, prioritizeEternal)
	elseif CustomHealthAPI.Helper.PlayerIsHealthless(player) or CustomHealthAPI.Helper.IsFoundSoul(player) then
		local returnHearts = {}
		if CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player) > 0 then
			table.insert(returnHearts, {Key = "GOLDEN_HEART", HP = 1})
			CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts(player, -99)
		end
		table.insert(returnHearts, {Key = "SOUL_HEART", HP = 1})
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts(player, -99)
		return returnHearts
	elseif CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		local returnHearts = {}
		local toRemove = math.floor(amount + 0.5)
		while CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) > 0 and toRemove > 0 do
			local hearts = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) / 2)
			local goldenHearts = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
			
			if goldenHearts > hearts - 1 then
				table.insert(returnHearts, {Key = "GOLDEN_HEART", HP = 1})
				CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts(player, -1)
			end
			
			table.insert(returnHearts, {Key = "COIN_HEART", HP = 2})
			CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts(player, -2)
			toRemove = toRemove - 2
		end
		return returnHearts
	end
	
	
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	local toRemove = math.floor(amount + 0.5)
	
	local currentCustomRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, false, nil, true)
	local currentBasegameRedHP = CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true)
	local currentRedHP = math.max(CustomHealthAPI.Helper.GetTotalRedHP(player, false, nil, true), CustomHealthAPI.Helper.GetTotalRedHP(player, true, nil, true))
	local forcedRedDamage = currentRedHP >= toRemove and 
	                        (tryForceRedDamage or player:HasTrinket(TrinketType.TRINKET_CROW_HEART))
	
	local handleFunc = CustomHealthAPI.Helper.HandleRegularDamage
	if forcedRedDamage then
		handleFunc = CustomHealthAPI.Helper.HandleForcedRedDamage
	end
	
	local flags = 0
	if tryForceRedDamage then
		flags = DamageFlag.DAMAGE_RED_HEARTS
	end
---@diagnostic disable-next-line: param-type-mismatch
	local isRedDamage, damagedDevilDeal, heartsBroken, didDamage = handleFunc(player, amount, flags, EntityRef(nil), 0, prioritizeEternal)
	
	if heartsBroken == nil then
		return {}
	elseif not didDamage then
		return {}
	end
	
	local returnHearts = {}
	for i = 1, #heartsDamaged do
		table.insert(returnHearts, heartsDamaged[i])
	end
	heartsDamaged = {}
	
	if heartsBroken["GOLDEN_HEART"] then
		table.insert(returnHearts, {Key = "GOLDEN_HEART", HP = 1})
	end
	
	--update hp
	CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
	
	return returnHearts
end
