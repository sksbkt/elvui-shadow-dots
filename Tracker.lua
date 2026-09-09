local frame = CreateFrame("Frame")
frame.elapsed = 0
local watchdog

local function WatchdogColor(state)
    if state == "SWP_ONLY" then
        return ShadowDotsDB.swpColor
    elseif state == "VT_ONLY" then
        return ShadowDotsDB.vtColor
    elseif state == "BOTH" then
        return ShadowDotsDB.bothColor
    end
end

local function DifferentColor(r1, g1, b1, r2, g2, b2)
    return r1 ~= r2 or g1 ~= g2 or b1 ~= b2
end

local function WatchdogMob(mob)
    local plate = mob.plate
    local unitFrame = plate and plate.UnitFrame
    local health = unitFrame and unitFrame.HealthBar
    if not mob.unit or not plate or not unitFrame or not health then
        return
    end

    local r, g, b = health:GetStatusBarColor()
    local expected = WatchdogColor(mob.state)
    local snapshot = mob.watchdogSnapshot
    local changed = not snapshot
        or snapshot.guid ~= mob.guid
        or snapshot.unit ~= mob.unit
        or snapshot.plate ~= plate
        or snapshot.health ~= health
        or snapshot.state ~= mob.state
        or snapshot.colorOwned ~= mob.colorOwned
        or DifferentColor(snapshot.r, snapshot.g, snapshot.b, r, g, b)

    if expected and mob.colorOwned
    and DifferentColor(expected.r, expected.g, expected.b, r, g, b) then
        changed = true
    end

    if changed and ShadowDotsDB.debug then
        ShadowDots_Debug("Watchdog", "time", GetTime(), "guid", mob.guid,
            "unit", mob.unit, "state", mob.state, "owner", mob.colorOwned,
            "expected", expected and expected.r or "native",
            expected and expected.g or "", expected and expected.b or "",
            "actual", r, g, b, "swp", mob.hasSWP, "vt", mob.hasVT,
            "swpExp", mob.swpExpiration, "vtExp", mob.vtExpiration,
            "plate", tostring(plate), "health", tostring(health))
    end

    mob.watchdogSnapshot = {
        guid = mob.guid,
        unit = mob.unit,
        plate = plate,
        health = health,
        state = mob.state,
        colorOwned = mob.colorOwned,
        r = r,
        g = g,
        b = b,
    }
end

local function WatchdogTick()
    if not ShadowDots.enabled or not ShadowDots_IsShadowPriest() or not ShadowDotsDB.debug then
        return
    end
    for _, mob in pairs(ShadowDots.mobs) do
        if mob.plate and mob.unit then
            WatchdogMob(mob)
        end
    end
end

function ShadowDots_StartWatchdog()
    if watchdog or not ShadowDotsDB.debug or not C_Timer or not C_Timer.NewTicker then
        return
    end
    watchdog = C_Timer.NewTicker(0.1, WatchdogTick)
end

function ShadowDots_StopWatchdog()
    if watchdog then
        watchdog:Cancel()
        watchdog = nil
    end
    for _, mob in pairs(ShadowDots.mobs) do
        mob.watchdogSnapshot = nil
    end
end

local function StopBlink(mob)
    if not mob.blinking then
        return
    end
    local health = mob.plate and mob.plate.UnitFrame and mob.plate.UnitFrame.HealthBar
    if health then
        health:SetAlpha(1)
    end
    mob.blinking = false
end

local function IsExpiring(mob)
    if mob.hasSWP and ShadowDotsDB.blinkSWP and mob.swpExpiration then
        if mob.swpExpiration - GetTime() <= ShadowDotsDB.blinkThreshold then
            return true
        end
    end
    if mob.hasVT and ShadowDotsDB.blinkVT and mob.vtExpiration then
        if mob.vtExpiration - GetTime() <= ShadowDotsDB.blinkThreshold then
            return true
        end
    end
    return false
end

local function UpdateBlinking()
    for _, mob in pairs(ShadowDots.mobs) do
        if not mob.plate
        and (not mob.swpExpiration or mob.swpExpiration <= GetTime())
        and (not mob.vtExpiration or mob.vtExpiration <= GetTime()) then
            ShadowDots.mobs[mob.guid] = nil
        elseif mob.hasSWP or mob.hasVT then
            local now = GetTime()
            if (mob.swpExpiration and mob.swpExpiration <= now)
            or (mob.vtExpiration and mob.vtExpiration <= now) then
                if ShadowDots_ScanMob then
                    ShadowDots_ScanMob(mob)
                end
            end
            local health = mob.plate and mob.plate.UnitFrame and mob.plate.UnitFrame.HealthBar
            if ShadowDotsDB.blinkEnabled and IsExpiring(mob) and health and mob.colorOwned then
                mob.blinking = true
                mob.blinkPhase = not mob.blinkPhase
                health:SetAlpha(mob.blinkPhase and ShadowDotsDB.blinkAlpha or 1)
            else
                StopBlink(mob)
            end
        else
            StopBlink(mob)
        end
    end
end

local function OnUpdate(self, elapsed)
    if not ShadowDots.enabled or not ShadowDots_IsShadowPriest() then
        return
    end
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < ShadowDotsDB.blinkSpeed then
        return
    end
    self.elapsed = 0
    UpdateBlinking()
end

function ShadowDots_StartBlinking()
    frame.elapsed = 0
    frame:SetScript("OnUpdate", OnUpdate)
    ShadowDots_StartWatchdog()
end

function ShadowDots_StopBlinking()
    for _, mob in pairs(ShadowDots.mobs) do
        StopBlink(mob)
    end
    frame:SetScript("OnUpdate", nil)
    ShadowDots_StopWatchdog()
end
