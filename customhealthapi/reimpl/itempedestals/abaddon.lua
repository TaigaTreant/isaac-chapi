function CustomHealthAPI.Helper.HandleAbaddon(player)
	-- remove all maxhp 0 containers, add an equal number of black hearts + 2
	local data = player:GetData().CustomHealthAPISavedata
	local redMasks = data.RedHealthMasks
	local otherMasks = data.OtherHealthMasks
	
	for i = 1, #redMasks do
		local mask = redMasks[i]
		for j = #mask, 1, -1 do
			table.remove(mask, j)
		end
	end
	
	local maxRemoved = 0
	for i = 1, #otherMasks do
		local mask = otherMasks[i]
		for j = #mask, 1, -1 do
			local health = mask[j]
			if CustomHealthAPI.Library.GetInfoOfHealth(health, "Type") == CustomHealthAPI.Enums.HealthTypes.CONTAINER and
			   CustomHealthAPI.PersistentData.HealthDefinitions[health.Key].KindContained ~= CustomHealthAPI.Enums.HealthKinds.NONE
			then
				local maxHpOfHealth = CustomHealthAPI.Library.GetInfoOfHealth(health, "MaxHP")
				if maxHpOfHealth <= 0 then
					table.remove(mask, j)
					maxRemoved = maxRemoved + 1
				end
			end
		end
	end
	
	CustomHealthAPI.Helper.UpdateHealthMasks(player, "BLACK_HEART", maxRemoved * 2 + 4)
end
