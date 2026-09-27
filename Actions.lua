local _, ns = ...

-- An action is what an item does when used:
--   "/dance"             emote (with its animation)
--   "/any command args"  any slash command, including other addons' commands
--   "/e waves happily"   chat commands (/s, /y, /e) are sent directly
--   "Hello there"        text without a slash is said aloud (/say)
--   "/bow; /wait 1; Hi"  steps separated by ";", /wait N changes the pause before the next step

local DEFAULT_STEP_GAP = 2

local CHAT_TYPES = {
    ["/s"] = "SAY", ["/say"] = "SAY",
    ["/y"] = "YELL", ["/yell"] = "YELL", ["/sh"] = "YELL", ["/shout"] = "YELL",
    ["/e"] = "EMOTE", ["/em"] = "EMOTE", ["/me"] = "EMOTE", ["/emote"] = "EMOTE",
}

local emoteList
local emoteByCommand

-- The client defines every emote as EMOTE<n>_TOKEN with its commands in EMOTE<n>_CMD1..4
local function BuildEmoteList()
    emoteList = {}
    emoteByCommand = {}
    for index = 1, 1000 do
        local token = _G["EMOTE" .. index .. "_TOKEN"]
        if type(token) == "string" then
            for commandIndex = 1, 4 do
                local command = _G["EMOTE" .. index .. "_CMD" .. commandIndex]
                if type(command) == "string" then
                    emoteByCommand[string.lower(command)] = token
                end
            end
            local primary = _G["EMOTE" .. index .. "_CMD1"]
            if type(primary) == "string" then
                local aliases = {}
                for commandIndex = 1, 4 do
                    local command = _G["EMOTE" .. index .. "_CMD" .. commandIndex]
                    if type(command) == "string" then
                        table.insert(aliases, string.lower(command))
                    end
                end
                table.insert(emoteList, { token = token, command = string.lower(primary), aliases = aliases })
            end
        end
    end

    -- Fallback when the client does not expose the list: at least the built-in emotes
    if #emoteList == 0 then
        for _, category in ipairs(ns.DefaultCategories) do
            for _, item in ipairs(category.items) do
                local command = string.lower(item.action)
                if not emoteByCommand[command] then
                    local token = string.upper(string.sub(command, 2))
                    emoteByCommand[command] = token
                    table.insert(emoteList, { token = token, command = command, aliases = { command } })
                end
            end
        end
    end

    table.sort(emoteList, function(a, b) return a.command < b.command end)
end

function ns.GetEmoteList()
    if not emoteList then
        BuildEmoteList()
    end
    return emoteList
end

local function EmoteTokenFor(command)
    if not emoteByCommand then
        BuildEmoteList()
    end
    return emoteByCommand[command]
end

local function SendChat(message, chatType)
    if not message or message == "" then
        return
    end
    local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    send(message, chatType)
end

local function ListHasCommand(list, command)
    if type(list) ~= "table" then
        return false
    end
    for key in pairs(list) do
        local index = 1
        while true do
            local alias = _G["SLASH_" .. key .. index]
            if not alias then
                break
            end
            if string.lower(alias) == command then
                return true, key
            end
            index = index + 1
        end
    end
    return false
end

-- Lets the chat box handle the command exactly as if it was typed
local function SendViaChatBox(text)
    if not (ChatEdit_ChooseBoxForSend and ChatEdit_SendText) then
        return false
    end
    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then
        return false
    end
    editBox:SetText(text)
    ChatEdit_SendText(editBox, 0)
    return true
end

local function ExecuteStep(step)
    if not string.find(step, "^/") then
        SendChat(step, "SAY")
        return
    end

    local command, rest = string.match(step, "^(%S+)%s*(.-)$")
    command = string.lower(command)

    local chatType = CHAT_TYPES[command]
    if chatType then
        SendChat(rest, chatType)
        return
    end

    local token = EmoteTokenFor(command)
    if token then
        DoEmote(token)
        return
    end

    -- /cast, /use, /target and similar are protected; calling them from an addon only triggers a block
    if ListHasCommand(SecureCmdList, command) then
        ns.Print(command .. " is a protected Blizzard command, addons cannot run it.")
        return
    end

    if SendViaChatBox(step) then
        return
    end

    local found, key = ListHasCommand(SlashCmdList, command)
    if found then
        SlashCmdList[key](rest, DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox)
        return
    end

    ns.Print("unknown command: " .. command)
end

function ns.SplitSteps(action)
    local steps = {}
    for part in string.gmatch(action or "", "[^;]+") do
        local step = strtrim(part)
        if step ~= "" then
            table.insert(steps, step)
        end
    end
    return steps
end

local pendingTimers = {}

local function CancelPending()
    for _, timer in ipairs(pendingTimers) do
        timer:Cancel()
    end
    pendingTimers = {}
end

function ns.RunAction(action)
    -- A new action interrupts a sequence that is still running
    CancelPending()

    local delay = 0
    local first = true
    local gap
    for _, step in ipairs(ns.SplitSteps(action)) do
        local wait = string.match(step, "^/wait%s+([%d%.]+)$")
        if wait then
            gap = tonumber(wait)
        else
            if first then
                delay = gap or 0
            else
                delay = delay + (gap or DEFAULT_STEP_GAP)
            end
            gap = nil
            first = false
            if delay <= 0 then
                ExecuteStep(step)
            else
                table.insert(pendingTimers, C_Timer.NewTimer(delay, function() ExecuteStep(step) end))
            end
        end
    end
end

-- Used by the menu: runs the action and hides the menu when "hide after use" is on
function ns.PerformAction(action)
    ns.RunAction(action)
    if ns.db.hideAfterUse and ns.panel then
        ns.panel:Hide()
    end
end

function Charades_RunFavorite(index)
    local action = ns.data and ns.data.favorites[index]
    if action then
        ns.RunAction(action)
    end
end
