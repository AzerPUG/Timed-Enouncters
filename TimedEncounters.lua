-- TODO
    -- Draggable
    -- Remember location
    -- Remember Hide/Show

if AZP == nil then AZP = {} end
if AZP.VersionControl == nil then AZP.VersionControl = {} end
if AZP.OnLoad == nil then AZP.OnLoad = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end

AZP.VersionControl.TimedEncounters = 1
AZP.TimedEncounters = {}

local AZPTETimerFrame, AZPTECombatBar, TEUpdateFrame = nil, nil, nil
local BossHPBar = nil
local TEOptionsPanel
local HaveShowedUpdateNotification = false
EncounterTrackingData = {}
local EcounterTrackingEditBoxes = {}

local moveable = false
local EncounterTimer = nil

local tempFrame

function AZP.TimedEncounters:OnLoad()
    local EventFrame = CreateFrame("FRAME", nil)
    EventFrame:RegisterEvent("CHAT_MSG_ADDON")
    EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    EventFrame:RegisterEvent("ENCOUNTER_START")
    EventFrame:RegisterEvent("ENCOUNTER_END")
    EventFrame:RegisterEvent("VARIABLES_LOADED")
    EventFrame:SetScript("OnEvent", AZP.TimedEncounters.OnEvent)

    C_ChatInfo.RegisterAddonMessagePrefix("AZPVERSIONS")

    TEUpdateFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    TEUpdateFrame:SetPoint("CENTER", 0, 250)
    TEUpdateFrame:SetSize(400, 200)
    TEUpdateFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    TEUpdateFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)
    TEUpdateFrame.header = TEUpdateFrame:CreateFontString("TEUpdateFrame", "ARTWORK", "GameFontNormalHuge")
    TEUpdateFrame.header:SetPoint("TOP", 0, -10)
    TEUpdateFrame.header:SetText("|cFFFF0000TimedEncounters is out of date!|r")

    TEUpdateFrame.text = TEUpdateFrame:CreateFontString("TEUpdateFrame", "ARTWORK", "GameFontNormalLarge")
    TEUpdateFrame.text:SetPoint("TOP", 0, -40)
    TEUpdateFrame.text:SetText("Error!")

    local TEUpdateFrameCloseButton = CreateFrame("Button", nil, TEUpdateFrame, "UIPanelCloseButton")
    TEUpdateFrameCloseButton:SetWidth(25)
    TEUpdateFrameCloseButton:SetHeight(25)
    TEUpdateFrameCloseButton:SetPoint("TOPRIGHT", TEUpdateFrame, "TOPRIGHT", 2, 2)
    TEUpdateFrameCloseButton:SetScript("OnClick", function() TEUpdateFrame:Hide() end )

    TEOptionsPanel = CreateFrame("FRAME", nil)
    TEOptionsPanel.name = "Timed Encounters"
    InterfaceOptions_AddCategory(TEOptionsPanel)

    local OptionsPanelTitle = TEOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    OptionsPanelTitle:SetText("Timed Encounters Options Panel")
    OptionsPanelTitle:SetWidth(TEOptionsPanel:GetWidth())
    OptionsPanelTitle:SetHeight(25)
    OptionsPanelTitle:SetPoint("TOP", 0, -10)

    TEOptionsPanel:Hide()

    for i = 1, 10 do
        EncounterTrackingData[i] = {}
        local counterFrame = CreateFrame("Frame", nil, TEOptionsPanel)
        counterFrame:SetSize(200, 25)
        counterFrame:SetPoint("LEFT", 75, -30*i + 250)
        counterFrame.timeEditBox = CreateFrame("EditBox", nil, counterFrame, "InputBoxTemplate")
        counterFrame.timeEditBox:SetSize(100, 25)
        counterFrame.timeEditBox:SetPoint("LEFT", 50, 0)
        counterFrame.timeEditBox:SetAutoFocus(false)
        counterFrame.timeEditBox:SetNumeric(true)
        counterFrame.healthEditBox = CreateFrame("EditBox", nil, counterFrame, "InputBoxTemplate")
        counterFrame.healthEditBox:SetSize(100, 25)
        counterFrame.healthEditBox:SetPoint("LEFT", 175, 0)
        counterFrame.healthEditBox:SetAutoFocus(false)
        counterFrame.healthEditBox:SetNumeric(true)
        counterFrame.text = counterFrame:CreateFontString("counterFrame", "ARTWORK", "GameFontNormalLarge")
        counterFrame.text:SetSize(100, 25)
        counterFrame.text:SetPoint("LEFT", -50, 0)
        counterFrame.text:SetText("Checkpoint " .. i .. ":")

        EcounterTrackingEditBoxes[i] = counterFrame
        counterFrame.timeEditBox:SetScript("OnEditFocusLost", function() AZP.TimedEncounters:PullNumbersFromEditBox(i) end)
        counterFrame.healthEditBox:SetScript("OnEditFocusLost", function() AZP.TimedEncounters:PullNumbersFromEditBox(i) end)
    end

    local AZPTEToggleMoveButton = CreateFrame("Button", nil, TEOptionsPanel, "UIPanelButtonTemplate")
    AZPTEToggleMoveButton:SetText("Toggle Movement!")
    AZPTEToggleMoveButton:SetSize(100, 25)
    AZPTEToggleMoveButton:SetPoint("TOP", 100, -50)
    AZPTEToggleMoveButton:SetScript("OnClick",
    function()
        if moveable == false then
            AZPTETimerFrame:SetMovable(true)
            AZPTETimerFrame:EnableMouse(true)
            AZPTETimerFrame:RegisterForDrag("LeftButton")
            AZPTETimerFrame:Show()
            AZPTECombatBar:SetMovable(true)
            AZPTECombatBar:EnableMouse(true)
            AZPTECombatBar:RegisterForDrag("LeftButton")
            AZPTECombatBar:Show()
            AZPTECombatBar:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                edgeSize = 12,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            AZPTECombatBar:SetBackdropColor(0.5, 0.5, 0.5, 0.75)
            moveable = true
        else
            AZPTETimerFrame:SetMovable(false)
            AZPTETimerFrame:EnableMouse(false)
            AZPTETimerFrame:RegisterForDrag()
            AZPTECombatBar:SetMovable(false)
            AZPTECombatBar:EnableMouse(false)
            AZPTECombatBar:RegisterForDrag()
            AZPTECombatBar:Hide()
            AZPTECombatBar:SetBackdrop({
                bgFile = nil,
                edgeFile = nil,
                edgeSize = nil,
                insets = { left = 1, right = 1, top = 1, bottom = 1 },
            })
            AZPTECombatBar:SetBackdropColor(0, 0, 0, 0)
            local x1, x2, x3, x4, x5 = AZPTECombatBar:GetPoint()
            AZPTELocation = {x1, x4, x5}
            moveable = false
        end
    end)

    AZP.TimedEncounters:ShareVersion()
    AZP.TimedEncounters:CreateCombatBar()
