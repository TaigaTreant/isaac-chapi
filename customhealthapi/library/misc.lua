function CustomHealthAPI.Library.ResetPlayerData(player, includeOtherData)
	player:GetData().CustomHealthAPISavedata = nil
	if includeOtherData then
		player:GetData().CustomHealthAPIOtherData = nil
	end
	
	local i = CustomHealthAPI.Helper.GetPlayerIndex(player)
	CustomHealthAPI.PersistentData.HiddenPlayerHealthBackup[i] = nil
	
	if player:GetSubPlayer() ~= nil then
		player:GetSubPlayer():GetData().CustomHealthAPISavedata = nil
		if includeOtherData then
			player:GetSubPlayer():GetData().CustomHealthAPIOtherData = nil
		end
	end
end
