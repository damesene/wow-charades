local _, ns = ...

-- Export/import of the active profile as readable JSON.
-- Imported text is only parsed, never executed as Lua.

local FORMAT = "charades"
local FORMAT_VERSION = 1
local MAX_CATEGORIES, MAX_ITEMS, MAX_FAVORITES = 50, 200, 100
local MAX_LABEL, MAX_ACTION = 60, 500
local MAX_ICON = 200

-- JSON writer ------------------------------------------------------------------

local ESCAPES = { ['"'] = '\\"', ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }

local function EncodeString(value)
    value = string.gsub(value, '[%c"\\|]', function(char)
        -- "|" is escaped too: WoW edit boxes treat it as the start of a colour or link code
        return ESCAPES[char] or string.format("\\u%04x", string.byte(char))
    end)
    return '"' .. value .. '"'
end

-- Lists built for export carry __array = true, so empty lists still encode as []
local function IsArray(value)
    if value.__array == true then
        return true
    end
    if next(value) == nil then
        return false
    end
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" then
            return false
        end
        count = count + 1
    end
    return count == #value
end

-- ordered: list of keys in the order they should appear
local function Encode(value, indent, ordered)
    local kind = type(value)
    if kind == "string" then
        return EncodeString(value)
    elseif kind == "number" then
        return tostring(value)
    elseif kind == "boolean" then
        return value and "true" or "false"
    elseif kind ~= "table" then
        return "null"
    end

    local inner = indent .. "  "
    local parts = {}
    if IsArray(value) then
        if #value == 0 then
            return "[]"
        end
        for _, element in ipairs(value) do
            table.insert(parts, inner .. Encode(element, inner, ordered))
        end
        return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
    end
    -- Objects with only simple values (like an item) fit on one line
    local simple = true
    for _, key in ipairs(ordered) do
        if type(value[key]) == "table" then
            simple = false
        end
    end
    for _, key in ipairs(ordered) do
        if value[key] ~= nil then
            local pair = EncodeString(key) .. ": " .. Encode(value[key], inner, ordered)
            table.insert(parts, simple and pair or (inner .. pair))
        end
    end
    if simple then
        return "{ " .. table.concat(parts, ", ") .. " }"
    end
    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

-- JSON reader ------------------------------------------------------------------

local function Utf8(code)
    if code < 0x80 then
        return string.char(code)
    elseif code < 0x800 then
        return string.char(0xC0 + math.floor(code / 0x40), 0x80 + code % 0x40)
    end
    return string.char(0xE0 + math.floor(code / 0x1000), 0x80 + math.floor(code / 0x40) % 0x40, 0x80 + code % 0x40)
end

local Parse