end

function AZP.TimedEncounters:CreateCombatBar()
    AZPTECombatBar = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    AZPTECombatBar:SetSize(GetScreenWidth() * 0.75, 100)
    AZPTECombatBar:SetPoint("CENTER", 0, 400)
    AZPTECombatBar:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    AZPTECombatBar:SetBackdropColor(0.25, 0.25, 0.25, 0.80)
    AZPTECombatBar:SetScript("OnDragStart", AZPTECombatBar.StartMoving)
    AZPTECombatBar:SetScript("OnDragStop", AZPTECombatBar.StopMovingOrSizing)

    BossHPBar = CreateFrame("StatusBar", nil, AZPTECombatBar)
    BossHPBar:SetSize(AZPTECombatBar:GetWidth(), 35)
    BossHPBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    BossHPBar:SetMinMaxValues(0, 10000)
    BossHPBar:SetValue(10000)
    BossHPBar:SetReverseFill(true)
    BossHPBar:SetPoint("CENTER", 0, 0)
    BossHPBar:SetStatusBarColor(0, 1, 0)
    BossHPBar.bg = BossHPBar:CreateTexture(nil, "BACKGROUND")
    BossHPBar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    BossHPBar.bg:SetAllPoints(true)
    BossHPBar.bg:SetVertexColor(1, 0, 0)

    AZPTECombatBar.checkPoints = {}
    AZPTECombatBar.checkPoints.markers = {}
    AZPTECombatBar.checkPoints.timers = {}
    AZPTECombatBar.checkPoints.HPs = {}
    for i = 1, 10 do
        AZPTECombatBar.checkPoints[i] = CreateFrame("FRAME", nil, BossHPBar, "BackdropTemplate")
        AZPTECombatBar.checkPoints[i]:SetSize(1, 1)
        -- AZPTECombatBar.checkPoints[i]:SetBackdrop({
        --     bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        --     edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        --     edgeSize = 12,
        --     insets = { left = 1, right = 1, top = 1, bottom = 1 },
        -- })
        --AZPTECombatBar.checkPoints[i]:SetBackdropColor(0.5, 0.5, 0.5, 1)

        AZPTECombatBar.checkPoints.markers[i] = CreateFrame("FRAME", nil, AZPTECombatBar.checkPoints[i], "BackdropTemplate")
        AZPTECombatBar.checkPoints.markers[i]:SetSize(5, 50)
        AZPTECombatBar.checkPoints.markers[i]:SetPoint("CENTER", 0, 0)
        AZPTECombatBar.checkPoints.markers[i]:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        })
        AZPTECombatBar.checkPoints.markers[i]:SetBackdropColor(0, 0, 0, 1)
        AZPTECombatBar.checkPoints.timers[i] = AZPTECombatBar.checkPoints[i]:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        AZPTECombatBar.checkPoints.timers[i]:SetSize(50, 25)
        AZPTECombatBar.checkPoints.timers[i]:SetPoint("CENTER", 0, -35)
        AZPTECombatBar.checkPoints.timers[i]:SetText("Time", i)
        AZPTECombatBar.checkPoints.HPs[i] = AZPTECombatBar.checkPoints[i]:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        AZPTECombatBar.checkPoints.HPs[i]:SetSize(50, 25)
        AZPTECombatBar.checkPoints.HPs[i]:SetPoint("CENTER", 0, 35)
        AZPTECombatBar.checkPoints.HPs[i]:SetText("HP+Diff", i)
    end

    --AZPTECombatBar:Hide()
