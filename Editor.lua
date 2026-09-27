local _, ns = ...

local LEFT_X, LEFT_WIDTH = 16, 200
local RIGHT_X, RIGHT_WIDTH = 232, 390
local CATEGORY_ROWS, CATEGORY_ROW_HEIGHT = 15, 22
local ITEM_ROWS, ITEM_ROW_HEIGHT = 12, 24
local LIST_TOP = -64
local FAVORITES = 0 -- pseudo category index shown at the top of the list

local editor
local state = {
    category = FAVORITES,
    item = nil,
    icon = nil, -- icon chosen in the item form

    categoryOffset = 0,
    itemOffset = 0,
}

local function SetStatus(message, isError)
    editor.status:SetText(message or "")
    if isError then
        editor.status:SetTextColor(1, 0.35, 0.35)
    else
        editor.status:SetTextColor(0.5, 1, 0.5)
    end
end

local function SelectedCategory()
    if state.category == FAVORITES then
        return nil
    end
    return ns.data.categories[state.category]
end

-- Right list: favorites (actions) or the selected category's items
local function CurrentList()
    local category = SelectedCategory()
    if category then
        return category.items
    end
    return ns.data.favorites
end

local function CreateTextButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetNormalFontObject(ns.fonts.button)
    button:SetHighlightFontObject(ns.fonts.buttonHighlight)
    button:SetDisabledFontObject(ns.fonts.small)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function CreateIconButton(parent, texture, size, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button:SetNormalTexture(texture)
    button:SetHighlightTexture(texture)
    button:GetHighlightTexture():SetAlpha(0.4)
    button:SetScript("OnClick", onClick)
    return button
end

-- Square button that previews an icon; empty slot shows a faded question mark
local function CreateIconPickerButton(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(24, 24)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(0, 0, 0, 0.6)
    button:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.texture = button:CreateTexture(nil, "ARTWORK")
    button.texture:SetPoint("TOPLEFT", 2, -2)
    button.texture:SetPoint("BOTTOMRIGHT", -2, 2)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.2)
    return button
end

local function ShowIconPreview(button, icon)
    local path = ns.IconPath(icon)
    button.texture:SetTexture(path or "Interface\\Icons\\INV_Misc_QuestionMark")
    button.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.texture:SetDesaturated(not path)
    button.texture:SetAlpha(path and 1 or 0.3)
end

local function CreateInput(parent, width, maxLetters, onEnter)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(width, 20)
    input:SetAutoFocus(false)
    input:SetFontObject(ns.fonts.buttonHighlight)
    input:SetMaxLetters(maxLetters)
    input:SetScript("OnEscapePressed", input.ClearFocus)
    input:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if onEnter then
            onEnter()
        end
    end)
    return input
end

local function CreateLabel(parent, text, font)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFontObject(font or ns.fonts.small)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function ClampOffset(offset, total, visible)
    return math.max(0, math.min(offset, math.max(0, total - visible)))
end

