local addonName = ...

ShadowDots = ShadowDots or {}

ShadowDots.enabled = false
ShadowDots.mobs = ShadowDots.mobs or {}



function ShadowDots_IsShadowPriest()

    local spec = GetSpecialization()

    if not spec then
        return false
    end

    return GetSpecializationInfo(spec) == 258

end



function ShadowDots_Enable()

    if ShadowDots.enabled then
        return
    end


    ShadowDots.enabled = true


    print("ShadowDots Enabled")


    if ShadowDots_ScanNameplates then
        ShadowDots_ScanNameplates()
    end

end



function ShadowDots_Disable()

    ShadowDots.enabled = false

    print("ShadowDots Disabled")


    for guid,mob in pairs(ShadowDots.mobs) do

        if mob.plate
        and mob.plate.UnitFrame then

            mob.plate.UnitFrame:SetScale(1)

        end

    end

end



function ShadowDots_CheckSpec()

    if ShadowDots_IsShadowPriest() then

        ShadowDots_Enable()

    else

        ShadowDots_Disable()

    end

end



local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")



frame:SetScript("OnEvent",function(self,event,unit)

    if event == "PLAYER_LOGIN" then

        ShadowDots_CheckSpec()


    elseif event == "PLAYER_SPECIALIZATION_CHANGED"
    and unit == "player" then

        ShadowDots_CheckSpec()

    end

end)