end

function AZP.TimedEncounters:PlaceMarkers()
    for i = 1, 10 do
        if AZPTESavedList[i][1] ~= nil and AZPTESavedList[i][2] ~= nil then
            AZPTECombatBar.checkPoints[i]:SetPoint("RIGHT", -AZPTECombatBar:GetWidth()*AZPTESavedList[i][2]/100, 0)
            AZPTECombatBar.checkPoints.timers[i]:SetText(AZPTESavedList[i][1] .. "s")
            AZPTECombatBar.checkPoints.HPs[i]:SetText(AZPTESavedList[i][2] .. "%")
        else
            AZPTECombatBar.checkPoints.timers[i]:SetText("")
            AZPTECombatBar.checkPoints.HPs[i]:SetText("")
            --AZPTECombatBar.checkPoints.markers[i]:SetSize(0, 0)
            --AZPTECombatBar.checkPoints.markers[i]:SetPoint()
            AZPTECombatBar.checkPoints:ClearAllPoints()
        end
    end
end

function AZP.TimedEncounters:CreateAZPTETimerFrame()
    if AZPTESavedList == nil then
        AZPTESavedList = {}
    end
    for i = 1, 10 do
        if AZPTESavedList[i] == nil then
            AZPTESavedList[i] = {}
            AZPTESavedList[i][1] = 0
            AZPTESavedList[i][2] = 0
        end
        if AZPTESavedList[i][1] ~= nil then
            EcounterTrackingEditBoxes[i].timeEditBox:SetText(AZPTESavedList[i][1])
            EcounterTrackingEditBoxes[i].healthEditBox:SetText(AZPTESavedList[i][2])
            EncounterTrackingData[i][1] = AZPTESavedList[i][1]
        end
    end

    AZPTETimerFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    AZPTETimerFrame:SetSize(400, 300)
    AZPTETimerFrame:SetPoint("CENTER", -750, 0)
    AZPTETimerFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    AZPTETimerFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)
    AZPTETimerFrame.header = AZPTETimerFrame:CreateFontString("AZPTETimerFrame", "ARTWORK", "GameFontNormalHuge")
    AZPTETimerFrame.header:SetPoint("TOP", 0, -10)
    AZPTETimerFrame.header:SetText("|cFF00FFFFAzerPUG's Timed Encounters!|r")
    AZPTETimerFrame.text = AZPTETimerFrame:CreateFontString("AZPTETimerFrame", "ARTWORK", "GameFontNormalLarge")
    AZPTETimerFrame.text:SetPoint("TOP", 0, -30)
    AZPTETimerFrame:SetScript("OnDragStart", AZPTETimerFrame.StartMoving)
    AZPTETimerFrame:SetScript("OnDragStop", AZPTETimerFrame.StopMovingOrSizing)

    local AZPTETimerFrameCloseButton = CreateFrame("Button", nil, AZPTETimerFrame, "UIPanelCloseButton")
    AZPTETimerFrameCloseButton:SetWidth(25)
    AZPTETimerFrameCloseButton:SetHeight(25)
    AZPTETimerFrameCloseButton:SetPoint("TOPRIGHT", AZPTETimerFrame, "TOPRIGHT", 2, 2)
    AZPTETimerFrameCloseButton:SetScript("OnClick", function() AZPTETimerFrame:Hide() end)

    AZPTETimerFrame.Plan = {}
    AZPTETimerFrame.HPActual = {}
    AZPTETimerFrame.CurrentTimer = {}
    AZPTETimerFrame.Difference = {}
    AZPTETimerFrame.Plan.Header = AZPTETimerFrame:CreateFontString("AZPTETimerFrame", "ARTWORK", "GameFontNormalLarge")
    AZPTETimerFrame.Plan.Header:SetSize(100, 20)
    AZPTETimerFrame.Plan.Header:SetPoint("TOP", -85, -40)
    AZPTETimerFrame.Plan.Header:SetJustifyH("RIGHT")
    AZPTETimerFrame.Plan.Header:SetText("Plan")
    AZPTETimerFrame.HPActual.Header = AZPTETimerFrame:CreateFontString("AZPTETimerFrame", "ARTWORK", "GameFontNormalLarge")
    AZPTETimerFrame.HPActual.Header:SetSize(100, 20)
    AZPTETimerFrame.HPActual.Header:SetPoint("TOP", 0, -40)
    AZPTETimerFrame.HPActual.Header:SetText("HP%")
    AZPTETimerFrame.CurrentTimer.Header = AZPTETimerFrame:CreateFontString("AZPTETimerFrame", "ARTWORK", "GameFontNormalLarge")
    AZPTETimerFrame.CurrentTimer.Header:SetSize(100, 20)
    AZPTETimerFrame.CurrentTimer.Header:SetPoint("TOP", 50, -40)
    AZPTETimerFrame.CurrentTimer.Header:SetText("Timer")
    AZPTETimerFrame.Difference.Header = AZPTETimerFrame:CreateFontString("AZPTETimerFrame", "ARTWORK", "GameFontNormalLarge")
    AZPTETimerFrame.Difference.Header:SetSize(100, 20)
    AZPTETimerFrame.Difference.Header:SetPoint("TOP", 150, -40)
    AZPTETimerFrame.Difference.Header:SetText("Difference")
    for i = 1, #EncounterTrackingData do
        AZPTETimerFrame.Plan[i] = AZPTETimerFrame:CreateFontString("AZPTETimerFrame", "ARTWORK", "GameFontNormalLarge")
        AZPTETimerFrame.Plan[i]:SetSize(100, 20)
        AZPTETimerFrame.Plan[i]:SetPoint("TOP", -85, -20 * i - 40)
        AZPTETimerFrame.Plan[i]:SetJustifyH("RIGHT")
        if AZPTESavedList[i][1] ~= nil and AZPTESavedList[i][2] ~= nil then
            AZPTETimerFrame.Plan[i]:SetText(AZPTESavedList[i][2] .. "% at " .. AZPTESavedList[i][1] .. "s")
        end
        AZPTETimerFrame.HPActual[i] = AZPTETimerFrame:CreateFontString("AZPTETimerFrame", "ARTWORK", "GameFontNormalLarge")
        AZPTETimerFrame.HPActual[i]:SetSize(50, 20)
        AZPTETimerFrame.HPActual[i]:SetPoint("TOP", 0, -20 * i - 40)
        AZPTETimerFrame.CurrentTimer[i] = AZPTETimerFrame:CreateFontString("AZPTETimerFrame", "ARTWORK", "GameFontNormalLarge")
        AZPTETimerFrame.CurrentTimer[i]:SetSize(50, 20)
        AZPTETimerFrame.CurrentTimer[i]:SetPoint("TOP", 50, -20 * i - 40)
        AZPTETimerFrame.Difference[i] = AZPTETimerFrame:CreateFontString("AZPTETimerFrame", "ARTWORK", "GameFontNormalLarge")
        AZPTETimerFrame.Difference[i]:SetSize(50, 20)
        AZPTETimerFrame.Difference[i]:SetPoint("TOP", 150, -20 * i - 40)
    end

    --AZPTETimerFrame:Hide()

    tempFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    tempFrame:SetSize(100, 50)
    tempFrame:SetPoint("CENTER", -750, -200)
    tempFrame:EnableMouse(true)
    tempFrame:SetMovable(true)
    tempFrame:RegisterForDrag("LeftButton")
    tempFrame:SetScript("OnDragStart", tempFrame.StartMoving)
    tempFrame:SetScript("OnDragStop", tempFrame.StopMovingOrSizing)
    tempFrame:SetScript("OnEvent", AZP.TimedEncounters.OnEvent)
    tempFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    tempFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)

    local tempButton = CreateFrame("Button", nil, tempFrame, "UIPanelButtonTemplate")
    tempButton:SetPoint("CENTER", 0, 0)
    tempButton:SetSize(75, 25)
    tempButton:SetScript("OnClick", function()
        if AZPTETimerFrame:IsShown() then
            AZPTETimerFrame:Hide()
            tempButton.text:SetText("ShowFrame")
        else
            AZPTETimerFrame:Show()
            tempButton.text:SetText("HideFrame")
        end
    end)
    tempButton.text = tempButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tempButton.text:SetText("ShowFrame")
    tempButton.text:SetSize(75, 25)
    tempButton.text:SetPoint("CENTER", 0, 0)