local function ConfirmDialog(name, text, onAccept)
    StaticPopupDialogs[name] = {
        text = text,
        button1 = YES,
        button2 = NO,
        OnAccept = function(_, data) onAccept(data) end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

-- Category actions ---------------------------------------------------------

local function AddCategory()
    local title = strtrim(editor.categoryInput:GetText() or "")
    if title == "" then
        SetStatus("Enter a name for the new category.", true)
        return
    end
    table.insert(ns.data.categories, { title = title, items = {} })
    state.category = #ns.data.categories
    state.item = nil
    editor.categoryInput:SetText("")
    SetStatus("Category \"" .. title .. "\" created.")
    ns.RefreshAll()
end

local function RenameCategory()
    local category = SelectedCategory()
    local title = strtrim(editor.categoryInput:GetText() or "")
    if not category then
        SetStatus("Favorites cannot be renamed, select a category.", true)
        return
    end
    if title == "" then
        SetStatus("Enter the new name in the field above the buttons.", true)
        return
    end
    category.title = title
    editor.categoryInput:SetText("")
    SetStatus("Category renamed.")
    ns.RefreshAll()
end

local function MoveCategory(delta)
    if state.category ~= FAVORITES then
        state.category = ns.MoveItem(ns.data.categories, state.category, delta)
        ns.RefreshAll()
    end
end

ConfirmDialog("CHARADES_DELETE_CATEGORY", "Delete category \"%s\" with all its items?", function(index)
    table.remove(ns.data.categories, index)
    state.category = FAVORITES
    state.item = nil
    ns.RefreshAll()
end)

ConfirmDialog("CHARADES_RESET_CATEGORY", "Restore category \"%s\" to its default? Your changes in it will be lost; other categories and favorites stay.", function(index)
    if ns.ResetCategory(index) then
        state.item = nil
        ns.RefreshAll()
        ns.Print("category restored to default.")
    end
end)

ConfirmDialog("CHARADES_RESET", "Restore the active profile to defaults? Custom categories will be deleted and favorites reset.", function()
    state.category = FAVORITES
    state.item = nil
    ns.ResetToDefaults()
    ns.Print("defaults restored.")
end)

local function DeleteCategory()
    local category = SelectedCategory()
    if not category then
        SetStatus("Favorites cannot be deleted.", true)
        return
    end
    StaticPopup_Show("CHARADES_DELETE_CATEGORY", category.title, nil, state.category)
end

local function ResetSelectedCategory()
    local category = SelectedCategory()
    if not category or not ns.FindDefaultCategory(category.defaultId) then
        SetStatus("Only built-in categories have a default.", true)
        return
    end
    StaticPopup_Show("CHARADES_RESET_CATEGORY", category.title, nil, state.category)
end

-- Item actions -------------------------------------------------------------

local function ReadItemForm()
    local action = strtrim(editor.actionInput:GetText() or "")
    if action == "" then
        SetStatus("Enter a command, emote or text.", true)
        return nil
    end
    local label = strtrim(editor.labelInput:GetText() or "")
    if label == "" then
        label = ns.DefaultLabel(action)
    end
    return action, label
end

local function ContainsAction(items, action, exceptIndex)
    for index, item in ipairs(items) do
        if item.action == action and index ~= exceptIndex then
            return true
        end
    end
    return false
end

local function ClearItemForm()
    state.item = nil
    state.icon = nil
    editor.labelInput:SetText("")
    editor.actionInput:SetText("")
    ShowIconPreview(editor.itemIconButton, nil)
end

local function AddItem()
    local category = SelectedCategory()
    if not category then
        SetStatus("Add favorites with the star next to an item in a category.", true)
        return
    end
    local action, label = ReadItemForm()
    if not action then
        return
    end
    if ContainsAction(category.items, action) then
        SetStatus("This action is already in the category.", true)
        return
    end
    table.insert(category.items, { label = label, action = action, icon = state.icon or false })
    ClearItemForm()
    SetStatus("Added: " .. label)
    ns.RefreshAll()
end

local function SaveItem()
    local category = SelectedCategory()
    if not category or not state.item then
        SetStatus("Click an item in the list first.", true)
        return
    end
    local action, label = ReadItemForm()
    if not action then
        return
    end
    if ContainsAction(category.items, action, state.item) then
        SetStatus("This action is already in the category.", true)
        return
    end
    local item = category.items[state.item]
    -- Keep the favorite when the action changes
    if item.action ~= action then
        for index, favorite in ipairs(ns.data.favorites) do
            if favorite == item.action then
                ns.data.favorites[index] = action
            end
        end
    end
    item.action = action
    item.label = label
    item.icon = state.icon or false
    ClearItemForm()
    SetStatus("Changes saved.")
    ns.RefreshAll()
end

local function OnRowSelect(row)
    local category = SelectedCategory()
    if not category or not row.index then
        return
    end
    state.item = row.index
    local item = category.items[row.index]
    editor.labelInput:SetText(item.label)
    editor.actionInput:SetText(item.action)
    state.icon = item.icon or nil
    ShowIconPreview(editor.itemIconButton, state.icon)
    SetStatus("Edit the name or action and click Save changes.")
    ns.RefreshEditor()
end

local function OnRowMove(row, delta)
    local newIndex = ns.MoveItem(CurrentList(), row.index, delta)
    if state.item == row.index then
        state.item = newIndex
    end
    ns.RefreshAll()
end

local function OnRowDelete(row)
    local category = SelectedCategory()
    if category then
        table.remove(category.items, row.index)
    else
        table.remove(ns.data.favorites, row.index)
    end
    ClearItemForm()
    ns.RefreshAll()
end

local function OnRowFavorite(row)
    local category = SelectedCategory()
    if category then
        ns.ToggleFavorite(category.items[row.index].action)
        ns.RefreshAll()
    end
end

-- Emote picker (optional helper, the action field still accepts anything) ---

local PICKER_ROWS = 14
local picker
local pickerOffset = 0
local pickerMatches = {}

local function RefreshPicker()
    local query = ns.Fold(strtrim(picker.search:GetText() or ""))
    pickerMatches = {}
    for _, emote in ipairs(ns.GetEmoteList()) do
        if query == "" or string.find(emote.command, query, 1, true) or string.find(string.lower(emote.token), query, 1, true) then
            table.insert(pickerMatches, emote)
        end
    end
    pickerOffset = ClampOffset(pickerOffset, #pickerMatches, PICKER_ROWS)
    for index, row in ipairs(picker.rows) do
        local emote = pickerMatches[pickerOffset + index]
        if emote then
            row.emote = emote
            row.label:SetText(emote.command)
            row:Show()
        else
            row:Hide()
        end
    end
    picker.count:SetText(#pickerMatches .. " emotes (mouse wheel)")
end

local function PickEmote(emote)
    editor.actionInput:SetText(emote.command)
    if strtrim(editor.labelInput:GetText() or "") == "" then
        editor.labelInput:SetText(string.sub(emote.command, 2))
    end
    picker:Hide()
    SetStatus("Emote selected, adjust the name and click Add or Save changes.")
end

local function CreatePicker()
    picker = CreateFrame("Frame", "CharadesEmotePicker", UIParent, "BackdropTemplate")
    picker:SetSize(240, 120 + PICKER_ROWS * 20)
    picker:SetFrameStrata("FULLSCREEN_DIALOG")
    ns.ApplyDialogBackdrop(picker)
    ns.MakeMovable(picker)
    picker:Hide()
    table.insert(UISpecialFrames, "CharadesEmotePicker")

    CreateLabel(picker, "Choose emote", ns.fonts.title):SetPoint("TOP", 0, -16)
    local close = CreateFrame("Button", nil, picker, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    picker.search = CreateInput(picker, 196, 30)
    picker.search:SetPoint("TOPLEFT", 24, -44)
    picker.search:SetScript("OnTextChanged", function()
        pickerOffset = 0
        RefreshPicker()
    end)
    picker.search:SetScript("OnEnterPressed", function()
        if pickerMatches[1] then
            PickEmote(pickerMatches[1])
        end
    end)

    picker.rows = {}
    for index = 1, PICKER_ROWS do
        local row = CreateFrame("Button", nil, picker)
        row:SetSize(200, 18)
        row:SetPoint("TOPLEFT", 20, -72 - (index - 1) * 20)
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.1)
        row.label = CreateLabel(row, "", ns.fonts.buttonHighlight)
        row.label:SetPoint("LEFT", 4, 0)
        row:SetScript("OnClick", function(self) PickEmote(self.emote) end)
        picker.rows[index] = row
    end

    picker.count = CreateLabel(picker, "")
    picker.count:SetPoint("BOTTOMLEFT", 22, 18)

    picker:EnableMouseWheel(true)
    picker:SetScript("OnMouseWheel", function(_, delta)
        pickerOffset = pickerOffset - delta * 3
        RefreshPicker()
    end)
end

local function TogglePicker()
    if not picker then
        CreatePicker()
    end
    if picker:IsShown() then
        picker:Hide()
        return
    end
    picker:ClearAllPoints()
    picker:SetPoint("TOPLEFT", editor.pickerButton, "TOPRIGHT", 8, 0)
    picker.search:SetText("")
    pickerOffset = 0
    picker:Show()
    RefreshPicker()
    picker.search:SetFocus()
end

-- Drag and drop -----------------------------------------------------------
-- Drag rows to reorder items, favorites or categories. Drop an item onto a category
-- on the left to move it there, or onto Favorites to add it to favorites.

local drag
local AUTO_SCROLL_INTERVAL = 0.12

local function CursorInEditorSpace()
    local scale = editor:GetEffectiveScale()
    local x, y = GetCursorPosition()
    return x / scale, y / scale
end

local function IsOverRow(row, x, y)
    return row:IsShown() and x >= row:GetLeft() and x <= row:GetRight() and y >= row:GetBottom() - 1 and y <= row:GetTop() + 1
end

local function ClearDropHighlights()
    editor.dropLine:Hide()
    for _, row in ipairs(editor.categoryRows) do
        row.dropTarget:Hide()
    end
end

-- Returns the insertion index (1..#list + 1) for the cursor within a column of rows.
-- rowIndexOf(row) gives the list index shown by that row, or nil for rows that cannot be targets.
local function FindInsertion(rows, x, y, rowIndexOf, listLength)
    local first, last
    for _, row in ipairs(rows) do
        local index = row:IsShown() and rowIndexOf(row)
        if index then
            first = first or row
            last = row
            if x >= row:GetLeft() - 10 and x <= row:GetRight() + 10 then
                local top, bottom = row:GetTop(), row:GetBottom()
                if y <= top + 1 and y >= bottom - 1 then
                    if y > (top + bottom) / 2 then
                        return index, row, "TOP", 0
                    end
                    return index + 1, row, "BOTTOM", 0
                end
            end
        end
    end
    if not first or x < first:GetLeft() - 10 or x > first:GetRight() + 10 then
        return nil
    end
    if y > first:GetTop() then
        return rowIndexOf(first), first, "TOP", -1
    end
    if y < last:GetBottom() then
        return math.min(rowIndexOf(last) + 1, listLength + 1), last, "BOTTOM", 1
    end
    return nil
end

local function ShowDropLine(row, edge)
    editor.dropLine:ClearAllPoints()
    editor.dropLine:SetPoint("LEFT", row, edge .. "LEFT", 0, 0)
    editor.dropLine:SetPoint("RIGHT", row, edge .. "RIGHT", 0, 0)
    editor.dropLine:Show()
end

local function AutoScroll(direction, isCategory)
    if direction == 0 or GetTime() - (drag.lastScroll or 0) < AUTO_SCROLL_INTERVAL then
        return
    end
    drag.lastScroll = GetTime()
    if isCategory then
        state.categoryOffset = state.categoryOffset + direction
    else
        state.itemOffset = state.itemOffset + direction
    end
    ns.RefreshEditor()
end

local function OnDragUpdate()
    local x, y = CursorInEditorSpace()
    local uiScale = UIParent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    editor.dragGhost:ClearAllPoints()
    editor.dragGhost:SetPoint("LEFT", UIParent, "BOTTOMLEFT", cursorX / uiScale + 14, cursorY / uiScale)

    ClearDropHighlights()
    drag.target = nil

    if drag.kind == "item" then
        -- Dropping onto a category row on the left
        for _, row in ipairs(editor.categoryRows) do
            if IsOverRow(row, x, y) then
                local index = row.categoryIndex
                local valid = drag.fromCategory ~= FAVORITES and index ~= drag.fromCategory
                if valid then
                    row.dropTarget:Show()
                    drag.target = { type = "category", index = index }
                end
                return
            end
        end
        local list = drag.list
        local insertAt, row, edge, scroll = FindInsertion(editor.itemRows, x, y, function(r) return r.index end, #list)
        if insertAt then
            ShowDropLine(row, edge)
            drag.target = { type = "insert", index = insertAt }
            AutoScroll(scroll, false)
        end
    else
        local categories = ns.data.categories
        local insertAt, row, edge, scroll = FindInsertion(editor.categoryRows, x, y, function(r)
            -- The Favorites row stays on top; dropping on it means "first position"
            if r.categoryIndex == FAVORITES then
                return 1
            end
            return r.categoryIndex
        end, #categories)
        if insertAt then
            if row.categoryIndex == FAVORITES then
                edge = "BOTTOM"
            end
            ShowDropLine(row, edge)
            drag.target = { type = "insert", index = math.max(1, insertAt) }
            AutoScroll(scroll, true)
        end
    end
end

local function MoveWithin(list, from, to)
    if to > from then
        to = to - 1
    end
    if to == from then
        return
    end
    local entry = table.remove(list, from)
    table.insert(list, to, entry)
end

local function IndexOf(list, value)
    for index, entry in ipairs(list) do
        if entry == value then
            return index
        end
    end
    return nil
end

local function FinishDrag()
    if not drag then
        return
    end
    local finished = drag
    drag = nil
    editor:SetScript("OnUpdate", nil)
    editor.dragGhost:Hide()
    ClearDropHighlights()

    local target = finished.target
    if not target then
        ns.RefreshEditor()
        return
    end

    if finished.kind == "category" then
        local selected = SelectedCategory()
        MoveWithin(ns.data.categories, finished.from, target.index)
        state.category = selected and IndexOf(ns.data.categories, selected) or state.category
    elseif target.type == "insert" then
        local selected = state.item and finished.list[state.item]
        MoveWithin(finished.list, finished.from, target.index)
        state.item = selected and IndexOf(finished.list, selected) or nil
    elseif target.index == FAVORITES then
        local action = finished.entry.action
        if ns.IsFavorite(action) then
            SetStatus("\"" .. finished.entry.label .. "\" is already a favorite.", true)
        else
            table.insert(ns.data.favorites, action)
            SetStatus("\"" .. finished.entry.label .. "\" added to favorites.")
        end
    else
        local destination = ns.data.categories[target.index]
        for _, item in ipairs(destination.items) do
            if item.action == finished.entry.action then
                SetStatus("\"" .. destination.title .. "\" already contains this action.", true)
                ns.RefreshEditor()
                return
            end
        end
        table.remove(finished.list, finished.from)
        table.insert(destination.items, finished.entry)
        ClearItemForm()
        SetStatus("Moved \"" .. finished.entry.label .. "\" to \"" .. destination.title .. "\".")
    end
    ns.RefreshAll()
end

local function StartDrag(row, kind)
    if drag then
        return
    end
    if kind == "category" then
        if not row.categoryIndex or row.categoryIndex == FAVORITES then
            return
        end
        drag = { kind = "category", from = row.categoryIndex }
        editor.dragGhost.label:SetText(ns.data.categories[row.categoryIndex].title)
    else
        if not row.index then
            return
        end
        local list = CurrentList()
        local entry = list[row.index]
        local isFavorites = state.category == FAVORITES
        drag = {
            kind = "item",
            list = list,
            from = row.index,
            fromCategory = state.category,
            entry = not isFavorites and entry or nil,
        }
        editor.dragGhost.label:SetText(isFavorites and ns.LabelFor(entry) or entry.label)
    end
    editor.dragGhost:Show()
    editor:SetScript("OnUpdate", OnDragUpdate)
end

local function EnableRowDrag(row, kind)
    row:RegisterForDrag("LeftButton")
    row:SetScript("OnDragStart", function(self) StartDrag(self, kind) end)
    row:SetScript("OnDragStop", FinishDrag)
end

local function CreateDragVisuals()
    local line = editor:CreateTexture(nil, "OVERLAY")
    line:SetHeight(2)
    line:SetColorTexture(1, 0.82, 0, 1)
    line:Hide()
    editor.dropLine = line

    local ghost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    ghost:SetSize(170, 22)
    ghost:SetFrameStrata("TOOLTIP")
    ghost:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    ghost:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    ghost:SetBackdropBorderColor(1, 0.82, 0, 1)
    ghost.label = ghost:CreateFontString(nil, "OVERLAY")
    ghost.label:SetFontObject(ns.fonts.buttonHighlight)
    ghost.label:SetPoint("LEFT", 8, 0)
    ghost.label:SetPoint("RIGHT", -8, 0)
    ghost.label:SetWordWrap(false)
    ghost:Hide()
    editor.dragGhost = ghost
end

-- Building -----------------------------------------------------------------

local function CreateSelectableRow(width, height)
    local row = CreateFrame("Button", nil, editor)
    row:SetSize(width, height)

    local selected = row:CreateTexture(nil, "BACKGROUND")
    selected:SetAllPoints()
    selected:SetColorTexture(0.2, 0.45, 1, 0.35)
    row.selected = selected

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.08)
    return row
end

local function CreateCategoryRows()
    editor.categoryRows = {}
    for rowIndex = 1, CATEGORY_ROWS do
        local row = CreateSelectableRow(LEFT_WIDTH, CATEGORY_ROW_HEIGHT - 2)
        row:SetPoint("TOPLEFT", LEFT_X, LIST_TOP - (rowIndex - 1) * CATEGORY_ROW_HEIGHT)

        local star = row:CreateTexture(nil, "ARTWORK")
        star:SetTexture(ns.STAR_TEXTURE)
        star:SetSize(12, 12)
        star:SetPoint("LEFT", 4, 0)
        row.star = star

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ns.ICON_SIZE, ns.ICON_SIZE)
        icon:SetPoint("LEFT", 20, 0)
        row.icon = icon

        local text = CreateLabel(row, "", ns.fonts.header)
        text:SetWordWrap(false)
        row.label = text

        row:SetScript("OnClick", function(self)
            state.category = self.categoryIndex
            state.itemOffset = 0
            ClearItemForm()
            SetStatus("")
            ns.RefreshEditor()
        end)
        local dropTarget = row:CreateTexture(nil, "BORDER")
        dropTarget:SetAllPoints()
        dropTarget:SetColorTexture(1, 0.82, 0, 0.3)
        dropTarget:Hide()
        row.dropTarget = dropTarget

        EnableRowDrag(row, "category")
        editor.categoryRows[rowIndex] = row
    end
end

local function CreateItemRows()
    editor.itemRows = {}
    for rowIndex = 1, ITEM_ROWS do
        local row = CreateSelectableRow(RIGHT_WIDTH, ITEM_ROW_HEIGHT - 2)
        row:SetPoint("TOPLEFT", RIGHT_X, LIST_TOP - (rowIndex - 1) * ITEM_ROW_HEIGHT)

        local favorite = CreateIconButton(row, ns.STAR_TEXTURE, 16, function(self) OnRowFavorite(self:GetParent()) end)
        favorite:SetPoint("LEFT", 4, 0)
        ns.AddTooltip(favorite, "Favorite", { "Add to or remove from favorites" })
        row.favorite = favorite

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ns.ICON_SIZE, ns.ICON_SIZE)
        icon:SetPoint("LEFT", 24, 0)
        row.icon = icon

        row.label = CreateLabel(row, "", ns.fonts.buttonHighlight)
        row.label:SetWordWrap(false)

        row.action = CreateLabel(row, "")
        row.action:SetPoint("LEFT", 190, 0)
        row.action:SetWidth(120)
        row.action:SetWordWrap(false)

        local up = CreateIconButton(row, "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up", 22, function(self) OnRowMove(self:GetParent(), -1) end)
        up:SetPoint("RIGHT", -52, 0)
        local down = CreateIconButton(row, "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up", 22, function(self) OnRowMove(self:GetParent(), 1) end)
        down:SetPoint("RIGHT", -28, 0)
        local delete = CreateIconButton(row, "Interface\\Buttons\\UI-GroupLoot-Pass-Up", 18, function(self) OnRowDelete(self:GetParent()) end)
        delete:SetPoint("RIGHT", -4, 0)
        ns.AddTooltip(delete, function()
            return state.category == FAVORITES and "Remove from favorites" or "Delete item"
        end)

        row:SetScript("OnClick", OnRowSelect)
        EnableRowDrag(row, "item")
        editor.itemRows[rowIndex] = row
    end
end

local ACTION_HELP = {
    "|cffffd200/dance|r  emote with animation",
    "|cffffd200/command|r  any command, including other addons",
    "|cffffd200/e waves|r  custom text emote (/s and /y too)",
    "|cffffd200Hello!|r  text without a slash is said aloud",
    "|cffffd200/bow; /wait 1; Hello|r  sequence, steps separated by ;",
    "Steps are 2 s apart by default, /wait N changes the pause.",
    "Protected commands (/cast, /use, /target) cannot be run by addons.",
}

local function HasSettingsApi()
    return Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory and Settings.OpenToCategory
end

function ns.CreateEditor()
    if not HasSettingsApi() then
        ns.Print("this client has no AddOns options panel, editing is unavailable.")
        return
    end

    -- Page inside Options > AddOns; the settings panel parents, sizes and shows it
    editor = CreateFrame("Frame", "CharadesEditor")
    editor:Hide()

    local title = CreateLabel(editor, "Charades", ns.fonts.title)
    title:SetPoint("TOPLEFT", LEFT_X, -14)
    editor.profileInfo = CreateLabel(editor, "")
    editor.profileInfo:SetPoint("LEFT", title, "RIGHT", 12, -1)

    local category = Settings.RegisterCanvasLayoutCategory(editor, "Charades")
    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
    ns.CreateGeneralPage(category)
    ns.CreateKeyBindingsPage(category)

    editor:SetScript("OnShow", function()
        SetStatus("")
        ns.RefreshEditor()
    end)
    editor:SetScript("OnHide", function()
        if drag then
            drag.target = nil
            FinishDrag()
        end
        if picker then
            picker:Hide()
        end
        ns.CloseIconPicker()
    end)

    CreateDragVisuals()

    -- Left column: categories
    CreateLabel(editor, "Categories", ns.fonts.gold):SetPoint("TOPLEFT", LEFT_X, -44)
    CreateCategoryRows()

    local listBottom = LIST_TOP - CATEGORY_ROWS * CATEGORY_ROW_HEIGHT
    CreateLabel(editor, "Category name"):SetPoint("TOPLEFT", LEFT_X, listBottom - 6)
    editor.categoryIconButton = CreateIconPickerButton(editor)
    editor.categoryIconButton:SetPoint("TOPLEFT", LEFT_X, listBottom - 20)
    editor.categoryIconButton:SetScript("OnClick", function(self, mouseButton)
        local category = SelectedCategory()
        if not category then
            SetStatus("Favorites use the star; select a category to set its icon.", true)
            return
        end
        if mouseButton == "RightButton" then
            category.icon = false
            ns.RefreshAll()
            return
        end
        ns.OpenIconPicker(self, function(icon)
            category.icon = icon
            ns.RefreshAll()
        end)
    end)
    ns.AddTooltip(editor.categoryIconButton, "Category icon", { "Left-click: choose an icon for the selected category", "Right-click: remove icon" })

    editor.categoryInput = CreateInput(editor, LEFT_WIDTH - 36, 40, AddCategory)
    editor.categoryInput:SetPoint("TOPLEFT", LEFT_X + 36, listBottom - 22)

    local newButton = CreateTextButton(editor, "New", 98, AddCategory)
    newButton:SetPoint("TOPLEFT", LEFT_X, listBottom - 48)
    local renameButton = CreateTextButton(editor, "Rename", 98, RenameCategory)
    renameButton:SetPoint("LEFT", newButton, "RIGHT", 4, 0)

    local upButton = CreateTextButton(editor, "Up", 64, function() MoveCategory(-1) end)
    upButton:SetPoint("TOPLEFT", LEFT_X, listBottom - 74)
    local downButton = CreateTextButton(editor, "Down", 64, function() MoveCategory(1) end)
    downButton:SetPoint("LEFT", upButton, "RIGHT", 4, 0)
    local deleteButton = CreateTextButton(editor, "Delete", 64, DeleteCategory)
    deleteButton:SetPoint("LEFT", downButton, "RIGHT", 4, 0)
    editor.categoryButtons = { renameButton, upButton, downButton, deleteButton }

    editor.resetCategoryButton = CreateTextButton(editor, "Restore category", LEFT_WIDTH, ResetSelectedCategory)
    editor.resetCategoryButton:SetPoint("TOPLEFT", LEFT_X, listBottom - 100)
    ns.AddTooltip(editor.resetCategoryButton, "Restore category", { "Restores the selected built-in category to its original state. Other categories and favorites are not changed." })

    -- Right column: items of the selected category (or favorites)
    editor.listTitle = CreateLabel(editor, "", ns.fonts.gold)
    editor.listTitle:SetPoint("TOPLEFT", RIGHT_X, -44)
    editor.scrollInfo = CreateLabel(editor, "")
    editor.scrollInfo:SetPoint("TOPRIGHT", editor, "TOPLEFT", RIGHT_X + RIGHT_WIDTH, -46)
    CreateItemRows()

    local formTop = LIST_TOP - ITEM_ROWS * ITEM_ROW_HEIGHT - 8
    editor.labelCaption = CreateLabel(editor, "Button label")
    editor.labelCaption:SetPoint("TOPLEFT", RIGHT_X + 30, formTop)
    editor.itemIconButton = CreateIconPickerButton(editor)
    editor.itemIconButton:SetPoint("TOPLEFT", RIGHT_X, formTop - 14)
    editor.itemIconButton:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            state.icon = nil
            ShowIconPreview(self, nil)
            return
        end
        ns.OpenIconPicker(self, function(icon)
            state.icon = icon or nil
            ShowIconPreview(self, state.icon)
            SetStatus(state.item and "Icon selected, click Save changes." or "Icon selected, click Add.")
        end)
    end)
    ns.AddTooltip(editor.itemIconButton, "Icon (optional)", { "Left-click: choose icon", "Right-click: no icon", "Saved with Add or Save changes." })
    ShowIconPreview(editor.itemIconButton, nil)

    editor.labelInput = CreateInput(editor, 150, 40, AddItem)
    editor.labelInput:SetPoint("TOPLEFT", RIGHT_X + 36, formTop - 16)
    editor.pickerButton = CreateTextButton(editor, "Choose emote", 120, TogglePicker)
    editor.pickerButton:SetPoint("TOPLEFT", RIGHT_X + 196, formTop - 15)
    ns.AddTooltip(editor.pickerButton, "Choose emote", { "List of all emotes the client knows. Optional: the Action field accepts anything." })

    editor.actionCaption = CreateLabel(editor, "Action: emote, command, text or sequence (hover for help)")
    editor.actionCaption:SetPoint("TOPLEFT", RIGHT_X, formTop - 42)
    editor.actionInput = CreateInput(editor, RIGHT_WIDTH - 10, 500, AddItem)
    editor.actionInput:SetPoint("TOPLEFT", RIGHT_X + 6, formTop - 58)
    ns.AddTooltip(editor.actionInput, "What an action can be", ACTION_HELP)

    editor.addButton = CreateTextButton(editor, "Add", 100, AddItem)
    editor.addButton:SetPoint("TOPLEFT", RIGHT_X, formTop - 84)
    editor.saveButton = CreateTextButton(editor, "Save changes", 120, SaveItem)
    editor.saveButton:SetPoint("LEFT", editor.addButton, "RIGHT", 4, 0)
    editor.clearButton = CreateTextButton(editor, "Clear selection", 110, function()
        ClearItemForm()
        SetStatus("")
        ns.RefreshEditor()
    end)
    editor.clearButton:SetPoint("LEFT", editor.saveButton, "RIGHT", 4, 0)

    editor.status = CreateLabel(editor, "")
    editor.status:SetPoint("TOPLEFT", RIGHT_X, formTop - 112)
    editor.status:SetWidth(RIGHT_WIDTH)

    local pagesHint = CreateLabel(editor, "More settings (menu, wheel, profiles, icons, export and import) and key bindings are on the pages under Charades on the left.")
    pagesHint:SetPoint("TOPLEFT", RIGHT_X, formTop - 140)
    pagesHint:SetWidth(RIGHT_WIDTH)

    -- Mouse wheel scrolling for both lists
    editor:EnableMouseWheel(true)
    editor:SetScript("OnMouseWheel", function(self, delta)
        local cursorX = GetCursorPosition() / self:GetEffectiveScale()
        if cursorX < self:GetLeft() + RIGHT_X - 10 then
            state.categoryOffset = state.categoryOffset - delta
        else
            state.itemOffset = state.itemOffset - delta
        end
        ns.RefreshEditor()
    end)

    ns.editor = editor
end

function ns.RefreshEditor()
    if not editor or not editor:IsShown() then
        return
    end
    local categories = ns.data.categories

    -- The profile may have been switched on the General page: start from Favorites again
    if editor.shownData ~= ns.data then
        editor.shownData = ns.data
        state.category = FAVORITES
        state.categoryOffset = 0
        state.itemOffset = 0
        state.item = nil
        state.icon = nil
        editor.labelInput:SetText("")
        editor.actionInput:SetText("")
    end

    if state.category ~= FAVORITES and not categories[state.category] then
        state.category = FAVORITES
    end

    editor.profileInfo:SetText(ns.IsUsingOwnProfile() and ("character profile: " .. (UnitName("player") or "")) or "shared profile")

    -- Left list: favorites row first, then categories
    state.categoryOffset = ClampOffset(state.categoryOffset, #categories + 1, CATEGORY_ROWS)
    for rowIndex, row in ipairs(editor.categoryRows) do
        local index = state.categoryOffset + rowIndex - 1
        if index == FAVORITES then
            row.categoryIndex = FAVORITES
            row.star:Show()
            row.label:SetFontObject(ns.fonts.gold)
            row.label:SetText("Favorites  |cff999999(" .. #ns.data.favorites .. ")|r")
            ns.SetIcon(row.icon, nil)
            row.selected:SetShown(state.category == FAVORITES)
            row:Show()
        elseif categories[index] then
            row.categoryIndex = index
            row.star:Hide()
            row.label:SetFontObject(ns.fonts.header)
            row.label:SetText(categories[index].title .. "  |cff999999(" .. #categories[index].items .. ")|r")
            ns.SetIcon(row.icon, categories[index].icon)
            row.selected:SetShown(state.category == index)
            row:Show()
        else
            row:Hide()
        end
    end

    -- Label positions depend only on the "show icons" setting
    for _, row in ipairs(editor.categoryRows) do
        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT", ns.TextOffset(20), 0)
        row.label:SetPoint("RIGHT", -4, 0)
    end

    local isFavorites = state.category == FAVORITES
    ShowIconPreview(editor.categoryIconButton, SelectedCategory() and SelectedCategory().icon)
    editor.categoryIconButton:SetEnabled(not isFavorites)
    for _, button in ipairs(editor.categoryButtons) do
        button:SetEnabled(not isFavorites)
    end
    local selectedCategory = SelectedCategory()
    editor.resetCategoryButton:SetEnabled(selectedCategory ~= nil and ns.FindDefaultCategory(selectedCategory.defaultId) ~= nil)

    -- Right list
    local list = CurrentList()
    state.itemOffset = ClampOffset(state.itemOffset, #list, ITEM_ROWS)
    editor.listTitle:SetText(isFavorites and "Favorites (order in menu, wheel and key bindings)" or selectedCategory.title)
    if #list > ITEM_ROWS then
        editor.scrollInfo:SetText((state.itemOffset + 1) .. "-" .. math.min(#list, state.itemOffset + ITEM_ROWS) .. " of " .. #list .. " (mouse wheel)")
    else
        editor.scrollInfo:SetText(#list > 1 and "Drag rows to reorder" or "")
    end

    for rowIndex, row in ipairs(editor.itemRows) do
        local index = state.itemOffset + rowIndex
        local entry = list[index]
        if entry then
            row.index = index
            local action = isFavorites and entry or entry.action
            local label = isFavorites and ns.LabelFor(entry) or entry.label
            if isFavorites and index <= ns.FAVORITE_BINDINGS then
                label = index .. ". " .. label
            end
            row.label:SetText(label)
            row.label:ClearAllPoints()
            row.label:SetPoint("LEFT", ns.TextOffset(24), 0)
            row.label:SetWidth(186 - ns.TextOffset(24))
            row.action:SetText(action)
            ns.SetIcon(row.icon, isFavorites and ns.IconFor(entry) or entry.icon)
            row.favorite:SetShown(not isFavorites)
            if not isFavorites then
                local on = ns.IsFavorite(action)
                row.favorite:GetNormalTexture():SetDesaturated(not on)
                row.favorite:GetNormalTexture():SetAlpha(on and 1 or 0.35)
            end
            row.selected:SetShown(not isFavorites and state.item == index)
            row:Show()
        else
            row.index = nil
            row:Hide()
        end
    end

    if #list == 0 then
        SetStatus(isFavorites and "Nothing yet. Use the star next to an item in a category to add it." or "This category is empty, add an item with the form below.")
    end

    -- The add/edit form only applies to categories
    for _, widget in ipairs({ editor.itemIconButton, editor.labelInput, editor.actionInput, editor.labelCaption, editor.actionCaption, editor.pickerButton, editor.addButton, editor.saveButton, editor.clearButton }) do
        widget:SetShown(not isFavorites)
    end
    if isFavorites then
        if picker then
            picker:Hide()
        end
        ns.CloseIconPicker()
    end
    editor.saveButton:SetEnabled(state.item ~= nil)

end

-- Opens the Charades page in Options > AddOns
function ns.OpenEditor()
    if not ns.settingsCategory then
        return
    end
    if InCombatLockdown() then
        ns.Print("options cannot be opened in combat.")
        return
    end
    if ns.panel then
        ns.panel:Hide()
    end
    local category = ns.settingsCategory
    Settings.OpenToCategory(category.GetID and category:GetID() or category.ID)
end
