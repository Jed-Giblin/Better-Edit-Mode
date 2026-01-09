-- Modules/CooldownPanel.lua: Cooldown manager settings

local BEM = BetterEditMode

function BEM:CreateCdManagerPanel()
    if self._cdMiniPanel then return end
    if not EditModeManagerFrame then return end
    if not self._bndPanel then return end

    local panel = BetterEditMode_GameplayEnhancementsPanel
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
        { name = "Diminishing Returns Tracking", cVar = "spellDiminishPVPEnemiesEnabled", minVersion = 120000, children = {
            { name = "Only Castable by me", cVar = "spellDiminishPVPOnlyTriggerableByMe", minVersion = 120000 }
            }
        }
    }

    for _, feature in ipairs(features) do
        if toc >= feature.minVersion then
            local cb = CreateFrame("CheckButton", nil, panel, "ChatConfigCheckButtonTemplate")
            local children = {}
            cb:SetPoint("TOPLEFT", 8, y)
            cb.Text:SetText(feature.name)
            cb:SetChecked(GetCVar(feature.cVar) == "1")
            if feature.children ~= nil then
                local yy = -22
                for _, child in ipairs(feature.children) do
                    local childCb = CreateFrame("CheckButton", nil, cb, "ChatConfigCheckButtonTemplate")
                    childCb:SetPoint("TOPLEFT", 12, yy)
                    childCb.Text:SetText(child.name)
                    childCb:SetChecked(GetCVar(child.cVar) == "1")
                    table.insert(panel.checks, childCb)
                    table.insert(children, childCb)
                    if cb:GetChecked() == false then
                        childCb:Disable()
                        childCb.Text:SetTextColor(0.5, 0.5, 0.5)
                    end
                    yy = yy - 22
                    BEM:setupCvarListener(child.cVar, childCb)
                end
            end

            local cvarName = feature.cVar
            BEM:setupCvarListener( cvarName, cb)
            cb:SetScript("OnClick", function(btn)
                local isEnabled = GetCVar(cvarName) == "1"
                SetCVar(cvarName, isEnabled and "0" or "1")
                if #children > 0 then
                    for _, child in ipairs(children) do
                        if btn:GetChecked() then
                            child:Enable()
                            child.Text:SetTextColor(1, 1, 1)
                        else
                            child:Disable()
                            child.Text:SetTextColor(0.5, 0.5, 0.5)
                        end
                    end
                end
            end)
            y = y - 22
            table.insert(panel.checks, cb)
        end
    end
    for k, v in pairs(Settings) do
        print(k)
        if k:match("_ID" .. "$") then
            print(k)
        end
    end
    print(Settings.GetSetting("cooldownViewerEnabled"))
    panel:RegisterEvent("CVAR_UPDATE")
    panel:SetScript("OnEvent", function(_, event, cvarName, cvarValue)
        if event == "CVAR_UPDATE" then
            if BEM.cvarListeners[cvarName] == nil then return end
            BEM.cvarListeners[cvarName](cvarValue)
        end
    end)

    local height = math.max((32 + 16) + (#panel.checks * 22), 60)
    panel:SetSize(290, height)
    panel:Show()

    self._cdMiniPanel = panel
end
