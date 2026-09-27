local _, ns = ...

ns.ICON = "Interface\\AddOns\\Charades\\Icons\\drama"
-- Arial Narrow ships with the client and covers Czech diacritics
ns.FONT_PATH = "Fonts\\ARIALN.TTF"
ns.STAR_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"
ns.FAVORITE_BINDINGS = 10
ns.DATA_VERSION = 8

local SETTING_DEFAULTS = {
    minimapAngle = 200,
    hideMinimapButton = false,
    hideAfterUse = false,
    showIcons = true,
    panelView = "mine", -- "mine" or "all"
    wheelRightClickCancels = true,
    wheelConfirmClick = false,
    animatedOnly = true,
}

function ns.DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, inner in pairs(value) do
        copy[key] = ns.DeepCopy(inner)
    end
    return copy
end

function ns.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd200Charades:|r " .. message)
end

-- Data ---------------------------------------------------------------------
-- data = { version, favorites = { action, ... }, categories = { { title, defaultId, icon, collapsed, items = { { label, action, icon } } } } }
-- icon: nil = none (after v4), false = explicitly removed, number/string = texture

local function CopyDefaultCategory(default)
    local copy = ns.DeepCopy(default)
    copy.defaultId = copy.id
    copy.id = nil
    return copy
end

function ns.BuildDefaultData()
    local data = { version = ns.DATA_VERSION, categories = {}, favorites = ns.DeepCopy(ns.DefaultFavorites) }
    for _, default in ipairs(ns.DefaultCategories) do
        table.insert(data.categories, CopyDefaultCategory(default))
    end
    return data
end

function ns.FindDefaultCategory(defaultId)
    if not defaultId then
        return nil
    end
    for _, default in ipairs(ns.DefaultCategories) do
        if default.id == defaultId then
            return default
        end
    end
    return nil
end

-- Default names used by Charades 1.x-4.x; only used to convert old saved data to the English defaults.
local LEGACY_TITLES = {
    greetings = "Pozdravy",
    moods = "Nálady",
    other = "Ostatní",
}
local LEGACY_LABELS = {
    ["/wave"] = "Zamávat",
    ["/bow"] = "Uklonit se",
    ["/salute"] = "Salutovat",
    ["/kneel"] = "Pokleknout",
    ["/thank"] = "Poděkovat",
    ["/bye"] = "Rozloučit se",
    ["/dance"] = "Tancovat",
    ["/cheer"] = "Jásat",
    ["/laugh"] = "Smát se",
    ["/applaud"] = "Tleskat",
    ["/cry"] = "Plakat",
    ["/shy"] = "Stydět se",
    ["/flex"] = "Svaly",
    ["/roar"] = "Řvát",
    ["/kiss"] = "Pusa",
    ["/flirt"] = "Flirtovat",
    ["/chicken"] = "Slepice",
    ["/rude"] = "Hrubé gesto",
    ["/sit"] = "Sednout",
    ["/sleep"] = "Spát",
    ["/point"] = "Ukázat",
    ["/talk"] = "Mluvit",
    ["/yes"] = "Přikývnout",
    ["/no"] = "Zavrtět hlavou",
    ["/beg"] = "Prosit",
    ["/eat"] = "Jíst",
    ["/train"] = "Vláček",
}

-- Game icons used as defaults by Charades 4.x-5.x; replaced by the bundled icons when unchanged.
local LEGACY_DEFAULT_ICONS = {
    ["/applaud"] = "Spell_Holy_HolyBolt",
    ["/beg"] = "Spell_Holy_PrayerOfHealing02",
    ["/bow"] = "Spell_Holy_PrayerOfHealing02",
    ["/bye"] = "Ability_Rogue_Sprint",
    ["/cheer"] = "Ability_Warrior_BattleShout",
    ["/cry"] = "Spell_Frost_FrostBolt02",
    ["/dance"] = "Spell_Nature_Lightning",
    ["/eat"] = "INV_Misc_Food_15",
    ["/flex"] = "Ability_Racial_BearForm",
    ["/flirt"] = "Spell_Shadow_Charm",
    ["/kiss"] = "INV_Misc_Flower_02",
    ["/kneel"] = "Spell_Holy_Renew",
    ["/laugh"] = "Spell_Nature_Polymorph",
    ["/point"] = "Spell_Holy_MindVision",
    ["/roar"] = "Spell_Shadow_DeathScream",
    ["/rude"] = "Spell_Shadow_Possession",
    ["/salute"] = "INV_Sword_04",
    ["/shy"] = "Ability_Stealth",
    ["/sleep"] = "Spell_Nature_Sleep",
    ["/talk"] = "INV_Misc_Note_01",
    ["/thank"] = "Spell_Holy_Heal",
    ["/train"] = "Ability_Mount_RidingHorse",
    ["/wave"] = "Ability_Hunter_BeastCall",
}
local LEGACY_CATEGORY_ICONS = {
    greetings = "Spell_Holy_PrayerOfHealing02",
    moods = "Spell_Shadow_Charm",
    other = "INV_Misc_Bag_08",
}

