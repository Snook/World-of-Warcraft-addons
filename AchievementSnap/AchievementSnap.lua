--------------------------------------------------------------------------
-- AchievementSnap.lua
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
	Automatically snaps a screen shot when you gain an achievement.

	-- Dependencies
	Chronos - Embedded
	Khaos - Optional

	-- Changes
	1.0.0	- Initial Release

	-- SVN info
	$Id: AchievementSnap.lua 1088 2008-11-20 19:32:24Z ghryphen $
	$Rev: 1088 $
	$LastChangedBy: ghryphen $
	$Date: 2008-11-20 11:32:24 -0800 (Thu, 20 Nov 2008) $

]]--

ASNAP_Setting = {
	Version = GetAddOnMetadata("AchievementSnap", "Version");
	Revision = tonumber(strsub("$Rev: 1088 $", 7, strlen("$Rev: 1088 $") - 2));
}

ASNAP_Options = {
	Active = 1;
	MinLevel = 1;
	MaxLevel = 80;
}

ASNAP_On = {

	Load = function()

		ASNAP_Register.RegisterEvent("ACHIEVEMENT_EARNED")

		if (Khaos) then
			ASNAP_Register.Khaos();
		else
			ASNAP_Register.SlashCommands()
		end

	end;

	Event = function(event)

		if ( event == "ACHIEVEMENT_EARNED" and ASNAP_Options.Active == 1 ) then
			if (UnitLevel("player") >= ASNAP_Options.MinLevel and UnitLevel("player") <= ASNAP_Options.MaxLevel) then
				if (ASNAP_Options.CloseWindows == 1) then
					CloseAllWindows()
					RequestTimePlayed()
					ASNAP_Function.TakeScreenshot()
				else
					RequestTimePlayed()
					ASNAP_Function.TakeScreenshot()
				end
			end
		end

	end;

}

ASNAP_Register = {

	RegisterEvent = function(event)
		this:RegisterEvent(event)
	end;

	SlashCommands = function()
		SLASH_ASNAP_HELP1 = "/asnap";
		SLASH_ASNAP_HELP2 = "/achievementsnap";
		SlashCmdList["ASNAP_HELP"] = ASNAP_Command;
	end;

	Khaos = function()
		local version = ASNAP_Setting.Version.."."..ASNAP_Setting.Revision

		local optionSet = {
			id = "AchievementSnap";
			text = function() return ASNAP_TITLE end;
			helptext = function() return ASNAP_INFO end;
			difficulty = 1;
			default = true;
			callback = function(checked)
				ASNAP_Options.Active = checked and 1 or 0;
			end;
			options = {
				{
					id = "Header";
					text = function() return ASNAP_TITLE.." "..ASNAP_Color.Green("v"..version) end;
					helptext = function() return ASNAP_INFO end;
					type = K_HEADER;
					difficulty = 1;
				};

				{
					id="ASNAP_MinLevel";
					type = K_SLIDER;
					text = function() return ASNAP_MINIMUM end;
					helptext = function() return ASNAP_HELP_MIN end;
					difficulty = 1;
					feedback = function(state)
						return string.format(ASNAP_MINMAXSET2, ASNAP_MINIMUM, state.slider);
					end;
					callback = function(state)
						if (state.slider >= ASNAP_Options.MaxLevel) then
							Khaos.setSetKeyParameter("AchievementSnap","ASNAP_MaxLevel", "slider", state.slider);
							Khaos.refresh(false, false, true);
						end;
						ASNAP_Options.MinLevel = state.slider;
					end;
					default = { checked = true; slider = 1 };
					disabled = { checked = false; slider = 1 };
					setup = {
						sliderMin = 1;
						sliderMax = 80;
						sliderStep = 1;
						sliderDisplayFunc = function(val)
							return val;
						end;
					};
				};


				{
					id="ASNAP_MaxLevel";
					type = K_SLIDER;
					text = function() return ASNAP_MAXIMUM end;
					helptext = function() return ASNAP_HELP_MAX end;
					difficulty = 1;
					feedback = function(state)
						return string.format(ASNAP_MINMAXSET2, ASNAP_MAXIMUM, state.slider);
					end;
					callback = function(state)
						if (state.slider <= ASNAP_Options.MinLevel) then
							Khaos.setSetKeyParameter("AchievementSnap","ASNAP_MinLevel", "slider", state.slider);
							Khaos.refresh(false, false, true);
						end;
						ASNAP_Options.MaxLevel = state.slider;
					end;
					default = { checked = false; slider = 80 };
					disabled = { checked = false; slider = 80 };
					setup = {
						sliderMin = 1;
						sliderMax = 80;
						sliderStep = 1;
						sliderDisplayFunc = function(val)
							return val;
						end;
					};
				};
				
				{
					id = "ASNAP_CloseWindows";
					type = K_TEXT;
					text = function() return ASNAP_CLOSEWIN end;
					helptext = function() return ASNAP_HELP_CLOSEWIN end;
					difficulty = 1;
					feedback = function(state)
						if (state.checked) then
							return string.format(ASNAP_CLOSEALL, ASNAP_ENABLED);
						else
							return string.format(ASNAP_CLOSEALL, ASNAP_DISABLED);
						end
					end;
					callback = function(state)
						if (state.checked) then
							ASNAP_Options.CloseWindows = 1;
						else
							ASNAP_Options.CloseWindows = 0;
						end
					end;
					check = true;
					default = { checked = false };
					disabled = { checked = true };
				};

				{
					id = "ASNAP_Status";
					type = K_BUTTON;
					text = function() return ASNAP_STATUS end;
					helptext = function() return ASNAP_HELP_STATUS end;
					difficulty = 1;
					callback = function(state)
						ASNAP_Out.Status()
					end;
					feedback = function(state) end;
					setup = { buttonText = function() return ASNAP_STATUS end; };
				};

			};
		};
		Khaos.registerOptionSet(
			"other",
			optionSet
		);

	end;

}

