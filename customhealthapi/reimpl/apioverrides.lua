local isEvaluateCacheFunction = 0

function CustomHealthAPI.Helper.AddPreEvaluateCacheCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_EVALUATE_CACHE, -1 * math.huge, CustomHealthAPI.Mod.PreEvaluateCacheCallback, -1) 
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPreEvaluateCacheCallback)

function CustomHealthAPI.Helper.RemovePreEvaluateCacheCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_EVALUATE_CACHE, CustomHealthAPI.Mod.PreEvaluateCacheCallback) 
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePreEvaluateCacheCallback)

function CustomHealthAPI.Mod:PreEvaluateCacheCallback()
	isEvaluateCacheFunction = isEvaluateCacheFunction + 1
end

function CustomHealthAPI.Helper.AddPostEvaluateCacheCallback()
---@diagnostic disable-next-line: param-type-mismatch
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_EVALUATE_CACHE, math.huge, CustomHealthAPI.Mod.PostEvaluateCacheCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddPostEvaluateCacheCallback)

function CustomHealthAPI.Helper.RemovePostEvaluateCacheCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_EVALUATE_CACHE, CustomHealthAPI.Mod.PostEvaluateCacheCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemovePostEvaluateCacheCallback)

function CustomHealthAPI.Mod:PostEvaluateCacheCallback()
	isEvaluateCacheFunction = isEvaluateCacheFunction - 1
end

function CustomHealthAPI.Helper.AddResetEvaluateCacheCallback()
	Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.ResetEvaluateCacheCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddResetEvaluateCacheCallback)

function CustomHealthAPI.Helper.RemoveResetEvaluateCacheCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_UPDATE, CustomHealthAPI.Mod.ResetEvaluateCacheCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveResetEvaluateCacheCallback)

function CustomHealthAPI.Mod:ResetEvaluateCacheCallback()
	if isEvaluateCacheFunction ~= 0 then
		print("Custom Health API ERROR: Evaluate Items callback detection failed with value " .. isEvaluateCacheFunction .. ".")
		isEvaluateCacheFunction = 0
	end
end

CustomHealthAPI.PersistentData.OverriddenFunctions = CustomHealthAPI.PersistentData.OverriddenFunctions or {}
CustomHealthAPI.Helper.HookFunctions = {}

local META, META0
local function BeginClass(T)
	META = {}
	if type(T) == "function" then
		META0 = getmetatable(T())
	else
		META0 = getmetatable(T).__class
	end
end

local function EndClass()
	local oldIndex = META0.__index
	local newMeta = META
		
	rawset(META0, "__index", function(self, k)
		return newMeta[k] or oldIndex(self, k)
	end)
end

----------------------
-- Entity Overrides --
----------------------

if CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamageEntity == nil then
	BeginClass(Entity)
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamageEntity = META0.TakeDamage
	function META:TakeDamage(amount, flags, source, countdown)
		return CustomHealthAPI.Helper.HookFunctions.TakeDamageEntity(self, amount, flags, source, countdown)
	end

	EndClass()
end

----------------------------
-- EntityPlayer Overrides --
----------------------------

if CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickGoldenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.EvaluateItems == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffectiveMaxHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHeartsAndSoulHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveBlackHeart == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.SetFullHearts == nil or
   CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamagePlayer == nil
