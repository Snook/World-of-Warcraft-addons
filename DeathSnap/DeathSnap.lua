--------------------------------------------------------------------------
-- DeathSnap.lua
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
	Automatically snaps a screen shot when you die.

	-- Dependencies
	Chronos - Embedded
	Khaos - Optional

	-- Changes
	1.0.1	- Level Cap 80
	1.0.0	- Initial Release

	-- SVN info
	$Id: DeathSnap.lua 1088 2008-11-20 19:32:24Z ghryphen $
	$Rev: 1088 $
	$LastChangedBy: ghryphen $
	$Date: 2008-11-20 11:32:24 -0800 (Thu, 20 Nov 2008) $

]]--

DS_Setting = {
	Version = GetAddOnMetadata("DeathSnap", "Version");
	Revision = tonumber(strsub("$Rev: 1088 $", 7, strlen("$Rev: 1088 $") - 2));
}

DS_Options = {
	Active = 1;
	MinLevel = 1;
	MaxLevel = 80;
	CloseWindows = 0;
}

DS_On = {

	Load = function()

		DS_Register.RegisterEvent("UNIT_DIED")
		DS_Register.RegisterEvent("PLAYER_DEAD")

		if (Khaos) then
			DS_Register.Khaos();
		else
			DS_Register.SlashCommands()
		end

	end;

	Event = function(event)

		if ( ( event == "UNIT_DIED" or event == "PLAYER_DEAD" ) and DS_Options.Active == 1 ) then
			if (UnitLevel("player") >= DS_Options.MinLevel and UnitLevel("player") <= DS_Options.MaxLevel) then
				if (DS_Options.CloseWindows == 1) then
					CloseAllWindows()
					RequestTimePlayed()
					DS_Function.TakeScreenshot()
				else
					RequestTimePlayed()
					DS_Function.TakeScreenshot()
				end
			end
		end

	end;

}

DS_Register = {

	RegisterEvent = function(event)
		this:RegisterEvent(event)
	end;

	SlashCommands = function()
		SLASH_DS_HELP1 = "/ds";
		SLASH_DS_HELP2 = "/deathsnap";
		SlashCmdList["DS_HELP"] = DS_Command;
	end;

	Khaos = function()
		local version = DS_Setting.Version.."."..DS_Setting.Revision

		local optionSet = {
			id = "DeathSnap";
			text = function() return DS_TITLE end;
			helptext = function() return DS_INFO end;
			difficulty = 1;
			default = true;
			callback = function(checked)
				DS_Options.Active = checked and 1 or 0;
			end;
			options = {
				{
					id = "Header";
					text = function() return DS_TITLE.." "..DS_Color.Green("v"..version) end;
					helptext = function() return DS_INFO end;
					type = K_HEADER;
					difficulty = 1;
				};

				{
					id="DS_MinLevel";
					type = K_SLIDER;
					text = function() return DS_MINIMUM end;
					helptext = function() return DS_HELP_MIN end;
					difficulty = 1;
					feedback = function(state)
						return string.format(DS_MINMAXSET2, DS_MINIMUM, state.slider);
					end;
					callback = function(state)
						if (state.slider >= DS_Options.MaxLevel) then
							Khaos.setSetKeyParameter("DeathSnap","DS_MaxLevel", "slider", state.slider);
							Khaos.refresh(false, false, true);
						end;
						DS_Options.MinLevel = state.slider;
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
					id="DS_MaxLevel";
					type = K_SLIDER;
					text = function() return DS_MAXIMUM end;
					helptext = function() return DS_HELP_MAX end;
					difficulty = 1;
					feedback = function(state)
						return string.format(DS_MINMAXSET2, DS_MAXIMUM, state.slider);
					end;
					callback = function(state)
						if (state.slider <= DS_Options.MinLevel) then
							Khaos.setSetKeyParameter("DeathSnap","DS_MinLevel", "slider", state.slider);
							Khaos.refresh(false, false, true);
						end;
						DS_Options.MaxLevel = state.slider;
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
					id = "DS_CloseWindows";
					type = K_TEXT;
					text = function() return DS_CLOSEWIN end;
					helptext = function() return DS_HELP_CLOSEWIN end;
					difficulty = 1;
					feedback = function(state)
						if (state.checked) then
							return string.format(DS_CLOSEALL, DS_ENABLED);
						else
							return string.format(DS_CLOSEALL, DS_DISABLED);
						end
					end;
					callback = function(state)
						if (state.checked) then
							DS_Options.CloseWindows = 1;
						else
							DS_Options.CloseWindows = 0;
						end
					end;
					check = true;
					default = { checked = false };
					disabled = { checked = true };
				};

				{
					id = "DS_Status";
					type = K_BUTTON;
					text = function() return DS_STATUS end;
					helptext = function() return DS_HELP_STATUS end;
					difficulty = 1;
					callback = function(state)
						DS_Out.Status()
					end;
					feedback = function(state) end;
					setup = { buttonText = function() return DS_STATUS end; };
				};

			};
		};
		Khaos.registerOptionSet(
			"other",
			optionSet
		);

	end;

}

