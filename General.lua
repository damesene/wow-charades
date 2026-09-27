local _, ns = ...

-- "General" page under Options > AddOns > Charades: icons, menu, wheel, profile and data.

local LEFT = 16
local WIDTH = 560

local page
local checks = {}

local function CreateHeader(text, y)
    local header = page:CreateFontString(nil, "OVERLAY")
    header:SetFontObject(ns.fonts.gold)
    header:SetPoint("TOPLEFT", LEFT, y)
    header:SetText(text)
end

local function CreateCheck(text, y, get, set, tooltipLines)
    local check = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", LEFT - 4, y)
    local label = page:CreateFontString(nil, "OVERLAY")
    label:SetFontObject(ns.fonts.buttonHighlight)
    label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    label:SetText(text)
    check:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    if tooltipLines then
        ns.AddTooltip(check, text, tooltipLines)
    end
    check.get = get
    table.insert(checks, check)
    return check
end

local function CreateButton(text, width, onClick, tooltipLines)
    local button = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetNormalFontObject(ns.fonts.button)
    button:SetHighlightFontObject(ns.fonts.buttonHighlight)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    if tooltipLines then
        ns.AddTooltip(button, text, tooltipLines)
    end
    return button
end

local function Setting(key)
    return function() return ns.db[key] end, function(value) ns.db[key] = value end
end

function ns.CreateGeneralPage(parentCategory)
    page = CreateFrame("Frame", "CharadesGeneral")
    page:Hide()

    local title = page:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(ns.fonts.title)
    title:SetPoint("TOPLEFT", LEFT, -14)
    title:SetText("Charades: General")

    -- General
    CreateHeader("General", -48)
    CreateCheck("Show icons", -64, function() return ns.db.showIcons end, function(value)
        ns.db.showIcons = value
        ns.RefreshAll()
    end, { "Icons next to items and categories in the menu, the wheel and the options." })
    CreateCheck("Hide minimap button", -90, function() return ns.db.hideMinimapButton end, function(value)
        ns.db.hideMinimapButton = value
        ns.ApplyMinimapVisibility()
    end, { "The menu is still available with /charades, the Addon Compartment and key bindings." })

    -- Menu
    CreateHeader("Menu", -130)
    CreateCheck("Hide menu after using an item", -146, Setting("hideAfterUse"))

    -- Wheel
    CreateHeader("Wheel", -186)
    local cancelGet, cancelSet = Setting("wheelRightClickCancels")
    CreateCheck("Right-click closes the wheel without doing anything", -202, cancelGet, cancelSet, {
        "Works wherever the cursor is, also over an item. Escape always closes the wheel.",
    })
    local confirmGet, confirmSet = Setting("wheelConfirmClick")
    CreateCheck("Confirm actions in the wheel with a left click", -228, confirmGet, confirmSet, {
        "Off: point at an item and release the key.",
        "On: hold the key and left-click an item to use it. Releasing the key closes the wheel without doing anything.",
    })

    -- Profile
    CreateHeader("Profile", -268)
    CreateCheck("Separate items and favorites for this character", -284, ns.IsUsingOwnProfile, function(value)
        ns.SetUseOwnProfile(value)
    end, {
        "On: this character has its own categories, items and favorites. The first time, the shared setup is copied.",
        "Off: the character uses the shared account profile. Its own profile is kept in case you turn this on again.",
    })

    -- Data
    CreateHeader("Data", -324)
    local export = CreateButton("Export", 120, function() ns.ShowExport() end, {
        "Show the items, categories and favorites of the active profile as JSON, ready to copy.",
    })
    export:SetPoint("TOPLEFT", LEFT, -342)
    local import = CreateButton("Import", 120, function() ns.ShowImport() end, {
        "Replace the active profile with an export. Only import from people you trust: items can run commands.",
    })
    import:SetPoint("LEFT", export, "RIGHT", 6, 0)
    local reset = CreateButton("Restore all", 160, function() StaticPopup_Show("CHARADES_RESET") end, {
        "Restores all categories, items and favorites of the active profile to defaults.",
    })
    reset:SetPoint("LEFT", import, "RIGHT", 18, 0)

    local hint = page:CreateFontString(nil, "OVERLAY")
    hint:SetFontObject(ns.fonts.small)
    hint:SetPoint("TOPLEFT", LEFT, -376)
    hint:SetWidth(WIDTH)
    hint:SetJustifyH("LEFT")
    hint:SetText("Export, import and restore work on the active profile (shared or this character's).")

    page:SetScript("OnShow", function()
        for _, check in ipairs(checks) do
            check:SetChecked(check.get())
        end
    end)

    if Settings.RegisterCanvasLayoutSubcategory then
        Settings.RegisterCanvasLayoutSubcategory(parentCategory, page, "General")
    else
        local category = Settings.RegisterCanvasLayoutCategory(page, "Charades General")
        Settings.RegisterAddOnCategory(category)
    end
    ns.generalPage = page
end
