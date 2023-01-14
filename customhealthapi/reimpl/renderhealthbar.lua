local healthsprites = {}
CustomHealthAPI.PersistentData.DisableCustomHealthRendering = CustomHealthAPI.PersistentData.DisableCustomHealthRendering or false

function CustomHealthAPI.Helper.AddRenderCustomHealthCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_RENDER, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.RenderCustomHealthCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddRenderCustomHealthCallback)

function CustomHealthAPI.Helper.RemoveRenderCustomHealthCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_RENDER, CustomHealthAPI.Mod.RenderCustomHealthCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveRenderCustomHealthCallback)

function CustomHealthAPI.Mod:RenderCustomHealthCallback()
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitialized()
	CustomHealthAPI.Helper.CheckSubPlayerInfo()
	CustomHealthAPI.Helper.RenderCustomHealth()
end

function CustomHealthAPI.Helper.AddRenderCustomHealthOfStrawmanCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PLAYER_RENDER, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.RenderCustomHealthOfStrawmanCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddRenderCustomHealthOfStrawmanCallback)

function CustomHealthAPI.Helper.RemoveRenderCustomHealthOfStrawmanCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PLAYER_RENDER, CustomHealthAPI.Mod.RenderCustomHealthOfStrawmanCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveRenderCustomHealthOfStrawmanCallback)

function CustomHealthAPI.Mod:RenderCustomHealthOfStrawmanCallback(player, renderOffset)
	if CustomHealthAPI.PersistentData.DisableCustomHealthRendering or
	   Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD) or
	   (StageAPI ~= nil and StageAPI.PlayingBossSprite) or
	   not Game():GetHUD():IsVisible()
	then
		return
	end
	
	local rendermode = Game():GetRoom():GetRenderMode()
	if rendermode ~= RenderMode.RENDER_NORMAL and rendermode ~= RenderMode.RENDER_WATER_ABOVE then
		return
	end
	
	CustomHealthAPI.Helper.RenderShardOfGlass(player, renderOffset)

	if player.Parent ~= nil then
		local playerType = player:GetPlayerType()

		if not (player:IsCoopGhost() or CustomHealthAPI.Helper.IsFoundSoul(player)) and Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN ~= 0 then
			CustomHealthAPI.Helper.RenderCurseOfTheUnknown(player, -2, renderOffset)
		elseif playerType == PlayerType.PLAYER_KEEPER or playerType == PlayerType.PLAYER_KEEPER_B then
			CustomHealthAPI.Helper.RenderKeeperHealth(player, -2, renderOffset)
			CustomHealthAPI.Helper.RenderHolyMantle(player, -2, renderOffset)
		elseif playerType == PlayerType.PLAYER_THELOST or playerType == PlayerType.PLAYER_THELOST_B then
			CustomHealthAPI.Helper.RenderHolyMantle(player, -2, renderOffset)
		elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) or player:IsCoopGhost() or CustomHealthAPI.Helper.IsFoundSoul(player) then
			--do nothing
		else
			CustomHealthAPI.Helper.CheckIfHealthOrderSet()
			CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
			CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
			CustomHealthAPI.Helper.RenderCustomHealthOfPlayer(player, -2, false, renderOffset)
			CustomHealthAPI.Helper.RenderHolyMantle(player, -2, renderOffset)
		end
		
		if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN == 0 then
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HP_BAR)
			for _, callback in ipairs(callbacks) do
				callback.Function(player, -2, renderOffset)
			end
		end
	end
end

function CustomHealthAPI.Helper.GetCurrentRedHealthForRendering(player)
	local order = CustomHealthAPI.Helper.GetRedHealthOrder()
	
	local currentRedHealth = {}
	for i = 1, #order do
		local mask = CustomHealthAPI.Helper.GetRedHealthMask(player, i)
		for j = 1, #mask do
			table.insert(currentRedHealth, mask[j])
		end
	end
	
	return currentRedHealth
end

function CustomHealthAPI.Helper.GetCurrentOtherHealthForRendering(player)
	local order = CustomHealthAPI.Helper.GetOtherHealthOrder()
	
	local currentOtherHealth = {}
	for i = 1, #order do
		local mask = CustomHealthAPI.Helper.GetOtherHealthMask(player, i)
		for j = 1, #mask do
			table.insert(currentOtherHealth, mask[j])
		end
	end
	
	return currentOtherHealth
