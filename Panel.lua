local _, ns = ...

-- Main menu: fixed-size, resizable window. Title, view switches and search stay on top;
-- the list below scrolls (mouse wheel or scroll bar) and its columns follow the window width.

local BUTTON_MIN_WIDTH = 104
local BUTTON_HEIGHT = 22
local SPACING = 4
local PADDING = 18
local HEADER_TOP = -70 -- where the scrolling area starts
local SCROLLBAR_WIDTH = 10
local BOTTOM_MARGIN = 26 -- room for the resize grip
local WHEEL_STEP = 3 * (BUTTON_HEIGHT + SPACING)

local DEFAULT_WIDTH, DEFAULT_HEIGHT = 520, 470
local MIN_WIDTH, MIN_HEIGHT = 300, 220
local MAX_WIDTH, MAX_HEIGHT = 1400, 1100

local panel, content, scrollFrame, scrollBar
local pools = {}
local searchResults = {}
local layout = { columns = 4, buttonWidth = 112, width = 460 }

-- Widget pool ----------------------------------------------------------------

local function ResetPools()
    for _, pool in pairs(pools) do
        pool.used = 0
    end
end

local function Acquire(name, create)
    local pool = pools[name]
    if not pool then
        pool = { items = {}, used = 0 }
        pools[name] = pool
    end
    pool.used = pool.used + 1
    local item = pool.items[pool.used]
    if not item then
        item = create()
        pool.items[pool.used] = item
    end
    item:ClearAllPoints()
    item:Show()
    return item
end

local function ReleaseUnused()
    for _, pool in pairs(pools) do
        for index = pool.used + 1, #pool.items do
            pool.items[index]:Hide()
        end
    end
end

-- Buttons ----------------------------------------------------------------------

local function ItemTooltipLines(self)
    local lines = { "|cff999999" .. self.action .. "|r", "Left-click: use" }
    if ns.IsFavorite(self.action) then
        table.insert(lines, "Right-click: remove from favorites")
    else
        table.insert(lines, "Right-click: add to favorites")
    end
    return lines
end

local function OnItemClick(self, mouseButton)
    if mouseButton == "RightButton" then
        local added = ns.ToggleFavorite(self.action)
        ns.Print((added and "added to favorites: " or "removed from favorites: ") .. ns.LabelFor(self.action))
        ns.RefreshAll()
        return
    end
    ns.PerformAction(self.action)
end

local function CreateMenuFavoriteButton()
    local button = ns.CreateFavoriteButton(content, layout.buttonWidth, BUTTON_HEIGHT)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", OnItemClick)
    ns.AddTooltip(button, function(self) return self.labelText end, ItemTooltipLines)
    return button
end

local function CreateCategoryButton()
    local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    button:SetSize(layout.buttonWidth, BUTTON_HEIGHT)
    button:SetNormalFontObject(ns.fonts.button)
    button:SetHighlightFontObject(ns.fonts.buttonHighlight)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetSize(ns.ICON_SIZE, ns.ICON_SIZE)
    icon:SetPoint("LEFT", 6, 0)
    button.icon = icon

    -- Small star: this item is also in favorites
    local star = button:CreateTexture(nil, "OVERLAY")
    star:SetTexture(ns.STAR_TEXTURE)
    star:SetSize(10, 10)
    star:SetPoint("TOPRIGHT", -3, -3)
    star:SetAlpha(0.8)
    button.star = star

    button:SetScript("OnClick", OnItemClick)
    ns.AddTooltip(button, function(self) return self.labelText end, ItemTooltipLines)
    return button
end

local function CreateCategoryHeader()
    local header = CreateFrame("Button", nil, content)
    header:SetHeight(18)

    local icon = header:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT")
    header.icon = icon

    local categoryIcon = header:CreateTexture(nil, "ARTWORK")
    categoryIcon:SetSize(ns.ICON_SIZE, ns.ICON_SIZE)
    categoryIcon:SetPoint("LEFT", 18, 0)
    header.categoryIcon = categoryIcon

    local text = header:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(ns.fonts.header)
    header.label = text

    local highlight = header:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.06)

    header:SetScript("OnClick", function(self)
        self.category.collapsed = not self.category.collapsed
        ns.RefreshPanel()
    end)
    return header
end

local function CreateSmallText()
    local text = content:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(ns.fonts.small)
    text:SetJustifyH("LEFT")
    return text
end

local function CreateGoldText()
    local text = content:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(ns.fonts.gold)
    return text
end

