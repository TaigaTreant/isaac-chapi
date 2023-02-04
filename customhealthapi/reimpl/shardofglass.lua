local bleedingSprite = Sprite()
bleedingSprite:Load("gfx/statuseffects.anm2", true)

function CustomHealthAPI.Helper.AddUpdateShardOfGlassColorCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PEFFECT_UPDATE, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.UpdateShardOfGlassColorCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddUpdateShardOfGlassColorCallback)

function CustomHealthAPI.Helper.RemoveUpdateShardOfGlassColorCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, CustomHealthAPI.Mod.UpdateShardOfGlassColorCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveUpdateShardOfGlassColorCallback)

function CustomHealthAPI.Mod:UpdateShardOfGlassColorCallback(player)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then return end
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.UpdateShardOfGlassColor(player)
end

function CustomHealthAPI.Helper.AddUpdateShardOfGlassCallback()
	Isaac.AddPriorityCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_PLAYER_UPDATE, CustomHealthAPI.Enums.CallbackPriorities.LATE, CustomHealthAPI.Mod.UpdateShardOfGlassCallback, -1)
end
table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddUpdateShardOfGlassCallback)

function CustomHealthAPI.Helper.RemoveUpdateShardOfGlassCallback()
	CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, CustomHealthAPI.Mod.UpdateShardOfGlassCallback)
end
table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveUpdateShardOfGlassCallback)

function CustomHealthAPI.Mod:UpdateShardOfGlassCallback(player)
	CustomHealthAPI.Helper.CheckIfHealthOrderSet()
	CustomHealthAPI.Helper.CheckHealthIsInitializedForPlayer(player)
	if CustomHealthAPI.Helper.PlayerIsIgnored(player) then return end
	CustomHealthAPI.Helper.CheckSubPlayerInfoOfPlayer(player)
	CustomHealthAPI.Helper.UpdateShardOfGlass(player)
end

function CustomHealthAPI.Helper.UpdateShardOfGlassColor(player)
	local data = player:GetData().CustomHealthAPISavedata
	if data and data.ShardBleedTimer ~= nil then
		local timer = data.ShardBleedTimer
		local tint = 1.0
		local offset = 0
		if timer < 58 then
			if (timer % 8) == 1 or (timer % 8) == 0 then
				tint = 0.0
				offset = 1
			elseif (timer % 8) == 7 or (timer % 8) == 6 then
				tint = 0.25
				offset = 0.75
			elseif (timer % 8) == 5 or (timer % 8) == 4 then
				tint = 0.5
				offset = 0.5
			elseif (timer % 8) == 3 or (timer % 8) == 2 then
				tint = 0.75
				offset = 0.25
			end
		end
		
		local color = Color(1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0)
		color = Color.Lerp(color, player:GetSprite().Color, math.min(1.0, timer / 300))
		color.G = color.G * tint
		color.B = color.B * tint
		color.RO = color.RO + offset
		
		player:SetColor(color, 1, 1, false, false)
	end
end

function CustomHealthAPI.Helper.UpdateShardOfGlass(player)
	local data = player:GetData().CustomHealthAPISavedata
	
	if player:HasEntityFlags(EntityFlag.FLAG_BLEED_OUT) then
		player:ClearEntityFlags(EntityFlag.FLAG_BLEED_OUT)
		if data then data.ShardBleedTimer = 1200 end
	end
	
	if data and 
	   data.ShardBleedTimer ~= nil and
	   (CustomHealthAPI.Helper.GetTotalRedHP(player, true) <= 0 or 
	    CustomHealthAPI.Helper.GetTotalHP(player) <= 1 or
		player:GetEffects():HasNullEffect(NullItemID.ID_LOST_CURSE))
	then 
		data.ShardBleedTimer = nil 
	end
	
	if data and data.ShardBleedTimer ~= nil then
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		if player:GetData().CustomHealthAPIOtherData.LastBleedTick ~= Game():GetFrameCount() then
			data.ShardBleedTimer = data.ShardBleedTimer - 2
			player:GetData().CustomHealthAPIOtherData.LastBleedTick = Game():GetFrameCount()
			
			if math.random() <= 0.25 and not player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_SCISSORS) then
				local aim = player:GetAimDirection()
				local inheritance = player:GetTearMovementInheritance(aim)
				local dir = aim:Resized(8)
				
				local angle = math.random() * 360.0
				local vel = Vector.FromAngle(angle):Resized(math.random() * 2) + dir + inheritance
				
				local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLOOD, 0, player.Position, vel, player):ToTear()
				local rand = math.random()
				tear.CollisionDamage = player.Damage * (rand * 0.3375 + 0.675)
				tear.Scale = (0.55 + math.sqrt(player.Damage) * 0.23 + player.Damage / 100) * (rand * 0.5 + 0.75)
				tear.Height = -11.01 + math.random() * 1.02
				tear.FallingSpeed = -14.1 + math.random() * 10.2
				tear.FallingAcceleration = 0.5
				
				tear:Update()
			end
			
			if math.random() <= 0.20 and not player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_ANEMIC) then
				local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0, player.Position, Vector.Zero, player):ToEffect()
				creep:Update()
			end
		end
		
		if data.ShardBleedTimer <= 0 then
			player:TakeDamage(1, 33824800, EntityRef(player), 0)
			if CustomHealthAPI.Helper.GetTotalRedHP(player, true) > 0 and CustomHealthAPI.Helper.GetTotalHP(player) > 1 then
				data.ShardBleedTimer = 1200
			else
				data.ShardBleedTimer = nil
			end
		end
	end
end

function CustomHealthAPI.Helper.RenderShardOfGlass(player, offset)
	local data = player:GetData().CustomHealthAPISavedata
	
	if data and data.ShardBleedTimer ~= nil then
		player:GetData().CustomHealthAPIOtherData = player:GetData().CustomHealthAPIOtherData or {}
		if player:GetData().CustomHealthAPIOtherData.BleedSpriteFrame == nil then
			player:GetData().CustomHealthAPIOtherData.BleedSpriteFrame = 0
			player:GetData().CustomHealthAPIOtherData.LastBleedSpriteUpdate = Game():GetFrameCount()
		end
		
		player:GetData().CustomHealthAPIOtherData.BleedSpriteFrame = player:GetData().CustomHealthAPIOtherData.BleedSpriteFrame + 
		                                                             (Game():GetFrameCount() - player:GetData().CustomHealthAPIOtherData.BleedSpriteFrame)
		player:GetData().CustomHealthAPIOtherData.LastBleedSpriteUpdate = Game():GetFrameCount()
		
		bleedingSprite.Scale = player.SpriteScale
		bleedingSprite:SetFrame("BleedingOut", player:GetData().CustomHealthAPIOtherData.BleedSpriteFrame % 18)
		bleedingSprite:Render(Isaac.WorldToRenderPosition(player.Position) + offset + Vector(0,-35) * player.SpriteScale.Y, Vector.Zero, Vector.Zero)
	end
end