end

function CustomHealthAPI.Helper.GetEternalRenderIndex(player)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	local redOrder = {}
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			table.insert(redOrder, {i, j})
		end
	end
	
	local healthOrder = {}
	local redIndex = 1
	local lastRedIndex = 1
	local lastInitialEmptyIndex = 1
	local encounteredNonEmpty = false
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = 1, #mask do
			local health = mask[j]
			local key = health.Key
			
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				table.insert(healthOrder, {Red = redOrder[redIndex], Other = {i, j}})
				if redOrder[redIndex] ~= nil then lastRedIndex = #healthOrder end
				redIndex = redIndex + 1
			elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
				table.insert(healthOrder, {Red = nil, Other = {i, j}})
			end
			
			if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP <= 0 and
			   not encounteredNonEmpty
			then
				lastInitialEmptyIndex = #healthOrder
			else
				encounteredNonEmpty = true
			end
		end
	end
	
	return math.max(lastRedIndex, lastInitialEmptyIndex)
end

function CustomHealthAPI.Helper.GetGoldenRenderMask(player)
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	local redOrder = {}
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = 1, #mask do
			table.insert(redOrder, {i, j})
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
	
	local numGoldHearts = data.Overlays["GOLDEN_HEART"]
	local goldMask = {}
	for i = #healthOrder, 1, -1 do
		if numGoldHearts <= 0 then
			break
		end
		
		local redIndices = healthOrder[i].Red
		local otherIndices = healthOrder[i].Other
		
		local health = otherMasks[otherIndices[1]][otherIndices[2]]
		local key = health.Key
		
		if CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
		   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
		   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP == 0 and 
		   redIndices ~= nil
		then
			goldMask[i] = true
			numGoldHearts = numGoldHearts - 1
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and
			   CustomHealthAPI.PersistentData.HealthDefinitions[key].MaxHP > 0 
		then
			goldMask[i] = true
			numGoldHearts = numGoldHearts - 1
		elseif CustomHealthAPI.PersistentData.HealthDefinitions[key].Type == CustomHealthAPI.Enums.HealthTypes.SOUL then
			goldMask[i] = true
			numGoldHearts = numGoldHearts - 1
		end
	end
	
	return goldMask
end

function CustomHealthAPI.Helper.GetHealthSprite(filename)
	if healthsprites[filename] ~= nil then
		return healthsprites[filename]
	else
		healthsprites[filename] = Sprite()
		healthsprites[filename]:Load(filename, true)
		return healthsprites[filename]
	end
end

function CustomHealthAPI.Helper.RenderHealth(sprite, player, playerSlot, i, renderOffset, numOtherHearts, offset, ignoreEsauFlipX)
	local bottomRight = Game():GetRoom():GetRenderSurfaceTopLeft() * 2 + Vector(442,286) -- thank-q stageapi
	local hudOffset = Options.HUDOffset * 10
	local heartDistanceX = CustomHealthAPI.Constants.HEART_PIXEL_WIDTH_DEFAULT
	local heartDistanceY = CustomHealthAPI.Constants.HEART_PIXEL_HEIGHT_DEFAULT

	local offset = offset or Vector.Zero
	sprite.FlipX = false
	if playerSlot == 0 then -- Player 1
		sprite:Render(Vector(48 + hudOffset * 2 + heartDistanceX * (i % 6), 
		                     12 + math.floor(hudOffset * 2.4 + 0.5) / 2 + heartDistanceY * math.floor(i / 6)) + offset, 
		              Vector.Zero, Vector.Zero)
	elseif playerSlot == 1 then -- Player 2
		sprite:Render(Vector(bottomRight.X - 111 - math.floor(hudOffset * 2.4 + 0.5) + heartDistanceX * (i % 3), 
		                     12 + math.floor(hudOffset * 2.4 + 0.5) / 2 + heartDistanceY * math.floor(i / 3)) + offset, 
		              Vector.Zero, Vector.Zero)
	elseif playerSlot == 2 then -- Player 3
		sprite:Render(Vector(58 + math.floor(hudOffset * 2.2 + 0.5) + heartDistanceX * (i % 3), 
		                     bottomRight.Y - 27 - math.floor(hudOffset * 1.2 + 0.5) / 2 + heartDistanceY * math.floor(i / 3)) + offset, 
		              Vector.Zero, Vector.Zero)
	elseif playerSlot == 3 then -- Player 4
		sprite:Render(Vector(bottomRight.X - 119 - math.floor(hudOffset * 1.6 + 0.5) + heartDistanceX * (i % 3), 
		                     bottomRight.Y - 27 - math.floor(hudOffset * 1.2 + 0.5) / 2 + heartDistanceY * math.floor(i / 3)) + offset, 
		              Vector.Zero, Vector.Zero)
	elseif playerSlot == -1 then -- Esau
		if not ignoreEsauFlipX then
			sprite.FlipX = true
		end
		sprite:Render(Vector(bottomRight.X - 48 - math.floor(hudOffset * 1.6 + 0.5) - heartDistanceX * (i % 6), 
		                     bottomRight.Y - 27 - math.floor(hudOffset * 1.2 + 0.5) / 2 + heartDistanceY * math.floor(i / 6)) + offset, 
		              Vector.Zero, Vector.Zero)
	elseif playerSlot == -2 then -- Soulstones / Strawman / etc.
		local centerPosition = Isaac.WorldToScreen(player.Position) - Game():GetRoom():GetRenderScrollOffset()
		local heartPosition = centerPosition + 
		                      Vector((i % 3) * heartDistanceX, math.floor(i / 3) * heartDistanceY) + 
		                      Vector(-5 * (math.min(numOtherHearts, 6) - 1), -30) + 
		                      renderOffset + offset
		sprite:Render(heartPosition, Vector.Zero, Vector.Zero)
	end
