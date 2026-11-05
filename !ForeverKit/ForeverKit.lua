-- Forever Kit. The ! in the folder name loads this before other addons, so a
-- character's layout is in place before Bartender4, SexyMap, Questie, and
-- RestedXP read their settings.
--
-- Layout.lua is applied once per character, and /forever applies it again.
-- Config.lua and Personal.lua hold binds and game settings, which apply at
-- login whenever they change.

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

local seeders = {
	Bartender4 = seedBartender, SexyMap = seedSexyMap,
	Questie = seedQuestie, RXPGuides = seedRestedXP,
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
frame:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGIN" then
		onLogin()
	elseif event == "PLAYER_ENTERING_WORLD" or event == "EDIT_MODE_LAYOUTS_UPDATED" then
		onLayouts()
	elseif name == "!ForeverKit" then
		ForeverKitChar = ForeverKitChar or {}
		fresh = ForeverKitChar.version ~= Layout.version
	elseif fresh and seeders[name] then
		seeders[name]()
	end
end)

SLASH_FOREVERKIT1 = "/forever"
SlashCmdList.FOREVERKIT = function()
	ForeverKitChar.version = nil
	ReloadUI()
end
