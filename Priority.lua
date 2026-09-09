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

local function RestoreElvUIColor(mob)
    local frame = mob.plate and mob.plate.UnitFrame
    local E = GetElvUI()
    local health = GetHealthBar(mob)
    if not frame or not E or not health then
        return
    end

    local nameplates = E:GetModule("NamePlates", true)
    if nameplates and nameplates.UpdateElement_HealthColor then
        ShadowDots_Debug("native color reconciliation", GetTime(), mob.unit, mob.guid,
            "before", health.r, health.g, health.b)
        health.r, health.g, health.b = nil, nil, nil
        nameplates:UpdateElement_HealthColor(frame)
        ShadowDots_Debug("native color result", health.r, health.g, health.b)
    end
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

function ShadowDots_ApplyNameplateColor(mob)
    if not ShadowDots.enabled then
        return
    end

    local state = mob.state
    if state == "NONE" then
        ShadowDots_RestoreNameplate(mob)
        return
    end

    local color = ShadowDotsDB[state == "SWP_ONLY" and "swpColor"
        or state == "VT_ONLY" and "vtColor" or "bothColor"]
    local health = GetHealthBar(mob)
    if not color or not health then
        return
    end

    if mob.colorOwned and mob.colorState == state then
        return
    end
    ShadowDots_Debug("apply", GetTime(), mob.unit, mob.guid, "plate",
        mob.plate and tostring(mob.plate) or "nil", "health", tostring(health),
        "state", state, "owned", mob.colorOwned, "rgb", color.r, color.g, color.b,
        "before", health.r, health.g, health.b)
    health:SetStatusBarColor(color.r, color.g, color.b)
    mob.colorOwned = true
    mob.colorState = state
    ShadowDots_Debug("color", mob.name, state, color.r, color.g, color.b)
end

local function UpdateScale()
    if not ShadowDots.enabled then
        return
    end

    if not ShadowDotsDB.enableScale then
        for _, mob in pairs(ShadowDots.mobs) do
            if mob.plate and mob.plate.UnitFrame then
                mob.plate.UnitFrame:SetScale(1)
            end
        end
        return
    end

    local bestTarget
    local bestPriority = -1
    for _, mob in pairs(ShadowDots.mobs) do
        if mob.plate and mob.unit
        and UnitExists(mob.unit) and UnitAffectingCombat(mob.unit) then
            local priority = 0
            if not mob.hasVT then priority = priority + 100 end
            if not mob.hasSWP then priority = priority + 100 end
            if priority > bestPriority then
                bestPriority = priority
                bestTarget = mob
            end
        end
        if mob.plate and mob.plate.UnitFrame then
            mob.plate.UnitFrame:SetScale(1)
        end
    end
    if bestTarget and bestTarget.plate and bestTarget.plate.UnitFrame then
        bestTarget.plate.UnitFrame:SetScale(ShadowDotsDB.scaleSize)
    end
end

function ShadowDots_UpdatePriority()
    UpdateScale()
end

function ShadowDots_RefreshVisuals()
    if not ShadowDots.enabled or not ShadowDots_IsShadowPriest() then
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
