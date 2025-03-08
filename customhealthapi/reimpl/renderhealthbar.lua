local healthsprites = {}
CustomHealthAPI.PersistentData.DisableCustomHealthRendering = CustomHealthAPI.PersistentData.DisableCustomHealthRendering or false
CustomHealthAPI.PersistentData.NumOccupiedPlayerHUDs = 1

if REPENTOGON then
	function CustomHealthAPI.Helper.AddPrePlayerHudRenderHeartsCallback()
	---@diagnostic disable-next-line: param-type-mismatch
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_PLAYERHUD_RENDER_HEARTS, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.PrePlayerHudRenderHeartsCallback, -1)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPrePlayerHudRenderHeartsCallback)

	function CustomHealthAPI.Helper.RemovePrePlayerHudRenderHeartsCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_HEARTS, CustomHealthAPI.Mod.PrePlayerHudRenderHeartsCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePrePlayerHudRenderHeartsCallback)

	function CustomHealthAPI.Mod:PrePlayerHudRenderHeartsCallback()
		return true
	end
end

function CustomHealthAPI.Helper.AddRenderCustomHealthCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_HUD_RENDER or ModCallbacks.MC_POST_RENDER, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.RenderCustomHealthCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddRenderCustomHealthCallback)

function CustomHealthAPI.Helper.RemoveRenderCustomHealthCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_HUD_RENDER or ModCallbacks.MC_POST_RENDER, CustomHealthAPI.Mod.RenderCustomHealthCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveRenderCustomHealthCallback)

function CustomHealthAPI.Mod:RenderCustomHealthCallback()
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitialized()
	CustomHealthAPI.Helper.CheckSubPlayerInfo()
	CustomHealthAPI.Helper.RenderCustomHealth()
end

function CustomHealthAPI.Helper.AddRenderCustomHealthOfStrawmanCallback()
---@diagnostic disable-next-line: param-type-mismatch
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
		CustomHealthAPI.Helper.RenderPlayerHPBar(player, -1)
	end
end

function CustomHealthAPI.Helper.GetCurrentRedHealthForRendering(player)
	local data = player:GetData().CustomHealthAPISavedata
	data.Cached = data.Cached or {}
	if data.Cached.RedHealthInRender then
		return data.Cached.RedHealthInRender
	end
	
	local order = CustomHealthAPI.Helper.GetRedHealthOrder()
	
	local currentRedHealth = {}
	for i = 1, #order do
		local mask = CustomHealthAPI.Helper.GetRedHealthMask(player, i)
		for j = 1, #mask do
			table.insert(currentRedHealth, mask[j])
		end
	end
	
	data.Cached.RedHealthInRender = currentRedHealth
	return currentRedHealth
end

function CustomHealthAPI.Helper.GetCurrentOtherHealthForRendering(player)
	local data = player:GetData().CustomHealthAPISavedata
	data.Cached = data.Cached or {}
	if data.Cached.OtherHealthInRender then
		return data.Cached.OtherHealthInRender
	end
	
	local order = CustomHealthAPI.Helper.GetOtherHealthOrder()
	
	local currentOtherHealth = {}
	for i = 1, #order do
		local mask = CustomHealthAPI.Helper.GetOtherHealthMask(player, i)
		for j = 1, #mask do
			table.insert(currentOtherHealth, mask[j])
		end
	end
	
	data.Cached.OtherHealthInRender = currentOtherHealth
	return currentOtherHealth
end

function CustomHealthAPI.Helper.GetEternalRenderIndex(player)
	local data = player:GetData().CustomHealthAPISavedata
	data.Cached = data.Cached or {}
	if data.Cached.EternalIndex then
		return data.Cached.EternalIndex
	end
	
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
	
	local eternalIndex = math.max(lastRedIndex, lastInitialEmptyIndex)
	data.Cached.EternalIndex = eternalIndex
	return eternalIndex
end

