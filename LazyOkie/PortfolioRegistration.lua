--------------------------------------------------
-- $LastChangedBy: $
-- $Date: $

if (not LazyOkie) then
	LazyOkie = {}
end

local Portfolio = LibStub and LibStub("Portfolio")
if not Portfolio then return end

local optionTable = {
	id = "LazyOkie";
	options = {
		{
			id = "Enabled",
			text = LZYOK_ENABLED,
			tooltipText = LZYOK_HELP_ENABLED,
			type = CONTROLTYPE_CHECKBOX,
			defaultValue = 1,
		},
	},
	savedVarTable = "LazyOkie_SavedVars",
}

Portfolio.RegisterOptionSet(optionTable)