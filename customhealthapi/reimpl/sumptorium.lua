-- 0 = Red Heart
-- 1 = Soul Heart
-- 2 = Black Heart
-- 3 = Eternal Heart
-- 4 = Golden Heart
-- 5 = Bone Heart
-- 6 = Rotten Heart
-- 7 = Lil Clot

CustomHealthAPI.PersistentData.IgnoreSumptoriumHandling = CustomHealthAPI.PersistentData.IgnoreSumptoriumHandling or false
CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey = CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey or {}
CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType or {}
CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey or {}

function CustomHealthAPI.Helper.AddPreventSumptoriumReloadOnRecallBugCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_GAME_EXIT, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.PreventSumptoriumReloadOnRecallBugCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreventSumptoriumReloadOnRecallBugCallback)

function CustomHealthAPI.Helper.RemovePreventSumptoriumReloadOnRecallBugCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_GAME_EXIT, CustomHealthAPI.Mod.PreventSumptoriumReloadOnRecallBugCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreventSumptoriumReloadOnRecallBugCallback)

function CustomHealthAPI.Mod:PreventSumptoriumReloadOnRecallBugCallback(shouldSave)
	-- fixin basegame bugs woooooooo
	for _, clot in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY)) do
		clot:ToFamiliar().State = 0
	end
end

function CustomHealthAPI.Helper.AddSumptoriumPreSpawnCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_ENTITY_SPAWN, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.SumptoriumPreSpawnCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddSumptoriumPreSpawnCallback)

function CustomHealthAPI.Helper.RemoveSumptoriumPreSpawnCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, CustomHealthAPI.Mod.SumptoriumPreSpawnCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveSumptoriumPreSpawnCallback)

local keyOfNextOverlapClotSpawned = nil
function CustomHealthAPI.Mod:SumptoriumPreSpawnCallback(typ, var, subt, pos, vel, spawner, seed)
	if typ == EntityType.ENTITY_FAMILIAR and 
	   var == FamiliarVariant.BLOOD_BABY
	then
		if subt >= 900 and subt <= 906 then
			keyOfNextOverlapClotSpawned = nil
			return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, subt - 900, seed}
		end
		
		if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[subt] then
			keyOfNextOverlapClotSpawned = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[subt]
			return {EntityType.ENTITY_FAMILIAR, 
			        FamiliarVariant.BLOOD_BABY, 
			        CustomHealthAPI.PersistentData.HealthDefinitions[keyOfNextOverlapClotSpawned].SumptoriumSubType, 
			        seed}
		end
		
		if CustomHealthAPI.PersistentData.IgnoreSumptoriumHandling then
			keyOfNextOverlapClotSpawned = nil
			return
		end
		
		if spawner and 
		   spawner.Type == EntityType.ENTITY_PLAYER and 
		   CustomHealthAPI.PersistentData.SaveDataLoaded
		then
			--WHY IS PLAYER:ISCOOPGHOST() NIL WHEN USING SPAWNER:TOPLAYER() HERE WHAT THE FUCK
			local player
			for i = 0, Game():GetNumPlayers() - 1 do
				local p = Isaac.GetPlayer(i)
				local subp = p:GetSubPlayer()
				if p.Index == spawner.Index and p.InitSeed == spawner.InitSeed then
					player = p
					break
				end
				if subp ~= nil and subp.Index == spawner.Index and subp.InitSeed == spawner.InitSeed then
					player = subp
					break
				end
			end
			
			if player ~= nil and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
				local data = player:GetData().CustomHealthAPISavedata
				if subt == 0 or subt == 6 then
					local redMasks = data.RedHealthMasks
					
					local earliestKey
					for i = #redMasks, 1, -1 do
						local mask = redMasks[i]
						local doneSearching = false
						for j = #mask, 1, -1 do
							local health = mask[j]
							earliestKey = health.Key
							health.HP = health.HP - 1
							if health.HP <= 0 then
								table.remove(mask, j)
							end
							doneSearching = true
							break
						end
						if doneSearching then break end
					end
					
					player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
					player:GetData().CustomHealthAPIOtherData.SpawningSumptorium = true
					
					CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
					
					player:GetData().CustomHealthAPIOtherData.SpawningSumptorium = nil
					
					if earliestKey == nil then
						keyOfNextOverlapClotSpawned = nil
						return
					end
					
					local newSubt = CustomHealthAPI.PersistentData.HealthDefinitions[earliestKey].SumptoriumSubType
					if newSubt ~= nil then
						keyOfNextOverlapClotSpawned = nil
						if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[earliestKey] then
							keyOfNextOverlapClotSpawned = earliestKey
						end
						return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, newSubt, seed}
					else
						keyOfNextOverlapClotSpawned = nil
						return
					end
				elseif subt == 1 or subt == 2 or subt == 5 then
					local otherMasks = data.OtherHealthMasks
					
					local earliestKey
					for i = #otherMasks, 1, -1 do
						local mask = otherMasks[i]
						local doneSearching = false
						for j = #mask, 1, -1 do
							local health = mask[j]
							if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
								earliestKey = health.Key
								health.HP = health.HP - 1
								if health.HP <= 0 then
									table.remove(mask, j)
								end
								doneSearching = true
								break
							elseif CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
								   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].MaxHP > 0 and
								   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
							then
								earliestKey = health.Key
								table.remove(mask, j)
								doneSearching = true
								break
							end
						end
						if doneSearching then break end
					end
					
					player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
					player:GetData().CustomHealthAPIOtherData.SpawningSumptorium = true
					
					CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
					
					player:GetData().CustomHealthAPIOtherData.SpawningSumptorium = nil
					
					if earliestKey == nil then
						keyOfNextOverlapClotSpawned = nil
						return
					end
					
					local newSubt = CustomHealthAPI.PersistentData.HealthDefinitions[earliestKey].SumptoriumSubType
					if newSubt ~= nil then
						keyOfNextOverlapClotSpawned = nil
						if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[earliestKey] then
							keyOfNextOverlapClotSpawned = earliestKey
						end
						return {EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLOOD_BABY, newSubt, seed}
					else
						keyOfNextOverlapClotSpawned = nil
						return
					end
				end
			end
		end
	end
