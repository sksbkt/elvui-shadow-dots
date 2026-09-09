local E = unpack(ElvUI)
local plugin = LibStub("LibElvUIPlugin-1.0", true)
local pendingSpellID
local dotListArgs
local BuildDotRows
local addStatus = ""

local function Refresh()
    if ShadowDots_RefreshVisuals then
        ShadowDots_RefreshVisuals()
    end
    local registry = LibStub("AceConfigRegistry-3.0-ElvUI", true)
    if registry then
        registry:NotifyChange("ElvUI")
    end
end

local function Resolve(spellID)
    local name, icon = ShadowDots_GetSpellMetadata(spellID)
    return name, icon
end

local function FormatHP(value)
    value = tonumber(value) or 0
    if value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    end
    return tostring(value)
end

local function AddDot(spellID)
    spellID = tonumber(spellID)
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
        color = { r = 1, g = 1, b = 1 }, blendColor = false,
        blinkEnabled = true, blinkThreshold = 3, blinkSpeed = 0.25,
        scaleHP = 2000000,
    }
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

local function DotRow(spellID, dot, order)
    local name, icon = Resolve(spellID)
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
        get = function() return dot.enabled end,
        set = function(_, value) dot.enabled = value; Refresh() end,
    }
    row.args.icon = {
        type = "description", name = "", order = 2, width = "half",
        image = icon, imageWidth = 20, imageHeight = 20,
    }
    row.args.displayName = {
        type = "input", name = "Name / Spell ID",
        desc = "Display name only. Changing this does not change the spell ID used for detection.",
        order = 3, width = "double",
        get = function() return dot.displayName end,
        set = function(_, value) dot.displayName = value; Refresh() end,
    }
    row.args.color = {
        type = "color", name = "Color",
        desc = "The nameplate color used while this DoT is active.",
        order = 4, width = "half",
        get = function() return dot.color.r, dot.color.g, dot.color.b end,
        set = function(_, r, g, b) dot.color = { r = r, g = g, b = b }; Refresh() end,
    }
    row.args.blend = {
        type = "toggle", name = "Blend",
        desc = "Blend the configured DoT color with ElvUI's native nameplate color.",
        order = 5, width = "half",
        get = function() return dot.blendColor end,
        set = function(_, value) dot.blendColor = value; Refresh() end,
    }
    row.args.blink = {
        type = "toggle", name = "Blink",
        desc = "Enable expiration blinking for this DoT.",
        order = 6, width = "half",
        get = function() return dot.blinkEnabled end,
        set = function(_, value) dot.blinkEnabled = value end,
    }
    row.args.threshold = {
        type = "range", name = "Blink Threshold", min = 0.5, max = 20, step = 0.5,
        desc = "Begin blinking when the DoT has this many seconds remaining.",
        order = 7, width = "half",
        get = function() return dot.blinkThreshold end,
        set = function(_, value) dot.blinkThreshold = value end,
    }
    row.args.speed = {
        type = "range", name = "Blink Speed", min = 0.05, max = 2, step = 0.05,
        desc = "Controls how quickly the nameplate blinks.",
        order = 8, width = "half",
        get = function() return dot.blinkSpeed end,
        set = function(_, value) dot.blinkSpeed = value end,
    }
    row.args.scaleHP = {
        type = "input", name = "Scale HP",
        desc = "The target's minimum current HP required for this DoT to trigger nameplate scaling.",
        order = 9, width = "half",
        get = function() return tostring(dot.scaleHP) end,
        set = function(_, value) dot.scaleHP = math.max(0, tonumber(value) or dot.scaleHP) end,
    }
    row.args.scaleHPDisplay = {
        type = "description", name = function() return "Current: "..FormatHP(dot.scaleHP) end,
        order = 9.5, width = "half",
    }
    row.args.spellID = {
        type = "description",
        name = "Spell ID: "..tostring(spellID)..(name and "" or " |cffff2020Invalid spell|r"),
        order = 10, width = "full",
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
        args["dot"..spellID] = DotRow(spellID, dots[spellID], 20 + index)
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
        type = "group", name = "Universal DoTs", order = 2,
        childGroups = "tree", args = {
            intro = {
                type = "description", order = 1, width = "full",
                name = "Player-owned DoTs are identified by spell ID and UnitDebuff(). Multiple active DoTs use the average of their configured colors; Blend averages that result with ElvUI's native color.",
            },
            columns = {
                type = "description", order = 1.5, width = "full",
                name = "|cffbbbbbbEnable   Icon   Name / ID   Color   Blend   Blink   Threshold   Speed   Scale HP|r",
            },
            addID = {
                type = "input", name = "Add DoT Spell ID", order = 2, width = "double",
                desc = "Add a DoT by entering its spell ID.",
                get = function() return pendingSpellID or "" end,
                set = function(_, value) pendingSpellID = value end,
            },
            add = {
                type = "execute", name = "Add DoT", order = 3,
                desc = "Add a DoT by entering its spell ID.",
                func = function() AddDot(pendingSpellID); pendingSpellID = nil end,
            },
            status = {
                type = "description", order = 4, width = "full",
                name = function() return addStatus end,
            },
        },
    }
    dotListArgs = dots.args
    BuildDotRows(dots.args)

    local options = {
        type = "group", name = "ShadowDots", order = 20, childGroups = "tab",
        args = {
            about = {
                type = "group", name = "About / Welcome", order = 1,
                args = {
                    title = { type = "header", name = "|cffb366ffElvUI ShadowDots|r", order = 1 },
                    text = { type = "description", name = "|cffd8c8e8Universal DoT Nameplate System|r\n|cff999999Legion 7.2.5 / WoWZone|r\n\n|cffffd966Created by|r\n|cffffffffHexman (Narco)|r\n\nDesigned and developed for WoWZone 7.2.5.", order = 2, fontSize = "large" },
                },
            },
            general = {
                type = "group", name = "General", order = 2,
                args = {
                    enabled = {
                        type = "toggle", name = "Enable ShadowDots", order = 1,
                        get = function() return ShadowDotsDB.enabled end,
                        set = function(_, value) ShadowDotsDB.enabled = value; ShadowDots_CheckEnabled() end,
                    },
                    blinkAlpha = {
                        type = "range", name = "Blink Alpha", min = 0.05, max = 1, step = 0.05, order = 2,
                        get = function() return ShadowDotsDB.blinkAlpha end,
                        set = function(_, value) ShadowDotsDB.blinkAlpha = value end,
                    },
                },
            },
            dots = dots,
            priority = {
                type = "group", name = "Priority / Tracker", order = 4,
                args = {
                    enableScale = { type = "toggle", name = "Enable HP Scaling", order = 1, get = function() return ShadowDotsDB.enableScale end, set = function(_, v) ShadowDotsDB.enableScale = v; Refresh() end },
                    scaleSize = { type = "range", name = "Scale Size", min = 1, max = 2, step = 0.05, order = 2, get = function() return ShadowDotsDB.scaleSize end, set = function(_, v) ShadowDotsDB.scaleSize = v; Refresh() end },
                },
            },
            debug = {
                type = "group", name = "Debug", order = 5,
                args = {
                    enabled = { type = "toggle", name = "Enable Debug Messages", order = 1, get = function() return ShadowDotsDB.debug end, set = function(_, value) ShadowDotsDB.debug = value; if value then ShadowDots_StartWatchdog() else ShadowDots_StopWatchdog() end end },
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
