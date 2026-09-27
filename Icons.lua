local addonName, ns = ...

-- Icons are optional on categories and items. A value is a texture file ID (number)
-- or an icon name / path (string). Every button reserves the same icon slot whether
-- an icon is set or not, so labels never shift.

ns.ICON_SIZE = 16
ns.ICON_SLOT = 20 -- icon plus gap

-- Icons shipped with Charades (Icons folder), drawn from Lucide (ISC license, see Icons\LICENSE-Lucide.txt)
ns.CustomIcons = {
    { "wave", "wave hello hi greet bye hand" },
    { "bow", "bow greet respect person" },
    { "salute", "salute flag honor" },
    { "kneel", "kneel king queen royal crown" },
    { "thank", "thank thanks grateful" },
    { "bye", "bye leave goodbye door exit" },
    { "handshake", "handshake deal agree friend" },
    { "hug", "hug embrace friend" },
    { "talk", "talk say chat speak" },
    { "speech", "speech speak talk say" },
    { "question", "question ask what" },
    { "group", "group party friends people" },
    { "dance", "dance music party" },
    { "cheer", "cheer party celebrate hooray" },
    { "laugh", "laugh lol funny haha" },
    { "smile", "smile happy glad" },
    { "sad", "sad unhappy frown" },
    { "cry", "cry tears sad weep" },
    { "angry", "angry mad rage" },
    { "annoyed", "annoyed bored sigh" },
    { "meh", "meh shrug whatever" },
    { "shy", "shy hide blush" },
    { "kiss", "kiss love heart" },
    { "love", "love heart romance" },
    { "heartbreak", "heartbreak broken sad" },
    { "flirt", "flirt wink charm" },
    { "cool", "cool glasses smart" },
    { "applaud", "applaud clap bravo sparkle" },
    { "idea", "idea think lightbulb" },
    { "think", "think ponder brain" },
    { "flex", "flex muscle strong" },
    { "roar", "roar shout yell loud" },
    { "sit", "sit chair rest" },
    { "sleep", "sleep bed rest tired" },
    { "night", "night moon sleep" },
    { "point", "point there look" },
    { "look", "look see watch eye" },
    { "listen", "listen hear ear" },
    { "yes", "yes nod agree ok" },
    { "no", "no disagree shake" },
    { "check", "check done ok yes" },
    { "cross", "cross no cancel" },
    { "beg", "beg money please" },
    { "eat", "eat food meat hungry" },
    { "drink", "drink beer ale cheers" },
    { "wine", "wine drink toast" },
    { "coffee", "coffee tea cup" },
    { "cake", "cake birthday party" },
    { "walk", "walk steps travel" },
    { "wait", "wait time patience" },
    { "sing", "sing song mic" },
    { "guitar", "guitar music play" },
    { "drum", "drum music beat" },
    { "drama", "drama theater act roleplay masks" },
    { "gift", "gift present" },
    { "dice", "dice roll random luck" },
    { "game", "game play fun" },
    { "magic", "magic spell wand" },
    { "train", "train choo" },
    { "chicken", "chicken bird coward" },
    { "cat", "cat pet" },
    { "dog", "dog pet" },
    { "ghost", "ghost spooky boo" },
    { "rocket", "rocket launch fast" },
    { "rude", "rude fist threat" },
    { "fight", "fight duel battle swords" },
    { "sword", "sword attack weapon" },
    { "shield", "shield defend protect" },
    { "fire", "fire flame burn hot" },
    { "skull", "skull death danger" },
    { "bomb", "bomb explode boom" },
    { "target", "target aim focus" },
    { "alert", "alert warning danger" },
    { "trophy", "trophy win victory" },
    { "coins", "coins gold money" },
    { "gem", "gem jewel treasure" },
    { "key", "key unlock" },
    { "map", "map travel explore" },
    { "compass", "compass direction explore" },
    { "home", "home house hearth" },
    { "tent", "tent camp rest" },
    { "book", "book read story lore" },
    { "scroll", "scroll quest letter" },
    { "bell", "bell ring attention" },
    { "sun", "sun day warm" },
    { "snow", "snow cold winter" },
    { "flower", "flower nature gift" },
    { "tree", "tree forest nature" },
    { "mountain", "mountain climb" },
    { "star", "star favorite" },
    { "hello", "hello hi greet morning" },
    { "welcome", "welcome host serve greet" },
    { "hail", "hail salute honor" },
    { "curtsey", "curtsey bow polite" },
    { "grovel", "grovel beg kneel low" },
    { "commend", "commend praise award" },
    { "congrats", "congrats congratulate medal" },
    { "guffaw", "guffaw laugh loud" },
    { "talkex", "exclaim talk shout" },
    { "ask", "ask talk question conversation" },
    { "followme", "follow me lead way" },
    { "boggle", "boggle stare shock" },
    { "clap", "clap applause hands" },
    { "confused", "confused unsure" },
    { "curious", "curious search look" },
    { "gasp", "gasp shock breath" },
    { "gloat", "gloat brag smug" },
    { "golfclap", "golf clap polite" },
    { "mourn", "mourn grief funeral" },
    { "plead", "plead please beg" },
    { "pray", "pray prayer faith" },
    { "puzzled", "puzzled question huh" },
    { "chuckle", "chuckle laugh" },
    { "giggle", "giggle laugh cute" },
    { "violin", "violin music sad" },
    { "peon", "peon work mine" },
    { "party", "party fun celebrate" },
    { "rofl", "rofl laugh floor" },
    { "lay", "lay lie down rest" },
    { "feast", "feast food dinner" },
    { "cackle", "cackle evil laugh" },
    { "surrender", "surrender give up" },
    { "attacktarget", "attack target" },
    { "charge", "charge attack rush" },
    { "flee", "flee run away" },
    { "healme", "heal me healer" },
    { "helpme", "help me rescue" },
    { "incoming", "incoming enemy alarm" },
    { "oom", "oom out of mana" },
    { "openfire", "open fire attack" },
    { "taunt", "taunt provoke come" },
    { "insult", "insult offend" },
    { "lost", "lost where" },
    { "potion", "potion alchemy flask" },
    { "apple", "apple fruit food" },
    { "bread", "bread food bake" },
    { "meat", "meat food steak" },
    { "cookie", "cookie sweet snack" },
    { "candy", "candy sweet treat" },
    { "milk", "milk drink" },
    { "water", "water drink glass" },
    { "fish", "fish fishing" },
    { "axe", "axe weapon chop" },
    { "hammer", "hammer craft build" },
    { "archery", "bow arrow archery hunter" },
    { "feather", "feather light" },
    { "write", "write note journal" },
    { "letter", "letter mail message" },
    { "lantern", "lantern lamp light" },
    { "castle", "castle keep city" },
    { "anchor", "anchor sea port" },
    { "ship", "ship boat sail" },
    { "turtle", "turtle slow" },
    { "squirrel", "squirrel critter" },
    { "snail", "snail slow" },
    { "bug", "bug insect" },
    { "paw", "paw pet tracks" },
    { "bone", "bone dead" },
    { "sprout", "sprout grow plant" },
    { "clover", "clover luck" },
    { "leaf", "leaf nature" },
    { "umbrella", "umbrella rain" },
    { "rainbow", "rainbow color" },
    { "storm", "storm thunder weather" },
    { "shell", "shell beach sea" },
    { "pine", "pine forest tree" },
    { "peak", "peak snow mountain" },
    { "waves", "waves sea swim" },
    { "savings", "savings money bank" },
    { "rest", "rest eyes calm" },
    { "stars", "stars night sky" },
    { "alarm", "alarm bell ring" },
    { "baby", "baby child" },
    { "rat", "rat mouse critter" },
    { "quote", "quote say story" },
}
-- Hand-picked game icons with search words
ns.RecommendedIcons = {
    { "Ability_Warrior_BattleShout", "shout roar cheer" },
    { "Ability_Warrior_Charge", "charge attack run fight" },
    { "Ability_Rogue_Sprint", "run sprint fast leave bye" },
    { "Ability_Stealth", "sneak hide shy" },
    { "Ability_Hunter_BeastCall", "call wave greet hello" },
    { "Ability_Racial_BearForm", "bear strength flex" },
    { "Ability_Druid_CatForm", "cat" },
    { "Ability_Mount_RidingHorse", "horse ride travel" },
    { "Ability_Hunter_Pet_Wolf", "wolf dog" },
    { "Ability_Seal", "seal" },
    { "Spell_Nature_Sleep", "sleep night rest" },
    { "Spell_Nature_Polymorph", "sheep funny laugh" },
    { "Spell_Nature_Invisibilty", "invisible vanish" },
    { "Spell_Nature_Lightning", "lightning energy dance" },
    { "Spell_Nature_Rejuvenation", "nature leaf calm" },
    { "Spell_Holy_Heal", "heal light thank" },
    { "Spell_Holy_Renew", "renew kneel" },
    { "Spell_Holy_PrayerOfHealing02", "prayer beg bow greet" },
    { "Spell_Holy_MindVision", "eye look point" },
    { "Spell_Holy_HolyBolt", "light applaud" },
    { "Spell_Fire_Fire", "fire" },
    { "Spell_Frost_FrostBolt02", "frost cold tears cry" },
    { "Spell_Shadow_Charm", "charm flirt love mood" },
    { "Spell_Shadow_DeathScream", "scream fear roar" },
    { "Spell_Shadow_Possession", "possession rude evil" },
    { "INV_Misc_QuestionMark", "question mark ask" },
    { "INV_Misc_Note_01", "note text talk" },
    { "INV_Misc_Book_09", "book story" },
    { "INV_Scroll_03", "scroll" },
    { "INV_Letter_15", "letter message" },
    { "INV_Misc_Coin_01", "coin money gold" },
    { "INV_Misc_Bag_08", "bag other" },
    { "INV_Misc_Food_15", "food eat" },
    { "INV_Drink_05", "drink" },
    { "INV_Misc_Fish_02", "fish" },
    { "INV_Fishingpole_02", "fishing" },
    { "INV_Misc_Flower_02", "flower love kiss" },
    { "INV_Misc_Bone_HumanSkull_01", "skull death" },
    { "INV_Misc_Head_Dragon_01", "dragon" },
    { "INV_Misc_Rune_01", "rune home" },
    { "INV_Misc_Map_01", "map travel" },
    { "INV_Misc_Key_03", "key" },
    { "INV_Misc_Orb_01", "orb magic" },
    { "INV_Misc_Pocketwatch_01", "time watch wait" },
    { "INV_Jewelry_Ring_03", "ring" },
    { "INV_Sword_04", "sword fight salute" },
    { "INV_Shield_06", "shield defense" },
}

