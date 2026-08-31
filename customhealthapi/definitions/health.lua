CustomHealthAPI.Library.RegisterRedHealth("RED_HEART", 
	{MaxHP = 2,
	 AnimationFilenames = {EMPTY_HEART = "gfx/ui/CustomHealthAPI/hearts.anm2",
	                       BONE_HEART = "gfx/ui/CustomHealthAPI/hearts.anm2"},								  
	 AnimationNames = {EMPTY_HEART = {"RedHeartHalf", "RedHeartFull"},
	                   BONE_HEART = {"BoneHeartHalf", "BoneHeartFull"}},
	 SortOrder = 0, 
	 AddPriority = 0,
	 HealFlashRO = 128/255, 
	 HealFlashGO = 0/255, 
	 HealFlashBO = 0/255,
	 CollectSound = SoundEffect.SOUND_BOSS2_BUBBLES,
	 ProtectsDealChance = false,
	 PrioritizeHealing = true})
	
CustomHealthAPI.Library.RegisterRedHealth("COIN_HEART", 
	{MaxHP = 2,
	 AnimationFilenames = {EMPTY_COIN_HEART = "gfx/ui/CustomHealthAPI/hearts.anm2"},								  
	 AnimationNames = {EMPTY_COIN_HEART = {"CoinHeartHalf", "CoinHeartFull"}},
	 SortOrder = 0, 
	 AddPriority = 0,
	 HealFlashRO = 128/255, 
	 HealFlashGO = 100/255, 
	 HealFlashBO = 20/255,
	 ProtectsDealChance = true,
	 PrioritizeHealing = true})
	
CustomHealthAPI.Library.RegisterRedHealth("ROTTEN_HEART", 
	{MaxHP = 1,
	 AnimationFilenames = {EMPTY_HEART = "gfx/ui/CustomHealthAPI/hearts.anm2",
	                       BONE_HEART = "gfx/ui/CustomHealthAPI/hearts.anm2"},								  
	 AnimationNames = {EMPTY_HEART = {"RottenHeartFull"},
	                   BONE_HEART = {"RottenBoneHeartFull"}},
	 SortOrder = 100, 
	 AddPriority = 100,
	 HealFlashRO = 60/255, 
	 HealFlashGO = 128/255, 
	 HealFlashBO = 0/255,
	 CollectSound = SoundEffect.SOUND_ROTTEN_HEART,
	 ProtectsDealChance = true,
	 PrioritizeHealing = false})

CustomHealthAPI.Library.RegisterSoulHealth("SOUL_HEART", 
	{MaxHP = 2, 
	 AnimationFilename = "gfx/ui/CustomHealthAPI/hearts.anm2",
	 AnimationName = {"BlueHeartHalf", "BlueHeartFull"},
	 SortOrder = 100, 
	 AddPriority = 100,
	 HealFlashRO = 50/255, 
	 HealFlashGO = 70/255,
	 HealFlashBO = 90/255,
	 CollectSound = SoundEffect.SOUND_HOLY,
	 PrioritizeHealing = true})

CustomHealthAPI.Library.RegisterSoulHealth("BLACK_HEART", 
	{MaxHP = 2,
	 AnimationFilename = "gfx/ui/CustomHealthAPI/hearts.anm2",
	 AnimationName = {"BlackHeartHalf", "BlackHeartFull"},
	 SortOrder = 100, 
	 AddPriority = 150,
	 HealFlashRO = 80/255, 
	 HealFlashGO = 26/255,
	 HealFlashBO = 26/255,
	 CollectSound = SoundEffect.SOUND_UNHOLY,
	 PrioritizeHealing = false})

CustomHealthAPI.Library.RegisterHealthContainer("EMPTY_HEART", 
	{MaxHP = 0,
	 AnimationFilename = "gfx/ui/CustomHealthAPI/hearts.anm2",
	 AnimationName = "EmptyHeart",
	 SortOrder = 0, 
	 AddPriority = 100, 
	 RemovePriority = 0, 
	 ProtectsDealChance = false, 
	 CanHaveHalfCapacity = true,
	 ForceBleedingIfFilled = false})

