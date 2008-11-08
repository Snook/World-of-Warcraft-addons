--------------------------------------------------------------------------
-- LevelSnap.lua
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
	Automatically snaps a screen shot when you level.

	-- Dependencies
	Chronos - Embedded
	Khaos - Optional

	-- Changes
	1.4.1	- Bugfix
	1.4.0	- Level Cap 80
	1.31	- Updated TOC for 2.4
	1.30	- Shows /played in screenshots
				- Removed hide ui option
	1.24	- Updated TOC for 2.1
	1.23	- Updated TOC for 2.0
	1.22	- Updated TOC for 1.12
	1.21	- Updated TOC for 1.11
	1.20	- Added the option to close open windows prior to screen shot
				- Added Localization support
	1.10	- Added Khaos support
	1.00	- Initial Release

  -- SVN info
	$Id: LevelSnap.lua 1088 2008-11-20 19:32:24Z ghryphen $
	$Rev: 1088 $
	$LastChangedBy: ghryphen $
	$Date: 2008-11-20 11:32:24 -0800 (Thu, 20 Nov 2008) $

]]--

LS_Setting = {
	Version = GetAddOnMetadata("LevelSnap", "Version");
	Revision = tonumber(strsub("$Rev: 1088 $", 7, strlen("$Rev: 1088 $") - 2));
}

LS_Options = {
	Active = 1;
	MinLevel = 1;
	MaxLevel = 80;
	CloseWindows = 1;
}

LS_On = {

	Load = function()

		LS_Register.RegisterEvent("PLAYER_LEVEL_UP")

		if (Khaos) then
			LS_Register.Khaos();
		else
			LS_Register.SlashCommands()
		end

	end;

	Event = function(event)

		if (event == "PLAYER_LEVEL_UP" and LS_Options.Active == 1) then
			if (arg1 >= LS_Options.MinLevel and arg1 <= LS_Options.MaxLevel) then
				if (LS_Options.CloseWindows == 1) then
					CloseAllWindows()
					RequestTimePlayed()
					LS_Function.TakeScreenshot()
				else
					RequestTimePlayed()
					LS_Function.TakeScreenshot()
				end
			end
		end

	end;

}

LS_Register = {

	RegisterEvent = function(event)
		this:RegisterEvent(event)
	end;

	SlashCommands = function()
		SLASH_LS_HELP1 = "/ls";
		SLASH_LS_HELP2 = "/levelsnap";
		SlashCmdList["LS_HELP"] = LS_Command;
	end;

	Khaos = function()
		local version = LS_Setting.Version.."."..LS_Setting.Revision

		local optionSet = {
			id = "LevelSnap";
			text = function() return LS_TITLE end;
			helptext = function() return LS_INFO end;
			difficulty = 1;
			default = true;
			callback = function(checked)
				LS_Options.Active = checked and 1 or 0;
			end;
			options = {
				{
					id = "Header";
					text = function() return LS_TITLE.." "..LS_Color.Green("v"..version) end;
					helptext = function() return LS_INFO end;
					type = K_HEADER;
					difficulty = 1;
				};

				{
					id="LS_MinLevel";
					type = K_SLIDER;
					text = function() return LS_MINIMUM end;
					helptext = function() return LS_HELP_MIN end;
					difficulty = 1;
					feedback = function(state)
						return string.format(LS_MINMAXSET2, LS_MINIMUM, state.slider);
					end;
					callback = function(state)
						if (state.slider >= LS_Options.MaxLevel) then
							Khaos.setSetKeyParameter("LevelSnap","LS_MaxLevel", "slider", state.slider);
							Khaos.refresh(false, false, true);
						end;
						LS_Options.MinLevel = state.slider;
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
					id="LS_MaxLevel";
					type = K_SLIDER;
					text = function() return LS_MAXIMUM end;
					helptext = function() return LS_HELP_MAX end;
					difficulty = 1;
					feedback = function(state)
						return string.format(LS_MINMAXSET2, LS_MAXIMUM, state.slider);
					end;
					callback = function(state)
						if (state.slider <= LS_Options.MinLevel) then
							Khaos.setSetKeyParameter("LevelSnap","LS_MinLevel", "slider", state.slider);
							Khaos.refresh(false, false, true);
						end;
						LS_Options.MaxLevel = state.slider;
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
					id = "LS_CloseWindows";
					type = K_TEXT;
					text = function() return LS_CLOSEWIN end;
					helptext = function() return LS_HELP_CLOSEWIN end;
					difficulty = 1;
					feedback = function(state)
						if (state.checked) then
							return string.format(LS_CLOSEALL, LS_ENABLED);
						else
							return string.format(LS_CLOSEALL, LS_DISABLED);
						end
					end;
					callback = function(state)
						if (state.checked) then
							LS_Options.CloseWindows = 1;
						else
							LS_Options.CloseWindows = 0;
						end
					end;
					check = true;
					default = { checked = true };
					disabled = { checked = true };
				};

				{
					id = "LS_Status";
					type = K_BUTTON;
					text = function() return LS_STATUS end;
					helptext = function() return LS_HELP_STATUS end;
					difficulty = 1;
					callback = function(state)
						LS_Out.Status()
					end;
					feedback = function(state) end;
					setup = { buttonText = function() return LS_STATUS end; };
				};

			};
		};
		Khaos.registerOptionSet(
			"other",
			optionSet
		);

	end;

}