-- "@name" refers to an icon shipped in this addon's Icons folder
function ns.IconPath(icon)
    if type(icon) == "number" then
        return icon
    end
    if type(icon) == "string" and string.sub(icon, 1, 1) == "@" then
        return "Interface\\AddOns\\" .. addonName .. "\\Icons\\" .. string.sub(icon, 2)
    end
    if type(icon) == "string" and icon ~= "" then
        if string.find(icon, "\\", 1, true) then
            return icon
        end
        return "Interface\\Icons\\" .. icon
    end
    return nil
end

-- Accepts user input: a file ID, an icon name or a full path; returns a storable value or nil
function ns.ParseIcon(input)
    input = strtrim(input or "")
    if input == "" then
        return nil
    end
    if string.match(input, "^%d+$") then
        return tonumber(input)
    end
    if string.match(input, "^@[%w_%-]+$") or string.match(input, "^[%w_\\ %-]+$") then
        return input
    end
    return nil
end

function ns.IconsEnabled()
    return ns.db and ns.db.showIcons
end

-- Shows the icon in the fixed slot or leaves the slot empty
function ns.SetIcon(texture, icon)
    local path = ns.IconsEnabled() and ns.IconPath(icon)
    if path then
        texture:SetTexture(path)
        texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        texture:Show()
    else
        texture:Hide()
    end
