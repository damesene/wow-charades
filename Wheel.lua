local _, ns = ...

-- Radial menu: inner ring = categories (Favorites first and open by default),
-- outer ring = items of the open category fanned out around it.
-- Hold the key, point at a category to open it, point further out at an item, release to use it.

local NODE_WIDTH, NODE_HEIGHT = 104, 22
local ITEM_WIDTH, ITEM_HEIGHT = 124, 24
local MAX_NODES = 13 -- Favorites + 12 categories
local MAX_ITEMS = 24
local MAX_FAN_SPAN = 300 -- wider fans switch to a full circle
local FAN_SELECT_TOLERANCE = 30 -- degrees; pointing further from the fan selects nothing
local DEAD_ZONE = 26
local NODE_HOVER_PADDING = 6

local wheel
local catcher -- invisible full-screen frame under the wheel that receives clicks outside the boxes
local nodes, items = {}, {}
local sources = {}
local openIndex
local selectedItem
local innerRadius, outerRadius = 70, 180
local itemCount, fanMode = 0, true

-- Style ------------------------------------------------------------------

local STYLES = {
    favorite = { bg = { 0.32, 0.24, 0.04, 0.95 }, border = { 1, 0.82, 0, 1 }, activeBg = { 0.55, 0.42, 0.08, 1 } },
    normal = { bg = { 0.08, 0.08, 0.08, 0.92 }, border = { 0.55, 0.55, 0.55, 1 }, activeBg = { 0.25, 0.25, 0.25, 1 } },
}

local function ApplyStyle(box, active)
    local style = STYLES[box.style]
    local bg = active and style.activeBg or style.bg
    box:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    if active then
        box:SetBackdropBorderColor(1, 1, 1, 1)
    else
        box:SetBackdropBorderColor(style.border[1], style.border[2], style.border[3], style.border[4])
    end
end

local function CreateBox(width, height)
    local box = CreateFrame("Button", nil, wheel, "BackdropTemplate")
    box:SetSize(width, height)
    box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

    local star = box:CreateTexture(nil, "ARTWORK")
    star:SetTexture(ns.STAR_TEXTURE)
    star:SetSize(12, 12)
    star:SetPoint("LEFT", 5, 0)
    box.star = star

    local icon = box:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ns.ICON_SIZE, ns.ICON_SIZE)
    icon:SetPoint("LEFT", 20, 0)
    box.icon = icon

    local text = box:CreateFontString(nil, "OVERLAY")
    text:SetJustifyH("CENTER")
    text:SetWordWrap(false)
    box.label = text
    return box
end

-- The star slot and the icon slot are always reserved, so labels line up in every box
local function SetBoxContent(box, style, text, icon)
    box.style = style
    box.star:SetShown(style == "favorite")
    ns.SetIcon(box.icon, icon)
    box.label:SetFontObject(style == "favorite" and ns.fonts.favorite or ns.fonts.button)
    box.label:ClearAllPoints()
    box.label:SetPoint("LEFT", ns.TextOffset(20), 0)
    box.label:SetPoint("RIGHT", -4, 0)
    box.label:SetText(text)
    ApplyStyle(box, false)
end

-- Geometry ---------------------------------------------------------------

local function Overlaps(radius, angleA, angleB, width, height)
    local dx = radius * (math.cos(math.rad(angleA)) - math.cos(math.rad(angleB)))
    local dy = radius * (math.sin(math.rad(angleA)) - math.sin(math.rad(angleB)))
    return math.abs(dx) < width + 4 and math.abs(dy) < height + 4
end

-- Smallest radius at which neighbouring boxes do not overlap
local function FitRadius(angles, width, height, minimum, closed)
    for radius = minimum, 420, 4 do
        local fits = true
        for index = 1, #angles - 1 do
            if Overlaps(radius, angles[index], angles[index + 1], width, height) then
                fits = false
                break
            end
        end
        if fits and closed and #angles > 2 and Overlaps(radius, angles[#angles], angles[1], width, height) then
            fits = false
        end
        if fits then
            return radius
        end
    end
    return 420
end

-- Places items clockwise with the smallest gaps that avoid overlap, centred on centerAngle.
-- Boxes are wide, so gaps are larger at the top and bottom than at the sides.
local function PlaceFan(count, centerAngle, radius)
    local angles, span = {}, 0
    for _ = 1, 4 do -- a few passes let the centring converge
        angles = { centerAngle + span / 2 }
        for index = 2, count do
            local previous = angles[index - 1]
            local candidate = previous - 1
            while Overlaps(radius, previous, candidate, ITEM_WIDTH, ITEM_HEIGHT) and previous - candidate < 180 do
                candidate = candidate - 1
            end
            angles[index] = candidate
        end
        span = angles[1] - angles[count]
    end
    return angles, span
