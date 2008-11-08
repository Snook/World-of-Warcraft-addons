--------------------------------------------------------------------------
-- GuildRecruiter.lua
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
	Automatically sends a recruitment messages to the GuildRecruitment channel
	in regular intervals and automatically invites new recruits interested
	in joining.

	-- Dependencies
	Chronos - Embedded

	-- Changes
	1.13	- Updated TOC for 2.4
	1.12	- Updated TOC for 2.1
				- Now uses hidden chat channel to detect reset.
	1.11	- Updated TOC for 2.0
	1.10	- Change default message
	1.09	- Updated TOC for 1.12
	1.08	- Updated TOC for 1.11
	1.07	- Embedded Chronos
	1.06	- Fixed public note setting
	1.05	- Fixed Round error
	1.04	- GuildRecruitment channel should get activated properly now
				- Fixed not in guild message when you are not in a guild
	1.03	- GetGuildRosterInfo Bug fix
				- Changed the way spam detection works, hopefully we dont all spam anymore
	1.02	- Message length adjustments
				- Added length check before sending message
				- Added automatic recruit note set (thanks to SilverTalon the guinea pig)
				- Fixed number of online guild member check
	1.01	- Bug fixes
				- Limit message length
	1.0		- Initial Private Release

	-- SVN info
	$Id: GuildRecruiter.lua 1088 2008-11-20 19:32:24Z ghryphen $
	$Rev: 1088 $
	$LastChangedBy: ghryphen $
	$Date: 2008-11-20 11:32:24 -0800 (Thu, 20 Nov 2008) $

	-- Defaults
	-- Guild leaders should set these before distributing to your guild in order for
	-- it to work optimally.

	-- INVITE.AUTO
	-- Set to "1" to have the AutoInvite keyword enabled by default, "0" for disabled.

	-- INVITE.MESSAGE
	-- Set to "1" to have the AutoInvite keyword added to your Recruitment message.

	-- INVITE.KEYWORD
	-- This is the word/words that are needed in a whisper to you in order for you
	-- to send them and auto invite, this can be used without the recruitment spam.

	-- RECRUIT.AUTO
	-- Set to "1" to have the AutoRecruit message enabled by default, "0" for disabled.

	-- RECRUIT.GUILDNAME
	-- Needs to match the guild you are in, just to make sure you dont advertise for
	-- a guild you dont want to advertise for.
	-- Say you want to advertise for "Insert Guild Name" on server 1, but on server 2
	-- you are in "Guild Insert Name" and dont want to advertise for them.

	-- RECRUIT.MESSAGE
	-- This is the message that is spamed to the GuildRecruitment channel.  If
	-- AutoInvite is enabled, the keyword will be appended to this message automatically.
	-- Make sure this message is no longer than GR_SETTING.MSGLENGTH

	-- RECRUIT.THRESHOLD
	-- How many people need to be online in order for the recruitment message to
	-- be broadcasted. This allows you to have a good showing of members for your potentials.

	-- RECRUIT.INTERVAL
	-- How often in seconds should the recruit message be sent.
	-- Don't be obnoxious and set this to a low number, it will really piss
	-- people off.

	-- VERSION/REVISION/MSGLENGTH/DEBUG
	-- No need to change.
	-- Debug set to "1" will disable the recruitment message sent to GuildRecruitment
	-- channel and it will just print it to your chat window.
	-- MsgLength should be around 170 for most guilds.

]]--

GR_Setting = {
	Version = GetAddOnMetadata("GuildRecruiter", "Version");
	Revision = "$Rev: 1088 $";
	MsgLength = 170;
	Debug = 0;
}

GR_Options = {
	Invite = {
		Auto = 1;
		Message = 1;
		Keyword = "invite to guild";
	};
	Recruit = {
		Auto = 1;
		Tag = "<ATF>";
		GuildName = "Allied Tribal Forces";
		Message = "We are a casual-friendly guild seeking mature, interactive members of any level who are looking for a well established guild. We encourage TS and Forum use.";
		Threshold = 8;
		Interval = 900;
	};
	Default = {
		Invite = {};
		Recruit = {};
	};
}

