local log = {}
local all = {}
local function Widget(name)
  local w = { scripts = {}, shown = true, text = "" }
  local mt = {}
  mt.__index = function(t, k)
    return function(self, ...)
      local a = {...}
      if k == "SetScript" then self.scripts[a[1]] = a[2]; return end
      if k == "GetScript" then return self.scripts[a[1]] end
      if k == "Show" then self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end return end
      if k == "Hide" then self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end return end
      if k == "SetShown" then if a[1] then self:Show() else self:Hide() end return end
      if k == "IsShown" then return self.shown end
      if k == "SetText" then local old=self.text; self.text = a[1]; if self.scripts.OnTextChanged and old ~= a[1] then self.scripts.OnTextChanged(self) end return end
      if k == "GetText" then return self.text end
      if k == "HasFocus" then return false end
      if k == "SetChecked" then self.checked = a[1]; return end
      if k == "GetChecked" then return self.checked end
      if k == "SetEnabled" then self.enabled = a[1]; return end
      if k == "GetParent" then return rawget(self, "parent") end
      if k == "SetSize" then rawset(self, "w", a[1]); rawset(self, "h", a[2]); return end
      if k == "SetWidth" then rawset(self, "w", a[1]); return end
      if k == "SetHeight" then rawset(self, "h", a[1]); return end
      if k == "GetHeight" then return rawget(self, "h") or 300 end
      if k == "GetVerticalScroll" then return rawget(self, "vs") or 0 end
      if k == "SetVerticalScroll" then rawset(self, "vs", a[1]); return end
      if k == "SetPoint" and a[1] == "CENTER" and type(a[4]) == "number" then rawset(self, "cx", a[4]); rawset(self, "cy", a[5]) end
      if k == "SetPoint" and a[1] == "TOPLEFT" and type(a[2]) == "number" then rawset(self, "px", a[2]); rawset(self, "py", a[3]); return end
      if k == "GetLeft" then return 1000 + (rawget(self, "px") or 0) end
      if k == "GetRight" then return 1000 + (rawget(self, "px") or 0) + (rawget(self, "w") or 0) end
      if k == "GetTop" then return 1000 + (rawget(self, "py") or 0) end
      if k == "GetBottom" then return 1000 + (rawget(self, "py") or 0) - (rawget(self, "h") or 0) end
      if k == "GetWidth" then return rawget(self, "w") or 460 end
      if k == "GetCenter" then return 500, 400 end
      if k == "GetEffectiveScale" then return 1 end
      if k:match("^Create") or k:match("^Get") then return Widget() end
      return nil
    end
  end
  setmetatable(w, mt)
  if name then _G[name] = w end
  table.insert(all, w)
  return w
