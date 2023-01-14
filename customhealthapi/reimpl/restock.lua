-- oh my godddddddddddd there is a singular function for this in the game but we don't have it in the api whyyyyyyyyyyyyyyy

CustomHealthAPI.PersistentData.RestockInfo = CustomHealthAPI.PersistentData.RestockInfo or {}

function CustomHealthAPI.Helper.ShouldRestock()
	if Game():IsGreedMode() then
		return true
	end
	
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		if player:HasCollectible(CollectibleType.COLLECTIBLE_RESTOCK) then
			return true
		end
	end
	
	return false
end

function CustomHealthAPI.Helper.GetDimension()
	local level = Game():GetLevel()
	
	local roomIndex = level:GetCurrentRoomIndex()
	for i = 0, 2 do
		if GetPtrHash(level:GetRoomByIdx(roomIndex, i)) == GetPtrHash(level:GetRoomByIdx(roomIndex, -1)) then
			return i
		end
	end
	return 0
end

function CustomHealthAPI.Library.TriggerRestock(pickup, noSpawn)
	if CustomHealthAPI.Helper.ShouldRestock() then
		local shopid = pickup.ShopItemId
		
		local level = Game():GetLevel()
		local room = Game():GetRoom()
		
		local roomIndex = level:GetCurrentRoomIndex()
		local dimension = CustomHealthAPI.Helper.GetDimension()
		
		CustomHealthAPI.PersistentData.RestockInfo["a"..dimension] = CustomHealthAPI.PersistentData.RestockInfo["a"..dimension] or {}
		CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex] = CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex] or {}
		CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex]["a"..shopid] = CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex]["a"..shopid] or {}
		
		local restockInfo = CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex]["a"..shopid]
		restockInfo.NextType = pickup.Type
		restockInfo.NextVariant = pickup.Variant
		restockInfo.NextSubType = pickup.SubType
		restockInfo.NextGridIndex = room:GetGridIndex(pickup.Position)
		restockInfo.TimesPurchased = (restockInfo.TimesPurchased or 0) + 1
		if noSpawn then
			restockInfo.TimeTilRestock = 0
		else
			restockInfo.TimeTilRestock = 30
		end
		
		pickup.AutoUpdatePrice = false
	end
end

function CustomHealthAPI.Helper.HasCustomRestocked(pickup)
	local level = Game():GetLevel()
	local room = Game():GetRoom()
	
	local roomIndex = level:GetCurrentRoomIndex()
	local dimension = CustomHealthAPI.Helper.GetDimension()
	
	local shopid = pickup.ShopItemId
	local timesPurchased = 0
	if CustomHealthAPI.PersistentData.RestockInfo["a"..dimension] and 
	   CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex] and
	   CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex]["a"..shopid]
	then
		timesPurchased = (CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex]["a"..shopid].TimesPurchased or 0)
	end
	
	return timesPurchased > 0
end

function CustomHealthAPI.Helper.AddRestockPickupsCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.RestockPickupsCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddRestockPickupsCallback)

function CustomHealthAPI.Helper.RemoveRestockPickupsCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.RestockPickupsCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveRestockPickupsCallback)

function CustomHealthAPI.Mod:RestockPickupsCallback()
	local level = Game():GetLevel()
	local room = Game():GetRoom()
	
	local roomIndex = level:GetCurrentRoomIndex()
	local dimension = CustomHealthAPI.Helper.GetDimension()
	
	if CustomHealthAPI.PersistentData.RestockInfo["a"..dimension] and CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex] then
		local pickupsToRestock = CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex]
		
		for shopid, restockInfo in pairs(pickupsToRestock) do
			if restockInfo.TimeTilRestock ~= nil and restockInfo.TimeTilRestock > 0 then
				restockInfo.TimeTilRestock = restockInfo.TimeTilRestock - 1
				
				if restockInfo.TimeTilRestock == 0 then
					local pickup = Isaac.Spawn(restockInfo.NextType, 
					                           restockInfo.NextVariant, 
					                           restockInfo.NextSubType, 
					                           room:GetGridPosition(restockInfo.NextGridIndex), 
					                           Vector(0, 0), 
					                           nil):ToPickup()
					
					pickup.AutoUpdatePrice = true
---@diagnostic disable-next-line: assign-type-mismatch
					pickup.ShopItemId = tonumber(string.sub(shopid, 2))
					pickup.Price = 1
					
					pickup:Update()
					
					local poof = Isaac.Spawn(1000, 
					                         15, 
					                         2, 
					                         room:GetGridPosition(restockInfo.NextGridIndex), 
					                         Vector(0, 0), 
					                         nil)
					poof:Update()
				end
			end
		end
	end
	
	if not Game():IsGreedMode() then
		for _, p in ipairs(Isaac.FindByType(5)) do
			local pickup = p:ToPickup()
			if CustomHealthAPI.Helper.HasCustomRestocked(pickup) then
				if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE and pickup:IsShopItem() then
					if pickup.AutoUpdatePrice and not pickup:IsDead() then
						pickup.Price = CustomHealthAPI.Helper.GetPriceOfPickup(pickup)
						pickup:GetData().CHAPILastPriceUpdate = Game():GetFrameCount()
					elseif pickup:IsDead() then
						pickup.AutoUpdatePrice = false
					end
				end
			end
		end
	end
end

function CustomHealthAPI.Helper.GetNumSteamSales()
	local numSteamSales = 0
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		numSteamSales = numSteamSales + player:GetCollectibleNum(CollectibleType.COLLECTIBLE_STEAM_SALE)
	end
	return numSteamSales