GR_On = {

	Load = function()

		GR_Register.RegisterEvent("CHAT_MSG_ADDON")
		--GR_Register.RegisterEvent("CHAT_MSG_CHANNEL")
		GR_Register.RegisterEvent("CHAT_MSG_WHISPER")
		GR_Register.RegisterEvent("CHAT_MSG_SYSTEM")

		GR_Register.SlashCommands()

		GR_Chronos.scheduleRepeating()

	end;

	Event = function(event)

		if (event == "CHAT_MSG_WHISPER" and GR_Options.Invite.Auto == 1 and GR_Check.Message(arg1, GR_Options.Invite.Keyword)) then
			if (CanGuildInvite()) then
				GuildInviteByName(arg2);
				GR_Out.Print("AutoInvite: "..GR_Color.Green(arg2))
			else
				GR_Out.Print(GR_Color.Red(arg2).." wants a guild invite, but you can't grant that wish.")
			end
		elseif (event == "CHAT_MSG_ADDON" and arg1 == "AM_GR" and arg3 == "GUILD") then
			GR_Chronos.unscheduleRepeating()
			GR_Chronos.schedule(GR_Chronos.scheduleRepeating)
			GR_Out.Print("Detected an AutoRecruit message for "..GR_Color.Green(GR_Options.Recruit.GuildName).." by "..arg2..", restarting timer.")
		elseif (event == "CHAT_MSG_SYSTEM" and CanEditPublicNote()) then
			local player = GR_Check.JoinedGuild(arg1)
			if (player) then
				GR_Chronos.schedule(GR_Function.SetPublicNote, player)
			end
		end

	end;

}

GR_Check = {

	JoinedGuild = function(msg)
		local joinedguild = string.format(ERR_GUILD_JOIN_S, "(.+)")
		local _, _, player = string.find(msg, joinedguild)
		if (player) then
			GR_Out.Print("Detected a new member in the guild: "..GR_Color.Green(player))
		end
		return player;
	end;

	Message = function(msg, forwhat)
		return string.find(string.lower(msg), string.lower(forwhat), 1, true)
	end;

	ShouldRecruit = function()
		if (GR_Setting.Debug == 1) then
			return 1;
		elseif (GR_Options.Recruit.Auto == 1 and IsInGuild()) then
			GuildRoster()

			local showOfflineTemp = GetGuildRosterShowOffline();
			SetGuildRosterShowOffline(0);
			local numGuildMembers = GetNumGuildMembers()
			SetGuildRosterShowOffline(showOfflineTemp)

		  local faction = UnitFactionGroup("player");
			local zone = GetRealZoneText()
			local guildName, _, _ = GetGuildInfo("player")
			if (numGuildMembers >= GR_Options.Recruit.Threshold and guildName == GR_Options.Recruit.GuildName and CanGuildInvite() and GR_CAPITAL_CITIES[faction][zone]) then
				return 1;
			end
		else
		  return 0;
		end
	end;

}

GR_Recruit = {

	JoinChannel = function()
		JoinChannelByName("GuildRecruitment", nil, DEFAULT_CHAT_FRAME:GetID())
		local id, name = GetChannelName("GuildRecruitment - City");
		ChatFrame_AddChannel(DEFAULT_CHAT_FRAME, name);
		return id
	end;

	BuildMessage = function()
		local msg = GR_Options.Recruit.GuildName..": "..GR_Options.Recruit.Message;
		local plural = nil;

		if (GR_Check.Message(GR_Options.Invite.Keyword, " ")) then
			plural = "s"
		else
			plural = ""
		end

		if (GR_Options.Invite.Auto == 1 and GR_Options.Invite.Message == 1) then
			return msg.." PST for more info or with the word"..plural.." '"..GR_Options.Invite.Keyword.."'.";
		else
			return msg.." PST for more info.";
		end
	end;

  Send2Chat = function()
  	if (GR_Check.ShouldRecruit() == 1) then
  		local channel = GR_Recruit.JoinChannel()
  		local playerName = UnitName("player")
  		GR_Chronos.schedule(GR_Out.Broadcast, channel)
		SendAddonMessage("AM_GR", playerName, "GUILD");
  	end
  end;

}

GR_Out = {

  Broadcast = function(channel)
  	local msg = GR_Recruit.BuildMessage()
		if (string.len(msg) > 255) then
			GR_Out.Print("Message is too long, it is "..GR_Color.Red(string.len(msg)).." characters long, the limit is "..GR_Color.Green("255")..". This is the current message: "..msg)
		elseif (GR_Setting.Debug == 1) then
			GR_Out.Print(msg)
		else
			SendChatMessage(msg, "CHANNEL", nil, channel)
		end
	end;

	Print = function(msg)
		local color = NORMAL_FONT_COLOR;
		DEFAULT_CHAT_FRAME:AddMessage("GuildRecruiter: "..msg, color.r, color.g, color.b)
	end;

}