then
	BeginClass(EntityPlayer)

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts = META0.AddBlackHearts
		function META:AddBlackHearts(hp)
			CustomHealthAPI.Helper.HookFunctions.AddBlackHearts(self, hp)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts = META0.AddBoneHearts
		function META:AddBoneHearts(hp)
			CustomHealthAPI.Helper.HookFunctions.AddBoneHearts(self, hp)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts = META0.AddBrokenHearts
		function META:AddBrokenHearts(hp)
			CustomHealthAPI.Helper.HookFunctions.AddBrokenHearts(self, hp)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible = META0.AddCollectible
		function META:AddCollectible(item, charge, firstTimePickingUp, slot, varData, pool)
			CustomHealthAPI.Helper.HookFunctions.AddCollectible(self, item, charge, firstTimePickingUp, slot, varData, pool)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts = META0.AddEternalHearts
		function META:AddEternalHearts(hp)
			CustomHealthAPI.Helper.HookFunctions.AddEternalHearts(self, hp)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts = META0.AddGoldenHearts
		function META:AddGoldenHearts(hp)
			CustomHealthAPI.Helper.HookFunctions.AddGoldenHearts(self, hp)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts = META0.AddHearts
		function META:AddHearts(hp)
			CustomHealthAPI.Helper.HookFunctions.AddHearts(self, hp)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts = META0.AddMaxHearts
		function META:AddMaxHearts(hp)
			CustomHealthAPI.Helper.HookFunctions.AddMaxHearts(self, hp)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts = META0.AddRottenHearts
		function META:AddRottenHearts(hp)
			CustomHealthAPI.Helper.HookFunctions.AddRottenHearts(self, hp)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts = META0.AddSoulHearts
		function META:AddSoulHearts(hp)
			CustomHealthAPI.Helper.HookFunctions.AddSoulHearts(self, hp)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts = META0.CanPickBlackHearts
		function META:CanPickBlackHearts()
			return CustomHealthAPI.Helper.HookFunctions.CanPickBlackHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts = META0.CanPickBoneHearts
		function META:CanPickBoneHearts()
			return CustomHealthAPI.Helper.HookFunctions.CanPickBoneHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickGoldenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickGoldenHearts = META0.CanPickGoldenHearts
		function META:CanPickGoldenHearts()
			return CustomHealthAPI.Helper.HookFunctions.CanPickGoldenHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts = META0.CanPickRedHearts
		function META:CanPickRedHearts()
			return CustomHealthAPI.Helper.HookFunctions.CanPickRedHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts = META0.CanPickRottenHearts
		function META:CanPickRottenHearts()
			return CustomHealthAPI.Helper.HookFunctions.CanPickRottenHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts = META0.CanPickSoulHearts
		function META:CanPickSoulHearts()
			return CustomHealthAPI.Helper.HookFunctions.CanPickSoulHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType = META0.ChangePlayerType
		function META:ChangePlayerType(playertype)
			return CustomHealthAPI.Helper.HookFunctions.ChangePlayerType(self, playertype)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.EvaluateItems == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.EvaluateItems = META0.EvaluateItems
		function META:EvaluateItems()
			return CustomHealthAPI.Helper.HookFunctions.EvaluateItems(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts = META0.GetBlackHearts
		function META:GetBlackHearts()
			return CustomHealthAPI.Helper.HookFunctions.GetBlackHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts = META0.GetBoneHearts
		function META:GetBoneHearts()
			return CustomHealthAPI.Helper.HookFunctions.GetBoneHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts = META0.GetBrokenHearts
		function META:GetBrokenHearts()
			return CustomHealthAPI.Helper.HookFunctions.GetBrokenHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffectiveMaxHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffectiveMaxHearts = META0.GetEffectiveMaxHearts
		function META:GetEffectiveMaxHearts()
			return CustomHealthAPI.Helper.HookFunctions.GetEffectiveMaxHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts = META0.GetEternalHearts
		function META:GetEternalHearts()
			return CustomHealthAPI.Helper.HookFunctions.GetEternalHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts = META0.GetGoldenHearts
		function META:GetGoldenHearts()
			return CustomHealthAPI.Helper.HookFunctions.GetGoldenHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit = META0.GetHeartLimit
		function META:GetHeartLimit()
			return CustomHealthAPI.Helper.HookFunctions.GetHeartLimit(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts = META0.GetHearts
		function META:GetHearts()
			return CustomHealthAPI.Helper.HookFunctions.GetHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts = META0.GetMaxHearts
		function META:GetMaxHearts()
			return CustomHealthAPI.Helper.HookFunctions.GetMaxHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts = META0.GetRottenHearts
		function META:GetRottenHearts()
			return CustomHealthAPI.Helper.HookFunctions.GetRottenHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts = META0.GetSoulHearts
		function META:GetSoulHearts()
			return CustomHealthAPI.Helper.HookFunctions.GetSoulHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHearts = META0.HasFullHearts
		function META:HasFullHearts()
			return CustomHealthAPI.Helper.HookFunctions.HasFullHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHeartsAndSoulHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHeartsAndSoulHearts = META0.HasFullHeartsAndSoulHearts
		function META:HasFullHeartsAndSoulHearts()
			return CustomHealthAPI.Helper.HookFunctions.HasFullHeartsAndSoulHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart = META0.IsBlackHeart
		function META:IsBlackHeart(heart)
			return CustomHealthAPI.Helper.HookFunctions.IsBlackHeart(self, heart)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart = META0.IsBoneHeart
		function META:IsBoneHeart(heart)
			return CustomHealthAPI.Helper.HookFunctions.IsBoneHeart(self, heart)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveBlackHeart == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveBlackHeart = META0.RemoveBlackHeart
		function META:RemoveBlackHeart(heart)
			CustomHealthAPI.Helper.HookFunctions.RemoveBlackHeart(self, heart)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.SetFullHearts == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.SetFullHearts = META0.SetFullHearts
		function META:SetFullHearts()
			CustomHealthAPI.Helper.HookFunctions.SetFullHearts(self)
		end
	end

	if CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamagePlayer == nil then
		CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamagePlayer = META0.TakeDamage
		function META:TakeDamage(amount, flags, source, countdown)
			return CustomHealthAPI.Helper.HookFunctions.TakeDamagePlayer(self, amount, flags, source, countdown)
		end
	end

	EndClass()
end

-------------------
-- HUD Overrides --
-------------------

if CustomHealthAPI.PersistentData.OverriddenFunctions.RenderHUD == nil then
	BeginClass(HUD)

	CustomHealthAPI.PersistentData.OverriddenFunctions.RenderHUD = META0.Render
	function META:Render()
		CustomHealthAPI.Helper.HookFunctions.RenderHUD(self)
	end

	EndClass()
end

----------------------------
-- EntityPlayer Overrides --
----------------------------

CustomHealthAPI.Helper.HookFunctions.AddBlackHearts = function(player, hp)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddBlackHearts(player:GetOtherTwin(), hp)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "BLACK_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBlackHearts(player, hp)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddBoneHearts = function(player, hp)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddBoneHearts(player:GetOtherTwin(), hp)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "BONE_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBoneHearts(player, hp)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddBrokenHearts = function(player, hp)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddBrokenHearts(player:GetOtherTwin(), hp)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "BROKEN_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddBrokenHearts(player, hp)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddCollectible = function(player, item, charge, firstTimePickingUp, slot, varData, pool)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddCollectible(player:GetOtherTwin(), item, charge, firstTimePickingUp, slot, varData, pool)
		end
	end
	
	if CustomHealthAPI then
		if not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
			CustomHealthAPI.Helper.CheckIfHealthOrderSet()
			CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
			CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		
		player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
		local pdata = player:GetData().CustomHealthAPIPersistent
		
		pdata.HasFunGuyTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_MUSHROOM)
		pdata.HasSeraphimTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_ANGEL)
		pdata.HasLeviathanTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_EVIL_ANGEL)
	end
	
	CustomHealthAPI.PersistentData.OverriddenFunctions.AddCollectible(player, 
	                                                                  item, 
	                                                                  charge or 0, 
	                                                                  firstTimePickingUp or firstTimePickingUp == nil, 
	                                                                  slot or ActiveSlot.SLOT_PRIMARY, 
	                                                                  varData or 0,
	                                                                  pool or ItemPoolType.POOL_TREASURE)
	
	if CustomHealthAPI then
		if not CustomHealthAPI.Helper.PlayerIsIgnored(player) and firstTimePickingUp then
			CustomHealthAPI.Helper.HandleCollectibleHP(player, item)
		end
		
		player:GetData().CustomHealthAPIPersistent = player:GetData().CustomHealthAPIPersistent or {}
		local pdata = player:GetData().CustomHealthAPIPersistent
		
		pdata.HasFunGuyTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_MUSHROOM)
		pdata.HasSeraphimTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_ANGEL)
		pdata.HasLeviathanTransformation = player:HasPlayerForm(PlayerForm.PLAYERFORM_EVIL_ANGEL)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddEternalHearts = function(player, hp)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddEternalHearts(player:GetOtherTwin(), hp)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "ETERNAL_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddEternalHearts(player, hp)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddGoldenHearts = function(player, hp)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddGoldenHearts(player:GetOtherTwin(), hp)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "GOLDEN_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddGoldenHearts(player, hp)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddHearts = function(player, hp)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddHearts(player:GetOtherTwin(), hp)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "RED_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddHearts(player, hp)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddMaxHearts = function(player, hp)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddMaxHearts(player:GetOtherTwin(), hp)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "EMPTY_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddMaxHearts(player, hp)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddRottenHearts = function(player, hp)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddRottenHearts(player:GetOtherTwin(), hp)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "ROTTEN_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddRottenHearts(player, hp)
	end
