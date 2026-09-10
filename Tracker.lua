local frame = CreateFrame("Frame")
frame.elapsed = 0
local watchdog

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
    local expectedR, expectedG, expectedB
    local count = 0
    for _, active in pairs(mob.activeDots or {}) do
        count = count + 1
        expectedR = (expectedR or 0) + active.dot.color.r
        expectedG = (expectedG or 0) + active.dot.color.g
        expectedB = (expectedB or 0) + active.dot.color.b
    end
    if count > 0 then
        expectedR, expectedG, expectedB = expectedR / count, expectedG / count, expectedB / count
    end
    local snapshot = mob.watchdogSnapshot
    local changed = not snapshot
        or snapshot.guid ~= mob.guid or snapshot.unit ~= mob.unit
        or snapshot.plate ~= plate or snapshot.health ~= health
        or snapshot.state ~= mob.state or snapshot.colorOwned ~= mob.colorOwned
        or DifferentColor(snapshot.r, snapshot.g, snapshot.b, r, g, b)
    if changed and ShadowDotsDB.debug then
        ShadowDots_Debug("Watchdog", "time", GetTime(), "guid", mob.guid,
            "unit", mob.unit, "state", mob.state, "owner", mob.colorOwned,
            "expected", expectedR or "native", expectedG or "", expectedB or "",
            "actual", r, g, b, "plate", tostring(plate), "health", tostring(health))
    end
    mob.watchdogSnapshot = {
        guid = mob.guid, unit = mob.unit, plate = plate, health = health,
        state = mob.state, colorOwned = mob.colorOwned, r = r, g = g, b = b,
    }
end

local function WatchdogTick()
    if not ShadowDots.enabled or not ShadowDotsDB.debug then
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

local function GetExpiring(mob, now)
    local speed
    local expiring = false
    for _, active in pairs(mob.activeDots or {}) do
        local dot = active.dot
        if ShadowDots_IsDotAllowedForCurrentSpec(dot)
        and dot.blinkEnabled and active.expiration
        and active.expiration - now <= dot.blinkThreshold then
            expiring = true
            speed = not speed and 0.25 or math.min(speed, 0.25)
        end
    end
    return expiring, speed
end

local function UpdateBlinking(elapsed)
    local now = GetTime()
    for _, mob in pairs(ShadowDots.mobs) do
        if not ShadowDotsDB.enableBlink then
            StopBlink(mob)
            mob.blinkElapsed = 0
        else
        local activeDots = mob.activeDots
        local hasActive = activeDots and next(activeDots) ~= nil
        if not mob.plate and not hasActive then
            ShadowDots.mobs[mob.guid] = nil
        elseif hasActive then
            mob.blinkElapsed = (mob.blinkElapsed or 0) + elapsed
            for _, active in pairs(mob.activeDots) do
                if active.expiration and active.expiration <= now and ShadowDots_ScanMob then
                    ShadowDots_ScanMob(mob)
                    break
                end
            end
            local expiring, speed = GetExpiring(mob, now)
            local health = mob.plate and mob.plate.UnitFrame and mob.plate.UnitFrame.HealthBar
            if expiring and health and mob.colorOwned then
                if mob.blinkElapsed >= speed then
                    mob.blinking = true
                    mob.blinkPhase = not mob.blinkPhase
                    health:SetAlpha(mob.blinkPhase and 0.35 or 1)
                    mob.blinkElapsed = 0
                end
            else
                StopBlink(mob)
                mob.blinkElapsed = 0
            end
        else
            StopBlink(mob)
        end
        end
    end
end

local function OnUpdate(self, elapsed)
    if not ShadowDots.enabled then
        return
    end
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < 0.05 then
        return
    end
    self.elapsed = 0
    UpdateBlinking(elapsed)
end

function ShadowDots_StartBlinking()
    frame.elapsed = 0
    frame:SetScript("OnUpdate", OnUpdate)
    if ShadowDotsDB.debug and ShadowDotsDB.watchdog then
        ShadowDots_StartWatchdog()
    end
end

function ShadowDots_StopBlinking()
    for _, mob in pairs(ShadowDots.mobs) do
        StopBlink(mob)
    end
    frame:SetScript("OnUpdate", nil)
    ShadowDots_StopWatchdog()
end