local function CreateStar()
    local star = content:CreateTexture(nil, "OVERLAY")
    star:SetTexture(ns.STAR_TEXTURE)
    star:SetSize(14, 14)
    return star
end

local function CreateBand()
    return content:CreateTexture(nil, "BACKGROUND", nil, 1)
end

-- Layout -----------------------------------------------------------------------

local function UpdateLayout()
    local width = math.max(100, scrollFrame:GetWidth())
    local columns = math.max(1, math.floor((width + SPACING) / (BUTTON_MIN_WIDTH + SPACING)))
    layout.width = width
    layout.columns = columns
    layout.buttonWidth = math.floor((width - (columns - 1) * SPACING) / columns)
end

-- entries: { { label, action, icon, favorite = bool } }
local function LayoutGrid(entries, y)
    for index, entry in ipairs(entries) do
        local column = (index - 1) % layout.columns
        local row = math.floor((index - 1) / layout.columns)
        local button
        if entry.favorite then
            button = Acquire("favorite", CreateMenuFavoriteButton)
            ns.SetFavoriteButtonContent(button, entry.label, entry.icon)
        else
            button = Acquire("category", CreateCategoryButton)
            button:SetText(entry.label)
            -- Fixed text area: the icon slot is reserved even when this item has no icon
            local text = button:GetFontString()
            text:ClearAllPoints()
            text:SetPoint("LEFT", ns.TextOffset(6), 0)
            text:SetPoint("RIGHT", -8, 0)
            text:SetWordWrap(false)
            ns.SetIcon(button.icon, entry.icon)
            button.star:SetShown(ns.IsFavorite(entry.action))
        end
        button:SetWidth(layout.buttonWidth)
        button.action = entry.action
        button.labelText = entry.label
        button:SetPoint("TOPLEFT", column * (layout.buttonWidth + SPACING), y - row * (BUTTON_HEIGHT + SPACING))
    end
    return y - math.ceil(#entries / layout.columns) * (BUTTON_HEIGHT + SPACING)
end

local function AddHint(y, text)
    local hint = Acquire("smallText", CreateSmallText)
    hint:SetPoint("TOPLEFT", 0, y)
    hint:SetWidth(layout.width)
    hint:SetText(text)
    return y - 20
end

local function AddGoldHeader(y, text, withStar)
    local header = Acquire("goldText", CreateGoldText)
    header:SetPoint("TOPLEFT", withStar and 16 or 0, y)
    header:SetText(text)
    if withStar then
        local star = Acquire("star", CreateStar)
        star:SetPoint("RIGHT", header, "LEFT", -3, 0)
    end
    return y - 20
end

local function FavoriteEntries()
    local entries = {}
    for _, action in ipairs(ns.data.favorites) do
        table.insert(entries, { label = ns.LabelFor(action), action = action, icon = ns.IconFor(action), favorite = true })
    end
    return entries
end

-- Search goes through favorites and all categories, each action listed once
local function SearchEntries(query)
    local folded = ns.Fold(query)
    local entries, seen = {}, {}
    local function Consider(label, action, icon, favorite)
        if seen[action] then
            return
        end
        if string.find(ns.Fold(label), folded, 1, true) or string.find(ns.Fold(action), folded, 1, true) then
            seen[action] = true
            table.insert(entries, { label = label, action = action, icon = icon, favorite = favorite })
        end
    end
    for _, action in ipairs(ns.data.favorites) do
        Consider(ns.LabelFor(action), action, ns.IconFor(action), true)
    end
    for _, category in ipairs(ns.data.categories) do
        for _, item in ipairs(category.items) do
            Consider(item.label, item.action, item.icon, false)
        end
    end
    return entries
end

local function AddFavoritesSection(y)
    local top = y + 4
    y = AddGoldHeader(y, "Favorites", true)
    if #ns.data.favorites == 0 then
        y = AddHint(y, "Right-click an item in a category to add it here.")
    else
        y = LayoutGrid(FavoriteEntries(), y)
    end
    local band = Acquire("band", CreateBand)
    band:SetColorTexture(1, 0.82, 0, 0.10)
    band:SetPoint("TOPLEFT", content, "TOPLEFT", -6, top)
    band:SetPoint("BOTTOMRIGHT", content, "TOPRIGHT", 4, y - 2)
    return y - 14
end

local function AddCategories(y)
    for _, category in ipairs(ns.data.categories) do
        local header = Acquire("header", CreateCategoryHeader)
        header.category = category
        header:SetWidth(layout.width)
        header:SetPoint("TOPLEFT", 0, y)
        header.icon:SetTexture(category.collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
        ns.SetIcon(header.categoryIcon, category.icon)
        header.label:ClearAllPoints()
        header.label:SetPoint("LEFT", ns.TextOffset(18), 0)
        header.label:SetText(category.title .. "  |cff999999(" .. #category.items .. ")|r")
        y = y - 20

        if not category.collapsed and #category.items > 0 then
            local entries = {}
            for _, item in ipairs(category.items) do
                table.insert(entries, { label = item.label, action = item.action, icon = item.icon })
            end
            y = LayoutGrid(entries, y)
        end
        y = y - 6
    end
    return y
end

local function AddSearchResults(y, query)
    searchResults = SearchEntries(query)
    y = AddGoldHeader(y, "Results  |cff999999(" .. #searchResults .. ")|r")
    if #searchResults == 0 then
        return AddHint(y, "Nothing found.")
    end
    return LayoutGrid(searchResults, y)
end

-- All emotes view ----------------------------------------------------------------

local allEmoteEntries -- built once from the client's emote list

local function BuildAllEmoteEntries()
    allEmoteEntries = {}
    local labelByAction, iconByAction = {}, {}
    for _, category in ipairs(ns.DefaultCategories) do
        for _, item in ipairs(category.items) do
            labelByAction[item.action] = labelByAction[item.action] or item.label
            iconByAction[item.action] = iconByAction[item.action] or item.icon
        end
    end
    local customIcon = {}
    for _, entry in ipairs(ns.CustomIcons) do
        customIcon[entry[1]] = "@" .. entry[1]
    end

    for _, emote in ipairs(ns.GetEmoteList()) do
        local name = string.sub(emote.command, 2)
        local animated = false
        for _, alias in ipairs(emote.aliases or { emote.command }) do
            if ns.AnimatedEmoteCommands[alias] then
                animated = true
            end
        end
        table.insert(allEmoteEntries, {
            action = emote.command,
            label = labelByAction[emote.command] or (string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)),
            icon = iconByAction[emote.command] or customIcon[name],
            animated = animated,
            search = ns.Fold(table.concat(emote.aliases or { emote.command }, " ") .. " " .. (labelByAction[emote.command] or "")),
        })
    end
    table.sort(allEmoteEntries, function(a, b) return a.label < b.label end)
end

local function AddAllEmotes(y, query)
    if not allEmoteEntries then
        BuildAllEmoteEntries()
    end
    local folded = ns.Fold(query)
    local entries = {}
    for _, entry in ipairs(allEmoteEntries) do
        if (not ns.db.animatedOnly or entry.animated)
            and (folded == "" or string.find(entry.search, folded, 1, true) or string.find(ns.Fold(entry.label), folded, 1, true)) then
            table.insert(entries, { label = entry.label, action = entry.action, icon = entry.icon })
        end
    end
    searchResults = entries
    y = AddGoldHeader(y, (ns.db.animatedOnly and "Animated emotes" or "All emotes") .. "  |cff999999(" .. #entries .. ")|r")
    if #entries == 0 then
        return AddHint(y, "Nothing found.")
    end
    return LayoutGrid(entries, y)
end

-- Scrolling ----------------------------------------------------------------------

local function MaxScroll()
    return math.max(0, content:GetHeight() - scrollFrame:GetHeight())
end

local function UpdateScrollBar()
    local maximum = MaxScroll()
    local current = math.min(scrollFrame:GetVerticalScroll(), maximum)
    scrollFrame:SetVerticalScroll(current)
    if maximum <= 0 then
        scrollBar:Hide()
        return
    end
    scrollBar:Show()
    local trackHeight = scrollBar:GetHeight()
    local visible = scrollFrame:GetHeight() / content:GetHeight()
    local thumbHeight = math.max(24, trackHeight * visible)
    scrollBar.thumb:SetHeight(thumbHeight)
    scrollBar.thumb:ClearAllPoints()
    scrollBar.thumb:SetPoint("TOP", scrollBar, "TOP", 0, -(trackHeight - thumbHeight) * current / maximum)
end

local function ScrollTo(value)
    scrollFrame:SetVerticalScroll(math.max(0, math.min(value, MaxScroll())))
    UpdateScrollBar()
end

local function CreateScrollBar()
    scrollBar = CreateFrame("Frame", nil, panel)
    scrollBar:SetWidth(SCROLLBAR_WIDTH)
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 0)
    scrollBar:EnableMouse(true)

    local track = scrollBar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0, 0, 0, 0.45)

    local thumb = CreateFrame("Button", nil, scrollBar)
    thumb:SetWidth(SCROLLBAR_WIDTH)
    local thumbTexture = thumb:CreateTexture(nil, "ARTWORK")
    thumbTexture:SetAllPoints()
    thumbTexture:SetColorTexture(1, 0.82, 0, 0.6)
    local thumbHighlight = thumb:CreateTexture(nil, "HIGHLIGHT")
    thumbHighlight:SetAllPoints()
    thumbHighlight:SetColorTexture(1, 1, 1, 0.25)
    scrollBar.thumb = thumb

    -- Drag the thumb
    thumb:SetScript("OnMouseDown", function(self)
        local _, cursorY = GetCursorPosition()
        self.dragStartY = cursorY / self:GetEffectiveScale()
        self.dragStartScroll = scrollFrame:GetVerticalScroll()
        self:SetScript("OnUpdate", function()
            local _, y = GetCursorPosition()
            y = y / self:GetEffectiveScale()
            local travel = scrollBar:GetHeight() - self:GetHeight()
            if travel > 0 then
                ScrollTo(self.dragStartScroll + (self.dragStartY - y) / travel * MaxScroll())
            end
        end)
    end)
    thumb:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)

    -- Click the track to jump a page
    scrollBar:SetScript("OnMouseDown", function(self)
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / self:GetEffectiveScale()
        local page = scrollFrame:GetHeight() - BUTTON_HEIGHT
        if cursorY > thumb:GetTop() then
            ScrollTo(scrollFrame:GetVerticalScroll() - page)
        elseif cursorY < thumb:GetBottom() then
            ScrollTo(scrollFrame:GetVerticalScroll() + page)
        end
    end)
end

-- Title bar ------------------------------------------------------------------------

local function UpdateTitleButtons()
    local allView = ns.db.panelView == "all"
    panel.title:SetText(allView and "All emotes" or "Charades")
    panel.viewButton.border:SetShown(allView)
    panel.filterButton:SetShown(allView)
    local on = ns.db.animatedOnly
    panel.filterButton.border:SetShown(on)
    panel.filterButton.texture:SetDesaturated(not on)
    panel.filterButton.texture:SetAlpha(on and 1 or 0.45)
end

local function CreateTitleIconButton(icon)
    local button = CreateFrame("Button", nil, panel)
    button:SetSize(20, 20)
    button.texture = button:CreateTexture(nil, "ARTWORK")
    button.texture:SetAllPoints()
    button.texture:SetTexture(ns.IconPath(icon))
    button.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.2)

    local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    border:SetBackdropBorderColor(1, 0.82, 0, 1)
    border:Hide()
    button.border = border
    return button
end

-- Refresh --------------------------------------------------------------------------

function ns.RefreshPanel()
    if not panel then
        return
    end
    ResetPools()
    UpdateLayout()
    UpdateTitleButtons()

    local query = strtrim(panel.search:GetText() or "")
    panel.searchPlaceholder:SetShown(query == "" and not panel.search:HasFocus())

    local y = 0
    if ns.db.panelView == "all" then
        y = AddAllEmotes(y, query)
    elseif query ~= "" then
        y = AddSearchResults(y, query)
    else
        searchResults = {}
        y = AddFavoritesSection(y)
        y = AddCategories(y)
    end

    ReleaseUnused()
    content:SetWidth(layout.width)
    content:SetHeight(math.max(1, -y + 4))
    UpdateScrollBar()
end

-- Window -------------------------------------------------------------------------------

local function SavePosition()
    local point, _, relativePoint, x, y = panel:GetPoint(1)
    ns.db.panelPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function SaveSize()
    ns.db.panelWidth = math.floor(panel:GetWidth() + 0.5)
    ns.db.panelHeight = math.floor(panel:GetHeight() + 0.5)
end

local function RestoreGeometry()
    panel:SetSize(ns.db.panelWidth or DEFAULT_WIDTH, ns.db.panelHeight or DEFAULT_HEIGHT)
    panel:ClearAllPoints()
    local position = ns.db.panelPosition
    if position then
        panel:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
    else
        panel:SetPoint("CENTER")
    end
