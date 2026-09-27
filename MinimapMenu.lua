local _, ns = ...

-- Dropdown shown by the minimap button: open the window, open the options, the favorites
-- (listed directly) and every category as a submenu. Clicking an item runs it.

local ROW_HEIGHT = 20
local MENU_WIDTH = 190
local SUBMENU_WIDTH = 200
local MAX_ROWS_PER_COLUMN = 20
local PADDING = 8

local catcher, menu, submenu
local openCategoryRow

-- Frames ---------------------------------------------------------------------------

local function CreateMenuFrame(name)
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(20)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    frame:EnableMouse(true)
    frame.rows = {}
    frame:Hide()
    return frame
end

local function AcquireRow(frame, index)
    local row = frame.rows[index]
    if row then
        return row
    end
    row = CreateFrame("Button", nil, frame)
    row:SetHeight(ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp")

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.12)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ns.ICON_SIZE, ns.ICON_SIZE)
    row.icon:SetPoint("LEFT", 4, 0)

    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)

    row.arrow = row:CreateFontString(nil, "OVERLAY")
    row.arrow:SetFontObject(ns.fonts.small)
    row.arrow:SetPoint("RIGHT", -6, 0)
    row.arrow:SetText(">")

    row.separator = row:CreateTexture(nil, "ARTWORK")
    row.separator:SetHeight(1)
    row.separator:SetPoint("LEFT", 4, 0)
    row.separator:SetPoint("RIGHT", -4, 0)
    row.separator:SetColorTexture(1, 1, 1, 0.2)

    frame.rows[index] = row
    return row
end