end

-- Label position depends only on the global setting, never on whether this item has an icon
function ns.TextOffset(base)
    return base + (ns.IconsEnabled() and ns.ICON_SLOT or 0)
end

-- All icons the client offers for macros (the same set as the macro icon picker)
local allIcons
local function BuildAllIcons()
    allIcons = {}
    local seen = {}
    local function Collect(fill)
        if type(fill) ~= "function" then
            return
        end
        local list = {}
        if not pcall(fill, list) then
            return
        end
        for _, icon in ipairs(list) do
            if not seen[icon] then
                seen[icon] = true
                table.insert(allIcons, icon)
            end
        end
    end
    Collect(GetLooseMacroIcons)
    Collect(GetLooseMacroItemIcons)
    Collect(GetMacroIcons)
    Collect(GetMacroItemIcons)
end

-- Picker ---------------------------------------------------------------------

local COLUMNS, ROWS, CELL = 8, 6, 36
local picker
local pickerState = { tab = "charades", offset = 0, matches = {}, onPick = nil }

-- Every word of the query must appear (so "food 1" or "sword 2h" narrow the list)
local function MatchesAllWords(text, query)
    for word in string.gmatch(query, "%S+") do
        if not string.find(text, word, 1, true) then
            return false
        end
    end
    return true