-- 2.x stored emote tokens ({ token, label } and "DANCE" favorites); 3.0 stores actions ("/dance")
local function MigrateFromV2(data)
    for _, category in ipairs(data.categories) do
        if category.emotes and not category.items then
            category.items = {}
            for _, emote in ipairs(category.emotes) do
                table.insert(category.items, { label = emote.label, action = "/" .. string.lower(emote.token) })
            end
        end
        category.emotes = nil
        if category.defaultId == nil then
            for _, default in ipairs(ns.DefaultCategories) do
                if default.title == category.title or LEGACY_TITLES[default.id] == category.title then
                    category.defaultId = default.id
                end
            end
        end
    end
    for index, favorite in ipairs(data.favorites) do
        data.favorites[index] = "/" .. string.lower(favorite)
    end
end

-- 4.0 added icons: give existing built-in categories and emotes their default icons once
local function ApplyDefaultIcons(data)
    local iconByAction = {}
    for _, default in ipairs(ns.DefaultCategories) do
        for _, item in ipairs(default.items) do
            if item.icon and not iconByAction[item.action] then
                iconByAction[item.action] = item.icon
            end
        end
    end
    for _, category in ipairs(data.categories) do
        local default = ns.FindDefaultCategory(category.defaultId)
        if category.icon == nil and default then
            category.icon = default.icon
        end
        for _, item in ipairs(category.items or {}) do
            if item.icon == nil then
                item.icon = iconByAction[item.action]
            end
        end
    end
end

-- 5.0 switched the defaults to English: rename built-in names the user never changed
local function TranslateLegacyDefaults(data)
    for _, category in ipairs(data.categories) do
        local default = ns.FindDefaultCategory(category.defaultId)
        if default and category.title == LEGACY_TITLES[default.id] then
            category.title = default.title
        end
        for _, item in ipairs(category.items or {}) do
            if LEGACY_LABELS[item.action] and item.label == LEGACY_LABELS[item.action] then
                for _, defaultCategory in ipairs(ns.DefaultCategories) do
                    for _, defaultItem in ipairs(defaultCategory.items) do
                        if defaultItem.action == item.action then
                            item.label = defaultItem.label
                        end
                    end
                end
            end
        end
    end
end

-- 6.0 ships its own icons: swap the old default game icons the user never changed
local function UpgradeDefaultIcons(data)
    local newIcon = {}
    for _, default in ipairs(ns.DefaultCategories) do
        for _, item in ipairs(default.items) do
            newIcon[item.action] = newIcon[item.action] or item.icon
        end
    end
    for _, category in ipairs(data.categories) do
        local default = ns.FindDefaultCategory(category.defaultId)
        if default and category.icon == LEGACY_CATEGORY_ICONS[default.id] then
            category.icon = default.icon
        end
        for _, item in ipairs(category.items or {}) do
            if item.icon ~= nil and item.icon == LEGACY_DEFAULT_ICONS[item.action] and newIcon[item.action] then
                item.icon = newIcon[item.action]
            end
        end
    end
end

-- 6.1 added every animated emote to the defaults: add the new categories and the new
-- items to existing built-in categories, without touching anything the user already has
local NEW_ITEMS_V7 = {
    greetings = { "/hello", "/welcome", "/hail", "/curtsey" },
    other = { "/lay", "/feast", "/drink", "/violin", "/peon", "/party", "/rasp" },
}
local NEW_CATEGORIES_V7 = { reactions = true, signals = true }

local function AddNewDefaults(data)
    local present = {}
    for _, category in ipairs(data.categories) do
        if category.defaultId then
            present[category.defaultId] = category
        end
    end
    for _, default in ipairs(ns.DefaultCategories) do
        local category = present[default.id]
        if not category and NEW_CATEGORIES_V7[default.id] then
            table.insert(data.categories, CopyDefaultCategory(default))
        elseif category and NEW_ITEMS_V7[default.id] then
            local has = {}
            for _, item in ipairs(category.items) do
                has[item.action] = true
            end
            for _, action in ipairs(NEW_ITEMS_V7[default.id]) do
                if not has[action] then
                    for _, item in ipairs(default.items) do
                        if item.action == action then
                            table.insert(category.items, ns.DeepCopy(item))
                        end
                    end
                end
            end
        end
    end
end