CustomHealthAPI.Library.RegisterHealthContainer("EMPTY_COIN_HEART", 
	{MaxHP = 0,
	 AnimationFilename = "gfx/ui/CustomHealthAPI/hearts.anm2",
	 AnimationName = "CoinEmpty",
	 SortOrder = 0, 
	 AddPriority = 100, 
	 RemovePriority = 0, 
	 ProtectsDealChance = true, 
	 CanHaveHalfCapacity = true,
	 ForceBleedingIfFilled = false})

CustomHealthAPI.Library.RegisterHealthContainer("BONE_HEART", 
	{MaxHP = 1,
	 AnimationFilename = "gfx/ui/CustomHealthAPI/hearts.anm2",
	 AnimationName = "BoneHeartEmpty",
	 LayeredAnimationFilename = "gfx/ui/CustomHealthAPI/bone_heart_layered.anm2",
	 LayeredAnimationName = "BoneHeartLayered",
	 SortOrder = 100, 
	 AddPriority = 0, 
	 RemovePriority = 100, 
	 CollectSound = SoundEffect.SOUND_BONE_HEART,
	 ProtectsDealChance = true, 
	 DamageGate = true,
	 CanHaveHalfCapacity = false,
	 ForceBleedingIfFilled = false})

CustomHealthAPI.Library.RegisterHealthContainer("BROKEN_HEART", 
	{MaxHP = 0,
	 AnimationFilename = "gfx/ui/CustomHealthAPI/hearts.anm2",
	 AnimationName = "BrokenHeart",
	 SortOrder = 999999, 
	 AddPriority = 999999, 
	 RemovePriority = 999999, 
	 ProtectsDealChance = true, 
	 CanHaveHalfCapacity = false,
	 ForceBleedingIfFilled = false})

CustomHealthAPI.Library.RegisterHealthContainer("BROKEN_COIN_HEART", 
	{MaxHP = 0,
	 AnimationFilename = "gfx/ui/CustomHealthAPI/hearts.anm2",
	 AnimationName = "BrokenCoinHeart",
	 SortOrder = 999999, 
	 AddPriority = 999999, 
	 RemovePriority = 999999, 
	 ProtectsDealChance = true, 
	 CanHaveHalfCapacity = false,
	 ForceBleedingIfFilled = false})

CustomHealthAPI.Library.RegisterHealthOverlay("ETERNAL_HEART", 
	{MaxHP = 2,
	 AnimationFilename = "gfx/ui/CustomHealthAPI/hearts.anm2",
	 AnimationName = "WhiteHeartOverlay", 
	 OverlayLayerOrder = -100,
	 AllowSharedOverlayLayer = true,
	 StickyOverlay = false,
	 OverlayFlags = CustomHealthAPI.Enums.OverlayFlagSets.ETERNAL,
	 DamageGate = false,
	 SortOrder = 0,
	 AddPriority = 0,
	 CollectSound = SoundEffect.SOUND_SUPERHOLY,
	 IgnoreBleeding = false})

CustomHealthAPI.Library.RegisterHealthOverlay("GOLDEN_HEART", 
	{MaxHP = 0,
	 AnimationFilename = "gfx/ui/CustomHealthAPI/hearts.anm2",
	 AnimationName = "GoldHeartOverlay", 
	 OverlayLayerOrder = 0,
	 AllowSharedOverlayLayer = true,
	 OverlayFlags = CustomHealthAPI.Enums.OverlayFlagSets.GOLDEN,
	 SortOrder = 0,
	 AddPriority = 0,
	 HealFlashRO = 128/255, 
	 HealFlashGO = 100/255, 
	 HealFlashBO = 20/255,
	 CollectSound = SoundEffect.SOUND_GOLD_HEART,
	 IgnoreBleeding = true})