GR_Chronos = {

	schedule = function(func, channel)
		local z = math.random(4, 16)
		if (channel) then
			Chronos.schedule(z, func, channel)
		else
			Chronos.schedule(z, func)
		end
	end;

	scheduleRepeating = function()
		Chronos.scheduleRepeating("GRMessage", GR_Options.Recruit.Interval, GR_Recruit.Send2Chat)
	end;

	unscheduleRepeating = function()
		Chronos.unscheduleRepeating("GRMessage")
	end;

	isScheduledByName = function()
		return Chronos.isScheduledByName("GRMessage")
	end;

}

GR_Color = {

	Green = function(msg)
		return "|cff00cc00"..msg.."|r";
	end;

	Red = function(msg)
		return "|cffff0000"..msg.."|r";
	end;

}

GR_Function = {

	-- GetGuildMemberIndex from GroupCalendar
	-- http://www.curse-gaming.com/mod.php?addid=2718
	GetGuildMemberIndex = function(pPlayerName)
		local		vUpperUserName = pPlayerName
		local		vNumGuildMembers = GetNumGuildMembers(true)

		for vIndex = 1, vNumGuildMembers do
			local	vName = GetGuildRosterInfo(vIndex)

			if vName == pPlayerName then
				return vIndex;
			end
		end

		return nil;
	end;

	SetPublicNote = function(player)
		GuildRoster()
		local index = GR_Function.GetGuildMemberIndex(player)
		if (index) then
			local _, _, _, _, _, _, note, _, _, _ = GetGuildRosterInfo(index);
			if (note == "") then
				local joindate = date("%m-%d-%Y")
				GuildRosterSetPublicNote(index, joindate)
				GR_Out.Print("Setting note for ("..index..")"..GR_Color.Green(player).." to "..GR_Color.Green(joindate)..".")
			end
		end
	end;

}

--[[ Slash Commands ]]--

GR_Register = {

	RegisterEvent = function(event)
		this:RegisterEvent(event)
	end;

	SlashCommands = function()
		SLASH_GR_HELP1 = "/gr";
		SLASH_GR_HELP2 = "/grecruiter";
	 	SlashCmdList["GR_HELP"] = GR_Command.Help;

	 	SLASH_GR_STATUS1 = "/grstatus";
	 	SlashCmdList["GR_STATUS"] = GR_Command.Status;

		SLASH_GR_TOGGLEALL1 = "/grtoggleall";
	 	SlashCmdList["GR_TOGGLEALL"] = GR_Command.ToggleAll;

		SLASH_GR_IAUTO1 = "/griauto";
	 	SlashCmdList["GR_IAUTO"] = GR_Command.Invite.Auto;

		SLASH_GR_IMESSAGE1 = "/grimessage";
	 	SlashCmdList["GR_IMESSAGE"] = GR_Command.Invite.Message;

		SLASH_GR_IKEYWORD1 = "/grikeyword";
	 	SlashCmdList["GR_IKEYWORD"] = GR_Command.Invite.Keyword;

		SLASH_GR_RAUTO1 = "/grrauto";
	 	SlashCmdList["GR_RAUTO"] = GR_Command.Recruit.Auto;

		SLASH_GR_RMESSAGE1 = "/grrmessage";
	 	SlashCmdList["GR_RMESSAGE"] = GR_Command.Recruit.Message;

		SLASH_GR_RTHRESHOLD1 = "/grrthreshold";
	 	SlashCmdList["GR_RTHRESHOLD"] = GR_Command.Recruit.Threshold;

		SLASH_GR_RINTERVAL1 = "/grrinterval";
	 	SlashCmdList["GR_RINTERVAL"] = GR_Command.Recruit.Interval;

		SLASH_GR_RGUILDNAME1 = "/grrguildname";
	 	SlashCmdList["GR_RGUILDNAME"] = GR_Command.Recruit.GuildName;

	 	SLASH_GR_VERSION1 = "/grversion";
	 	SlashCmdList["GR_VERSION"] = GR_Command.Version;
	end;

}

