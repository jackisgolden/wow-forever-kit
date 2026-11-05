-- Forever Kit defaults for everyone. Edit, push, and each player gets the
-- change the next time they run Install.bat and log in.
--
-- binds: key = action. Key names: A, SHIFT-1, CTRL-F, ALT-Q, BUTTON4, BUTTON5,
-- MOUSEWHEELUP. Set a key to false to unbind it.
-- cvars: game settings. cameraFov tops out at 90.

ForeverKitConfig = {
	binds = {
		A = "STRAFELEFT", D = "STRAFERIGHT",
		["1"] = "ACTIONBUTTON1", ["2"] = "ACTIONBUTTON2", ["3"] = "ACTIONBUTTON3",
		["4"] = "ACTIONBUTTON4", ["5"] = "ACTIONBUTTON5", ["6"] = "ACTIONBUTTON6",
		Q = "ACTIONBUTTON7", E = "ACTIONBUTTON8", R = "ACTIONBUTTON9",
		F = "ACTIONBUTTON10", C = "ACTIONBUTTON11", V = "ACTIONBUTTON12",
		G = "MULTIACTIONBAR1BUTTON1", Z = "MULTIACTIONBAR1BUTTON2", X = "MULTIACTIONBAR1BUTTON3",
		Y = "MULTIACTIONBAR1BUTTON4", H = "MULTIACTIONBAR1BUTTON5", ["`"] = "MULTIACTIONBAR1BUTTON6",
		["SHIFT-1"] = "MULTIACTIONBAR1BUTTON7", ["SHIFT-2"] = "MULTIACTIONBAR1BUTTON8",
		["SHIFT-3"] = "MULTIACTIONBAR1BUTTON9", ["SHIFT-4"] = "MULTIACTIONBAR1BUTTON10",
		["SHIFT-5"] = "MULTIACTIONBAR1BUTTON11", ["SHIFT-6"] = "MULTIACTIONBAR1BUTTON12",
		T = "INTERACTTARGET", ["SHIFT-C"] = "TOGGLECHARACTER0", ["SHIFT-R"] = "REPLY",
	},
	cvars = {
		cameraSmoothStyle = 0,
		cameraFov = 90,
	},
}
