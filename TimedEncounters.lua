if AZP == nil then AZP = {} end
if AZP.TimedEncounters == nil then AZP.TimedEncounters = {} end
if AZP.VersionControl == nil then AZP.VersionControl = {} end
if AZP.OnLoad == nil then AZP.OnLoad = {} end
if AZP.OnEvent == nil then AZP.OnEvent = {} end

AZP.VersionControl["Timed Encounters"] = 16
if AZP.TimedEncounters == nil then AZP.TimedEncounters = {} end
if AZP.TimedEncounters.Events == nil then AZP.TimedEncounters.Events = {} end

local AZPTETimerFrame, AZPTECombatBar, UpdateFrame, EventFrame = nil, nil, nil, nil
local BossHPBar = nil
local AZPTimedEncountersOptionsPanel
local HaveShowedUpdateNotification = false
local EncounterTrackingData = {}
local EcounterTrackingEditBoxes = {}
local endOfCombatPost = {}

local moveable = false
local EncounterTimer = nil
local EncounterTimeIndex = nil

local VarsAndAddOnLoaded = {false, false}

local tempFrame

function AZP.TimedEncounters:OnLoadBoth()
end

function AZP.TimedEncounters:OnLoadCore()
    AZP.Core:RegisterEvents("VARIABLES_LOADED", function(...) AZP.TimedEncounters.Events:VariablesLoaded(...) end)
    AZP.Core:RegisterEvents("ENCOUNTER_START", function(...) AZP.TimedEncounters.Events:EncounterStart() end)
    AZP.Core:RegisterEvents("ENCOUNTER_END", function(...) AZP.TimedEncounters.Events:EncounterEnd() end)

    AZP.OptionsPanels:RemovePanel("Timed Encounters")
    AZP.OptionsPanels:Generic("Timed Encounters", optionHeader, function(frame)
        AZPTimedEncountersOptionsPanel = frame
        AZP.TimedEncounters:FillOptionsPanel(frame)
    end)

    DevTools_Dump(AZP.Core.AddOns.TE.MainFrame)

    AZP.TimedEncounters:CreateAZPTETimerFrame(AZP.Core.AddOns.TE.MainFrame)

    AZP.TimedEncounters:OnLoadBoth()
end

function AZP.TimedEncounters:OnLoadSelf()
    EventFrame = CreateFrame("FRAME", nil)
    EventFrame:RegisterEvent("ENCOUNTER_START")
    EventFrame:RegisterEvent("ENCOUNTER_END")
    EventFrame:RegisterEvent("VARIABLES_LOADED")
    EventFrame:RegisterEvent("CHAT_MSG_ADDON")
    EventFrame:SetScript("OnEvent", AZP.TimedEncounters.OnEvent)

    UpdateFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    UpdateFrame:SetPoint("CENTER", 0, 250)
    UpdateFrame:SetSize(400, 200)
    UpdateFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    UpdateFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)
    UpdateFrame.header = UpdateFrame:CreateFontString("UpdateFrame", "ARTWORK", "GameFontNormalHuge")
    UpdateFrame.header:SetPoint("TOP", 0, -10)
    UpdateFrame.header:SetText("|cFFFF0000AzerPUG's Timed Encounters is out of date!|r")

    UpdateFrame.text = UpdateFrame:CreateFontString("UpdateFrame", "ARTWORK", "GameFontNormalLarge")
    UpdateFrame.text:SetPoint("TOP", 0, -40)
    UpdateFrame.text:SetText("Error!")

    local UpdateFrameCloseButton = CreateFrame("Button", nil, UpdateFrame, "UIPanelCloseButton")
    UpdateFrameCloseButton:SetWidth(25)
    UpdateFrameCloseButton:SetHeight(25)
    UpdateFrameCloseButton:SetPoint("TOPRIGHT", UpdateFrame, "TOPRIGHT", 2, 2)
    UpdateFrameCloseButton:SetScript("OnClick", function() UpdateFrame:Hide() end )

    UpdateFrame:Hide()

    AZPTimedEncountersOptionsPanel = CreateFrame("FRAME", nil)
    AZPTimedEncountersOptionsPanel.name = "|c0000FFFFAzerPUG's Timed Encounters|r"
    InterfaceOptions_AddCategory(AZPTimedEncountersOptionsPanel)

    AZPTimedEncountersOptionsPanel.Header = AZPTimedEncountersOptionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    AZPTimedEncountersOptionsPanel.Header:SetText("|c0000FFFFAzerPUG's Timed Encounters Options|r")
    AZPTimedEncountersOptionsPanel.Header:SetWidth(AZPTimedEncountersOptionsPanel:GetWidth())
    AZPTimedEncountersOptionsPanel.Header:SetHeight(25)
    AZPTimedEncountersOptionsPanel.Header:SetPoint("TOP", 0, -10)

    AZPTimedEncountersOptionsPanel.Footer = AZPTimedEncountersOptionsPanel:CreateFontString("AZPTimedEncountersOptionsPanel", "ARTWORK", "GameFontNormalLarge")
    AZPTimedEncountersOptionsPanel.Footer:SetPoint("TOP", 0, -400)
    AZPTimedEncountersOptionsPanel.Footer:SetText(
        "|cFF00FFFFAzerPUG Links:\n" ..
        "Website: www.azerpug.com\n" ..
        "Discord: www.azerpug.com/discord\n" ..
        "Twitch: www.twitch.tv/azerpug\n|r"
    )

    AZPTimedEncountersOptionsPanel:Hide()

    AZP.TimedEncounters:FillOptionsPanel(AZPTimedEncountersOptionsPanel)

    AZPTETimerFrame = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    AZPTETimerFrame:SetSize(350, 275)
    if TEFrameLocation ~= nil then
        AZPTETimerFrame:SetPoint(TEFrameLocation[1], TEFrameLocation[2], TEFrameLocation[3])
    else
        AZPTETimerFrame:SetPoint("CENTER", -750, 0)
    end
    AZPTETimerFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    AZPTETimerFrame:SetBackdropColor(0.25, 0.25, 0.25, 0.80)
    AZP.TimedEncounters:CreateAZPTETimerFrame(AZPTETimerFrame)
    AZP.TimedEncounters:OnLoadBoth()
