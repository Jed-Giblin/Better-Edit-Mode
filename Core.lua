-- Core.lua: Addon initialization and shared utilities

BetterEditMode = LibStub("AceAddon-3.0"):NewAddon(
    "BetterEditMode",
    "AceEvent-3.0"
)

local BEM = BetterEditMode

-- Defaults
BEM.DEFAULTS = {
    AnchorDirection = "RIGHT",
}

-- Shared backdrop info
BEM.PANEL_BACKDROP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileEdge = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- Apply backdrop to panel frames
function BEM:ApplyPanelBackdrop(frame)
    frame:SetBackdrop(self.PANEL_BACKDROP)
    frame:SetBackdropColor(0, 0, 0, 0.7)
end

-- Utility functions
function BEM:ApplyDefaults(db, defaults)
    if type(db) ~= "table" then db = {} end
    for k, v in pairs(defaults) do
        if db[k] == nil then
            db[k] = v
        end
    end
    return db
end

function BEM:GetBarBit(idx)
    local bits = { [2] = 0, [3] = 1, [4] = 2, [5] = 3, [6] = 4, [7] = 5, [8] = 6 }
    return bits[idx]
end

function BEM:GetEnableMultiMask()
    return tonumber(GetCVar("enableMultiActionBars")) or 0
end

function BEM:GetBarEnabled(frame)
    local bitIndex = self:GetBarBit(frame)
    if bitIndex then
        local mask = self:GetEnableMultiMask()
        local flag = bit.lshift(1, bitIndex)
        return bit.band(mask, flag) ~= 0
    end
    return false
end

function BEM:ToggleBar(frame, enable)
    if InCombatLockdown() then
        UIErrorsFrame:AddMessage("Cannot modify action bars in combat.", 1, 0.2, 0.2)
        return
    end
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_" .. frame, enable)
end

function BEM:InEditMode()
    return EditModeManagerFrame and EditModeManagerFrame:IsShown()
end

function BEM:EnsureClickBindingUILoaded()
    if C_AddOns and not C_AddOns.IsAddOnLoaded("Blizzard_ClickBindingUI") then
        pcall(UIParentLoadAddOn, "Blizzard_ClickBindingUI")
    end
end

-- Addon Enable
function BEM:OnEnable()
    self.ClickedCastingButton = false
    self.ClickedKeybindingMode = false

    if type(BetterEditModeDB) ~= "table" then BetterEditModeDB = {} end
    self:ApplyDefaults(BetterEditModeDB, self.DEFAULTS)

    if C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
        self:SetupEditModeHooks()
        self:HookStaticPopupResponse()
        self:CreateOptionsPanel()
    else
        self:RegisterEvent("ADDON_LOADED", function(_, addonName)
            if addonName == "Blizzard_EditMode" then
                self:SetupEditModeHooks()
                self:HookStaticPopupResponse()
                self:CreateOptionsPanel()
            end
        end)
    end
end

function BEM:SetupEditModeHooks()
    if self._editModeHooked then return end
    self._editModeHooked = true

    self:CreateActionBarMiniPanel()
    self:CreateBindingsPanel()
    self:CreateCdManagerPanel()

    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
        if self._abMiniPanel then
            self._abMiniPanel:Show()
        end
    end)

    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        if self._abMiniPanel then
            self._abMiniPanel:Hide()
        end
    end)
end

function BEM:HookStaticPopupResponse()
    if self._keybindPopupHooked then return end
    self._keybindPopupHooked = true

    local popup = StaticPopupDialogs["CONFIRM_DELETING_CHARACTER_SPECIFIC_BINDINGS"]
    if popup then
        popup.OnAccept = function()
            Settings.SetValue("PROXY_CHARACTER_SPECIFIC_BINDINGS", false)
            if BEM._pendingKeybindCheckbox then
                BEM._pendingKeybindCheckbox:SetChecked(false)
                BEM._pendingKeybindCheckbox = nil
            end
        end
    end
end

function BEM:RecreatePanels()
    if self._abMiniPanel then
        self._abMiniPanel:Hide()
        self._abMiniPanel:SetParent(nil)
    end
    if self._bndPanel then
        self._bndPanel:Hide()
        self._bndPanel:SetParent(nil)
    end
    if self._cdMiniPanel then
        self._cdMiniPanel:Hide()
        self._cdMiniPanel:SetParent(nil)
    end

    self._abMiniPanel = nil
    self._bndPanel = nil
    self._cdMiniPanel = nil

    self:CreateActionBarMiniPanel()
    self:CreateBindingsPanel()
    self:CreateCdManagerPanel()
end