local function PrepareData(data)
    data.categories = type(data.categories) == "table" and data.categories or {}
    data.favorites = type(data.favorites) == "table" and data.favorites or {}
    if data.version == nil then
        MigrateFromV2(data)
    end
    if (data.version or 0) < 4 then
        ApplyDefaultIcons(data)
    end
    if (data.version or 0) < 5 then
        TranslateLegacyDefaults(data)
    end
    if (data.version or 0) < 6 then
        UpgradeDefaultIcons(data)
    end
    if (data.version or 0) < 7 then
        AddNewDefaults(data)
    end
    if (data.version or 0) < 8 then
        -- 6.3.1 gave "Ask" its own icon instead of sharing the "Question" one
        for _, category in ipairs(data.categories) do
            for _, item in ipairs(category.items or {}) do
                if item.action == "/talkq" and item.icon == "@question" then
                    item.icon = "@ask"
                end
            end
        end
    end
    data.version = ns.DATA_VERSION
    for _, category in ipairs(data.categories) do
        category.items = category.items or {}
    end
end

function ns.InitDatabase()
    CharadesDB = CharadesDB or {}
    local db = CharadesDB
    -- Older builds stored "close after use" and later "keep open"; both became "hide after use"
    db.closeAfterUse = nil
    if db.keepOpen ~= nil then
        db.hideAfterUse = not db.keepOpen
        db.keepOpen = nil
    end

    for key, value in pairs(SETTING_DEFAULTS) do
        if db[key] == nil then
            db[key] = value
        end
    end

    -- 2.x kept categories and favorites directly in CharadesDB
    if db.shared == nil then
        if type(db.categories) == "table" then
            db.shared = { categories = db.categories, favorites = db.favorites or {} }
        else
            db.shared = ns.BuildDefaultData()
        end
    end
    db.categories = nil
    db.favorites = nil
    PrepareData(db.shared)

    CharadesCharDB = CharadesCharDB or {}
    if CharadesCharDB.data then
        PrepareData(CharadesCharDB.data)
    end

    ns.db = db
    ns.charDB = CharadesCharDB
    ns.SelectProfile()
end

-- Profiles -----------------------------------------------------------------

function ns.SelectProfile()
    if ns.charDB.useOwn and ns.charDB.data then
        ns.data = ns.charDB.data
    else
        ns.data = ns.db.shared
    end
end

function ns.IsUsingOwnProfile()
    return ns.charDB.useOwn and true or false
end

function ns.SetUseOwnProfile(enabled)
    ns.charDB.useOwn = enabled and true or false
    -- First switch copies the shared setup, so the character starts from what you already have
    if enabled and not ns.charDB.data then
        ns.charDB.data = ns.DeepCopy(ns.db.shared)
    end
    ns.SelectProfile()
    ns.RefreshAll()
end

function ns.ReplaceActiveData(data)
    PrepareData(data)
    if ns.IsUsingOwnProfile() then
        ns.charDB.data = data
    else
        ns.db.shared = data
    end
    ns.SelectProfile()
    ns.RefreshAll()
end

function ns.ResetToDefaults()
    ns.ReplaceActiveData(ns.BuildDefaultData())
end

-- Restores title and items of one built-in category, keeps its position and collapsed state
function ns.ResetCategory(index)
    local category = ns.data.categories[index]
    local default = category and ns.FindDefaultCategory(category.defaultId)
    if not default then
        return false
    end
    local restored = CopyDefaultCategory(default)
    restored.collapsed = category.collapsed
    ns.data.categories[index] = restored
    return true
end

-- Items and favorites ------------------------------------------------------