end

function AZP.TimedEncounters:FillOptionsPanel(frameToFill)
    local headerFrame = CreateFrame("Frame", nil, frameToFill)
    headerFrame:SetSize(200, 50)
    headerFrame:SetPoint("LEFT", 75, 200)
    headerFrame.time = headerFrame:CreateFontString("headerFrame", "ARTWORK", "GameFontNormalLarge")
    headerFrame.time:SetSize(100, 50)
    headerFrame.time:SetPoint("LEFT", 50, 0)
    headerFrame.time:SetText("Time\nin Sec:")
    headerFrame.health = headerFrame:CreateFontString("headerFrame", "ARTWORK", "GameFontNormalLarge")
    headerFrame.health:SetSize(100, 50)
    headerFrame.health:SetPoint("LEFT", 175, 0)
    headerFrame.health:SetText("Health\nin %:")
    for i = 1, 10 do
        EncounterTrackingData[i] = {}
        local counterFrame = CreateFrame("Frame", nil, frameToFill)
        counterFrame:SetSize(200, 25)
        counterFrame:SetPoint("LEFT", 75, -30*i + 200)
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

    local AZPTEToggleMoveButton = CreateFrame("Button", nil, frameToFill, "UIPanelButtonTemplate")
    AZPTEToggleMoveButton:SetText("Toggle Movement!")
    AZPTEToggleMoveButton:SetSize(100, 25)
    AZPTEToggleMoveButton:SetPoint("TOPLEFT", 375, -100)
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
            local x1, _, _, x4, x5 = AZPTETimerFrame:GetPoint()
            TEFrameLocation = {x1, x4, x5}
            local y1, _, _, y4, y5 = AZPTECombatBar:GetPoint()
            TECombatFrameLocation = {y1, y4, y5}
            moveable = false
        end
    end)

    local AZPTEScaleSlider = CreateFrame("SLIDER", "AZPTEScaleSlider", frameToFill, "OptionsSliderTemplate")
    AZPTEScaleSlider:SetHeight(20)
    AZPTEScaleSlider:SetWidth(100)
    AZPTEScaleSlider:SetOrientation('HORIZONTAL')
    AZPTEScaleSlider:SetPoint("TOP", 150, -300)
    AZPTEScaleSlider:EnableMouse(true)
    AZPTEScaleSlider.tooltipText = 'Scale BossBar'
    AZPTEScaleSliderLow:SetText('small')
    AZPTEScaleSliderHigh:SetText('big')
    AZPTEScaleSliderText:SetText('BossBar Scale')

    AZPTEScaleSlider:Show()
    AZPTEScaleSlider:SetMinMaxValues(0.5, 2)
    AZPTEScaleSlider:SetValueStep(0.1)

    AZPTEScaleSlider:SetScript("OnValueChanged", AZP.TimedEncounters.setScale)

    frameToFill.BarStyleDropDown = CreateFrame("Button", nil, frameToFill, "UIDropDownMenuTemplate")
    frameToFill.BarStyleDropDown:SetPoint("TOPLEFT", 350, -150)
    frameToFill.FontStyleDropDown = CreateFrame("Button", nil, frameToFill, "UIDropDownMenuTemplate")
    frameToFill.FontStyleDropDown:SetPoint("TOPLEFT", 350, -200)

    UIDropDownMenu_SetWidth(frameToFill.BarStyleDropDown, 150)
    UIDropDownMenu_SetWidth(frameToFill.FontStyleDropDown, 150)

    local BarStyles = AZP.TimedEncounters.dataTables.BarStyles
    local FontStyles = AZP.TimedEncounters.dataTables.FontStyles
    local StyleVars = AZP.TimedEncounters.StyleVars
    UIDropDownMenu_Initialize(frameToFill.BarStyleDropDown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = AZP.TimedEncounters.SetValue
        for i = 1, #BarStyles do
            info.text = string.match(string.match(BarStyles[i], "\\(.*)"), "\\(.*)")
            info.arg1 = "bar"
            info.arg2 = BarStyles[i]
            UIDropDownMenu_AddButton(info, 1)
        end
    end)
    UIDropDownMenu_Initialize(frameToFill.FontStyleDropDown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = AZP.TimedEncounters.SetValue
        for i = 1, #FontStyles do
            info.text = string.match(FontStyles[i], "\\(.*)")
            info.arg1 = "font"
            info.arg2 = FontStyles[i]
            UIDropDownMenu_AddButton(info, 1)
        end
    end)