function CustomHealthAPI.Helper.GetGoldenRenderMask(player)
	local data = player:GetData().CustomHealthAPISavedata
	data.Cached = data.Cached or {}
	if data.Cached.GoldenRenderMask then
		return data.Cached.GoldenRenderMask
	end
	
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
	
	data.Cached.GoldenRenderMask = goldMask
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

-- How much the health bars moved between rep and rep+
local REPENTANCE_PLUS_OFFSETS = {
	[0] = Vector(0, 6),   -- P1
	[1] = Vector(-16, 6), -- P2
	[2] = Vector(0, 0),   -- P3
	[3] = Vector(-16, 0), -- P4
}

function CustomHealthAPI.Helper.GetHealthBarPos(player, playerSlot, numOtherHearts)
	local bottomRight = Game():GetRoom():GetRenderSurfaceTopLeft() * 2 + Vector(442,286) -- thank-q stageapi
	local hudOffset = Options.HUDOffset * 10

	local esauFlipped = playerSlot == 4 -- P1's Esau when in the bottom right corner
	if esauFlipped and REPENTANCE_PLUS and CustomHealthAPI.PersistentData.NumOccupiedPlayerHUDs > 3 then
		-- In REP+ P1's Esau's health moves up under Jacob's if there are >3 occupied PlayerHUDs
		esauFlipped = false
	end

	local pos = Vector.Zero

	if playerSlot == -1 then -- Soulstones / Strawman / etc.
		pos = Isaac.WorldToScreen(player.Position) - Game():GetRoom():GetRenderScrollOffset() + Vector(-5 * (math.min(numOtherHearts, 6) - 1), -30)
	elseif playerSlot == 4 and esauFlipped then -- P1's Esau when in the bottom right corner
		pos = Vector(bottomRight.X - 48 - math.floor(hudOffset * 1.6 + 0.5),
		             bottomRight.Y - 27 - math.floor(hudOffset * 1.2 + 0.5) / 2)
	elseif playerSlot % 4 == 0 then -- Player 1
		pos = Vector(48 + hudOffset * 2,
		             12 + math.floor(hudOffset * 2.4 + 0.5) / 2)
	elseif playerSlot % 4 == 1 then -- Player 2
		pos = Vector(bottomRight.X - 111 - math.floor(hudOffset * 2.4 + 0.5),
		             12 + math.floor(hudOffset * 2.4 + 0.5) / 2)
	elseif playerSlot % 4 == 2 then -- Player 3
		pos = Vector(58 + math.floor(hudOffset * 2.2 + 0.5),
		             bottomRight.Y - 27 - math.floor(hudOffset * 1.2 + 0.5) / 2)
	elseif playerSlot % 4 == 3 then -- Player 4
		pos = Vector(bottomRight.X - 119 - math.floor(hudOffset * 1.6 + 0.5),
		             bottomRight.Y - 27 - math.floor(hudOffset * 1.2 + 0.5) / 2)
	end

	if REPENTANCE_PLUS then
		local repPlusOffset = REPENTANCE_PLUS_OFFSETS[playerSlot]
		if playerSlot > 3 and not esauFlipped then  -- Esau, except P1's Esau when in the bottom right corner
			pos = pos + Vector(0, 34)
			repPlusOffset = REPENTANCE_PLUS_OFFSETS[playerSlot-4]
		end
		if repPlusOffset then
			pos = pos + repPlusOffset
		end
	end

	return pos, esauFlipped
end

