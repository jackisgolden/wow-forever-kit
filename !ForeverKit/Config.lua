-- Forever Kit defaults for everyone. Edit, push, and each player gets the
-- change the next time they run Install.bat and log in.
--
-- binds: key = action. Only keys the game leaves free, so default binds keep
-- working. The bottom row uses the default 1 to 0, - and =. Key names: A, SHIFT-1, CTRL-F, ALT-Q, BUTTON4, BUTTON5,
-- MOUSEWHEELUP. Set a key to false to unbind it.
-- cvars: game settings. cameraFov tops out at 90.
-- leatrix: Leatrix Plus options, set once per character.
-- macros: { name = "Heal", key = "SHIFT-2", bind = "BUTTON3", body = "..." }. A
-- macro lands on the button a key presses, a bind goes straight on a key, and
-- each takes either. Macros belong to one character.
-- spells: key = spell name, placed on the button that key presses.

ForeverKitConfig = {
	binds = {
		-- Row 2
		["ALT-1"] = "MULTIACTIONBAR1BUTTON1", ["ALT-2"] = "MULTIACTIONBAR1BUTTON2",
		["ALT-3"] = "MULTIACTIONBAR1BUTTON3", ["ALT-4"] = "MULTIACTIONBAR1BUTTON4",
		["ALT-5"] = "MULTIACTIONBAR1BUTTON5", ["ALT-6"] = "MULTIACTIONBAR1BUTTON6",
		["ALT-7"] = "MULTIACTIONBAR1BUTTON7", ["ALT-8"] = "MULTIACTIONBAR1BUTTON8",
		["ALT-9"] = "MULTIACTIONBAR1BUTTON9", ["ALT-0"] = "MULTIACTIONBAR1BUTTON10",
		["ALT--"] = "MULTIACTIONBAR1BUTTON11", ["ALT-="] = "MULTIACTIONBAR1BUTTON12",
		-- Row 3
		["CTRL-SHIFT-1"] = "MULTIACTIONBAR2BUTTON1", ["CTRL-SHIFT-2"] = "MULTIACTIONBAR2BUTTON2",
		["CTRL-SHIFT-3"] = "MULTIACTIONBAR2BUTTON3", ["CTRL-SHIFT-4"] = "MULTIACTIONBAR2BUTTON4",
		["CTRL-SHIFT-5"] = "MULTIACTIONBAR2BUTTON5", ["CTRL-SHIFT-6"] = "MULTIACTIONBAR2BUTTON6",
		["CTRL-SHIFT-7"] = "MULTIACTIONBAR2BUTTON7", ["CTRL-SHIFT-8"] = "MULTIACTIONBAR2BUTTON8",
		["CTRL-SHIFT-9"] = "MULTIACTIONBAR2BUTTON9", ["CTRL-SHIFT-0"] = "MULTIACTIONBAR2BUTTON10",
		["CTRL-SHIFT--"] = "MULTIACTIONBAR2BUTTON11", ["CTRL-SHIFT-="] = "MULTIACTIONBAR2BUTTON12",
		-- Utility bar
		["ALT-Q"] = "MULTIACTIONBAR4BUTTON1", ["ALT-E"] = "MULTIACTIONBAR4BUTTON2",
		["ALT-R"] = "MULTIACTIONBAR4BUTTON3", ["ALT-F"] = "MULTIACTIONBAR4BUTTON4",
		["ALT-C"] = "MULTIACTIONBAR4BUTTON5", ["ALT-V"] = "MULTIACTIONBAR4BUTTON6",
	},
	cvars = {
		cameraSmoothStyle = 0,
		cameraFov = 90,
		nameplateShowEnemies = 1,
	},
	leatrix = {
		AutoRepairGear = "On",
	},
	macros = {},
	spells = {},
}
