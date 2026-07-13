local addonName = ...

ShadowDotsDB = ShadowDotsDB or {

    enableVTColor = true,
    enableSWPColor = true,
    enableBothColor = true,

    enableScale = true,
    scaleSize = 1.15,

    vtColor = {
        r = 0.6,
        g = 0,
        b = 1,
    },

    swpColor = {
        r = 1,
        g = 0.5,
        b = 0,
    },

    bothColor = {
        r = 1,
        g = 0,
        b = 0.8,
    },

}



local panel = CreateFrame(
    "Frame",
    "ShadowDotsOptionsPanel",
    InterfaceOptionsFramePanelContainer
)


panel.name = "ShadowDots"



local title = panel:CreateFontString(
    nil,
    "ARTWORK",
    "GameFontNormalLarge"
)

title:SetPoint(
    "TOPLEFT",
    16,
    -16
)

title:SetText(
    "ShadowDots Settings"
)



local function RefreshColors()

    if ShadowDots_IsShadowPriest and not ShadowDots_IsShadowPriest() then
        return
    end


    if ShadowDots_HighlightTarget then
        ShadowDots_HighlightTarget()
    end

end




local function CreateColorBox(parent, x, y, variable)

    local box = CreateFrame(
        "Button",
        nil,
        parent
    )


    box:SetSize(
        22,
        22
    )


    box:SetPoint(
        "TOPLEFT",
        x,
        y
    )


    box.texture = box:CreateTexture(
        nil,
        "BACKGROUND"
    )


    box.texture:SetAllPoints()



    local function Update()

        local c = ShadowDotsDB[variable]


        box.texture:SetColorTexture(
            c.r,
            c.g,
            c.b
        )

    end


    Update()



    box:SetScript(
        "OnClick",
        function()


            local c = ShadowDotsDB[variable]


            ColorPickerFrame:SetColorRGB(
                c.r,
                c.g,
                c.b
            )


            ColorPickerFrame.func = function()


                local r, g, b =
                    ColorPickerFrame:GetColorRGB()


                ShadowDotsDB[variable] = {

                    r = r,
                    g = g,
                    b = b,

                }


                Update()

                RefreshColors()


            end


            ColorPickerFrame:Show()


        end
    )


end




local function CreateCheckbox(
    text,
    x,
    y,
    variable,
    colorVariable
)


    local check = CreateFrame(
        "CheckButton",
        nil,
        panel,
        "InterfaceOptionsCheckButtonTemplate"
    )


    check:SetPoint(
        "TOPLEFT",
        x,
        y
    )


    check.Text:SetText(text)


    check:SetChecked(
        ShadowDotsDB[variable]
    )



    check:SetScript(
        "OnClick",
        function(self)


            ShadowDotsDB[variable] =
                self:GetChecked()


            RefreshColors()


        end
    )



    if colorVariable then


        CreateColorBox(
            panel,
            x + 250,
            y,
            colorVariable
        )


    end


end




CreateCheckbox(
    "Missing Vampiric Touch",
    20,
    -60,
    "enableVTColor",
    "vtColor"
)



CreateCheckbox(
    "Missing Shadow Word: Pain",
    20,
    -100,
    "enableSWPColor",
    "swpColor"
)



CreateCheckbox(
    "Missing Both Dots",
    20,
    -140,
    "enableBothColor",
    "bothColor"
)



CreateCheckbox(
    "Enable Nameplate Size Increase",
    20,
    -200,
    "enableScale"
)




local scaleSlider = CreateFrame(
    "Slider",
    "ShadowDotsScaleSlider",
    panel,
    "OptionsSliderTemplate"
)


scaleSlider:SetPoint(
    "TOPLEFT",
    20,
    -250
)


scaleSlider:SetWidth(
    250
)


scaleSlider:SetMinMaxValues(
    1,
    2
)


scaleSlider:SetValueStep(
    0.05
)


scaleSlider:SetValue(
    ShadowDotsDB.scaleSize
)


scaleSlider:SetScript(
    "OnValueChanged",
    function(self, value)


        ShadowDotsDB.scaleSize = value


        RefreshColors()


    end
)



_G["ShadowDotsScaleSliderText"]:SetText(
    "Nameplate Scale"
)



InterfaceOptions_AddCategory(panel)



SLASH_SHADOWDOTS1 = "/sd"



SlashCmdList["SHADOWDOTS"] = function()


    InterfaceOptionsFrame_OpenToCategory(panel)

    InterfaceOptionsFrame_OpenToCategory(panel)


end