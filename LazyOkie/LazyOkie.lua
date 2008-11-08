--------------------------------------------------------------------------
-- LazyOkie.lua
--------------------------------------------------------------------------
--[[

	-- Author
	Ghryphen (ghryphen@gmail.com)
	https://github.com/ghryphen/World-of-Warcraft

	-- Request
	Please do not re-release this AddOn as "Continued", "Resurrected", etc...
	if you have updates/fixes/additions for it, please contact me. If I am
	no longer active in WoW I will gladly pass on the maintenance to someone
	else, however until then please assume I am still active in WoW.

	-- AddOn Description
	Nides names when entering an instance.

	-- Dependencies
	Portfolio - Embedded

	-- Changes
	2.0.0	- Rewrite
	1.0.0	- Initial Release

	-- SVN info
	$Id: LazyOkie.lua 1090 2008-11-21 20:37:08Z ghryphen $
	$Rev: 1090 $
	$LastChangedBy: ghryphen $
	$Date: 2008-11-21 12:37:08 -0800 (Fri, 21 Nov 2008) $

]]--

if (not LazyOkie) then
	LazyOkie = {}
end

if (not LazyOkie_SavedVars) then
	LazyOkie_SavedVars = {}
end

LazyOkie.Setting = {

	Version = GetAddOnMetadata("LazyOkie", "Version");
	Revision = tonumber(strsub("$Rev: 1090 $", 7, strlen("$Rev: 1090 $") - 2));

}

function LazyOkie.GetDefaults()

	if (not IsInInstance() and LazyOkie_SavedVars.Hidden ~= true ) then
	
		LazyOkie_SavedVars.Hidden = false;

		for index in pairs(NamePanelOptions) do
			LazyOkie_SavedVars[index] = GetCVar(index)
		end

	end
end

function LazyOkie.HideNames()

	LazyOkie_SavedVars.Hidden = true;

	for index in pairs(NamePanelOptions) do
		SetCVar(index, 0, "scriptCVar")
	end

end

function LazyOkie.RestoreNames()

	LazyOkie_SavedVars.Hidden = false;

	for index in pairs(NamePanelOptions) do
		SetCVar(index, LazyOkie_SavedVars[index], "scriptCVar")
	end

end

function LazyOkie.OnEvent()
	if (LazyOkie_SavedVars.Enabled ~= "0") then

	local isInInstance, instanceType = IsInInstance()

	if ( event == "PLAYER_ENTERING_WORLD" ) then

		if ( not IsInInstance() and LazyOkie_SavedVars.Hidden ~= true ) then
			LazyOkie.GetDefaults()
		end

		if ( IsInInstance() and ( instanceType == "party" or instanceType == "raid" ) ) then
			LazyOkie.HideNames()
		else
			LazyOkie.RestoreNames()
		end

	elseif ( event == "PLAYER_LEAVING_WORLD" ) then

		if ( not IsInInstance() and LazyOkie_SavedVars.Hidden ~= true ) then
			LazyOkie.GetDefaults()
		end

	elseif ( event == "CVAR_UPDATE" ) then

		for index in pairs(NamePanelOptions) do
			if ( arg1 == NamePanelOptions[index].text ) then
				LazyOkie.GetDefaults()
				break
			end
		end

	end
	
	end
end

if (not LazyOkieFrame) then
	local frame = CreateFrame("Frame", "LazyOkieFrame")
	frame:Hide()
	frame:SetScript("OnEvent", LazyOkie.OnEvent)
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_LEAVING_WORLD")
	frame:RegisterEvent("CVAR_UPDATE")
end