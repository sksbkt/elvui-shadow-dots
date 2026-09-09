local defaults = {
    enabled = true,
    debug = false,
    enableScale = true,
    scaleSize = 1.15,
    blinkEnabled = true,
    blinkThreshold = 3,
    blinkSpeed = 0.25,
    blinkSWP = true,
    blinkVT = true,
    blinkAlpha = 0.35,
    swpColor = { r = 1, g = 1, b = 0 },
    vtColor = { r = 0.6, g = 0, b = 1 },
    bothColor = { r = 1, g = 1, b = 1 },
}

ShadowDotsDB = ShadowDotsDB or {}

for key, value in pairs(defaults) do
    if ShadowDotsDB[key] == nil then
        ShadowDotsDB[key] = value
    end
end

for _, key in ipairs({"swpColor", "vtColor", "bothColor"}) do
    local color = ShadowDotsDB[key]
    if not color.r or not color.g or not color.b then
        ShadowDotsDB[key] = defaults[key]
    end
end