end
function CreateFrame(_, name, parent) local w = Widget(name); rawset(w, "parent", parent); w.shown = true; return w end
function CreateFont(name) return Widget(name) end
UIParent = Widget(); Minimap = Widget("Minimap"); UISpecialFrames = {}
GameTooltip = Widget(); GameTooltip_Hide = function() end
DoEmote = function(t) table.insert(log, "EMOTE:" .. t) end
C_ChatInfo = { SendChatMessage = function(m, t) table.insert(log, t .. ":" .. m) end }
local cursor = { 500, 400 }
GetCursorPosition = function() return cursor[1], cursor[2] end
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) table.insert(log, "PRINT:" .. m) end }
SlashCmdList = {}; SecureCmdList = { CAST = function() end }; SLASH_CAST1 = "/cast"
StaticPopupDialogs = {}; YES = "Yes"; NO = "No"; CLOSE = "Close"
local popup
StaticPopup_Show = function(name, a, b, data) popup = { name = name, data = data } end
InCombatLockdown = function() return false end
UnitName = function() return "Ondra" end
ChatEdit_ChooseBoxForSend = function() return Widget() end
ChatEdit_SendText = function(box) table.insert(log, "CHATBOX:" .. box.text) end
local timers = {}
C_Timer = { NewTimer = function(d, fn) local t = { d = d, fn = fn, Cancel = function(self) self.cancelled = true end }; table.insert(timers, t); return t end }
EMOTE1_TOKEN = "DANCE"; EMOTE1_CMD1 = "/dance"; EMOTE2_TOKEN = "WAVE"; EMOTE2_CMD1 = "/wave"
EMOTE3_TOKEN = "BOW"; EMOTE3_CMD1 = "/bow"; EMOTE4_TOKEN = "CHEER"; EMOTE4_CMD1 = "/cheer"; EMOTE5_TOKEN = "ROAR"; EMOTE5_CMD1 = "/roar"
EMOTE7_TOKEN = "SILLY"; EMOTE7_CMD1 = "/silly"; EMOTE7_CMD2 = "/joke2"
local bindings, saved = {}, 0
SetBinding = function(key, action) bindings[key] = action end
GetBindingKey = function(action) local keys = {} for k, a in pairs(bindings) do if a == action then table.insert(keys, k) end end table.sort(keys) return keys[1], keys[2] end
GetBindingAction = function(key) return bindings[key] or "" end
SaveBindings = function() saved = saved + 1 end
GetCurrentBindingSet = function() return 1 end
GetBindingText = function(k) return k end
local mods = {}
IsAltKeyDown = function() return mods.alt end; IsControlKeyDown = function() return mods.ctrl end; IsShiftKeyDown = function() return mods.shift end
local subpage
local registered
Settings = {
  RegisterCanvasLayoutSubcategory = function(parent, frame, name) subpage = frame end,
  RegisterCanvasLayoutCategory = function(frame) registered = frame; return { GetID = function() return 42 end } end,
  RegisterAddOnCategory = function() end,
  OpenToCategory = function() registered:Show() end,
}
GetTime = function() return os.clock() * 1000 end
local function check(name, cond) print((cond and "OK   " or "FAIL ") .. name) end
local function last() return log[#log] end

-- 2.x saved data to test migration
CharadesDB = { minimapAngle = 10, closeAfterUse = true, categories = { { title = "Pozdravy", emotes = { { token = "WAVE", label = "Zamávat" } } }, { title = "Moje", emotes = { { token = "ROAR", label = "Řev" } } } }, favorites = { "ROAR" } }
local ns = {}
for _, f in ipairs({ "Defaults.lua", "Core.lua", "GameIcons.lua", "Icons.lua", "Actions.lua", "Panel.lua", "Wheel.lua", "Transfer.lua", "General.lua", "KeyBindings.lua", "Editor.lua", "MinimapMenu.lua", "Charades.lua" }) do
  assert(loadfile(f))("Charades", ns)
end
local loader
for i = #all, 1, -1 do if all[i].scripts.OnEvent then loader = all[i]; break end end
loader.scripts.OnEvent(loader, "ADDON_LOADED", "Charades")

local d = ns.data
check("migration items", d.categories[2].items[1].action == "/roar" and d.categories[1].defaultId == "greetings" and d.favorites[1] == "/roar")
check("default icons migrated", d.categories[1].items[1].icon == "@wave" and d.categories[1].icon == "@group" and d.categories[2].items[1].icon == "@roar" and d.categories[2].icon == nil)
check("text offset with icons", ns.TextOffset(20) == 40)
ns.db.showIcons = false; check("text offset without icons", ns.TextOffset(20) == 20); ns.db.showIcons = true
check("legacy names translated", d.categories[1].title == "Social" and d.categories[1].items[1].label == "Wave" and d.categories[2].title == "Moje" and d.categories[2].items[1].label == "Řev")
check("old keys removed", CharadesDB.categories == nil and CharadesDB.shared ~= nil)
check("binding name", BINDING_NAME_CHARADES_FAV1 == "Favorite 1: Řev" and BINDING_NAME_CHARADES_FAV2 == "Favorite 2 (empty)")

ns.RunAction("/roar"); check("emote", last() == "EMOTE:ROAR")
ns.RunAction("/joke2"); check("emote alias CMD2", last() == "EMOTE:SILLY")
ns.RunAction("Ahoj všichni"); check("plain text says", last() == "SAY:Ahoj všichni")
ns.RunAction("/e mává"); check("custom emote", last() == "EMOTE:mává")
ns.RunAction("/y Pozor!"); check("yell", last() == "YELL:Pozor!")
ns.RunAction("/cast Fireball"); check("secure blocked", last():find("protected") ~= nil)
ns.RunAction("/someaddon go"); check("chatbox for other", last() == "CHATBOX:/someaddon go")
timers = {}
ns.RunAction("/bow; /wait 1.5; Ahoj; /wave")
check("sequence first immediate", last() == "EMOTE:BOW")
check("sequence timers", #timers == 2 and timers[1].d == 1.5 and timers[2].d == 3.5)
timers[1].fn(); check("sequence step 2", last() == "SAY:Ahoj")
ns.RunAction("/dance"); check("new action cancels", timers[2].cancelled == true)

-- panel + search
Charades_Toggle()
CharadesPanel.search:SetText("rev")
local found
for _, w in ipairs(all) do if rawget(w, "action") == "/roar" and w.shown then found = w end end
check("search folds diacritics", found ~= nil)
CharadesPanel.search.scripts.OnEnterPressed(CharadesPanel.search)
check("enter runs first result, menu stays open", last() == "EMOTE:ROAR" and CharadesPanel.shown == true)
check("old closeAfterUse migrated", CharadesDB.closeAfterUse == nil and CharadesDB.keepOpen == nil and CharadesDB.hideAfterUse == false)
ns.db.hideAfterUse = true; ns.PerformAction("/roar"); check("hides when hide after use is on", CharadesPanel.shown == false)
ns.db.hideAfterUse = false; Charades_Toggle()
CharadesDB.keepOpen = false; CharadesDB.hideAfterUse = nil; ns.InitDatabase()
check("keepOpen off migrates to hideAfterUse on", CharadesDB.hideAfterUse == true and CharadesDB.keepOpen == nil)
CharadesDB.hideAfterUse = false

-- All emotes view in the main menu
Charades_Toggle(); if not CharadesPanel.shown then Charades_Toggle() end
local function visibleAll() local list = {} for _, w in ipairs(all) do if type(rawget(w, "action")) == "string" and w.shown and rawget(w, "icon") and rawget(w, "star") then list[#list + 1] = w end end return list end
CharadesPanel.viewButton.scripts.OnClick(CharadesPanel.viewButton)
check("view switch", ns.db.panelView == "all" and CharadesPanel.title.text == "All emotes" and CharadesPanel.filterButton.shown)
check("animated only default", #visibleAll() == 5)
CharadesPanel.filterButton.scripts.OnClick(CharadesPanel.filterButton)
check("filter off shows all", #visibleAll() == 6 and ns.db.animatedOnly == false)
CharadesPanel.search:SetText("joke2")
local silly = visibleAll()
check("search aliases", #silly == 1 and silly[1].action == "/silly")
silly[1].scripts.OnClick(silly[1], "LeftButton"); check("click runs emote", last() == "EMOTE:SILLY")
silly[1].scripts.OnClick(silly[1], "RightButton"); check("right-click favorites", ns.IsFavorite("/silly"))
ns.ToggleFavorite("/silly")
CharadesPanel.search:SetText("")
CharadesPanel.filterButton.scripts.OnClick(CharadesPanel.filterButton)
CharadesPanel.viewButton.scripts.OnClick(CharadesPanel.viewButton)
check("back to my actions", ns.db.panelView == "mine" and CharadesPanel.title.text == "Charades" and not CharadesPanel.filterButton.shown)
Charades_Toggle()

-- resizable scrolling window
check("default size", CharadesPanel.w == 520 and CharadesPanel.h == 470)
Charades_Toggle(); if not CharadesPanel.shown then Charades_Toggle() end
check("columns follow width", true)
CharadesPanel:SetSize(700, 400); ns.RefreshPanel()
-- find the scroll frame (the one with a vertical scroll value we can move)
for _, c in ipairs(ns.data.categories) do c.collapsed = false end
ns.RefreshPanel()
local sf
for _, w in ipairs(all) do if rawget(w, "parent") == CharadesPanel and w.scripts.OnMouseWheel == nil and rawget(w, "vs") ~= nil then sf = w end end
CharadesPanel.scripts.OnMouseWheel(CharadesPanel, -1)
for _, w in ipairs(all) do if rawget(w, "vs") and rawget(w, "vs") > 0 then sf = w end end
check("mouse wheel scrolls", sf ~= nil and sf.vs > 0)
for _ = 1, 200 do CharadesPanel.scripts.OnMouseWheel(CharadesPanel, -1) end
local maxVs = sf.vs
CharadesPanel.scripts.OnMouseWheel(CharadesPanel, -1)
check("scroll clamps at bottom", sf.vs == maxVs)
for _ = 1, 200 do CharadesPanel.scripts.OnMouseWheel(CharadesPanel, 1) end
check("scroll clamps at top", sf.vs == 0)
Charades_Toggle()

-- minimap quick menu
local mm = CharadesMinimapButton
UIParent.GetRight = function() return 1920 end
UIParent.GetWidth = function() return 1920 end
UIParent.GetHeight = function() return 1080 end
mm.GetCenter = function() return 1800, 900 end
mm.scripts.OnClick(mm, "LeftButton")
local qm = CharadesMinimapMenu
check("quick menu opens", qm and qm.shown and CharadesMinimapMenuCatcher.shown)
local function rowWith(frame, text) for _, r in ipairs(frame.rows) do if r.shown and r.entry and r.entry.label == text then return r end end end
check("quick menu entries", rowWith(qm, "Open Charades") and rowWith(qm, "Settings") and rowWith(qm, "Favorites") and rowWith(qm, ns.data.categories[1].title))
local sm = CharadesMinimapSubmenu
local firstFav = rowWith(qm, ns.LabelFor(ns.data.favorites[1]))
check("favorites listed directly", firstFav ~= nil and firstFav.entry.kind == "action" and rowWith(qm, "Favorites").entry.kind == "title")
local before = #log
firstFav.scripts.OnClick(firstFav)
check("favorite runs and closes", #log > before and not qm.shown and not CharadesMinimapMenuCatcher.shown)
mm.scripts.OnClick(mm, "LeftButton")
local catRow = rowWith(qm, ns.data.categories[2].title)
catRow.scripts.OnEnter(catRow)
check("submenu side fixed for the menu", qm.submenuSide == "LEFT")
check("category submenu", sm.shown and rowWith(sm, ns.data.categories[2].items[1].label) ~= nil)
local subItem = rowWith(sm, ns.data.categories[2].items[1].label)
before = #log
subItem.scripts.OnClick(subItem)
check("submenu item runs and closes", #log > before and not qm.shown and not sm.shown)
mm.scripts.OnClick(mm, "LeftButton")
CharadesMinimapMenuCatcher.scripts.OnMouseDown(CharadesMinimapMenuCatcher)
check("click outside closes", not qm.shown)
mm.scripts.OnClick(mm, "LeftButton"); rowWith(qm, "Open Charades").scripts.OnClick()
check("open charades", CharadesPanel.shown and not qm.shown)
Charades_Toggle()
mm.scripts.OnClick(mm, "RightButton"); check("right-click opens window", CharadesPanel.shown)
Charades_Toggle()

-- wheel: favorites open by default, fanned around the top node
table.insert(ns.data.favorites, "Ahoj"); ns.RefreshAll()
local function at(angle, r) cursor = { 500 + math.cos(math.rad(angle)) * r, 400 + math.sin(math.rad(angle)) * r }; CharadesWheel.scripts.OnUpdate(CharadesWheel) end
cursor = { 500, 400 }
Charades_Wheel("down")
check("favorites open by default", CharadesWheel.center.text == "Favorites")
check("wheel opens below cursor", CharadesWheel.cx == 500 and CharadesWheel.cy < 400)
at(102, 400); check("fan item 1 (up-left)", CharadesWheel.center.text == "Řev")
at(78, 400); check("fan item 2 (up-right)", CharadesWheel.center.text == "Ahoj")
at(-90, 400); check("away from fan selects nothing", CharadesWheel.center.text == "Favorites")
at(78, 400); Charades_Wheel("up"); check("wheel release runs", last() == "SAY:Ahoj" and CharadesWheel.shown == false)
-- switch category by pointing at its node
Charades_Wheel("down")
local node
for _, w in ipairs(all) do local l = rawget(w, "label"); if rawget(w, "x") and l and l.text == "Moje" and w.shown then node = w end end
cursor = { 500 + node.x, 400 + node.y }; CharadesWheel.scripts.OnUpdate(CharadesWheel)
check("hover opens category", CharadesWheel.center.text == "Moje")
at(node.angle, 400); check("category item selected", CharadesWheel.center.text == "Řev")
Charades_Wheel("up"); check("category item runs", last() == "EMOTE:ROAR")
Charades_Wheel("down"); at(0, 5); Charades_Wheel("up")
check("dead zone does nothing", last() == "EMOTE:ROAR")
-- right-click cancels (default on), anywhere
local catcherW = CharadesWheelCatcher
Charades_Wheel("down"); at(78, 400)
check("catcher shown with wheel", catcherW.shown)
local before = #log
catcherW.scripts.OnMouseDown(catcherW, "RightButton")
check("right-click cancels", not CharadesWheel.shown and not catcherW.shown and #log == before)
Charades_Wheel("up"); check("release after cancel does nothing", #log == before)
ns.db.wheelRightClickCancels = false
Charades_Wheel("down"); at(78, 400); catcherW.scripts.OnMouseDown(catcherW, "RightButton")
check("right-click ignored when off", CharadesWheel.shown)
Charades_Wheel("up"); check("release still runs", last() == "SAY:Ahoj")
ns.db.wheelRightClickCancels = true
-- click to confirm mode
ns.db.wheelConfirmClick = true
before = #log
Charades_Wheel("down"); at(78, 400); Charades_Wheel("up")
check("confirm mode: release closes without running", not CharadesWheel.shown and #log == before)
Charades_Wheel("down"); at(78, 400)
catcherW.scripts.OnMouseDown(catcherW, "LeftButton")
check("confirm mode: left click while holding runs", last() == "SAY:Ahoj" and not CharadesWheel.shown)
before = #log
Charades_Wheel("up")
check("confirm mode: release after click does nothing more", #log == before)
ns.db.wheelConfirmClick = false

Charades_RunFavorite(1); check("favorite binding", last() == "EMOTE:ROAR")
Charades_RunFavorite(9); check("empty favorite binding", last() == "EMOTE:ROAR")

-- editor, picker, add free text item
ns.OpenEditor()
local ed = ns.editor
ed.categoryRows[3].scripts.OnClick(ed.categoryRows[3]) -- "Moje"
ed.pickerButton.scripts.OnClick()
CharadesEmotePicker.search:SetText("sil")
CharadesEmotePicker.search.scripts.OnEnterPressed(CharadesEmotePicker.search)
check("picker fills", ed.actionInput.text == "/silly" and ed.labelInput.text == "silly")
ed.addButton.scripts.OnClick()
ed.labelInput:SetText(""); ed.actionInput:SetText("Zdravím, poutníku! Jak se máš dnes večer?")
ed.addButton.scripts.OnClick()
local items = ns.data.categories[2].items
check("free text item", items[3].action:find("Zdravím") and items[3].label == "Zdravím, poutníku! Ja...")

-- icons in editor: pick recommended for new item, remove icon from category
ed.itemIconButton.scripts.OnClick(ed.itemIconButton, "LeftButton")
CharadesIconPicker.search:SetText("sleep")
local cell
for _, w in ipairs(all) do if rawget(w, "icon") == "@sleep" and rawget(w, "texture") and w.shown then cell = w end end
cell.scripts.OnClick(cell)
ed.labelInput:SetText("Chrupkat"); ed.actionInput:SetText("/sleep")
ed.addButton.scripts.OnClick()
check("item icon saved", ns.data.categories[2].items[4].icon == "@sleep")
ed.itemIconButton.scripts.OnClick(ed.itemIconButton, "LeftButton")
CharadesIconPicker.custom:SetText("12345"); CharadesIconPicker.custom.scripts.OnEnterPressed(CharadesIconPicker.custom)
check("custom file id", ns.editor and true)
ed.labelInput:SetText("Vlastní"); ed.actionInput:SetText("/wave"); ed.addButton.scripts.OnClick()
check("numeric icon saved", ns.data.categories[2].items[5].icon == 12345)
ed.categoryIconButton.scripts.OnClick(ed.categoryIconButton, "LeftButton")
for _, w in ipairs(all) do if w.text == "No icon" then w.scripts.OnClick(w) end end
check("category icon removed", ns.data.categories[2].icon == false)

-- drag and drop in the editor
local function rowCenter(row, upper) local top, bottom = row:GetTop(), row:GetBottom(); return (row:GetLeft() + row:GetRight()) / 2, upper and (top - 3) or (bottom + 3) end
local function dragTo(src, x, y) src.scripts.OnDragStart(src); cursor = { x, y }; ed.scripts.OnUpdate(ed); src.scripts.OnDragStop(src) end
ed.categoryRows[3].scripts.OnClick(ed.categoryRows[3]) -- Moje
local moje = ns.data.categories[2]
local savedMoje, savedGreet, savedFav = {}, {}, {}
for i, v in ipairs(moje.items) do savedMoje[i] = v end
for i, v in ipairs(ns.data.categories[1].items) do savedGreet[i] = v end
for i, v in ipairs(ns.data.favorites) do savedFav[i] = v end
local a1, a2, a3 = moje.items[1].action, moje.items[2].action, moje.items[3].action
local tx, ty = rowCenter(ed.itemRows[3], false)
dragTo(ed.itemRows[1], tx, ty)
check("drag reorder items", moje.items[1].action == a2 and moje.items[2].action == a3 and moje.items[3].action == a1)
local gx, gy = rowCenter(ed.categoryRows[2], true)
local movedAction = moje.items[1].action
dragTo(ed.itemRows[1], gx, gy)
check("drag item to other category", ns.data.categories[1].items[#ns.data.categories[1].items].action == movedAction and moje.items[1].action ~= movedAction)
local fx, fy = rowCenter(ed.categoryRows[1], true)
local favAction = moje.items[1].action
local wasFav = ns.IsFavorite(favAction)
dragTo(ed.itemRows[1], fx, fy)
check("drag item to favorites", wasFav or ns.IsFavorite(favAction))
local cx2, cy2 = rowCenter(ed.categoryRows[2], true)
dragTo(ed.categoryRows[3], cx2, cy2)
check("drag reorder categories", ns.data.categories[1] == moje and state_ok ~= false)
check("selection follows category", ed.listTitle.text == "Moje")
dragTo(ed.itemRows[1], 5000, 5000)
check("drop outside cancels", ns.data.categories[1] == moje)
-- move Moje back to position 2 for the rest of the tests
local bx, by = rowCenter(ed.categoryRows[3], false)
dragTo(ed.categoryRows[2], bx, by)
check("drag category down", ns.data.categories[2] == moje)
moje.items = savedMoje; ns.data.categories[1].items = savedGreet; ns.data.favorites = savedFav; ns.RefreshAll()

-- icon search in "All": file IDs only
GetMacroIcons = function(t) for _, id in ipairs({ 136000, 136001, 237000, 999 }) do table.insert(t, id) end end
ed.itemIconButton.scripts.OnClick(ed.itemIconButton, "LeftButton")
local allTab
for _, w in ipairs(all) do if w.text == "All" then allTab = w end end
allTab.scripts.OnClick(allTab)
local function visibleCells() local n = 0 for _, w in ipairs(all) do if rawget(w, "texture") and rawget(w, "icon") ~= nil and w.shown and rawget(w, "parent") == CharadesIconPicker then n = n + 1 end end return n end
CharadesIconPicker.search:SetText("")
check("all tab lists ids", visibleCells() == 4)
CharadesIconPicker.search:SetText("1360")
check("all tab numeric search", visibleCells() == 2)
CharadesIconPicker.search:SetText("sleep")
check("all tab text falls back to game icons", visibleCells() >= 1 and CharadesIconPicker.info.text:find("Game icons") ~= nil)
local gameTab
for _, w in ipairs(all) do if w.text == "Game" then gameTab = w end end
gameTab.scripts.OnClick(gameTab)
CharadesIconPicker.search:SetText("")
check("game tab has thousands", CharadesIconPicker.info.text:match("^(%d+)") and tonumber(CharadesIconPicker.info.text:match("^(%d+)")) > 4000)
CharadesIconPicker.search:SetText("food")
local foodCount = tonumber(CharadesIconPicker.info.text:match("^(%d+)"))
check("game search by word", foodCount and foodCount > 20)
CharadesIconPicker.search:SetText("misc food 1")
check("game search multiple words", tonumber(CharadesIconPicker.info.text:match("^(%d+)")) < foodCount)
CharadesIconPicker:Hide()

-- profiles
local profileCheck
for _, w in ipairs(all) do if rawget(w, "parent") == ns.generalPage and rawget(w, "get") == ns.IsUsingOwnProfile then profileCheck = w end end
profileCheck.checked = true; profileCheck.scripts.OnClick(profileCheck)
check("own profile copied", ns.data ~= CharadesDB.shared and #ns.data.categories[2].items == 5)
table.remove(ns.data.categories, 1)
check("isolated", #CharadesDB.shared.categories == #ns.data.categories + 1)
profileCheck.checked = false; profileCheck.scripts.OnClick(profileCheck)
check("back to shared", ns.data == CharadesDB.shared and CharadesCharDB.data ~= nil)

-- export/import roundtrip
local text = ns.ExportData(ns.data)
local back = ns.ImportData(text)
check("export is JSON", text:sub(1, 1) == "{" and text:find('"format": "charades"', 1, true) ~= nil and text:find("\n", 1, true) ~= nil)
check("export has no raw pipes", text:find("|", 1, true) == nil)
-- a pipe typed into an edit box comes back doubled
local piped = ns.ImportData((text:gsub('"format"', '"format"')):gsub("\\u007c", "||"))
check("import tolerates doubled pipes", piped ~= nil)
check("old CHARADES1 format is rejected", ns.ImportData("CHARADES1:Q0hBUkFERVM=") == nil)
check("icon roundtrip", back and back.categories[2].items[4].icon == "@sleep" and back.categories[2].items[5].icon == 12345 and back.categories[1].icon == "@group" and back.categories[2].icon == false)
check("roundtrip", back and #back.categories == #ns.data.categories and back.categories[2].items[3].action == ns.data.categories[2].items[3].action and back.favorites[2] == "Ahoj" and back.categories[1].defaultId == "greetings")
local bad, msg = ns.ImportData("hello"); check("bad import", bad == nil and msg ~= nil)
ns.ShowImport(); CharadesTransfer.input:SetText(text)
-- find import button
local importBtn
for _, w in ipairs(all) do if w.text == "Import" then importBtn = w end end
importBtn.scripts.OnClick(importBtn)
check("import popup", popup and popup.name == "CHARADES_IMPORT")
StaticPopupDialogs.CHARADES_IMPORT.OnAccept(nil, popup.data)
check("import applied", ns.data == CharadesDB.shared and ns.data.categories[2].items[3] ~= nil)

-- reset
StaticPopupDialogs.CHARADES_RESET.OnAccept()
check("reset", #ns.data.categories == 5 and ns.data.favorites[1] == "/sit" and ns.data.categories[1].title == "Social" and ns.data.categories[3].title == "Rest" and #ns.data.categories[3].items == 6)
-- fresh install
CharadesDB = nil; CharadesCharDB = nil; ns.InitDatabase()
check("fresh defaults", #ns.data.categories == 5 and ns.data.categories[2].items[1].action == "/dance" and ns.data.version == 8 and ns.data.categories[2].items[1].label == "Dance" and ns.data.categories[2].items[1].icon == "@dance")
-- v3 data gets default icons once, but keeps removed ones removed afterwards
CharadesDB = { shared = { version = 3, favorites = {}, categories = { { title = "Nálady", defaultId = "moods", items = { { label = "T", action = "/dance" }, { label = "X", action = "/custom" } } } } } }
CharadesCharDB = nil; ns.InitDatabase()
check("v3 -> v7 icons", ns.data.categories[1].items[1].icon == "@dance" and ns.data.categories[1].items[2].icon == nil and ns.data.version == 8)
check("custom label kept", ns.data.categories[1].items[1].label == "T" and ns.data.categories[1].title == "Moods")
ns.data.categories[1].items[1].icon = false; ns.InitDatabase()
check("removed icon stays removed", ns.data.categories[1].items[1].icon == false)
-- v5 data: unchanged old game icons become bundled icons, changed ones stay
CharadesDB = { shared = { version = 5, favorites = {}, categories = { { title = "Moods", defaultId = "moods", icon = "Spell_Shadow_Charm", items = { { label = "Dance", action = "/dance", icon = "Spell_Nature_Lightning" }, { label = "Cry", action = "/cry", icon = "INV_Misc_Fish_02" } } } } } }
CharadesCharDB = nil; ns.InitDatabase()
local m = ns.data.categories[1]
check("v5 -> v6 icon upgrade", m.icon == "@smile" and m.items[1].icon == "@dance" and m.items[2].icon == "INV_Misc_Fish_02")
-- v6 data: new categories and new items are added, user's own items and deletions elsewhere stay
CharadesDB = { shared = { version = 6, favorites = {}, categories = {
  { title = "Greetings", defaultId = "greetings", items = { { label = "Wave", action = "/wave" }, { label = "Hi!", action = "/hello" } } },
  { title = "Mine", items = { { label = "X", action = "/x" } } } } } }
CharadesCharDB = nil; ns.InitDatabase()
local g = ns.data.categories[1]
local actions = {}
for _, item in ipairs(g.items) do actions[#actions + 1] = item.action end
check("v7 adds new items once", #g.items == 3 and g.items[2].label == "Hi!" and actions[3] == "/curtsey")
check("v7 adds new categories", #ns.data.categories == 4 and ns.data.categories[3].defaultId == "reactions" and ns.data.categories[4].defaultId == "signals" and ns.data.categories[4].collapsed == true)
check("v7 does not re-add other/moods", ns.data.categories[2].title == "Mine")
ns.InitDatabase(); check("v7 idempotent", #ns.data.categories[1].items == 3 and #ns.data.categories == 4)
check("bundled icon path", ns.IconPath("@wave") == "Interface\\AddOns\\Charades\\Icons\\wave")
-- key bindings page
check("subcategory registered", subpage ~= nil)
local generalChecks = 0
for _, w in ipairs(all) do if rawget(w, "parent") == ns.generalPage and rawget(w, "get") then generalChecks = generalChecks + 1 end end
check("general page has 6 options", generalChecks == 6)
ns.generalPage:Show()
local hideCheck
for _, w in ipairs(all) do if rawget(w, "parent") == ns.generalPage and rawget(w, "get") and w.get() == false and w.checked == false then hideCheck = w end end
check("general page shows current values", hideCheck ~= nil)
subpage:Show()
local wheelBtn
for _, w in ipairs(all) do if rawget(w, "command") == "CHARADES_WHEEL" then wheelBtn = w end end
bindings["G"] = "SOMETHING_ELSE"; _G.BINDING_NAME_SOMETHING_ELSE = "Other thing"
GetCurrentKeyBoardFocus = function() return nil end
wheelBtn.scripts.OnClick(wheelBtn, "LeftButton")
local catcherFrame = CharadesKeyCatcher
check("capture overlay shown", catcherFrame and catcherFrame.shown and wheelBtn.text:find("Waiting") ~= nil)
catcherFrame.scripts.OnKeyDown(catcherFrame, "LSHIFT")
mods.shift = true; catcherFrame.scripts.OnKeyDown(catcherFrame, "G"); mods.shift = false
check("binding set with modifier", bindings["SHIFT-G"] == "CHARADES_WHEEL" and saved == 1 and wheelBtn.text == "SHIFT-G" and not catcherFrame.shown)
wheelBtn.scripts.OnClick(wheelBtn, "LeftButton"); catcherFrame.scripts.OnKeyDown(catcherFrame, "G")
check("rebinding replaces and reports", bindings["G"] == "CHARADES_WHEEL" and bindings["SHIFT-G"] == nil and subpage.status.text:find("Other thing") ~= nil)
wheelBtn.scripts.OnClick(wheelBtn, "LeftButton"); catcherFrame.scripts.OnKeyDown(catcherFrame, "ESCAPE")
check("escape cancels", bindings["G"] == "CHARADES_WHEEL" and wheelBtn.text == "G" and not catcherFrame.shown)
wheelBtn.scripts.OnClick(wheelBtn, "LeftButton"); catcherFrame.scripts.OnMouseDown(catcherFrame, "Button4")
check("mouse button", bindings["BUTTON4"] == "CHARADES_WHEEL")
wheelBtn.scripts.OnClick(wheelBtn, "LeftButton"); catcherFrame.scripts.OnMouseDown(catcherFrame, "LeftButton")
check("left click cancels", not catcherFrame.shown and bindings["BUTTON4"] == "CHARADES_WHEEL")
wheelBtn.scripts.OnClick(wheelBtn, "RightButton")
check("right-click clears", GetBindingKey("CHARADES_WHEEL") == nil and wheelBtn.text:find("Not bound") ~= nil)
InCombatLockdown = function() return true end
wheelBtn.scripts.OnClick(wheelBtn, "LeftButton")
check("combat refused", subpage.status.text:find("combat") ~= nil)
InCombatLockdown = function() return false end
-- no FAIL lines expected
