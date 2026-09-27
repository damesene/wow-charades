local _, ns = ...

-- "Key Bindings" page under Options > AddOns > Charades: set the addon's bindings
-- without going to the game's Keybindings screen. Uses the same bindings, so both stay in sync.

local ROW_HEIGHT = 28
local LABEL_WIDTH = 300
local BUTTON_WIDTH = 200

local IGNORED_KEYS = {
    LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
    LALT = true, RALT = true, LMETA = true, RMETA = true, UNKNOWN = true,
}

local MOUSE_BUTTONS = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }

local page
local rows = {}
local capturing -- the row button waiting for a key
local catcher -- full-screen frame that receives the key press

local function Actions()
    local list = {
        { command = "CHARADES_TOGGLE" },
        { command = "CHARADES_WHEEL" },
    }
    for index = 1, ns.FAVORITE_BINDINGS do
        table.insert(list, { command = "CHARADES_FAV" .. index })
    end
    return list
end

local function BindingName(command)
    return _G["BINDING_NAME_" .. command] or command
end

local function KeyText(key)
    if GetBindingText then
        return GetBindingText(key)
    end
    return key
end

local function SetStatus(message, isError)
    page.status:SetText(message or "")
    if isError then
        page.status:SetTextColor(1, 0.35, 0.35)
    else
        page.status:SetTextColor(0.5, 1, 0.5)
    end
end

local function ModifierPrefix()
    local prefix = ""
    if IsAltKeyDown() then
        prefix = prefix .. "ALT-"
    end
    if IsControlKeyDown() then
        prefix = prefix .. "CTRL-"
    end
    if IsShiftKeyDown() then
        prefix = prefix .. "SHIFT-"
    end
    if IsMetaKeyDown and IsMetaKeyDown() then
        prefix = prefix .. "META-"
    end
    return prefix
end

local function RefreshRows()
    if not page then
        return
    end
    ns.UpdateBindingNames()
    for _, row in ipairs(rows) do
        row.label:SetText(BindingName(row.command))
        if capturing == row.button then
            row.button:SetText("Waiting for a key...")
        else
            local key1, key2 = GetBindingKey(row.command)
            if key1 and key2 then
                row.button:SetText(KeyText(key1) .. ", " .. KeyText(key2))
            elseif key1 then
                row.button:SetText(KeyText(key1))
            else
                row.button:SetText("|cff888888Not bound|r")
            end
        end
    end
end

local function StopCapture()
    capturing = nil
    if catcher then
        catcher:Hide()
    end
    RefreshRows()
end

local function ClearBinding(command)
    local key1, key2 = GetBindingKey(command)
    if key1 then
        SetBinding(key1)
    end
    if key2 then
        SetBinding(key2)
    end
end

local function Save()
    SaveBindings(GetCurrentBindingSet())
end

local function ApplyKey(command, key)
    if InCombatLockdown() then
        SetStatus("Key bindings cannot be changed in combat.", true)
        StopCapture()
        return
    end
    local previous = GetBindingAction(key)
    -- One key per action here; the game's Keybindings screen can still add a second one
    ClearBinding(command)
    SetBinding(key, command)
    Save()
    if previous and previous ~= "" and previous ~= command then
        SetStatus(KeyText(key) .. " was bound to \"" .. BindingName(previous) .. "\"; it now belongs to \"" .. BindingName(command) .. "\".")
    else
        SetStatus(KeyText(key) .. " bound to \"" .. BindingName(command) .. "\".")
    end
    StopCapture()
end