function CustomHealthAPI.Helper.RenderHealth(sprite, player, playerSlot, i, renderOffset, numOtherHearts, extraOffset, ignoreEsauFlipX)
	renderOffset = renderOffset or Vector.Zero
	extraOffset = extraOffset or Vector.Zero

	local barPos, esauFlipped = CustomHealthAPI.Helper.GetHealthBarPos(player, playerSlot, numOtherHearts)

	local heartDistanceX = CustomHealthAPI.Constants.HEART_PIXEL_WIDTH_DEFAULT
	local heartDistanceY = CustomHealthAPI.Constants.HEART_PIXEL_HEIGHT_DEFAULT

	if esauFlipped then
		heartDistanceX = -heartDistanceX
		extraOffset = Vector(-extraOffset.X, extraOffset.Y)
	end
	sprite.FlipX = esauFlipped and not ignoreEsauFlipX

	-- In REP+, co-op health bars are no longer rendered in rows of 3.
	local numColumns = 6
	if not REPENTANCE_PLUS and playerSlot ~= 0 and playerSlot ~= 4 then
		numColumns = 3
	end
	local heartOffset = Vector(heartDistanceX * (i % numColumns), heartDistanceY * math.floor(i / numColumns))

	sprite:Render(barPos + heartOffset + renderOffset + extraOffset, Vector.Zero, Vector.Zero)
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
	if CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		inDanger = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player) <= 1
	else
		inDanger = CustomHealthAPI.Helper.GetTotalHP(player) <= 1
	end
	
	return (maggyBleeding or forcedBleeding) and not inDanger and not ignoreBleeding
end

function CustomHealthAPI.Helper.CheckDangerHealth(player, isSubPlayer)
	local playertype = player:GetPlayerType()
	if CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
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
	local numOtherHearts = #currentOtherHealth
	
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
			local extraOffset = Vector(0,0)
			
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HEART)
			for _, callback in ipairs(callbacks) do
				local returnTable = callback.Function(player, healthIndex, health, redHealth, filename, animname, Color.Lerp(color, Color(1,1,1,1,0,0,0), 0), extraOffset)
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
					if returnTable.Offset ~= nil then
						extraOffset = returnTable.Offset
					end
					break
				end
			end
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
			
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
			healthSprite:Play(animname, true)
			healthSprite.Color = color
			
			if not prevent then
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderOffset, numOtherHearts, extraOffset)
				
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
				local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HEART)
				for _, callback in ipairs(callbacks) do
					callback.Function(player, playerSlot, healthIndex, health, redHealth, filename, animname, Color.Lerp(color, Color(1,1,1,1,0,0,0), 0))
				end
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
			end
		end
		
		if otherHealthIndex == eternalIndex and data.Overlays["ETERNAL_HEART"] > 0 then
			local eternalDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["ETERNAL_HEART"]
			
			local filename = eternalDefinition.AnimationFilename
			local animname = eternalDefinition.AnimationName
			local color = CustomHealthAPI.Helper.GetHealthColor(healthDefinition, hasRedHealth, redKey, player, otherHealthIndex, redHealthIndex, goldenMask[otherHealthIndex], isSubPlayer)
			
			local prevent = false
			local healthIndex = otherHealthIndex - 1 + ((isSubPlayer and 6) or 0)
			local extraOffset = Vector(0,0)
			
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HEART)
			for _, callback in ipairs(callbacks) do
				local returnTable = callback.Function(player, healthIndex, {Key = "ETERNAL_HEART", HP = 1}, nil, filename, animname, Color.Lerp(color, Color(1,1,1,1,0,0,0), 0), extraOffset)
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
					if returnTable.Offset ~= nil then
						extraOffset = returnTable.Offset
					end
					break
				end
			end
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
			
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
			healthSprite:Play(animname, true)
			healthSprite.Color = color
			
			if not prevent then
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderOffset, numOtherHearts, extraOffset)
				
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
				local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HEART)
				for _, callback in ipairs(callbacks) do
					callback.Function(player, playerSlot, healthIndex, {Key = "ETERNAL_HEART", HP = 1}, nil, filename, animname, Color.Lerp(color, Color(1,1,1,1,0,0,0), 0))
				end
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
			end
		end
		
		if updateRedHealthIndex then
			redHealthIndex = redHealthIndex + 1
		end
		otherHealthIndex = otherHealthIndex + 1
	end
	
	for i = numOtherHearts, 1, -1 do
		if goldenMask[i] then
			local goldenDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["GOLDEN_HEART"]
			
			local filename = goldenDefinition.AnimationFilename
			local animname = goldenDefinition.AnimationName
			local color = Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255)
			
			local prevent = false
			local healthIndex = i - 1 + ((isSubPlayer and 6) or 0)
			local extraOffset = Vector(0,0)
			
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HEART)
			for _, callback in ipairs(callbacks) do
				local returnTable = callback.Function(player, healthIndex, {Key = "GOLDEN_HEART", HP = 1}, nil, filename, animname, Color.Lerp(color, Color(1,1,1,1,0,0,0), 0), extraOffset)
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
					if returnTable.Offset ~= nil then
						extraOffset = returnTable.Offset
					end
					break
				end
			end
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
			
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
			healthSprite:Play(animname, true)
			healthSprite.Color = color
			
			if not prevent then
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderOffset, numOtherHearts, extraOffset)
				
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
				local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HEART)
				for _, callback in ipairs(callbacks) do
					callback.Function(player, playerSlot, healthIndex, {Key = "GOLDEN_HEART", HP = 1}, nil, filename, animname, Color.Lerp(color, Color(1,1,1,1,0,0,0), 0))
				end
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
			end
		end
	end
	
	if player:GetSubPlayer() ~= nil and not isSubPlayer	then
		CustomHealthAPI.Helper.RenderCustomHealthOfPlayer(player:GetSubPlayer(), playerSlot, true)
	end

	return numOtherHearts
