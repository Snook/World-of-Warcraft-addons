--------------------------------------------------------------------------
-- ZoneTimer.lua
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
	Displays how long it takes to zone in seconds.

	-- Dependencies
	None

	-- Changes
	1.23	- Updated TOC for 2.4
	1.22	- Updated TOC for 2.1
	1.21	- Updated TOC for 2.0
	1.20	- Dropped .xml for CreateFrame()
	1.13	- Updated TOC for 1.12
	1.12	- Fixed syntax errors
	1.11	- Updated TOC for 1.11
	1.10	- Cleaning house, general maintenance and reorganization.
	1.00	- Initial Release

  -- SVN info
	$Id: ZoneTimer.lua 1088 2008-11-20 19:32:24Z ghryphen $
	$Rev: 1088 $
	$LastChangedBy: ghryphen $
	$Date: 2008-11-20 11:32:24 -0800 (Thu, 20 Nov 2008) $

]]--

local ZT = {
	Version = GetAddOnMetadata("ZoneTimer", "Version");
	Revision = tonumber(strsub("$Rev: 1088 $", 7, strlen("$Rev: 1088 $") - 2));
	Time = 0.01;
}

function ZoneTimer_OnEvent()
	if ( event == "PLAYER_ENTERING_WORLD" ) then
	  local t = GetTime() - ZT.Time
	  local c = "00cc00"

	  if ( t > 10 ) then
	    c = "ff0000"
	  elseif ( t > 5 ) then
	    c = "ffff00"
	  end

	  if ( t > .01 ) then
	    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffffd100ZoneTimer:|r |cff"..c.."%.3f Seconds|r", t))
	  end
	elseif ( event == "PLAYER_LEAVING_WORLD" ) then
		ZT.Time = GetTime()
		this:RegisterEvent("PLAYER_ENTERING_WORLD")
	end
end

--Event Driver
if (not ZoneTimerFrame) then
	CreateFrame("Frame", "ZoneTimerFrame")
end
ZoneTimerFrame:Hide()
--Frame Scripts
ZoneTimerFrame:SetScript("OnEvent", ZoneTimer_OnEvent)
ZoneTimerFrame:RegisterEvent("PLAYER_LEAVING_WORLD")