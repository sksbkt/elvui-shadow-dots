local E = unpack(ElvUI)
local plugin = LibStub("LibElvUIPlugin-1.0", true)
local pendingSpellID
local dotListArgs
local BuildDotRows
local addStatus = ""
local spellLinkHooked

local function ExtractSpellID(value)
    if type(value) ~= "string" then
        return
    end
    local spellID = value:match("|Hspell:(%d+)")
    if not spellID then
        spellID = value:match("|hspell:(%d+)")
    end
    return tonumber(spellID)
end

local function HookSpellLinkInput()
    if spellLinkHooked or not hooksecurefunc then
        return
    end
    local AceGUI = LibStub("AceGUI-3.0", true)
    if not AceGUI then
        return
    end
    hooksecurefunc("ChatEdit_InsertLink", function()
        for index = 1, AceGUI:GetWidgetCount("EditBox") do
            local editBox = _G["AceGUI-3.0EditBox"..index]
            if editBox and editBox:IsVisible() and editBox:HasFocus() then
                local spellID = ExtractSpellID(editBox:GetText())
                if spellID then
                    local text = tostring(spellID)
                    editBox:SetText(text)
                    pendingSpellID = text
                end
                return
            end
        end
    end)
    spellLinkHooked = true
end

HookSpellLinkInput()

local function Refresh()
    if ShadowDots_RefreshVisuals then
        ShadowDots_RefreshVisuals()
    end
    local registry = LibStub("AceConfigRegistry-3.0-ElvUI", true)
    if registry then
        registry:NotifyChange("ElvUI")
    end
end

local function FeatureDisabled()
    return not ShadowDotsDB.enabled
end

local function ColorDisabled()
    return FeatureDisabled() or not ShadowDotsDB.enableColor
end

local function ScaleDisabled()
    return FeatureDisabled() or not ShadowDotsDB.enableScale
end

local function BlinkDisabled()
    return FeatureDisabled() or not ShadowDotsDB.enableBlink
end

