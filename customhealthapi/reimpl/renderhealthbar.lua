local healthsprites = {}
CustomHealthAPI.PersistentData.DisableCustomHealthRendering = CustomHealthAPI.PersistentData.DisableCustomHealthRendering or false
CustomHealthAPI.PersistentData.CancelCustomHealthRenderingRepentogon = CustomHealthAPI.PersistentData.CancelCustomHealthRenderingRepentogon or false
CustomHealthAPI.PersistentData.AllowPlayerHudRenderHeartsCallback = 0
CustomHealthAPI.PersistentData.NumOccupiedPlayerHUDs = 1
CustomHealthAPI.PersistentData.PlayerOneHasMultiplayerHUD = false

CustomHealthAPI.PersistentData.RenderTwin = {
	[PlayerType.PLAYER_JACOB] = true
}
CustomHealthAPI.PersistentData.RenderTwinBelowMain = {}
CustomHealthAPI.PersistentData.RenderTwinBelowMainThroughUnknown = {}
CustomHealthAPI.PersistentData.TwinRenderOffset = {}
CustomHealthAPI.PersistentData.CombineLivesOfTwins = {}

local shouldQueueRenders = false
local queuedRenders = {}

if REPENTOGON then
	function CustomHealthAPI.Helper.AddPrePlayerHudRenderHeartsCallback()
	---@diagnostic disable-next-line: param-type-mismatch
		Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_PLAYERHUD_RENDER_HEARTS, CustomHealthAPI.Enums.CallbackPriorities.FIRST, CustomHealthAPI.Mod.PrePlayerHudRenderHeartsCallback, -1)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPrePlayerHudRenderHeartsCallback)

	function CustomHealthAPI.Helper.RemovePrePlayerHudRenderHeartsCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_HEARTS, CustomHealthAPI.Mod.PrePlayerHudRenderHeartsCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePrePlayerHudRenderHeartsCallback)

	function CustomHealthAPI.Mod:PrePlayerHudRenderHeartsCallback(...)
		-- check and see if other mods are trying to cancel health rendering using repentogon
		-- if so, disable custom rendering of health
		if CustomHealthAPI.PersistentData.AllowPlayerHudRenderHeartsCallback <= 0 then
			CustomHealthAPI.PersistentData.AllowPlayerHudRenderHeartsCallback = CustomHealthAPI.PersistentData.AllowPlayerHudRenderHeartsCallback + 1
			local cancelCustomRendering = Isaac.RunCallback(ModCallbacks.MC_PRE_PLAYERHUD_RENDER_HEARTS, ...)
			if cancelCustomRendering == true then
				CustomHealthAPI.PersistentData.CancelCustomHealthRenderingRepentogon = true
			else
				CustomHealthAPI.PersistentData.CancelCustomHealthRenderingRepentogon = false
			end

			return true
		end
		
		CustomHealthAPI.PersistentData.AllowPlayerHudRenderHeartsCallback = CustomHealthAPI.PersistentData.AllowPlayerHudRenderHeartsCallback - 1
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
	   not Game():GetHUD():IsVisible() or
	   CustomHealthAPI.PersistentData.CancelCustomHealthRenderingRepentogon
	then
		return
	end
	
	local rendermode = Game():GetRoom():GetRenderMode()
	if rendermode ~= RenderMode.RENDER_NORMAL and rendermode ~= RenderMode.RENDER_WATER_ABOVE then
		return
	end
	
	local flyingOffset = (player:IsFlying() and Vector(0,-4)) or Vector.Zero
	CustomHealthAPI.Helper.RenderShardOfGlass(player, renderOffset + flyingOffset)

	if player.Parent ~= nil then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.RenderPlayerHPBar(player, -1, renderOffset + flyingOffset)
	end
end