end

function AZP.TimedEncounters:SetValue(var, newValue)
    local StyleVars = AZP.TimedEncounters.StyleVars
    local StylePath = newValue
    local barStyleName, fontStyleName = nil, nil
    if var == "font" then
        StyleVars.font = newValue
        AZPTEConfig.font = newValue
        fontStyleName = string.match(StylePath, "\\(.*)")
        UIDropDownMenu_SetText(AZPTimedEncountersOptionsPanel.FontStyleDropDown, fontStyleName)
        AZP.TimedEncounters:ChangeTimerFrameFonts(AZPTETimerFrame)
    elseif var == "size" then
        StyleVars.size = newValue
    elseif var == "outline" then
        StyleVars.outline = newValue
    elseif var == "monochrome" then
        StyleVars.monochrome = newValue
    elseif var == "bar" then
        StyleVars.bar = newValue
        AZPTEConfig.bar = newValue
        barStyleName = string.match(StylePath, ".*\\(.*)")
        UIDropDownMenu_SetText(AZPTimedEncountersOptionsPanel.BarStyleDropDown, barStyleName)
    end
    BossHPBar:SetStatusBarTexture(StyleVars.bar)
    BossHPBar.bg:SetTexture(StyleVars.bar)
    CloseDropDownMenus()
end

function AZP.TimedEncounters:ChangeTimerFrameFonts(InputFrame)
    local StyleVars = AZP.TimedEncounters.StyleVars
    local OutlineAndMonochrome = nil
    if StyleVars.outline ~= nil and StyleVars.monochrome ~= nil then OutlineAndMonochrome = StyleVars.outline .. ", " .. StyleVars.monochrome
    elseif StyleVars.outline ~= nil and StyleVars.monochrome == nil then OutlineAndMonochrome = StyleVars.outline
    elseif StyleVars.outline == nil and StyleVars.monochrome ~= nil then OutlineAndMonochrome = StyleVars.monochrome
    end
    StyleVars.size = 12
    InputFrame.header:SetFont(StyleVars.font, 20, OutlineAndMonochrome)
    InputFrame.text:SetFont(StyleVars.font, StyleVars.size, OutlineAndMonochrome)
    InputFrame.Plan.Header:SetFont(StyleVars.font, StyleVars.size, OutlineAndMonochrome)
    InputFrame.HPActual.Header:SetFont(StyleVars.font, StyleVars.size, OutlineAndMonochrome)
    InputFrame.CurrentTimer.Header:SetFont(StyleVars.font, StyleVars.size, OutlineAndMonochrome)
    InputFrame.Difference.Header:SetFont(StyleVars.font, StyleVars.size, OutlineAndMonochrome)
    for i = 1, #EncounterTrackingData do
        InputFrame.Plan[i]:SetFont(StyleVars.font, StyleVars.size, OutlineAndMonochrome)
        InputFrame.HPActual[i]:SetFont(StyleVars.font, StyleVars.size, OutlineAndMonochrome)
        InputFrame.CurrentTimer[i]:SetFont(StyleVars.font, StyleVars.size, OutlineAndMonochrome)
        InputFrame.Difference[i]:SetFont(StyleVars.font, StyleVars.size, OutlineAndMonochrome)
    end