end

local function CreateResizeGrip()
    local grip = CreateFrame("Button", nil, panel)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -8, 8)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() panel:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        panel:StopMovingOrSizing()
        SaveSize()
        SavePosition()
        ns.RefreshPanel()
    end)
    ns.AddTooltip(grip, "Resize", { "Drag to change the window size." })
end

local function CreateSearchBox()
    local search = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    search:SetHeight(20)
    search:SetPoint("TOPLEFT", PADDING + 6, -40)
    search:SetPoint("TOPRIGHT", -PADDING, -40)
    search:SetAutoFocus(false)
    search:SetFontObject(ns.fonts.buttonHighlight)
    search:SetMaxLetters(40)

    local placeholder = search:CreateFontString(nil, "OVERLAY")
    placeholder:SetFontObject(ns.fonts.small)
    placeholder:SetPoint("LEFT", 2, 0)
    placeholder:SetText("Search...  (Enter uses the first result)")
    panel.searchPlaceholder = placeholder

    search:SetScript("OnTextChanged", function()
        ns.RefreshPanel()
        ScrollTo(0)
    end)
    search:SetScript("OnEditFocusGained", function() placeholder:Hide() end)
    search:SetScript("OnEditFocusLost", function() ns.RefreshPanel() end)
    search:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    search:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        local first = searchResults[1]
        if first then
            self:SetText("")
            ns.PerformAction(first.action)
        end
    end)
    return search
