-- Forever Kit. The ! in the folder name loads this before other addons, so
-- each character's layout is in place before Bartender4, SexyMap, and Questie
-- read their settings. The layout runs once per character, and /forever runs
-- it again. Binds and game settings live in Config.lua and Personal.lua, and
-- apply at login whenever they change.

local PROFILE = "Forever Kit"
local VERSION = 1

local function charKey(separator)
	local name, surname = UnitNameUnmodified("player")
	if surname then
		return name .. " " .. surname
	end
	return name .. separator .. GetRealmName()
end

local function bar(x, y, extra)
	local t = {
		version = 3, WoW10Layout = true, rows = 2, padding = 2, showgrid = true,
		position = { point = "BOTTOM", x = x, y = y },
	}
	for k, v in pairs(extra or {}) do t[k] = v end
	return t
end

local function off()
	return { version = 3, WoW10Layout = true, enabled = false }
end

local function module(enabled, x, y)
	local t = { version = 3 }
	if enabled == false then t.enabled = false end
	if x then t.position = { point = "BOTTOM", x = x, y = y } end
	return t
end

local function seedBartender()
	Bartender4DB = Bartender4DB or {}
	local db = Bartender4DB
	db.profileKeys = db.profileKeys or {}
	db.profiles = db.profiles or {}
	db.namespaces = db.namespaces or {}
	db.profileKeys[charKey(" - ")] = PROFILE
	db.profiles[PROFILE] = { blizzardVehicle = true, focuscastmodifier = false, outofrange = "hotkey" }

	local function put(ns, data)
		db.namespaces[ns] = db.namespaces[ns] or {}
		db.namespaces[ns].profiles = db.namespaces[ns].profiles or {}
		db.namespaces[ns].profiles[PROFILE] = data
	end

	local bars = {
		bar(-140, 212),
		off(), off(), off(), off(),
		bar(-140, 118),
		{ WoW10Layout = true }, { WoW10Layout = true }, { WoW10Layout = true }, { WoW10Layout = true },
	}
	bars[13] = { WoW10Layout = true }
	bars[14] = { WoW10Layout = true }
	bars[15] = { WoW10Layout = true }
	put("ActionBars", { actionbars = bars })
	put("BlizzardArt", module(false))
	put("BagBar", module(false))
	put("MicroMenu", module(false))
	put("StatusTrackingBar", module(true, -285, 20))
	put("StanceBar", module(true, -140, 256))
end

local function seedSexyMap()
	SexyMap2DB = type(SexyMap2DB) == "table" and SexyMap2DB or {}
	local key = charKey("-")
	if type(SexyMap2DB[key]) ~= "table" then SexyMap2DB[key] = {} end
	local p = SexyMap2DB[key]
	p.core = {
		lock = true, clamp = true, rightClickToConfig = true, autoZoom = 0, northTag = false,
		shape = 130871, scale = 1.22,
		point = "TOPRIGHT", relpoint = "TOPRIGHT", x = -6, y = -6,
	}
	p.coordinates = {
		enabled = false, xOffset = 0, yOffset = 10, updateRate = 1, monochrome = false,
		font = "Friz Quadrata TT", outline = "NONE", coordPrecision = "%d,%d",
		fontColor = {}, borderColor = {}, backgroundColor = {},
	}
	p.buttons = {
		radius = 10, lockDragging = false, allowDragging = true, scale = 1, controlVisibility = true,
		dragPositions = {},
		visibilitySettings = {
			MinimapZoomIn = "never", MinimapZoomOut = "never", MiniMapWorldMapButton = "never",
			AddonCompartmentFrame = "never", MiniMapMailFrame = "always",
			DayNight = "hover", ExpansionLandingPageMinimapButton = "hover", CraftingOrder = "hover",
			TimeManagerClockButton = "hover", SexyMapZoneTextButton = "hover",
		},
	}
	p.borders = {
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
	QuestieConfig.profiles = QuestieConfig.profiles or {}
	QuestieConfig.profiles.Default = QuestieConfig.profiles.Default or {}
	QuestieConfig.profiles.Default.TrackerLocation = { "TOPRIGHT", "UIParent", "TOPRIGHT", -14, -300 }
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

local seeders = { Bartender4 = seedBartender, SexyMap = seedSexyMap, Questie = seedQuestie }
local fresh = false
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, name)
	if event == "PLAYER_LOGIN" then
		local current = signature()
		if fresh or ForeverKitChar.settings ~= current then
			applySettings()
			ForeverKitChar.settings = current
			print("|cff33ff99Forever Kit:|r your keys and settings are up to date.")
		end
		if fresh then
			ForeverKitChar.version = VERSION
			print("|cff33ff99Forever Kit:|r your bars and minimap are set.")
		end
	elseif name == "!ForeverKit" then
		ForeverKitChar = ForeverKitChar or {}
		fresh = ForeverKitChar.version ~= VERSION
	elseif fresh and seeders[name] then
		seeders[name]()
	end
end)

SLASH_FOREVERKIT1 = "/forever"
SlashCmdList.FOREVERKIT = function()
	ForeverKitChar.version = nil
	ReloadUI()
end