end

function CustomHealthAPI.Helper.CheckFadedHealth(player, isSubPlayer)
	return player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) or isSubPlayer or player:GetPlayerType() == PlayerType.PLAYER_JACOB2_B
end

function CustomHealthAPI.Helper.CheckLeakingHealth(healthDefinition, hasRedHealth, player, redHealthIndex)
	local isTaintedMaggie = CustomHealthAPI.Helper.PlayerIsTaintedMaggie(player)
	local isSoulHeart = healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.SOUL
	local isBleedingContainer = hasRedHealth and 
	                            ((redHealthIndex > 2 and not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)) or redHealthIndex > 3)
	
	local maggyBleeding = isTaintedMaggie and (isSoulHeart or isBleedingContainer)
	local forcedBleeding = healthDefinition.ForceBleedingIfFilled and hasRedHealth
	local ignoreBleeding = healthDefinition.IgnoreBleeding
	
	local inDanger
	local playertype = player:GetPlayerType()
	if playertype == PlayerType.PLAYER_KEEPER or playertype == PlayerType.PLAYER_KEEPER_B then
		inDanger = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) <= 1
	else
		inDanger = CustomHealthAPI.Helper.GetTotalHP(player) <= 1
	end
	
	return (maggyBleeding or forcedBleeding) and not inDanger and not ignoreBleeding
end

function CustomHealthAPI.Helper.CheckDangerHealth(player, isSubPlayer)
	local playertype = player:GetPlayerType()
	if playertype == PlayerType.PLAYER_KEEPER or playertype == PlayerType.PLAYER_KEEPER_B then
		local numRed = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
		return numRed == 1 and
		       not player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) and
		       not isSubPlayer
	else
		local numEternal = player:GetData().CustomHealthAPISavedata.Overlays["ETERNAL_HEART"]
		return CustomHealthAPI.Helper.GetTotalHP(player) + numEternal == 1 and
		       not player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) and
		       not isSubPlayer
	end
end