local function GetGeneralStatus()
    local lines = { "|cffffd966Detected Specialization|r" }
    local specName = ShadowDots_GetCurrentSpecName and ShadowDots_GetCurrentSpecName() or nil
    lines[#lines + 1] = specName or "Unknown"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "|cffffd966Active Debuffs|r"

    if not ShadowDotsDB.enabled then
        lines[#lines + 1] = "Disabled"
        return table.concat(lines, "\n")
    end

    local configured = false
    local active = {}
    for _, dot in pairs(ShadowDotsDB.dots or {}) do
        if type(dot) == "table" and dot.enabled
        and ShadowDots_IsDotAllowedForCurrentSpec(dot) then
            configured = true
        end
    end
    for _, mob in pairs(ShadowDots.mobs or {}) do
        if mob.plate and mob.unit then
            for spellID, activeDot in pairs(mob.activeDots or {}) do
                local dot = activeDot.dot
                if dot and dot.enabled and ShadowDots_IsDotAllowedForCurrentSpec(dot) then
                    configured = true
                    active[spellID] = dot
                end
            end
        end
    end

    local names = {}
    for _, dot in pairs(active) do
        names[#names + 1] = dot.displayName or tostring(dot.spellID)
    end
    table.sort(names)
    if #names > 0 then
        for _, name in ipairs(names) do
            lines[#lines + 1] = name
        end
    elseif configured then
        lines[#lines + 1] = "None"
    else
        lines[#lines + 1] = "None configured for this specialization"
    end
    return table.concat(lines, "\n")
end

function ShadowDots_NotifyStatusChanged()
    local registry = LibStub("AceConfigRegistry-3.0-ElvUI", true)
    if registry then
        registry:NotifyChange("ElvUI")
    end
end

local function Resolve(spellID)
    local name, icon = ShadowDots_GetSpellMetadata(spellID)
    if type(icon) == "number" then
        icon = tostring(icon)
    elseif type(icon) ~= "string" then
        icon = nil
    end
    return name, icon
end

local function GetPlayerSpecValues()
    local values = {}
    local _, _, classID = UnitClass("player")
    if classID and GetNumSpecializationsForClassID and GetSpecializationInfoForClassID then
        for index = 1, GetNumSpecializationsForClassID(classID) do
            local specID, specName = GetSpecializationInfoForClassID(classID, index)
            if specID and specName then
                values[specID] = specName
            end
        end
    end
    if not next(values) then
        values = ShadowDots_GetSpecValues()
    end
    return values
end

local function FormatInteger(value)
    local text = tostring(math.floor(tonumber(value) or 0))
    while true do
        local formatted = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if formatted == text then
            return text
        end
        text = formatted
    end
end

local function AddDot(spellID)
    spellID = ExtractSpellID(spellID) or tonumber(spellID)
    if not spellID or not Resolve(spellID) then
        addStatus = "|cffff2020Invalid or unavailable spell ID.|r"
        Refresh()
        return
    end
    if ShadowDotsDB.dots[spellID] then
        addStatus = "|cffffd966That spell ID is already configured.|r"
        Refresh()
        return
    end
    local name = Resolve(spellID)
    ShadowDotsDB.dots[spellID] = {
        enabled = true, spellID = spellID, displayName = name,
        color = { r = 1, g = 1, b = 1 },
        blinkEnabled = true, blinkThreshold = 3,
        scaleEnabled = true, scaleHP = 2000000, scaleMultiplier = 1.15,
        specs = {},
    }
    for specID in pairs(ShadowDots_GetSpecValues()) do
        ShadowDotsDB.dots[spellID].specs[specID] = true
    end
    ShadowDots_EnsureSpecs(ShadowDotsDB.dots[spellID])
    addStatus = "|cff20ff20DoT added.|r"
    if dotListArgs then
        for key in pairs(dotListArgs) do
            if tostring(key):match("^dot%d+$") then
                dotListArgs[key] = nil
            end
        end
        BuildDotRows(dotListArgs)
    end
    Refresh()
end

local function RemoveDot(spellID)
    local dots = ShadowDotsDB.dots
    local key = spellID
    if dots[key] == nil then
        for candidate in pairs(dots) do
            if tonumber(candidate) == spellID then
                key = candidate
                break
            end
        end
    end
    dots[key] = nil

    for _, mob in pairs(ShadowDots.mobs) do
        if mob.activeDots and mob.activeDots[spellID] then
            if mob.unit and UnitExists(mob.unit) and ShadowDots_ScanMob then
                ShadowDots_ScanMob(mob)
            else
                mob.activeDots[spellID] = nil
                mob.state = ShadowDots_GetState and ShadowDots_GetState(mob) or "NONE"
                mob.hasDots = next(mob.activeDots) ~= nil
                if not mob.hasDots and ShadowDots_RestoreNameplate then
                    ShadowDots_RestoreNameplate(mob)
                end
            end
        end
    end
    if ShadowDots_UpdatePriority then
        ShadowDots_UpdatePriority()
    end

    if dotListArgs then
        for optionKey in pairs(dotListArgs) do
            if tostring(optionKey):match("^dot%d+$") then
                dotListArgs[optionKey] = nil
            end
        end
        BuildDotRows(dotListArgs)
    end
    Refresh()
end

local function DotRow(spellID, dot, order)
    local name, icon = Resolve(spellID)
    local specs = ShadowDots_EnsureSpecs(dot)
    local row = {
        type = "group",
        name = (dot.displayName or name or "Invalid spell").." ("..tostring(spellID)..")",
        order = order,
        inline = true,
        args = {},
    }
    row.args.enabled = {
        type = "toggle", name = "Enable", desc = "Enable or disable tracking for this DoT.",
        order = 1, width = "half",
        disabled = FeatureDisabled,
        get = function() return dot.enabled end,
        set = function(_, value) dot.enabled = value; Refresh() end,
    }
    row.args.icon = {
        type = "description", name = "", order = 2, width = "half",
        image = function() return icon end, imageWidth = 20, imageHeight = 20,
    }
    row.args.displayName = {
        type = "input", name = "Name / Spell ID",
        desc = "Display name only. Changing this does not change the spell ID used for detection.",
        order = 3, width = "double",
        disabled = FeatureDisabled,
        get = function() return dot.displayName end,
        set = function(_, value) dot.displayName = value; Refresh() end,
    }
    row.args.color = {
        type = "color", name = "Color",
        desc = "The nameplate color used while this DoT is active.",
        order = 4, width = "half",
        disabled = ColorDisabled,
        get = function() return dot.color.r, dot.color.g, dot.color.b end,
        set = function(_, r, g, b) dot.color = { r = r, g = g, b = b }; Refresh() end,
    }
    row.args.blink = {
        type = "toggle", name = "Blink",
        desc = "Enable expiration blinking for this DoT.",
        order = 5, width = "half",
        disabled = BlinkDisabled,
        get = function() return dot.blinkEnabled end,
        set = function(_, value) dot.blinkEnabled = value end,
    }
    row.args.threshold = {
        type = "range", name = "Blink Threshold", min = 0.5, max = 20, step = 0.5,
        desc = "Begin blinking when the DoT has this many seconds remaining.",
        order = 6, width = "half",
        disabled = BlinkDisabled,
        get = function() return dot.blinkThreshold end,
        set = function(_, value) dot.blinkThreshold = value end,
    }
    row.args.scaleHP = {
        type = "input", name = "Scale HP (millions)",
        desc = function()
            return "HP threshold in millions. "..tostring((tonumber(dot.scaleHP) or 0) / 1000000)..
                " means "..FormatInteger(dot.scaleHP).." HP."
        end,
        order = 7, width = "half",
        disabled = ScaleDisabled,
        get = function() return tostring((tonumber(dot.scaleHP) or 0) / 1000000) end,
        set = function(_, value)
            local millions = tonumber(value)
            if millions and millions >= 0 then
                dot.scaleHP = millions * 1000000
                Refresh()
            end
        end,
    }
    row.args.scaleEnabled = {
        type = "toggle", name = "Scale", order = 8, width = "half",
        desc = "Enable this DoT as a source of nameplate scaling.",
        disabled = ScaleDisabled,
        get = function() return dot.scaleEnabled end,
        set = function(_, value) dot.scaleEnabled = value; Refresh() end,
    }
    row.args.scaleMultiplier = {
        type = "range", name = "Scale Multiplier", min = 1, max = 3, step = 0.05,
        order = 9, width = "half",
        desc = "Nameplate scale multiplier when this DoT is eligible for scaling.",
        disabled = ScaleDisabled,
        get = function() return dot.scaleMultiplier end,
        set = function(_, value) dot.scaleMultiplier = value; Refresh() end,
    }
    row.args.specs = {
        type = "multiselect", name = "Specs", order = 10, width = "half",
        desc = "Only the selected specializations can use this DoT for ShadowDots features.",
        disabled = FeatureDisabled,
        values = GetPlayerSpecValues(),
        get = function(_, key) return specs[key] end,
        set = function(_, key, value)
            specs[key] = value
            if ShadowDots_ScanNameplates then
                ShadowDots_ScanNameplates()
            end
            Refresh()
        end,
    }
    row.args.spellID = {
        type = "description",
        name = "Spell ID: "..tostring(spellID)..(name and "" or " |cffff2020Invalid spell|r"),
        order = 12, width = "half",
    }
    row.args.remove = {
        type = "execute", name = "Remove", order = 13, width = "half",
        desc = "Remove this configured DoT.",
        func = function() RemoveDot(spellID) end,
    }
    return row
end

BuildDotRows = function(args)
    local ids = {}
    if type(ShadowDotsDB) ~= "table" then
        ShadowDotsDB = {}
    end
    if type(ShadowDotsDB.dots) ~= "table" then
        ShadowDotsDB.dots = {}
    end
    local dots = ShadowDotsDB.dots
    for spellID in pairs(dots) do
        ids[#ids + 1] = tonumber(spellID)
    end
    table.sort(ids)
    for index, spellID in ipairs(ids) do
        args["dot"..spellID] = DotRow(spellID, dots[spellID], index)
    end
end

local function RegisterOptions()
    if type(ShadowDotsDB) ~= "table" then
        ShadowDotsDB = {}
    end
    if type(ShadowDotsDB.dots) ~= "table" then
        ShadowDotsDB.dots = {}
    end
    local ACR = LibStub("AceConfigRegistry-3.0-ElvUI", true)
    if not E or not E.Options or not ACR then
        return
    end
    local dots = {
        type = "group", name = "Debuffs", order = 2,
        childGroups = "tree", args = {
            multiDotColor = {
                type = "color", name = "Multi-Dot Color", order = 1000, width = "half",
                desc = "Color used when two or more configured player-owned DoTs are active on the same enemy.",
                disabled = ColorDisabled,
                get = function()
                    local color = ShadowDots_GetMultiDotColor()
                    return color.r, color.g, color.b
                end,
                set = function(_, r, g, b)
                    ShadowDotsDB.multiDotColor = { r = r, g = g, b = b }
                    Refresh()
                end,
            },
            addID = {
                type = "input", name = "Add Debuff ID", order = 1001, width = "double",
                desc = "Add a tracked debuff by entering its spell ID or Shift-clicking a spell link.",
                get = function() return pendingSpellID or "" end,
                set = function(_, value) pendingSpellID = value end,
            },
            add = {
                type = "execute", name = "Add Debuff", order = 1002,
                desc = "Add a tracked debuff using the ID in the field.",
                func = function() AddDot(pendingSpellID); pendingSpellID = nil end,
            },
            status = {
                type = "description", order = 1003, width = "full",
                name = function() return addStatus end,
            },
            combatScaleEnabled = {
                type = "toggle", name = "Combat Scaling", order = 1004, width = "half",
                desc = "Scale nameplates of enemies you are actively engaged with during combat.",
                disabled = ScaleDisabled,
                get = function() return ShadowDotsDB.combatScaleEnabled end,
                set = function(_, value) ShadowDotsDB.combatScaleEnabled = value; Refresh() end,
            },
            combatScale = {
                type = "range", name = "Combat Enemy Scale", min = 1, max = 3, step = 0.05,
                order = 1005, width = "half",
                desc = "Multiplier applied to enemies engaged with you in combat.",
                disabled = ScaleDisabled,
                get = function() return ShadowDotsDB.combatScale end,
                set = function(_, value) ShadowDotsDB.combatScale = value; Refresh() end,
            },
        },
    }
    dotListArgs = dots.args
    BuildDotRows(dots.args)

    local options = {
        type = "group", name = "ShadowDots", order = 20, childGroups = "tab",
        args = {
            general = {
                type = "group", name = "General", order = 1,
                args = {
                    status = {
                        type = "description", name = GetGeneralStatus, order = 1,
                        width = "full", fontSize = "medium",
                    },
                    enabled = {
                        type = "toggle", name = "Enable ShadowDots", order = 2, width = "half",
                        desc = "Enable or disable all ShadowDots functionality.",
                        get = function() return ShadowDotsDB.enabled end,
                        set = function(_, value)
                            ShadowDotsDB.enabled = value
                            ShadowDots_CheckEnabled()
                            Refresh()
                        end,
                    },
                    enableColor = {
                        type = "toggle", name = "Enable Debuff Coloring", order = 3, width = "half",
                        desc = "Allow ShadowDots to color HealthBars for active configured debuffs.",
                        get = function() return ShadowDotsDB.enableColor end,
                        set = function(_, value) ShadowDotsDB.enableColor = value; Refresh() end,
                    },
                    enableScale = {
                        type = "toggle", name = "Enable HP Scaling", order = 4, width = "half",
                        desc = "Enable ShadowDots health-based nameplate scaling.",
                        get = function() return ShadowDotsDB.enableScale end,
                        set = function(_, value) ShadowDotsDB.enableScale = value; Refresh() end,
                    },
                    enableBlink = {
                        type = "toggle", name = "Enable Blinking", order = 5, width = "half",
                        desc = "Allow configured debuffs to blink when they are close to expiring.",
                        get = function() return ShadowDotsDB.enableBlink end,
                        set = function(_, value)
                            ShadowDotsDB.enableBlink = value
                            if value then
                                if ShadowDots.enabled and ShadowDots_StartBlinking then
                                    ShadowDots_StartBlinking()
                                end
                            elseif ShadowDots_StopBlinking then
                                ShadowDots_StopBlinking()
                            end
                            Refresh()
                        end,
                    },
                },
            },
            dots = dots,
            about = {
                type = "group", name = "About", order = 3,
                args = {
                    title = { type = "header", name = "|cffb366ffElvUI ShadowDots|r", order = 1 },
                    text = { type = "description", name = "|cffd8c8e8Universal Debuff Nameplate System|r\n|cff999999Legion 7.2.5 / WoWZone|r\n\n|cffffd966Created by|r\n|cffffffffHexman (Narco)|r", order = 2, fontSize = "large" },
                    debug = {
                        type = "toggle", name = "Enable Debug Logging", order = 3,
                        desc = "Print ShadowDots diagnostic messages.",
                        get = function() return ShadowDotsDB.debug end,
                        set = function(_, value)
                            ShadowDotsDB.debug = value
                            if not value or not ShadowDotsDB.watchdog then
                                ShadowDots_StopWatchdog()
                            elseif ShadowDots.enabled then
                                ShadowDots_StartWatchdog()
                            end
                        end,
                    },
                    watchdog = {
                        type = "toggle", name = "Watchdog", order = 4,
                        desc = "Enable the existing debug-only visual state watchdog.",
                        get = function() return ShadowDotsDB.watchdog end,
                        set = function(_, value)
                            ShadowDotsDB.watchdog = value
                            if value and ShadowDotsDB.debug and ShadowDots.enabled then
                                ShadowDots_StartWatchdog()
                            else
                                ShadowDots_StopWatchdog()
                            end
                        end,
                    },
                    scriptErrors = {
                        type = "toggle", name = "Show Lua Errors", order = 5,
                        desc = "Show Lua script errors when addon code encounters an error.",
                        get = function() return GetCVarBool("scriptErrors") end,
                        set = function(_, value) SetCVar("scriptErrors", value and 1 or 0) end,
                    },
                },
            },
        },
    }

    local nameplateOptions = E.Options.args.nameplate
    if nameplateOptions and nameplateOptions.args then
        nameplateOptions.args.shadowdots = options
        options.order = 90
        ShadowDots.configPath = { "nameplate", "shadowdots" }
    else
        E.Options.args.shadowdots = options
        ShadowDots.configPath = { "shadowdots" }
    end
    ACR:NotifyChange("ElvUI")
end

if plugin then
    plugin:RegisterPlugin("ElvUI_ShadowDots", RegisterOptions)
end

SLASH_SHADOWDOTS1 = "/sd"
SlashCmdList.SHADOWDOTS = function()
    local ACD = LibStub("AceConfigDialog-3.0-ElvUI", true)
    if ACD and ShadowDots.configPath then
        ACD:Open("ElvUI")
        ACD:SelectGroup("ElvUI", unpack(ShadowDots.configPath))
    end
end