function CustomHealthAPI.Helper.GetCurrentRedHealthForRendering(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	data.Cached = data.Cached or {}
	if data.Cached.RedHealthInRender then
		return data.Cached.RedHealthInRender
	end
	
	local order = CustomHealthAPI.Helper.GetRedHealthOrder() or {}
	
	local currentRedHealth = {}
	for i = 1, #order do
		local mask = CustomHealthAPI.Helper.GetRedHealthMask(player, i) or {}
		for j = 1, #mask do
			table.insert(currentRedHealth, mask[j])
		end
	end
	
	data.Cached.RedHealthInRender = currentRedHealth
	return currentRedHealth
end

function CustomHealthAPI.Helper.GetCurrentOtherHealthForRendering(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	data.Cached = data.Cached or {}
	if data.Cached.OtherHealthInRender then
		return data.Cached.OtherHealthInRender
	end
	
	local order = CustomHealthAPI.Helper.GetOtherHealthOrder() or {}
	
	local currentOtherHealth = {}
	for i = 1, #order do
		local mask = CustomHealthAPI.Helper.GetOtherHealthMask(player, i) or {}
		for j = 1, #mask do
			table.insert(currentOtherHealth, mask[j])
		end
	end
	
	data.Cached.OtherHealthInRender = currentOtherHealth
	return currentOtherHealth
end

-- [LEGACY]
function CustomHealthAPI.Helper.GetEternalRenderIndex(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	data.Cached = data.Cached or {}
	if data.Cached.EternalIndex then
		return data.Cached.EternalIndex
	end
	
	local redMasks = data.RedHealthMasks or {}
	local otherMasks = data.OtherHealthMasks or {}
	
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

function CustomHealthAPI.Helper.GetOverlayRenderMasks(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	data.Cached = data.Cached or {}
	if data.Cached.OverlayRenderMasks then
		return data.Cached.OverlayRenderMasks
	end
	
	local overlayRenderMasks = {}
	
	local healthOrder = CustomHealthAPI.Library.GetHealthInOrder(player, true)
	
	for i = #healthOrder, 1, -1 do
		overlayRenderMasks[i] = healthOrder[i].Overlays
	end
	
	data.Cached.OverlayRenderMasks = overlayRenderMasks
	return overlayRenderMasks
end

-- [legacy]
function CustomHealthAPI.Helper.GetGoldenRenderMask(player)
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	data.Cached = data.Cached or {}
	if data.Cached.GoldenRenderMask then
		return data.Cached.GoldenRenderMask
	end
	
	local goldMask = {}
	
	local overlayMasks = CustomHealthAPI.Helper.GetOverlayRenderMasks(player)
	for i, overlays in pairs(overlayMasks) do
		for _, overlay in ipairs(overlays) do
			if overlay.Key == "GOLDEN_HEART" then
				goldMask[i] = true
				break
			end
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
		pos = Isaac.WorldToScreen(player.Position) - Game():GetRoom():GetRenderScrollOffset() + Vector(-5 * (math.max(1, math.min(numOtherHearts, 6)) - 1), -30)
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

function CustomHealthAPI.Helper.GetHealthRenderPos(player, playerSlot, i, renderOffset, numOtherHearts, extraOffset, flip, scale)
	renderOffset = renderOffset or Vector.Zero
	extraOffset = extraOffset or Vector.Zero

	local numOtherHearts = math.max(numOtherHearts or 0, 1)
	local barPos, esauFlipped = CustomHealthAPI.Helper.GetHealthBarPos(player, playerSlot, numOtherHearts)
	
	local isReverse = esauFlipped
	if flip then
		isReverse = not isReverse
	end

	scale = scale or Vector.One
	local heartDistanceX = CustomHealthAPI.Constants.HEART_PIXEL_WIDTH_DEFAULT * scale.X
	local heartDistanceY = CustomHealthAPI.Constants.HEART_PIXEL_HEIGHT_DEFAULT * scale.Y

	if isReverse then
		heartDistanceX = -heartDistanceX
		extraOffset = Vector(-extraOffset.X, extraOffset.Y)
	end

	-- In REP+, co-op health bars are no longer rendered in rows of 3.
	local numColumns = 6
	if not REPENTANCE_PLUS and playerSlot ~= 0 and playerSlot ~= 4 then
		numColumns = 3
	end
	if CustomHealthAPI.Constants.HEARTS_PER_ROW > 0 then numColumns = CustomHealthAPI.Constants.HEARTS_PER_ROW end
	local heartOffset = Vector(heartDistanceX * (i % numColumns), heartDistanceY * math.floor(i / numColumns))
	
	return barPos + heartOffset + ((renderOffset + extraOffset) * scale), esauFlipped
end

function CustomHealthAPI.Helper.RenderHealth(sprite, player, playerSlot, i, renderOffset, numOtherHearts, extraOffset, ignoreEsauFlipX, flip, scale, color)
	scale = scale or Vector.One

	local renderPos, esauFlipped = CustomHealthAPI.Helper.GetHealthRenderPos(player, playerSlot, i, renderOffset, numOtherHearts, extraOffset, flip, scale)
	
	local flipX = esauFlipped and not ignoreEsauFlipX
	if flip then
		flipX = not flipX
	end
	sprite.FlipX = flipX
	
	sprite.Scale = scale
	sprite.Color = color or sprite.Color
	sprite:Render(renderPos, Vector.Zero, Vector.Zero)
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
		return CustomHealthAPI.Helper.GetTotalHP(player) + CustomHealthAPI.Helper.GetTotalOverlayHP(player) == 1 and
		       not player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_HOLY_MANTLE) and
		       not isSubPlayer
	end
end

function CustomHealthAPI.Helper.GetLeakingHealthColor(A)
	local pulseHighColor = Color(0.8, 0.8, 0.8, A, 25/255, 0/255, 0/255)
	local pulseLowColor = Color(0.5, 0.5, 0.5, A, 0/255, 0/255, 0/255)

	pulseHighColor:SetColorize(1, 1, 1, 0.5)
	pulseLowColor:SetColorize(1, 1, 1, 0.6)

	return Color.Lerp(pulseLowColor,
	                  pulseHighColor,
	                  (math.sin(Game():GetFrameCount() / 9.55) + 1) / 2)
end

function CustomHealthAPI.Helper.GetHealthColor(healthDefinition, hasRedHealth, redKey, player, healthSlot, redHealthIndex, overlays, isSubPlayer, color)
	local data = CustomHealthAPI.Helper.GetOtherData(player)
	local shouldRedFlash = data ~= nil and data.RedFlash ~= nil and data.RedFlash > 0
	local shouldSoulFlash = data ~= nil and data.SoulFlash ~= nil and data.SoulFlash > 0
	
	local A = (CustomHealthAPI.Helper.CheckFadedHealth(player, isSubPlayer) and 0.3) or 1.0
	local healthcolor = Color.Lerp(color or Color(1, 1, 1), color or Color(1, 1, 1), 1)
	if CustomHealthAPI.Helper.CheckDangerHealth(player, isSubPlayer) then
		if healthSlot == 1 then
			healthcolor.RO = math.max(0, ((Game():GetFrameCount() % 45) - 9) / 9 * -1)
		end
	elseif CustomHealthAPI.Helper.CheckLeakingHealth(healthDefinition, hasRedHealth, player, redHealthIndex) then
		healthcolor = healthcolor * CustomHealthAPI.Helper.GetLeakingHealthColor(A)
	end
	healthcolor.A = A * ((color and color.A) or 1)
	
	local flashDef = nil
	
	if overlays == true then
		local overlayDef = CustomHealthAPI.PersistentData.HealthDefinitions["GOLDEN_HEART"]
		if data ~= nil and data.OverlayFlash and (data.OverlayFlash[overlayDef.OverlayLayerIndex] or 0) > 0 then
			flashDef = overlayDef
		end
	elseif overlays then
		for i=#overlays, 1, -1 do
			local overlayDef = CustomHealthAPI.PersistentData.HealthDefinitions[overlays[i].Key]
			if (overlayDef.HealFlashRO or overlayDef.HealFlashGO or overlayDef.HealFlashBO) and
			   data ~= nil and data.OverlayFlash and (data.OverlayFlash[overlayDef.OverlayLayerIndex] or 0) > 0
			then
				flashDef = overlayDef
				break
			end
		end
	end
	
	if not flashDef then
		if hasRedHealth and shouldRedFlash then
			flashDef = CustomHealthAPI.PersistentData.HealthDefinitions[redKey]
		elseif healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.SOUL and shouldSoulFlash then
			flashDef = healthDefinition
		end
	end
	
	if flashDef then
		healthcolor.RO = healthcolor.RO + (flashDef.HealFlashRO or 0)
		healthcolor.GO = healthcolor.GO + (flashDef.HealFlashGO or 0)
		healthcolor.BO = healthcolor.BO + (flashDef.HealFlashBO or 0)
	end
	
	return healthcolor
end

function CustomHealthAPI.Helper.RunPreHealthRenderCallback(iter, player, playerSlot, healthIndex, renderInfo)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_RENDER)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	local returnTable = {}
	for callback in iterator do
		if not callback.Param or (renderInfo.RedHealth and callback.Param == renderInfo.RedHealth.Key) or (renderInfo.OtherHealth and callback.Param == renderInfo.OtherHealth.Key) or callback.Param == playerType then
			local ret = callback.Function(callback.Mod, player, playerSlot, healthIndex, renderInfo)
			if ret ~= nil then
				if ret.Index ~= nil then
					healthIndex = ret.Index
					returnTable.Index = ret.Index
				end
				if ret.AnimationFilename ~= nil then
					renderInfo.Filename = ret.AnimationFilename
					returnTable.AnimationFilename = ret.AnimationFilename
				end
				if ret.AnimationName ~= nil then
					renderInfo.Animation = ret.AnimationName
					returnTable.AnimationName = ret.AnimationName
				end
				if ret.AnimationFrame ~= nil then
					renderInfo.Frame = ret.AnimationFrame
					returnTable.AnimationFrame = ret.AnimationFrame
				end
				if ret.Flip ~= nil then
					renderInfo.Flip = ret.Flip
					returnTable.Flip = ret.Flip
				end
				if ret.Scale ~= nil then
					renderInfo.Scale = ret.Scale
					returnTable.Scale = ret.Scale
				end
				if ret.Color ~= nil then
					renderInfo.Color = ret.Color
					returnTable.Color = ret.Color
				end
				if ret.Offset ~= nil then
					renderInfo.ExtraOffset = ret.Offset
					returnTable.Offset = ret.Offset
				end
				if ret.ContainerAnimationFilename ~= nil then
					renderInfo.ContainerFilename = ret.ContainerAnimationFilename
					returnTable.ContainerAnimationFilename = ret.ContainerAnimationFilename
				end
				if ret.ContainerAnimationName ~= nil then
					renderInfo.ContainerAnimation = ret.ContainerAnimationName
					returnTable.ContainerAnimationName = ret.ContainerAnimationName
				end
				if ret.ContainerAnimationFrame ~= nil then
					renderInfo.ContainerFrame = ret.ContainerAnimationFrame
					returnTable.ContainerAnimationFrame = ret.ContainerAnimationFrame
				end
				if ret.SkipContainer == true then
					renderInfo.ContainerFilename = nil
					renderInfo.ContainerAnimation = nil
					returnTable.SkipContainer = true
				end
				if ret.Prevent == true then
					returnTable.Prevent = true
					return returnTable
				end
			end
		elseif type(callback.Param) == "table" then
			for _,v in pairs(callback.Param) do
				if (renderInfo.RedHealth and v == renderInfo.RedHealth.Key) or (renderInfo.OtherHealth and v == renderInfo.OtherHealth.Key) or v == playerType then
					local ret = callback.Function(callback.Mod, player, playerSlot, healthIndex, renderInfo)
					if ret ~= nil then
						if ret.Index ~= nil then
							healthIndex = ret.Index
							returnTable.Index = ret.Index
						end
						if ret.AnimationFilename ~= nil then
							renderInfo.Filename = ret.AnimationFilename
							returnTable.AnimationFilename = ret.AnimationFilename
						end
						if ret.AnimationName ~= nil then
							renderInfo.Animation = ret.AnimationName
							returnTable.AnimationName = ret.AnimationName
						end
						if ret.AnimationFrame ~= nil then
							renderInfo.Frame = ret.AnimationFrame
							returnTable.AnimationFrame = ret.AnimationFrame
						end
						if ret.Flip ~= nil then
							renderInfo.Flip = ret.Flip
							returnTable.Flip = ret.Flip
						end
						if ret.Scale ~= nil then
							renderInfo.Scale = ret.Scale
							returnTable.Scale = ret.Scale
						end
						if ret.Color ~= nil then
							renderInfo.Color = ret.Color
							returnTable.Color = ret.Color
						end
						if ret.Offset ~= nil then
							renderInfo.ExtraOffset = ret.Offset
							returnTable.Offset = ret.Offset
						end
						if ret.ContainerAnimationFilename ~= nil then
							renderInfo.ContainerFilename = ret.ContainerAnimationFilename
							returnTable.ContainerAnimationFilename = ret.ContainerAnimationFilename
						end
						if ret.ContainerAnimationName ~= nil then
							renderInfo.ContainerAnimation = ret.ContainerAnimationName
							returnTable.ContainerAnimationName = ret.ContainerAnimationName
						end
						if ret.ContainerAnimationFrame ~= nil then
							renderInfo.ContainerFrame = ret.ContainerAnimationFrame
							returnTable.ContainerAnimationFrame = ret.ContainerAnimationFrame
						end
						if ret.SkipContainer == true then
							renderInfo.ContainerFilename = nil
							renderInfo.ContainerAnimation = nil
							returnTable.SkipContainer = true
						end
						if ret.Prevent == true then
							returnTable.Prevent = true
							return returnTable
						end
					end
					break
				end
			end
		end
	end
	return returnTable
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_HEALTH_RENDER] = CustomHealthAPI.Helper.RunPreHealthRenderCallback

function CustomHealthAPI.Helper.RunPostHealthRenderCallback(iter, player, playerSlot, healthIndex, renderInfo)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.POST_HEALTH_RENDER)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	for callback in iterator do
		if not callback.Param or (renderInfo.RedHealth and callback.Param == renderInfo.RedHealth.Key) or (renderInfo.OtherHealth and callback.Param == renderInfo.OtherHealth.Key) or callback.Param == playerType then
			callback.Function(callback.Mod, player, playerSlot, healthIndex, renderInfo)
		elseif type(callback.Param) == "table" then
			for _,v in pairs(callback.Param) do
				if v == key or (renderInfo.RedHealth and v == renderInfo.RedHealth.Key) or (renderInfo.OtherHealth and v == renderInfo.OtherHealth.Key) or v == playerType then
					callback.Function(callback.Mod, player, playerSlot, healthIndex, renderInfo)
					break
				end
			end
		end
	end
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.POST_HEALTH_RENDER] = CustomHealthAPI.Helper.RunPostHealthRenderCallback

function CustomHealthAPI.Helper.RenderHealthWithCallbacks(player, playerSlot, healthIndex, renderInfo)
	local playertype = player:GetPlayerType()
	local prevent = false
	
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	local returnTable = CustomHealthAPI.Helper.RunPreHealthRenderCallback(nil, player, playerSlot, healthIndex, renderInfo)
	if returnTable ~= nil then
		if returnTable.Index ~= nil then
			healthIndex = returnTable.Index
		end
		if returnTable.AnimationFilename ~= nil then
			renderInfo.Filename = returnTable.AnimationFilename
		end
		if returnTable.AnimationName ~= nil then
			renderInfo.Animation = returnTable.AnimationName
		end
		if returnTable.AnimationFrame ~= nil then
			renderInfo.Frame = returnTable.AnimationFrame
		end
		if returnTable.Color ~= nil then
			renderInfo.Color = returnTable.Color
		end
		if returnTable.Scale ~= nil then
			renderInfo.Scale = returnTable.Scale
		end
		if returnTable.Flip ~= nil then
			renderInfo.Flip = returnTable.Flip
		end
		if returnTable.Offset ~= nil then
			renderInfo.ExtraOffset = returnTable.Offset
		end
		if returnTable.ContainerAnimationFilename ~= nil then
			renderInfo.ContainerFilename = returnTable.ContainerAnimationFilename
		end
		if returnTable.ContainerAnimationName ~= nil then
			renderInfo.ContainerAnimation = returnTable.ContainerAnimationName
		end
		if returnTable.ContainerAnimationFrame ~= nil then
			renderInfo.ContainerFrame = returnTable.ContainerAnimationFrame
		end
		if returnTable.SkipContainer == true then
			renderInfo.ContainerFilename = nil
			renderInfo.ContainerAnimation = nil
		end
		if returnTable.Prevent == true then
			prevent = true
		end
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	
	if prevent then
		return false
	else
		local func = function()
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(renderInfo.Filename)
			healthSprite:Play(renderInfo.Animation, true)
			healthSprite:SetFrame(renderInfo.Frame or 0)
			healthSprite.Color = renderInfo.Color
			CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderInfo.RenderOffset, renderInfo.TotalHealthRendered, renderInfo.ExtraOffset, false, renderInfo.Flip, renderInfo.Scale, renderInfo.Color)
			
			if renderInfo.ContainerFilename and renderInfo.ContainerAnimation then
				local containerSprite = CustomHealthAPI.Helper.GetHealthSprite(renderInfo.ContainerFilename)
				containerSprite:Play(renderInfo.ContainerAnimation, true)
				containerSprite:SetFrame(renderInfo.ContainerFrame or 0)
				containerSprite.Color = renderInfo.Color
				CustomHealthAPI.Helper.RenderHealth(containerSprite, player, playerSlot, healthIndex, renderInfo.RenderOffset, renderInfo.TotalHealthRendered, renderInfo.ExtraOffset, false, renderInfo.Flip, renderInfo.Scale, renderInfo.Color)
			end
			
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
			CustomHealthAPI.Helper.RunPostHealthRenderCallback(nil, player, playerSlot, healthIndex, renderInfo)
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
		end
		if shouldQueueRenders then
			table.insert(queuedRenders, func)
		else
			func()
		end
		return true
	end