end

function CustomHealthAPI.Helper.AddSumptoriumInitCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_FAMILIAR_INIT, CustomHealthAPI.Mod.SumptoriumInitCallback, FamiliarVariant.BLOOD_BABY)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddSumptoriumInitCallback)

function CustomHealthAPI.Helper.RemoveSumptoriumInitCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_FAMILIAR_INIT, CustomHealthAPI.Mod.SumptoriumInitCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveSumptoriumInitCallback)

function CustomHealthAPI.Mod:SumptoriumInitCallback(fam)
	local key = CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[fam.SubType]
	
	if keyOfNextOverlapClotSpawned then
		fam:GetData().TrueKeyOfClot = keyOfNextOverlapClotSpawned
	elseif key ~= nil and CustomHealthAPI.PersistentData.SaveDataLoaded then
		local splatColor = CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSplatColor
		if splatColor ~= nil then
			local splat = Isaac.Spawn(EntityType.ENTITY_EFFECT, 
									  EffectVariant.BLOOD_EXPLOSION, 
									  2, 
									  fam.Position, 
									  Vector.Zero, 
									  nil)
			
			splat:GetSprite().Color = splatColor
		end
	end
	keyOfNextOverlapClotSpawned = nil
end

function CustomHealthAPI.Helper.AddSumptoriumUpdateCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_FAMILIAR_UPDATE, CustomHealthAPI.Mod.SumptoriumUpdateCallback, FamiliarVariant.BLOOD_BABY)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddSumptoriumUpdateCallback)

function CustomHealthAPI.Helper.RemoveSumptoriumUpdateCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_FAMILIAR_UPDATE, CustomHealthAPI.Mod.SumptoriumUpdateCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveSumptoriumUpdateCallback)

