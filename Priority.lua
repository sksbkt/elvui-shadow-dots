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

local nativeColorHooked
local restoringNativeColor

local function ProtectOwnedHealthColor(frame)
    if restoringNativeColor or not ShadowDotsDB.enableColor then
        return
    end
    for _, mob in pairs(ShadowDots.mobs) do
        if mob.colorOwned and mob.plate and mob.plate.UnitFrame == frame then
            ShadowDots_ApplyNameplateColor(mob)
            return
        end
    end
end

local function HookNativeHealthColor()
    if nativeColorHooked or not hooksecurefunc then
        return
    end
    local E = GetElvUI()
    local nameplates = E and E:GetModule("NamePlates", true)
    if not nameplates or not nameplates.UpdateElement_HealthColor then
        return
    end
    hooksecurefunc(nameplates, "UpdateElement_HealthColor", ProtectOwnedHealthColor)
    nativeColorHooked = true
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
    restoringNativeColor = true
    RestoreElvUIColor(mob)
    restoringNativeColor = nil
    mob.colorOwned = false
    mob.colorState = nil
end

local function BuildDoTColor(mob)
    local count = 0
    local singleColor
    for _, active in pairs(mob.activeDots or {}) do
        if ShadowDots_IsDotAllowedForCurrentSpec(active.dot) then
            count = count + 1
            singleColor = active.dot.color
        end
    end
    if count == 0 then
        return nil
    elseif count == 1 then
        return singleColor.r, singleColor.g, singleColor.b
    end
    local color = ShadowDots_GetMultiDotColor()
    return color.r, color.g, color.b
end

function ShadowDots_ApplyNameplateColor(mob)
    if not ShadowDots.enabled or not ShadowDotsDB.enableColor then
        if mob.colorOwned then
            ShadowDots_RestoreNameplate(mob, true)
        end
        return
    end
    HookNativeHealthColor()
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

local function GetDotScale(mob)
    if not ShadowDotsDB.enableScale or not mob.combatEngaged
    or not mob.unit or not UnitExists(mob.unit) then
        return 1
    end
    local hp = UnitHealth(mob.unit)
    local scale = 1
    local activeDots = mob.activeDots or {}
    for spellID, dot in pairs(ShadowDotsDB.dots or {}) do
        local configuredSpellID = tonumber(spellID) or spellID
        if type(dot) == "table"
        and dot.enabled
        and dot.scaleEnabled
        and not activeDots[configuredSpellID]
        and ShadowDots_IsDotAllowedForCurrentSpec(dot)
        and hp > (dot.scaleHP or 0) then
            scale = math.max(scale, dot.scaleMultiplier or 1)
        end
    end
    return scale
end

local function GetRequiredScale(mob)
    if not ShadowDotsDB.enableScale then
        return 1
    end
    local scale = 1
    if ShadowDotsDB.combatScaleEnabled and mob.combatEngaged then
        scale = math.max(scale, ShadowDotsDB.combatScale or 1)
    end
    return math.max(scale, GetDotScale(mob))
end

function ShadowDots_ReleaseScale(mob)
    local frame = mob.plate and mob.plate.UnitFrame
    if frame and mob.scaleOwned then
        frame:SetScale(mob.nativeScale or 1)
    end
    mob.scaleOwned = false
    mob.nativeScale = nil
end

local function UpdateScale()
    for _, mob in pairs(ShadowDots.mobs) do
        local frame = mob.plate and mob.plate.UnitFrame
        if frame then
            if not ShadowDots.enabled then
                ShadowDots_ReleaseScale(mob)
            else
                local required = GetRequiredScale(mob)
                if required > 1 then
                    if not mob.scaleOwned then
                        mob.nativeScale = frame.GetScale and frame:GetScale() or 1
                        mob.scaleOwned = true
                    end
                    frame:SetScale(math.max(mob.nativeScale or 1, required))
                else
                    ShadowDots_ReleaseScale(mob)
                end
            end
        end
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
        if not ShadowDotsDB.enableColor then
            ShadowDots_RestoreNameplate(mob, true)
        elseif mob.state ~= "NONE" then
            mob.colorState = nil
            ShadowDots_ApplyNameplateColor(mob)
        else
            ShadowDots_ApplyNameplateColor(mob)
        end
    end
    UpdateScale()
end
