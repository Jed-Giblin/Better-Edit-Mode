-- Modules/Options.lua: Settings panel

local BEM = BetterEditMode
local AceGUI = LibStub("AceGUI-3.0")

function BEM:CreateOptionsPanel()
    if self._optionsPanel then return end

    local panel = CreateFrame("Frame", "BetterEdit_Config", UIParent)
    panel.name = "Better Edit Mode"

    local title = panel:CreateFontString(nil, "ARTWORK")
    title:SetFont(STANDARD_TEXT_FONT, 18)
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("BetterEditMode - Settings & Options")

    local container = AceGUI:Create("SimpleGroup")
    container.frame:SetParent(panel)
    container.frame:SetPoint("TOPLEFT", 16, -50)
    container.frame:SetPoint("TOPRIGHT", -16, -50)
    container.frame:SetHeight(80)
    container:SetLayout("List")

    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetWidth(200)
    dropdown:SetList({ LEFT = "Left", RIGHT = "Right" })
    dropdown:SetValue(BetterEditModeDB.AnchorDirection or "RIGHT")
    dropdown:SetLabel("Frame Anchor")
    dropdown:SetCallback("OnValueChanged", function(_, _, key)
        BetterEditModeDB.AnchorDirection = key
        BEM:RecreatePanels()
    end)
    container:AddChild(dropdown)

    local category = Settings.RegisterCanvasLayoutCategory(panel, "Better Edit Mode")
    Settings.RegisterAddOnCategory(category)

    self._optionsPanel = panel
end