function CustomHealthAPI.Helper.GetHealthColor(healthDefinition, hasRedHealth, redKey, player, healthSlot, redHealthIndex, isGolden, isSubPlayer)
	local data = player:GetData().CustomHealthAPIOtherData
	local shouldRedFlash = data ~= nil and data.RedFlash ~= nil and data.RedFlash > 0
	local shouldSoulFlash = data ~= nil and data.SoulFlash ~= nil and data.SoulFlash > 0
	local shouldGoldFlash = data ~= nil and data.GoldFlash ~= nil and data.GoldFlash > 0
	
	local A = (CustomHealthAPI.Helper.CheckFadedHealth(player, isSubPlayer) and 0.3) or 1.0
	
	local color = Color(1.0, 1.0, 1.0, A, 0/255, 0/255, 0/255)
	if CustomHealthAPI.Helper.CheckDangerHealth(player, isSubPlayer) then
		if healthSlot == 1 then
			color = Color.Lerp(Color(1.0, 1.0, 1.0, A, 0/255, 0/255, 0/255), 
			                   Color(1.0, 1.0, 1.0, A, 255/255, 0/255, 0/255), 
							   math.max(0, ((Game():GetFrameCount() % 45) - 9) / 9 * -1))
		end
	elseif CustomHealthAPI.Helper.CheckLeakingHealth(healthDefinition, hasRedHealth, player, redHealthIndex) then
		local pulseHighColor = Color(0.8, 0.8, 0.8, A, 25/255, 0/255, 0/255)
		local pulseLowColor = Color(0.5, 0.5, 0.5, A, 0/255, 0/255, 0/255)

		pulseHighColor:SetColorize(1, 1, 1, 0.5)
		pulseLowColor:SetColorize(1, 1, 1, 0.6)
		
		color = Color.Lerp(pulseLowColor, 
		                   pulseHighColor, 
		                   (math.sin(Game():GetFrameCount() / 9.55) + 1) / 2)
	end
	
	if isGolden and shouldGoldFlash then
		color.RO = color.RO + 128/255
		color.GO = color.GO + 100/255
		color.BO = color.BO + 20/255
	elseif hasRedHealth and shouldRedFlash then
		local redHealthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[redKey]
		color.RO = color.RO + redHealthDefinition.HealFlashRO
		color.GO = color.GO + redHealthDefinition.HealFlashGO
		color.BO = color.BO + redHealthDefinition.HealFlashBO
	elseif healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.SOUL and shouldSoulFlash then
		color.RO = color.RO + healthDefinition.HealFlashRO
		color.GO = color.GO + healthDefinition.HealFlashGO
		color.BO = color.BO + healthDefinition.HealFlashBO
	end
	
	return color
end

