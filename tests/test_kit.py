"""Runs the Forever Kit addon in real Lua against a stubbed WoW API.

Needs: pip install lupa. Run from the repo root: python tests/test_kit.py
"""
import re
from pathlib import Path

from lupa import LuaRuntime

ADDON = Path("!ForeverKit")
TOC_FILES = [l.strip() for l in (ADDON / "!ForeverKit.toc").read_text().splitlines()
             if l.strip().endswith(".lua")]

STUBS = """
binds, saved, resets, cvars, messages, handler, saves = {}, 0, 0, {}, {}, nil, 0
inCombat, breakEditMode = false, false
function UnitNameUnmodified() return NAME, SURNAME end
function GetRealmName() return "Realm" end
function CreateFrame() return { RegisterEvent = function() end, SetScript = function(_, _, f) handler = f end } end
function SetBinding(k, a) binds[k] = a end
function SaveBindings() saved = saved + 1 end
function GetCurrentBindingSet() return 2 end
DEFAULT_BINDINGS = 0
function LoadBindings(n) assert(n == 0); resets = resets + 1; binds = {} end
function SetCVar(k, v) cvars[k] = v end
function print(m) messages[#messages + 1] = m end
function ReloadUI() end
macroList, slots, cursor, knownSpells = {}, {}, nil, { Exorcism = true }
keyActions = { ["2"] = "ACTIONBUTTON2", ["4"] = "ACTIONBUTTON4",
  ["SHIFT-2"] = "MULTIACTIONBAR1BUTTON2", ["CTRL-SHIFT-3"] = "MULTIACTIONBAR2BUTTON3" }
function GetBindingAction(k) return keyActions[k] or "" end
function GetMacroIndexByName(n) for i, m in ipairs(macroList) do if m.name == n then return i end end return 0 end
function CreateMacro(n, _, b, perChar) assert(perChar); macroList[#macroList + 1] = { name = n, body = b }; return #macroList end
function EditMacro(i, _, _, b) macroList[i].body = b end
function SetBindingMacro(k, n) binds[k] = "MACRO " .. n end
function PickupMacro(n) cursor = n end
C_Spell = { PickupSpell = function(n) if knownSpells[n] then cursor = n end end }
function GetCursorInfo() return cursor end
function ClearCursor() cursor = nil end
function PlaceAction(s) slots[s] = cursor; cursor = nil end
C_Timer = { After = function(_, f) f() end }
function InCombatLockdown() return inCombat end
SlashCmdList = {}
Enum = {
  EditModeSystem = { UnitFrame = 3 },
  EditModeUnitFrameSystemIndices = { Party = 5 },
  EditModeUnitFrameSetting = { UseRaidStylePartyFrames = 9 },
  EditModeLayoutType = { Account = 1 },
}
local function preset()
  return { layoutName = "Modern", systems = { { system = 3, systemIndex = 5, settings = { { setting = 9, value = 0 } } } } }
end
EditModePresetLayoutManager = { GetCopyOfPresetLayouts = function() return { preset(), preset() } end }
layoutInfo = { activeLayout = 1, layouts = {} }
C_EditMode = {
  GetLayouts = function() if breakEditMode then error("nope") end return layoutInfo end,
  SaveLayouts = function(i) saves = saves + 1; layoutInfo = i; handler(nil, "EDIT_MODE_LAYOUTS_UPDATED") end,
}
"""

ADDONS = ("!ForeverKit", "Bartender4", "SexyMap", "Questie", "RXPGuides",
          "Leatrix_Plus", "EllesmereUIUnitFrames", "EllesmereUIRaidFrames")


def login(name="Raba", surname="Canoosh", before="", personal=""):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUBS)
    lua.globals().NAME, lua.globals().SURNAME = name, surname
    lua.execute(before)
    for file in TOC_FILES:
        lua.execute(personal if file == "Personal.lua" else (ADDON / file).read_text())
    handler = lua.globals().handler
    for addon in ADDONS:
        handler(None, "ADDON_LOADED", addon)
    handler(None, "PLAYER_LOGIN", None)
    handler(None, "PLAYER_ENTERING_WORLD", None)
    return lua


