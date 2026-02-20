

BetterEditMode = LibStub("AceAddon-3.0"):NewAddon(
    "BetterEditMode",
    "AceEvent-3.0"
)

local BetterEditMode = LibStub("AceAddon-3.0"):GetAddon("BetterEditMode")
local AceGUI = LibStub("AceGUI-3.0")

local DEFAULTS = {
    AnchorDirection = "RIGHT",
}

local function ApplyDefaults(db, defaults)
    if type(db) ~= "table" then db = {} end
    for k, v in pairs(defaults) do
        if db[k] == nil then
            db[k] = v
        end
    end
    return db
end

local function GetBarBit(idx)
    if idx == 2 then return 0 end  -- Bottom Left
    if idx == 3 then return 1 end  -- Bottom Right
    if idx == 4 then return 2 end  -- Right Bar 1
    if idx == 5 then return 3 end  -- Right Bar 2
    if idx == 6 then return 4 end  -- Bar 5
    if idx == 7 then return 5 end  -- Bar 6
    if idx == 8 then return 6 end  -- Bar 7

    return nil
end

local function GetEnableMultiMask()
    local v = tonumber(GetCVar("enableMultiActionBars")) or 0
    return v
end

local function ToggleBar(frame, enable)
    if InCombatLockdown() then
        UIErrorsFrame:AddMessage("Cannot modify action bars in combat.", 1, 0.2, 0.2)
        return
    end
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_" .. frame, enable)
end

local function InEditMode()
    return EditModeManagerFrame and EditModeManagerFrame:IsShown()
end

local function EnsureClickBindingUILoaded()
    if C_AddOns and not C_AddOns.IsAddOnLoaded("Blizzard_ClickBindingUI") then
        pcall(UIParentLoadAddOn, "Blizzard_ClickBindingUI")
    end
end


local function GetBarEnabled(frame)
    local bitIndex = GetBarBit(frame)
    if bitIndex then
        local mask = GetEnableMultiMask()
        local flag = bit.lshift(1, bitIndex)
        if bit.band(mask, flag) ~= 0 then
            return true
        end
    end
    return false
end

local function setupPanel(panelName, parent)
    local panel = CreateFrame("Frame", panelName, parent, "BackdropTemplate")
    panel:SetSize(260, 10)
    panel:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, 3)
    panel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    panel:SetBackdropColor(0, 0, 0, 0.7)
    return panel
end

local function setupTitle(panel, text)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 8, -8)
    title:SetText(text)
end

local function setupCheckboxWithCallback(parent, featureName, featureData, y)
    local checkBox = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    checkBox:SetPoint("TOPLEFT", 8, y)
    checkBox.Text:SetText(featureName)
    checkBox:SetChecked( featureData.getValue() )
    checkBox:SetScript("OnClick", function(btn)
        isEnabled = featureData.getValue()
        if isEnabled then
            featureData.disable(checkBox)
            checkBox:SetChecked(true)
        else
            -- Enable
            featureData.enable()
        end
    end)
    return checkBox
end

local function setupButtonWithCallback(parent, featureName, featureData, y, x, width)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 20)
    btn:SetText(featureName)
    btn:SetPoint("TOPLEFT", x, y)
    btn:SetScript("OnClick", function(btn)
        featureData.callback()
    end)
        
end