end

function CustomHealthAPI.Helper.SomeoneHasPoundOfFlesh()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		if player:HasCollectible(CollectibleType.COLLECTIBLE_POUND_OF_FLESH) then
			return true
		end
	end
	return false
end

function CustomHealthAPI.Helper.SomeoneHasStoreCredit()
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		if player:HasTrinket(TrinketType.TRINKET_STORE_CREDIT) then
			return true
		end
	end
	return false
end

function CustomHealthAPI.Helper.GetPriceOfPickup(pickup, force)
	if pickup:GetData().CHAPILastPriceUpdate == Game():GetFrameCount() and not force then
		return pickup.Price
	end
	
	if CustomHealthAPI.Helper.SomeoneHasPoundOfFlesh() then
		return PickupPrice.PRICE_SPIKES
	elseif CustomHealthAPI.Helper.SomeoneHasStoreCredit() then
		return PickupPrice.PRICE_FREE
	end
	
	local level = Game():GetLevel()
	local room = Game():GetRoom()
	
	local roomIndex = level:GetCurrentRoomIndex()
	local dimension = CustomHealthAPI.Helper.GetDimension()
	
	local shopid = pickup.ShopItemId
	local timesPurchased = 0
	if CustomHealthAPI.PersistentData.RestockInfo["a"..dimension] and 
	   CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex] and
	   CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex]["a"..shopid]
	then
		timesPurchased = (CustomHealthAPI.PersistentData.RestockInfo["a"..dimension]["a"..roomIndex]["a"..shopid].TimesPurchased or 0)
	end
	
	local isGreedMode = Game():IsGreedMode()
	local hasDiscount = level:GetRoomByIdx(level:GetCurrentRoomIndex()).ShopItemDiscountIdx == shopid
	local numSteamSales = CustomHealthAPI.Helper.GetNumSteamSales()
	
	local basePrice = 5
	if pickup.Variant == PickupVariant.PICKUP_HEART and
	   (pickup.SubType == HeartSubType.HEART_FULL or pickup.SubType == HeartSubType.HEART_HALF)
	then
		basePrice = 3
	elseif pickup.Variant == PickupVariant.PICKUP_GRAB_BAG then
		basePrice = 7
	end
	
	local discountedPrice = basePrice
	if pickup.Variant == PickupVariant.PICKUP_GRAB_BAG and
	   (numSteamSales == 1 or (numSteamSales <= 0 and hasDiscount))
	then
		discountedPrice = math.max(1, math.floor(basePrice / 2))
	elseif numSteamSales > 0 then
		discountedPrice = math.max(1, math.ceil(basePrice / (numSteamSales + 1)))
	elseif hasDiscount then
		discountedPrice = math.max(1, math.ceil(basePrice / 2))
	end
	
	local basegameRestockPrice = pickup.Price - discountedPrice
	local estimatedBasegameRestocks = 0
	if basegameRestockPrice > 0 then
		estimatedBasegameRestocks = math.ceil((math.sqrt(8 * basegameRestockPrice + 1) - 1) / 2)
	end
	timesPurchased = timesPurchased + estimatedBasegameRestocks
	
	local price = discountedPrice
	if not isGreedMode then
		price = math.min(99, price + (timesPurchased * (timesPurchased + 1)) / 2)
	end
	
	return price
end

function CustomHealthAPI.Helper.TryRemoveStoreCredit(player)
	local t0 = player:GetTrinket(0)
	local t1 = player:GetTrinket(1)
	
	if t0 % TrinketType.TRINKET_GOLDEN_FLAG == TrinketType.TRINKET_STORE_CREDIT then
		player:TryRemoveTrinket(TrinketType.TRINKET_STORE_CREDIT)
		return
	elseif t1 % TrinketType.TRINKET_GOLDEN_FLAG == TrinketType.TRINKET_STORE_CREDIT then
		player:TryRemoveTrinket(TrinketType.TRINKET_STORE_CREDIT)
		return
	end
	
	local numStoreCredits = player:GetTrinketMultiplier(TrinketType.TRINKET_STORE_CREDIT)
	if player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_BOX) then
		numStoreCredits = numStoreCredits - 1
	end
	
	if numStoreCredits >= 2 then
		player:TryRemoveTrinket(TrinketType.TRINKET_STORE_CREDIT + TrinketType.TRINKET_GOLDEN_FLAG)
	else
		player:TryRemoveTrinket(TrinketType.TRINKET_STORE_CREDIT)
	end
end

function CustomHealthAPI.Helper.AddUpdatePickupPriceCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PICKUP_UPDATE, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.UpdatePickupPriceCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddUpdatePickupPriceCallback)

function CustomHealthAPI.Helper.RemoveUpdatePickupPriceCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, CustomHealthAPI.Mod.UpdatePickupPriceCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveUpdatePickupPriceCallback)

function CustomHealthAPI.Mod:UpdatePickupPriceCallback(pickup)
	if pickup.Variant ~= PickupVariant.PICKUP_COLLECTIBLE and 
	   pickup:IsShopItem() and 
	   pickup.AutoUpdatePrice and 
	   not pickup:IsDead() and 
	   not Game():IsGreedMode() and
	   CustomHealthAPI.Helper.HasCustomRestocked(pickup)
	then
		pickup.Price = CustomHealthAPI.Helper.GetPriceOfPickup(pickup, true)
		pickup:GetData().CHAPILastPriceUpdate = Game():GetFrameCount()
	end
end