DS_Function = {

	TakeScreenshot = function()
		Chronos.schedule(1, TakeScreenshot)
	end;

}

DS_Out = {

	Print = function(msg)
		local color = NORMAL_FONT_COLOR;
		DEFAULT_CHAT_FRAME:AddMessage(DS_TITLE..": "..msg, color.r, color.g, color.b)
	end;

	Status = function()
		local active = DS_Color.Green(DS_ENABLED)
		local closeall = DS_Color.Green(DS_ENABLED)

		if (DS_Options.Active == 0) then
			active = DS_Color.Red(DS_DISABLED)
		end
		if (DS_Options.CloseWindows == 0) then
			closeall = DS_Color.Red(DS_DISABLED)
		end

		DS_Out.Print("AddOn "..active..". "..string.format(DS_MINMAXSET2, DS_MINIMUM, DS_Color.Green(DS_Options.MinLevel)).." "..string.format(DS_MINMAXSET2, DS_MAXIMUM, DS_Color.Green(DS_Options.MaxLevel)).." "..string.format(DS_CLOSEALL, closeall))
	end;

	Version = function()
		local version = DS_Setting.Version.."."..DS_Setting.Revision
		DS_Out.Print(DS_VERSION..": "..DS_Color.Green(version))
	end;

}

DS_Color = {

	Green = function(msg)
		return "|cff00cc00"..msg.."|r";
	end;

	Red = function(msg)
		return "|cffff0000"..msg.."|r";
	end;

}

DS_Command = function(msg)

	local cmd = string.lower(msg)

	if (cmd == "" or cmd == "help") then
		DS_Out.Print("/ds on|off, "..DS_HELP_ONOFF)
		DS_Out.Print("/ds min #, "..DS_HELP_MIN)
		DS_Out.Print("/ds max #, "..DS_HELP_MAX)
		DS_Out.Print("/ds closewin on|off, "..DS_HELP_CLOSEWIN)
		DS_Out.Print("/ds status, "..DS_HELP_STATUS)
		DS_Out.Print("/ds version, "..DS_HELP_VERSION)
	end

	if (cmd == "version") then
		DS_Out.Version()
	end

	if (cmd == "status") then
		DS_Out.Status()
	end

	if (cmd == "on") then
		DS_Options.Active = 1;
		DS_Out.Print(DS_Color.Green(DS_ENABLED))
	end

	if (cmd == "off") then
		DS_Options.Active = 0;
		DS_Out.Print(DS_Color.Red(DS_DISABLED))
	end

	if (strsub(msg, 1, 3) == "min") then
		local num = tonumber(strsub(msg, 4))
		DS_Options.MinLevel = num;
		DS_Out.Print(string.format(DS_MINMAXSET2, DS_MINIMUM, DS_Color.Green(num)))
	end

	if (strsub(msg, 1, 3) == "max") then
		local num = tonumber(strsub(msg, 4))
		DS_Options.MaxLevel = num;
		DS_Out.Print(string.format(DS_MINMAXSET2, DS_MAXIMUM, DS_Color.Green(num)))
	end

	if (strsub(msg, 1, 8) == "closewin") then
		local state = strsub(msg, 10)
		if (state == "on") then
			DS_Options.CloseWindows = 1;
			DS_Out.Print(string.format(DS_CLOSEALL, DS_ENABLED))
		elseif (state == "off") then
			DS_Options.CloseWindows = 0;
			DS_Out.Print(string.format(DS_CLOSEALL, DS_DISABLED))
		end
	end

end;