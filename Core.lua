ShadowDots = ShadowDots or {}
ShadowDots.enabled = false
ShadowDots.mobs = ShadowDots.mobs or {}
ShadowDots.plates = ShadowDots.plates or {}

function ShadowDots_IsShadowPriest()
    local spec = GetSpecialization()
    return spec and GetSpecializationInfo(spec) == 258
end

function ShadowDots_Debug(...)
    if ShadowDotsDB.debug then
        print("|cffb366ffShadowDots:|r", ...)
    end
end

function ShadowDots_Enable()
    if ShadowDots.enabled or not ShadowDotsDB.enabled or not ShadowDots_IsShadowPriest() then
        return
    end

    ShadowDots.enabled = true
    if ShadowDots_StartBlinking then
        ShadowDots_StartBlinking()
    end
    ShadowDots_Debug("enabled")
    if ShadowDots_ScanNameplates then
        ShadowDots_ScanNameplates()
    end
end

function ShadowDots_Disable()
    if not ShadowDots.enabled and not next(ShadowDots.mobs) then
        return
    end

    ShadowDots.enabled = false
    if ShadowDots_StopBlinking then
        ShadowDots_StopBlinking()
    end

    for _, mob in pairs(ShadowDots.mobs) do
        if ShadowDots_RestoreNameplate then
            ShadowDots_RestoreNameplate(mob)
        end
        if mob.plate and mob.plate.UnitFrame then
            mob.plate.UnitFrame:SetScale(1)
        end
    end

    wipe(ShadowDots.mobs)
    wipe(ShadowDots.plates)
    ShadowDots_Debug("disabled")
end

function ShadowDots_CheckSpec()
    if ShadowDots_IsShadowPriest() and ShadowDotsDB.enabled then
        ShadowDots_Enable()
    else
        ShadowDots_Disable()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        ShadowDots_CheckSpec()
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" and unit == "player" then
        ShadowDots_CheckSpec()
    end
end)