end

function CustomHealthAPI.Helper.RunPreRenderHeartsCallback(iter, player, playerSlot, isSubPlayer, renderOffset, indexOffset, mainPlayer, flip, scale, color)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HEARTS)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	local returnTable = {}
	for callback in iterator do
		if not callback.Param or callback.Param == playerType then
			local ret = callback.Function(callback.Mod, player, playerSlot, isSubPlayer, renderOffset, indexOffset, mainPlayer, flip, scale, color)
			if ret ~= nil then
				if type(ret) == "table" then
					if ret.IndexOffset ~= nil then
						indexOffset = ret.IndexOffset
						returnTable.IndexOffset = ret.IndexOffset
					end
					if ret.Prevent ~= nil then
						returnTable.Prevent = ret.Prevent
						break
					end
				elseif ret then
					returnTable.Prevent = ret
					break
				end
			end
		end
	end
	return returnTable
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HEARTS] = CustomHealthAPI.Helper.RunPreRenderHeartsCallback

function CustomHealthAPI.Helper.RenderCustomHealthOfPlayer(player, playerSlot, isSubPlayer, renderOffset, indexOffset, mainPlayer, flip, scale, color)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then return 0 end

	local playertype = player:GetPlayerType()
	local indexOffset = indexOffset or 0
	local prevent = nil
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	local returnTable = CustomHealthAPI.Helper.RunPreRenderHeartsCallback(nil, player, playerSlot, isSubPlayer, renderOffset, indexOffset, mainPlayer, flip, scale, color)
	if type(returnTable) == "table" then
		if returnTable.IndexOffset ~= nil then
			indexOffset = returnTable.IndexOffset
		end
		if returnTable.Prevent ~= nil then
			prevent = returnTable.Prevent
		end
	elseif returnTable then
		prevent = returnTable
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	if prevent then return 0 end

	local currentRedHealth = CustomHealthAPI.Helper.GetCurrentRedHealthForRendering(player) or {}
	local currentOtherHealth = CustomHealthAPI.Helper.GetCurrentOtherHealthForRendering(player) or {}
	local numOtherHearts = #currentOtherHealth
	
	local overlayRenderMasks = CustomHealthAPI.Helper.GetOverlayRenderMasks(player)
	
	local data = CustomHealthAPI.Helper.GetSavedata(player)
	if not data then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		data = CustomHealthAPI.Helper.GetSavedata(player)
	end
	local redHealthIndex = 1
	local otherHealthIndex = 1
	local healthToRender = {}
	while currentOtherHealth[otherHealthIndex] ~= nil do
		local animationFilename = nil
		local animationName = nil
		local containerFilename = nil
		local containerAnimation = nil
		
		local health = currentOtherHealth[otherHealthIndex]
		local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[health.Key]
		local hasRedHealth = false
		local redKey = nil
		local redHealth = nil
		
		local updateRedHealthIndex = false
		if healthDefinition.Type == CustomHealthAPI.Enums.HealthTypes.CONTAINER then
			local containerHp = currentOtherHealth[otherHealthIndex].HP
			animationFilename = healthDefinition.AnimationFilename
			animationName = healthDefinition.AnimationName
			if type(animationName) == "table" then
				animationName = animationName[containerHp] or animationName[1]
			end
			
			redHealth = healthDefinition.KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and currentRedHealth[redHealthIndex] or nil
			if redHealth then
				local redHealthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[redHealth.Key]
				local redToOtherNames = redHealthDefinition.AnimationNames
				local redAnimNameKey = health.Key
				local defaultAnimNameKey = redHealthDefinition.Kind == CustomHealthAPI.Enums.HealthKinds.COIN and "EMPTY_COIN_HEART" or "EMPTY_HEART"
				
				if redToOtherNames[redAnimNameKey] == nil then
					-- There is no custom animation to use for this red health in this container. Use the default.
					redAnimNameKey = defaultAnimNameKey
					if healthDefinition.LayeredAnimationName then
						-- The container has a "layered" animation defined, which will render on top of the default red health animation.
						containerFilename = healthDefinition.LayeredAnimationFilename or healthDefinition.AnimationFilename
						containerAnimation = healthDefinition.LayeredAnimationName
						if type(containerAnimation) == "table" then
							containerAnimation = containerAnimation[containerHp] or containerAnimation[1]
						end
					end
				end
				
				local names = redToOtherNames[redAnimNameKey]
				
				if names ~= nil then
					local hp = redHealth.HP
					while names[hp] == nil and hp > 0 do
						hp = hp - 1
					end
					
					if names[hp] == nil then
						print("Custom Health API ERROR: CustomHealthAPI.Helper.RenderCustomHealthOfPlayer; No animation name associated to health of red key " ..
						      redHealth.Key .. 
						      ", other key " .. 
						      redAnimNameKey .. 
						      " and HP " .. 
						      tostring(redHealth.HP) .. 
						      ".")
					    return
					end
					
					animationFilename = redHealthDefinition.AnimationFilenames[redAnimNameKey] or redHealthDefinition.AnimationFilenames[defaultAnimNameKey]
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
			local healthcolor = CustomHealthAPI.Helper.GetHealthColor(healthDefinition, hasRedHealth, redKey, player, otherHealthIndex, redHealthIndex, overlayRenderMasks[otherHealthIndex], isSubPlayer, color)
			local healthIndex = otherHealthIndex - 1 + indexOffset
			local renderInfo = {
				OtherHealth = health,
				RedHealth = redHealth,
				Filename = animationFilename, 
				Animation = animationName,
			    Frame = 0,
				ContainerFilename = containerFilename,
				ContainerAnimation = containerAnimation,
				ContainerFrame = 0,
				OrderIndex = otherHealthIndex,
				Flip = flip,
				Scale = scale,
				Color = healthcolor, 
				RenderOffset = renderOffset,
				ExtraOffset = Vector(0,0),
				Other = {},
			}
			table.insert(healthToRender, {Index = healthIndex, RedHealthIndex = redHealthIndex, OtherHealthIndex = otherHealthIndex, RenderInfo = renderInfo})
		end
		
		if updateRedHealthIndex then
			redHealthIndex = redHealthIndex + 1
		end
		otherHealthIndex = otherHealthIndex + 1
	end
	
	local skippedIndices = 0
	local skippedAtIndex = {}
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	for i = #healthToRender, 1, -1 do
		local returnTable = CustomHealthAPI.Helper.RunPreHealthRenderCallback(nil, player, playerSlot, healthToRender[i].Index, healthToRender[i].RenderInfo)
		if returnTable ~= nil then
			if returnTable.Index ~= nil then
				healthToRender[i].Index = returnTable.Index
			end
			if returnTable.AnimationFilename ~= nil then
				healthToRender[i].RenderInfo.Filename = returnTable.AnimationFilename
			end
			if returnTable.AnimationName ~= nil then
				healthToRender[i].RenderInfo.Animation = returnTable.AnimationName
			end
			if returnTable.AnimationFrame ~= nil then
				healthToRender[i].RenderInfo.Frame = returnTable.AnimationFrame
			end
			if returnTable.Flip ~= nil then
				healthToRender[i].RenderInfo.Flip = returnTable.Flip
			end
			if returnTable.Scale ~= nil then
				healthToRender[i].RenderInfo.Scale = returnTable.Scale
			end
			if returnTable.Color ~= nil then
				healthToRender[i].RenderInfo.Color = returnTable.Color
			end
			if returnTable.Offset ~= nil then
				healthToRender[i].RenderInfo.ExtraOffset = returnTable.Offset
			end
			if returnTable.ContainerAnimationFilename ~= nil then
				healthToRender[i].RenderInfo.ContainerFilename = returnTable.ContainerAnimationFilename
			end
			if returnTable.ContainerAnimationName ~= nil then
				healthToRender[i].RenderInfo.ContainerAnimation = returnTable.ContainerAnimationName
			end
			if returnTable.ContainerAnimationFrame ~= nil then
				healthToRender[i].RenderInfo.ContainerFrame = returnTable.ContainerAnimationFrame
			end
			if returnTable.SkipContainer == true then
				healthToRender[i].RenderInfo.ContainerFilename = nil
				healthToRender[i].RenderInfo.ContainerAnimation = nil
			end
			if returnTable.Prevent == true then
				healthToRender[i].Prevent = true
				skippedIndices = skippedIndices + 1
				skippedAtIndex[healthToRender[i].OtherHealthIndex] = true
			end
		end
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	
	local skippedSoFar = 0
	for i = 1, #healthToRender do
		if healthToRender[i].Prevent then
			skippedSoFar = skippedSoFar + 1
		else
			local healthIndex = healthToRender[i].Index - skippedSoFar
			local renderInfo = healthToRender[i].RenderInfo
			renderInfo.TotalHealthRendered = numOtherHearts - skippedIndices

			local func = function()
				local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(renderInfo.Filename)
				healthSprite:Play(renderInfo.Animation, true)
				healthSprite:SetFrame(renderInfo.Frame or 0)
				healthSprite.Color = renderInfo.Color
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderInfo.RenderOffset, renderInfo.TotalHealthRendered, renderInfo.ExtraOffset, false, renderInfo.Flip, renderInfo.Scale, renderInfo.Color)
				
				if renderInfo.ContainerFilename and renderInfo.ContainerAnimation then
					local containerSprite = CustomHealthAPI.Helper.GetHealthSprite(renderInfo.ContainerFilename)
					containerSprite:Play(renderInfo.ContainerAnimation, true)
					containerSprite:SetFrame(renderInfo.ContainerFrame or 0)
					containerSprite.Color = renderInfo.Color
					CustomHealthAPI.Helper.RenderHealth(containerSprite, player, playerSlot, healthIndex, renderInfo.RenderOffset, renderInfo.TotalHealthRendered, renderInfo.ExtraOffset, false, renderInfo.Flip, renderInfo.Scale, renderInfo.Color)
				end
				
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
				CustomHealthAPI.Helper.RunPostHealthRenderCallback(nil, player, playerSlot, healthIndex, renderInfo)
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
			end
			if shouldQueueRenders then
				table.insert(queuedRenders, func)
			else
				func()
			end
		end
	end
	
	local unskippedIndices = 0
	for i = numOtherHearts, 1, -1 do
		if skippedAtIndex[i] then
			unskippedIndices = unskippedIndices + 1
		else
			for j, overlay in ipairs(overlayRenderMasks[i] or {}) do
				local overlayDef = CustomHealthAPI.PersistentData.HealthDefinitions[overlay.Key]
				
				local filename = overlayDef.AnimationFilename
				local animname = overlayDef.AnimationName
				if type(animname) == "table" then
					animname = animname[overlay.HP] or animname[1]
				end
				local A = (CustomHealthAPI.Helper.CheckFadedHealth(player, isSubPlayer) and 0.3) or 1.0
				local leaking = CustomHealthAPI.Helper.CheckLeakingHealth(overlayDef, healthToRender[i].RenderInfo.RedHealth ~= nil, player, healthToRender[i].RedHealthIndex)
				local healthcolor = ((leaking and CustomHealthAPI.Helper.GetLeakingHealthColor(A)) or Color(1, 1, 1)) * (color or Color(1, 1, 1))
				healthcolor.A = A * ((color and color.A) or 1)
				
				local healthIndex = i - 1 + indexOffset
				
				local renderInfo = {
					OtherHealth = {Key = overlay.Key, HP = math.max(overlay.HP, 1)},
					RedHealth = nil,
					OtherHealthOverlayed = healthToRender[i].RenderInfo.OtherHealth,
					RedHealthOverlayed = healthToRender[i].RenderInfo.RedHealth,
					TotalHealthRendered = numOtherHearts - skippedIndices,
					Filename = filename, 
					Animation = animname,
					Frame = 0,
					ContainerFilename = nil,
					ContainerAnimation = nil,
					ContainerFrame = 0,
					OrderIndex = i,
					Flip = flip,
					Scale = scale,
					Color = healthcolor, 
					RenderOffset = renderOffset,
					ExtraOffset = Vector(0,0),
					Other = {},
				}
				CustomHealthAPI.Helper.RenderHealthWithCallbacks(player, playerSlot, healthIndex - skippedIndices + unskippedIndices, renderInfo)
			end
		end
	end

	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HEARTS, playertype, player, playerSlot, isSubPlayer, renderOffset, numOtherHearts - skippedIndices, renderInfo)
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1

	return numOtherHearts - skippedIndices