def test_bars_are_three_rows_of_twelve_and_a_faded_utility_bar():
    e = login().eval
    bars = 'Bartender4DB.namespaces.ActionBars.profiles["Forever Kit"].actionbars'
    assert e('Bartender4DB.profileKeys["Raba Canoosh"]') == "Forever Kit"
    tops = [e(f"{bars}[{i}].position.y") for i in (1, 6, 5)]
    assert tops == sorted(tops) and tops[1] - tops[0] == 47 and tops[2] - tops[1] == 47
    for i in (1, 6, 5):
        assert e(f"{bars}[{i}].rows") == 1 and e(f"{bars}[{i}].position.x") == -281
        assert e(f"{bars}[{i}].version") == 3
    assert e(f"{bars}[4].fadeout") is True and e(f"{bars}[4].fadeoutalpha") == 0.3
    assert e(f"{bars}[2].enabled") is False and e(f"{bars}[3].enabled") is False
    for module in ("BlizzardArt", "BagBar", "MicroMenu"):
        assert e(f'Bartender4DB.namespaces.{module}.profiles["Forever Kit"].enabled') is False


def test_map_icons_keep_their_size_and_sit_on_the_edge():
    e = login().eval
    core, buttons = 'SexyMap2DB["Raba Canoosh"].core', 'SexyMap2DB["Raba Canoosh"].buttons'
    scale, icon, radius = e(f"{core}.scale"), e(f"{buttons}.scale"), e(f"{buttons}.radius")
    assert 1.22 < scale < 2.44
    assert abs(scale * icon - 1) < 1e-9, "icons render at default size"
    assert abs((70 + radius) * icon - 78) < 1e-9, "icons sit 8 units outside the 70 unit half width"


def test_binds_avoid_default_keys():
    lua = login()
    keys = list(lua.globals().binds)
    assert len(keys) == 30 and len({lua.globals().binds[k] for k in keys}) == 30
    assert all(re.fullmatch(r"(ALT|CTRL-SHIFT)-[0-9=-]|ALT-[QERFCV]", k) for k in keys), keys
    assert lua.eval("resets") == 0 and lua.eval("cvars.cameraFov") == 90


def test_party_preset_is_copied_then_saved_once():
    e = login().eval
    assert e("saves") == 1 and e("layoutInfo.activeLayout") == 3
    layout = "layoutInfo.layouts[1]"
    assert e(f"{layout}.layoutName") == "Forever Kit" and e(f"{layout}.layoutType") == 1
    assert e(f"{layout}.systems[1].settings[1].value") == 1
    assert e(f"{layout}.systems[1].anchorInfo.offsetX") == -480
    assert e("ForeverKitChar.partyPending") is None


def test_existing_custom_layout_is_edited_in_place():
    before = """layoutInfo = { activeLayout = 3, layouts = { { layoutName = "Mine",
      systems = { { system = 3, systemIndex = 5, settings = { { setting = 9, value = 0 } } } } } } }"""
    e = login(before=before).eval
    assert e("#layoutInfo.layouts") == 1 and e("layoutInfo.layouts[1].layoutName") == "Mine"
    assert e("layoutInfo.layouts[1].systems[1].settings[1].value") == 1


def test_edit_mode_failure_tells_the_player_and_breaks_nothing():
    lua = login(before="breakEditMode = true")
    assert any("Edit Mode" in m for m in lua.globals().messages.values())
    assert lua.eval("ForeverKitChar.version") == 2


def test_combat_defers_party_frames():
    lua = login(before="inCombat = true")
    assert lua.eval("saves") == 0 and lua.eval("ForeverKitChar.partyPending") is True


