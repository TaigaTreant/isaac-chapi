function CustomHealthAPI.Helper.AddEternalMain(player, key, hp)
	local data = player:GetData().CustomHealthAPISavedata
	data.Overlays["ETERNAL_HEART"] = math.max(0, data.Overlays["ETERNAL_HEART"] + hp)
	
	if data.Overlays["ETERNAL_HEART"] >= 2 then
		CustomHealthAPI.Helper.AddBasegameEternalHealthWithoutModifiers(player, 2) -- Play eternal heart animation
		
		local hpToAdd = data.Overlays["ETERNAL_HEART"] - (data.Overlays["ETERNAL_HEART"] % 2)
		if player:GetPlayerType() == PlayerType.PLAYER_THESOUL then
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "SOUL_HEART", hpToAdd)
		else
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "EMPTY_HEART", hpToAdd)
			CustomHealthAPI.Helper.UpdateHealthMasks(player, "RED_HEART", hpToAdd)
		end
		
		data.Overlays["ETERNAL_HEART"] = data.Overlays["ETERNAL_HEART"] % 2
	end
end

function CustomHealthAPI.Helper.AddGoldMain(player, key, hp)
	local data = player:GetData().CustomHealthAPISavedata
	local limit = CustomHealthAPI.Helper.GetNumOverlayableHearts(player)
	
	data.Overlays[key] = math.max(0, math.min(limit, data.Overlays[key] + hp))
end

function CustomHealthAPI.Helper.AddOverlayMain(player, key, hp)
	if key == "ETERNAL_HEART" then
		CustomHealthAPI.Helper.AddEternalMain(player, key, hp)
	elseif key == "GOLDEN_HEART" then
		CustomHealthAPI.Helper.AddGoldMain(player, key, hp)
	end
end

function CustomHealthAPI.Helper.HandleGoldenRoom(p, doGoldEffects)
	local data = p:GetData().CustomHealthAPISavedata
	local limit = CustomHealthAPI.Helper.GetNumOverlayableHearts(p)
	
	local currentGold = data.Overlays["GOLDEN_HEART"]
	if currentGold > limit then
		data.Overlays["GOLDEN_HEART"] = limit
		
		if doGoldEffects then
			local player = p
			local originalPosition = player.Position
			if CustomHealthAPI.Helper.PlayerIsTheForgotten(player) then
				if player:GetSubPlayer() ~= nil then
					originalPosition = player:GetSubPlayer().Position
					player:GetSubPlayer().Position = player.Position
					player = player:GetSubPlayer()
				else
					--idk fuck bone hearts in this specific scenario
					return
				end
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
			
			local numRed = CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
			local numRotten = CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
			local numSoul = CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
			local blackMask = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts(player)
			local numMax = CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
			local numBone = CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
			local numGolden = CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
			
			if not (CustomHealthAPI.PersistentData.CharactersThatCantHaveRedHealth[player:GetPlayerType()] or 
			        CustomHealthAPI.PersistentData.CharactersThatConvertMaxHealth[player:GetPlayerType()] or
			        CustomHealthAPI.Helper.PlayerIsTheSoul(player))
			then
				CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -99)
				CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, -99)
				CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, -99)
				CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, -99)
				CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, -99)
				for i = 1, currentGold - limit do
					CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, 1)
					CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, 1)
					CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, 99)
					CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, -1)
					CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, -1)
					CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -99)
				end
				
				for i = 2, 0, -1 do
					if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
						player:SetActiveCharge(24, i)
					end
				end
				
				local soulToAdd = numSoul
				local blackToMask = blackMask
				while soulToAdd > 0 do
					local soulAdding = 2
					if soulToAdd == 1 then
						soulAdding = 1
					end
					soulToAdd = soulToAdd - soulAdding
					
					if blackMask % 2 == 1 then
						CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, soulAdding)
					else
						CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, soulAdding)
					end
					blackMask = blackMask >> 1
				end
				CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, numBone)
				CustomHealthAPI.Helper.AddBasegameMaxHealthWithoutModifiers(player, numMax)
				CustomHealthAPI.Helper.AddBasegameRedHealthWithoutModifiers(player, numRed - (numRotten * 2))
				CustomHealthAPI.Helper.AddBasegameRottenHealthWithoutModifiers(player, numRotten * 2)
				CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, numGolden)
			else
				CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -99)
				CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, -99)
				CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, -99)
				for i = 1, currentGold - limit do
					CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, 1)
					CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, 99)
					CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, -1)
					CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, -99)
				end
				
				for i = 2, 0, -1 do
					if player:GetActiveItem(i) == CollectibleType.COLLECTIBLE_ALABASTER_BOX then
						player:SetActiveCharge(24, i)
					end
				end
				
				local soulToAdd = numSoul
				local blackToMask = blackMask
				while soulToAdd > 0 do
					local soulAdding = 2
					if soulToAdd == 1 then
						soulAdding = 1
					end
					soulToAdd = soulToAdd - soulAdding
					
					if blackMask % 2 == 1 then
						CustomHealthAPI.Helper.AddBasegameBlackHealthWithoutModifiers(player, soulAdding)
					else
						CustomHealthAPI.Helper.AddBasegameSoulHealthWithoutModifiers(player, soulAdding)
					end
					blackMask = blackMask >> 1
				end
				CustomHealthAPI.Helper.AddBasegameBoneHealthWithoutModifiers(player, numBone)
				CustomHealthAPI.Helper.AddBasegameGoldenHealthWithoutModifiers(player, numGolden)
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
			
			player.Position = originalPosition
		end
	end
end