function CustomHealthAPI.Helper.RenderCustomHealthOfPlayer(player, playerSlot, isSubPlayer, renderOffset)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then return end

	local currentRedHealth = CustomHealthAPI.Helper.GetCurrentRedHealthForRendering(player)
	local currentOtherHealth = CustomHealthAPI.Helper.GetCurrentOtherHealthForRendering(player)
	
	local eternalIndex = CustomHealthAPI.Helper.GetEternalRenderIndex(player)
	local goldenMask = CustomHealthAPI.Helper.GetGoldenRenderMask(player)
	
	local data = player:GetData().CustomHealthAPISavedata
	local redHealthIndex = 1
	local otherHealthIndex = 1
	while currentOtherHealth[otherHealthIndex] ~= nil do
		local animationFilename = nil
		local animationName = nil
		
		local health = currentOtherHealth[otherHealthIndex]
		local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
		local hasRedHealth = false
		local redKey = nil
		local redHealth = nil
		
		local updateRedHealthIndex = false
		if healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
			animationFilename = healthDefinition.AnimationFilename
			animationName = healthDefinition.AnimationName
			
			redHealth = currentRedHealth[redHealthIndex]
			if redHealth ~= nil then
				local redHealthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[redHealth.Key]
				local redToOtherNames = redHealthDefinition.AnimationNames
				
				if redToOtherNames[health.Key] ~= nil then
					local names = redToOtherNames[health.Key]
					
					local hp = redHealth.HP
					while names[hp] == nil and hp > 0 do
						hp = hp - 1
					end
					
					if names[hp] == nil then
						print("Custom Health API ERROR: CustomHealthAPI.Helper.RenderCustomHealthOfPlayer; No animation name associated to health of red key " ..
						      redHealth.Key .. 
						      ", other key " .. 
						      health.Key .. 
						      " and HP " .. 
						      tostring(redHealth.HP) .. 
						      ".")
					    return
					end
					
					animationFilename = redHealthDefinition.AnimationFilenames[health.Key]
					animationName = names[hp]
					
					hasRedHealth = true
					redKey = redHealth.Key
				end
				
				updateRedHealthIndex = true
			end
		else
			animationFilename = healthDefinition.AnimationFilename
			
			local hp = health.HP
			while healthDefinition.AnimationName[hp] == nil and hp > 0 do
				hp = hp - 1
			end
			
			if healthDefinition.AnimationName[hp] == nil then
				print("Custom Health API ERROR: CustomHealthAPI.Helper.RenderCustomHealthOfPlayer; No animation name associated to health of other key " .. 
				      health.Key .. " and HP " .. tostring(health.HP) .. ".")
			    return
			end
			
			animationName = healthDefinition.AnimationName[hp]
		end
		
		if animationName ~= nil then
			local filename = animationFilename
			local animname = animationName
			local color = CustomHealthAPI.Helper.GetHealthColor(healthDefinition, hasRedHealth, redKey, player, otherHealthIndex, redHealthIndex, goldenMask[otherHealthIndex], isSubPlayer)
			
			local prevent = false
			local healthIndex = otherHealthIndex - 1 + ((isSubPlayer and 6) or 0)
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HEART)
			for _, callback in ipairs(callbacks) do
				returnTable = callback.Function(player, healthIndex, health, redHealth, filename, animname, Color.Lerp(color, Color(1,1,1,1,0,0,0), 0))
				if returnTable ~= nil then
					if returnTable.Prevent == true then
						prevent = true
					end
					if returnTable.Index ~= nil then
						healthIndex = returnTable.Index
					end
					if returnTable.AnimationFilename ~= nil then
						filename = returnTable.AnimationFilename
					end
					if returnTable.AnimationName ~= nil then
						animname = returnTable.AnimationName
					end
					if returnTable.Color ~= nil then
						color = returnTable.Color
					end
					break
				end
			end
			
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
			healthSprite:Play(animname, true)
			healthSprite.Color = color
			
			if not prevent then
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderOffset, #currentOtherHealth)
			end
		end
		
		if otherHealthIndex == eternalIndex and data.Overlays["ETERNAL_HEART"] > 0 then
			local eternalDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["ETERNAL_HEART"]
			
			local filename = eternalDefinition.AnimationFilename
			local animname = eternalDefinition.AnimationName
			local color = CustomHealthAPI.Helper.GetHealthColor(healthDefinition, hasRedHealth, redKey, player, otherHealthIndex, redHealthIndex, goldenMask[otherHealthIndex], isSubPlayer)
			
			local prevent = false
			local healthIndex = otherHealthIndex - 1 + ((isSubPlayer and 6) or 0)
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HEART)
			for _, callback in ipairs(callbacks) do
				returnTable = callback.Function(player, healthIndex, {Key = "ETERNAL_HEART", HP = 1}, nil, filename, animname, Color.Lerp(color, Color(1,1,1,1,0,0,0), 0))
				if returnTable ~= nil then
					if returnTable.Prevent == true then
						prevent = true
					end
					if returnTable.Index ~= nil then
						healthIndex = returnTable.Index
					end
					if returnTable.AnimationFilename ~= nil then
						filename = returnTable.AnimationFilename
					end
					if returnTable.AnimationName ~= nil then
						animname = returnTable.AnimationName
					end
					if returnTable.Color ~= nil then
						color = returnTable.Color
					end
					break
				end
			end
			
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
			healthSprite:Play(animname, true)
			healthSprite.Color = color
			
			if not prevent then
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderOffset, #currentOtherHealth)
			end
		end
		
		if updateRedHealthIndex then
			redHealthIndex = redHealthIndex + 1
		end
		otherHealthIndex = otherHealthIndex + 1
	end
	
	for i = #currentOtherHealth, 1, -1 do
		if goldenMask[i] then
			local goldenDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["GOLDEN_HEART"]
			
			local filename = goldenDefinition.AnimationFilename
			local animname = goldenDefinition.AnimationName
			local color = Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255)
			
			local prevent = false
			local healthIndex = i - 1 + ((isSubPlayer and 6) or 0)
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HEART)
			for _, callback in ipairs(callbacks) do
				returnTable = callback.Function(player, healthIndex, {Key = "GOLDEN_HEART", HP = 1}, nil, filename, animname, Color.Lerp(color, Color(1,1,1,1,0,0,0), 0))
				if returnTable ~= nil then
					if returnTable.Prevent == true then
						prevent = true
					end
					if returnTable.Index ~= nil then
						healthIndex = returnTable.Index
					end
					if returnTable.AnimationFilename ~= nil then
						filename = returnTable.AnimationFilename
					end
					if returnTable.AnimationName ~= nil then
						animname = returnTable.AnimationName
					end
					if returnTable.Color ~= nil then
						color = returnTable.Color
					end
					break
				end
			end
			
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
			healthSprite:Play(animname, true)
			healthSprite.Color = color
			
			if not prevent then
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderOffset, #currentOtherHealth)
			end
		end
	end
	
	if player:GetSubPlayer() ~= nil and not isSubPlayer	then
		CustomHealthAPI.Helper.RenderCustomHealthOfPlayer(player:GetSubPlayer(), playerSlot, true)
	end