end

function CustomHealthAPI.Helper.RenderKeeperHealth(player, playerSlot, renderOffset)
	local numRed = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	local numMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
	local numBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	local numGolden = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player) -- ??? why does this work in basegame
	
	local keeperHealthToRender = {}
	
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
		
		local color = CustomHealthAPI.Helper.GetHealthColor(healthDefinition, 
		                                                    hasRedHealth, 
		                                                    redKey, 
		                                                    player, 
		                                                    otherHealthIndex, 
		                                                    redHealthIndex, 
		                                                    isGolden, 
		                                                    false)
		table.insert(keeperHealthToRender, {AnimationFilename = animationFilename,
		                                    AnimationName = animationName,
		                                    Color = color,
		                                    Index = otherHealthIndex - 1})
		
		otherHealthIndex = otherHealthIndex + 1
		if hasRedHealth then
			redHealthIndex = redHealthIndex + 1
		end
		
		if otherHealthIndex > 24 then
			break
		end
	end
	
	if not REPENTANCE_PLUS and (playerSlot == 1 or playerSlot == 2 or playerSlot == 3 or playerSlot == -1) then
		for i = 7, 0, -1 do
			for j = i * 3 + 1, i * 3 + 3 do
				local keeperHealth = keeperHealthToRender[j]
				if keeperHealth ~= nil then
					local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(keeperHealth.AnimationFilename)
					healthSprite:Play(keeperHealth.AnimationName, true)
					healthSprite.Color = keeperHealth.Color
					CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, keeperHealth.Index, renderOffset, numKeys)
				end
			end
		end
	else
		for i = 3, 0, -1 do
			for j = i * 6 + 1, i * 6 + 6 do
				local keeperHealth = keeperHealthToRender[j]
				if keeperHealth ~= nil then
					local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(keeperHealth.AnimationFilename)
					healthSprite:Play(keeperHealth.AnimationName, true)
					healthSprite.Color = keeperHealth.Color
					CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, keeperHealth.Index, renderOffset, numKeys)
				end
			end
		end
	end
	
	local goldenToRender = numGolden
	for i = math.min(24, math.ceil(numRed / 2)), 1, -1 do
		if goldenToRender > 0 then
			local goldenDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["GOLDEN_HEART"]
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(goldenDefinition.AnimationFilename)
			healthSprite:Play(goldenDefinition.AnimationName, true)
			healthSprite.Color = Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255)
			CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, i - 1, renderOffset, numKeys)
			
			goldenToRender = goldenToRender - 1
		end
	end
	
	return numKeys