def test_layout_upgrade_reapplies_but_same_version_does_not():
    e = login(before='ForeverKitChar = { version = 1 }').eval
    assert e('SexyMap2DB["Raba Canoosh"].core.scale') == 1.5
    settings = e("ForeverKitChar.settings")
    e = login(before=f"ForeverKitChar = {{ version = 2, settings = [==[{settings}]==], defaultsRestored = true }}").eval
    assert e("SexyMap2DB") is None and e("saved") == 0


def test_seeding_keeps_other_settings():
    before = """SexyMap2DB = { ["Raba Canoosh"] = { clock = { font = "x" } } }
      QuestieConfig = { profiles = { Default = { keep = true } } }
      RXPSettings = { profiles = { ["Raba Canoosh - Realm"] = { framePositions = { RXPFrame = 1 } } } }"""
    e = login(before=before, surname=None, name="Raba Canoosh").eval
    assert e('QuestieConfig.profiles.Default.keep') is True
    assert e('RXPSettings.profiles["Raba Canoosh - Realm"].framePositions.RXPFrame') == 1


def test_personal_overrides_apply_without_touching_layout():
    personal = 'ForeverKitConfig.binds.BUTTON4 = "TOGGLEAUTORUN"; ForeverKitConfig.binds["ALT-1"] = false; ForeverKitConfig.cvars.cameraFov = 75'
    e = login(before='ForeverKitChar = { version = 2, settings = "old", defaultsRestored = true }', personal=personal).eval
    assert e("saved") == 1 and e("binds.BUTTON4") == "TOGGLEAUTORUN"
    assert e('binds["ALT-1"]') is None and e("cvars.cameraFov") == 75 and e("SexyMap2DB") is None


def test_old_kit_binds_reset_once_and_friends_never():
    e = login(before='ForeverKitChar = { version = 1, settings = "old" }').eval
    assert e("resets") == 1 and e("ForeverKitChar.defaultsRestored") is True
    assert login(name="Bob", surname=None).eval("resets") == 0


def test_restedxp_target_box_moves_for_this_character():
    e = login().eval
    frame = 'RXPSettings.profiles["Raba Canoosh"].framePositions.activeTargetFrame[1]'
    assert e(f"{frame}[1]") == "TOPLEFT" and e(f"{frame}[4]") == 30
    assert e('RXPSettings.profileKeys["Raba Canoosh"]') == "Raba Canoosh"


def test_party_waits_for_a_late_combat_to_end():
    lua = login(before="inCombat = true")
    lua.execute("inCombat = false")
    lua.globals().handler(None, "EDIT_MODE_LAYOUTS_UPDATED", None)
    assert lua.eval("saves") == 1


def test_surnameless_characters_use_each_addons_key_format():
    e = login(name="Bob", surname=None).eval
    assert e('Bartender4DB.profileKeys["Bob - Realm"]') == "Forever Kit"
    assert e('SexyMap2DB["Bob-Realm"].core.scale') == 1.5


MACROS = """ForeverKitConfig.macros = {
  { name = "Heal", key = "SHIFT-2", body = "/cast Holy Light" },
  { name = "Skull", bind = "BUTTON3", body = "/tm !8" },
}
ForeverKitConfig.spells = { ["4"] = "Exorcism", ["CTRL-SHIFT-3"] = "Devotion Aura" }"""


def test_macros_land_on_the_button_each_key_presses():
    e = login(personal=MACROS).eval
    assert e("#macroList") == 2 and e("slots[62]") == "Heal"
    assert e("binds.BUTTON3") == "MACRO Skull" and e("slots[4]") == "Exorcism"


def test_unknown_spell_leaves_the_button_alone():
    e = login(personal=MACROS, before='slots[51] = "keep"').eval
    assert e("slots[51]") == "keep"


def test_friends_with_no_macros_touch_no_buttons():
    e = login().eval
    assert e("#macroList") == 0 and e("next(slots)") is None and e("ForeverKitChar.actions") is None


