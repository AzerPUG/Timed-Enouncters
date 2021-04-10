if AZP == nil then AZP = {} end
if AZP.VersionControl == nil then AZP.VersionControl = {} end
if AZP.OnLoad == nil then AZP.OnLoad = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end

AZP.VersionControl.TimedEncounters = 1
AZP.TimedEncounters = {}

local TEMainFrame, TEUpdateFrame = nil, nil
local TEOptionsPanel
local HaveShowedUpdateNotification = false
local EncounterTrackingData = {}
local EcounterTrackingEditBoxes = {}

local tempFrame

function AZP.TimedEncounters:OnLoad()
    TEMainFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    TEMainFrame:SetSize(400, 300)
    TEMainFrame:SetPoint("CENTER", -750, 0)
    TEMainFrame:RegisterEvent("CHAT_MSG_ADDON")
    TEMainFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    TEMainFrame:RegisterEvent("ENCOUNTER_START")
    TEMainFrame:RegisterEvent("ENCOUNTER_END")
    TEMainFrame:SetScript("OnEvent", AZP.TimedEncounters.OnEvent)
    TEMainFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    TEMainFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)
    TEMainFrame.header = TEMainFrame:CreateFontString("TEMainFrame", "ARTWORK", "GameFontNormalHuge")
    TEMainFrame.header:SetPoint("TOP", 0, -10)
    TEMainFrame.header:SetText("|cFFFFFFFFTimedEncounters!|r")
    TEMainFrame.text = TEMainFrame:CreateFontString("TEMainFrame", "ARTWORK", "GameFontNormalLarge")
    TEMainFrame.text:SetPoint("TOP", 0, -30)
    TEMainFrame.text:SetText("|cFFFF0000No Info Yet!|r")

    local TEMainFrameCloseButton = CreateFrame("Button", nil, TEMainFrame, "UIPanelCloseButton")
    TEMainFrameCloseButton:SetWidth(25)
    TEMainFrameCloseButton:SetHeight(25)
    TEMainFrameCloseButton:SetPoint("TOPRIGHT", TEMainFrame, "TOPRIGHT", 2, 2)
    TEMainFrameCloseButton:SetScript("OnClick", function() TEMainFrame:Hide() end)

    tempFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    tempFrame:SetSize(100, 50)
    tempFrame:SetPoint("CENTER", -250, 0)
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
        if TEMainFrame:IsShown() then
            TEMainFrame:Hide()
            tempButton.text:SetText("ShowFrame")
        else
            TEMainFrame:Show()
            tempButton.text:SetText("HideFrame")
        end
    end)
    tempButton.text = tempButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tempButton.text:SetText("XxX")
    tempButton.text:SetSize(75, 25)
    tempButton.text:SetPoint("CENTER", 0, 0)

    C_ChatInfo.RegisterAddonMessagePrefix("AZPTT_VERSION")

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

    for i = 1, 10 do
        EncounterTrackingData[i] = {}
        local counterFrame = CreateFrame("Frame", nil, TEOptionsPanel)
        counterFrame:SetSize(200, 25)
        counterFrame:SetPoint("LEFT", 75, -30*i + 250)
        counterFrame.editbox = CreateFrame("EditBox", nil, counterFrame, "InputBoxTemplate")
        counterFrame.editbox:SetSize(100, 25)
        counterFrame.editbox:SetPoint("LEFT", 50, 0)
        counterFrame.editbox:SetAutoFocus(false)
        counterFrame.editbox:SetNumeric(true)
        counterFrame.text = counterFrame:CreateFontString("counterFrame", "ARTWORK", "GameFontNormalLarge")
        counterFrame.text:SetSize(100, 25)
        counterFrame.text:SetPoint("LEFT", -50, 0)
        counterFrame.text:SetText("Checkpoint " .. i .. ":")

        --counterFrame.editbox:SetScript("OnEditFocusLost", function() EncounterTrackingData[i][1] = tonumber(EcounterTrackingEditBoxes[i].editbox:GetText()) end)

        EcounterTrackingEditBoxes[i] = counterFrame
        counterFrame.editbox:SetScript("OnEditFocusLost", function() AZP.TimedEncounters:PullNumbersFromEditBox(i) end)
    end

    AZP.TimedEncounters:ShareVersion()
end

function AZP.TimedEncounters:PullNumbersFromEditBox(index)
    EncounterTrackingData[index][1] = tonumber(EcounterTrackingEditBoxes[index].editbox:GetText(), 10)
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

function AZP.TimedEncounters:TrackTime()
    for i = 1, #EncounterTrackingData do
        if EncounterTrackingData[i][1] == nil then
            break
        else
            print(EncounterTrackingData[i][1])
            C_Timer.After(EncounterTrackingData[i][1], function() AZP.TimedEncounters:TrackHealth(i) end)
        end
    end
end

function AZP.TimedEncounters:TrackHealth(i)
    local bossMaxHealth = UnitHealthMax("boss1")
    local bossCurrentHealth = UnitHealth("boss1")
    local bossPercentHealth = math.floor(bossCurrentHealth/bossMaxHealth*10000)/100
    EncounterTrackingData[i][2] = bossPercentHealth
    AZP.TimedEncounters:DisplayResults()
end

function AZP.TimedEncounters:DisplayResults()
    local setText = "Tracked Data:\n"
    TEMainFrame.text:SetText(setText)
    for i = 1, #EncounterTrackingData do
        if EncounterTrackingData[i][1] == nil or EncounterTrackingData[i][2] == nil then
            break
        else
            setText = setText .. "Boss at " .. EncounterTrackingData[i][2] .. "% at " .. EncounterTrackingData[i][1] .. "seconds.\n"
        end
    end
    TEMainFrame.text:SetText(setText)
end

function AZP.TimedEncounters:ShareVersion()
    DelayedExecution(10, function()
        if IsInRaid() then
            C_ChatInfo.SendAddonMessage("AZPTT_VERSION", TEVersion ,"RAID", 1)
        end
        if IsInGroup() then
            C_ChatInfo.SendAddonMessage("AZPTT_VERSION", TEVersion ,"PARTY", 1)
        end
        if IsInGuild() then
            C_ChatInfo.SendAddonMessage("AZPTT_VERSION", TEVersion ,"GUILD", 1)
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
            --AZP.TimedEncounters:ReceiveVersion(tonumber(payload))
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        AZP.TimedEncounters:ShareVersion()
    elseif event == "ENCOUNTER_START" then
        AZP.TimedEncounters:TrackTime()
    elseif event == "ENCOUNTER_END" then
        AZP.TimedEncounters:DisplayResults()
        TEMainFrame:Show()
    end
end

AZP.TimedEncounters:OnLoad()