end

function CustomHealthAPI.Helper.RenderKeeperHealth(player, playerSlot, renderOffset, flip, scale, color)
	local playertype = player:GetPlayerType()
	local prevent = nil
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	local returnTable = CustomHealthAPI.Helper.RunPreRenderHeartsCallback(nil, player, playerSlot, false, renderOffset, nil, nil, flip, scale, color)
	if type(returnTable) == "table" then
		if returnTable.Prevent ~= nil then
			prevent = returnTable.Prevent
		end
	elseif returnTable then
		prevent = returnTable
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	if prevent then return 0 end
	
	local numRed = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	local numMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
	local numBroken = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	local numGolden = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player) -- ??? why does this work in basegame
	
	local healthToRender = {}
	
	local redToRender = numRed
	local maxToRender = numMax
	local brokenToRender = numBroken
	local numKeys = math.min(math.ceil(numMax / 2) + numBroken, 24)
	local otherHealthIndex = 1
	local redHealthIndex = 1
	while redToRender > 0 or maxToRender > 0 or brokenToRender > 0 do
		local healthDefinition
		local hasRedHealth
		local redKey, otherKey
		local redHP
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
			otherKey = "EMPTY_COIN_HEART"
			redHP = 2
			
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
			otherKey = "EMPTY_COIN_HEART"
			redHP = 1
			
			redToRender = redToRender - 1
			maxToRender = maxToRender - 2
		elseif maxToRender > 0 then
			healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["EMPTY_COIN_HEART"]
			
			animationFilename = healthDefinition.AnimationFilename
			animationName = healthDefinition.AnimationName
			
			hasRedHealth = false
			redKey = nil
			otherKey = "EMPTY_COIN_HEART"
			
			maxToRender = maxToRender - 2
		elseif brokenToRender > 0 then
			healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["BROKEN_COIN_HEART"]
			
			animationFilename = healthDefinition.AnimationFilename
			animationName = healthDefinition.AnimationName
			
			hasRedHealth = false
			redKey = nil
			otherKey = "BROKEN_COIN_HEART"
			
			brokenToRender = brokenToRender - 1
		end
		
		local healthcolor = CustomHealthAPI.Helper.GetHealthColor(healthDefinition, 
		                                                    hasRedHealth, 
		                                                    redKey, 
		                                                    player, 
		                                                    otherHealthIndex, 
		                                                    redHealthIndex, 
		                                                    isGolden, 
		                                                    false,
		                                                    color)
		local healthIndex = otherHealthIndex - 1
		local renderInfo = {
			OtherHealth = {Key = otherKey, HP = 0, HalfCapacity = false},
			RedHealth = (redKey and {Key = redKey, HP = redHP}) or nil,
			TotalHealthRendered = numKeys,
			Filename = animationFilename,
			Animation = animationName,
			Frame = 0,
			ContainerFilename = nil,
			ContainerAnimation = nil,
			ContainerFrame = 0,
			OrderIndex = otherHealthIndex,
			Flip = flip,
			Scale = scale,
			Color = healthcolor,
			RenderOffset = renderOffset,
			ExtraOffset = Vector(0,0),
			Other = {},
		}
		table.insert(healthToRender, {Index = healthIndex, OtherHealthIndex = otherHealthIndex, RenderInfo = renderInfo})
		
		otherHealthIndex = otherHealthIndex + 1
		if hasRedHealth then
			redHealthIndex = redHealthIndex + 1
		end
		
		if otherHealthIndex > 24 then
			break
		end
	end
	
	local skippedIndices = 0
	local skippedAtIndex = {}
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	for i = #healthToRender, 1, -1 do
		local returnTable = CustomHealthAPI.Helper.RunPreHealthRenderCallback(nil, player, playerSlot, healthToRender[i].Index, healthToRender[i].RenderInfo)
		if returnTable ~= nil then
			if returnTable.Index ~= nil then
				healthToRender[i].Index = returnTable.Index
			end
			if returnTable.AnimationFilename ~= nil then
				healthToRender[i].RenderInfo.Filename = returnTable.AnimationFilename
			end
			if returnTable.AnimationName ~= nil then
				healthToRender[i].RenderInfo.Animation = returnTable.AnimationName
			end
			if returnTable.AnimationFrame ~= nil then
				healthToRender[i].RenderInfo.Frame = returnTable.AnimationFrame
			end
			if returnTable.Flip ~= nil then
				healthToRender[i].RenderInfo.Flip = returnTable.Flip
			end
			if returnTable.Scale ~= nil then
				healthToRender[i].RenderInfo.Scale = returnTable.Scale
			end
			if returnTable.Color ~= nil then
				healthToRender[i].RenderInfo.Color = returnTable.Color
			end
			if returnTable.Offset ~= nil then
				healthToRender[i].RenderInfo.ExtraOffset = returnTable.Offset
			end
			if returnTable.ContainerAnimationFilename ~= nil then
				healthToRender[i].RenderInfo.ContainerFilename = returnTable.ContainerAnimationFilename
			end
			if returnTable.ContainerAnimationName ~= nil then
				healthToRender[i].RenderInfo.ContainerAnimation = returnTable.ContainerAnimationName
			end
			if returnTable.ContainerAnimationFrame ~= nil then
				healthToRender[i].RenderInfo.ContainerFrame = returnTable.ContainerAnimationFrame
			end
			if returnTable.SkipContainer == true then
				healthToRender[i].RenderInfo.ContainerFilename = nil
				healthToRender[i].RenderInfo.ContainerAnimation = nil
			end
			if returnTable.Prevent == true then
				healthToRender[i].Prevent = true
				skippedIndices = skippedIndices + 1
				skippedAtIndex[healthToRender[i].OtherHealthIndex] = true
			end
		end
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	
	local skippedSoFar = 0
	for i = 1, #healthToRender do
		if healthToRender[i].Prevent then
			skippedSoFar = skippedSoFar + 1
		else
			local healthIndex = healthToRender[i].Index - skippedSoFar
			local renderInfo = healthToRender[i].RenderInfo
			renderInfo.TotalHealthRendered = numKeys - skippedIndices
			
			local func = function()
				local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(renderInfo.Filename)
				healthSprite:Play(renderInfo.Animation, true)
				healthSprite:SetFrame(renderInfo.Frame or 0)
				healthSprite.Color = renderInfo.Color
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderInfo.RenderOffset, renderInfo.TotalHealthRendered, renderInfo.ExtraOffset, false, renderInfo.Flip, renderInfo.Scale, renderInfo.Color)
				
				if renderInfo.ContainerFilename and renderInfo.ContainerAnimation then
					local containerSprite = CustomHealthAPI.Helper.GetHealthSprite(renderInfo.ContainerFilename)
					containerSprite:Play(renderInfo.ContainerAnimation, true)
					containerSprite:SetFrame(renderInfo.ContainerFrame or 0)
					containerSprite.Color = renderInfo.Color
					CustomHealthAPI.Helper.RenderHealth(containerSprite, player, playerSlot, healthIndex, renderInfo.RenderOffset, renderInfo.TotalHealthRendered, renderInfo.ExtraOffset, false, renderInfo.Flip, renderInfo.Scale, renderInfo.Color)
				end
				
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
				CustomHealthAPI.Helper.RunPostHealthRenderCallback(nil, player, playerSlot, healthIndex, renderInfo)
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
			end
			if shouldQueueRenders then
				table.insert(queuedRenders, func)
			else
				func()
			end
		end
	end
	
	local goldenToRender = numGolden
	local unskippedIndices = 0
	for i = math.min(24, math.ceil(numRed / 2)), 1, -1 do
		if goldenToRender > 0 then
			if skippedAtIndex[i] then
				unskippedIndices = unskippedIndices + 1
			else
				local goldenDefinition = CustomHealthAPI.PersistentData.HealthDefinitions["GOLDEN_HEART"]
				local renderInfo = {
					OtherHealth = {Key = "GOLDEN_HEART", HP = 0},
					RedHealth = nil,
					TotalHealthRendered = numKeys - skippedIndices,
					Filename = goldenDefinition.AnimationFilename, 
					Animation = goldenDefinition.AnimationName,
				    Frame = 0,
					ContainerFilename = nil,
					ContainerAnimation = nil,
					ContainerFrame = 0,
					OrderIndex = i,
					Flip = flip,
					Scale = scale,
					Color = color or Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255), 
					RenderOffset = renderOffset,
					ExtraOffset = Vector(0,0),
					Other = {},
				}
				CustomHealthAPI.Helper.RenderHealthWithCallbacks(player, playerSlot, i - 1 - skippedIndices + unskippedIndices, renderInfo)
			end
			goldenToRender = goldenToRender - 1
		end
	end
	
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HEARTS, playertype, player, playerSlot, false, renderOffset, numOtherHearts, renderInfo)
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	
	return numKeys - skippedIndices
