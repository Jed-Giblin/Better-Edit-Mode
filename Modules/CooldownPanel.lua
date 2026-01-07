-- Modules/CooldownPanel.lua: Cooldown manager settings

local BEM = BetterEditMode

function BEM:CreateCdManagerPanel()
    if self._cdMiniPanel then return end
    if not EditModeManagerFrame then return end
    if not self._bndPanel then return end

    local panel = BetterEditMode_CdMiniPanel
    panel:SetParent(self._bndPanel)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", self._bndPanel, "BOTTOMLEFT", 0, 3)

    panel.checks = panel.checks or {}

    -- Clear existing checkboxes if recreating
    for _, cb in ipairs(panel.checks) do
        cb:Hide()
        cb:SetParent(nil)
    end
    wipe(panel.checks)

    local y = -32
    local _, _, _, toc = GetBuildInfo()

    local features = {
        { name = "Cooldown Manager", cVar = "cooldownViewerEnabled", minVersion = 110207 },
        { name = "External Defensives", cVar = "externalDefensivesEnabled", minVersion = 120000 },
        { name = "Damage Meter", cVar = "damageMeterEnabled", minVersion = 120000 },
        { name = "Boss Warnings", cVar = "combatWarningsEnabled", minVersion = 120000 },
        { name = "Diminishing Returns Tracking", cVar = "spellDiminishPVPEnemiesEnabled", minVersion = 120000 },
    }

    for _, feature in ipairs(features) do
        if toc >= feature.minVersion then
            local cb = CreateFrame("CheckButton", nil, panel, "ChatConfigCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 8, y)
            y = y - 22
            cb.Text:SetText(feature.name)
            cb:SetChecked(GetCVar(feature.cVar) == "1")

            local cvarName = feature.cVar
            cb:SetScript("OnClick", function(btn)
                local isEnabled = GetCVar(cvarName) == "1"
                SetCVar(cvarName, isEnabled and "0" or "1")
            end)
            table.insert(panel.checks, cb)
        end
    end

    local height = math.max((32 + 16) + (#panel.checks * 22), 60)
    panel:SetSize(260, height)
    panel:Show()

    self._cdMiniPanel = panel
end