end

function AZP.TimedEncounters.Events:VariablesLoaded()
    VarsAndAddOnLoaded[1] = true
    AZP.TimedEncounters:VarsAndAddOnLoaded()
end

function AZP.TimedEncounters:VarsAndAddOnLoaded()
    if VarsAndAddOnLoaded[1] == true and VarsAndAddOnLoaded[2] == true then
        if AZPTEConfig == nil then
            AZPTEConfig = {
                ["font"] = "Fonts\\FRIZQT__.TTF",
                ["bar"] = "Interface\\TargetingFrame\\UI-StatusBar",
                ["barScale"] = 1,
            }
        end

        AZP.TimedEncounters:CreateCombatBar()
        AZP.TimedEncounters:PlaceMarkers()
        BossHPBar:SetScale(AZPTEConfig.barScale)
        AZPTEScaleSlider:SetValue(AZPTEConfig.barScale)
        AZP.TimedEncounters:LoadStyle(AZPTETimerFrame)
    end
end

function AZP.TimedEncounters:setScale(scale)
    AZPTEConfig.barScale = scale
    BossHPBar:SetScale(scale)
end

function AZP.TimedEncounters:LoadStyle()
    UIDropDownMenu_SetText(AZPTimedEncountersOptionsPanel.FontStyleDropDown, string.match(AZPTEConfig.font, "\\(.*)"))
    UIDropDownMenu_SetText(AZPTimedEncountersOptionsPanel.BarStyleDropDown, string.match(AZPTEConfig.bar, ".*\\(.*)"))

    AZP.TimedEncounters.StyleVars.bar = AZPTEConfig.bar
    AZP.TimedEncounters.StyleVars.font = AZPTEConfig.font

    BossHPBar:SetStatusBarTexture(AZPTEConfig.bar)
    BossHPBar.bg:SetTexture(AZPTEConfig.bar)

    AZP.TimedEncounters:ChangeTimerFrameFonts(AZPTETimerFrame)
end

function AZP.TimedEncounters.Events:EncounterEnd()
    EncounterTimer:Cancel()
    AZPTECombatBar:Hide()
    AZP.TimedEncounters:SendToRaidChat()
    AZPTETimerFrame:Show()
end

function AZP.TimedEncounters:SendToRaidChat() -- AZPTESavedList
    --SendChatMessage("AzerPUG's Timed Encounters Post-Combat Data:", "RAID")
    --SendChatMessage("AzerPUG's Timed Encounters Post-Combat Data:", "WHISPER", nil, "Tex-Ravencrest")
    if EncounterTrackingData[1][1] ~= nil and EncounterTrackingData[1][1] ~= "0" then
        print("AzerPUG's Timed Encounters Post-Combat Data:")
    end
    for i = 1, 10 do
        if EncounterTrackingData[i][1] ~= nil and EncounterTrackingData[i][1] ~= "0" and EncounterTrackingData[i][2] ~= nil and EncounterTrackingData[i][2] ~= "0" then
            local raidMessage = "Boss was at " .. EncounterTrackingData[i][2] .. "% at " .. AZPTESavedList[i][1] .. " seconds into the fight!"
            print(raidMessage)
                -- <3 <3 <3     Make it actually say something, test in whisper?
        end
    end
end

function AZP.TimedEncounters.Events:EncounterStart()
    AZP.TimedEncounters:ResetResults()
    AZPTECombatBar:Show()
    EncounterTimeIndex = 0
    EncounterTimer = C_Timer.NewTicker(1, function() AZP.TimedEncounters:Ticker() end, 1000)
end

