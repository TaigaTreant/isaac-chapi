function CustomHealthAPI.Helper.HandleBrittleBonesCollection(player)
	-- convert up to 6 maxhp 0 containers to bone hearts, remove any extra, add more bone hearts if necessary to reach 6 added total
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			table.remove(mask, j)
		end
	end
	
	local maskIndex = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].MaskIndex
	local boneContainingMask = otherMasks[maskIndex]
	local bonePriority = CustomHealthAPI.PersistentData.HealthDefinitions["BONE_HEART"].RemovePriority
	
	local bonesAdded = 0
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				local removePriorityOfHealth = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].RemovePriority
				local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				
				if (maxHpOfHealth <= 0 or removePriorityOfHealth <= bonePriority) and health.Key ~= "BONE_HEART" then
					if i < maskIndex then
						table.remove(mask, j)
						table.insert(boneContainingMask, 1, {Key = "BONE_HEART", HP = 1, HalfCapacity = false})
						bonesAdded = bonesAdded + 1
					elseif i > maskIndex then
						table.remove(mask, j)
						table.insert(boneContainingMask, {Key = "BONE_HEART", HP = 1, HalfCapacity = false})
						bonesAdded = bonesAdded + 1
					else
						mask[j] = {Key = "BONE_HEART", HP = 1, HalfCapacity = false}
						bonesAdded = bonesAdded + 1
					end
				end
			end
		end
	end
	
	if bonesAdded ~= 6 then
		CustomHealthAPI.Helper.UpdateHealthMasks(player, "BONE_HEART", 6 - bonesAdded)
	end
end

function CustomHealthAPI.Helper.HandleBrittleBonesOnBreak(player)
	local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_BRITTLE_BONES)
	local randAngle = rng:RandomFloat() * 360
	for i = 1, 10 do
		local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 
		                         TearVariant.BONE,
		                         0,
		                         player.Position,
		                         Vector.FromAngle(randAngle + 36 * i):Resized(10.0),
		                         player):ToTear()
		
		tear.Height = -23.75
		tear.FallingSpeed = rng:RandomFloat() * 0.1
		tear.FallingAcceleration = 0.0
		tear.CollisionDamage = player.Damage * 2.0 + 22.0
		tear.TearFlags = player.TearFlags | TearFlags.TEAR_BONE
		if player:HasCollectible(CollectibleType.COLLECTIBLE_HAEMOLACRIA) then
			tear.TearFlags = tear.TearFlags | TearFlags.TEAR_BURSTSPLIT
		end
		
		if player.Damage >= 0.0 then
			tear.Scale = 0.31165 * math.sqrt(player.Damage) + player.Damage / 73.8 + 0.74525
		else
			tear.Scale = 0.01
		end
		tear:ResetSpriteScale()
		
		tear:Update()
	end
	
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	local pdata = player:GetData().CustomHealthAPIPersistent
	pdata.FakeBrittleBonesTears = (pdata.FakeBrittleBonesTears or 0) + 1
end

local function tearsUp(firedelay, val)
	local currentTears = 30 / (firedelay + 1)
	local newTears = currentTears + val
	return math.max((30 / newTears) - 1, -0.99)
end