end

function CustomHealthAPI.Helper.RunPreRenderUnknownCurseCallback(iter, player, playerSlot, renderInfo)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_UNKNOWN_CURSE)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	local returnTable = {}
	for callback in iterator do
		if not callback.Param or callback.Param == playerType then
			local ret = callback.Function(callback.Mod, player, playerSlot, renderInfo)
			if ret ~= nil then
				if type(ret) == "table" then
					if ret.AnimationFilename ~= nil then
						renderInfo.Filename = ret.AnimationFilename
						returnTable.AnimationFilename = ret.AnimationFilename
					end
					if ret.AnimationName ~= nil then
						renderInfo.Animation = ret.AnimationName
						returnTable.AnimationName = ret.AnimationName
					end
					if ret.Color ~= nil then
						renderInfo.Color = ret.Color
						returnTable.Color = ret.Color
					end
					if ret.Scale ~= nil then
						renderInfo.Scale = ret.Scale
						returnTable.Scale = ret.Scale
					end
					if ret.Offset ~= nil then
						renderInfo.RenderOffset = ret.Offset
						returnTable.Offset = ret.Offset
					end
					if ret.Prevent ~= nil then
						returnTable.Prevent = ret.Prevent
						break
					end
				elseif ret then
					returnTable.Prevent = ret
					break
				end
			end
		end
	end
	return returnTable
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_RENDER_UNKNOWN_CURSE] = CustomHealthAPI.Helper.RunPreRenderUnknownCurseCallback

function CustomHealthAPI.Helper.RenderCurseOfTheUnknown(player, playerSlot, renderOffset, flip, scale, color)
	local renderInfo = {
		Filename = (CustomHealthAPI.REPPLUS_V1_9_7_13 and "gfx/ui/CustomHealthAPI/hearts_v2.anm2") or "gfx/ui/CustomHealthAPI/hearts.anm2", 
		Animation = "CurseHeart",
		Flip = flip,
		Scale = scale,
		Color = color or Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255),
		RenderOffset = renderOffset,
		Other = {},
	}
	
	local playertype = player:GetPlayerType()
	local prevent = nil
	local renderOffset = renderOffset or Vector.Zero
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	local returnTable = CustomHealthAPI.Helper.RunPreRenderUnknownCurseCallback(nil, player, playerSlot, renderInfo)
	if type(returnTable) == "table" then
		if returnTable.AnimationFilename ~= nil then
			renderInfo.Filename = returnTable.AnimationFilename
		end
		if returnTable.AnimationName ~= nil then
			renderInfo.Animation = returnTable.AnimationName
		end
		if returnTable.Color ~= nil then
			renderInfo.Color = returnTable.Color
		end
		if returnTable.Scale ~= nil then
			renderInfo.Scale = returnTable.Scale
		end
		if returnTable.Flip ~= nil then
			renderInfo.Flip = returnTable.Flip
		end
		if returnTable.Offset ~= nil then
			renderInfo.RenderOffset = returnTable.Offset
		end
		if returnTable.Prevent ~= nil then
			prevent = returnTable.Prevent
		end
	elseif returnTable then
		prevent = returnTable
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	
	local func = function()
		local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(renderInfo.Filename)
		healthSprite:Play(renderInfo.Animation, true)
		healthSprite.Color = renderInfo.Color
	
		if not prevent then
			CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, 0, renderInfo.RenderOffset, 1, nil, true, flip, scale, color)
			
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
			Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_RENDER_UNKNOWN_CURSE, playertype, player, playerSlot, renderInfo)
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
		end
	end
	if shouldQueueRenders then
		table.insert(queuedRenders, func)
	else
		func()
	end
end

-- Deprecated
function CustomHealthAPI.Helper.RenderHolyMantle(player, playerSlot, renderOffset, heartsRenderedOffset, flip, scale, color)
	local numKeys, keyLimit
	if CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		numKeys = math.min(24, math.ceil(CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player) / 2) +
				               CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player) + heartsRenderedOffset)
		keyLimit = math.min(24, math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2))
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) or player:IsCoopGhost() or CustomHealthAPI.Helper.IsFoundSoul(player) then
		numKeys = 0
		keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
	else
		numKeys = #CustomHealthAPI.Helper.GetCurrentOtherHealthForRendering(player) + heartsRenderedOffset
		keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
	end
	numKeys = math.max(numKeys, 0)
	return CustomHealthAPI.Helper.RenderAfterHealthIcons(player, playerSlot, renderOffset, numKeys, flip, scale, color)
end

function CustomHealthAPI.Helper.RunPreAfterHealthIconRenderCallback(iter, player, key, playerSlot, index, indexOffset, renderInfo)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_AFTER_HEALTH_ICON_RENDER)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	local returnTable = {}
	for callback in iterator do
		if not callback.Param or callback.Param == playerType then
			local ret = callback.Function(callback.Mod, player, key, playerSlot, index, indexOffset, renderInfo)
			if ret ~= nil then
				if type(ret) == "table" then
					if ret.IndexOffset ~= nil then
						indexOffset = ret.IndexOffset
						returnTable.IndexOffset = ret.IndexOffset
					end
					if ret.Flip ~= nil then
						renderInfo.Flip = ret.Flip
						returnTable.Flip = ret.Flip
					end
					if ret.Scale ~= nil then
						renderInfo.Scale = ret.Scale
						returnTable.Scale = ret.Scale
					end
					if ret.Color ~= nil then
						renderInfo.Color = ret.Color
						returnTable.Color = ret.Color
					end
					if ret.Offset ~= nil then
						renderInfo.ExtraOffset = ret.Offset
						returnTable.Offset = ret.Offset
					end
					if ret.Prevent ~= nil then
						returnTable.Prevent = ret.Prevent
						break
					end
				elseif ret then
					returnTable.Prevent = ret
					break
				end
			end
		end
	end
	return returnTable
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_AFTER_HEALTH_ICON_RENDER] = CustomHealthAPI.Helper.RunPreAfterHealthIconRenderCallback

function CustomHealthAPI.Helper.RenderAfterHealthIcons(player, playerSlot, renderOffset, totalHealthRendered, flip, scale, color)
	local index = totalHealthRendered
	if CustomHealthAPI.Helper.CheckFadedHealth(player, isSubPlayer) then
		index = 0
	end
	
	local offsetedBy = 0
	local numColumns = 6
	local keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
	if CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		keyLimit = math.min(24, keyLimit)
	end
	if not REPENTANCE_PLUS and playerSlot ~= 0 and playerSlot ~= 4 then
		numColumns = 3
	end
	if CustomHealthAPI.Constants.HEARTS_PER_ROW > 0 then numColumns = CustomHealthAPI.Constants.HEARTS_PER_ROW end
	if index >= keyLimit and index % numColumns == 0 then
		index = index - 1
		offsetedBy = offsetedBy + 1
	end
	
	local playertype = player:GetPlayerType()
	local afterHealthIconOrder = CustomHealthAPI.Helper.GetAfterHealthIconOrder()
	local totalIconsRendered = 0
	local totalIconsOffset = 0
	for _, icons in ipairs(afterHealthIconOrder) do
		for _, key in ipairs(icons) do
			local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[key]
			if healthDefinition.ShouldRenderFunc(player) then
				local indexOffset = 0
				local renderInfo = {
					Flip = flip,
					Scale = scale,
					Color = color or Color(1.0, 1.0, 1.0, 1.0, 0/255, 0/255, 0/255), 
					RenderOffset = renderOffset, 
					ExtraOffset = Vector(0,0), 
					TotalHealthRendered = totalHealthRendered,
					Other = {},
				}
				local prevent = nil
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
				local returnTable = CustomHealthAPI.Helper.RunPreAfterHealthIconRenderCallback(nil, player, key, playerSlot, index, indexOffset, renderInfo)
				if type(returnTable) == "table" then
					if returnTable.IndexOffset ~= nil then
						indexOffset = returnTable.IndexOffset
					end
					if returnTable.Flip ~= nil then
						renderInfo.Flip = returnTable.Flip
					end
					if returnTable.Scale ~= nil then
						renderInfo.Scale = returnTable.Scale
					end
					if returnTable.Color ~= nil then
						renderInfo.Color = returnTable.Color
					end
					if returnTable.Offset ~= nil then
						renderInfo.ExtraOffset = returnTable.Offset
					end
					if returnTable.Prevent ~= nil then
						prevent = returnTable.Prevent
					end
				elseif returnTable then
					prevent = returnTable
				end
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
				
				if not prevent then
					local extraOffset = renderInfo.ExtraOffset
					if offsetedBy >= 1 then
						renderInfo.ExtraOffset = Vector(CustomHealthAPI.Constants.HEART_PIXEL_WIDTH_DEFAULT * (REPENTANCE_PLUS and 1 or 0.5), 0)
						renderInfo.ExtraOffset = renderInfo.ExtraOffset + Vector(CustomHealthAPI.Constants.HEART_PIXEL_WIDTH_DEFAULT * (offsetedBy - 1), 0)
					end
					
					healthDefinition.OnRenderFunc(player, playerSlot, index + indexOffset, renderInfo)
					
					CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
					Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_AFTER_HEALTH_ICON_RENDER, playertype, player, key, playerSlot, index + indexOffset, renderInfo)
					CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
					
					totalIconsRendered = totalIconsRendered + 1
					totalIconsOffset = totalIconsOffset + ((offsetedBy > 0 and 1) or 0)
					
					index = index + 1
					if index >= keyLimit and index % numColumns == 0 then
						index = index - 1
						offsetedBy = offsetedBy + 1
					end
				end
			end
		end
	end
	
	return totalIconsRendered, totalIconsOffset
