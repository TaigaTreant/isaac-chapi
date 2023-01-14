-- A lot of this uses StageAPI as a reference. Thanks DeadInfinity.

CustomHealthAPI.PersistentData.Callbacks = CustomHealthAPI.PersistentData.Callbacks or {}

local highestID = 0
for _,v in pairs(CustomHealthAPI.Enums.Callbacks) do
	highestID = math.max(v, highestID)
	CustomHealthAPI.PersistentData.Callbacks[v] = CustomHealthAPI.PersistentData.Callbacks[v] or {}
end

function CustomHealthAPI.Library.AddCallback(modID, id, priority, fn, ...)
	if id < 1 or id > highestID then
		print("Custom Health API Error: CustomHealthAPI.Library.AddCallback called with invalid callback ID.")
		return
	end

	local callbacks = CustomHealthAPI.PersistentData.Callbacks[id]
	local index = 1

    for i = #callbacks, 1, -1 do
		local callback = callbacks[i]
        if priority >= callback.Priority then
            index = i + 1
            break
        end
    end

    table.insert(callbacks, index, {
        Priority = priority,
        Function = fn,
        ModID = modID,
        Params = {...},
        CallbackID = id,
    })
end

function CustomHealthAPI.Library.UnregisterCallbacks(modID)
    for id, callbacks in pairs(CustomHealthAPI.PersistentData.Callbacks) do
        for i = #callbacks, 1, -1 do
			local callback = callbacks[i]
            if callback.ModID == modID then
                table.remove(callbacks, i)
            end
        end
    end
end

function CustomHealthAPI.Helper.GetCallbacks(id)
	return CustomHealthAPI.PersistentData.Callbacks[id]
end