function CustomHealthAPI.Mod:SumptoriumUpdateCallback(fam)
	if CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[fam.SubType] ~= nil then
		local key = CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[fam.SubType]
		
		if not fam:GetData().Init then
			local splatColor = CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSplatColor
			if splatColor ~= nil then
				fam.SplatColor = splatColor
			end
			
			fam:GetData().Init = true
		end
		
		if fam.State >= 89 and 
		   fam.Player and 
		   (fam.Position - fam.Player.Position):Length() <= 20.0 
		then
			if CustomHealthAPI.Helper.CanPickKey(fam.Player, key) then
				local maxHP = CustomHealthAPI.Library.GetInfoOfKey(key, "MaxHP")
				local typ = CustomHealthAPI.Library.GetInfoOfKey(key, "Type")
				
				if (typ == CustomHealthAPI.Enums.HealthTypes.RED or typ == CustomHealthAPI.Enums.HealthTypes.SOUL) and maxHP <= 1 then
					CustomHealthAPI.Library.AddHealth(fam.Player, key, 2)
				elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
					CustomHealthAPI.Library.AddHealth(fam.Player, key, maxHP)
				else
					CustomHealthAPI.Library.AddHealth(fam.Player, key, 1)
				end
				
				local collectSoundSettings = CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumCollectSoundSettings
				if collectSoundSettings ~= nil then
					SFXManager():Play(collectSoundSettings.ID, 
							 collectSoundSettings.Volume or 1.0, 
							 collectSoundSettings.FrameDelay or 2, 
							 collectSoundSettings.Loop or false, 
							 collectSoundSettings.Pitch or 1.0, 
							 collectSoundSettings.Pan or 0)
				end
				
				fam:Remove()
			end
		end
	elseif fam.SubType >= 0 and fam.SubType <= 6 then
		if fam.State == -2 or fam.State > 0 then
			if fam:GetData().TrueKeyOfClot then
				fam.SubType = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[fam:GetData().TrueKeyOfClot]
			else
				fam.SubType = fam.SubType + 900
			end
		elseif fam:GetData().ReenableVisible then
			fam.Visible = true
			fam:GetData().ReenableVisible = false
		end
	elseif (fam.SubType >= 900 and fam.SubType <= 906) or CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[fam.SubType] then
		if fam.State == -1000 then
			fam.SubType = (fam.SubType - 900) % 7
			fam.Visible = false
			fam:GetData().ReenableVisible = true
		elseif fam.State >= 89 and 
		   fam.Player and 
		   (fam.Position - fam.Player.Position):Length() <= 20.0 
		then
			local overlapKey = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[fam.SubType]
			if overlapKey and CustomHealthAPI.Helper.CanPickKey(fam.Player, overlapKey) then
				local maxHP = CustomHealthAPI.Library.GetInfoOfKey(overlapKey, "MaxHP")
				local typ = CustomHealthAPI.Library.GetInfoOfKey(overlapKey, "Type")
				
				if (typ == CustomHealthAPI.Enums.HealthTypes.RED or typ == CustomHealthAPI.Enums.HealthTypes.SOUL) and maxHP <= 1 then
					CustomHealthAPI.Library.AddHealth(fam.Player, overlapKey, 2)
				elseif typ == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
					CustomHealthAPI.Library.AddHealth(fam.Player, overlapKey, maxHP)
				else
					CustomHealthAPI.Library.AddHealth(fam.Player, overlapKey, 1)
				end
				
				local collectSoundSettings = CustomHealthAPI.PersistentData.HealthDefinitions[overlapKey].SumptoriumCollectSoundSettings
				if collectSoundSettings ~= nil then
					SFXManager():Play(collectSoundSettings.ID, 
							 collectSoundSettings.Volume or 1.0, 
							 collectSoundSettings.FrameDelay or 2, 
							 collectSoundSettings.Loop or false, 
							 collectSoundSettings.Pitch or 1.0, 
							 collectSoundSettings.Pan or 0)
				end
				
				fam:Remove()
			elseif fam.SubType == 900 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "RED_HEART") then
				CustomHealthAPI.Library.AddHealth(fam.Player, "RED_HEART", 1)
				SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES, 1, 0, false, 1.0)
				fam:Remove()
			elseif fam.SubType == 901 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "SOUL_HEART") then
				CustomHealthAPI.Library.AddHealth(fam.Player, "SOUL_HEART", 1)
				SFXManager():Play(SoundEffect.SOUND_HOLY, 1, 0, false, 1.0)
				fam:Remove()
			elseif fam.SubType == 902 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "BLACK_HEART") then
				CustomHealthAPI.Library.AddHealth(fam.Player, "BLACK_HEART", 1)
				SFXManager():Play(SoundEffect.SOUND_UNHOLY, 1, 0, false, 1.0)
				fam:Remove()
			elseif fam.SubType == 903 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "ETERNAL_HEART") then
				CustomHealthAPI.Library.AddHealth(fam.Player, "ETERNAL_HEART", 1)
				SFXManager():Play(SoundEffect.SOUND_SUPERHOLY, 1, 0, false, 1.0)
				fam:Remove()
			elseif fam.SubType == 904 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "GOLDEN_HEART") then
				CustomHealthAPI.Library.AddHealth(fam.Player, "GOLDEN_HEART", 1)
				SFXManager():Play(SoundEffect.SOUND_GOLD_HEART, 1, 0, false, 1.0)
				fam:Remove()
			elseif fam.SubType == 905 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "BONE_HEART") then
				CustomHealthAPI.Library.AddHealth(fam.Player, "BONE_HEART", 1)
				SFXManager():Play(SoundEffect.SOUND_BONE_HEART, 1, 0, false, 1.0)
				fam:Remove()
			elseif fam.SubType == 906 and CustomHealthAPI.Helper.CanPickKey(fam.Player, "ROTTEN_HEART") then
				CustomHealthAPI.Library.AddHealth(fam.Player, "ROTTEN_HEART", 2)
				SFXManager():Play(SoundEffect.SOUND_ROTTEN_HEART, 1, 0, false, 1.0)
				fam:Remove()
			end
		end
	end
	
	if fam.Child and fam.Child.Type == EntityType.ENTITY_EFFECT and fam.Child.Variant == EffectVariant.SPRITE_TRAIL then
		local trail = fam.Child
	
		local color
		if fam.SubType == 0 or fam.SubType == 900 then
			color = Color(0.85, 0.00, 0.00, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 1 or fam.SubType == 901 then
			color = Color(0.30, 0.80, 1.00, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 2 or fam.SubType == 902 then
			color = Color(0.10, 0.10, 0.10, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 3 or fam.SubType == 903 then
			color = Color(1.00, 1.00, 1.00, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 4 or fam.SubType == 904 then
			color = Color(1.00, 0.80, 0.00, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 5 or fam.SubType == 905 then
			color = Color(1.00, 1.00, 1.00, 0.40, 0.00, 0.00, 0.00)
		elseif fam.SubType == 6 or fam.SubType == 906 then
			color = Color(0.85, 0.30, 0.20, 0.40, 0.00, 0.00, 0.00)
		elseif CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[fam.SubType] ~= nil then
			local key = CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[fam.SubType]
			color = CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumTrailColor
		elseif CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[fam.SubType] ~= nil then
			local basegameSubType = (fam.SubType - 900) % 7
			
			if basegameSubType == 0 then
				color = Color(0.85, 0.00, 0.00, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 1 then
				color = Color(0.30, 0.80, 1.00, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 2 then
				color = Color(0.10, 0.10, 0.10, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 3 then
				color = Color(1.00, 1.00, 1.00, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 4 then
				color = Color(1.00, 0.80, 0.00, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 5 then
				color = Color(1.00, 1.00, 1.00, 0.40, 0.00, 0.00, 0.00)
			elseif basegameSubType == 6 then
				color = Color(0.85, 0.30, 0.20, 0.40, 0.00, 0.00, 0.00)
			end
		end
		
		if color ~= nil then
			trail:GetSprite().Color = color
		end
	end
end