end

function CustomHealthAPI.Helper.RunPreRenderLivesCallback(iter, player, numLives, isChance, ignoredHealth)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_LIVES)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	local returnTable = {}
	for callback in iterator do
		if not callback.Param or callback.Param == playerType then
			local ret = callback.Function(callback.Mod, player, numLives, isChance, ignoredHealth)
			if ret ~= nil then
				if ret.Prevent == true then
					returnTable.Prevent = ret.Prevent
					break
				end
				if ret.Lives ~= nil then
					numLives = ret.Lives
					returnTable.Lives = ret.Lives
				end
				if ret.IsChance ~= nil then
					isChance = ret.IsChance
					returnTable.IsChance = ret.IsChance
				end
				if ret.Force ~= nil then
					returnTable.Force = ret.Force
				end
				if ret.IgnoreNumHearts ~= nil then
					ignoredHealth = ret.IgnoreNumHearts
					returnTable.IgnoreNumHearts = ret.IgnoreNumHearts
				end
				if ret.Offset ~= nil then
					returnTable.Offset = ret.Offset
				end
			end
		end
	end
	return returnTable
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_RENDER_LIVES] = CustomHealthAPI.Helper.RunPreRenderLivesCallback

function CustomHealthAPI.Helper.RenderLives(player, playerSlot, renderOffset, totalHealthRendered, numRowsRendered, numColumnsRendered, flip, scale, color)
	if not REPENTANCE_PLUS and (playerSlot == 1 or playerSlot == 2 or playerSlot == 3 or playerSlot == -1) then -- Players 2-4 + Soulstones / Strawman / etc.
		-- i'm actually surprised to see they don't render extra lives in basegame not gonna lie
		return
	end
	
	renderOffset = renderOffset or Vector.Zero
	scale = scale or Vector.One
	color = color or KColor.White
	if not color.Alpha then color = KColor(color.R,color.G,color.B,color.A) end
	
	local game = Game()
	local bottomRight = game:GetRoom():GetRenderSurfaceTopLeft() * 2 + Vector(442,286) -- thank-q stageapi
	local hudOffset = Options.HUDOffset * 10
	local heartDistanceX = CustomHealthAPI.Constants.HEART_PIXEL_WIDTH_DEFAULT * scale.X
	local heartDistanceY = CustomHealthAPI.Constants.HEART_PIXEL_HEIGHT_DEFAULT * scale.Y

	local numLives = player:GetExtraLives()
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
	
	if CustomHealthAPI.PersistentData.CombineLivesOfTwins[player:GetPlayerType()] then
		local twin = player:GetOtherTwin()
		if twin then
			numLives = numLives + twin:GetExtraLives()
			if REPENTOGON then
				if twin:HasChanceRevive() then
					isChance = true
				end
			else
				if twin:HasCollectible(CollectibleType.COLLECTIBLE_GUPPYS_COLLAR) or twin:HasTrinket(TrinketType.TRINKET_BROKEN_ANKH) then
					isChance = true
				end
			end
		end
	end
	
	local playertype = player:GetPlayerType()
	local ignoredHealth = 0
	local overrideLivesCheck = false
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	local returnTable = CustomHealthAPI.Helper.RunPreRenderLivesCallback(nil, player, numLives, isChance, ignoredHealth)
	if returnTable ~= nil then
		if returnTable.Prevent == true then
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
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
		if returnTable.Offset ~= nil then
			renderOffset = returnTable.Offset
		end
	end
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1

	if numLives <= 0 and not overrideLivesCheck then
		return
	end
	local livesString = (flip and (numLives .. ((isChance and "?") or "") .. "x")) or ("x" .. numLives .. ((isChance and "?") or ""))
	
	local numRows = math.max(0, numRowsRendered - 1) / 2
	local numColumns = numColumnsRendered
	
	local pos, esauFlipped = CustomHealthAPI.Helper.GetHealthBarPos(player, playerSlot, totalHealthRendered)
	
	if esauFlipped then
		local livesStringWidth = CustomHealthAPI.Constants.FONT:GetStringWidth(livesString)
		pos = pos + Vector(-4 + math.floor(hudOffset * 1.6 + 0.5) - livesStringWidth - heartDistanceX * numColumns,
		                   -10 + math.floor(hudOffset * 1.2 + 0.5) / 2 + 8 * numRows)
		if REPENTANCE_PLUS then
			pos = pos + Vector(-10, -4)
		end
	else
		pos = pos + Vector(-2 + heartDistanceX * numColumns,
		                   -8 + 8 * numRows)
	end
	pos = pos + (renderOffset * scale) + game.ScreenShakeOffset
	
	CustomHealthAPI.Constants.FONT:DrawStringScaled(livesString, pos.X, pos.Y, scale.X, scale.Y, color, 0, true)
	
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
	Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_RENDER_LIVES, playertype, player, pos, numLives, isChance, livesString)
	CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
end

function CustomHealthAPI.Helper.RunBelowHealthIconRenderCallback(iter, player, key, playerSlot, row, renderInfo)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_BELOW_HEALTH_ICON_RENDER)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	local returnTable = {}
	for callback in iterator do
		if not callback.Param or callback.Param == playerType then
			local ret = callback.Function(callback.Mod, player, key, playerSlot, row, renderInfo)
			if ret ~= nil then
				if type(ret) == "table" then
					if ret.Row ~= nil then
						row = ret.Row
						returnTable.Row = ret.Row
					end
					if ret.Offset ~= nil then
						renderInfo.ExtraOffset = ret.Offset
						returnTable.Offset = ret.Offset
					end
					if ret.Prevent ~= nil then
						returnTable.Prevent = ret.Prevent
						break
					end
				elseif ret then
					returnTable.Prevent = ret
					break
				end
			end
		end
	end
	return returnTable
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_BELOW_HEALTH_ICON_RENDER] = CustomHealthAPI.Helper.RunBelowHealthIconRenderCallback

function CustomHealthAPI.Helper.GetBelowHealthIconsToRender(player, playerSlot, isUnknownCurse)
	local belowHealthIconsToRender = {}
	local rowsUsed = 0
	local playertype = player:GetPlayerType()
	local belowHealthIconOrder = CustomHealthAPI.Helper.GetBelowHealthIconOrder()
	for _, icons in ipairs(belowHealthIconOrder) do
		for _, key in ipairs(icons) do
			local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[key]
			if (not isUnknownCurse or healthDefinition.IgnoreUnknownCurse) and 
			   healthDefinition.ShouldRenderFunc(player) and 
			   Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.SHOULD_RENDER_BELOW_HEALTH_ICON, playertype, player, key, playerSlot) == nil
			then
				table.insert(belowHealthIconsToRender, key)
				rowsUsed = rowsUsed + healthDefinition.RowsUsed
			end
		end
	end
	
	return belowHealthIconsToRender, rowsUsed
end

