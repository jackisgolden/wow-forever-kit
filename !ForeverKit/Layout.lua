-- The Forever Kit layout, as data. ForeverKit.lua applies it. All positions are
-- in UI units on a 1920x1080 grid. Bartender4 positions are a bar's top-left
-- corner, measured from the named screen point. Raise VERSION to re-apply this
-- for every character. Raise frames.version to re-apply only the unit frames.

local BUTTON = 45
local GAP = 2
local ROW = BUTTON + GAP
local BAR_LEFT = -(12 * BUTTON + 11 * GAP) / 2
local BOTTOM_ROW_TOP = 67

local MAP_SCALE = 1.5
local ICON_SIZE = 1          -- on-screen icon size, relative to the default
local ICON_OFFSET = 8        -- how far icons sit outside the map edge
local MAP_HALF_WIDTH = 70

local iconScale = ICON_SIZE / MAP_SCALE

local CARD_WIDTH = 170
local CARD_HEIGHT = 26
local CARD_POWER = 6
local CARD_X = -317
local CARD_Y = -193
local CARD_OPACITY = 60
local PARTY_SHIFT = 100      -- how far left of the player card the party stack sits
local PARTY_GAP = 8          -- how far above the player card the party stack starts

local cardTotalWidth = CARD_WIDTH + CARD_HEIGHT + CARD_POWER
local cardLeft = CARD_X - cardTotalWidth / 2
local cardTop = CARD_Y + (CARD_HEIGHT + CARD_POWER) / 2

local function card(side)
	return {
		frameWidth = CARD_WIDTH, healthHeight = CARD_HEIGHT, powerHeight = CARD_POWER,
		healthBarOpacity = CARD_OPACITY, powerBarOpacity = CARD_OPACITY,
		showPortrait = true, portraitStyle = "attached", portraitSide = side,
	}
end

ForeverKitLayout = {
	version = 2,
	profile = "Forever Kit",

	bartender = {
		-- Bar ids are Bartender4's. Bar 1 is the bottom row.
		bars = {
			[1] = { rows = 1, x = BAR_LEFT, y = BOTTOM_ROW_TOP },
			[6] = { rows = 1, x = BAR_LEFT, y = BOTTOM_ROW_TOP + ROW },
			[5] = { rows = 1, x = BAR_LEFT, y = BOTTOM_ROW_TOP + 2 * ROW },
			[4] = {
				rows = 6, x = -104, y = 320, point = "BOTTOMRIGHT",
				fadeout = true, fadeoutalpha = 0.3,
			},
		},
		disabledBars = { 2, 3 },
		hidden = { "BlizzardArt", "BagBar", "MicroMenu" },
		placed = {
			StatusTrackingBar = { x = -285, y = 20 },
			StanceBar = { x = BAR_LEFT, y = BOTTOM_ROW_TOP + 2 * ROW + 40 },
		},
	},

	sexymap = {
		scale = MAP_SCALE,
		iconScale = iconScale,
		-- SexyMap places an icon at (half width + radius) in the icon's own
		-- scale, so a smaller icon needs a larger radius to stay on the edge.
		iconRadius = (MAP_HALF_WIDTH + ICON_OFFSET) / iconScale - MAP_HALF_WIDTH,
		shape = 130871,
		x = -8,
		y = -8,
	},

	questie = { "TOPRIGHT", "UIParent", "TOPRIGHT", -14, -310 },

	restedxp = {
		activeTargetFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 30, -290 },
	},

	-- Raid-style party frames, just left of the player frame.
	party = { point = "TOPRIGHT", relativePoint = "CENTER", x = -480, y = -240 },

	-- EllesmereUI unit frames, used when those addons are installed. Positions
	-- are measured from the screen center.
	frames = {
		version = 1,
		player = card("left"),
		target = card("right"),
		positions = {
			player = { point = "CENTER", relPoint = "CENTER", x = CARD_X, y = CARD_Y },
			target = { point = "CENTER", relPoint = "CENTER", x = -CARD_X, y = CARD_Y },
		},
		party = {
			partyFrameWidth = 110, partyFrameHeight = 24, partyHideSelf = true,
			partyFlipGrowth = true, healthBarOpacity = CARD_OPACITY,
			partyPortraitStyle = "attached", partyPortraitSide = "left",
			partyUnlockPos = {
				point = "BOTTOMLEFT", relPoint = "CENTER",
				x = cardLeft - PARTY_SHIFT, y = cardTop + PARTY_GAP,
			},
		},
	},
}
