--------------------------------------------------------------------------
-- UserIScale.lua
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
	Saves separate uiScale values per WoW account.

	-- Dependencies
	None

	-- Changes
	1.00	- Initial Release

	-- SVN info
	$Id: UserIScale.lua 1087 2008-11-20 19:26:54Z ghryphen $
	$Rev: 1087 $
	$LastChangedBy: ghryphen $
	$Date: 2008-11-20 11:26:54 -0800 (Thu, 20 Nov 2008) $

]]--

if (not UserIScale) then
	UserIScale = {}
end

function UserIScale.OnEvent()
	if (event == "VARIABLES_LOADED") then
		if (not UserIScale_uiScale) then
			UserIScale_uiScale = GetCVar("uiScale")
		else
			SetCVar("uiScale", UserIScale_uiScale, "scriptCVar")
		end
	elseif (event == "UPDATE_FLOATING_CHAT_WINDOWS") then
		UserIScale_uiScale = GetCVar("uiScale")
	end
end

if (not UserIScaleFrame) then
	CreateFrame("Frame", "UserIScaleFrame")
end
UserIScaleFrame:Hide()
UserIScaleFrame:SetScript("OnEvent", UserIScale.OnEvent)
UserIScaleFrame:RegisterEvent("VARIABLES_LOADED")
UserIScaleFrame:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS")