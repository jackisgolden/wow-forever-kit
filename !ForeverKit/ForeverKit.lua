-- Forever Kit. The ! in the folder name loads this before other addons, so a
-- character's layout is in place before Bartender4, SexyMap, Questie, and
-- RestedXP read their settings.
--
-- Layout.lua is applied once per character, and /forever applies it again.
-- Config.lua and Personal.lua hold binds, game settings, macros, and spell
-- placement, which apply at login whenever they change. Leatrix Plus options
-- and EllesmereUI frames apply once per character, each on its own version.

local Layout = ForeverKitLayout

local function ensure(parent, key)
	if type(parent[key]) ~= "table" then parent[key] = {} end
	return parent[key]
end

local function characterKey(separator)
	local name, surname = UnitNameUnmodified("player")
	if surname then
		return name .. " " .. surname
	end
	return name .. separator .. GetRealmName()
end

local function barConfig(spec)
	local config = {
		version = 3, WoW10Layout = true, rows = spec.rows, padding = 2, showgrid = true,
		position = { point = spec.point or "BOTTOM", x = spec.x, y = spec.y },
	}
	config.fadeout = spec.fadeout
	config.fadeoutalpha = spec.fadeoutalpha
	return config
end

local function seedBartender()
	Bartender4DB = Bartender4DB or {}
	local db, spec, name = Bartender4DB, Layout.bartender, Layout.profile
	ensure(db, "profileKeys")[characterKey(" - ")] = name
	ensure(db, "profiles")[name] = { blizzardVehicle = true, focuscastmodifier = false, outofrange = "hotkey" }

	local namespaces = ensure(db, "namespaces")
	local function put(namespace, data)
		ensure(ensure(namespaces, namespace), "profiles")[name] = data
	end

	local bars = {}
	for _, id in ipairs({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 14, 15 }) do
		bars[id] = { WoW10Layout = true }
	end
	for _, id in ipairs(spec.disabledBars) do
		bars[id] = { version = 3, WoW10Layout = true, enabled = false }
	end
	for id, barSpec in pairs(spec.bars) do
		bars[id] = barConfig(barSpec)
	end
	put("ActionBars", { actionbars = bars })

	for _, module in ipairs(spec.hidden) do
		put(module, { version = 3, enabled = false })
	end
	for module, position in pairs(spec.placed) do
		put(module, { version = 3, position = { point = "BOTTOM", x = position.x, y = position.y } })
	end
end

local function seedSexyMap()
	if type(SexyMap2DB) ~= "table" then SexyMap2DB = {} end
	local spec = Layout.sexymap
	local profile = ensure(SexyMap2DB, characterKey("-"))
	profile.core = {
		lock = true, clamp = true, rightClickToConfig = true, autoZoom = 0, northTag = false,
		shape = spec.shape, scale = spec.scale,
		point = "TOPRIGHT", relpoint = "TOPRIGHT", x = spec.x, y = spec.y,
	}
	profile.coordinates = {
		enabled = false, xOffset = 0, yOffset = 10, updateRate = 1, monochrome = false,
		font = "Friz Quadrata TT", outline = "NONE", coordPrecision = "%d,%d",
		fontColor = {}, borderColor = {}, backgroundColor = {},
	}
	profile.buttons = {
		radius = spec.iconRadius, scale = spec.iconScale,
		lockDragging = false, allowDragging = true, controlVisibility = true,
		dragPositions = {},
		visibilitySettings = {
			MinimapZoomIn = "never", MinimapZoomOut = "never", MiniMapWorldMapButton = "never",
			AddonCompartmentFrame = "never", MiniMapMailFrame = "always",
			DayNight = "hover", ExpansionLandingPageMinimapButton = "hover", CraftingOrder = "hover",
			TimeManagerClockButton = "hover", SexyMapZoneTextButton = "hover",
		},
	}
	profile.borders = {
		applyPreset = false, borders = {}, hideBlizzard = true,
		backdrop = {
			show = false, textureColor = {}, borderColor = {}, scale = 0.5,
			settings = {
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = false, edgeSize = 16,
				insets = { top = 4, right = 4, left = 4, bottom = 4 },
			},
		},
	}
end

local function seedQuestie()
	QuestieConfig = QuestieConfig or {}
	ensure(ensure(QuestieConfig, "profiles"), "Default").TrackerLocation = Layout.questie
end

local function seedRestedXP()
	RXPSettings = RXPSettings or {}
	local key = characterKey(" - ")
	ensure(RXPSettings, "profileKeys")[key] = key
	local profile = ensure(ensure(RXPSettings, "profiles"), key)
	local positions = ensure(profile, "framePositions")
	for frameName, anchor in pairs(Layout.restedxp) do
		positions[frameName] = { anchor }
	end
end

local function seedLeatrix()
	LeaPlusDB = LeaPlusDB or {}
	for option, value in pairs(ForeverKitConfig.leatrix) do
		LeaPlusDB[option] = value
	end
end

-- EllesmereUI fills missing keys from its defaults, so a partial profile keeps
-- every other setting. Its store is profiles[active].addons[folder].
local function frameProfile(store, folder)
	local active = store.activeProfile or "Default"
	return ensure(ensure(ensure(ensure(store, "profiles"), active), "addons"), folder)
end

local function merge(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" then
			merge(ensure(target, key), value)
		else
			target[key] = value
		end
	end
end

local function seedUnitFrames()
	EllesmereUIDB = EllesmereUIDB or {}
	EllesmereUIDB.firstInstallPopupShown = true
	local spec = Layout.frames
	local profile = frameProfile(EllesmereUIDB, "EllesmereUIUnitFrames")
	merge(profile, { player = spec.player, target = spec.target, positions = spec.positions })
	merge(profile.player, spec.playerHealth)
end

local function seedPartyFrames()
	EllesmereUIDB = EllesmereUIDB or {}
	merge(frameProfile(EllesmereUIDB, "EllesmereUIRaidFrames"), Layout.frames.party)
end

local function seedThreat()
	ForeverThreatDB = ForeverThreatDB or {}
	merge(ForeverThreatDB, Layout.frames.threat)
end

local function findSetting(system, settingId)
	for _, setting in ipairs(system.settings) do
		if setting.setting == settingId then return setting end
	end
end

-- Edit Mode cannot change a preset, so a preset is copied to a kit layout first.
local function editableLayout(info)
	local presets = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
	if info.activeLayout > #presets then
		return info.layouts[info.activeLayout - #presets]
	end
	local layout = presets[info.activeLayout]
	layout.layoutName = Layout.profile
	layout.layoutType = Enum.EditModeLayoutType.Account
	table.insert(info.layouts, layout)
	info.activeLayout = #presets + #info.layouts
	return layout
end

local function applyPartyFrames()
	local info = C_EditMode.GetLayouts()
	local layout = editableLayout(info)
	for _, system in ipairs(layout.systems) do
		if system.system == Enum.EditModeSystem.UnitFrame
			and system.systemIndex == Enum.EditModeUnitFrameSystemIndices.Party then
			findSetting(system, Enum.EditModeUnitFrameSetting.UseRaidStylePartyFrames).value = 1
			local spec = Layout.party
			system.isInDefaultPosition = false
			system.anchorInfo = {
				point = spec.point, relativeTo = "UIParent", relativePoint = spec.relativePoint,
				offsetX = spec.x, offsetY = spec.y,
			}
			C_EditMode.SaveLayouts(info)
			return
		end
	end
	error("party frame system not found")
end

local function signature()
	local parts = {}
	for _, group in ipairs({ "binds", "cvars" }) do
		for key, value in pairs(ForeverKitConfig[group]) do
			parts[#parts + 1] = group .. ":" .. key .. "=" .. tostring(value)
		end
	end
	table.sort(parts)
	return table.concat(parts, ";")
end

local function applySettings()
	-- Earlier versions rebound default keys. Characters they touched go back to
	-- the defaults once. Characters they never touched keep their own binds.
	if (ForeverKitChar.version or ForeverKitChar.settings) and not ForeverKitChar.defaultsRestored then
		LoadBindings(DEFAULT_BINDINGS)
	end
	ForeverKitChar.defaultsRestored = true
	for key, action in pairs(ForeverKitConfig.binds) do
		SetBinding(key, action or nil)
	end
	SaveBindings(GetCurrentBindingSet())
	for name, value in pairs(ForeverKitConfig.cvars) do
		SetCVar(name, value)
	end
end

local function say(message)
	print("|cff33ff99Forever Kit:|r " .. message)
end

local SLOT_OFFSET = {
	ACTIONBUTTON = 0, MULTIACTIONBAR1BUTTON = 60, MULTIACTIONBAR2BUTTON = 48,
	MULTIACTIONBAR3BUTTON = 24, MULTIACTIONBAR4BUTTON = 36,
}

local function slotForKey(key)
	local prefix, index = (GetBindingAction(key) or ""):match("^(.-BUTTON)(%d+)$")
	return SLOT_OFFSET[prefix] and SLOT_OFFSET[prefix] + tonumber(index)
end

local function place(key, pickup, target)
	local slot = slotForKey(key)
	if not slot then return end
	ClearCursor()
	pickup(target)
	if GetCursorInfo() then PlaceAction(slot) end
	ClearCursor()
end

local function actionSignature()
	local parts = {}
	for _, macro in ipairs(ForeverKitConfig.macros) do
		parts[#parts + 1] = table.concat({ macro.name, macro.key or "", macro.bind or "", macro.body }, "|")
	end
	for key, spell in pairs(ForeverKitConfig.spells) do
		parts[#parts + 1] = key .. "=" .. spell
	end
	table.sort(parts)
	return table.concat(parts, ";")
end

local function applyActions()
	local pickupSpell = C_Spell and C_Spell.PickupSpell or PickupSpell
	for _, macro in ipairs(ForeverKitConfig.macros) do
		if GetMacroIndexByName(macro.name) == 0 then
			CreateMacro(macro.name, "INV_MISC_QUESTIONMARK", macro.body, true)
		else
			EditMacro(GetMacroIndexByName(macro.name), macro.name, nil, macro.body)
		end
		if macro.key then place(macro.key, PickupMacro, macro.name) end
		if macro.bind then SetBindingMacro(macro.bind, macro.name) end
	end
	for key, spell in pairs(ForeverKitConfig.spells) do
		place(key, pickupSpell, spell)
	end
	SaveBindings(GetCurrentBindingSet())
end

-- Macros and action bars load a moment after the world does, and neither can
-- change in combat, so this waits for both.
local function onActions()
	local current = actionSignature()
	if (ForeverKitChar.actions or "") == current or InCombatLockdown() then return end
	applyActions()
	ForeverKitChar.actions = current
	say("your macros and buttons are in place.")
end

local seeders = {
	Bartender4 = seedBartender, SexyMap = seedSexyMap,
	Questie = seedQuestie, RXPGuides = seedRestedXP,
}
local onceSeeders = {
	Leatrix_Plus = { run = seedLeatrix, version = 1 },
	EllesmereUIUnitFrames = { run = seedUnitFrames, version = Layout.frames.version },
	EllesmereUIRaidFrames = { run = seedPartyFrames, version = Layout.frames.version },
	ForeverThreat = { run = seedThreat, version = Layout.frames.version },
}
local fresh = false
local frame = CreateFrame("Frame")

local function onLogin()
	local current = signature()
	if fresh or ForeverKitChar.settings ~= current then
		applySettings()
		ForeverKitChar.settings = current
		say("your keys and settings are up to date.")
	end
	if fresh then
		ForeverKitChar.version = Layout.version
		ForeverKitChar.partyPending = true
		say("your bars and minimap are set.")
	end
end

-- Layouts are readable once the world loads. Saving fires the layouts event
-- again, so the pending flag clears first.
local function onLayouts()
	if not ForeverKitChar.partyPending or InCombatLockdown() then return end
	ForeverKitChar.partyPending = nil
	local ok = pcall(applyPartyFrames)
	if not ok then
		say("party frames need one click: Esc, Edit Mode, then pick Raid-Style Party Frames.")
	end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGIN" then
		onLogin()
	elseif event == "PLAYER_ENTERING_WORLD" then
		onLayouts()
		C_Timer.After(2, onActions)
	elseif event == "EDIT_MODE_LAYOUTS_UPDATED" then
		onLayouts()
	elseif event == "PLAYER_REGEN_ENABLED" then
		onActions()
	elseif name == "!ForeverKit" then
		ForeverKitChar = ForeverKitChar or {}
		fresh = ForeverKitChar.version ~= Layout.version
	elseif fresh and seeders[name] then
		seeders[name]()
	elseif onceSeeders[name] then
		local seeded = ensure(ForeverKitChar, "seeded")
		if seeded[name] ~= onceSeeders[name].version then
			onceSeeders[name].run()
			seeded[name] = onceSeeders[name].version
		end
	end
end)

SLASH_FOREVERKIT1 = "/forever"
SlashCmdList.FOREVERKIT = function()
	ForeverKitChar.version = nil
	ReloadUI()
end
