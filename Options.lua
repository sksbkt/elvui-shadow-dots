local E = unpack(ElvUI)
local plugin = LibStub("LibElvUIPlugin-1.0", true)

local function Refresh()
    if ShadowDots_RefreshVisuals then
        ShadowDots_RefreshVisuals()
    end
end

local function SetEnabled(value)
    ShadowDotsDB.enabled = value
    ShadowDots_CheckSpec()
end

local function SetColor(key, r, g, b)
    ShadowDotsDB[key] = { r = r, g = g, b = b }
    Refresh()
end

local function RegisterOptions()
    local ACR = LibStub("AceConfigRegistry-3.0-ElvUI", true)
    if not E or not E.Options or not ACR then
        return
    end

    local shadowdotsOptions = {
        type = "group",
        name = "ShadowDots",
        order = 20,
        childGroups = "tab",
        args = {
            about = {
                type = "group",
                name = "About / Welcome",
                order = 1,
                args = {
                    title = {
                        type = "header",
                        name = "|cffb366ffElvUI ShadowDots|r",
                        order = 1,
                    },
                    subtitle = {
                        type = "description",
                        name = "|cffd8c8e8Shadow Priest Nameplate & DoT System|r\n|cff999999Legion 7.2.5 / WoWZone|r",
                        order = 2,
                    },
                    spacer = {
                        type = "description",
                        name = " ",
                        order = 3,
                    },
                    creator = {
                        type = "description",
                        name = "|cffffd966Created by|r\n|cffffffffHexman (Narco)|r",
                        order = 4,
                        fontSize = "large",
                    },
                    description = {
                        type = "description",
                        name = "\nDesigned and developed for WoWZone 7.2.5.",
                        order = 5,
                    },
                },
            },
            general = {
                type = "group",
                name = "General",
                order = 2,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable ShadowDots",
                        order = 1,
                        get = function() return ShadowDotsDB.enabled end,
                        set = function(_, value) SetEnabled(value) end,
                    },
                    status = {
                        type = "description",
                        name = function()
                            if ShadowDots_IsShadowPriest() then
                                return "|cff20ff20Shadow specialization detected: Enabled|r"
                            end
                            return "|cffff2020Shadow specialization not detected: Inactive|r"
                        end,
                        order = 2,
                    },
                },
            },
            colors = {
                type = "group",
                name = "DoT Colors",
                order = 3,
                args = {
                    swp = {
                        type = "color",
                        name = "Shadow Word: Pain Only",
                        order = 1,
                        get = function()
                            local c = ShadowDotsDB.swpColor
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b) SetColor("swpColor", r, g, b) end,
                    },
                    vt = {
                        type = "color",
                        name = "Vampiric Touch Only",
                        order = 2,
                        get = function()
                            local c = ShadowDotsDB.vtColor
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b) SetColor("vtColor", r, g, b) end,
                    },
                    both = {
                        type = "color",
                        name = "Both SW:P + VT",
                        order = 3,
                        get = function()
                            local c = ShadowDotsDB.bothColor
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b) SetColor("bothColor", r, g, b) end,
                    },
                },
            },
            expiration = {
                type = "group",
                name = "Expiration / Blinking",
                order = 4,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable Blinking",
                        order = 1,
                        get = function() return ShadowDotsDB.blinkEnabled end,
                        set = function(_, value)
                            ShadowDotsDB.blinkEnabled = value
                            if value and ShadowDots.enabled then
                                ShadowDots_StartBlinking()
                            elseif not value then
                                ShadowDots_StopBlinking()
                            end
                        end,
                    },
                    threshold = {
                        type = "range",
                        name = "Expiration Threshold",
                        min = 0.5,
                        max = 10,
                        step = 0.5,
                        order = 2,
                        get = function() return ShadowDotsDB.blinkThreshold end,
                        set = function(_, value) ShadowDotsDB.blinkThreshold = value end,
                    },
                    speed = {
                        type = "range",
                        name = "Blink Speed",
                        min = 0.05,
                        max = 1,
                        step = 0.05,
                        order = 3,
                        get = function() return ShadowDotsDB.blinkSpeed end,
                        set = function(_, value) ShadowDotsDB.blinkSpeed = value end,
                    },
                    swp = {
                        type = "toggle",
                        name = "Blink SW:P",
                        order = 4,
                        get = function() return ShadowDotsDB.blinkSWP end,
                        set = function(_, value) ShadowDotsDB.blinkSWP = value end,
                    },
                    vt = {
                        type = "toggle",
                        name = "Blink VT",
                        order = 5,
                        get = function() return ShadowDotsDB.blinkVT end,
                        set = function(_, value) ShadowDotsDB.blinkVT = value end,
                    },
                    alpha = {
                        type = "range",
                        name = "Blink Alpha",
                        min = 0.05,
                        max = 1,
                        step = 0.05,
                        order = 6,
                        get = function() return ShadowDotsDB.blinkAlpha end,
                        set = function(_, value) ShadowDotsDB.blinkAlpha = value end,
                    },
                },
            },
            priority = {
                type = "group",
                name = "Priority / Tracker",
                order = 5,
                args = {
                    enableScale = {
                        type = "toggle",
                        name = "Enable Priority Scale",
                        order = 1,
                        get = function() return ShadowDotsDB.enableScale end,
                        set = function(_, value)
                            ShadowDotsDB.enableScale = value
                            Refresh()
                        end,
                    },
                    scaleSize = {
                        type = "range",
                        name = "Priority Scale",
                        min = 1,
                        max = 2,
                        step = 0.05,
                        order = 2,
                        get = function() return ShadowDotsDB.scaleSize end,
                        set = function(_, value)
                            ShadowDotsDB.scaleSize = value
                            Refresh()
                        end,
                    },
                },
            },
            debug = {
                type = "group",
                name = "Debug",
                order = 6,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable Debug Messages",
                        order = 1,
                        get = function() return ShadowDotsDB.debug end,
                        set = function(_, value)
                            ShadowDotsDB.debug = value
                            if value and ShadowDots_StartWatchdog then
                                ShadowDots_StartWatchdog()
                            elseif not value and ShadowDots_StopWatchdog then
                                ShadowDots_StopWatchdog()
                            end
                        end,
                    },
                },
            },
        },
    }

    local nameplateOptions = E.Options.args.nameplate
    if nameplateOptions and nameplateOptions.args then
        nameplateOptions.args.shadowdots = shadowdotsOptions
        shadowdotsOptions.order = 90
        ShadowDots.configPath = {"nameplate", "shadowdots"}
    else
        E.Options.args.shadowdots = shadowdotsOptions
        ShadowDots.configPath = {"shadowdots"}
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