GR_Command = {

	Help = function(msg)
  	local cmd = string.lower(msg)

		if (cmd == "" or cmd == "help") then
			GR_Out.Print("/grstatus, shows current status.")
			GR_Out.Print("/grtoggleall "..GR_Color.Green("help")..", toggle all on or off.")
			GR_Out.Print("/griauto, toggle AutoInvite On/Off")
			GR_Out.Print("/grimessage, toggle AutoInvite public Keyword annouce On/Off")
			GR_Out.Print("/grikeyword "..GR_Color.Green("help")..", change AutoInvite Keyword.")
			GR_Out.Print("/grrauto, toggle AutoRecruit On/Off")
			GR_Out.Print("/grrmessage "..GR_Color.Green("help")..", change AutoRecruit Message.")
			GR_Out.Print("/grrthreshold "..GR_Color.Green("help")..", change AutoRecruit Threshold.")
			GR_Out.Print("/grrinterval "..GR_Color.Green("help")..", change AutoRecruit message Interval.")
			GR_Out.Print("/grrguildname "..GR_Color.Green("help")..", change AutoRecruit Guild.")
			GR_Out.Print("/grrtag "..GR_Color.Green("help")..", change AutoRecruit identifier Tag.")
			GR_Out.Print("/grversion, shows version info.")
		end
	end;

	Status = function(msg)
		local cmd = string.lower(msg)
		local rstatus = GR_Color.Red("Off");
		local rtime = 0.000;
		local istatus = GR_Color.Red("Off");
		local imstatus = GR_Color.Red("Off");

		if (GR_Options.Recruit.Auto == 1) then
			rstatus = GR_Color.Green("On");
			local scheduledbyname = GR_Chronos.isScheduledByName();
			if (scheduledbyname) then
				rtime = scheduledbyname;
			end
		end

		if (GR_Options.Invite.Auto == 1) then
			istatus = GR_Color.Green("On");
		end

		if (GR_Options.Invite.Message == 1) then
			imstatus = GR_Color.Green("On");
		end

		GR_Out.Print("AutoRecruit is "..rstatus..", "..GR_Color.Green(string.format("%.3f", rtime)).." seconds until next broadcast.")
		GR_Out.Print("AutoInvite is "..istatus)
		GR_Out.Print("AutoInvite in public Message is "..imstatus)

		if (cmd == "full") then
			GR_Out.Print("AutoInvite Keyword is: "..GR_Color.Green(GR_Options.Invite.Keyword)..".")
			GR_Out.Print("AutoRecruit Message is: "..GR_Recruit.BuildMessage())
			GR_Out.Print("AutoRecruit Threshold set to "..GR_Color.Green(GR_Options.Recruit.Threshold))
			GR_Out.Print("AutoRecruit Interval set to: "..GR_Color.Green(GR_Options.Recruit.Interval).." Seconds")
		else
			GR_Out.Print("/grstatus full, for more information.")
		end
	end;

	ToggleAll = function(msg)
		local cmd = string.lower(msg)
	  local status = nil;

		if (cmd == "off") then
			status = GR_Color.Red("Off")
			GR_Options.Invite.Auto = 0;
			GR_Options.Recruit.Auto = 0;
			GR_Chronos.unscheduleRepeating()
		elseif (cmd == "on") then
			status = GR_Color.Green("On")
			GR_Options.Invite.Auto = 1;
			GR_Options.Recruit.Auto = 1;
			GR_Chronos.scheduleRepeating()
		elseif (cmd == "" or cmd == "help") then
			GR_Out.Print("/grtoggleall On|Off")
			GR_Out.Print("Example: /grtoggleall Off")
		end

		if (cmd ~= "" and cmd ~= "help") then
			GR_Out.Print("AutoInvite and AutoRecruit "..status)
		end

	end;

	Invite = {

		Auto = function()
		  local status = nil;

			if (GR_Options.Invite.Auto == 1) then
				status = GR_Color.Red("Off")
				GR_Options.Invite.Auto = 0;
			else
				status = GR_Color.Green("On")
				GR_Options.Invite.Auto = 1;
			end

			GR_Out.Print("AutoInvite: "..status)
		end;

    Message = function()
		  local status = nil;

			if (GR_Options.Invite.Message == 1) then
				status = GR_Color.Red("Off")
				GR_Options.Invite.Message = 0;
			else
				status = GR_Color.Green("On")
				GR_Options.Invite.Message = 1;
			end

			GR_Out.Print("AutoInvite Keyword in public Message: "..status)
		end;

		Keyword = function(msg)
			local cmd = string.lower(msg)

			if (cmd == "" or cmd == "help") then
				GR_Out.Print("/grkeyword default|Keyword, change the AutoInvite Keyword.")
				GR_Out.Print("Example: /grkeyword bewbs")
			elseif (cmd == "default") then
				GR_Options.Invite.Keyword = GR_Options.Default.Invite.Keyword;
			else
				GR_Options.Default.Invite.Keyword = GR_Options.Invite.Keyword;
				GR_Options.Invite.Keyword = msg;
			end

      if (cmd ~= "" and cmd ~= "help") then
				GR_Out.Print("AutoInvite Keyword set to: "..GR_Options.Invite.Keyword)
      end

		end;

	};

	Recruit = {

		Auto = function()
		  local status = nil;

			if (GR_Options.Recruit.Auto == 1) then
				status = GR_Color.Red("Off")
				GR_Options.Recruit.Auto = 0;
				GR_Chronos.unscheduleRepeating()
			else
				status = GR_Color.Green("On")
				GR_Options.Recruit.Auto = 1;
				GR_Chronos.scheduleRepeating()
			end

			GR_Out.Print("AutoRecruit: "..status)
		end;

		Message = function(msg)
			local cmd = string.lower(msg)
			local msglen = string.len(msg)

			if (cmd == "" or cmd == "help") then
				GR_Out.Print("/grrmessage default|Message, change the AutoRecruit Message.")
				GR_Out.Print("Example: /grrmessage Join our guild!")
			elseif (cmd == "default") then
				GR_Options.Recruit.Message = GR_Options.Default.Recruit.Message;
			elseif (msglen > GR_Setting.MsgLength) then
				GR_Out.Print("Message to long, limit message length to "..GR_Color.Red(GR_Setting.MsgLength).." characters.")
			else
				GR_Options.Default.Recruit.Message = GR_Options.Recruit.Message;
				GR_Options.Recruit.Message = msg;
			end

      if (cmd ~= "" and cmd ~= "help" and msglen <= GR_Setting.MsgLength) then
				GR_Out.Print("AutoRecruit Message set to: "..GR_Options.Recruit.Message)
      end
		end;

		Threshold = function(msg)
			local cmd = string.lower(msg)

			if (cmd == "" or cmd == "help") then
				GR_Out.Print("/grrthreshold default|Number, change the AutoRecruit Threshold (How many people need to be online for the message to be sent)")
				GR_Out.Print("Example: /grrthreshold 12")
			elseif (cmd == "default") then
				GR_Options.Recruit.Threshold = GR_Options.Default.Recruit.Threshold;
				GR_Out.Print("AutoRecruit Threshold set to "..GR_Options.Recruit.Threshold)
			else
				GR_Options.Default.Recruit.Threshold = GR_Options.Recruit.Threshold;
				GR_Options.Recruit.Threshold = tonumber(msg);
			end

      if (cmd ~= "" and cmd ~= "help") then
				GR_Out.Print("AutoRecruit Threshold set to: "..GR_Options.Recruit.Threshold)
      end
		end;

		Interval = function(msg)
			local cmd = string.lower(msg)

			if (cmd == "" or cmd == "help") then
				GR_Out.Print("/grrinterval default|Number, change the AutoRecruit Interval (How often in seconds for the message to be sent)")
				GR_Out.Print("Example: /grrthreshold 900")
			elseif (cmd == "default") then
				GR_Options.Recruit.Interval = GR_Options.Default.Recruit.Interval;
			else
				GR_Options.Default.Recruit.Interval = GR_Options.Recruit.Interval;
				GR_Options.Recruit.Interval = tonumber(msg);
			end

      if (cmd ~= "" and cmd ~= "help") then
				GR_Out.Print("AutoRecruit Interval set to: "..GR_Options.Recruit.Interval)
      end
		end;

		GuildName = function(msg)
			local cmd = string.lower(msg)

			if (cmd == "" or cmd == "help") then
				GR_Out.Print("/grrguildname default|GuildName, change the AutoRecruit GuildName (Has to match your current GuildName)")
				GR_Out.Print("Example: /grrguildname Bewbs For Lyfe")
			elseif (cmd == "default") then
				GR_Options.Recruit.GuildName = GR_Options.Default.Recruit.GuildName;
			else
				GR_Options.Default.Recruit.GuildName = GR_Options.Recruit.GuildName;
				GR_Options.Recruit.GuildName = msg;
			end

			if (cmd ~= "" and cmd ~= "help") then
				GR_Out.Print("AutoRecruit GuildName set to: "..GR_Options.Recruit.GuildName)
			end
		end;

	};

	Version = function()
		local version = GR_Setting.Version.."."..tonumber(strsub(GR_Setting.Revision, 7, strlen(GR_Setting.Revision) - 2))
		GR_Out.Print("Version: "..GR_Color.Green(version))
	end;

}