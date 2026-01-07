-- Modules/ActionBarPanel.lua: Action bar toggle panel logic

local BEM = BetterEditMode

function BEM:CreateActionBarMiniPanel()
    if self._abMiniPanel then return end
    if not EditModeManagerFrame then return end

    local panel = BetterEditMode_ActionBarMiniPanel
    panel:SetParent(EditModeManagerFrame)

    panel:ClearAllPoints()
    if BetterEditModeDB.AnchorDirection == "RIGHT" then
        panel:SetPoint("TOPLEFT", EditModeManagerFrame, "TOPRIGHT", 0, 0)
    else
        panel:SetPoint("TOPRIGHT", EditModeManagerFrame, "TOPLEFT", 0, 0)
    end

    panel.checks = panel.checks or {}

    -- Clear existing checkboxes if recreating
    for _, cb in ipairs(panel.checks) do
        cb:Hide()
        cb:SetParent(nil)
    end
    wipe(panel.checks)

    local y = -32

    for i = 2, 8 do
        local cb = CreateFrame("CheckButton", nil, panel, "ChatConfigCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 8, y)
        y = y - 22

        cb.Text:SetText("Action Bar " .. tostring(i))
        cb:SetChecked(self:GetBarEnabled(i))

        local barIndex = i
        cb:SetScript("OnClick", function(btn)
            if InCombatLockdown() then
                btn:SetChecked(BEM:GetBarEnabled(barIndex))
                UIErrorsFrame:AddMessage("Cannot modify action bars in combat.", 1, 0.2, 0.2)
                return
            end
            BEM:ToggleBar(barIndex, btn:GetChecked())
        end)
        table.insert(panel.checks, cb)
    end

    local height = math.max((32 + 16) + (#panel.checks * 22), 60)
    panel:SetSize(260, height)

    if self:InEditMode() then
        panel:Show()
    end

    self._abMiniPanel = panel
end
