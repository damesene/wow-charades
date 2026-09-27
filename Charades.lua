local addonName, ns = ...

BINDING_HEADER_CHARADES = "Charades"
BINDING_NAME_CHARADES_TOGGLE = "Open/close menu"
BINDING_NAME_CHARADES_WHEEL = "Wheel (hold, point, release)"
for index = 1, ns.FAVORITE_BINDINGS do
    _G["BINDING_NAME_CHARADES_FAV" .. index] = "Favorite " .. index
end

local minimapButton

function Charades_Toggle()
    if ns.panel then
        ns.panel:SetShown(not ns.panel:IsShown())
    end
end

local function UpdateMinimapButtonPosition()
    local angle = math.rad(ns.db.minimapAngle)
    local radius = (Minimap:GetWidth() / 2) + 10
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnMinimapDragUpdate()
    local centerX, centerY = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    ns.db.minimapAngle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
    UpdateMinimapButtonPosition()
end

local function CreateMinimapButton()
    local button = CreateFrame("Button", "CharadesMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ns.ICON)
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            ns.CloseMinimapMenu()
            Charades_Toggle()
        else
            ns.ToggleMinimapMenu(self)
        end
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", OnMinimapDragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    -- Same style as other minimap buttons: gold title, blue mouse button, plain description
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Charades", 1, 0.82, 0)
        GameTooltip:AddLine("|cff66b3ffLeft-click|r open the quick menu", 1, 1, 1)
        GameTooltip:AddLine("|cff66b3ffRight-click|r open the Charades window", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    return button
end

function ns.ApplyMinimapVisibility()
    if minimapButton then
        minimapButton:SetShown(not ns.db.hideMinimapButton)
    end
end

local function HandleSlashCommand(input)
    local command = string.lower(strtrim(input or ""))

    if command == "options" or command == "config" then
        ns.OpenEditor()
    elseif command == "minimap" then
        ns.db.hideMinimapButton = not ns.db.hideMinimapButton
        ns.ApplyMinimapVisibility()
        ns.RefreshAll()
        ns.Print(ns.db.hideMinimapButton and "minimap button hidden." or "minimap button shown.")
    elseif command == "autohide" then
        ns.db.hideAfterUse = not ns.db.hideAfterUse
        ns.RefreshAll()
        ns.Print(ns.db.hideAfterUse and "menu hides after use." or "menu stays open after use.")
    elseif command == "export" then
        ns.ShowExport()
    elseif command == "import" then
        ns.ShowImport()
    elseif command == "help" then
        ns.Print("/charades (menu), /charades options, /charades export, /charades import, /charades minimap, /charades autohide")
    else
        Charades_Toggle()
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")

    ns.InitDatabase()
    ns.CreateFonts()
    ns.CreatePanel()
    ns.CreateWheel()
    ns.CreateEditor()
    ns.UpdateBindingNames()

    minimapButton = CreateMinimapButton()
    UpdateMinimapButtonPosition()
    ns.ApplyMinimapVisibility()

    SLASH_CHARADES1 = "/charades"
    SlashCmdList.CHARADES = HandleSlashCommand
end)
