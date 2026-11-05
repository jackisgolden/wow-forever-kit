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

ADDONS = ("!ForeverKit", "Bartender4", "SexyMap", "Questie", "RXPGuides")


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
    assert len(keys) == 24 and len({lua.globals().binds[k] for k in keys}) == 24
    assert all(re.fullmatch(r"(ALT|CTRL-SHIFT)-[0-9=-]", k) for k in keys), keys
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


if __name__ == "__main__":
    tests = [(n, f) for n, f in sorted(globals().items()) if n.startswith("test_")]
    for name, test in tests:
        test()
        print("ok", name)
    print(len(tests), "passed")