end

local function AngleDistance(a, b)
    local difference = math.abs(a - b) % 360
    return difference > 180 and 360 - difference or difference
end

local function Place(box, angle, radius)
    box.angle = angle
    box.x = math.cos(math.rad(angle)) * radius
    box.y = math.sin(math.rad(angle)) * radius
    box:ClearAllPoints()
    box:SetPoint("CENTER", wheel, "CENTER", box.x, box.y)
end

local function ResizeWheel()
    local extent = math.max(outerRadius, innerRadius) + ITEM_WIDTH
    wheel:SetSize(extent * 2, extent * 2)
end

-- Content ----------------------------------------------------------------

local function BuildSources()
    sources = {}
    local favorites = { title = "Favorites", style = "favorite", entries = {} }
    for _, action in ipairs(ns.data.favorites) do
        table.insert(favorites.entries, { label = ns.LabelFor(action), action = action, icon = ns.IconFor(action) })
    end
    table.insert(sources, favorites)

    for _, category in ipairs(ns.data.categories) do
        if #sources >= MAX_NODES then
            break
        end
        local source = { title = category.title, icon = category.icon, style = "normal", entries = {} }
        for _, item in ipairs(category.items) do
            table.insert(source.entries, { label = item.label, action = item.action, icon = item.icon })
        end
        table.insert(sources, source)
    end
end