end

CustomHealthAPI.Helper.HookFunctions.AddSoulHearts = function(player, hp)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.AddSoulHearts(player:GetOtherTwin(), hp)
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "SOUL_HEART", hp)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.AddSoulHearts(player, hp)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickBlackHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickBlackHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "BLACK_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBlackHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickBoneHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickBoneHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "BONE_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickBoneHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickGoldenHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickGoldenHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "GOLDEN_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickGoldenHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickRedHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickRedHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "RED_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRedHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickRottenHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickRottenHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "ROTTEN_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickRottenHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.CanPickSoulHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.CanPickSoulHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI then
		return CustomHealthAPI.Library.CanPickKey(player, "SOUL_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.CanPickSoulHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.ChangePlayerType = function(player, playertype)
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.ChangePlayerType(player, playertype)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.ChangePlayerType(player, playertype)
	end
end

CustomHealthAPI.Helper.HookFunctions.EvaluateItems = function(player)
	if not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	end
	
	isEvaluateCacheFunction = isEvaluateCacheFunction + 1
	CustomHealthAPI.PersistentData.OverriddenFunctions.EvaluateItems(player)
	isEvaluateCacheFunction = isEvaluateCacheFunction - 1
end

CustomHealthAPI.Helper.HookFunctions.GetBlackHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetBlackHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		
		local data = player:GetData().CustomHealthAPISavedata
		local otherMasks = data.OtherHealthMasks
		
		local blackHearts = 0
		for i = #otherMasks, 1, -1 do
			local mask = otherMasks[i]
			for j = #mask, 1, -1 do
				local health = mask[j]
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
					blackHearts = blackHearts << 1
					
					local key = health.Key
					if key == "BLACK_HEART" then
						blackHearts = blackHearts + 1
					end
				end
			end
		end
		
		return blackHearts
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetBlackHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetBoneHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetBoneHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalBoneHP(player, true)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetBoneHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetBrokenHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetBrokenHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalKeys(player, "BROKEN_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetBrokenHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetEffectiveMaxHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetEffectiveMaxHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if CustomHealthAPI.Helper.PlayerIsSoulHeartOnly(player, true) then
			return 0
		end
	
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetRedCapacity(player)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetEffectiveMaxHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetEternalHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetEternalHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		
		local data = player:GetData().CustomHealthAPISavedata
		if data ~= nil then
			return data.Overlays["ETERNAL_HEART"] or 0
		else
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
		end
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetGoldenHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetGoldenHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		
		local data = player:GetData().CustomHealthAPISavedata
		if data ~= nil then
			return data.Overlays["GOLDEN_HEART"] or 0
		else
			return CustomHealthAPI.PersistentData.OverriddenFunctions.GetEternalHearts(player)
		end
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetGoldenHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetHeartLimit = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetHeartLimit(player:GetOtherTwin())
		end
	end
	
	return CustomHealthAPI.PersistentData.OverriddenFunctions.GetHeartLimit(player)
end

CustomHealthAPI.Helper.HookFunctions.GetHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalRedHP(player, true)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetMaxHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetMaxHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalMaxHP(player)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetMaxHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetRottenHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetRottenHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalKeys(player, "ROTTEN_HEART")
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetRottenHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.GetSoulHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.GetSoulHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalSoulHP(player, true)
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.GetSoulHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.HasFullHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.HasFullHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetRedCapacity(player) - CustomHealthAPI.Helper.GetTotalRedHP(player, true) <= 0
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.HasFullHeartsAndSoulHearts = function(player)
	-- so this checks if red hp + soul hp > max hp (ignoring bone)
	-- ...what is the point of this?
	-- does anyone actually use this function?
	-- this isn't what i thought it would do at all
	-- i thought it would check if your red hp + soul hp fills the entire hp bar
	-- that would actually be useful
	-- and why does it ignore bone heart red capacity?
	-- hasfullhearts doesn't do that
	-- florian why
	-- nicalis why
	-- spider why
	-- kilburn why
	-- who do i blame for this
	-- why does this exist
	-- okay so apparently this is the check for regular challenge room doors???
	-- why is it not just called checkifchallengedoorshouldopen or something
	-- the current name is just confusing
	-- goddamnit
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.HasFullHeartsAndSoulHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		return CustomHealthAPI.Helper.GetTotalMaxHP(player) - (CustomHealthAPI.Helper.GetTotalRedHP(player, true) + CustomHealthAPI.Helper.GetTotalSoulHP(player, true)) <= 0
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.HasFullHeartsAndSoulHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.IsBlackHeart = function(player, heart)
	--...why does this skip over the even numbers
	--it's not even a half heart thing
	--it just flat out skips the even numbers and returns false for them
	--wtf
	
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.IsBlackHeart(player:GetOtherTwin(), heart)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		CustomHealthAPI.Helper.CheckIfHealthOrderSet()
		CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
		CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
		if isEvaluateCacheFunction <= 0 then
			CustomHealthAPI.Helper.ResyncHealthOfPlayer(player)
		end
		
		if heart % 2 == 0 or heart < 0 then
			return false
		end
		
		local data = player:GetData().CustomHealthAPISavedata
		local otherMasks = data.OtherHealthMasks
		
		local soulHeartsToProcess = math.floor(heart / 2) + 1
		for i = 1, #otherMasks do
			local mask = otherMasks[i]
			for j = 1, #mask do
				local health = mask[j]
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
					soulHeartsToProcess = soulHeartsToProcess - 1
					
					local key = health.Key
					if soulHeartsToProcess == 0 then
						if key == "BLACK_HEART" then
							return true
						else
							return false
						end
					end
				end
			end
		end
		
		return false
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.IsBlackHeart(player, heart)
	end
end

CustomHealthAPI.Helper.HookFunctions.IsBoneHeart = function(player, heart)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.IsBoneHeart(player:GetOtherTwin(), heart)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if heart < 0 then
			return false
		end
		
		local data = player:GetData().CustomHealthAPISavedata
		local otherMasks = data.OtherHealthMasks
		
		local heartsToProcess = heart + 1
		for i = 1, #otherMasks do
			local mask = otherMasks[i]
			for j = 1, #mask do
				local health = mask[j]
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
					heartsToProcess = heartsToProcess - 1
					
					local key = health.Key
					if heartsToProcess == 0 then
						return false
					end
				elseif CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
				       CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE and 
				       CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP") > 0
				then
					heartsToProcess = heartsToProcess - 1
					
					local key = health.Key
					if heartsToProcess == 0 then
						return true
					end
				end
			end
		end
		
		return false
	else
		return CustomHealthAPI.PersistentData.OverriddenFunctions.IsBoneHeart(player, heart)
	end
end

CustomHealthAPI.Helper.HookFunctions.RemoveBlackHeart = function(player, heart)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.RemoveBlackHeart(player:GetOtherTwin(), heart)
		end
	end
	
	if CustomHealthAPI and not CustomHealthAPI.Helper.PlayerIsIgnored(player) then
		if heart < 0 then
			return
		end
		
		local data = player:GetData().CustomHealthAPISavedata
		local otherMasks = data.OtherHealthMasks
		
		local soulHeartsToProcess = math.floor(heart / 2) + 1
		for i = 1, #otherMasks do
			local mask = otherMasks[i]
			for j = 1, #mask do
				local health = mask[j]
				if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.SOUL then
					soulHeartsToProcess = soulHeartsToProcess - 1
					
					local key = health.Key
					if soulHeartsToProcess == 0 then
						if key == "BLACK_HEART" then
							health.Key = "SOUL_HEART"
							CustomHealthAPI.Helper.UpdateBasegameHealthState(player)
							return
						end
					end
				end
			end
		end
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.RemoveBlackHeart(player, heart)
	end
end

CustomHealthAPI.Helper.HookFunctions.SetFullHearts = function(player)
	if player:GetPlayerType() == PlayerType.PLAYER_THESOUL_B then
		if player:GetOtherTwin() ~= nil then
			return CustomHealthAPI.Helper.HookFunctions.SetFullHearts(player:GetOtherTwin())
		end
	end
	
	if CustomHealthAPI.Library.AddHealth then
		CustomHealthAPI.Library.AddHealth(player, "RED_HEART", 99, true, true)
	else
		CustomHealthAPI.PersistentData.OverriddenFunctions.SetFullHearts(player)
	end
end

CustomHealthAPI.Helper.HookFunctions.RenderHUD = function(hud)
	CustomHealthAPI.PersistentData.OverriddenFunctions.RenderHUD(hud)
	
	if CustomHealthAPI and CustomHealthAPI.Mod and CustomHealthAPI.Mod.RenderCustomHealthCallback then
		CustomHealthAPI.Mod:RenderCustomHealthCallback()
	end
end

CustomHealthAPI.Helper.HookFunctions.TakeDamage = function(ent, amount, flags, source, countdown, damageFunc, ignoreResync)
	local alreadyInDamageCallback = (ent:GetData().CustomHealthAPIOtherData ~= nil and 
	                                ent:GetData().CustomHealthAPIOtherData.InDamageCallback) or nil
	
	local alreadyEnabledDebugThreeForDamage = (ent:GetData().CustomHealthAPIPersistent ~= nil and 
	                                          ent:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage) or nil
	
	local alreadyHandlingDamage = (ent:GetData().CustomHealthAPISavedata ~= nil and 
	                               ent:GetData().CustomHealthAPISavedata.HandlingDamage) or nil
	local alreadyHandlingDamageAmount = (ent:GetData().CustomHealthAPISavedata ~= nil and 
	                                     ent:GetData().CustomHealthAPISavedata.HandlingDamageAmount) or nil
	local alreadyHandlingDamageFlags = (ent:GetData().CustomHealthAPISavedata ~= nil and 
	                                    ent:GetData().CustomHealthAPISavedata.HandlingDamageFlags) or nil
	local alreadyHandlingDamageSource = (ent:GetData().CustomHealthAPISavedata ~= nil and 
	                                     ent:GetData().CustomHealthAPISavedata.HandlingDamageSource) or nil
	local alreadyHandlingDamageCountdown = (ent:GetData().CustomHealthAPISavedata ~= nil and 
	                                        ent:GetData().CustomHealthAPISavedata.HandlingDamageCountdown) or nil
	
	local returnVal = damageFunc(ent, amount, flags, source, countdown)
	if not ignoreResync and 
	   ent:GetData().CustomHealthAPISavedata and 
	   ent:GetData().CustomHealthAPISavedata.HandlingDamage ~= nil 
	then
		CustomHealthAPI.Helper.FinishDamageDesync(ent)
	end
	
	if alreadyInDamageCallback ~= nil then
		ent:GetData().CustomHealthAPIOtherData.InDamageCallback = alreadyInDamageCallback
	end
	
	if alreadyHandlingDamage ~= nil then
		ent:GetData().CustomHealthAPISavedata.HandlingDamage = alreadyHandlingDamage
		ent:GetData().CustomHealthAPISavedata.HandlingDamageAmount = alreadyHandlingDamageAmount
		ent:GetData().CustomHealthAPISavedata.HandlingDamageFlags = alreadyHandlingDamageFlags
		ent:GetData().CustomHealthAPISavedata.HandlingDamageSource = alreadyHandlingDamageSource
		ent:GetData().CustomHealthAPISavedata.HandlingDamageCountdown = alreadyHandlingDamageCountdown
		
		ent:GetData().CustomHealthAPISavedata.HandlingDamageCanShackle = ent:ToPlayer() and
		                                                                 not (player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_SOUL) or 
		                                                                      player:GetEffects():HasNullEffect(NullItemID.ID_SPIRIT_SHACKLES_DISABLED))
		ent:GetData().CustomHealthAPIOtherData.ShouldActivateScapular = ent:ToPlayer() and 
		                                                                ent:ToPlayer():GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_SCAPULAR)
	end
	
	if alreadyEnabledDebugThreeForDamage ~= nil then
		ent:GetData().CustomHealthAPIPersistent.EnabledDebugThreeForDamage = alreadyEnabledDebugThreeForDamage
		
		local s = ""
		repeat
			s = Isaac.ExecuteCommand("debug 3")
		until s == "Enabled debug flag."
	end
	
	return returnVal
end

CustomHealthAPI.Helper.HookFunctions.TakeDamageEntity = function(ent, amount, flags, source, countdown)
	return CustomHealthAPI.Helper.HookFunctions.TakeDamage(ent, 
	                                                       amount, 
	                                                       flags, 
	                                                       source, 
	                                                       countdown, 
	                                                       CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamageEntity)
end

CustomHealthAPI.Helper.HookFunctions.TakeDamagePlayer = function(ent, amount, flags, source, countdown)
	return CustomHealthAPI.Helper.HookFunctions.TakeDamage(ent, 
	                                                       amount, 
	                                                       flags, 
	                                                       source, 
	                                                       countdown, 
	                                                       CustomHealthAPI.PersistentData.OverriddenFunctions.TakeDamagePlayer)
end