local function getFireRateMultiplier(player)
	local multi = 1
	
	local playerType = player:GetPlayerType()
	if playerType == PlayerType.PLAYER_THEFORGOTTEN or playerType == PlayerType.PLAYER_THEFORGOTTEN_B then
		multi = multi * 0.5
	end
	if playerType == PlayerType.PLAYER_EVE_B then
		multi = multi * 0.66
	end
	if playerType == PlayerType.PLAYER_AZAZEL_B or player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
		multi = multi * 0.33
	elseif playerType == PlayerType.PLAYER_AZAZEL then
		multi = multi * 0.267
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then
		multi = multi * 0.4
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_EVES_MASCARA) then
		multi = multi * 0.66
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_IPECAC) then
		multi = multi * 0.33
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_MONSTROS_LUNG) then
		multi = multi / 4.3
	end
	
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_20_20) then
		if player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) or 
		   player:HasCollectible(CollectibleType.COLLECTIBLE_POLYPHEMUS) 
		then
			multi = multi * 0.42
		elseif player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) or
		       player:GetEffects():HasNullEffect(NullItemID.ID_REVERSE_HANGED_MAN)
		then
			multi = multi * 0.51
		end
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then
		multi = multi * 5.5
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY_2) then
		multi = multi * 0.66
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) then
		multi = multi * 4
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_BERSERK) then
		multi = multi * 0.5
	end
	
	if player:GetEffects():HasNullEffect(NullItemID.ID_REVERSE_CHARIOT) then
		multi = multi * 4
	end
	
	if player:GetData().CustomHealthAPIOtherData then
		local odata = player:GetData().CustomHealthAPIOtherData
		if not REPENTOGON or CustomHealthAPI.PersistentData.DoManualHallowedGroundChecking then
			if (odata.InHallowAura or 0) > 0 or 
			   (odata.InHallowDipAura or 0) > 0 or 
			   (odata.InBethlehemAura or 0) > 0 or
			   (odata.InHallowSpellAura or 0) > 0
			then
				multi = multi * 2.5
			end
		end
		
		if player:HasCollectible(CollectibleType.COLLECTIBLE_EPIPHORA) then
			local fireDirection = player:GetFireDirection()
			if fireDirection == Direction.NO_DIRECTION or
			   (odata.PreviousEpiphoraDirection ~= Direction.NO_DIRECTION and fireDirection ~= odata.PreviousEpiphoraDirection)
			then
				odata.EpiphoraStart = Game():GetFrameCount()
			elseif Game():GetFrameCount() - (odata.EpiphoraStart or 0) >= 270 then
				multi = multi * 2
			elseif Game():GetFrameCount() - (odata.EpiphoraStart or 0) >= 180 then
				multi = multi * 1.66
			elseif Game():GetFrameCount() - (odata.EpiphoraStart or 0) >= 90 then
				multi = multi * 1.33
			end
			odata.PreviousEpiphoraDirection = fireDirection
		end
	end
	
	if REPENTOGON and not CustomHealthAPI.PersistentData.DoManualHallowedGroundChecking then
		if player:GetHallowedGroundCountdown() > 0 then
			multi = multi * 2.5
		end
	end
	
	-- fuck the d8 in particular
	
	return multi
end

if REPENTOGON then

if CustomHealthAPI.PersistentData.DoManualHallowedGroundChecking then

function CustomHealthAPI.Helper.AddHallowPoopCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_GRID_ENTITY_POOP_UPDATE, CustomHealthAPI.Mod.HallowPoopCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHallowPoopCallback)

function CustomHealthAPI.Helper.RemoveHallowPoopCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_GRID_ENTITY_POOP_UPDATE, CustomHealthAPI.Mod.HallowPoopCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHallowPoopCallback)

function CustomHealthAPI.Mod:HallowPoopCallback(poop)
	if poop:GetVariant() == 6 and poop.State ~= 1000 then
		for i = 0, Game():GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(i)
			
			player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
			local data = player:GetData().CustomHealthAPIOtherData
	
			if player.Position:Distance(poop.Position) <= 80.0 then
				data.InHallowAura = 4
			end
		end
	end
end

end

else

--yes this shit is now a chapi feature don't @ me
local cachedHallowPoopIndices = {}
local lastTimeCachedHallowPoops = nil

function CustomHealthAPI.Helper.AddHallowPlayerCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PLAYER_UPDATE, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.HallowPlayerCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHallowPlayerCallback)

function CustomHealthAPI.Helper.RemoveHallowPlayerCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, CustomHealthAPI.Mod.HallowPlayerCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHallowPlayerCallback)

function CustomHealthAPI.Mod:HallowPlayerCallback(player)
	player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
	local data = player:GetData().CustomHealthAPIOtherData
	
	local game = Game()
	local room = game:GetRoom()
	local framecount = Isaac.GetFrameCount()
	local isInHallowAura = false
	
	if lastTimeCachedHallowPoops == nil or lastTimeCachedHallowPoops ~= framecount then
		cachedHallowPoopIndices = {}
		
		for i = 0, room:GetGridSize() do
			local grid = room:GetGridEntity(i)
			if grid and grid:GetType() == GridEntityType.GRID_POOP and grid:GetVariant() == 6 and grid.State ~= 1000 then
				table.insert(cachedHallowPoopIndices, i)
			end
		end
		
		lastTimeCachedHallowPoops = framecount
	end
	
	for _, i in ipairs(cachedHallowPoopIndices) do
		if player.Position:Distance(room:GetGridPosition(i)) <= 80.0 then
			isInHallowAura = true
		end
	end
	
	if isInHallowAura then
		data.InHallowAura = 4
	elseif data.InHallowAura == 4 and framecount % 2 == 1 then
		data.InHallowAura = 3
	end