end

function AZP.TimedEncounters:PullNumbersFromEditBox(index)
    AZPTESavedList[index][1] = tonumber(EcounterTrackingEditBoxes[index].timeEditBox:GetText(), 10)
    AZPTESavedList[index][2] = tonumber(EcounterTrackingEditBoxes[index].healthEditBox:GetText(), 10)
    EncounterTrackingData[index][1] = AZPTESavedList[index][1]
    if AZPTESavedList[index][1] ~= nil and AZPTESavedList[index][2] ~= nil then
        AZPTETimerFrame.Plan[index]:SetText(AZPTESavedList[index][2] .. "% at " .. AZPTESavedList[index][1] .. "s")
    end

    AZP.TimedEncounters:PlaceMarkers()
end

function DelayedExecution(delayTime, delayedFunction)
    local frame = CreateFrame("Frame")
    frame.start_time = GetServerTime()
    frame:SetScript("OnUpdate",
        function(self)
            if GetServerTime() - self.start_time > delayTime then
                delayedFunction()
                self:SetScript("OnUpdate", nil)
                self:Hide()
            end
        end
    )
    frame:Show()
end

function AZP.TimedEncounters:TrackHealth(i)
    local bossMaxHealth = UnitHealthMax("boss1")
    local bossCurrentHealth = UnitHealth("boss1")
    local bossPercentHealth = math.floor(bossCurrentHealth/bossMaxHealth*10000)/100
    EncounterTrackingData[i][2] = bossPercentHealth
    AZPTETimerFrame.HPActual[i]:SetText(bossPercentHealth)
    local percentageDifference =  AZPTESavedList[i][2] - bossPercentHealth
    if percentageDifference > 0 then percentageDifference = "+" .. percentageDifference end
    AZPTETimerFrame.Difference[i]:SetText(percentageDifference)

    AZPTECombatBar.checkPoints.HPs[i]:SetText(AZPTESavedList[i][2] .. "%\n" .. percentageDifference .. "")

    BossHPBar:SetValue(bossCurrentHealth/bossMaxHealth*10000)
