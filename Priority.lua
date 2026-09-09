local function GetHealthBar(mob)
    if not mob.plate or not mob.plate.UnitFrame then
        return nil
    end
    return mob.plate.UnitFrame.HealthBar
end

local function GetElvUI()
    if not _G.ElvUI then
        return nil
    end
    return unpack(_G.ElvUI)
end

local function RecalculateNativeColor(mob)
    local frame = mob.plate and mob.plate.UnitFrame
    local health = GetHealthBar(mob)
    local E = GetElvUI()
    if not frame or not health or not E then
        return 1, 1, 1
    end
    local nameplates = E:GetModule("NamePlates", true)
    if not nameplates or not nameplates.UpdateElement_HealthColor then
        return health:GetStatusBarColor()
    end
    health.r, health.g, health.b = nil, nil, nil
    nameplates:UpdateElement_HealthColor(frame)
    return health:GetStatusBarColor()
end

local function RestoreElvUIColor(mob)
    local health = GetHealthBar(mob)
    if not health then
        return
    end
    RecalculateNativeColor(mob)
end

function ShadowDots_RestoreNameplate(mob, force)
    if not force and not mob.colorOwned then
        return
    end
    ShadowDots_Debug("release", GetTime(), mob.unit, mob.guid,
        "state", mob.state, "owned", mob.colorOwned, "forced", force and true or false)
    RestoreElvUIColor(mob)
    mob.colorOwned = false
    mob.colorState = nil
end

local function BuildDoTColor(mob)
    local count = 0
    local shouldBlend = false
    local r, g, b = 0, 0, 0
    for _, active in pairs(mob.activeDots or {}) do
        count = count + 1
        r = r + active.dot.color.r
        g = g + active.dot.color.g
        b = b + active.dot.color.b
        shouldBlend = shouldBlend or active.dot.blendColor
    end
    if count == 0 then
        return nil
    end
    r, g, b = r / count, g / count, b / count
    if shouldBlend then
        local nr, ng, nb = RecalculateNativeColor(mob)
        r, g, b = (r + nr) / 2, (g + ng) / 2, (b + nb) / 2
    end
    return r, g, b
end

function ShadowDots_ApplyNameplateColor(mob)
    if not ShadowDots.enabled then
        return
    end
    local health = GetHealthBar(mob)
    if not health then
        return
    end
    local r, g, b = BuildDoTColor(mob)
    if not r then
        ShadowDots_RestoreNameplate(mob)
        return
    end
    health:SetStatusBarColor(r, g, b)
    mob.colorOwned = true
    mob.colorState = mob.state
    ShadowDots_Debug("apply", GetTime(), mob.unit, mob.guid,
        "state", mob.state, "rgb", r, g, b)
end

local function UpdateScale()
    if not ShadowDots.enabled then
        return
    end
    for _, mob in pairs(ShadowDots.mobs) do
        if mob.plate and mob.plate.UnitFrame then
            mob.plate.UnitFrame:SetScale(1)
        end
    end
    if not ShadowDotsDB.enableScale then
        return
    end

    for _, mob in pairs(ShadowDots.mobs) do
        if mob.plate and mob.unit and UnitExists(mob.unit) and mob.hasDots then
            local hp = UnitHealth(mob.unit)
            for _, active in pairs(mob.activeDots) do
                if active.dot.scaleHP and hp >= active.dot.scaleHP
                then
                    mob.scaleThreshold = math.max(mob.scaleThreshold or 0, active.dot.scaleHP)
                end
            end
        end
    end
    for _, mob in pairs(ShadowDots.mobs) do
        if mob.scaleThreshold and mob.plate and mob.plate.UnitFrame then
            mob.plate.UnitFrame:SetScale(ShadowDotsDB.scaleSize)
        end
        mob.scaleThreshold = nil
    end
end

function ShadowDots_UpdatePriority()
    UpdateScale()
end

function ShadowDots_RefreshVisuals()
    if not ShadowDots.enabled then
        return
    end
    for _, mob in pairs(ShadowDots.mobs) do
        if mob.state ~= "NONE" then
            mob.colorState = nil
        end
        ShadowDots_ApplyNameplateColor(mob)
    end
    UpdateScale()
end
