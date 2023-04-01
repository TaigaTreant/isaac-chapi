CustomHealthAPI.PersistentData.HealthDefinitions = CustomHealthAPI.PersistentData.HealthDefinitions or {}
CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth = CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth or {}
CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth = CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth or {}

function CustomHealthAPI.Library.RegisterRedHealth(key, info)
	if info == nil then
		return
	end

	-- temporary disabling of kind support
	local kind = CustomHealthAPI.Enums.HealthKinds.HEART
	if key == "COIN_HEART" then
		kind = CustomHealthAPI.Enums.HealthKinds.COIN
	end

	CustomHealthAPI.PersistentData.HealthDefinitions[key] = {
		Type = CustomHealthAPI.Enums.HealthTypes.RED, 
		Kind = kind,
		MaxHP = math.max(1, math.floor(info.MaxHP + 0.5)),
		AnimationFilenames = info.AnimationFilenames,
		AnimationNames = info.AnimationNames,
		SortOrder = info.SortOrder,
		AddPriority = info.AddPriority,
		HealFlashRO = info.HealFlashRO, 
		HealFlashGO = info.HealFlashGO, 
		HealFlashBO = info.HealFlashBO,
		ProtectsDealChance = info.ProtectsDealChance,
		PrioritizeHealing = info.PrioritizeHealing,
		PickupEntities = info.PickupEntities,
		--SumptoriumSubType = info.SumptoriumSubType,
		SumptoriumSplatColor = info.SumptoriumSplatColor,
		SumptoriumTrailColor = info.SumptoriumTrailColor,
		SumptoriumCollectSoundSettings = info.SumptoriumCollectSoundSettings
	}
	
	if info.SumptoriumSubType ~= nil then
		if info.SumptoriumSubType >= 0 and info.SumptoriumSubType <= 6 then
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			
			if not CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = info.SumptoriumSubType + 907
				while CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] ~= nil do
					overlapSubtype = overlapSubtype + 7
				end
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = overlapSubtype
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = key
			end
		elseif info.SumptoriumSubType == 7 then
			print("Custom Health API ERROR: Custom health \"" + key + "\" defined with Lil Clot sumptorium subtype.")
		else
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[info.SumptoriumSubType] = key
			
			if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key]
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = nil
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = nil
			end
		end
	end
	
	redHealthOrder = nil
end

function CustomHealthAPI.Library.RegisterSoulHealth(key, info)
	if info == nil then
		return
	end

	-- temporary disabling of kind support
	local kind = CustomHealthAPI.Enums.HealthKinds.HEART

	CustomHealthAPI.PersistentData.HealthDefinitions[key] = {
		Type = CustomHealthAPI.Enums.HealthTypes.SOUL,
		Kind = kind,
		MaxHP = math.max(1, math.floor(info.MaxHP + 0.5)),
		AnimationFilename = info.AnimationFilename,
		AnimationName = info.AnimationName,
		SortOrder = info.SortOrder,
		AddPriority = info.AddPriority,
		HealFlashRO = info.HealFlashRO, 
		HealFlashGO = info.HealFlashGO, 
		HealFlashBO = info.HealFlashBO,
		PrioritizeHealing = info.PrioritizeHealing,
		PickupEntities = info.PickupEntities,
		--SumptoriumSubType = info.SumptoriumSubType,
		SumptoriumSplatColor = info.SumptoriumSplatColor,
		SumptoriumTrailColor = info.SumptoriumTrailColor,
		SumptoriumCollectSoundSettings = info.SumptoriumCollectSoundSettings
	}
	
	if info.SumptoriumSubType ~= nil then
		if info.SumptoriumSubType >= 0 and info.SumptoriumSubType <= 6 then
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			
			if not CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = info.SumptoriumSubType + 907
				while CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] ~= nil do
					overlapSubtype = overlapSubtype + 7
				end
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = overlapSubtype
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = key
			end
		elseif info.SumptoriumSubType == 7 then
			print("Custom Health API ERROR: Custom health \"" + key + "\" defined with Lil Clot sumptorium subtype.")
		else
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[info.SumptoriumSubType] = key
			
			if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key]
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = nil
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = nil
			end
		end
	end
	
	otherHealthOrder = nil
end