-- The capture happens on a separate top-level frame: inside the Options panel the key
-- presses are taken by the panel itself (or a focused edit box) and never reach a row button.
local function CreateCatcher()
    catcher = CreateFrame("Button", "CharadesKeyCatcher", UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:EnableMouse(true)
    catcher:EnableMouseWheel(true)
    catcher:EnableKeyboard(true)
    catcher:RegisterForClicks("AnyUp")
    catcher:Hide()

    local shade = catcher:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints()
    shade:SetColorTexture(0, 0, 0, 0.45)

    local box = CreateFrame("Frame", nil, catcher, "BackdropTemplate")
    box:SetSize(420, 110)
    box:SetPoint("CENTER")
    ns.ApplyDialogBackdrop(box)

    catcher.title = box:CreateFontString(nil, "OVERLAY")
    catcher.title:SetFontObject(ns.fonts.title)
    catcher.title:SetPoint("TOP", 0, -20)

    local hint = box:CreateFontString(nil, "OVERLAY")
    hint:SetFontObject(ns.fonts.buttonHighlight)
    hint:SetPoint("TOP", 0, -50)
    hint:SetWidth(380)
    hint:SetText("Press a key or key combination.\nEsc or a left/right click cancels.")

    catcher:SetScript("OnKeyDown", function(self, key)
        if not capturing then
            return
        end
        if key == "ESCAPE" then
            StopCapture()
            return
        end
        if IGNORED_KEYS[key] then
            return
        end
        ApplyKey(capturing.command, ModifierPrefix() .. key)
    end)
    catcher:SetScript("OnMouseDown", function(self, mouseButton)
        if not capturing then
            return
        end
        if MOUSE_BUTTONS[mouseButton] then
            ApplyKey(capturing.command, ModifierPrefix() .. MOUSE_BUTTONS[mouseButton])
        else
            StopCapture()
        end
    end)
    catcher:SetScript("OnMouseWheel", function(self, delta)
        if capturing then
            ApplyKey(capturing.command, ModifierPrefix() .. (delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"))
        end
    end)
end

local function StartCapture(button)
    if InCombatLockdown() then
        SetStatus("Key bindings cannot be changed in combat.", true)
        return
    end
    if not catcher then
        CreateCatcher()
    end
    -- A focused edit box would swallow the key press
    local focus = GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
    if focus then
        focus:ClearFocus()
    end
    capturing = button
    catcher.title:SetText(BindingName(button.command))
    catcher:Show()
    catcher:SetPropagateKeyboardInput(false)
    SetStatus("")
    RefreshRows()
end

local function CreateRow(index, command)
    local row = { command = command }
    local y = -76 - (index - 1) * ROW_HEIGHT

    row.label = page:CreateFontString(nil, "OVERLAY")
    row.label:SetFontObject(ns.fonts.buttonHighlight)
    row.label:SetPoint("TOPLEFT", 16, y - 4)
    row.label:SetWidth(LABEL_WIDTH)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)

    local button = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    button:SetSize(BUTTON_WIDTH, 22)
    button:SetPoint("TOPLEFT", 16 + LABEL_WIDTH + 10, y)
    button:SetNormalFontObject(ns.fonts.button)
    button:SetHighlightFontObject(ns.fonts.buttonHighlight)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(self, mouseButton)
        if capturing == self then
            -- A left or right click while waiting cancels
            StopCapture()
            return
        end
        if mouseButton == "RightButton" then
            if InCombatLockdown() then
                SetStatus("Key bindings cannot be changed in combat.", true)
                return
            end
            ClearBinding(command)
            Save()
            SetStatus("\"" .. BindingName(command) .. "\" unbound.")
            RefreshRows()
            return
        end
        StartCapture(self)
    end)
    button.command = command
    ns.AddTooltip(button, BindingName(command), {
        "Left-click, then press a key or key combination",
        "Right-click: remove binding",
        "Also works with the middle and side mouse buttons.",
    })

    row.button = button
    return row
end

function ns.CreateKeyBindingsPage(parentCategory)
    page = CreateFrame("Frame", "CharadesKeyBindings")
    page:Hide()

    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(ns.fonts.title)
    title:SetPoint("TOPLEFT", 16, -14)
    title:SetText("Charades: Key Bindings")

    local hint = page:CreateFontString(nil, "OVERLAY")
    hint:SetFontObject(ns.fonts.small)
    hint:SetPoint("TOPLEFT", 16, -40)
    hint:SetWidth(LABEL_WIDTH + BUTTON_WIDTH + 10)
    hint:SetJustifyH("LEFT")
    hint:SetText("These are the same bindings as in Options > Keybindings > AddOns > Charades. Favorite numbers follow the order of your favorites.")

    for index, action in ipairs(Actions()) do
        rows[index] = CreateRow(index, action.command)
    end

    page.status = page:CreateFontString(nil, "OVERLAY")
    page.status:SetFontObject(ns.fonts.small)
    page.status:SetPoint("TOPLEFT", 16, -76 - #rows * ROW_HEIGHT - 8)


    page:SetScript("OnShow", function(self)
        SetStatus("")
        self:RegisterEvent("UPDATE_BINDINGS")
        RefreshRows()
    end)
    page:SetScript("OnHide", function(self)
        self:UnregisterEvent("UPDATE_BINDINGS")
        StopCapture()
    end)
    page:SetScript("OnEvent", RefreshRows)

    if Settings.RegisterCanvasLayoutSubcategory then
        Settings.RegisterCanvasLayoutSubcategory(parentCategory, page, "Key Bindings")
    else
        local category = Settings.RegisterCanvasLayoutCategory(page, "Charades Key Bindings")
        Settings.RegisterAddOnCategory(category)
    end
end