function CustomHealthAPI.Helper.RenderBelowHealthIcons(player, playerSlot, renderOffset, belowHealthIconsToRender, totalHealthRendered, totalRowsRendered, isUnknownCurse, keyLimitOverride, flip, scale, color)
	local maxColumns = 6
	if not REPENTANCE_PLUS and playerSlot ~= 0 and playerSlot ~= 4 then
		maxColumns = 3
	end
	local keyLimit 
	if keyLimitOverride then
		keyLimit = keyLimitOverride
	else
		keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
		if CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
			keyLimit = math.min(24, keyLimit)
		end
	end
	
	local playertype = player:GetPlayerType()
	local currentRow = math.max(totalRowsRendered, math.ceil(keyLimit / maxColumns))
	local topOfScreen = playerSlot == 0 or 
	                    (playerSlot % 4 == 0 and CustomHealthAPI.PersistentData.NumOccupiedPlayerHUDs > 3) or 
	                    playerSlot % 4 == 1
	if topOfScreen and (playertype == PlayerType.PLAYER_ISAAC_B or playertype == PlayerType.PLAYER_BLUEBABY_B) then
		if REPENTANCE_PLUS and
		   ((playerSlot == 0 and CustomHealthAPI.PersistentData.PlayerOneHasMultiplayerHUD) or (playerSlot % 4 == 0 and CustomHealthAPI.PersistentData.NumOccupiedPlayerHUDs > 3) or playerSlot % 4 == 1)
		then
			if playertype == PlayerType.PLAYER_ISAAC_B and currentRow <= 5 then
				currentRow = currentRow + 2
				renderOffset = renderOffset + Vector(0, -1.5)
			elseif playertype == PlayerType.PLAYER_BLUEBABY_B then
				currentRow = currentRow + 1
				renderOffset = renderOffset + Vector(0, 3)
			end
		else
			if playertype == PlayerType.PLAYER_ISAAC_B and currentRow <= 5 then
				renderOffset = renderOffset + Vector(0, 5)
			end
		end
		currentRow = currentRow + 2
	end
	local index = currentRow * maxColumns
	
	local belowHealthIconOrder = CustomHealthAPI.Helper.GetBelowHealthIconOrder()
	for _, key in ipairs(belowHealthIconsToRender) do
		local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[key]
		if REPENTANCE_PLUS and
		   ((playerSlot == 0 and CustomHealthAPI.PersistentData.PlayerOneHasMultiplayerHUD) or (playerSlot % 4 == 0 and CustomHealthAPI.PersistentData.NumOccupiedPlayerHUDs > 3) or playerSlot % 4 == 1) and 
		   currentRow <= 2 and currentRow + healthDefinition.RowsUsed - 1 >= 2 
		then
			currentRow = 3
			index = currentRow * maxColumns
		end

		local rowOffset = 0
		local renderInfo = {
			Flip = flip,
			Scale = scale,
			Color = color,
			RenderOffset = renderOffset, 
			ExtraOffset = Vector(0,0), 
			TotalHealthRendered = totalHealthRendered,
			Other = {},
		}
		local prevent = nil
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
		local returnTable = CustomHealthAPI.Helper.RunBelowHealthIconRenderCallback(nil, player, key, playerSlot, (index / maxColumns) + rowOffset, renderInfo)
		if type(returnTable) == "table" then
			if returnTable.Row ~= nil then
				rowOffset = returnTable.Row - (index / maxColumns)
			end
			if returnTable.Flip ~= nil then
				renderInfo.Flip = returnTable.Flip
			end
			if returnTable.Scale ~= nil then
				renderInfo.Scale = returnTable.Scale
			end
			if returnTable.Color ~= nil then
				renderInfo.Color = returnTable.Color
			end
			if returnTable.Offset ~= nil then
				renderInfo.ExtraOffset = returnTable.Offset
			end
			if returnTable.Prevent ~= nil then
				prevent = returnTable.Prevent
			end
		elseif returnTable then
			prevent = returnTable
		end
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1

		if not prevent then
			healthDefinition.OnRenderFunc(player, playerSlot, index + rowOffset * maxColumns + ((playerSlot == 4 and CustomHealthAPI.PersistentData.NumOccupiedPlayerHUDs <= 3 and 5) or 0), renderInfo)

			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
			Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_BELOW_HEALTH_ICON_RENDER, playertype, player, key, playerSlot, index + rowOffset * maxColumns, renderInfo)
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
		end
		
		index = index + maxColumns * healthDefinition.RowsUsed
		currentRow = currentRow + healthDefinition.RowsUsed
	end
	
	if not topOfScreen and (playertype == PlayerType.PLAYER_ISAAC_B or playertype == PlayerType.PLAYER_BLUEBABY_B) then
		currentRow = currentRow + 2
	end
	
	return currentRow
end

function CustomHealthAPI.Helper.RunPreRenderHpBarCallback(iter, player, playerSlot, renderOffset, flip)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HP_BAR)
		local k = nil
		iterator = function()
			local v
			k, v = next(t, k)
			return v
		end
	end
	
	local playerType = player:GetPlayerType()
	local returnTable = {}
	for callback in iterator do
		if not callback.Param or callback.Param == playerType then
			local ret = callback.Function(callback.Mod, player, playerSlot, renderOffset, flip)
			if ret ~= nil then
				if type(ret) == "table" then
					if ret.PlayerSlot ~= nil then
						playerSlot = ret.PlayerSlot
						returnTable.PlayerSlot = ret.PlayerSlot
					end
					if ret.Offset ~= nil then
						renderOffset = ret.Offset
						returnTable.Offset = ret.Offset
					end
					if ret.Flip ~= nil then
						flip = ret.Flip
						returnTable.Flip = ret.Flip
					end
					if ret.Prevent ~= nil then
						returnTable.Prevent = ret.Prevent
						break
					end
				elseif ret then
					returnTable.Prevent = ret
					break
				end
			end
		end
	end
	return returnTable
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HP_BAR] = CustomHealthAPI.Helper.RunPreRenderHpBarCallback