function CustomHealthAPI.Library.RegisterHealthContainer(key, info)
	if info == nil then
		return
	end

	-- temporary disabling of kind support
	local kind = CustomHealthAPI.Enums.HealthKinds.HEART
	if key == "EMPTY_COIN_HEART" then
		kind = CustomHealthAPI.Enums.HealthKinds.COIN
	elseif key == "BROKEN_HEART" or key == "BROKEN_COIN_HEART" then
		kind = CustomHealthAPI.Enums.HealthKinds.NONE
	end

	CustomHealthAPI.PersistentData.HealthDefinitions[key] = {
		Type = CustomHealthAPI.Enums.HealthTypes.CONTAINER,
		KindContained = kind,
		MaxHP = math.max(0, math.floor(info.MaxHP + 0.5)),
		AnimationFilename = info.AnimationFilename,
		AnimationName = info.AnimationName,
		SortOrder = info.SortOrder,
		AddPriority = info.AddPriority,
		RemovePriority = info.RemovePriority,
		ForceBleedingIfFilled = info.ForceBleedingIfFilled,
		CanHaveHalfCapacity = info.CanHaveHalfCapacity,
		ProtectsDealChance = info.ProtectsDealChance,
		PickupEntities = info.PickupEntities,
		--SumptoriumSubType = info.SumptoriumSubType,
		SumptoriumSplatColor = info.SumptoriumSplatColor,
		SumptoriumTrailColor = info.SumptoriumTrailColor,
		SumptoriumCollectSoundSettings = info.SumptoriumCollectSoundSettings
	}
	
	if info.SumptoriumSubType ~= nil then
		if info.SumptoriumSubType >= 0 and info.SumptoriumSubType <= 6 then
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			
			if not CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = info.SumptoriumSubType + 907
				while CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] ~= nil do
					overlapSubtype = overlapSubtype + 7
				end
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = overlapSubtype
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = key
			end
		elseif info.SumptoriumSubType == 7 then
			print("Custom Health API ERROR: Custom health \"" + key + "\" defined with Lil Clot sumptorium subtype.")
		else
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[info.SumptoriumSubType] = key
			
			if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key]
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = nil
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = nil
			end
		end
	end
	
	otherHealthOrder = nil
end

function CustomHealthAPI.Library.RegisterHealthOverlay(key, info)
	if info == nil then
		return
	end

	-- temporary disabling of kind support
	local kind = CustomHealthAPI.Enums.HealthKinds.HEART
	
	CustomHealthAPI.PersistentData.HealthDefinitions[key] = {
		Type = CustomHealthAPI.Enums.HealthTypes.OVERLAY,
		Kind = kind,
		AnimationFilename = info.AnimationFilename,
		AnimationName = info.AnimationName,
		IgnoreBleeding = info.IgnoreBleeding,
		PickupEntities = info.PickupEntities,
		--SumptoriumSubType = info.SumptoriumSubType,
		SumptoriumSplatColor = info.SumptoriumSplatColor,
		SumptoriumTrailColor = info.SumptoriumTrailColor,
		SumptoriumCollectSoundSettings = info.SumptoriumCollectSoundSettings
	}
	
	if info.SumptoriumSubType ~= nil then
		if info.SumptoriumSubType >= 0 and info.SumptoriumSubType <= 6 then
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			
			if not CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = info.SumptoriumSubType + 907
				while CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] ~= nil do
					overlapSubtype = overlapSubtype + 7
				end
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = overlapSubtype
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = key
			end
		elseif info.SumptoriumSubType == 7 then
			print("Custom Health API ERROR: Custom health \"" + key + "\" defined with Lil Clot sumptorium subtype.")
		else
			CustomHealthAPI.PersistentData.HealthDefinitions[key].SumptoriumSubType = info.SumptoriumSubType
			CustomHealthAPI.PersistentData.SumptoriumSubTypeToKey[info.SumptoriumSubType] = key
			
			if CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] then
				local overlapSubtype = CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key]
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubTypeToKey[overlapSubtype] = nil
				CustomHealthAPI.PersistentData.BasegameOverlapSumptoriumSubType[key] = nil
			end
		end
	end
end

function CustomHealthAPI.Library.DefineContainerForRedHealth(redKey, containerKey, animationFilename, animationNames)
	if CustomHealthAPI.PersistentData.HealthDefinitions[redKey] and CustomHealthAPI.PersistentData.HealthDefinitions[redKey].Type == CustomHealthAPI.Enums.HealthTypes.RED then
		local redHealth = CustomHealthAPI.PersistentData.HealthDefinitions[redKey]
		redHealth.AnimationFilenames[containerKey] = animationFilename
		redHealth.AnimationNames[containerKey] = animationNames
	end
end

function CustomHealthAPI.Library.RegisterCharacterAsRedHealthless(playertype)
    --disabling as this is currently untested for modded characters
	--CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[playertype] = true
end

function CustomHealthAPI.Library.RegisterCharacterAsConvertingMaxHealth(playertype, keyToConvertTo)
    --disabling as this is currently untested for modded characters
	--CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[playertype] = keyToConvertTo
end

function CustomHealthAPI.Library.GetInfoOfKey(key, var)
	local info = CustomHealthAPI.PersistentData.HealthDefinitions[key]
	if info then
		return info[var]
	end
	return nil
end

function CustomHealthAPI.Library.GetInfoOfHealth(health, var)
	if health and health.Key then
		return CustomHealthAPI.Library.GetInfoOfKey(health.Key, var)
	end
	return nil
end
