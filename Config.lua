local defaults = {
    enabled = true,
    enableColor = true,
    debug = false,
    watchdog = false,
    enableScale = true,
    enableBlink = true,
    scaleSize = 1.15,
    combatScaleEnabled = true,
    combatScale = 1.20,
    multiDotColor = { r = 1, g = 1, b = 1 },
    dots = {
        [589] = {
            enabled = true, spellID = 589, displayName = "Shadow Word: Pain",
            color = { r = 1, g = 1, b = 0 },
            blinkEnabled = true, blinkThreshold = 3,
            scaleEnabled = true, scaleHP = 2000000, scaleMultiplier = 1.15,
        },
        [34914] = {
            enabled = true, spellID = 34914, displayName = "Vampiric Touch",
            color = { r = 0.6, g = 0, b = 1 },
            blinkEnabled = true, blinkThreshold = 3,
            scaleEnabled = true, scaleHP = 2000000, scaleMultiplier = 1.15,
        },
    },
}

local specValues = {
    [62] = "Arcane", [63] = "Fire", [64] = "Frost",
    [65] = "Holy", [66] = "Protection", [70] = "Retribution",
    [71] = "Arms", [72] = "Fury", [73] = "Protection",
    [102] = "Balance", [103] = "Feral", [104] = "Guardian", [105] = "Restoration",
    [250] = "Blood", [251] = "Frost", [252] = "Unholy",
    [253] = "Beast Mastery", [254] = "Marksmanship", [255] = "Survival",
    [256] = "Discipline", [257] = "Holy", [258] = "Shadow",
    [259] = "Assassination", [260] = "Outlaw", [261] = "Subtlety",
    [262] = "Elemental", [263] = "Enhancement", [264] = "Restoration",
    [265] = "Affliction", [266] = "Demonology", [267] = "Destruction",
    [268] = "Brewmaster", [269] = "Windwalker", [270] = "Mistweaver",
    [577] = "Havoc", [581] = "Vengeance",
}

function ShadowDots_GetSpecValues()
    return specValues
end

local function CopySpecSelection()
    local selection = {}
    for specID in pairs(specValues) do
        selection[specID] = true
    end
    return selection
end

function ShadowDots_EnsureSpecs(dot)
    if type(dot.specs) == "table" then
        return dot.specs
    end
    local specs = {}
    local migrated = false
    for _, legacyKey in ipairs({ "scaleSpecs", "colorSpecs" }) do
        local legacy = dot[legacyKey]
        if type(legacy) == "table" then
            migrated = true
            for specID, enabled in pairs(legacy) do
                if enabled then
                    specs[specID] = true
                end
            end
        end
    end
    dot.specs = migrated and specs or CopySpecSelection()
    return dot.specs
end

function ShadowDots_GetCurrentSpecID()
    if not GetSpecialization or not GetSpecializationInfo then
        return nil
    end
    local index = GetSpecialization()
    if not index then
        return nil
    end
    return GetSpecializationInfo(index)
end

function ShadowDots_GetCurrentSpecName()
    if not GetSpecialization or not GetSpecializationInfo then
        return nil
    end
    local index = GetSpecialization()
    if not index then
        return nil
    end
    local _, name = GetSpecializationInfo(index)
    return name
end

function ShadowDots_IsDotAllowedForCurrentSpec(dot)
    local specID = ShadowDots_GetCurrentSpecID()
    local specs = dot and dot.specs
    return specID and type(specs) == "table" and specs[specID] == true
end

ShadowDotsDB = ShadowDotsDB or {}

for key, value in pairs(defaults) do
    if ShadowDotsDB[key] == nil and key ~= "dots" then
        ShadowDotsDB[key] = value
    end
end

if type(ShadowDotsDB.dots) ~= "table" then
    ShadowDotsDB.dots = {}
end

function ShadowDots_GetMultiDotColor()
    local color = ShadowDotsDB.multiDotColor
    if type(color) ~= "table"
    or type(color.r) ~= "number"
    or type(color.g) ~= "number"
    or type(color.b) ~= "number" then
        color = { r = 1, g = 1, b = 1 }
        ShadowDotsDB.multiDotColor = color
    end
    return color
end

ShadowDots_GetMultiDotColor()

local function CopyDotDefaults(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = { r = value.r, g = value.g, b = value.b }
            else
                target[key] = value
            end
        end
    end
end

-- Migrate the two legacy entries without discarding user colors or blink settings.
local legacy = {
    [589] = { color = ShadowDotsDB.swpColor, blink = ShadowDotsDB.blinkSWP },
    [34914] = { color = ShadowDotsDB.vtColor, blink = ShadowDotsDB.blinkVT },
}
for spellID, source in pairs(defaults.dots) do
    local existing = ShadowDotsDB.dots[spellID]
    local dot = existing or {}
    local hadScaleMultiplier = dot.scaleMultiplier ~= nil
    CopyDotDefaults(dot, source)
    local old = legacy[spellID]
    if not existing and old and old.color then
        dot.color = { r = old.color.r, g = old.color.g, b = old.color.b }
    end
    if not existing and old and old.blink ~= nil then
        dot.blinkEnabled = old.blink
    end
    if not existing and ShadowDotsDB.blinkThreshold then
        dot.blinkThreshold = ShadowDotsDB.blinkThreshold
    end
    if not hadScaleMultiplier and ShadowDotsDB.scaleSize then
        dot.scaleMultiplier = tonumber(ShadowDotsDB.scaleSize) or dot.scaleMultiplier
    end
    ShadowDotsDB.dots[spellID] = dot
end

for spellID, dot in pairs(ShadowDotsDB.dots) do
    if type(dot) ~= "table" then
        ShadowDotsDB.dots[spellID] = nil
    else
        dot.spellID = tonumber(dot.spellID or spellID)
        dot.enabled = dot.enabled ~= false
        dot.displayName = dot.displayName or tostring(dot.spellID)
        dot.color = dot.color or { r = 1, g = 1, b = 1 }
        dot.color.r = tonumber(dot.color.r) or 1
        dot.color.g = tonumber(dot.color.g) or 1
        dot.color.b = tonumber(dot.color.b) or 1
        dot.blinkEnabled = dot.blinkEnabled ~= false
        dot.blinkThreshold = tonumber(dot.blinkThreshold) or 3
        dot.scaleEnabled = dot.scaleEnabled ~= false
        dot.scaleHP = tonumber(dot.scaleHP) or 2000000
        dot.scaleMultiplier = tonumber(dot.scaleMultiplier) or 1.15
        dot.scaleMultiplier = math.max(1, math.min(3, dot.scaleMultiplier))
        ShadowDots_EnsureSpecs(dot)
    end
end

function ShadowDots_GetDot(spellID)
    return ShadowDotsDB.dots[tonumber(spellID)]
end

function ShadowDots_GetSpellMetadata(spellID)
    spellID = tonumber(spellID)
    if not spellID then
        return nil, nil
    end
    local name, _, icon = GetSpellInfo(spellID)
    return name, icon
end