end

function ns.CreatePanel()
    panel = CreateFrame("Frame", "CharadesPanel", UIParent, "BackdropTemplate")
    panel:SetFrameStrata("DIALOG")
    ns.ApplyDialogBackdrop(panel)
    ns.MakeMovable(panel)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    panel:SetResizable(true)
    if panel.SetResizeBounds then
        panel:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
    else
        panel:SetMinResize(MIN_WIDTH, MIN_HEIGHT)
        panel:SetMaxResize(MAX_WIDTH, MAX_HEIGHT)
    end

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(ns.fonts.title)
    title:SetPoint("TOP", 0, -16)
    title:SetText("Charades")
    panel.title = title

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local settings = CreateFrame("Button", nil, panel)
    settings:SetSize(20, 20)
    settings:SetPoint("RIGHT", close, "LEFT", -2, 0)
    settings:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    settings:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton")
    settings:GetHighlightTexture():SetAlpha(0.4)
    settings:SetScript("OnClick", function() ns.OpenEditor() end)
    ns.AddTooltip(settings, "Options > AddOns > Charades", { "Edit items, categories and favorites" })

    -- View switch: your actions / every emote the game knows
    local viewButton = CreateTitleIconButton("@drama")
    viewButton:SetPoint("RIGHT", settings, "LEFT", -6, 0)
    viewButton:SetScript("OnClick", function()
        ns.db.panelView = ns.db.panelView == "all" and "mine" or "all"
        ns.RefreshPanel()
        ScrollTo(0)
    end)
    ns.AddTooltip(viewButton, function()
        return ns.db.panelView == "all" and "Show my actions" or "Show all emotes"
    end, { "Switch between your categories and every emote the game knows." })
    panel.viewButton = viewButton

    -- Animated-only filter, shown in the All emotes view
    local filterButton = CreateTitleIconButton("@dance")
    filterButton:SetPoint("RIGHT", viewButton, "LEFT", -6, 0)
    filterButton:SetScript("OnClick", function()
        ns.db.animatedOnly = not ns.db.animatedOnly
        ns.RefreshPanel()
        ScrollTo(0)
    end)
    ns.AddTooltip(filterButton, function()
        return ns.db.animatedOnly and "Animated only: on" or "Animated only: off"
    end, {
        "On: only emotes with an animation.",
        "Off: also emotes that only print text or play a sound.",
        "Based on the classic emote list; newer animated emotes may only show when off.",
    })
    panel.filterButton = filterButton

    panel.search = CreateSearchBox()

    -- Scrolling list area
    scrollFrame = CreateFrame("ScrollFrame", nil, panel)
    scrollFrame:SetPoint("TOPLEFT", PADDING, HEADER_TOP)
    scrollFrame:SetPoint("BOTTOMRIGHT", -(PADDING + SCROLLBAR_WIDTH + 6), BOTTOM_MARGIN)
    content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)
    CreateScrollBar()
    CreateResizeGrip()

    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        ScrollTo(scrollFrame:GetVerticalScroll() - delta * WHEEL_STEP)
    end)

    -- Re-flow columns while resizing
    panel:SetScript("OnSizeChanged", function()
        if panel:IsShown() then
            ns.RefreshPanel()
        end
    end)
    panel:SetScript("OnShow", function() ns.RefreshPanel() end)
    panel:SetScript("OnHide", function()
        panel.search:SetText("")
        panel.search:ClearFocus()
    end)

    RestoreGeometry()
    panel:Hide()
    table.insert(UISpecialFrames, "CharadesPanel")

    ns.panel = panel
end