end

function CustomHealthAPI.Helper.AddHallowRoomCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_NEW_ROOM, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.HallowRoomCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHallowRoomCallback)

function CustomHealthAPI.Helper.RemoveHallowRoomCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, CustomHealthAPI.Mod.HallowRoomCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHallowRoomCallback)

function CustomHealthAPI.Mod:HallowRoomCallback()
	cachedHallowPoopIndices = {}
	lastTimeCachedHallowPoops = nil
end

end

if not REPENTOGON or CustomHealthAPI.PersistentData.DoManualHallowedGroundChecking then

function CustomHealthAPI.Helper.AddHallowPeffectCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PEFFECT_UPDATE, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.HallowPeffectCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHallowPeffectCallback)

function CustomHealthAPI.Helper.RemoveHallowPeffectCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, CustomHealthAPI.Mod.HallowPeffectCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHallowPeffectCallback)

function CustomHealthAPI.Mod:HallowPeffectCallback(player)
	local game = Game()

	player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
	local data = player:GetData().CustomHealthAPIOtherData
	
	data.InHallowAura = math.max((data.InHallowAura or 0) - 1, 0)
	
	local isInHallowDipAura = false
	if game:GetFrameCount() % 3 == 0 then
		local dips = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.DIP, 6, true)
		for _, dip in ipairs(dips) do
			if player.Position:Distance(dip.Position) < 33.33 then
				isInHallowDipAura = true
			end
		end
	end
	
	if isInHallowDipAura then
		data.InHallowDipAura = 4
	else
		data.InHallowDipAura = math.max((data.InHallowDipAura or 0) - 1, 0)
	end
	
	local isInBethlehemAura = false
	local stars = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, FamiliarVariant.STAR_OF_BETHLEHEM, -1, true)
	for _, star in ipairs(stars) do
		if player.Position:Distance(star.Position) <= 80.0 then
			isInBethlehemAura = true
		end
	end
	
	if isInBethlehemAura then
		data.InBethlehemAura = 4
	else
		data.InBethlehemAura = math.max((data.InBethlehemAura or 0) - 1, 0)
	end
	
	local isInHallowSpellAura = false
	local spells = Isaac.FindByType(EntityType.ENTITY_POOP, 16, -1, true)
	for _, spell in ipairs(spells) do
		if spell.FrameCount % 3 == 0 and player.Position:Distance(spell.Position) < 79.99999 then
			isInHallowSpellAura = true
		end
	end
	
	if isInHallowSpellAura then
		data.InHallowSpellAura = 4
	else
		data.InHallowSpellAura = math.max((data.InHallowSpellAura or 0) - 1, 0)
	end
end

end

function CustomHealthAPI.Helper.AddBrittleBonesCacheCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_EVALUATE_CACHE, -1 * math.huge, CustomHealthAPI.Mod.BrittleBonesCacheCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddBrittleBonesCacheCallback)

function CustomHealthAPI.Helper.RemoveBrittleBonesCacheCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_EVALUATE_CACHE, CustomHealthAPI.Mod.BrittleBonesCacheCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveBrittleBonesCacheCallback)

function CustomHealthAPI.Mod:BrittleBonesCacheCallback(player, flag)
	player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
	local pdata = player:GetData().CustomHealthAPIPersistent
	
	if flag == CacheFlag.CACHE_FIREDELAY and pdata.FakeBrittleBonesTears ~= nil and pdata.FakeBrittleBonesTears > 0 then
		local fireRateUp = 0.4 * pdata.FakeBrittleBonesTears * getFireRateMultiplier(player)
		
		local maxFireDelay = player.MaxFireDelay
		if player:HasCollectible(CollectibleType.COLLECTIBLE_HAEMOLACRIA) then
			-- why the fuck is this still a fire delay multiplier when ipecac, 
			-- who stats this directly pulled from, was changed to a fire rate
			-- multiplier, alongside everything else
			maxFireDelay = (maxFireDelay - 11) / 2
		end
		
		maxFireDelay = tearsUp(maxFireDelay, fireRateUp)
		if player:HasCollectible(CollectibleType.COLLECTIBLE_HAEMOLACRIA) then
			maxFireDelay = maxFireDelay * 2 + 11
		end
		
		player.MaxFireDelay = maxFireDelay
	end
end