function AZP.TimedEncounters:CreateCombatBar()
    AZPTECombatBar = CreateFrame("FRAME", nil, UIParent, "BackdropTemplate")
    AZPTECombatBar:SetSize(GetScreenWidth() * 0.75, 100)
    if TECombatFrameLocation ~= nil then
        AZPTECombatBar:SetPoint(TECombatFrameLocation[1], TECombatFrameLocation[2], TECombatFrameLocation[3])
    else
        AZPTECombatBar:SetPoint("CENTER", 0, 400)
    end
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
    BossHPBar:SetScale(AZPTEConfig.barScale)
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

    AZPTECombatBar:Hide()
end

function AZP.TimedEncounters:PlaceMarkers()
    for i = 1, 10 do
        if AZPTESavedList[i][1] ~= nil and AZPTESavedList[i][2] ~= nil then
            AZPTECombatBar.checkPoints[i]:SetPoint("RIGHT", -AZPTECombatBar:GetWidth()*AZPTESavedList[i][2]/100, 0)
            AZPTECombatBar.checkPoints.timers[i]:SetText(AZPTESavedList[i][1] .. "s")
            AZPTECombatBar.checkPoints.HPs[i]:SetText(AZPTESavedList[i][2] .. "%")
        else
            AZPTECombatBar.checkPoints[i]:ClearAllPoints()
            AZPTECombatBar.checkPoints[i]:SetPoint("RIGHT", 0, 1000)
        end
    end
end

function AZP.TimedEncounters:CreateAZPTETimerFrame(InputFrame)
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

    InputFrame.header = InputFrame:CreateFontString("InputFrame", "ARTWORK", "GameFontNormalHuge")
    InputFrame.header:SetPoint("TOP", 0, -10)
    InputFrame.header:SetText("|cFF00FFFFAzerPUG's Timed Encounters|r")
    InputFrame.text = InputFrame:CreateFontString("InputFrame", "ARTWORK", "GameFontNormalLarge")
    InputFrame.text:SetPoint("TOP", 0, -30)
    InputFrame:SetScript("OnDragStart", InputFrame.StartMoving)
    InputFrame:SetScript("OnDragStop", InputFrame.StopMovingOrSizing)

    InputFrame.CloseButton = CreateFrame("Button", nil, InputFrame, "UIPanelCloseButton")
    InputFrame.CloseButton:SetWidth(25)
    InputFrame.CloseButton:SetHeight(25)
    InputFrame.CloseButton:SetPoint("TOPRIGHT", InputFrame, "TOPRIGHT", 2, 2)
    InputFrame.CloseButton:SetScript("OnClick", function() InputFrame:Hide() end)

    InputFrame.Plan = {}
    InputFrame.HPActual = {}
    InputFrame.CurrentTimer = {}
    InputFrame.Difference = {}
    InputFrame.Plan.Header = InputFrame:CreateFontString("InputFrame", "ARTWORK", "GameFontNormalLarge")
    InputFrame.Plan.Header:SetSize(100, 20)
    InputFrame.Plan.Header:SetPoint("TOP", -125, -40)
    InputFrame.Plan.Header:SetJustifyH("RIGHT")
    InputFrame.Plan.Header:SetText("Plan")
    InputFrame.HPActual.Header = InputFrame:CreateFontString("InputFrame", "ARTWORK", "GameFontNormalLarge")
    InputFrame.HPActual.Header:SetSize(100, 20)
    InputFrame.HPActual.Header:SetPoint("TOP", -25, -40)
    InputFrame.HPActual.Header:SetText("HP%")
    InputFrame.CurrentTimer.Header = InputFrame:CreateFontString("InputFrame", "ARTWORK", "GameFontNormalLarge")
    InputFrame.CurrentTimer.Header:SetSize(100, 20)
    InputFrame.CurrentTimer.Header:SetPoint("TOP", 50, -40)
    InputFrame.CurrentTimer.Header:SetText("Timer")
    InputFrame.Difference.Header = InputFrame:CreateFontString("InputFrame", "ARTWORK", "GameFontNormalLarge")
    InputFrame.Difference.Header:SetSize(100, 20)
    InputFrame.Difference.Header:SetPoint("TOP", 125, -40)
    InputFrame.Difference.Header:SetText("Difference")
    for i = 1, #EncounterTrackingData do
        InputFrame.Plan[i] = InputFrame:CreateFontString("InputFrame", "ARTWORK", "GameFontNormalLarge")
        InputFrame.Plan[i]:SetSize(100, 20)
        InputFrame.Plan[i]:SetPoint("TOP", -125, -20 * i - 40)
        InputFrame.Plan[i]:SetJustifyH("RIGHT")
        if AZPTESavedList[i][1] ~= nil and AZPTESavedList[i][2] ~= nil then
            InputFrame.Plan[i]:SetText(AZPTESavedList[i][2] .. "% at " .. AZPTESavedList[i][1] .. "s")
        end
        InputFrame.HPActual[i] = InputFrame:CreateFontString("InputFrame", "ARTWORK", "GameFontNormalLarge")
        InputFrame.HPActual[i]:SetSize(50, 20)
        InputFrame.HPActual[i]:SetPoint("TOP", -25, -20 * i - 40)
        InputFrame.CurrentTimer[i] = InputFrame:CreateFontString("InputFrame", "ARTWORK", "GameFontNormalLarge")
        InputFrame.CurrentTimer[i]:SetSize(50, 20)
        InputFrame.CurrentTimer[i]:SetPoint("TOP", 50, -20 * i - 40)
        InputFrame.Difference[i] = InputFrame:CreateFontString("InputFrame", "ARTWORK", "GameFontNormalLarge")
        InputFrame.Difference[i]:SetSize(50, 20)
        InputFrame.Difference[i]:SetPoint("TOP", 125, -20 * i - 40)
    end

    if IsAddOnLoaded("AzerPUGsCore") then
        AZPTETimerFrame = AZP.Core.AddOns.TE.MainFrame
    end

    VarsAndAddOnLoaded[2] = true
    AZP.TimedEncounters:VarsAndAddOnLoaded()
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

