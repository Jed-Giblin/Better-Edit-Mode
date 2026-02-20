-- Modules/BindingsPanel.lua: Keybinding and click casting panel

local BEM = BetterEditMode

local function SetupCheckboxWithCallback(parent, featureName, featureData, y)
    local cb = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 8, y)
    cb.Text:SetText(featureName)
    cb:SetChecked(featureData.getValue())
    cb:SetScript("OnClick", function(btn)
        if featureData.getValue() then
            featureData.disable(btn)
            btn:SetChecked(true)
        else
            featureData.enable()
        end
    end)
    return cb
end

local function SetupButtonWithCallback(parent, featureName, featureData, y, x, width)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 20)
    btn:SetText(featureName)
    btn:SetPoint("TOPLEFT", x, y)
    btn:SetScript("OnClick", featureData.callback)
    return btn
end

function BEM:CreateBindingsPanel()
    if self._bndPanel then return end
    if not EditModeManagerFrame then return end
    if not self._abMiniPanel then return end

    local panel = BetterEditMode_BindingsPanel
    panel:SetParent(self._abMiniPanel)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", self._abMiniPanel, "BOTTOMLEFT", 0, 3)

    panel.controls = panel.controls or {}

    -- Clear existing controls if recreating
    for _, ctrl in ipairs(panel.controls) do
        if ctrl.Hide then
            ctrl:Hide()
            ctrl:SetParent(nil)
        end
    end
    wipe(panel.controls)

    local y = -32

    local features = {
        {
            name = "Character Specific Keybinds",
            type = "check",
            getValue = function() return GetCurrentBindingSet() == 2 end,
            disable = function(checkbox)
                BEM._pendingKeybindCheckbox = checkbox
                StaticPopup_Show("CONFIRM_DELETING_CHARACTER_SPECIFIC_BINDINGS")
            end,
            enable = function()
                Settings.SetValue("PROXY_CHARACTER_SPECIFIC_BINDINGS", true)
            end
        },
        {
            name = "ROW_1",
            type = "row",
            children = {
                {
                    name = "Keybinding Mode",
                    width = 110,
                    callback = function()
                        if InCombatLockdown() then
                            UIErrorsFrame:AddMessage("Cannot open Keybinding mode in combat.", 1, 0.2, 0.2)
                            return
                        end
                        BEM.ClickedKeybindingMode = true
                        QuickKeybindFrame:HookScript("OnHide", function()
                            if BEM.ClickedKeybindingMode then
                                BEM.ClickedKeybindingMode = false
                                ShowUIPanel(EditModeManagerFrame)
                            end
                        end)
                        HideUIPanel(EditModeManagerFrame)
                        QuickKeybindFrame:Show()
                    end
                },
                {
                    name = "Click Casting",
                    width = 110,
                    callback = function()
                        if InCombatLockdown() then
                            UIErrorsFrame:AddMessage("Cannot open Click Casting in combat.", 1, 0.2, 0.2)
                            return
                        end
                        BEM.ClickedCastingButton = true
                        BEM:EnsureClickBindingUILoaded()
                        ClickBindingFrame:HookScript("OnHide", function()
                            if BEM.ClickedCastingButton then
                                BEM.ClickedCastingButton = false
                                ShowUIPanel(EditModeManagerFrame)
                            end
                        end)
                        HideUIPanel(EditModeManagerFrame)
                        ToggleClickBindingFrame()
                    end
                },
            },
        },
        {
            name = "ROW_2",
            type = "row",
            children = {
                {
                    name = "Advanced Cooldowns",
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

    local controlCount = 0
    for _, feature in ipairs(features) do
        if feature.type == "check" then
            local cb = SetupCheckboxWithCallback(panel, feature.name, feature, y)
            table.insert(panel.controls, cb)
            controlCount = controlCount + 1
        elseif feature.type == "row" then
            local x = 10
            for _, child in ipairs(feature.children) do
                local btn = SetupButtonWithCallback(panel, child.name, child, y, x, child.width)
                table.insert(panel.controls, btn)
                x = x + 115
            end
            controlCount = controlCount + 1
        end
        y = y - 26
    end

    local height = math.max((32 + 16) + (controlCount * 26), 60)
    panel:SetSize(290, height)
    panel:Show()

    self._bndPanel = panel
end
