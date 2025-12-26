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

local function SetEnableMultiMask(mask)
    SetCVar("enableMultiActionBars", tostring(mask))
end

local function SetBarEnabledByBit(idx, enable)
    local bitIndex = GetBarBit(idx)
    if not bitIndex then return end
    local mask = GetEnableMultiMask()
    local flag = bit.lshift(1, bitIndex)
    if enable then
        mask = bit.bor(mask, flag)
    else
        mask = bit.band(mask, bit.bnot(flag))
    end
    SetEnableMultiMask(mask)
end

local function SetBarEnabled(frame, enable)
    if InCombatLockdown() then
        UIErrorsFrame:AddMessage("Cannot modify action bars in combat.", 1, 0.2, 0.2)
        return
    end

    SetBarEnabledByBit(frame, enable)

    if ActionBarController_UpdateAll then
        pcall(ActionBarController_UpdateAll)
    end
    if UpdateMultiActionBars then
        pcall(UpdateMultiActionBars)
    end
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

local function GetBarVisible(frame)
    if frame and frame.GetSettingValue then
        return frame:IsShown()
    end
    return frame and frame:IsShown() or false
end

local function SetBarVisible(frame, enable)
    if not frame or not frame.SetSettingValue then return end
    frame:SetSettingValue(5, enable and 1 or 0)
    if frame.UpdateSystem then
        frame:UpdateSystem()
    end
end

