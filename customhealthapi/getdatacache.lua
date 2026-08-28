-- Context: GetData is a slow function. One of the slowest in an already-slow API, due to making multiple jumps back-and-forth from lua to c++.
-- While not damning by itself, the main issue is that GetData is otherwise a very convenient and widely used "first check" before running other code,
-- so it can add up a lot if code is calling GetData like 100 times per update but not actually *doing* anything.
--
-- This utility provides a wrapper around GetData that caches a reference to the table after the first time it is called.
-- This makes it so that while the very first GetData call for a given entity is as slow as ever, every subsequent call is significantly faster.
--
-- The main advantages of this over alternatives are it being very simple, and a drop-in replacement. The data is still in the same place
-- from the perspective of other mods using GetData, this just makes fetching the table more efficient. This can be good for established mods,
-- or if you just don't feel like wiring up a custom data system.
--
-- For new mods it could still be reasonable to consider either a custom data table, OR, if you'd like PERSISTENT data, use https://repentogon.com/EntitySaveStateManager.html
-- In the future REPENTOGON may offer a more direct drop-in replacement for GetData, but for now this exists.
--
-- Example integration:
--[[
include("path.to.getdatacache")

-- With this, can freely replace usage of `entity:GetData()` with `mod:GetEntityData(entity)`
function mod:GetEntityData(entity)
	-- Please access via the `GetDataCache` GLOBAL, don't put `GetDataCache` directly into your mod table.
	return GetDataCache.GetEntityData(entity)
end
]]


local version = 1

if GetDataCache then
	if GetDataCache.Version > version then
		return
	end

	GetDataCache:UnregisterCallbacks()
end

GetDataCache = RegisterMod("GetData Cache", 1)
GetDataCache.Version = version

-- _cache is a table with "weak values", meaning that it does not prevent referenced stuff from being
-- garbage collected. If a referenced value is destroyed, it gets removed from this table automatically.
-- See https://www.lua.org/pil/17.html
-- This prevents the cache from keeping the GetData tables alive when it shouldn't, and adds an extra
-- safety net against cache entries not being cleaned up properly.
-- We still manually clear the cache on certain callbacks, since garbage collection is not immediate.
local _cache = setmetatable({}, {__mode = 'v'})
local _originalGetDataFunc = getmetatable(Entity).__class.GetData

-- Uses cached references to GetData tables to save on multiple lua/c jumps and metatable stuff,
-- while still being a drop-in replacement for GetData (as opposed to a fully custom data structure).
-- The very first call for an entity is normal, every one after that is faster than any Entity function.
function GetDataCache.GetEntityData(entity)
	local hash = GetPtrHash(entity)
	if not _cache[hash] then
		local data = _originalGetDataFunc(entity)
		if not entity:Exists() then
			return data  -- Not safe to cache this
		end
		_cache[hash] = data
	end
	return _cache[hash]
end

function GetDataCache.ClearCache(entity)
	_cache[GetPtrHash(entity)] = nil
end

local function _clearCacheCallback(_, entity)
	GetDataCache.ClearCache(entity)
end

GetDataCache.Callbacks = {
	{
		ID = ModCallbacks.MC_POST_ENTITY_REMOVE,
		Priority = math.huge,
		Function = _clearCacheCallback,
	},
	{
		ID = ModCallbacks.MC_PLAYER_INIT_PRE_LEVEL_INIT_STATS,
		Priority = -math.huge,
		Function = _clearCacheCallback,
	},
	{
		ID = ModCallbacks.MC_POST_PLAYER_INIT,
		Priority = -math.huge,
		Function = _clearCacheCallback,
	},
}

function GetDataCache:RegisterCallbacks()
	for _, callback in pairs(self.Callbacks) do
		self:AddPriorityCallback(callback.ID, callback.Priority, callback.Function)
	end
end

function GetDataCache:UnregisterCallbacks()
	for _, callback in pairs(self.Callbacks) do
		self:RemoveCallback(callback.ID, callback.Function)
	end
end

GetDataCache:RegisterCallbacks()