end

function AZP.TimedEncounters:DisplayResults()
    local setText = "Tracked Data:\n"
    AZPTETimerFrame.text:SetText(setText)
    for i = 1, #EncounterTrackingData do
        if EncounterTrackingData[i][1] == nil or EncounterTrackingData[i][2] == nil then
            break
        else
            setText = setText .. EncounterTrackingData[i][2] .. "% at " .. AZPTESavedList[i][1] .. "s.\n"
        end
    end
    AZPTETimerFrame.text:SetText(setText)
end

function AZP.TimedEncounters:ResetResults()
    for i = 1, #EncounterTrackingData do
        EncounterTrackingData[i][1] = AZPTESavedList[i][1]
        EncounterTrackingData[i][2] = nil

        AZPTETimerFrame.HPActual[i]:SetText("")
        AZPTETimerFrame.CurrentTimer[i]:SetText("")
        AZPTETimerFrame.Difference[i]:SetText("")
    end
end

function AZP.TimedEncounters:Ticker()
    for i = 1, #EncounterTrackingData do
        if EncounterTrackingData[i][1] < 0 then
            AZPTETimerFrame.CurrentTimer[i]:SetText("-")
        elseif EncounterTrackingData[i][1] == 0 then
            AZP.TimedEncounters:TrackHealth(i)
            AZPTETimerFrame.CurrentTimer[i]:SetText(EncounterTrackingData[i][1])
            AZPTECombatBar.checkPoints.timers[i]:SetText(EncounterTrackingData[i][1])
            EncounterTrackingData[i][1] = EncounterTrackingData[i][1] - 1
        else
            AZPTETimerFrame.CurrentTimer[i]:SetText(EncounterTrackingData[i][1])
            AZPTECombatBar.checkPoints.timers[i]:SetText(EncounterTrackingData[i][1])
            EncounterTrackingData[i][1] = EncounterTrackingData[i][1] - 1
        end
    end
    --AZP.TimedEncounters:DisplayResults()