def test_macros_apply_once_and_update_in_place():
    lua = login(personal=MACROS)
    done = lua.eval("ForeverKitChar.actions")
    before = f'ForeverKitChar = {{ version = 2, settings = "old", actions = [==[{done}]==] }}'
    assert login(before=before, personal=MACROS).eval("#macroList") == 0
    edited = MACROS.replace("Holy Light", "Flash of Light")
    e = login(before='macroList = { { name = "Heal", body = "old" } }', personal=edited).eval
    assert e("#macroList") == 2 and e("macroList[1].body") == "/cast Flash of Light"


def test_macros_wait_for_combat_to_end():
    lua = login(before="inCombat = true", personal=MACROS)
    assert lua.eval("#macroList") == 0
    lua.execute("inCombat = false")
    lua.globals().handler(None, "PLAYER_REGEN_ENABLED", None)
    assert lua.eval("#macroList") == 2


def test_auto_repair_turns_on_once_so_players_can_turn_it_off():
    e = login(before='LeaPlusDB = { AutoRepairGear = "Off", keep = 1 }').eval
    assert e("LeaPlusDB.AutoRepairGear") == "On" and e("LeaPlusDB.keep") == 1
    e = login(before='LeaPlusDB = { AutoRepairGear = "Off" }; ForeverKitChar = { version = 2, seeded = { Leatrix_Plus = 1 } }').eval
    assert e("LeaPlusDB.AutoRepairGear") == "Off"


def test_party_stack_sits_left_of_and_above_a_larger_player_card():
    e = login().eval
    unit = 'EllesmereUIDB.profiles.Default.addons.EllesmereUIUnitFrames'
    party = 'EllesmereUIDB.profiles.Default.addons.EllesmereUIRaidFrames'
    width, height = e(f"{unit}.player.frameWidth"), e(f"{unit}.player.healthHeight") + e(f"{unit}.player.powerHeight")
    assert e(f"{party}.partyFrameWidth") < width and e(f"{party}.partyFrameHeight") < height
    x, y = e(f"{unit}.positions.player.x"), e(f"{unit}.positions.player.y")
    left, top = x - (width + height) / 2, y + height / 2
    assert e(f"{party}.partyUnlockPos.x") == left - 100 and e(f"{party}.partyUnlockPos.y") > top
    assert e(f"{unit}.player.healthBarOpacity") < 100 and e(f"{party}.partyPortraitStyle") == "attached"
    assert e(f"{unit}.player.healthClassColored") is False and e(f"{unit}.target.healthClassColored") is None
    assert e(f"{unit}.player.customFillColor.g") == e(f"{party}.customFillColor.g")
    assert e(f"{party}.powerShowForDPS") is True and e("EllesmereUIDB.firstInstallPopupShown") is True


def test_frames_keep_other_settings_and_use_the_active_profile():
    before = """EllesmereUIDB = { activeProfile = "Mine", profiles = { Mine = { addons = {
      EllesmereUIUnitFrames = { player = { showBuffs = true } } } } } }"""
    e = login(before=before).eval
    player = "EllesmereUIDB.profiles.Mine.addons.EllesmereUIUnitFrames.player"
    assert e(f"{player}.showBuffs") is True and e(f"{player}.frameWidth") == 210


def test_layout_version_bump_leaves_frames_alone():
    version = re.search(r"version = (\d+),\n\t\tplayer", (ADDON / "Layout.lua").read_text())[1]
    before = f"ForeverKitChar = {{ version = 1, seeded = {{ EllesmereUIUnitFrames = {version}, EllesmereUIRaidFrames = {version} }} }}"
    assert login(before=before).eval("EllesmereUIDB") is None


if __name__ == "__main__":
    tests = [(n, f) for n, f in sorted(globals().items()) if n.startswith("test_")]
    for name, test in tests:
        test()
        print("ok", name)
    print(len(tests), "passed")