end

function CustomHealthAPI.Helper.RenderCurseOfTheUnknown(player, playerSlot, renderOffset)
	local filename = "gfx/ui/CustomHealthAPI/hearts.anm2"
	local animname = "CurseHeart"
	local color = Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255)
	
	local prevent = nil
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_UNKNOWN_CURSE)
	for _, callback in ipairs(callbacks) do
		local returnTable = callback.Function(player)
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
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	
	local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
	healthSprite:Play(animname, true)
	healthSprite.Color = color
	
	if not prevent then
		CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, 0, renderOffset, 1, nil, true)
		
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RENDER_UNKNOWN_CURSE)
		for _, callback in ipairs(callbacks) do
			callback.Function(player, playerSlot)
		end
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	end
end

local function GetHolyMantleIndex(player)
	local playerType = player:GetPlayerType()
	local numKeys, keyLimit
	if CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		numKeys = math.min(24, math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2) +
				               CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player))
		keyLimit = math.min(24, math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2))
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) or player:IsCoopGhost() or CustomHealthAPI.Helper.IsFoundSoul(player) then
		numKeys = 0
		keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
	else
		numKeys = #CustomHealthAPI.Helper.GetCurrentOtherHealthForRendering(player)
		keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
	end

	local hasLostCurse = player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE) or player:GetPlayerType() == PlayerType.PLAYER_JACOB2_B

	if hasLostCurse then
		return 0, false, numKeys
	elseif numKeys >= keyLimit and numKeys % 6 == 0 then
		return numKeys - 1, true, numKeys
	end
	return numKeys, false, numKeys
end

function CustomHealthAPI.Helper.RenderHolyMantle(player, playerSlot, renderOffset)
	if player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_HOLY_MANTLE) >= 1 then
		local filename = "gfx/ui/CustomHealthAPI/hearts.anm2"
		local animname = "HolyMantle"
		local color = Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255)
		
		local prevent = false
		local healthIndex, offsetMantle, numKeys = GetHolyMantleIndex(player)
		local additionalOffset = offsetMantle and Vector(CustomHealthAPI.Constants.HEART_PIXEL_WIDTH_DEFAULT * (REPENTANCE_PLUS and 1 or 0.5), 0) or Vector.Zero
		
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HOLY_MANTLE)
		for _, callback in ipairs(callbacks) do
			local returnTable = callback.Function(player, healthIndex)
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
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
		
		local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
		healthSprite:Play(animname, true)
		healthSprite.Color = color
		
		if not prevent then
			CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderOffset, numKeys, additionalOffset)
			
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
			local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HOLY_MANTLE)
			for _, callback in ipairs(callbacks) do
				callback.Function(player, playerSlot, healthIndex)
			end
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
		end
	end
end

local livesFont = Font()
livesFont:Load("font/pftempestasevencondensed.fnt")
local livesFontColor = KColor(1,1,1,1)

