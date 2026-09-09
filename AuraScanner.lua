local function GetMob(unit)
    if type(unit) ~= "string" or unit == "" then
        return
    end
    local guid = UnitGUID(unit)
    if guid and ShadowDots.mobs[guid] then
        return ShadowDots.mobs[guid]
    end
    for _, mob in pairs(ShadowDots.mobs) do
        if mob.unit == unit then
            return mob
        end
    end
end

local function DebugMob(mob)
    if not mob then
        return "untracked"
    end
    local plate = mob.plate and tostring(mob.plate) or "nil"
    local health = mob.plate and mob.plate.UnitFrame
        and mob.plate.UnitFrame.HealthBar and tostring(mob.plate.UnitFrame.HealthBar) or "nil"
    return "guid="..tostring(mob.guid).." plate="..plate.." health="..health
end

local function FindUnitByGUID(guid)
    for i = 1, 40 do
        local unit = "nameplate"..i
        if UnitExists(unit) and UnitGUID(unit) == guid then
            return unit
        end
    end
end

local function GetState(active)
    local count = 0
    for _ in pairs(active) do
        count = count + 1
    end
    if count == 0 then
        return "NONE"
    elseif count == 1 then
        for spellID in pairs(active) do
            return "DOT_"..tostring(spellID)
        end
    end
    return "MULTIPLE"
end

function ShadowDots_ScanMob(mob)
    if not ShadowDots.enabled or not mob or not UnitExists(mob.unit) then
        return
    end

    local active = {}
    local index = 1
    while true do
        local name, _, _, _, _, _, expirationTime, unitCaster, _, _, spellID = UnitDebuff(mob.unit, index)
        if not name then
            break
        end
        local dot = ShadowDots_GetDot(spellID)
        if dot and dot.enabled and unitCaster == "player" then
            active[spellID] = {
                expiration = expirationTime,
                dot = dot,
            }
        end
        index = index + 1
    end

    local oldState = mob.state
    mob.activeDots = active
    mob.state = GetState(active)
    mob.hasDots = next(active) ~= nil
    ShadowDots_Debug("scan", GetTime(), mob.unit, DebugMob(mob),
        "active", mob.state, "owned", mob.colorOwned)

    if oldState ~= mob.state or (mob.plate and not mob.colorOwned) then
        if ShadowDots_ApplyNameplateColor then
            ShadowDots_ApplyNameplateColor(mob)
        end
        if ShadowDots_UpdatePriority then
            ShadowDots_UpdatePriority()
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", function(self, event, ...)
    if not ShadowDots.enabled then
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        if ShadowDots_ScanNameplates then
            ShadowDots_ScanNameplates()
        end
        return
    end

    if event == "UNIT_AURA" or event == "UNIT_THREAT_LIST_UPDATE" then
        local unit = select(1, ...)
        local mob = GetMob(unit)
        ShadowDots_Debug(event, GetTime(), unit, DebugMob(mob))
        if mob then
            if event == "UNIT_THREAT_LIST_UPDATE" and ShadowDots_ScheduleFinalReconcile then
                ShadowDots_ScheduleFinalReconcile(unit)
            else
                ShadowDots_ScanMob(mob)
            end
        end
        return
    end

    local eventType = select(2, ...)
    local sourceGUID = select(4, ...)
    local destGUID = select(8, ...)
    local spellID = select(12, ...)
    local dot = ShadowDots_GetDot(spellID)
    local mob = ShadowDots.mobs[destGUID]
    if mob then
        mob.inCombat = true
    end
    if sourceGUID == UnitGUID("player") and dot then
        ShadowDots_Debug("COMBAT_LOG", GetTime(), eventType, spellID, "destGUID", destGUID, DebugMob(mob))
        if not mob then
            local unit = FindUnitByGUID(destGUID)
            if unit and ShadowDots_ScanNameplates then
                ShadowDots_ScanNameplates()
                mob = GetMob(unit)
            end
        end
        if mob then
            ShadowDots_ScanMob(mob)
            if C_Timer and C_Timer.After then
                C_Timer.After(0.1, function()
                    if ShadowDots.enabled and ShadowDots.mobs[mob.guid] == mob then
                        ShadowDots_ScanMob(mob)
                    end
                end)
            end
        end
    end
end)

function ShadowDots_GetState(mob)
    return mob.state
end
