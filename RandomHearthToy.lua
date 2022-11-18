-- To use random hearthstone toys gathered through world events.

local AllHearthToyIndex = {} --All the toys
local UsableHearthToyIndex = {} --Usable toys
local RHTIndex = false --Macro index
RHT = {} --Setup for button and timeout frame
local RHTInitialized = false

-- Setting up an invisible button named RHTB.  Toys can only be used through a button click, so we need one for the macro to click.
local frame = CreateFrame("Frame")
RHT.b = CreateFrame("Button","RHTB",nil,"SecureActionButtonTemplate")
RHT.b:SetAttribute("type","item")
-- Setting up a frame to wait and see if the toybox is loaded before getting stones on login.
local timeOut = 10 --Delay for checking stones.
RHT.to = CreateFrame("Frame","RHTO", UIParent)
RHT.to:SetScript("OnUpdate", function (self, elapse)
	if timeOut > 0 then
		timeOut = timeOut - elapse
	else
		if C_ToyBox.GetNumToys() > 0 then
			GetLearnedStones()
			if RHTInitialized then
				SetRandomHearthToy()
				-- print "RHT initialized" -- uncomment for debugging future versions
				RHT.to:SetScript("OnUpdate", nil)
			else
				timeOut = 1
			end
		else
			timeOut = 1
		end
	end
end)

frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Spellcast stopping is the check for if a hearthstone has been used.
frame:RegisterEvent("UNIT_SPELLCAST_STOP")

local function Event(self, event, arg1, arg2, arg3)
	if event == "PLAYER_ENTERING_WORLD" then
		GetMacroIndex()
		frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
	-- When a spell cast stops and it's the player's spell, send the ID to check if it's a stone.
	if event == "UNIT_SPELLCAST_STOP" and arg1 == "player" then
		SpellcastUpdate(arg3)
	end
end

frame:SetScript("OnEvent", Event)

-- Generate list of stones in game.
AllHearthToyIndex[166747] = 286353 --Brewfest
AllHearthToyIndex[165802] = 286031 --Noble
AllHearthToyIndex[165670] = 285424 --Peddlefeet
AllHearthToyIndex[165669] = 285362 --Lunar
AllHearthToyIndex[166746] = 286331 --Fire Eater
AllHearthToyIndex[163045] = 278559 --Horseman
AllHearthToyIndex[162973] = 278244 --Greatfather
AllHearthToyIndex[142542] = 231504 --Tome of TP
AllHearthToyIndex[64488]  = 94719   --Innkeeper
AllHearthToyIndex[54452]  = 75136   --Ethereal
AllHearthToyIndex[93672]  = 136508  --Dark Portal
AllHearthToyIndex[168907] = 298068 --Holographic Digitalization
AllHearthToyIndex[172179] = 308742 --Eternal Traveler
AllHearthToyIndex[182773] = 340200 --Necrolord
AllHearthToyIndex[180290] = 326064 --Night Fae
AllHearthToyIndex[184353] = 345393 --Kyrian
AllHearthToyIndex[183716] = 342122 --Venthyr
AllHearthToyIndex[188952] = 363799 --Dominated Hearthstone
AllHearthToyIndex[190237] = 367013 --Broker Translocation Matrix
AllHearthToyIndex[193588] = 375357 --Timewalker's Hearthstone



-- This is the meat right here.
function SetRandomHearthToy()
	-- Setting the new stone while in combat is bad.
	--if not InCombatLockdown() then
		-- Find the macro.
		CheckMacroIndex()
		-- Rebuild the stone list if it's empty.
		if next(UsableHearthToyIndex) == nil then
			GetLearnedStones()
		end		
		local itemID, toyName = ''
		-- Randomly pick one.
		local k = RandomKey(UsableHearthToyIndex)
		local itemID, toyName = C_ToyBox.GetToyInfo(k)
		if toyName then
			-- Remove it from the list so we don't pick it again.
			RemoveStone(k)
			-- Write the macro.
			GenMacro(itemID, toyName)
			-- Set button for first use
			if not RHT.b:GetAttribute("item") then RHT.b:SetAttribute("item",toyName) end
		end
	--end
