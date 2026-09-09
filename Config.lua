local defaults = {
    enabled = true,
    debug = false,
    enableScale = true,
    scaleSize = 1.15,
    blinkAlpha = 0.35,
    dots = {
        [589] = {
            enabled = true, spellID = 589, displayName = "Shadow Word: Pain",
            color = { r = 1, g = 1, b = 0 }, blendColor = false,
            blinkEnabled = true, blinkThreshold = 3, blinkSpeed = 0.25,
            scaleHP = 2000000,
        },
        [34914] = {
            enabled = true, spellID = 34914, displayName = "Vampiric Touch",
            color = { r = 0.6, g = 0, b = 1 }, blendColor = false,
            blinkEnabled = true, blinkThreshold = 3, blinkSpeed = 0.25,
            scaleHP = 2000000,
        },
    },
}

ShadowDotsDB = ShadowDotsDB or {}

for key, value in pairs(defaults) do
    if ShadowDotsDB[key] == nil and key ~= "dots" then
        ShadowDotsDB[key] = value
    end
end

if type(ShadowDotsDB.dots) ~= "table" then
    ShadowDotsDB.dots = {}
end

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
    if not existing and ShadowDotsDB.blinkSpeed then
        dot.blinkSpeed = ShadowDotsDB.blinkSpeed
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
        dot.blendColor = dot.blendColor == true
        dot.blinkEnabled = dot.blinkEnabled ~= false
        dot.blinkThreshold = tonumber(dot.blinkThreshold) or 3
        dot.blinkSpeed = tonumber(dot.blinkSpeed) or 0.25
        dot.scaleHP = tonumber(dot.scaleHP) or 2000000
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