-- entries: { kind = "action" | "category" | "separator" | "title", label, icon, font, onClick, category }
local function Fill(frame, entries, width, onEnterRow)
    local columns = math.max(1, math.ceil(#entries / MAX_ROWS_PER_COLUMN))
    local perColumn = math.ceil(#entries / columns)
    for index, entry in ipairs(entries) do
        local row = AcquireRow(frame, index)
        local column = math.floor((index - 1) / perColumn)
        local line = (index - 1) % perColumn
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", PADDING + column * width, -PADDING - line * ROW_HEIGHT)
        row:SetWidth(width)
        row.entry = entry

        local isSeparator = entry.kind == "separator"
        row.separator:SetShown(isSeparator)
        row.label:SetShown(not isSeparator)
        row.arrow:SetShown(entry.kind == "category")
        row:EnableMouse(not isSeparator and entry.kind ~= "title")
        if isSeparator then
            ns.SetIcon(row.icon, nil)
        else
            ns.SetIcon(row.icon, entry.icon)
            row.label:SetFontObject(entry.font or ns.fonts.buttonHighlight)
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", ns.TextOffset(4), 0)
            row.label:SetPoint("RIGHT", entry.kind == "category" and -18 or -6, 0)
            row.label:SetText(entry.label)
        end
        row:SetScript("OnClick", entry.onClick)
        row:SetScript("OnEnter", function(self) onEnterRow(self) end)
        row:Show()
    end
    for index = #entries + 1, #frame.rows do
        frame.rows[index]:Hide()
    end
    frame:SetSize(PADDING * 2 + columns * width, PADDING * 2 + perColumn * ROW_HEIGHT)
end

-- Opening and closing -------------------------------------------------------------------

local closing = false

local function CloseMenu()
    if closing then
        return
    end
    closing = true
    openCategoryRow = nil
    if submenu then
        submenu:Hide()
    end
    if menu then
        menu:Hide()
    end
    if catcher then
        catcher:Hide()
    end
    closing = false
end

local function RunAndClose(action)
    CloseMenu()
    ns.RunAction(action)
end

local function ShowSubmenu(row)
    if openCategoryRow == row and submenu:IsShown() then
        return
    end
    openCategoryRow = row
    local source = row.entry.category
    local entries = {}
    if #source.entries == 0 then
        table.insert(entries, { kind = "title", label = "Empty", font = ns.fonts.small })
    end
    for _, item in ipairs(source.entries) do
        table.insert(entries, {
            kind = "action",
            label = item.label,
            icon = item.icon,
            font = source.favorite and ns.fonts.favorite or ns.fonts.buttonHighlight,
            onClick = function() RunAndClose(item.action) end,
        })
    end
    Fill(submenu, entries, SUBMENU_WIDTH, function() end)

    -- Always the same side for one opening of the menu (chosen in ToggleMinimapMenu)
    submenu:ClearAllPoints()
    if menu.submenuSide == "LEFT" then
        submenu:SetPoint("TOPRIGHT", row, "TOPLEFT", -PADDING, PADDING)
    else
        submenu:SetPoint("TOPLEFT", row, "TOPRIGHT", PADDING, PADDING)
    end
    submenu:Show()
end

local function BuildMainEntries()
    local entries = {
        { kind = "action", label = "Open Charades", onClick = function()
            CloseMenu()
            if ns.panel and not ns.panel:IsShown() then
                ns.panel:Show()
            end
        end },
        { kind = "action", label = "Settings", onClick = function()
            CloseMenu()
            ns.OpenEditor()
        end },
        { kind = "separator" },
    }

    -- Favorites are listed right here, ready to click; section headers are plain gold text
    table.insert(entries, { kind = "title", label = "Favorites", font = ns.fonts.gold })
    if #ns.data.favorites == 0 then
        table.insert(entries, { kind = "title", label = "No favorites yet", font = ns.fonts.small })
    end
    for _, action in ipairs(ns.data.favorites) do
        table.insert(entries, {
            kind = "action",
            label = ns.LabelFor(action),
            icon = ns.IconFor(action),
            font = ns.fonts.favorite,
            onClick = function() RunAndClose(action) end,
        })
    end
    table.insert(entries, { kind = "separator" })

    table.insert(entries, { kind = "title", label = "Categories", font = ns.fonts.gold })
    for _, category in ipairs(ns.data.categories) do
        local source = { title = category.title, entries = {} }
        for _, item in ipairs(category.items) do
            table.insert(source.entries, { label = item.label, action = item.action, icon = item.icon })
        end
        table.insert(entries, { kind = "category", label = category.title, icon = category.icon, category = source })
    end
    return entries
end

local function CreateFrames()
    catcher = CreateFrame("Frame", "CharadesMinimapMenuCatcher", UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(1)
    catcher:EnableMouse(true)
    catcher:SetScript("OnMouseDown", CloseMenu)
    catcher:Hide()

    menu = CreateMenuFrame("CharadesMinimapMenu")
    submenu = CreateMenuFrame("CharadesMinimapSubmenu")
    submenu:SetFrameLevel(30)
    menu:SetScript("OnHide", CloseMenu)
    -- Escape closes the dropdown
    table.insert(UISpecialFrames, "CharadesMinimapMenu")
end

function ns.ToggleMinimapMenu(anchor)
    if not catcher then
        CreateFrames()
    end
    if menu:IsShown() then
        CloseMenu()
        return
    end

    Fill(menu, BuildMainEntries(), MENU_WIDTH, function(row)
        if row.entry.kind == "category" then
            ShowSubmenu(row)
        else
            openCategoryRow = nil
            submenu:Hide()
        end
    end)

    -- Drop down (or up) from the button, towards the middle of the screen
    menu:ClearAllPoints()
    local x, y = anchor:GetCenter()
    local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
    local vertical = y > screenHeight / 2 and "TOP" or "BOTTOM"
    local horizontal = x > screenWidth / 2 and "RIGHT" or "LEFT"
    local anchorVertical = vertical == "TOP" and "BOTTOM" or "TOP"
    local anchorHorizontal = horizontal == "RIGHT" and "LEFT" or "RIGHT"
    menu:SetPoint(vertical .. horizontal, anchor, anchorVertical .. anchorHorizontal, 0, 0)
    -- Submenus open towards the middle of the screen, the same way for every category
    menu.submenuSide = horizontal == "RIGHT" and "LEFT" or "RIGHT"

    catcher:Show()
    menu:Show()
end

function ns.CloseMinimapMenu()
    CloseMenu()
end