function CustomHealthAPI.Helper.RenderPlayerHPBar(truePlayer, playerSlot, renderOffset, renderingThroughTwin, ignoreCurse, flip, scale, color)
	local player = truePlayer	
	local playertype = player:GetPlayerType()
	if not renderingThroughTwin and CustomHealthAPI.PersistentData.RenderTwinBelowMain[playertype] then
		Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.PRE_CHECK_SWAP_TWIN_RENDERING, playertype, player)
		
		local data = CustomHealthAPI.Helper.GetOtherData(player)
		if data.SwapTwinBelowMainRendering then
			player = player:GetOtherTwin()
		end
	end
	
	local hasUnknownCurse = not ignoreCurse and Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_THE_UNKNOWN ~= 0
	local playerSlot = playerSlot
	local renderOffset = renderOffset or Vector.Zero
	local scale = scale or Vector.One
	local color = color or Color(1, 1, 1)
	if not hasUnknownCurse then
		local prevent = nil
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
		local returnTable = CustomHealthAPI.Helper.RunPreRenderHpBarCallback(nil, player, playerSlot, renderOffset, flip, scale, color)
		if type(returnTable) == "table" then
			playerSlot = returnTable.PlayerSlot or playerSlot
			renderOffset = returnTable.Offset or renderOffset
			flip = returnTable.Flip or flip
			scale = returnTable.Scale or scale
			color = returnTable.Color or color
			if returnTable.Prevent ~= nil then
				prevent = returnTable.Prevent
			end
		elseif returnTable then
			prevent = returnTable
		end
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
		if prevent then return nil, 0, 0 end
	end

	local maxColumns = 6
	if not REPENTANCE_PLUS and playerSlot ~= 0 and playerSlot ~= 4 then
		maxColumns = 3
	end
	if CustomHealthAPI.Constants.HEARTS_PER_ROW > 0 then maxColumns = CustomHealthAPI.Constants.HEARTS_PER_ROW end
	local isFadedHealth = CustomHealthAPI.Helper.CheckFadedHealth(player, false)
	local onBottomOfScreen = playerSlot > 0 and (playerSlot % 4 == 2 or playerSlot % 4 == 3 or (playerSlot % 4 == 0 and not (REPENTANCE_PLUS and CustomHealthAPI.PersistentData.NumOccupiedPlayerHUDs > 3)))

	if not renderingThroughTwin then
		shouldQueueRenders = true
		queuedRenders = {}
	end
	
	local belowHealthIconsToRender, belowHealthRows = {}, 0
	if not renderingThroughTwin then
		belowHealthIconsToRender, belowHealthRows = CustomHealthAPI.Helper.GetBelowHealthIconsToRender(player, playerSlot, hasUnknownCurse)
		local doExtraBelowHealthOffset = false
		for _, key in ipairs(belowHealthIconsToRender) do
			local healthDefinition = CustomHealthAPI.PersistentData.HealthDefinitions[key]
			if not healthDefinition.OffsetAsHP then
				doExtraBelowHealthOffset = true
				break
			end
		end
		if playertype == PlayerType.PLAYER_ISAAC_B or playertype == PlayerType.PLAYER_BLUEBABY_B then
			belowHealthRows = belowHealthRows + 2
			doExtraBelowHealthOffset = true
		end
		if onBottomOfScreen then
			local numRows = belowHealthRows
			
			local keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
			if CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
				keyLimit = math.min(24, keyLimit)
			end
			numRows = numRows + math.ceil(keyLimit / maxColumns)
			
			local subPlayer = player:GetSubPlayer()
			if subPlayer ~= nil	then
				local keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(subPlayer) / 2)
				if CustomHealthAPI.Helper.PlayerHasCoinHealth(subPlayer) then
					keyLimit = math.min(24, keyLimit)
				end
				numRows = numRows + math.ceil(keyLimit / maxColumns)
			end
			
			local twin = player:GetOtherTwin()
			if twin ~= nil and CustomHealthAPI.PersistentData.RenderTwinBelowMain[playertype] then
				local keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(twin) / 2)
				if CustomHealthAPI.Helper.PlayerHasCoinHealth(twin) then
					keyLimit = math.min(24, keyLimit)
				end
				numRows = numRows + math.ceil(keyLimit / maxColumns)
			
				local subtwin = twin:GetSubPlayer()
				if subtwin ~= nil then
					local keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(subtwin) / 2)
					if CustomHealthAPI.Helper.PlayerHasCoinHealth(subtwin) then
						keyLimit = math.min(24, keyLimit)
					end
					numRows = numRows + math.ceil(keyLimit / maxColumns)
				end
			end
			
			renderOffset = renderOffset - Vector(0, CustomHealthAPI.Constants.HEART_PIXEL_HEIGHT_DEFAULT * scale.Y * math.max(0, numRows - 2) + ((belowHealthRows > 0 and doExtraBelowHealthOffset and 2) or 0))
		end
	end
	
	local totalHealthRendered, totalIconsRendered, totalIconsOffset = 0, 0, 0
	local numRowsRendered, numColumnsRendered = 0, 0
	if hasUnknownCurse then
		CustomHealthAPI.Helper.RenderCurseOfTheUnknown(player, playerSlot, renderOffset, flip, scale, color)
		numRowsRendered = 1
		numColumnsRendered = 1
	elseif CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
		totalHealthRendered = CustomHealthAPI.Helper.RenderKeeperHealth(player, playerSlot, renderOffset, flip, scale, color)
		totalIconsRendered, totalIconsOffset = CustomHealthAPI.Helper.RenderAfterHealthIcons(player, playerSlot, renderOffset, totalHealthRendered, flip, scale, color)
		
		numRowsRendered = math.max(0, math.ceil((totalHealthRendered + totalIconsRendered - totalIconsOffset) / maxColumns))
		numColumnsRendered = math.max(0, math.min(totalHealthRendered + totalIconsRendered - totalIconsOffset, maxColumns) + totalIconsOffset)
		if isFadedHealth then
			local fadedRowsRendered = math.max(0, math.ceil(totalHealthRendered / maxColumns))
			local unfadedRowsRendered = math.max(0, math.ceil((totalIconsRendered - totalIconsOffset) / maxColumns))
			numRowsRendered = math.max(fadedRowsRendered, unfadedRowsRendered)
			
			local fadedColumnsRendered = math.max(0, math.min(totalHealthRendered, maxColumns))
			local unfadedColumnsRendered = math.max(0, math.min(totalIconsRendered - totalIconsOffset, maxColumns) + totalIconsOffset)
			numColumnsRendered = math.max(fadedColumnsRendered, unfadedColumnsRendered)
		end
	elseif CustomHealthAPI.Helper.PlayerIsHealthless(player, true) then
		totalIconsRendered, totalIconsOffset = CustomHealthAPI.Helper.RenderAfterHealthIcons(player, playerSlot, renderOffset, totalHealthRendered, flip, scale, color)
		
		numRowsRendered = math.max(0, math.ceil((totalHealthRendered + totalIconsRendered - totalIconsOffset) / maxColumns))
		numColumnsRendered = math.max(0, math.min(totalHealthRendered + totalIconsRendered - totalIconsOffset, maxColumns) + totalIconsOffset)
		if isFadedHealth then
			local fadedRowsRendered = math.max(0, math.ceil(totalHealthRendered / maxColumns))
			local unfadedRowsRendered = math.max(0, math.ceil((totalIconsRendered - totalIconsOffset) / maxColumns))
			numRowsRendered = math.max(fadedRowsRendered, unfadedRowsRendered)
			
			local fadedColumnsRendered = math.max(0, math.min(totalHealthRendered, maxColumns))
			local unfadedColumnsRendered = math.max(0, math.min(totalIconsRendered - totalIconsOffset, maxColumns) + totalIconsOffset)
			numColumnsRendered = math.max(fadedColumnsRendered, unfadedColumnsRendered)
		end
	elseif CustomHealthAPI.Helper.PlayerIsIgnored(player) or player:IsCoopGhost() or CustomHealthAPI.Helper.IsFoundSoul(player) then
		--do nothing
		return false, 0, 0
	else
		totalHealthRendered = CustomHealthAPI.Helper.RenderCustomHealthOfPlayer(player, playerSlot, false, renderOffset, nil, nil, flip, scale, color)
		totalIconsRendered, totalIconsOffset = CustomHealthAPI.Helper.RenderAfterHealthIcons(player, playerSlot, renderOffset, totalHealthRendered, flip, scale, color)
		
		numRowsRendered = math.max(0, math.ceil((totalHealthRendered + totalIconsRendered - totalIconsOffset) / maxColumns))
		numColumnsRendered = math.max(0, math.min(totalHealthRendered + totalIconsRendered - totalIconsOffset, maxColumns) + totalIconsOffset)
		if isFadedHealth then
			local fadedRowsRendered = math.max(0, math.ceil(totalHealthRendered / maxColumns))
			local unfadedRowsRendered = math.max(0, math.ceil((totalIconsRendered - totalIconsOffset) / maxColumns))
			numRowsRendered = math.max(fadedRowsRendered, unfadedRowsRendered)
			
			local fadedColumnsRendered = math.max(0, math.min(totalHealthRendered, maxColumns))
			local unfadedColumnsRendered = math.max(0, math.min(totalIconsRendered - totalIconsOffset, maxColumns) + totalIconsOffset)
			numColumnsRendered = math.max(fadedColumnsRendered, unfadedColumnsRendered)
		end
	
		local subPlayer = player:GetSubPlayer()
		if subPlayer ~= nil	then
			shouldQueueRenders = false
			
			local totalSubHealthRendered = CustomHealthAPI.Helper.RenderCustomHealthOfPlayer(subPlayer, playerSlot, true, renderOffset, numRowsRendered * maxColumns, player, flip, scale, color)
			local numSubRowsRendered = math.max(0, math.ceil(totalSubHealthRendered / maxColumns))
			local numSubColumnsRendered = math.max(0, math.min(totalSubHealthRendered, maxColumns))
			numRowsRendered = numRowsRendered + numSubRowsRendered
			numColumnsRendered = math.max(numColumnsRendered, numSubColumnsRendered)
		end
	end
	shouldQueueRenders = false

	local keyLimitOverride = nil
	local renderOffsetFromTwin = Vector(0,0)
	if not ((hasUnknownCurse and not CustomHealthAPI.PersistentData.RenderTwinBelowMainThroughUnknown[playertype]) or renderingThroughTwin) and 
	   CustomHealthAPI.PersistentData.RenderTwinBelowMain[playertype] 
	then
		local twin = player:GetOtherTwin()
		if twin ~= nil and twin:Exists() then
			local keyLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(player) / 2)
			if CustomHealthAPI.Helper.PlayerHasCoinHealth(player) then
				keyLimit = math.min(24, keyLimit)
			end
			local twinRenderOffset = renderOffset + 
									 Vector(0, CustomHealthAPI.Constants.HEART_PIXEL_HEIGHT_DEFAULT * math.max(numRowsRendered, math.ceil(keyLimit / maxColumns))) +
									 (CustomHealthAPI.PersistentData.TwinRenderOffset[playertype] or Vector(0,0))
			
			local _, numTwinRowsRendered, numTwinColumnsRendered = CustomHealthAPI.Helper.RenderPlayerHPBar(twin, playerSlot, twinRenderOffset, true, ignoreCurse, flip, scale, color)
			if numTwinColumnsRendered >= numColumnsRendered then
				renderOffsetFromTwin = Vector(math.max(0, (CustomHealthAPI.PersistentData.TwinRenderOffset[playertype] or Vector(0,0)).X), 0)
			end
			numRowsRendered = numRowsRendered + numTwinRowsRendered
			numColumnsRendered = math.max(numColumnsRendered, numTwinColumnsRendered)
			
			local twinLimit = math.ceil(CustomHealthAPI.Helper.GetTrueHeartLimit(twin) / 2)
			if CustomHealthAPI.Helper.PlayerHasCoinHealth(twin) then
				twinLimit = math.min(24, twinLimit)
			end
			
			keyLimitOverride = math.ceil(keyLimit / maxColumns) * maxColumns + twinLimit
		end
	end
	
	if not renderingThroughTwin then
		for _, func in ipairs(queuedRenders) do
			func()
		end
		queuedRenders = {}
	end
	
	if REPENTOGON and not (hasUnknownCurse or renderingThroughTwin) then
		CustomHealthAPI.Helper.RenderLives(truePlayer, playerSlot, renderOffset + renderOffsetFromTwin, totalHealthRendered, numRowsRendered, numColumnsRendered, flip, scale, color) 
	end
	
	if not renderingThroughTwin then
		numRowsRendered = CustomHealthAPI.Helper.RenderBelowHealthIcons(truePlayer, playerSlot, renderOffset, belowHealthIconsToRender, totalHealthRendered, numRowsRendered, hasUnknownCurse, keyLimitOverride, flip, scale, color)
	end

	if not hasUnknownCurse then
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
		Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HP_BAR, playertype, player, playerSlot, renderOffset, totalHealthRendered, flip, scale, color)
		CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
	end

	if REPENTANCE_PLUS or REPENTOGON then
		local barPos, esauFlipped = CustomHealthAPI.Helper.GetHealthBarPos(player, playerSlot, totalHealthRendered)
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

	return true, numRowsRendered, numColumnsRendered
end

function CustomHealthAPI.Helper.RenderCustomHealth()
	if CustomHealthAPI.PersistentData.DisableCustomHealthRendering or
	   Game():GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD) or
	   (StageAPI ~= nil and StageAPI.PlayingBossSprite) or
	   not Game():GetHUD():IsVisible() or
	   CustomHealthAPI.PersistentData.CancelCustomHealthRenderingRepentogon
	then
		return
	end

	local nextPlayerSlot = 0
	local foundControllerIdx = {}
	local mainPlayers = {}
	local twinPlayers = {}
	local numOccupiedPlayerHUDs = 0

	CustomHealthAPI.PersistentData.PlayerOneHasMultiplayerHUD = false
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		local playertype = player:GetPlayerType()
		local controllerIndex = player.ControllerIndex

		if player.Parent == nil and not foundControllerIdx[controllerIndex] then
			foundControllerIdx[controllerIndex] = true
			mainPlayers[nextPlayerSlot] = player
			numOccupiedPlayerHUDs = numOccupiedPlayerHUDs + 1
			CustomHealthAPI.PersistentData.PlayerOneHasMultiplayerHUD = CustomHealthAPI.PersistentData.PlayerOneHasMultiplayerHUD or nextPlayerSlot >= 2

			if CustomHealthAPI.PersistentData.RenderTwin[playertype] and player:GetOtherTwin() ~= nil and (nextPlayerSlot == 0 or REPENTANCE_PLUS) then
				twinPlayers[nextPlayerSlot] = player:GetOtherTwin()
				numOccupiedPlayerHUDs = numOccupiedPlayerHUDs + 1
			end

			nextPlayerSlot = nextPlayerSlot + 1

			if nextPlayerSlot > 3 then
				break
			end
		end
	end

	CustomHealthAPI.PersistentData.NumOccupiedPlayerHUDs = numOccupiedPlayerHUDs

	for playerSlot = 0, 3 do
		if not mainPlayers[playerSlot] then
			break
		end
		
		if playerSlot == 0 or playerSlot == 1 then
			local _, numRowsRendered = CustomHealthAPI.Helper.RenderPlayerHPBar(mainPlayers[playerSlot], playerSlot)
			if twinPlayers[playerSlot] then
				local renderOffset = nil
				if (playerSlot == 0 and numOccupiedPlayerHUDs > 3) or playerSlot == 1 then
					renderOffset = Vector(0, math.max(0, (numRowsRendered or 0) - 2) * CustomHealthAPI.Constants.HEART_PIXEL_HEIGHT_DEFAULT)
				end
				CustomHealthAPI.Helper.RenderPlayerHPBar(twinPlayers[playerSlot], playerSlot + 4, renderOffset)
			end
		elseif playerSlot == 2 or playerSlot == 3 then
			local renderOffset = nil
			if twinPlayers[playerSlot] then
				local _, numRowsRendered = CustomHealthAPI.Helper.RenderPlayerHPBar(twinPlayers[playerSlot], playerSlot + 4, Vector(0, -18.5))
				renderOffset = Vector(0, math.max(0, (numRowsRendered or 0) - 2) * CustomHealthAPI.Constants.HEART_PIXEL_HEIGHT_DEFAULT * -1 - 18.5)
			end
			CustomHealthAPI.Helper.RenderPlayerHPBar(mainPlayers[playerSlot], playerSlot, renderOffset)
		end
	end
end