end

function CustomHealthAPI.Helper.RenderKeeperHealth(player, playerSlot, renderOffset)
	local numRed = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	local numMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
	local numBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	local numGolden = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player) -- ??? why does this work in basegame
	
	local redToRender = numRed
	local maxToRender = numMax
	local brokenToRender = numBroken
	local numKeys = math.ceil(numMax / 2) + numBroken
	local otherHealthIndex = 1
	local redHealthIndex = 1
	while redToRender > 0 or maxToRender > 0 or brokenToRender > 0 do
		local healthDefinition
		local hasRedHealth
		local redKey
		local isGolden = numGolden > 0 and math.ceil(numRed / 2) - redHealthIndex  < numGolden
		
		local animationFilename
		local animationName
		
		if redToRender >= 2 then
			healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["EMPTY_COIN_HEART"]
			
			local redHealthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["COIN_HEART"]
			local redToOtherNames = redHealthDefinition.AnimationNames
			local names = redToOtherNames["EMPTY_COIN_HEART"]
			
			animationFilename = redHealthDefinition.AnimationFilenames["EMPTY_COIN_HEART"]
			animationName = names[2]
			
			hasRedHealth = true
			redKey = "COIN_HEART"
			
			redToRender = redToRender - 2
			maxToRender = maxToRender - 2
		elseif redToRender == 1 then
			healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["EMPTY_COIN_HEART"]
			
			local redHealthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["COIN_HEART"]
			local redToOtherNames = redHealthDefinition.AnimationNames
			local names = redToOtherNames["EMPTY_COIN_HEART"]
			
			animationFilename = redHealthDefinition.AnimationFilenames["EMPTY_COIN_HEART"]
			animationName = names[1]
			
			hasRedHealth = true
			redKey = "COIN_HEART"
			
			redToRender = redToRender - 1
			maxToRender = maxToRender - 2
		elseif maxToRender > 0 then
			healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["EMPTY_COIN_HEART"]
			
			animationFilename = healthDefinition.AnimationFilename
			animationName = healthDefinition.AnimationName
			
			hasRedHealth = false
			redKey = nil
			
			maxToRender = maxToRender - 2
		elseif brokenToRender > 0 then
			healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["BROKEN_COIN_HEART"]
			
			animationFilename = healthDefinition.AnimationFilename
			animationName = healthDefinition.AnimationName
			
			hasRedHealth = false
			redKey = nil
			
			brokenToRender = brokenToRender - 1
		end
		
		local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(animationFilename)
		healthSprite:Play(animationName, true)
		healthSprite.Color = CustomHealthAPI.Helper.GetHealthColor(healthDefinition, 
		                                    hasRedHealth, 
		                                    redKey, 
		                                    player, 
		                                    otherHealthIndex, 
		                                    redHealthIndex, 
		                                    isGolden, 
		                                    false)
		CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, otherHealthIndex - 1, renderOffset, numKeys)
		
		otherHealthIndex = otherHealthIndex + 1
		if hasRedHealth then
			redHealthIndex = redHealthIndex + 1
		end
	end
	
	local goldenToRender = numGolden
	for i = math.ceil(numRed / 2), 1, -1 do
		if goldenToRender > 0 then
			local goldenDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["GOLDEN_HEART"]
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(goldenDefinition.AnimationFilename)
			healthSprite:Play(goldenDefinition.AnimationName, true)
			healthSprite.Color = Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255)
			CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, i - 1, renderOffset, numKeys)
			
			goldenToRender = goldenToRender - 1
		end
	end
end

