CustomHealthAPI.PersistentData.UsingGlowingHourglass = CustomHealthAPI.PersistentData.UsingGlowingHourglass or false
CustomHealthAPI.PersistentData.GlowingHourglassBackup = CustomHealthAPI.PersistentData.GlowingHourglassBackup or nil

local isReversingTime = false

function CustomHealthAPI.Helper.AddUseGlowingHourglassCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_USE_ITEM, CustomHealthAPI.Mod.UseGlowingHourglassCallback, CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddUseGlowingHourglassCallback)

function CustomHealthAPI.Helper.RemoveUseGlowingHourglassCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_USE_ITEM, CustomHealthAPI.Mod.UseGlowingHourglassCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveUseGlowingHourglassCallback)

function CustomHealthAPI.Mod:UseGlowingHourglassCallback()
	if isReversingTime then
		CustomHealthAPI.PersistentData.UsingGlowingHourglass = true
	end
end

function CustomHealthAPI.Helper.AddPreUseGlowingHourglassCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.PreUseGlowingHourglassCallback, CollectibleType.COLLECTIBLE_GLOWING_HOUR_GLASS)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreUseGlowingHourglassCallback)

function CustomHealthAPI.Helper.RemovePreUseGlowingHourglassCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.PreUseGlowingHourglassCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreUseGlowingHourglassCallback)

function CustomHealthAPI.Mod:PreUseGlowingHourglassCallback(collectible, rng, player, useflags, activeslot, vardata)
	-- why does this not use vardata wtf
	if activeslot ~= -1 then
		isReversingTime = player:GetActiveCharge(activeslot) <= 0
	else
		isReversingTime = true
	end
end

function CustomHealthAPI.Helper.BackupHealthForGlowingHourglass()
	CustomHealthAPI.PersistentData.GlowingHourglassBackup = CustomHealthAPI.Library.GetHealthBackup()
end

function CustomHealthAPI.Helper.LoadHealthForGlowingHourglass()
	CustomHealthAPI.Library.LoadHealthFromBackup(CustomHealthAPI.PersistentData.GlowingHourglassBackup)
	
	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		local data = player:GetData().CustomHealthAPIOtherData
		data.LastValues = nil
	end
end