function CustomHealthAPI.Helper.RenderLives(player, playerSlot, renderOffset)
	local numLives = player:GetExtraLives()
	if not REPENTANCE_PLUS and (playerSlot == 1 or playerSlot == 2 or playerSlot == 3 or playerSlot == -1) then -- Players 2-4 + Soulstones / Strawman / etc.
		-- i'm actually surprised to see they don't render extra lives in basegame not gonna lie
		return
	end
	
	local bottomRight = Game():GetRoom():GetRenderSurfaceTopLeft() * 2 + Vector(442,286) -- thank-q stageapi
	local hudOffset = Options.HUDOffset * 10
	local heartDistanceX = CustomHealthAPI.Constants.HEART_PIXEL_WIDTH_DEFAULT
	local heartDistanceY = CustomHealthAPI.Constants.HEART_PIXEL_HEIGHT_DEFAULT

	local hasHolyMantle = player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_HOLY_MANTLE) >= 1
	local numOther
	if CustomHealthAPI.Helper.PlayerIsHealthless(player, true) then
		numOther = 0
	elseif CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		numOther = math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2) + 
		           CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	else
		numOther = #(CustomHealthAPI.Helper.GetCurrentOtherHealthForRendering(player))
	end
	
	local isChance = false
	if REPENTOGON then
		if player:HasChanceRevive() then
			isChance = true
		end
	else
		if player:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) or player:HasTrinket(TrinketType.TRINKET_BROKEN_ANKH) then
			isChance = true
		end
	end
	
	local ignoredHealth = 0
	local overrideLivesCheck = false
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_LIVES)
	for _, callback in ipairs(callbacks) do
		local returnTable = callback.Function(player, numLives, isChance, ignoredHealth)
		if returnTable ~= nil then
			if returnTable.Prevent == true then
				return
			end
			if returnTable.Lives ~= nil then
				numLives = returnTable.Lives
			end
			if returnTable.IsChance ~= nil then
				isChance = returnTable.IsChance
			end
			if returnTable.Force ~= nil then
				overrideLivesCheck = returnTable.Force
			end
			if returnTable.IgnoreNumHearts ~= nil then
				ignoredHealth = returnTable.IgnoreNumHearts
			end
		end
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1

	if numLives <= 0 and not overrideLivesCheck then
		return
	end
	local livesString = "x" .. numLives .. ((isChance and "?") or "")
	
	local numNonIgnoredHealth = math.max(0, numOther - ignoredHealth)
	local numColumns = math.min(numNonIgnoredHealth, 6)
	if hasHolyMantle then
		local mantleIndex, offsetMantle = GetHolyMantleIndex(player)
		if numOther < 6 or (REPENTANCE_PLUS and offsetMantle) then
			numColumns = numColumns + 1
		end
	end
	local numRows = math.floor(math.min(3, (numNonIgnoredHealth - 1) / 6)) / 2
	
	local pos, esauFlipped = CustomHealthAPI.Helper.GetHealthBarPos(player, playerSlot, numOther)
	
	if esauFlipped then
		local livesStringWidth = livesFont:GetStringWidth(livesString)
		pos = pos + Vector(-4 + math.floor(hudOffset * 1.6 + 0.5) - livesStringWidth - heartDistanceX * numColumns,
		                   -10 + math.floor(hudOffset * 1.2 + 0.5) / 2 + 8 * numRows)
		if REPENTANCE_PLUS then
			pos = pos + Vector(-10, -4)
		end
	else
		pos = pos + Vector(-2 + heartDistanceX * numColumns,
		                   -8 + 8 * numRows)
	end
	
	livesFont:DrawString(livesString, pos.X, pos.Y, livesFontColor)
	
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RENDER_LIVES)
	for _, callback in ipairs(callbacks) do
		callback.Function(player, pos, numLives, isChance, livesString)
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
end