function CustomHealthAPI.Helper.RunPreRenderHolyMantleCallback(iter, player, healthIndex, extraOffset, flip, scale, color)
	local iterator = iter
	if iterator == nil then
		local t = Isaac.GetCallbacks(CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HOLY_MANTLE)
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
			local ret = callback.Function(callback.Mod, player, healthIndex, extraOffset, flip, scale, color)
			if ret ~= nil then
				if ret.Index ~= nil then
					healthIndex = ret.Index
					returnTable.Index = ret.Index
				end
				if ret.Offset ~= nil then
					extraOffset = ret.Offset
					returnTable.Offset = ret.Offset
				end
				if ret.AnimationFilename ~= nil then
					returnTable.AnimationFilename = ret.AnimationFilename
				end
				if ret.AnimationName ~= nil then
					returnTable.AnimationName = ret.AnimationName
				end
				if ret.Scale ~= nil then
					returnTable.Scale = ret.Scale
				end
				if ret.Flip ~= nil then
					returnTable.Flip = ret.Flip
				end
				if ret.Color ~= nil then
					returnTable.Color = ret.Color
				end
				if ret.Prevent == true then
					returnTable.Prevent = true
					break
				end
			end
		end
	end
	return returnTable
end
CustomHealthAPI.Enums.RunCallbackFuncs[CustomHealthAPI.Enums.Callbacks.PRE_RENDER_HOLY_MANTLE] = CustomHealthAPI.Helper.RunPreRenderHolyMantleCallback

CustomHealthAPI.Library.RegisterAfterHealthIcon("HOLY_MANTLE", 
	{SortOrder = 0,
	 ShouldRenderFunc = function(player)
		local effects = player:GetEffects()
		return effects:GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_HOLY_MANTLE) > 0
	 end,
	 OnRenderFunc = function(player, playerSlot, healthIndex, renderInfo)
		local effects = player:GetEffects()
		local mantleNum = effects:GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_HOLY_MANTLE)
		local mantlesToRender = {}
		local numMantlesToRender = 1
		if CustomHealthAPI.REPPLUS_V1_9_7_13 then
			local odata = CustomHealthAPI.Helper.GetOtherData(player)
			local pdata = CustomHealthAPI.Helper.GetPersistentData(player)
			for i = 1, player:GetTrinketMultiplier(TrinketType.TRINKET_WOODEN_CROSS) - (pdata.WoodenCrossesBrokenThisFloor or 0) do
				table.insert(mantlesToRender, {Filename = "gfx/ui/CustomHealthAPI/hearts_v2.anm2",
				                               Animname = "HolyMantleWoodenCross",
				                               Type = CustomHealthAPI.Enums.MantleType.WOODEN_CROSS})
			end
			if effects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_BLANKET) then
				table.insert(mantlesToRender, {Filename = "gfx/ui/CustomHealthAPI/hearts_v2.anm2",
				                               Animname = "HolyMantleBlanket",
				                               Type = CustomHealthAPI.Enums.MantleType.BLANKET})
			end
			if player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE) and not odata.HasBrokenHolyMantle then
				table.insert(mantlesToRender, {Filename = "gfx/ui/CustomHealthAPI/hearts_v2.anm2",
				                               Animname = "HolyMantle",
				                               Type = CustomHealthAPI.Enums.MantleType.HOLY})
			end
			if effects:HasNullEffect(NullItemID.ID_HOLY_CARD) then
				table.insert(mantlesToRender, {Filename = "gfx/ui/CustomHealthAPI/hearts_v2.anm2",
				                               Animname = "HolyMantleHolyCard",
				                               Type = CustomHealthAPI.Enums.MantleType.HOLY_CARD})
			end
			numMantlesToRender = 2
		end
		while #mantlesToRender < mantleNum do
			table.insert(mantlesToRender, {Filename = "gfx/ui/CustomHealthAPI/hearts.anm2",
			                               Animname = "HolyMantle",
			                               Type = CustomHealthAPI.Enums.MantleType.UNKNOWN})
		end
		
		local firstMantleType = mantlesToRender[1].Type
		local secondMantleType
		if mantlesToRender[2] then
			secondMantleType = mantlesToRender[2].Type
		else
			secondMantleType = CustomHealthAPI.Enums.MantleType.NONE
		end
		
		for i = math.min(#mantlesToRender, numMantlesToRender), 1, -1 do
			local filename = mantlesToRender[i].Filename
			local animname = mantlesToRender[i].Animname
			local color = renderInfo.Color or Color(1, 1, 1)
			color.A = ((renderInfo.Color and renderInfo.Color.A) or 1) / i
			local scale = renderInfo.Scale or Vector.One
			local flip = renderInfo.Flip
			
			local prevent = false
			local healthIndex = healthIndex
			local extraOffset = renderInfo.ExtraOffset
			if i == 2 then
				extraOffset = extraOffset + Vector(6, -4)
			end
			
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
			local returnTable = CustomHealthAPI.Helper.RunPreRenderHolyMantleCallback(nil, player, healthIndex, extraOffset, flip, scale, color)
			if returnTable.Index ~= nil then
				healthIndex = returnTable.Index
			end
			if returnTable.Offset ~= nil then
				extraOffset = returnTable.Offset
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
			if returnTable.Scale ~= nil then
				scale = returnTable.Scale
			end
			if returnTable.Flip ~= nil then
				flip = returnTable.Flip
			end
			if returnTable.Prevent == true then
				prevent = true
				break
			end
			CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
			
			local healthSprite = CustomHealthAPI.Helper.GetHealthSprite(filename)
			healthSprite:Play(animname, true)
			healthSprite.Color = color
			
			if not prevent then
				CustomHealthAPI.Helper.RenderHealth(healthSprite, player, playerSlot, healthIndex, renderInfo.RenderOffset, renderInfo.TotalHealthRendered, extraOffset, false, flip, scale, color)
				
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing + 1
				Isaac.RunCallbackWithParam(CustomHealthAPI.Enums.Callbacks.POST_RENDER_HOLY_MANTLE, player:GetPlayerType(), player, playerSlot, healthIndex)
				CustomHealthAPI.PersistentData.PreventResyncing = CustomHealthAPI.PersistentData.PreventResyncing - 1
			end
		end
	 end,})

CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_FULL, {
	HealthKeys = {"RED_HEART"},
	HealthAmount = 2,
	AppleOfSodomValue = 3,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_HALF, {
	HealthKeys = {"RED_HEART"},
	HealthAmount = 1,
	AppleOfSodomValue = 1,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_SOUL, {
	HealthKeys = {"SOUL_HEART"},
	HealthAmount = 2,
	AppleOfSodomValue = 4,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_ETERNAL, {
	HealthKeys = {"ETERNAL_HEART"},
	HealthAmount = 1,
	AppleOfSodomValue = 6,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_DOUBLEPACK, {
	HealthKeys = {"RED_HEART"},
	HealthAmount = 4,
	AppleOfSodomValue = 6,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, {
	HealthKeys = {"BLACK_HEART"},
	HealthAmount = 2,
	AppleOfSodomValue = 5,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_GOLDEN, {
	HealthKeys = {"GOLDEN_HEART"},
	HealthAmount = 1,
	AppleOfSodomValue = 4,
	AllowImmaculateConception = false,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_HALF_SOUL, {
	HealthKeys = {"SOUL_HEART"},
	HealthAmount = 1,
	AppleOfSodomValue = 2,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_SCARED, {
	HealthKeys = {"RED_HEART"},
	HealthAmount = 2,
	AppleOfSodomValue = 3,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLENDED, {
	HealthKeys = {"RED_HEART", "SOUL_HEART"},
	HealthAmount = 2,
	AppleOfSodomValue = 3,
	AllowImmaculateConception = false,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_BONE, {
	HealthKeys = {"BONE_HEART"},
	HealthAmount = 1,
	AppleOfSodomValue = 3,
})
CustomHealthAPI.Library.RegisterHeartPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_ROTTEN, {
	HealthKeys = {"ROTTEN_HEART"},
	HealthAmount = 2,
	AppleOfSodomValue = 3,
})