function BetterEditMode:CreateCdManagerPanel()
    if self._cdMiniPanel then return end
    if not EditModeManagerFrame then return end

    local parent = self._abMiniPanel or EditModeManagerFrame
    local panel = CreateFrame("Frame", "BetterEditMode_CdMiniPanel", parent, "BackdropTemplate")
    panel:SetSize(260, 10)
    panel:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, 3)
    panel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    panel:SetBackdropColor(0, 0, 0, 0.7)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 8, -8)
    title:SetText("CD Manager Settings")

    panel.checks = {}

    local y = -32

    local _, _, _, toc = GetBuildInfo()

    local features = {
        ["Cooldown Manager"] = {
            cVar = "cooldownViewerEnabled",
            cVarEnabled = "1",
            cVarDisabled = "0",
            minVersion = 110207
        },
        ["External Defensives"] = {
            cVar = "externalDefensivesEnabled",
            cVarEnabled = "1",
            cVarDisabled = "0",
            minVersion = 120000
        },
        ["Damage Meter"] = {
            cVar = "damageMeterEnabled",
            cVarEnabled = "1",
            cVarDisabled = "0",
            minVersion = 120000
        },
        ["Boss Warnings"] = {
            cVar = "combatWarningsEnabled",
            cVarEnabled = "1",
            cVarDisabled = "0",
            minVersion = 120000
        },
        ["Diminishing Returns Tracking"] = {
            cVar = "spellDiminishPVPEnemiesEnabled",
            cVarEnabled = "1",
            cVarDisabled = "0",
            minVersion = 120000,
            children = {
                ["Only castable by me"] = {
                    cVar = "spellDiminishPVPOnlyTriggerableByMe",
                    cVarEnabled = "1",
                    cVarDisabled = "0"
                }
            }
        }
    }

    for featureName, featureData in pairs(features) do
        if toc >= featureData.minVersion then
            local cb = CreateFrame("CheckButton", nil, panel, "ChatConfigCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 8, y)
            y = y - 22
            cb.Text:SetText(featureName)
            cb:SetChecked(GetCVar(featureData.cVar) == featureData.cVarEnabled)
            cb:SetScript("OnClick", function()
                local isEnabled = GetCVar(featureData.cVar) == featureData.cVarEnabled
                if isEnabled then
                    SetCVar(featureData.cVar, featureData.cVarDisabled)
                else
                    SetCVar(featureData.cVar, featureData.cVarEnabled)
                end
            end)
            table.insert(panel.checks, cb)
        end
    end

    local height = math.max((32 + 16) + (#panel.checks * 22), 60)
    panel:SetSize(260, height)

    self._cdMiniPanel = panel
end

function BetterEditMode:CreateActionBarMiniPanel()
    if self._abMiniPanel then return end
    if not EditModeManagerFrame then return end

    local parent = EditModeManagerFrame
    local panel = CreateFrame("Frame", "BetterEditMode_ActionBarMiniPanel", parent, "BackdropTemplate")
    panel:SetSize(260, 10)
    if BetterEditModeDB.AnchorDirection == "RIGHT" then
        panel:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    else
        panel:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)        
    end
    

    panel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    panel:SetBackdropColor(0, 0, 0, 0.7)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 8, -8)
    title:SetText("Action Bars Enabled")
    panel.checks = {}

    local header = CreateFrame("Frame", nil, panel)
    header:SetPoint("TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", -6, -6)
    header:SetHeight(28)
    local btn1 = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    btn1:SetSize(110, 20)
    btn1:SetText("Click Casting")
    btn1:SetPoint("RIGHT")

    btn1:SetScript("OnClick", function()
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
            ClickBindingFrame:Show()
        end
    end)

    -- Start below header
    local y = -32

    for i = 2, 8 do
        local cb = CreateFrame("CheckButton", nil, panel, "ChatConfigCheckButtonTemplate")
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
            SetBarEnabled(i, btn:GetChecked())
        end)
        table.insert(panel.checks, cb)
    end

    local height = math.max((32 + 16) + (#panel.checks * 22), 60)
    panel:SetSize(260, height)

    self._abMiniPanel = panel
end

function BetterEditMode:CreateOptionsPanel()
    if self._optionsPanel then return end

    local panel = CreateFrame("Frame", "BetterEdit_Config", UIParent)
    panel.name = "Better Edit Mode"

    local configTitle = panel:CreateFontString(nil, "ARTWORK")
    configTitle:SetFont(STANDARD_TEXT_FONT, 18)
    configTitle:SetPoint("TOPLEFT", 16, -16)
    configTitle:SetText("BetterEditMode - Settings & Options")

    -- Create/attach AceGUI container once
    if not panel._aceContainer then
        local container = AceGUI:Create("SimpleGroup")
        container.frame:SetParent(panel)
        container.frame:SetPoint("TOPLEFT", 16, -50)
        container.frame:SetPoint("TOPRIGHT", -16, -50)
        container.frame:SetHeight(80)
        container:SetLayout("List")
        panel._aceContainer = container
    end

    -- Dropdown: Left/Right
    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetWidth(200)
    dropdown:SetList({ LEFT = "Left", RIGHT = "Right" })
    dropdown:SetValue(BetterEditModeDB.AnchorDirection or "RIGHT")
    dropdown:SetLabel("Frame Anchor")
    dropdown:SetCallback("OnValueChanged", function(_, _, key)
        BetterEditModeDB.AnchorDirection = key
        self._abMiniPanel = nil
        self._cdMiniPanel = nil
        self:CreateActionBarMiniPanel()
        self:CreateCdManagerPanel()
    end)
    panel._aceContainer:AddChild(dropdown)

    local category = Settings.RegisterCanvasLayoutCategory(panel, "Better Edit Mode")
    Settings.RegisterAddOnCategory(category)

    self._optionsPanel = panel
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
    self:CreateCdManagerPanel()

    EditModeManagerFrame:HookScript("OnShow", function()
        self._abMiniPanel:Show()
    end)
    EditModeManagerFrame:HookScript("OnHide", function()
        self._abMiniPanel:Hide()
    end)
end

function BetterEditMode:OnEnable()
    self.ClickedCastingButton = false
    if type(BetterEditModeDB) ~= "table" then
        BetterEditModeDB = {}
    end
    ApplyDefaults(BetterEditModeDB, DEFAULTS)
    if C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
        self:SetupEditModeHooks()
        self:CreateOptionsPanel()
    else
        self:RegisterEvent("ADDON_LOADED", function(_, addonName)
            if addonName == "Blizzard_EditMode" then
                self:SetupEditModeHooks()
            end
        end)
    end
end