ASNAP_Function = {

	TakeScreenshot = function()
		Chronos.schedule(1, TakeScreenshot)
	end;

}

ASNAP_Out = {

	Print = function(msg)
		local color = NORMAL_FONT_COLOR;
		DEFAULT_CHAT_FRAME:AddMessage(ASNAP_TITLE..": "..msg, color.r, color.g, color.b)
	end;

	Status = function()
		local active = ASNAP_Color.Green(ASNAP_ENABLED)
		local closeall = ASNAP_Color.Green(ASNAP_ENABLED)

		if (ASNAP_Options.Active == 0) then
			active = ASNAP_Color.Red(ASNAP_DISABLED)
		end
		if (ASNAP_Options.CloseWindows == 0) then
			closeall = ASNAP_Color.Red(ASNAP_DISABLED)
		end

		ASNAP_Out.Print("AddOn "..active..". "..string.format(ASNAP_MINMAXSET2, ASNAP_MINIMUM, ASNAP_Color.Green(ASNAP_Options.MinLevel)).." "..string.format(ASNAP_MINMAXSET2, ASNAP_MAXIMUM, ASNAP_Color.Green(ASNAP_Options.MaxLevel)).." "..string.format(ASNAP_CLOSEALL, closeall))
	end;

	Version = function()
		local version = ASNAP_Setting.Version.."."..ASNAP_Setting.Revision
		ASNAP_Out.Print(ASNAP_VERSION..": "..ASNAP_Color.Green(version))
	end;

}

ASNAP_Color = {

	Green = function(msg)
		return "|cff00cc00"..msg.."|r";
	end;

	Red = function(msg)
		return "|cffff0000"..msg.."|r";
	end;

}

ASNAP_Command = function(msg)

	local cmd = string.lower(msg)

	if (cmd == "" or cmd == "help") then
		ASNAP_Out.Print("/asnap on|off, "..ASNAP_HELP_ONOFF)
		ASNAP_Out.Print("/asnap min #, "..ASNAP_HELP_MIN)
		ASNAP_Out.Print("/asnap max #, "..ASNAP_HELP_MAX)
		ASNAP_Out.Print("/asnap closewin on|off, "..DS_HELP_CLOSEWIN)
		ASNAP_Out.Print("/asnap status, "..ASNAP_HELP_STATUS)
		ASNAP_Out.Print("/asnap version, "..ASNAP_HELP_VERSION)
	end

	if (cmd == "version") then
		ASNAP_Out.Version()
	end

	if (cmd == "status") then
		ASNAP_Out.Status()
	end

	if (cmd == "on") then
		ASNAP_Options.Active = 1;
		ASNAP_Out.Print(ASNAP_Color.Green(ASNAP_ENABLED))
	end

	if (cmd == "off") then
		ASNAP_Options.Active = 0;
		ASNAP_Out.Print(ASNAP_Color.Red(ASNAP_DISABLED))
	end

	if (strsub(msg, 1, 3) == "min") then
		local num = tonumber(strsub(msg, 4))
		ASNAP_Options.MinLevel = num;
		ASNAP_Out.Print(string.format(ASNAP_MINMAXSET2, ASNAP_MINIMUM, ASNAP_Color.Green(num)))
	end

	if (strsub(msg, 1, 3) == "max") then
		local num = tonumber(strsub(msg, 4))
		ASNAP_Options.MaxLevel = num;
		ASNAP_Out.Print(string.format(ASNAP_MINMAXSET2, ASNAP_MAXIMUM, ASNAP_Color.Green(num)))
	end

	if (strsub(msg, 1, 8) == "closewin") then
		local state = strsub(msg, 10)
		if (state == "on") then
			ASNAP_Options.CloseWindows = 1;
			ASNAP_Out.Print(string.format(ASNAP_CLOSEALL, ASNAP_ENABLED))
		elseif (state == "off") then
			ASNAP_Options.CloseWindows = 0;
			ASNAP_Out.Print(string.format(ASNAP_CLOSEALL, ASNAP_DISABLED))
		end
	end
end;