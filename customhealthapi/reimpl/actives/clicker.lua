function CustomHealthAPI.Helper.AddPreUseClickerCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_USE_ITEM, math.huge, CustomHealthAPI.Mod.PreUseClickerCallback, CollectibleType.COLLECTIBLE_CLICKER)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreUseClickerCallback)

function CustomHealthAPI.Helper.RemovePreUseClickerCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_USE_ITEM, CustomHealthAPI.Mod.PreUseClickerCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreUseClickerCallback)

function CustomHealthAPI.Mod:PreUseClickerCallback(collectible, rng, player)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
	CustomHealthAPI.Helper.PreChangePlayerType(player, nil, true)
end

function CustomHealthAPI.Helper.AddUseClickerCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_USE_ITEM, CallbackPriority.IMPORTANT, CustomHealthAPI.Mod.UseClickerCallback, CollectibleType.COLLECTIBLE_CLICKER)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddUseClickerCallback)

function CustomHealthAPI.Helper.RemoveUseClickerCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_USE_ITEM, CustomHealthAPI.Mod.UseClickerCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveUseClickerCallback)

function CustomHealthAPI.Mod:UseClickerCallback(collectible, rng, player, useflags)
	CustomHealthAPI.Helper.PostChangePlayerType(player, player:GetPlayerType())
end