local function SkipSpace(text, position)
    return string.find(text, "[^ \t\r\n]", position) or (#text + 1)
end

local function ParseString(text, position)
    local out = {}
    position = position + 1
    while true do
        local char = string.sub(text, position, position)
        if char == "" then
            error("unterminated string")
        elseif char == '"' then
            return table.concat(out), position + 1
        elseif char == "\\" then
            local escape = string.sub(text, position + 1, position + 1)
            local simple = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
            if simple[escape] then
                table.insert(out, simple[escape])
                position = position + 2
            elseif escape == "u" then
                local hex = string.sub(text, position + 2, position + 5)
                if not string.match(hex, "^%x%x%x%x$") then
                    error("bad unicode escape")
                end
                table.insert(out, Utf8(tonumber(hex, 16)))
                position = position + 6
            else
                error("bad escape")
            end
        else
            table.insert(out, char)
            position = position + 1
        end
    end
end

Parse = function(text, position, depth)
    if depth > 20 then
        error("too deeply nested")
    end
    position = SkipSpace(text, position)
    local char = string.sub(text, position, position)
    if char == "{" then
        local object = {}
        position = SkipSpace(text, position + 1)
        if string.sub(text, position, position) == "}" then
            return object, position + 1
        end
        while true do
            position = SkipSpace(text, position)
            if string.sub(text, position, position) ~= '"' then
                error("expected a key")
            end
            local key
            key, position = ParseString(text, position)
            position = SkipSpace(text, position)
            if string.sub(text, position, position) ~= ":" then
                error("expected ':'")
            end
            object[key], position = Parse(text, position + 1, depth + 1)
            position = SkipSpace(text, position)
            local separator = string.sub(text, position, position)
            if separator == "}" then
                return object, position + 1
            elseif separator ~= "," then
                error("expected ',' or '}'")
            end
            position = position + 1
        end
    elseif char == "[" then
        local array = {}
        position = SkipSpace(text, position + 1)
        if string.sub(text, position, position) == "]" then
            return array, position + 1
        end
        while true do
            local element
            element, position = Parse(text, position, depth + 1)
            table.insert(array, element)
            position = SkipSpace(text, position)
            local separator = string.sub(text, position, position)
            if separator == "]" then
                return array, position + 1
            elseif separator ~= "," then
                error("expected ',' or ']'")
            end
            position = position + 1
        end
    elseif char == '"' then
        return ParseString(text, position)
    elseif string.sub(text, position, position + 3) == "true" then
        return true, position + 4
    elseif string.sub(text, position, position + 4) == "false" then
        return false, position + 5
    elseif string.sub(text, position, position + 3) == "null" then
        return nil, position + 4
    end
    local number = string.match(text, "^-?%d+%.?%d*[eE]?[-+]?%d*", position)
    if number and number ~= "" and tonumber(number) then
        return tonumber(number), position + #number
    end
    error("unexpected character")
end

local function DecodeJson(text)
    local ok, value, position = pcall(Parse, text, 1, 0)
    if not ok then
        return nil
    end
    if SkipSpace(text, position) <= #text then
        return nil
    end
    return value
end

-- Export -------------------------------------------------------------------------

local KEY_ORDER = { "format", "version", "favorites", "categories", "title", "defaultId", "label", "action", "icon", "collapsed", "items" }

local function IconValue(icon)
    if type(icon) == "number" or type(icon) == "string" then
        return icon
    end
    return nil
end

function ns.ExportData(data)
    local favorites = { __array = true }
    for _, action in ipairs(data.favorites) do
        table.insert(favorites, action)
    end
    local categories = { __array = true }
    for _, category in ipairs(data.categories) do
        local items = { __array = true }
        for _, item in ipairs(category.items) do
            table.insert(items, { label = item.label, action = item.action, icon = IconValue(item.icon) })
        end
        table.insert(categories, {
            title = category.title,
            defaultId = category.defaultId,
            icon = IconValue(category.icon),
            collapsed = category.collapsed and true or nil,
            items = items,
        })
    end
    local document = { format = FORMAT, version = FORMAT_VERSION, favorites = favorites, categories = categories }
    return Encode(document, "", KEY_ORDER)
end

-- Import -------------------------------------------------------------------------

local function Text(value, maxLength)
    if type(value) ~= "string" then
        return nil
    end
    value = strtrim(string.gsub(value, "[%c]", " "))
    if value == "" then
        return nil
    end
    return string.sub(value, 1, maxLength)
end

local function Icon(value)
    if type(value) == "number" then
        return value
    end
    if type(value) == "string" and #value <= MAX_ICON then
        return ns.ParseIcon(value)
    end
    return nil
end

local function ImportJson(text)
    local document = DecodeJson(text)
    if type(document) ~= "table" or document.format ~= FORMAT then
        return nil, "This is not a Charades export (JSON with \"format\": \"charades\")."
    end
    if type(document.categories) ~= "table" then
        return nil, "The export has no \"categories\" list."
    end

    local data = { version = ns.DATA_VERSION, categories = {}, favorites = {} }
    for _, action in ipairs(type(document.favorites) == "table" and document.favorites or {}) do
        local value = Text(action, MAX_ACTION)
        if value and #data.favorites < MAX_FAVORITES then
            table.insert(data.favorites, value)
        end
    end
    for _, source in ipairs(document.categories) do
        local title = type(source) == "table" and Text(source.title, MAX_LABEL)
        if title and #data.categories < MAX_CATEGORIES then
            local category = { title = title, icon = Icon(source.icon) or false, collapsed = source.collapsed == true or nil, items = {} }
            if type(source.defaultId) == "string" and ns.FindDefaultCategory(source.defaultId) then
                category.defaultId = source.defaultId
            end
            for _, entry in ipairs(type(source.items) == "table" and source.items or {}) do
                local action = type(entry) == "table" and Text(entry.action, MAX_ACTION)
                if action and #category.items < MAX_ITEMS then
                    table.insert(category.items, {
                        label = Text(entry.label, MAX_LABEL) or ns.DefaultLabel(action),
                        action = action,
                        icon = Icon(entry.icon) or false,
                    })
                end
            end
            table.insert(data.categories, category)
        end
    end
    return data
end

local BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Returns data or nil plus an error message
function ns.ImportData(text)
    -- Edit boxes return a typed "|" as "||"
    text = strtrim(string.gsub(text or "", "||", "|"))
    if string.sub(text, 1, 1) == "{" then
        return ImportJson(text)
    end
    return nil, "This is not a Charades export."
end

-- Dialog -----------------------------------------------------------------------------

local DIALOG_WIDTH, DIALOG_HEIGHT = 720, 540
local dialog

StaticPopupDialogs["CHARADES_IMPORT"] = {
    text = "Replace current items, categories and favorites with the import (%s)? The import contains %d categories.",
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, data)
        ns.ReplaceActiveData(data)
        ns.Print("import complete.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function CreateTextButton(text, width, onClick)
    local button = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetNormalFontObject(ns.fonts.button)
    button:SetHighlightFontObject(ns.fonts.buttonHighlight)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function ScrollToCursor(cursorY, cursorHeight)
    local scroll = dialog.scroll
    local top = -cursorY
    local bottom = top + cursorHeight
    local current = scroll:GetVerticalScroll()
    local visible = scroll:GetHeight()
    if top < current then
        scroll:SetVerticalScroll(top)
    elseif bottom > current + visible then
        scroll:SetVerticalScroll(bottom - visible)
    end
end

local function CreateDialog()
    dialog = CreateFrame("Frame", "CharadesTransfer", UIParent, "BackdropTemplate")
    dialog:SetSize(DIALOG_WIDTH, DIALOG_HEIGHT)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetPoint("CENTER")
    ns.ApplyDialogBackdrop(dialog)
    ns.MakeMovable(dialog)
    dialog:Hide()
    table.insert(UISpecialFrames, "CharadesTransfer")

    dialog.title = dialog:CreateFontString(nil, "OVERLAY")
    dialog.title:SetFontObject(ns.fonts.title)
    dialog.title:SetPoint("TOP", 0, -16)

    local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    dialog.hint = dialog:CreateFontString(nil, "OVERLAY")
    dialog.hint:SetFontObject(ns.fonts.small)
    dialog.hint:SetPoint("TOPLEFT", 22, -42)
    dialog.hint:SetWidth(DIALOG_WIDTH - 44)
    dialog.hint:SetJustifyH("LEFT")

    -- Dark text area with a multi-line edit box that scrolls
    local area = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
    area:SetPoint("TOPLEFT", 20, -64)
    area:SetPoint("BOTTOMRIGHT", -20, 52)
    area:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    area:SetBackdropColor(0, 0, 0, 0.6)
    area:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local scroll = CreateFrame("ScrollFrame", nil, area)
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -8, 8)
    dialog.scroll = scroll

    local input = CreateFrame("EditBox", nil, scroll)
    input:SetMultiLine(true)
    input:SetAutoFocus(false)
    input:SetMaxLetters(0)
    input:SetFontObject(ns.fonts.buttonHighlight)
    input:SetWidth(DIALOG_WIDTH - 60)
    input:SetTextInsets(2, 2, 2, 2)
    input:SetScript("OnEscapePressed", function() dialog:Hide() end)
    input:SetScript("OnCursorChanged", function(_, _, y, _, height) ScrollToCursor(y, height) end)
    scroll:SetScrollChild(input)
    dialog.input = input

    -- Clicking anywhere in the text area puts the cursor into the text
    area:EnableMouse(true)
    area:SetScript("OnMouseDown", function() input:SetFocus() end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local maximum = math.max(0, input:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(maximum, self:GetVerticalScroll() - delta * 40)))
    end)

    local closeButton = CreateTextButton(CLOSE or "Close", 100, function() dialog:Hide() end)
    closeButton:SetPoint("BOTTOMRIGHT", -20, 18)

    dialog.importButton = CreateTextButton("Import", 120, function()
        local data, message = ns.ImportData(input:GetText())
        if not data then
            dialog.hint:SetText("|cffff5555" .. message .. "|r")
            return
        end
        local target = ns.IsUsingOwnProfile() and "this character's profile" or "shared profile"
        dialog:Hide()
        StaticPopup_Show("CHARADES_IMPORT", target, #data.categories, data)
    end)
    dialog.importButton:SetPoint("RIGHT", closeButton, "LEFT", -6, 0)

    local selectAll = CreateTextButton("Select all", 110, function()
        input:SetFocus()
        input:HighlightText()
    end)
    selectAll:SetPoint("BOTTOMLEFT", 20, 18)

    local clear = CreateTextButton("Clear", 90, function()
        input:SetText("")
        input:SetFocus()
    end)
    clear:SetPoint("LEFT", selectAll, "RIGHT", 6, 0)
    dialog.clearButton = clear
end

function ns.ShowExport()
    if not dialog then
        CreateDialog()
    end
    dialog.title:SetText("Export")
    dialog.hint:SetText("The items, categories and favorites of the active profile as JSON. Click Select all, then press Ctrl+C to copy.")
    dialog.importButton:Hide()
    dialog.clearButton:Hide()
    dialog.input:SetText(ns.ExportData(ns.data))
    dialog.scroll:SetVerticalScroll(0)
    dialog:Show()
    dialog.input:SetFocus()
    dialog.input:HighlightText()
end

function ns.ShowImport()
    if not dialog then
        CreateDialog()
    end
    dialog.title:SetText("Import")
    dialog.hint:SetText("Paste a Charades export (JSON) with Ctrl+V and click Import. Only import from people you trust: items can run commands.")
    dialog.importButton:Show()
    dialog.clearButton:Show()
    dialog.input:SetText("")
    dialog.scroll:SetVerticalScroll(0)
    dialog:Show()
    dialog.input:SetFocus()
end