function CustomHealthAPI.Helper.RenderCurseOfTheUnknown(player, playerSlot, renderOffset)
	local filename = "gfx/ui/CustomHealthAPI/hearts.anm2"
	local animname = "CurseHeart"
	local color = Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255)
	
	local prevent = nil
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_UNKNOWN_CURSE)
	for _, callback in ipairs(callbacks) do
		returnTable = callback.Function(player)
		if type(returnTable) == "table" then
			if returnTable.Prevent ~= nil then
				prevent = returnTable.Prevent
			end
			if returnTable.AnimationFilename ~= nil then
				filename = returnTable.AnimationFilename
			end
			if returnTable.AnimationName ~= nil then
				animname = returnTable.AnimationName
			end
			if returnTable.Color ~= nil then
				color = returnTable.Color
			end
			break
		elseif returnTable then
			prevent = returnTable
			break
		end
	end
	
	local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
	healthSprite:Play(animname, true)
	healthSprite.Color = color
	
	if not prevent then
		CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, 0, renderOffset, 1, nil, true)
	end
end

function CustomHealthAPI.Helper.RenderHolyMantle(player, playerSlot, renderOffset)
	if player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_HOLY_MANTLE) >= 1 then
		local filename = "gfx/ui/CustomHealthAPI/hearts.anm2"
		local animname = "HolyMantle"
		local color = Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255)
		
		local playerType = player:GetPlayerType()
		local numKeys
		if playerType == PlayerType.PLAYER_KEEPER or playerType == PlayerType.PLAYER_KEEPER_B then
			numKeys = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2) +
					  CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
		elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) or player:IsCoopGhost() or CustomHealthAPI.Helper.IsFoundSoul(player) then
			numKeys = 0
		else
			numKeys = #CustomHealthAPI.Helper.GetCurrentOtherHealthForRendering(player)
		end
		local keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
		
		if numKeys >= keyLimit and numKeys % 6 == 0 and 
		   not (player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) or player:GetPlayerType() == PlayerType.PLAYER_JACOB2_B) 
		then
			local prevent = false
			local healthIndex = numKeys - 1
			local additionalOffset = Vector(CustomHealthAPI.Constants.HEART_PIXEL_WIDTH_DEFAULT / 2, 0)
			
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HOLY_MANTLE)
			for _, callback in ipairs(callbacks) do
				returnTable = callback.Function(player, healthIndex)
				if returnTable ~= nil then
					if returnTable.Prevent == true then
						prevent = true
					end
					if returnTable.Index ~= nil then
						healthIndex = returnTable.Index
					end
					if returnTable.Offset ~= nil then
						additionalOffset = returnTable.Offset
					end
					if returnTable.AnimationFilename ~= nil then
						filename = returnTable.AnimationFilename
					end
					if returnTable.AnimationName ~= nil then
						animname = returnTable.AnimationName
					end
					if returnTable.Color ~= nil then
						color = returnTable.Color
					end
					break
				end
			end
			
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
			healthSprite:Play(animname, true)
			healthSprite.Color = color
			
			if not prevent then
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderOffset, numKeys, additionalOffset)
			end
		else
			local prevent = false
			local healthIndex = numKeys
			if player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) or player:GetPlayerType() == PlayerType.PLAYER_JACOB2_B then
				healthIndex = 0
			end
			local additionalOffset = Vector.Zero
			
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HOLY_MANTLE)
			for _, callback in ipairs(callbacks) do
				returnTable = callback.Function(player, healthIndex)
				if returnTable ~= nil then
					if returnTable.Prevent == true then
						prevent = true
					end
					if returnTable.Index ~= nil then
						healthIndex = returnTable.Index
					end
					if returnTable.Offset ~= nil then
						additionalOffset = returnTable.Offset
					end
					if returnTable.AnimationFilename ~= nil then
						filename = returnTable.AnimationFilename
					end
					if returnTable.AnimationName ~= nil then
						animname = returnTable.AnimationName
					end
					if returnTable.Color ~= nil then
						color = returnTable.Color
					end
					break
				end
			end
			
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
			healthSprite:Play(animname, true)
			healthSprite.Color = color
			
			if not prevent then
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderOffset, numKeys, additionalOffset)
			end
		end
	end
end

