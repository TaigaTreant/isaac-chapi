local version = 0.946

local root = "" -- Replace with the location of the 'customhealthapi' folder in your mod (e.g. "modscripts.dependencies.customhealthapi.")
local modname = "" -- Replace with "Custom Health API" + the name of your mod (e.g. "Custom Health API (My Cool Isaac Mod)"
local modinitials = "" -- Replace with the initials of your mod (e.g. "MCIM")

-- Example of above (from Fiend Folio):
-- local root = "ffscripts.customhealthapi."
-- local modname = "Custom Health API (Fiend Folio)"
-- local modinitials = "FF"

CustomHealthAPI = CustomHealthAPI or {}

local shouldLoadMod
if CustomHealthAPI.Mod and CustomHealthAPI.Mod.Version then
	if CustomHealthAPI.Mod.ModName == modname then
		shouldLoadMod = true
	elseif CustomHealthAPI.Mod.Version < version then
		shouldLoadMod = true
	else
		shouldLoadMod = false
	end
else
	shouldLoadMod = true
end

local hasBadLoad = nil

if shouldLoadMod then
	if CustomHealthAPI.Mod then
		if CustomHealthAPI.CallbacksToRemove then
			for _, func in pairs(CustomHealthAPI.CallbacksToRemove) do
				func()
			end
		end
		
		-- leftover from early versions before addprioritycallback was a thing
		if CustomHealthAPI.ForceEndCallbacksToRemove then
			for callback, funcs in pairs(CustomHealthAPI.ForceEndCallbacksToRemove) do
				for subid, subfuncs in pairs(funcs) do
					if type(subfuncs) == "table" then
						for _, func in pairs(subfuncs) do
							func()
						end
					else
						subfuncs()
					end
				end
			end
		end
		
		-- leftover from early versions before addprioritycallback was a thing
		if CustomHealthAPI.OtherCallbacksToRemove then
			for callback, funcs in pairs(CustomHealthAPI.OtherCallbacksToRemove) do
				for subid, subfuncs in pairs(funcs) do
					if type(subfuncs) == "table" then
						for _, func in pairs(subfuncs) do
							func()
						end
					else
						subfuncs()
					end
				end
			end
		end
	end

	CustomHealthAPI.Mod = RegisterMod(modname, 1)
	CustomHealthAPI.Mod.Version = version
	CustomHealthAPI.Mod.ModName = modname

	CustomHealthAPI.PersistentData = CustomHealthAPI.PersistentData or {}
	CustomHealthAPI.Helper = {}
	CustomHealthAPI.Library = {}
	CustomHealthAPI.Constants = {}
	CustomHealthAPI.Enums = {}

	CustomHealthAPI.Mod.AddedCallbacks = false
	
	CustomHealthAPI.PersistentData.OriginalAddCallback = CustomHealthAPI.PersistentData.OriginalAddCallback or Isaac.AddCallback
	CustomHealthAPI.CallbacksToAdd = CustomHealthAPI.CallbacksToAdd or {}
	CustomHealthAPI.CallbacksToRemove = CustomHealthAPI.CallbacksToRemove or {}
	
	for k,_ in pairs(CustomHealthAPI.CallbacksToAdd) do
		CustomHealthAPI.CallbacksToAdd[k] = nil
	end
	
	for k,_ in pairs(CustomHealthAPI.CallbacksToRemove) do
		CustomHealthAPI.CallbacksToRemove[k] = nil
	end

	-- leftover from early versions before addprioritycallback was a thing
	if CustomHealthAPI.ForceEndCallbacksToAdd then
		for k,_ in pairs(CustomHealthAPI.ForceEndCallbacksToAdd) do
			CustomHealthAPI.ForceEndCallbacksToAdd[k] = nil
		end
	end

	-- leftover from early versions before addprioritycallback was a thing
	if CustomHealthAPI.ForceEndCallbacksToRemove then
		for k,_ in pairs(CustomHealthAPI.ForceEndCallbacksToRemove) do
			CustomHealthAPI.ForceEndCallbacksToRemove[k] = nil
		end
	end

	-- leftover from early versions before addprioritycallback was a thing
	if CustomHealthAPI.OtherCallbacksToAdd then
		for k,_ in pairs(CustomHealthAPI.OtherCallbacksToAdd) do
			CustomHealthAPI.OtherCallbacksToAdd[k] = nil
		end
	end

	-- leftover from early versions before addprioritycallback was a thing
	if CustomHealthAPI.OtherCallbacksToRemove then
		for k,_ in pairs(CustomHealthAPI.OtherCallbacksToRemove) do
			CustomHealthAPI.OtherCallbacksToRemove[k] = nil
		end
	end
	
	-- leftover from early versions before addprioritycallback was a thing
	if CustomHealthAPI.PersistentData.CallbackHandler then
		function CustomHealthAPI.PersistentData.CallbackHandler(self, callbackId, fn, entityId)
			CustomHealthAPI.PersistentData.OriginalAddCallback(self, callbackId, fn, entityId)
		end
	end

	include(root .. "definitions.enums")
	include(root .. "library.callbacks")

	include(root .. "definitions.constants")
	include(root .. "library.addhealth.core")
	include(root .. "library.addhealth.red")
	include(root .. "library.addhealth.soul")
	include(root .. "library.addhealth.container")
	include(root .. "library.addhealth.overlay")
	include(root .. "library.masks.initialize")
	include(root .. "library.masks.order")
	include(root .. "library.backups")
	include(root .. "library.canpickkey")
	include(root .. "library.gethp")
	include(root .. "library.register")
	include(root .. "library.misc")
	include(root .. "definitions.characters")
	include(root .. "definitions.health")
	include(root .. "reimpl.actives.clicker")
	include(root .. "reimpl.actives.genesis")
	include(root .. "reimpl.actives.glowinghourglass")
	include(root .. "reimpl.actives.hiddenplayers")
	include(root .. "reimpl.actives.misc")
	include(root .. "reimpl.cards.reversefool")
	include(root .. "reimpl.cards.reversesun")
	include(root .. "reimpl.cards.strength")
	include(root .. "reimpl.cards.misc")
	include(root .. "reimpl.itempedestals.abaddon")
	include(root .. "reimpl.itempedestals.brittlebones")
	include(root .. "reimpl.itempedestals.core")
	include(root .. "reimpl.pills.hematemesis")
	include(root .. "reimpl.pills.misc")
	include(root .. "reimpl.apioverrides")
	include(root .. "reimpl.changeplayertype")
	include(root .. "reimpl.damage")
	include(root .. "reimpl.pickups")
	include(root .. "reimpl.renderhealthbar")
	include(root .. "reimpl.restock")
	include(root .. "reimpl.resyncing")
	include(root .. "reimpl.shardofglass")
	include(root .. "reimpl.subplayers")
	include(root .. "reimpl.sumptorium")
	include(root .. "reimpl.whoreofbabylon")
	include(root .. "misc")
	include(root .. "savingandloading")
	
	function CustomHealthAPI.Helper.CheckBadLoad()
		local anm2TestSprite = Sprite()
		anm2TestSprite:Load("gfx/ui/ui_hearts.anm2", true)
		anm2TestSprite:Play("RedHeartFull", true)

		anm2TestSprite:SetFrame("RedHeartFull", 0)
		anm2TestSprite:SetLastFrame()
		return anm2TestSprite:GetFrame() ~= 3
	end
	
	function CustomHealthAPI.Helper.AddTestBadLoadCallback()
		Isaac.AddCallback(CustomHealthAPI.Mod, ModCallbacks.MC_POST_RENDER, CustomHealthAPI.Mod.TestBadLoadCallback, -1)
	end
	table.insert(CustomHealthAPI.CallbacksToAdd, CustomHealthAPI.Helper.AddTestBadLoadCallback)

	function CustomHealthAPI.Helper.RemoveTestBadLoadCallback()
		CustomHealthAPI.Mod:RemoveCallback(ModCallbacks.MC_POST_RENDER, CustomHealthAPI.Mod.TestBadLoadCallback)
	end
	table.insert(CustomHealthAPI.CallbacksToRemove, CustomHealthAPI.Helper.RemoveTestBadLoadCallback)

	function CustomHealthAPI.Mod:TestBadLoadCallback()
		if hasBadLoad == true or (hasBadLoad == nil and CustomHealthAPI.Helper.CheckBadLoad()) then
			hasBadLoad = true

			local font = Font()
			font:Load("font/pftempestasevencondensed.fnt")
			local fontColor = KColor(1,0.5,0.5,1)
			
			if modinitials ~= nil then
				font:DrawString("[" .. modinitials .. "] Custom Health API animation files failed to load.",70,100,fontColor,0,false)
			else
				font:DrawString("Custom Health API animation files failed to load.",70,100,fontColor,0,false)
			end
			font:DrawString("Restart your game!",70,110,fontColor,0,false)
			
			font:DrawString("(This tends to happen when the mod is first installed, or when",70,120,fontColor,0,false)
			font:DrawString("it is re-enabled via the mod menu.)",70,130,fontColor,0,false)
			font:DrawString("If the issue persists, you may be experiencing a download failure",70,140,fontColor,0,false)
			font:DrawString("or mod incompatibility.",70,150,fontColor,0,false)
			
			font:DrawString("You will also need to restart the game after disabling the mod.",70,160,fontColor,0,false)
		else
			hasBadLoad = false
		end
	end

	for _, func in pairs(CustomHealthAPI.CallbacksToAdd) do
		func()
	end
	
	if not CustomHealthAPI.PersistentData.ShownDisclaimer then
		print("Custom Health API: v" .. version .. " Loaded")
		CustomHealthAPI.PersistentData.ShownDisclaimer = true
	end
end