end

local function CustomMatches(query)
    local matches = {}
    for _, entry in ipairs(ns.CustomIcons) do
        if query == "" or MatchesAllWords(entry[1] .. " " .. entry[2], query) then
            table.insert(matches, "@" .. entry[1])
        end
    end
    return matches
end

-- Game tab: the hand-picked icons first (with search words), then every classic game icon.
local gameIcons
local function BuildGameIcons()
    gameIcons = {}
    local seen = {}
    -- Skip icons the running client does not have, when the client can tell us
    local exists = GetFileIDFromPath and function(name)
        return GetFileIDFromPath("Interface\\Icons\\" .. name) ~= nil
    end or function() return true end
    for _, entry in ipairs(ns.RecommendedIcons) do
        local key = string.lower(entry[1])
        if not seen[key] and exists(entry[1]) then
            seen[key] = true
            table.insert(gameIcons, { icon = entry[1], search = key .. " " .. entry[2] })
        end
    end
    for _, name in ipairs(ns.GameIconNames or {}) do
        if not seen[name] and exists(name) then
            seen[name] = true
            table.insert(gameIcons, { icon = name, search = string.gsub(name, "_", " ") })
        end
    end
end

local function RecommendedMatches(query)
    if not gameIcons then
        BuildGameIcons()
    end
    local matches = {}
    for _, entry in ipairs(gameIcons) do
        if query == "" or MatchesAllWords(entry.search, query) then
            table.insert(matches, entry.icon)
        end
    end
    return matches
end

-- The full list usually holds only file IDs (the client exposes no names for them),
-- so it can be searched by number; a text query falls back to the named recommended icons.
local function AllMatches(query)
    if not allIcons then
        BuildAllIcons()
    end
    if query == "" then
        return allIcons, nil
    end
    local numeric = string.match(query, "^%d+$") ~= nil
    local matches = {}
    for _, icon in ipairs(allIcons) do
        local text = type(icon) == "number" and tostring(icon) or string.lower(icon)
        if (numeric or type(icon) == "string") and string.find(text, query, 1, true) then
            table.insert(matches, icon)
        end
    end
    if #matches == 0 and not numeric then
        return RecommendedMatches(query), "Names are only known for Game icons; showing those. In All, search by file number."
    end
    return matches, nil
end

