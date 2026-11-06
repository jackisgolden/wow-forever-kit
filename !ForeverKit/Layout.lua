-- The Forever Kit layout, as data. ForeverKit.lua applies it. Everything is built
-- from the action bar block, the way a page is built from one grid unit: frames
-- in the middle hang off the bottom of the screen with the bars, so they keep
-- their spacing at any resolution, and frames on the screen edges stay inside a
-- centered 16:9 area, so an ultrawide keeps them in view. Bartender4 positions
-- are a bar's top-left corner, measured from the named screen point.
--
-- Raise VERSION to re-apply this for every character. Raise frames.version to
-- re-apply only the unit frames and threat meter. /forever re-applies it all,
-- which also fits the edges to a new monitor.

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

-- How far an ultrawide's edges sit outside the centered 16:9 area.
local edgeInset = math.max(0, (GetScreenWidth() - GetScreenHeight() * 16 / 9) / 2)

local function span(buttons) return buttons * ROW - GAP end

local BLOCK_RIGHT = -BAR_LEFT
local BLOCK_TOP = BOTTOM_ROW_TOP + 2 * ROW
local BLOCK_BOTTOM = BOTTOM_ROW_TOP - BUTTON
local SPACE = 8              -- the gap between neighbouring frames

local CARD_HEALTH = 28
local CARD_POWER = 8
local CARD_HEIGHT = CARD_HEALTH + CARD_POWER
local CARD_SPAN = span(5)    -- two cards leave two buttons free in the middle
local CARD_BOTTOM = BLOCK_TOP + ROW + SPACE      -- clears the stance bar
local CARD_OPACITY = 60

local PARTY_SHIFT = 2 * ROW  -- how far left of the player card the party sits
local THREAT_WIDTH = 274

local HEALTH_GREEN = { r = 37 / 255, g = 193 / 255, b = 29 / 255 }

local function card(side)
	return {
		frameWidth = CARD_SPAN - CARD_HEIGHT, healthHeight = CARD_HEALTH, powerHeight = CARD_POWER,
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
				rows = 6, x = -104 - edgeInset, y = 320, point = "BOTTOMRIGHT",
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
		x = -8 - edgeInset / MAP_SCALE,
		y = -8,
	},

	questie = { "TOPRIGHT", "UIParent", "TOPRIGHT", -14 - edgeInset, -310 },

	restedxp = {
		activeTargetFrame = { "TOPLEFT", "UIParent", "TOPLEFT", 30 + edgeInset, -290 },
	},

	-- Raid-style party frames, just left of the player frame.
	party = { point = "TOPRIGHT", relativePoint = "CENTER", x = -480, y = -240 },

	-- EllesmereUI cards sit flush with the left and right of the bar block, and
	-- the party stacks up from above the player card.
	frames = {
		version = 4,
		player = card("left"),
		playerHealth = { healthClassColored = false, customFillColor = HEALTH_GREEN },
		target = card("right"),
		positions = {
			player = { point = "BOTTOMLEFT", relPoint = "BOTTOM", x = BAR_LEFT, y = CARD_BOTTOM },
			target = { point = "BOTTOMRIGHT", relPoint = "BOTTOM", x = BLOCK_RIGHT, y = CARD_BOTTOM },
		},
		party = {
			partyFrameWidth = span(3), partyFrameHeight = 30, partyHideSelf = true,
			partyFlipGrowth = true, healthBarOpacity = CARD_OPACITY,
			healthColorMode = "custom", customFillColor = HEALTH_GREEN, healthBarTexture = "none",
			showPowerBar = true, powerHeight = 4,
			powerShowForTank = true, powerShowForHealer = true, powerShowForDPS = true,
			healthTextMode = "percent", healthTextPosition = "right",
			partyPortraitStyle = "attached", partyPortraitSide = "left",
			partyUnlockPos = {
				point = "BOTTOMLEFT", relPoint = "BOTTOM",
				x = BAR_LEFT - PARTY_SHIFT, y = CARD_BOTTOM + CARD_HEIGHT + SPACE,
			},
		},
		-- ForeverThreat anchors its bottom center, beside the block and as tall as it.
		threat = {
			point = "BOTTOM", x = BLOCK_RIGHT + 2 * SPACE + THREAT_WIDTH / 2, y = BLOCK_BOTTOM,
			frameWidth = THREAT_WIDTH, frameHeight = span(3),
		},
	},
}