local function UpdateCenterText()
    if selectedItem then
        wheel.center:SetText(selectedItem.labelText)
    elseif openIndex then
        local source = sources[openIndex]
        wheel.center:SetText(#source.entries > 0 and source.title or (source.title .. ": empty"))
    end
end

local function SelectItem(item)
    if selectedItem == item then
        return
    end
    if selectedItem then
        ApplyStyle(selectedItem, false)
    end
    selectedItem = item
    if item then
        ApplyStyle(item, true)
    end
    UpdateCenterText()
end

local function OpenCategory(index)
    openIndex = index
    selectedItem = nil
    for nodeIndex = 1, #sources do
        ApplyStyle(nodes[nodeIndex], nodeIndex == index)
    end

    local source = sources[index]
    local count = math.min(#source.entries, MAX_ITEMS)
    local centerAngle = nodes[index].angle
    local angles = {}

    -- A fan around the open category; if it cannot fit even at a larger radius, a full circle
    local minimumRadius = innerRadius + (NODE_WIDTH + ITEM_WIDTH) / 2 + 10
    fanMode = false
    if count > 0 then
        for radius = minimumRadius, 300, 20 do
            local fanAngles, span = PlaceFan(count, centerAngle, radius)
            if span <= MAX_FAN_SPAN then
                angles, outerRadius, fanMode = fanAngles, radius, true
                break
            end
        end
    end
    if not fanMode then
        for itemIndex = 1, count do
            angles[itemIndex] = centerAngle - (itemIndex - 1) * 360 / count
        end
        outerRadius = FitRadius(angles, ITEM_WIDTH, ITEM_HEIGHT, minimumRadius, true)
    end

    for itemIndex = 1, MAX_ITEMS do
        local item = items[itemIndex]
        local entry = source.entries[itemIndex]
        if itemIndex <= count then
            item.action = entry.action
            item.labelText = entry.label
            SetBoxContent(item, source.style, entry.label, entry.icon)
            Place(item, angles[itemIndex], outerRadius)
            item:Show()
        else
            item:Hide()
        end
    end
    itemCount = count
    ResizeWheel()
    UpdateCenterText()
end

local function NodeUnderCursor(dx, dy)
    for index = 1, #sources do
        local node = nodes[index]
        if math.abs(dx - node.x) <= NODE_WIDTH / 2 + NODE_HOVER_PADDING
            and math.abs(dy - node.y) <= NODE_HEIGHT / 2 + NODE_HOVER_PADDING then
            return index
        end
    end
    return nil
end

local function OnUpdate()
    local scale = wheel:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    local centerX, centerY = wheel:GetCenter()
    local dx, dy = cursorX / scale - centerX, cursorY / scale - centerY

    -- Pointing at a category opens it
    local nodeIndex = NodeUnderCursor(dx, dy)
    if nodeIndex then
        if nodeIndex ~= openIndex then
            OpenCategory(nodeIndex)
        end
        SelectItem(nil)
        return
    end

    local distance = math.sqrt(dx * dx + dy * dy)
    if distance < math.max(DEAD_ZONE, innerRadius + NODE_HEIGHT) or itemCount == 0 then
        SelectItem(nil)
        return
    end

    local angle = math.deg(math.atan2(dy, dx))
    local best, bestDistance
    for index = 1, itemCount do
        local itemDistance = AngleDistance(angle, items[index].angle)
        if not bestDistance or itemDistance < bestDistance then
            best, bestDistance = items[index], itemDistance
        end
    end
    -- In a fan, pointing well away from it selects nothing
    if fanMode and bestDistance > FAN_SELECT_TOLERANCE then
        best = nil
    end
    SelectItem(best)
end

local function CloseWheel(runSelected)
    if not wheel:IsShown() then
        return
    end
    local action = runSelected and selectedItem and selectedItem.action
    selectedItem = nil
    wheel:Hide()
    catcher:Hide()
    if action then
        ns.RunAction(action)
    end
end

-- Mouse buttons while the wheel is open (on a box or anywhere else on screen)
local function OnWheelMouseDown(mouseButton)
    if mouseButton == "RightButton" then
        if ns.db.wheelRightClickCancels then
            CloseWheel(false)
        end
    elseif mouseButton == "LeftButton" and ns.db.wheelConfirmClick and selectedItem then
        CloseWheel(true)
    end
end

local function OpenWheel()
    if not ns.data then
        return
    end
    BuildSources()

    local count = #sources
    local angles = {}
    for index = 1, count do
        -- Favorites on top, categories clockwise
        angles[index] = 90 - (index - 1) * 360 / count
    end
    innerRadius = count > 1 and FitRadius(angles, NODE_WIDTH, NODE_HEIGHT, 70, true) or 70

    for index = 1, MAX_NODES do
        local node = nodes[index]
        if index <= count then
            SetBoxContent(node, sources[index].style, sources[index].title, sources[index].icon)
            Place(node, angles[index], innerRadius)
            node:Show()
        else
            node:Hide()
        end
    end

    -- Open the wheel so the Favorites node sits right under the cursor: its items fan out
    -- just above, so a short flick up picks one
    local scale = UIParent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    wheel:ClearAllPoints()
    wheel:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cursorX / scale, cursorY / scale - innerRadius)

    OpenCategory(1)
    catcher:Show()
    wheel:Show()
end

-- Called from the key binding with keystate "down" or "up"
function Charades_Wheel(keystate)
    if not wheel then
        return
    end
    if keystate == "down" then
        OpenWheel()
    else
        -- With click-to-confirm, releasing the key only closes the wheel: nothing runs by accident
        CloseWheel(not ns.db.wheelConfirmClick)
    end
end

function ns.CreateWheel()
    catcher = CreateFrame("Frame", "CharadesWheelCatcher", UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    catcher:SetFrameLevel(1)
    catcher:EnableMouse(true)
    catcher:SetScript("OnMouseDown", function(_, mouseButton) OnWheelMouseDown(mouseButton) end)
    catcher:Hide()

    wheel = CreateFrame("Frame", "CharadesWheel", UIParent)
    wheel:SetFrameStrata("FULLSCREEN_DIALOG")
    wheel:SetFrameLevel(10)
    wheel:Hide()
    wheel:SetScript("OnUpdate", OnUpdate)
    wheel:SetScript("OnHide", function() catcher:Hide() end)
    -- Escape closes the wheel without doing anything
    table.insert(UISpecialFrames, "CharadesWheel")

    local hub = wheel:CreateTexture(nil, "BACKGROUND")
    hub:SetSize(DEAD_ZONE * 2, DEAD_ZONE * 2)
    hub:SetPoint("CENTER")
    hub:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    hub:SetVertexColor(0, 0, 0, 0.6)

    local center = wheel:CreateFontString(nil, "OVERLAY")
    center:SetFontObject(ns.fonts.wheelCenter)
    center:SetPoint("CENTER")
    wheel.center = center

    for index = 1, MAX_NODES do
        local node = CreateBox(NODE_WIDTH, NODE_HEIGHT)
        node.index = index
        node:SetScript("OnClick", function(self) OpenCategory(self.index) end)
        node:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton == "RightButton" then
                OnWheelMouseDown(mouseButton)
            end
        end)
        node:Hide()
        nodes[index] = node
    end

    for index = 1, MAX_ITEMS do
        local item = CreateBox(ITEM_WIDTH, ITEM_HEIGHT)
        -- Clicking works too, for people who prefer it over releasing the key
        item:SetScript("OnClick", function(self)
            SelectItem(self)
            CloseWheel(true)
        end)
        item:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton == "RightButton" then
                OnWheelMouseDown(mouseButton)
            end
        end)
        item:Hide()
        items[index] = item
    end

    ns.wheel = wheel
end