function ns.DefaultLabel(action)
    if string.find(action, "^/") then
        local command = string.match(action, "^/([^%s;]+)") or action
        return command
    end
    -- Cut by UTF-8 characters, never in the middle of a multi-byte character
    local characters = {}
    for character in string.gmatch(action, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(characters, character)
    end
    if #characters > 24 then
        return strtrim(table.concat(characters, "", 1, 21)) .. "..."
    end
    return action
end

function ns.IsFavorite(action)
    for _, favorite in ipairs(ns.data.favorites) do
        if favorite == action then
            return true
        end
    end
    return false
end

function ns.ToggleFavorite(action)
    for index, favorite in ipairs(ns.data.favorites) do
        if favorite == action then
            table.remove(ns.data.favorites, index)
            return false
        end
    end
    table.insert(ns.data.favorites, action)
    return true
end

-- Favorites store only actions; the label comes from the first item with that action
function ns.LabelFor(action)
    for _, category in ipairs(ns.data.categories) do
        for _, item in ipairs(category.items) do
            if item.action == action then
                return item.label
            end
        end
    end
    return ns.DefaultLabel(action)
end

function ns.IconFor(action)
    for _, category in ipairs(ns.data.categories) do
        for _, item in ipairs(category.items) do
            if item.action == action then
                return item.icon
            end
        end
    end
    return nil
end

function ns.MoveItem(list, index, delta)
    local target = index + delta
    if target < 1 or target > #list then
        return index
    end
    list[index], list[target] = list[target], list[index]
    return target
end

-- Search helper: lowercase and strip accents, so "cafe" finds "Café"
local FOLD_MAP = {
    ["á"] = "a", ["č"] = "c", ["ď"] = "d", ["é"] = "e", ["ě"] = "e", ["í"] = "i", ["ň"] = "n",
    ["ó"] = "o", ["ř"] = "r", ["š"] = "s", ["ť"] = "t", ["ú"] = "u", ["ů"] = "u", ["ý"] = "y", ["ž"] = "z",
    ["Á"] = "a", ["Č"] = "c", ["Ď"] = "d", ["É"] = "e", ["Ě"] = "e", ["Í"] = "i", ["Ň"] = "n",
    ["Ó"] = "o", ["Ř"] = "r", ["Š"] = "s", ["Ť"] = "t", ["Ú"] = "u", ["Ů"] = "u", ["Ý"] = "y", ["Ž"] = "z",
}

function ns.Fold(text)
    text = string.gsub(text or "", "[\195-\197][\128-\191]", function(char)
        return FOLD_MAP[char] or char
    end)
    return string.lower(text)
end

-- Refresh ------------------------------------------------------------------

function ns.UpdateBindingNames()
    for index = 1, ns.FAVORITE_BINDINGS do
        local action = ns.data and ns.data.favorites[index]
        if action then
            _G["BINDING_NAME_CHARADES_FAV" .. index] = "Favorite " .. index .. ": " .. ns.LabelFor(action)
        else
            _G["BINDING_NAME_CHARADES_FAV" .. index] = "Favorite " .. index .. " (empty)"
        end
    end
end

-- Called after any data change so all windows stay in sync
function ns.RefreshAll()
    if ns.RefreshPanel then
        ns.RefreshPanel()
    end
    if ns.RefreshEditor then
        ns.RefreshEditor()
    end
    ns.UpdateBindingNames()
end

-- UI helpers ---------------------------------------------------------------

function ns.CreateFonts()
    local function Make(name, size, r, g, b)
        local font = CreateFont(name)
        font:SetFont(ns.FONT_PATH, size, "")
        font:SetTextColor(r, g, b)
        return font
    end

    ns.fonts = {
        button = Make("CharadesButtonFont", 13, 1, 0.82, 0),
        buttonHighlight = Make("CharadesButtonHighlightFont", 13, 1, 1, 1),
        favorite = Make("CharadesFavoriteFont", 13, 1, 0.95, 0.7),
        header = Make("CharadesHeaderFont", 14, 0.9, 0.9, 0.9),
        gold = Make("CharadesGoldFont", 14, 1, 0.82, 0),
        small = Make("CharadesSmallFont", 12, 0.75, 0.75, 0.75),
        title = Make("CharadesTitleFont", 16, 1, 0.82, 0),
        wheelCenter = Make("CharadesWheelCenterFont", 15, 1, 1, 1),
    }
end

function ns.ApplyDialogBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
end

function ns.MakeMovable(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

function ns.AddTooltip(widget, title, lines)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(type(title) == "function" and title(self) or title)
        local resolved = type(lines) == "function" and lines(self) or lines
        for _, line in ipairs(resolved or {}) do
            GameTooltip:AddLine(line, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", GameTooltip_Hide)
end

-- Gold "favorite" look shared by the menu and the wheel
function ns.CreateFavoriteButton(parent, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    button:SetBackdropColor(0.32, 0.24, 0.04, 0.95)
    button:SetBackdropBorderColor(1, 0.82, 0, 1)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.15)

    local star = button:CreateTexture(nil, "ARTWORK")
    star:SetTexture(ns.STAR_TEXTURE)
    star:SetSize(12, 12)
    star:SetPoint("LEFT", 5, 0)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ns.ICON_SIZE, ns.ICON_SIZE)
    icon:SetPoint("LEFT", 20, 0)
    button.icon = icon

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(ns.fonts.favorite)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)
    button.label = text
    ns.SetFavoriteButtonContent(button, "", nil)
    return button
end

function ns.SetFavoriteButtonContent(button, label, icon)
    ns.SetIcon(button.icon, icon)
    button.label:ClearAllPoints()
    button.label:SetPoint("LEFT", ns.TextOffset(20), 0)
    button.label:SetPoint("RIGHT", -4, 0)
    button.label:SetText(label)
end