end

-- Get stones learned and usable by character
function GetLearnedStones()
	-- Get the current setting for the toybox so we can set it back after we're done.
	ToyCollSetting = C_ToyBox.GetCollectedShown()
	ToyUnCollSetting = C_ToyBox.GetUncollectedShown()
	ToyUsableSetting = C_ToyBox.GetUnusableShown()
	
	C_ToyBox.SetCollectedShown(true) -- List collected toys
	C_ToyBox.SetUncollectedShown(false) -- Don't list uncollected toys
	C_ToyBox.SetUnusableShown(false) -- Don't list unusable toys in the the collection.	
	
	-- Go through all the toys to find the usable stons.
	for i = 1, C_ToyBox.GetNumFilteredToys() do
		-- Go through all the stone to see if this toy is a stone.
		for k in pairs(AllHearthToyIndex) do
			if k == C_ToyBox.GetToyFromIndex(i) then
				UsableHearthToyIndex [k] = 1
			end
		end
	end
	 -- Reset the toybox filter
	C_ToyBox.SetCollectedShown(ToyCollSetting)
	C_ToyBox.SetUncollectedShown(ToyUnCollSetting)
	C_ToyBox.SetUnusableShown(ToyUsableSetting)
	if next(UsableHearthToyIndex) then
		RHTInitialized = true
	end
end

-- We've removed the name from the macro, so now we need to find it so we know which one to edit.
function GetMacroIndex()
	local numg, numc = GetNumMacros()
	for i = 1, numg do
		local macroCont = GetMacroBody(i)
		--  Hopefully no other macro ever made has "RHT.b" in it...
		if string.find(macroCont, "RHT.b") then
			RHTIndex = i
		end
	end
end

-- Have we found the macro yet? Also, make sure the macro we're editing is the right one in case the user rearranged things or deleted it.  If not, go find it.
function CheckMacroIndex()
	local macroCont = GetMacroBody(RHTIndex)
	if macroCont then
		if string.find(macroCont, "RHT.b") then
			return
		end
	end
	GetMacroIndex()
end

-- Macro writing time.
function GenMacro(itemID, toyName)
	-- Did we find the index?  If so, edit that. The macro changes the button to the next stone, but only if we aren't in combat; can't SetAttribute. It then "clicks" the RHTB button
	if RHTIndex then
		EditMacro(RHTIndex, " ", "INV_MISC_QUESTIONMARK", "#showtooltip item:" .. itemID .. "\r/run if not InCombatLockdown() then RHT.b:SetAttribute(\"item\",\"" .. toyName .. "\") end\r/click RHTB LeftButton 1")
	else
		-- No macro found, make a new one, get it's ID, then set the toy on the invisble button. This one is named so people can find it on first use.
		CreateMacro("RHT", "INV_MISC_QUESTIONMARK", "#showtooltip item:" .. itemID .. "\r/run if not InCombatLockdown() then RHT.b:SetAttribute(\"item\",\"" .. toyName .. "\") end\r/click RHTB LeftButton 1")
		GetMacroIndex()
	end
end

-- Remove stone from the list so we don't use it again. (Here for debugging)
function RemoveStone(k)
	UsableHearthToyIndex[k] = nil
end

-- Did a stone get used?
function SpellcastUpdate(spellID)
	if not InCombatLockdown() then
		for k in pairs(AllHearthToyIndex) do
			if spellID == AllHearthToyIndex[k] or spellID == 346060 then -- there are two necrolord spells, adding one here temporarily, should refactor the spell lists soon
				SetRandomHearthToy()
				break
			end
		end
	end
end



-- Code to randomly pick a key from a table.
function RandomKey(t)
    local keys = {}
    for key, value in pairs(t) do
        keys[#keys+1] = key --Store keys in another table.
    end
    index = keys[math.random(1, #keys)]
    return index
end
