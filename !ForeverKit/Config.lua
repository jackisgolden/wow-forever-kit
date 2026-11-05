-- Forever Kit defaults for everyone. Edit, push, and each player gets the
-- change the next time they run Install.bat and log in.
--
-- binds: key = action. Only keys the game leaves free, so default binds keep
-- working. The top bar uses the default 1 to 0, - and =. Key names: A, SHIFT-1, CTRL-F, ALT-Q, BUTTON4, BUTTON5,
-- MOUSEWHEELUP. Set a key to false to unbind it.
-- cvars: game settings. cameraFov tops out at 90.

ForeverKitConfig = {
	binds = {
		["ALT-1"] = "MULTIACTIONBAR1BUTTON1", ["ALT-2"] = "MULTIACTIONBAR1BUTTON2",
		["ALT-3"] = "MULTIACTIONBAR1BUTTON3", ["ALT-4"] = "MULTIACTIONBAR1BUTTON4",
		["ALT-5"] = "MULTIACTIONBAR1BUTTON5", ["ALT-6"] = "MULTIACTIONBAR1BUTTON6",
		["ALT-7"] = "MULTIACTIONBAR1BUTTON7", ["ALT-8"] = "MULTIACTIONBAR1BUTTON8",
		["ALT-9"] = "MULTIACTIONBAR1BUTTON9", ["ALT-0"] = "MULTIACTIONBAR1BUTTON10",
		["ALT--"] = "MULTIACTIONBAR1BUTTON11", ["ALT-="] = "MULTIACTIONBAR1BUTTON12",
	},
	cvars = {
		cameraSmoothStyle = 0,
		cameraFov = 90,
	},
}