local function RefreshPicker()
    local rawQuery = strtrim(picker.search:GetText() or "")
    local query = ns.Fold(rawQuery)
    local matches, note
    if pickerState.tab == "charades" then
        matches = CustomMatches(query)
    elseif pickerState.tab == "recommended" then
        matches = RecommendedMatches(query)
    else
        matches, note = AllMatches(query)
    end
    pickerState.matches = matches
    picker.searchPlaceholder:SetShown(rawQuery == "" and not picker.search:HasFocus())
    local placeholders = {
        charades = "Search by word, e.g. wave, laugh, sleep",
        recommended = "Search by word, e.g. food, sword, potion, fish",
        all = "Search by file number",
    }
    picker.searchPlaceholder:SetText(placeholders[pickerState.tab])

    local rowsTotal = math.ceil(#matches / COLUMNS)
    pickerState.offset = math.max(0, math.min(pickerState.offset, rowsTotal - ROWS))
    for index, cell in ipairs(picker.cells) do
        local icon = matches[pickerState.offset * COLUMNS + index]
        if icon then
            cell.icon = icon
            cell.texture:SetTexture(ns.IconPath(icon))
            cell:Show()
        else
            cell:Hide()
        end
    end

    picker.charadesTab:SetEnabled(pickerState.tab ~= "charades")
    picker.recommendedTab:SetEnabled(pickerState.tab ~= "recommended")
    picker.allTab:SetEnabled(pickerState.tab ~= "all")
    if pickerState.tab == "all" and #allIcons == 0 then
        picker.info:SetText("The client provides no icon list, use Charades or Game, or enter a name.")
    elseif note then
        picker.info:SetText(note)
    elseif #matches == 0 then
        picker.info:SetText("No icons found.")
    else
        picker.info:SetText(#matches .. " icons (mouse wheel)")
    end
end

local function Pick(icon)
    picker:Hide()
    if pickerState.onPick then
        pickerState.onPick(icon)
    end
end

local function CreateTabButton(text, tab)
    local button = CreateFrame("Button", nil, picker, "UIPanelButtonTemplate")
    button:SetSize(94, 22)
    button:SetNormalFontObject(ns.fonts.button)
    button:SetHighlightFontObject(ns.fonts.buttonHighlight)
    button:SetDisabledFontObject(ns.fonts.buttonHighlight)
    button:SetText(text)
    button:SetScript("OnClick", function()
        pickerState.tab = tab
        pickerState.offset = 0
        RefreshPicker()
    end)
    return button
end

local function CreatePicker()
    picker = CreateFrame("Frame", "CharadesIconPicker", UIParent, "BackdropTemplate")
    picker:SetSize(COLUMNS * CELL + 44, ROWS * CELL + 206)
    picker:SetFrameStrata("FULLSCREEN_DIALOG")
    ns.ApplyDialogBackdrop(picker)
    ns.MakeMovable(picker)
    picker:Hide()
    table.insert(UISpecialFrames, "CharadesIconPicker")

    local title = picker:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(ns.fonts.title)
    title:SetPoint("TOP", 0, -16)
    title:SetText("Choose icon")
    local close = CreateFrame("Button", nil, picker, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    picker.charadesTab = CreateTabButton("Charades", "charades")
    picker.charadesTab:SetPoint("TOPLEFT", 22, -40)
    picker.recommendedTab = CreateTabButton("Game", "recommended")
    picker.recommendedTab:SetPoint("LEFT", picker.charadesTab, "RIGHT", 4, 0)
    picker.allTab = CreateTabButton("All", "all")
    picker.allTab:SetPoint("LEFT", picker.recommendedTab, "RIGHT", 4, 0)

    local search = CreateFrame("EditBox", nil, picker, "InputBoxTemplate")
    search:SetSize(COLUMNS * CELL - 6, 20)
    search:SetPoint("TOPLEFT", 28, -68)
    search:SetAutoFocus(false)
    search:SetFontObject(ns.fonts.buttonHighlight)
    search:SetScript("OnEscapePressed", search.ClearFocus)
    search:SetScript("OnEnterPressed", search.ClearFocus)
    search:SetScript("OnTextChanged", function()
        pickerState.offset = 0
        RefreshPicker()
    end)
    search:SetScript("OnEditFocusGained", function() picker.searchPlaceholder:Hide() end)
    search:SetScript("OnEditFocusLost", function() RefreshPicker() end)
    picker.search = search

    local placeholder = search:CreateFontString(nil, "OVERLAY")
    placeholder:SetFontObject(ns.fonts.small)
    placeholder:SetPoint("LEFT", 2, 0)
    picker.searchPlaceholder = placeholder

    picker.cells = {}
    for index = 1, COLUMNS * ROWS do
        local column = (index - 1) % COLUMNS
        local row = math.floor((index - 1) / COLUMNS)
        local cell = CreateFrame("Button", nil, picker)
        cell:SetSize(CELL - 4, CELL - 4)
        cell:SetPoint("TOPLEFT", 22 + column * CELL, -96 - row * CELL)
        cell.texture = cell:CreateTexture(nil, "ARTWORK")
        cell.texture:SetAllPoints()
        cell.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local highlight = cell:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.25)
        cell:SetScript("OnClick", function(self) Pick(self.icon) end)
        ns.AddTooltip(cell, function(self)
            if type(self.icon) == "number" then
                return "File " .. self.icon
            end
            return (string.gsub(tostring(self.icon), "^@", ""))
        end)
        picker.cells[index] = cell
    end

    local gridBottom = -96 - ROWS * CELL
    picker.info = picker:CreateFontString(nil, "OVERLAY")
    picker.info:SetFontObject(ns.fonts.small)
    picker.info:SetPoint("TOPLEFT", 22, gridBottom - 4)
    picker.info:SetWidth(COLUMNS * CELL)
    picker.info:SetJustifyH("LEFT")
    picker.info:SetWordWrap(true)

    local customLabel = picker:CreateFontString(nil, "OVERLAY")
    customLabel:SetFontObject(ns.fonts.small)
    customLabel:SetPoint("TOPLEFT", 22, gridBottom - 34)
    customLabel:SetText("Custom: icon name or file ID")

    local custom = CreateFrame("EditBox", nil, picker, "InputBoxTemplate")
    custom:SetSize(COLUMNS * CELL - 70, 20)
    custom:SetPoint("TOPLEFT", 28, gridBottom - 50)
    custom:SetAutoFocus(false)
    custom:SetFontObject(ns.fonts.buttonHighlight)
    custom:SetScript("OnEscapePressed", custom.ClearFocus)
    local function UseCustom()
        local icon = ns.ParseIcon(custom:GetText())
        if icon then
            Pick(icon)
        else
            picker.info:SetText("|cffff5555Enter a name (e.g. Spell_Nature_Sleep) or a number.|r")
        end
    end
    custom:SetScript("OnEnterPressed", UseCustom)
    picker.custom = custom

    local useButton = CreateFrame("Button", nil, picker, "UIPanelButtonTemplate")
    useButton:SetSize(56, 22)
    useButton:SetPoint("LEFT", custom, "RIGHT", 8, 0)
    useButton:SetText("OK")
    useButton:SetScript("OnClick", UseCustom)

    local none = CreateFrame("Button", nil, picker, "UIPanelButtonTemplate")
    none:SetSize(120, 22)
    none:SetPoint("BOTTOMLEFT", 20, 18)
    none:SetNormalFontObject(ns.fonts.button)
    none:SetHighlightFontObject(ns.fonts.buttonHighlight)
    none:SetText("No icon")
    none:SetScript("OnClick", function() Pick(false) end)

    picker:EnableMouseWheel(true)
    picker:SetScript("OnMouseWheel", function(_, delta)
        pickerState.offset = pickerState.offset - delta
        RefreshPicker()
    end)
end

-- onPick receives the icon value, or false for "no icon"
function ns.OpenIconPicker(anchor, onPick)
    if not picker then
        CreatePicker()
    end
    pickerState.onPick = onPick
    pickerState.offset = 0
    picker.search:SetText("")
    picker.custom:SetText("")
    picker:ClearAllPoints()
    picker:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
    picker:Show()
    RefreshPicker()
end

function ns.CloseIconPicker()
    if picker then
        picker:Hide()
    end
end