function CustomHealthAPI.Helper.RenderCustomHealth()
	if CustomHealthAPI.PersistentData.DisableCustomHealthRendering or
	   Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD) or
	   (StageAPI ~= nil and StageAPI.PlayingBossSprite) or
	   not Game():GetHUD():IsVisible()
	then
		return
	end

	local renderedPlayerOne = nil
	local renderedPlayerTwo = nil
	local renderedPlayerThree = nil
	local renderedPlayerFour = nil
	local esauToRender = nil

	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local playerType = player:GetPlayerType()
		local controllerIndex = player.ControllerIndex

		if player.Parent ~= nil then
			--is soulstone; do nothing
		elseif controllerIndex == renderedPlayerOne or controllerIndex == renderedPlayerTwo or controllerIndex == renderedPlayerThree or controllerIndex == renderedPlayerFour then
			--do nothing
		else
			local playerSlot = 0
			if renderedPlayerOne then
				playerSlot = 1
			end
			if renderedPlayerTwo then
				playerSlot = 2
			end
			if renderedPlayerThree then
				playerSlot = 3
			end

			
			if not (player:IsCoopGhost() or CustomHealthAPI.Helper.IsFoundSoul(player)) and Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN ~= 0 then
				CustomHealthAPI.Helper.RenderCurseOfTheUnknown(player, playerSlot, Vector.Zero)
			elseif playerType == PlayerType.PLAYER_KEEPER or playerType == PlayerType.PLAYER_KEEPER_B then
				CustomHealthAPI.Helper.RenderKeeperHealth(player, playerSlot, Vector.Zero)
				CustomHealthAPI.Helper.RenderHolyMantle(player, playerSlot, Vector.Zero)
			elseif playerType == PlayerType.PLAYER_THELOST or playerType == PlayerType.PLAYER_THELOST_B then
				CustomHealthAPI.Helper.RenderHolyMantle(player, playerSlot, Vector.Zero)
			elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) or player:IsCoopGhost() or CustomHealthAPI.Helper.IsFoundSoul(player) then
				--do nothing
			else
				CustomHealthAPI.Helper.RenderCustomHealthOfPlayer(player, playerSlot, false, Vector.Zero)
				CustomHealthAPI.Helper.RenderHolyMantle(player, playerSlot, Vector.Zero)
			end
			
			if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN == 0 then
				local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HP_BAR)
				for _, callback in ipairs(callbacks) do
					callback.Function(player, playerSlot, Vector.Zero)
				end
			end

			if renderedPlayerOne == nil then
				renderedPlayerOne = controllerIndex
			elseif renderedPlayerTwo == nil then
				renderedPlayerTwo = controllerIndex
			elseif renderedPlayerThree == nil then
				renderedPlayerThree = controllerIndex
			elseif renderedPlayerFour == nil then
				renderedPlayerFour = controllerIndex
			end

			if playerType == PlayerType.PLAYER_JACOB and esauToRender == nil and player:GetOtherTwin() ~= nil then
				esauToRender = player:GetOtherTwin()
			end
		end
	end

	if esauToRender then
		local esauType = esauToRender:GetPlayerType()
		
		if not (esauToRender:IsCoopGhost() or 
		        CustomHealthAPI.Helper.IsFoundSoul(esauToRender)) and 
		   Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN ~= 0 
		then
			CustomHealthAPI.Helper.RenderCurseOfTheUnknown(esauToRender, -1, Vector.Zero)
		elseif esauType == PlayerType.PLAYER_KEEPER or esauType == PlayerType.PLAYER_KEEPER_B then
			CustomHealthAPI.Helper.RenderKeeperHealth(esauToRender, -1, Vector.Zero)
			CustomHealthAPI.Helper.RenderHolyMantle(esauToRender, -1, Vector.Zero)
		elseif esauType == PlayerType.PLAYER_THELOST or esauType == PlayerType.PLAYER_THELOST_B then
			CustomHealthAPI.Helper.RenderHolyMantle(esauToRender, -1, Vector.Zero)
		elseif CustomHealthAPI.Helper.PlayerIsIgnored(esauToRender) or 
		       esauToRender:IsCoopGhost() or 
		       CustomHealthAPI.Helper.IsFoundSoul(esauToRender) 
		then
			--do nothing
		else
			CustomHealthAPI.Helper.RenderCustomHealthOfPlayer(esauToRender, -1, false, Vector.Zero)
			CustomHealthAPI.Helper.RenderHolyMantle(esauToRender, -1, Vector.Zero)
		end
			
		if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN == 0 then
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HP_BAR)
			for _, callback in ipairs(callbacks) do
				callback.Function(esauToRender, -1, Vector.Zero)
			end
		end
	end
end