function CustomHealthAPI.Helper.RenderPlayerHPBar(player, playerSlot, renderOffset)
	renderOffset = renderOffset or Vector.Zero

	local numOtherHearts = 0

	if not (player:IsCoopGhost() or CustomHealthAPI.Helper.IsFoundSoul(player)) and Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN ~= 0 then
		CustomHealthAPI.Helper.RenderCurseOfTheUnknown(player, playerSlot, renderOffset)
	elseif CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		numOtherHearts = CustomHealthAPI.Helper.RenderKeeperHealth(player, playerSlot, renderOffset)
		CustomHealthAPI.Helper.RenderHolyMantle(player, playerSlot, renderOffset)
		if REPENTOGON then CustomHealthAPI.Helper.RenderLives(player, playerSlot, renderOffset) end
	elseif CustomHealthAPI.Helper.PlayerIsHealthless(player, true) then
		CustomHealthAPI.Helper.RenderHolyMantle(player, playerSlot, renderOffset)
		if REPENTOGON then CustomHealthAPI.Helper.RenderLives(player, playerSlot, renderOffset) end
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) or player:IsCoopGhost() or CustomHealthAPI.Helper.IsFoundSoul(player) then
		--do nothing
		return false
	else
		numOtherHearts = CustomHealthAPI.Helper.RenderCustomHealthOfPlayer(player, playerSlot, false, renderOffset)
		CustomHealthAPI.Helper.RenderHolyMantle(player, playerSlot, renderOffset)
		if REPENTOGON then CustomHealthAPI.Helper.RenderLives(player, playerSlot, renderOffset) end
	end

	if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN == 0 then
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
		local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HP_BAR)
		for _, callback in ipairs(callbacks) do
			callback.Function(player, playerSlot, renderOffset)
		end
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	end

	if REPENTANCE_PLUS or REPENTOGON then
		local barPos, esauFlipped = CustomHealthAPI.Helper.GetHealthBarPos(player, playerSlot, numOtherHearts)
		if REPENTANCE_PLUS and playerSlot > 3 and not esauFlipped then
			local lineSprite = CustomHealthAPI.Helper.GetHealthSprite("gfx/ui/CustomHealthAPI/line.anm2")
			lineSprite:Play(lineSprite:GetDefaultAnimation(), true)
			lineSprite:Render(barPos + Vector(0, -13) + renderOffset)
		end
		if REPENTOGON then
			local hud = Game():GetHUD()
			local playerhud = player.GetPlayerHUD and player:GetPlayerHUD() or (playerSlot > -1 and hud:GetPlayerHUD(playerSlot))
			if playerhud then
				Isaac.RunCallback(ModCallbacks.MC_POST_PLAYERHUD_RENDER_HEARTS, Vector.Zero, hud:GetHeartsSprite(), barPos, 1.0, player, playerhud)
			end
		end
	end

	return true
end

function CustomHealthAPI.Helper.RenderCustomHealth()
	if CustomHealthAPI.PersistentData.DisableCustomHealthRendering or
	   Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD) or
	   (StageAPI ~= nil and StageAPI.PlayingBossSprite) or
	   not Game():GetHUD():IsVisible()
	then
		return
	end

	local nextPlayerSlot = 0
	local foundControllerIdx = {}
	local mainPlayers = {}
	local twinPlayers = {}
	local numOccupiedPlayerHUDs = 0

	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local playerType = player:GetPlayerType()
		local controllerIndex = player.ControllerIndex

		if player.Parent == nil and not foundControllerIdx[controllerIndex] then
			foundControllerIdx[controllerIndex] = true
			mainPlayers[nextPlayerSlot] = player
			numOccupiedPlayerHUDs = numOccupiedPlayerHUDs + 1

			if playerType == PlayerType.PLAYER_JACOB and player:GetOtherTwin() ~= nil and (nextPlayerSlot == 0 or REPENTANCE_PLUS) then
				twinPlayers[nextPlayerSlot] = player:GetOtherTwin()
				numOccupiedPlayerHUDs = numOccupiedPlayerHUDs + 1
			end

			nextPlayerSlot = nextPlayerSlot + 1

			if nextPlayerSlot > 4 then
				break
			end
		end
	end

	CustomHealthAPI.PersistentData.NumOccupiedPlayerHUDs = numOccupiedPlayerHUDs

	for playerSlot = 0, 4 do
		if mainPlayers[playerSlot] then
			CustomHealthAPI.Helper.RenderPlayerHPBar(mainPlayers[playerSlot], playerSlot)
			if twinPlayers[playerSlot] then
				CustomHealthAPI.Helper.RenderPlayerHPBar(twinPlayers[playerSlot], playerSlot + 4)
			end
		else
			break
		end
	end
end
