ShadowDots = ShadowDots or {}
ShadowDots.mobs = ShadowDots.mobs or {}
ShadowDots.plates = ShadowDots.plates or {}

local function FindMob(unit, plate, guid)
    if guid and ShadowDots.mobs[guid] then
        return ShadowDots.mobs[guid]
    end
    if plate and ShadowDots.plates[plate] then
        return ShadowDots.mobs[ShadowDots.plates[plate]]
    end
    for _, mob in pairs(ShadowDots.mobs) do
        if mob.unit == unit then
            return mob
        end
    end
end

local function DetachMob(mob)
    if not mob then
        return
    end
    if mob.plate then
        ShadowDots.plates[mob.plate] = nil
        if mob.blinking and mob.plate.UnitFrame and mob.plate.UnitFrame.HealthBar then
            mob.plate.UnitFrame.HealthBar:SetAlpha(1)
        end
    end
    mob.plate = nil
    mob.unit = nil
    mob.colorOwned = false
    mob.colorState = nil
    mob.blinking = false
end

local function RemoveNameplate(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    local mob = FindMob(unit, plate, UnitGUID(unit))
    if not mob then
        return
    end

    ShadowDots_Debug("removed", GetTime(), mob.unit, mob.guid)
    DetachMob(mob)
end

function ShadowDots_ReconcileNameplate(mob, unit, guid, plate)
    if not ShadowDots.enabled or not ShadowDots_IsShadowPriest()
    or not mob or ShadowDots.mobs[guid] ~= mob
    or UnitGUID(unit) ~= guid
    or C_NamePlate.GetNamePlateForUnit(unit) ~= plate
    or not plate.UnitFrame or not plate.UnitFrame.HealthBar then
        return
    end

    mob.unit = unit
    mob.plate = plate
    ShadowDots.plates[plate] = guid
    if ShadowDots_ScanMob then
        ShadowDots_ScanMob(mob)
    end
    if mob.state == "NONE" then
        ShadowDots_RestoreNameplate(mob, true)
    elseif ShadowDots_ApplyNameplateColor then
        mob.colorState = nil
        ShadowDots_ApplyNameplateColor(mob)
    end
    ShadowDots_Debug("reconciled", GetTime(), unit, guid,
        "plate", tostring(plate), "health", tostring(plate.UnitFrame.HealthBar),
        "state", mob.state, "owned", mob.colorOwned)
end

local function DeferReconcile(mob, unit, guid, plate)
    if not C_Timer or not C_Timer.After then
        return
    end
    C_Timer.After(0, function()
        ShadowDots_ReconcileNameplate(mob, unit, guid, plate)
    end)
end

function ShadowDots_ScheduleFinalReconcile(unit)
    if not ShadowDots.enabled or not ShadowDots_IsShadowPriest()
    or not UnitExists(unit) then
        return
    end

    local guid = UnitGUID(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    local mob = guid and ShadowDots.mobs[guid]
    if not mob or not plate or mob.pendingReconcile then
        return
    end

    mob.pendingReconcile = true
    ShadowDots_Debug("final reconcile scheduled", GetTime(), unit, guid)
    if not C_Timer or not C_Timer.After then
        mob.pendingReconcile = nil
        return
    end
    C_Timer.After(0, function()
        mob.pendingReconcile = nil
        ShadowDots_Debug("final reconcile executed", GetTime(), unit, guid)
        ShadowDots_ReconcileNameplate(mob, unit, guid, plate)
    end)
end

local function AddNameplate(unit)
    if not ShadowDots.enabled or not ShadowDots_IsShadowPriest() or not UnitExists(unit) then
        return
    end
    if not UnitCanAttack("player", unit) then
        return
    end

    local guid = UnitGUID(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if not guid or not plate then
        return
    end

    local existing = ShadowDots.mobs[guid]
    if existing then
        if existing.plate and existing.plate ~= plate then
            DetachMob(existing)
        end
        existing.unit = unit
        existing.plate = plate
        existing.name = UnitName(unit)
        existing.classification = UnitClassification(unit)
        ShadowDots.plates[plate] = guid
        if ShadowDots_ScanMob then
            ShadowDots_ScanMob(existing)
        end
        ShadowDots_ReconcileNameplate(existing, unit, guid, plate)
        DeferReconcile(existing, unit, guid, plate)
        return existing
    end

    local reused = ShadowDots.plates[plate]
    if reused and ShadowDots.mobs[reused] then
        DetachMob(ShadowDots.mobs[reused])
    end

    local mob = {
        unit = unit,
        plate = plate,
        name = UnitName(unit),
        guid = guid,
        classification = UnitClassification(unit),
        inCombat = false,
        hasVT = false,
        hasSWP = false,
        swpExpiration = nil,
        vtExpiration = nil,
        state = "NONE",
        colorOwned = false,
        blinking = false,
    }
    ShadowDots.mobs[guid] = mob
    ShadowDots.plates[plate] = guid
    ShadowDots_Debug("added", GetTime(), unit, guid,
        "plate", tostring(plate), "health", tostring(plate.UnitFrame.HealthBar))
    if ShadowDots_ScanMob then
        ShadowDots_ScanMob(mob)
    end
    ShadowDots_ReconcileNameplate(mob, unit, guid, plate)
    DeferReconcile(mob, unit, guid, plate)
    return mob
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
frame:SetScript("OnEvent", function(self, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        AddNameplate(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" and ShadowDots.enabled then
        RemoveNameplate(unit)
    end
end)

function ShadowDots_ScanNameplates()
    if not ShadowDots.enabled or not ShadowDots_IsShadowPriest() then
        return
    end
    for i = 1, 40 do
        local unit = "nameplate"..i
        if UnitExists(unit) then
            AddNameplate(unit)
        end
    end
    if ShadowDots_UpdatePriority then
        ShadowDots_UpdatePriority()
    end
end