end

function AZP.TimedEncounters:ShareVersion()
    local versionString = string.format("|TT:%d|", AZP.VersionControl.TimedEncounters)
    DelayedExecution(10, function()
        if IsInGroup() then
            if IsInRaid() then
                C_ChatInfo.SendAddonMessage("AZPVERSIONS", versionString ,"RAID", 1)
            else
                C_ChatInfo.SendAddonMessage("AZPVERSIONS", versionString ,"PARTY", 1)
            end
        end
        if IsInGuild() then
            C_ChatInfo.SendAddonMessage("AZPVERSIONS", versionString ,"GUILD", 1)
        end
    end)
end

function AZP.TimedEncounters:ReceiveVersion(version)
    if version > TEVersion then
        if (not HaveShowedUpdateNotification) then
            HaveShowedUpdateNotification = true
            TEUpdateFrame:Show()
            TEUpdateFrame.text:SetText(
                "Please download the new version through the CurseForge app.\n" ..
                "Or use the CurseForge website to download it manually!\n\n" ..
                "Newer Version: v" .. version .. "\n" ..
                "Your version: v" .. TEVersion)
        end
    end
end

function AZP.TimedEncounters:OnEvent(event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, payload, _, sender = ...
        if prefix == "AZPTT_VERSION" then
            AZP.TimedEncounters:ReceiveVersion(tonumber(payload))
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        AZP.TimedEncounters:ShareVersion()
    elseif event == "ENCOUNTER_START" then
        AZP.TimedEncounters:ResetResults()
        AZPTECombatBar:Show()
        EncounterTimer = C_Timer.NewTicker(1, function() AZP.TimedEncounters:Ticker() end, 1000)
    elseif event == "ENCOUNTER_END" then
        EncounterTimer:Cancel()
        --AZPTECombatBar:Hide()
        AZPTETimerFrame:Show()
    elseif event == "VARIABLES_LOADED" then
        AZP.TimedEncounters:CreateAZPTETimerFrame()
        AZP.TimedEncounters:PlaceMarkers()
    end
end

AZP.TimedEncounters:OnLoad()