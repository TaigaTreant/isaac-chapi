CustomHealthAPI.PersistentData.SaveDataLoaded = CustomHealthAPI.PersistentData.SaveDataLoaded or false

function CustomHealthAPI.Helper.AddSaveDataOnNewLevelCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_NEW_LEVEL, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.SaveDataOnNewLevelCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddSaveDataOnNewLevelCallback)

function CustomHealthAPI.Helper.RemoveSaveDataOnNewLevelCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_NEW_LEVEL, CustomHealthAPI.Mod.SaveDataOnNewLevelCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveSaveDataOnNewLevelCallback)

function CustomHealthAPI.Mod:SaveDataOnNewLevelCallback()
	CustomHealthAPI.PersistentData.RestockInfo = {}
	if CustomHealthAPI.PersistentData.SaveDataLoaded then
		CustomHealthAPI.Helper.SaveData()
	end
end

function CustomHealthAPI.Helper.AddSaveDataOnExitCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_PRE_GAME_EXIT, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.SaveDataOnExitCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddSaveDataOnExitCallback)

function CustomHealthAPI.Helper.RemoveSaveDataOnExitCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_PRE_GAME_EXIT, CustomHealthAPI.Mod.SaveDataOnExitCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveSaveDataOnExitCallback)

function CustomHealthAPI.Mod:SaveDataOnExitCallback(shouldSave)
	if shouldSave then
		CustomHealthAPI.Helper.SaveData(true)
	end
	
	CustomHealthAPI.PersistentData.SaveDataLoaded = false
end

function CustomHealthAPI.Helper.AddHandleSaveDataOnGameStartCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_GAME_STARTED, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.HandleSaveDataOnGameStartCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddHandleSaveDataOnGameStartCallback)

function CustomHealthAPI.Helper.RemoveHandleSaveDataOnGameStartCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_GAME_STARTED, CustomHealthAPI.Mod.HandleSaveDataOnGameStartCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveHandleSaveDataOnGameStartCallback)

function CustomHealthAPI.Mod:HandleSaveDataOnGameStartCallback(isContinued)
	CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup = {}
	CustomHealthAPI.PersistentData.HiddenSubplayerHealthBackup = {}
	CustomHealthAPI.PersistentData.RestockInfo = {}
	
	if isContinued then
		CustomHealthAPI.Helper.LoadData()
	end
	CustomHealthAPI.Helper.SaveData()
	CustomHealthAPI.PersistentData.GlowingHourglassBackup = CustomHealthAPI.Library.GetHealthBackup()
	
	CustomHealthAPI.PersistentData.SaveDataLoaded = true
end

function CustomHealthAPI.Helper.SaveData(isPreGameExit)
	local save = CustomHealthAPI.Library.GetHealthBackup()
	
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.ON_SAVE)
	for _, callback in ipairs(callbacks) do
		callback.Function(save, isPreGameExit == true)
	end
end

function CustomHealthAPI.Helper.LoadData()
	local save
	
	local callbacks = CustomHealthAPI.Helper.GetCallbacks(CustomHealthAPI.Enums.Callbacks.ON_LOAD)
	for _, callback in ipairs(callbacks) do
		save = callback.Function()
		if save ~= nil then
			break
		end
	end
	
	if save ~= nil then
		CustomHealthAPI.Library.LoadHealthFromBackup(save)
	end
end