function AZP.TimedEncounters:DelayedExecution(delayTime, delayedFunction)
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

function AZP.TimedEncounters:TrackHealth()
    local bossMaxHealth = UnitHealthMax("boss1")
    local bossCurrentHealth = UnitHealth("boss1")
    local bossPercentHealth = math.floor(bossCurrentHealth/bossMaxHealth*10000)/100
    BossHPBar:SetValue(bossCurrentHealth/bossMaxHealth*10000)
    return bossPercentHealth
end

function AZP.TimedEncounters:UpdateHealth(i, curPercentHealth)
    EncounterTrackingData[i][2] = curPercentHealth
    AZPTETimerFrame.HPActual[i]:SetText(curPercentHealth)
    local percentageDifference =  AZPTESavedList[i][2] - curPercentHealth
    if percentageDifference > 0 then percentageDifference = "+" .. percentageDifference end
    AZPTETimerFrame.Difference[i]:SetText(percentageDifference)

    AZPTECombatBar.checkPoints.HPs[i]:SetText(AZPTESavedList[i][2] .. "%\n" .. percentageDifference .. "")
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
    EncounterTimeIndex = EncounterTimeIndex + 1
    for i = 1, #EncounterTrackingData do
        local curPercentHealth = AZP.TimedEncounters:TrackHealth()
        if EncounterTrackingData[i][1] < 0 then
            AZPTETimerFrame.CurrentTimer[i]:SetText("-")
        elseif EncounterTrackingData[i][1] == 0 then
            AZP.TimedEncounters:UpdateHealth(i, curPercentHealth)
            AZPTETimerFrame.CurrentTimer[i]:SetText(EncounterTrackingData[i][1])
            AZPTECombatBar.checkPoints.timers[i]:SetText(EncounterTrackingData[i][1])
            EncounterTrackingData[i][1] = EncounterTrackingData[i][1] - 1
        else
            AZPTETimerFrame.CurrentTimer[i]:SetText(EncounterTrackingData[i][1])
            AZPTECombatBar.checkPoints.timers[i]:SetText(EncounterTrackingData[i][1])
            EncounterTrackingData[i][1] = EncounterTrackingData[i][1] - 1
        end
    end
end

function AZP.TimedEncounters:OnEvent(event, ...)
    if event == "ENCOUNTER_START" then
        AZP.TimedEncounters.Events:EncounterStart()
    elseif event == "ENCOUNTER_END" then
        AZP.TimedEncounters.Events:EncounterEnd()
    elseif event == "VARIABLES_LOADED" then
        AZP.TimedEncounters.Events:VariablesLoaded()
    end
end

if not IsAddOnLoaded("AzerPUGsCore") then
    AZP.TimedEncounters:OnLoadSelf()
end

SLASH_TE1 = '/te'
SlashCmdList['TE'] =
    function(arg)
        if arg == "show" then
            AZPTETimerFrame:Show()
        end
    end