function BetterEditMode:CreateBindingsPanel()
    if self._bndPanel then return end
    if not EditModeManagerFrame then return end
    parent = self._abMiniPanel
    panel = setupPanel( "BetterEditMode_BindingsPanel", parent)
    setupTitle( panel, "Bindings")
    panel.controls = {}

    local y = -32

    local features = {
        ["Character Specific Keybinds"] = {
                    type = "check",
                    getValue = function()
                        return GetCurrentBindingSet() == 2
                    end,
                    disable = function(checkbox)
                        BetterEditMode._pendingKeybindCheckbox = checkbox
                        StaticPopup_Show("CONFIRM_DELETING_CHARACTER_SPECIFIC_BINDINGS"); 
                    end,
                    enable = function()
                        Settings.SetValue("PROXY_CHARACTER_SPECIFIC_BINDINGS", true)
                    end
                },
        ["ROW_1"] = {
            type = "row",
            children = {
                ["Keybinding Mode"] = {
                    type = "button",
                    width = 110,
                    callback = function()
                        if InCombatLockdown() then
                            UIErrorsFrame:AddMessage("Cannot open Keybinding mode in combat.", 1, 0.2, 0.2)
                            return
                        end
                        if EditModeManagerFrame:HasActiveChanges() then
                            print("Active changes detected")
                        else
                            self.ClickedKeybindingMode = true
                            QuickKeybindFrame:HookScript("OnHide", function()
                                if self.ClickedKeybindingMode then
                                    self.ClickedKeybindingMode = false
                                    ShowUIPanel(EditModeManagerFrame)
                                end
                            end)
                            HideUIPanel(EditModeManagerFrame)
                            QuickKeybindFrame:Show()
                        end
                    end
                },
                ["Click Casting"] = {
                    type = "button",
                    width = 110,
                    callback = function()
                        if InCombatLockdown() then
                            UIErrorsFrame:AddMessage("Cannot open Click Casting in combat.", 1, 0.2, 0.2)
                            return
                        end
                        if EditModeManagerFrame:HasActiveChanges() then
                            print("Active changes detected")
                        else
                            self.ClickedCastingButton = true
                            EnsureClickBindingUILoaded()
                            ClickBindingFrame:HookScript("OnHide", function()
                                if self.ClickedCastingButton then
                                    self.ClickedCastingButton = false
                                    ShowUIPanel(EditModeManagerFrame)
                                end
                            end)
                            HideUIPanel(EditModeManagerFrame)
                            ToggleClickBindingFrame()
                        end
                    end
                }
            }
        },
        ["ROW_2"] = {
            type = "row",
            children = {
                ['Advanced Cooldowns'] = {
                    type = "button",
                    width = 220,
                    callback = function()
                        if InCombatLockdown() then
                            UIErrorsFrame:AddMessage("Cannot open Advanced Cooldowns in combat.", 1, 0.2, 0.2)
                            return
                        end
                        if EditModeManagerFrame:HasActiveChanges() then
                            print("Active changes detected")
                        else
                            CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
                        end
                    end
                }
            }
        }
    }
    for featureName, featureData in pairs(features) do
        if featureData.type == "check" then
            setupCheckboxWithCallback(panel, featureName, featureData, y)
        elseif featureData.type == "row" then
            local x = 10
            for childName, childData in pairs(featureData.children) do
                setupButtonWithCallback( panel, childName, childData, y, x, childData.width)
                x = x + 110
            end
        end
        table.insert(panel.controls, 1)
        y = y - 22
    end
    height = math.max((32 + 16) + (#panel.controls * 22), 60)
    panel:SetSize(260, height)

    self._bndPanel = panel
end

function BetterEditMode:CreateCdManagerPanel()
    if self._cdMiniPanel then return end
    if not EditModeManagerFrame then return end

    parent = self._bndPanel
    panel = setupPanel("BetterEditMode_CdMiniPanel", parent)
    setupTitle(panel, "CD Manager Settings")

    panel.checks = {}

    local y = -32
    local _, _, _, toc = GetBuildInfo()

    local features = {
        ["Cooldown Manager"] = {
            cVar = "cooldownViewerEnabled",
            cVarEnabled = "1",
            cVarDisabled = "0",
            minVersion = 110207,
        },
        ["External Defensives"] = {
            cVar = "externalDefensivesEnabled",
            cVarEnabled = "1",
            cVarDisabled = "0",
            minVersion = 120000,
        },
        ["Damage Meter"] = {
            cVar = "damageMeterEnabled",
            cVarEnabled = "1",
            cVarDisabled = "0",
            minVersion = 120000,
        },
        ["Boss Warnings"] = {
            cVar = "combatWarningsEnabled",
            cVarEnabled = "1",
            cVarDisabled = "0",
            minVersion = 120000,
        },
        ["Diminishing Returns Tracking"] = {
            cVar = "spellDiminishPVPEnemiesEnabled",
            cVarEnabled = "1",
            cVarDisabled = "0",
            minVersion = 120000,
            children = {
                ["Only castable by me"] = {
                    cVar = "spellDiminishPVPOnlyTriggerableByMe",
                    minVersion = 120000,
                    cVarEnabled = "1",
                    cVarDisabled = "0"
                }
            }
        }
    }
    for featureName, featureData in pairs(features) do
        if toc >= featureData.minVersion then
            cb = CreateFrame("CheckButton", nil, panel, "ChatConfigCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 8, y)
            y = y - 22
            cb.Text:SetText(featureName)
            cb:SetChecked(GetCVar(featureData.cVar) == featureData.cVarEnabled)
            cb:SetScript("OnClick", function(btn)
                isEnabled = GetCVar(featureData.cVar) == featureData.cVarEnabled
                if isEnabled then
                    SetCVar(featureData.cVar, featureData.cVarDisabled)
                else
                    SetCVar(featureData.cVar, featureData.cVarEnabled)
                end
            end)
            table.insert(panel.checks, cb)
        end
    end

    height = math.max((32 + 16) + (#panel.checks * 22), 60)
    panel:SetSize(260, height)

    self._cdMiniPanel = panel
end


function BetterEditMode:CreateActionBarMiniPanel()
    if self._abMiniPanel then return end
    if not EditModeManagerFrame then return end
    parent = EditModeManagerFrame
    panel = CreateFrame("Frame", "BetterEditMode_ActionBarMiniPanel", parent, "BackdropTemplate")
    panel:SetSize(260, 10)
    if BetterEditModeDB.AnchorDirection == "RIGHT" then
        panel:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    else
        panel:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0);
    end

    panel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    panel:SetBackdropColor(0, 0, 0, 0.7)

    title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 8, -8)
    title:SetText("Action Bars Enabled")
    panel.checks = {}

    header = CreateFrame("Frame", nil, panel)
    header:SetPoint("TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", -6, -6)
    header:SetHeight(28)
    

    
    -- Start below header
    local y = -32

    for i = 2, 8 do
        cb = CreateFrame("CheckButton", nil, panel, "ChatConfigCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 8, y)
        y = y - 22

        local label = "Action Bar " .. tostring(i)
        cb.Text:SetText(label)
        cb:SetChecked(GetBarEnabled(i))
        cb:SetScript("OnClick", function(btn)
            if InCombatLockdown() then
                btn:SetChecked(GetBarEnabled(i))
                UIErrorsFrame:AddMessage("Cannot modify action bars in combat.", 1, 0.2, 0.2)
                return
            end
            ToggleBar(i, btn:GetChecked())
        end)
        table.insert(panel.checks, cb)
    end

    height = math.max((32 + 16) + (#panel.checks * 22), 60)
    panel:SetSize(260, height)

    self._abMiniPanel = panel
end


function BetterEditMode:UpdateActionBarMiniPanelVisibility()
    if not self._abMiniPanel then return end
    if not InEditMode() then
        self._abMiniPanel:Hide()
        return
    end

    self._abMiniPanel:Show()
end

function BetterEditMode:SetupEditModeHooks()
    if self._editModeHooked then return end
    self._editModeHooked = true

    self:CreateActionBarMiniPanel()
    self:CreateBindingsPanel()
    self:CreateCdManagerPanel()

    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
        self._abMiniPanel:Show()
    end)

    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        self._abMiniPanel:Hide()
    end)

    -- EditModeManagerFrame:HookScript("OnShow", function()
    --     self._abMiniPanel:Show()
    -- end)
    -- EditModeManagerFrame:HookScript("OnHide", function()
    --     self._abMiniPanel:Hide()
    -- end)
end

function BetterEditMode:HookStaticPopupResponse()
    if self._keybindPopupHooked then return end
    self._keybindPopupHooked = true

    local popup = StaticPopupDialogs["CONFIRM_DELETING_CHARACTER_SPECIFIC_BINDINGS"]
    if popup ~= nil then
        popup.OnAccept = function(dialog, data)
            Settings.SetValue("PROXY_CHARACTER_SPECIFIC_BINDINGS", false);
            if BetterEditMode._pendingKeybindCheckbox ~= nil then
                BetterEditMode._pendingKeybindCheckbox:SetChecked(false)
                BetterEditMode._pendingKeybindCheckbox = nil
            end
        end
    end
end

function BetterEditMode:CreateOptionsPanel()
    if self._optionsPanel then return end
    local panel = CreateFrame("Frame", "BetterEdit_Config", UIParent)
    panel.name = "Better Edit Mode"
    local configTitle = panel:CreateFontString(nil, "ARTWORK")
    configTitle:SetFont(STANDARD_TEXT_FONT, 18)
    configTitle:SetPoint("TOPLEFT", 16, -16)
    configTitle:SetText("BetterEditMode - Settings & Options")
    if not panel._aceContainer then
        local container = AceGUI:Create("SimpleGroup")
        container.frame:SetParent(panel)
        container.frame:SetPoint("TOPLEFT", 16, -50)
        container.frame:SetPoint("TOPRIGHT", -16, -50)
        container.frame:SetHeight(80)
        container:SetLayout("List")
        panel._aceContainer = container
    end
    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetWidth(200)
    dropdown:SetList({ LEFT = "Left", RIGHT = "Right" })
    dropdown:SetValue(BetterEditModeDB.AnchorDirection or "RIGHT")
    dropdown:SetLabel("Frame Anchor")
    dropdown:SetCallback("OnValueChanged", function(_, _, key)
        BetterEditModeDB.AnchorDirection = key
        self._abMiniPanel = nil
        self._cdMiniPanel = nil
        self._bndPanel = nil
        self:CreateActionBarMiniPanel()
        self:CreateBindingsPanel()
        self:CreateCdManagerPanel()
    end)
    panel._aceContainer:AddChild(dropdown)
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Better Edit Mode")
    Settings.RegisterAddOnCategory(category)
    self._optionsPanel = panel
end

function BetterEditMode:OnEnable()
    self.ClickedCastingButton = false
    if type(BetterEditModeDB) ~= "table" then BetterEditModeDB = {} end
    if C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
        self:SetupEditModeHooks()
        self:HookStaticPopupResponse()
        self:CreateOptionsPanel()
    else
        self:RegisterEvent("ADDON_LOADED", function(_, addonName)
            if addonName == "Blizzard_EditMode" then
                self:SetupEditModeHooks()
            end
        end)
    end
end