LS_Function = {

	TakeScreenshot = function()
		Chronos.schedule(1, TakeScreenshot)
	end;

}

LS_Out = {

	Print = function(msg)
		local color = NORMAL_FONT_COLOR;
		DEFAULT_CHAT_FRAME:AddMessage(LS_TITLE..": "..msg, color.r, color.g, color.b)
	end;

  Status = function()
		local active = LS_Color.Green(LS_ENABLED)
		local closeall = LS_Color.Green(LS_ENABLED)

		if (LS_Options.Active == 0) then
			active = LS_Color.Red(LS_DISABLED)
		end
		if (LS_Options.CloseWindows == 0) then
			closeall = LS_Color.Red(LS_DISABLED)
		end

		LS_Out.Print("AddOn "..active..". "..string.format(LS_MINMAXSET2, LS_MINIMUM, LS_Color.Green(LS_Options.MinLevel)).." "..string.format(LS_MINMAXSET2, LS_MAXIMUM, LS_Color.Green(LS_Options.MaxLevel)).." "..string.format(LS_CLOSEALL, closeall))
  end;

  Version = function()
		local version = LS_Setting.Version.."."..LS_Setting.Revision
		LS_Out.Print(LS_VERSION..": "..LS_Color.Green(version))
  end;

}

LS_Color = {

	Green = function(msg)
		return "|cff00cc00"..msg.."|r";
	end;

	Red = function(msg)
		return "|cffff0000"..msg.."|r";
	end;

}

LS_Command = function(msg)

	local cmd = string.lower(msg)

	if (cmd == "" or cmd == "help") then
		LS_Out.Print("/ls on|off, "..LS_HELP_ONOFF)
		LS_Out.Print("/ls min #, "..LS_HELP_MIN)
		LS_Out.Print("/ls max #, "..LS_HELP_MAX)
		LS_Out.Print("/ls closewin on|off, "..LS_HELP_CLOSEWIN)
		LS_Out.Print("/ls ui on|off, "..LS_HELP_UI)
		LS_Out.Print("/ls status, "..LS_HELP_STATUS)
		LS_Out.Print("/ls version, "..LS_HELP_VERSION)
	end

	if (cmd == "version") then
		LS_Out.Version()
	end

	if (cmd == "status") then
		LS_Out.Status()
	end

	if (cmd == "on") then
		LS_Options.Active = 1;
		LS_Out.Print(LS_Color.Green(LS_ENABLED))
	end

	if (cmd == "off") then
		LS_Options.Active = 0;
		LS_Out.Print(LS_Color.Red(LS_DISABLED))
	end

	if (strsub(msg, 1, 3) == "min") then
		local num = tonumber(strsub(msg, 4))
		LS_Options.MinLevel = num;
		LS_Out.Print(string.format(LS_MINMAXSET2, LS_MINIMUM, LS_Color.Green(num)))
	end

	if (strsub(msg, 1, 3) == "max") then
		local num = tonumber(strsub(msg, 4))
		LS_Options.MaxLevel = num;
		LS_Out.Print(string.format(LS_MINMAXSET2, LS_MAXIMUM, LS_Color.Green(num)))
	end

	if (strsub(msg, 1, 8) == "closewin") then
		local state = strsub(msg, 10)
		if (state == "on") then
			LS_Options.CloseWindows = 1;
			LS_Out.Print(string.format(LS_CLOSEALL, LS_ENABLED))
		elseif (state == "off") then
			LS_Options.CloseWindows = 0;
			LS_Out.Print(string.format(LS_CLOSEALL, LS_DISABLED))
		end
	end

end;