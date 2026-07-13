local addonName = ...

ShadowDots = ShadowDots or {}
ShadowDots.mobs = ShadowDots.mobs or {}


local function AddNameplate(unit)

    if not ShadowDots.enabled then
        return
    end


    if not UnitExists(unit) then
        return
    end


    if not UnitCanAttack("player", unit) then
        return
    end


    local guid = UnitGUID(unit)

    if not guid then
        return
    end



    local plate = C_NamePlate.GetNamePlateForUnit(unit)

    if not plate then
        return
    end



    ShadowDots.mobs[guid] = {

        unit = unit,

        plate = plate,

        name = UnitName(unit),

        guid = guid,

        classification = UnitClassification(unit),

        inCombat = false,

        hasVT = false,

        hasSWP = false,

        priority = 0,

    }


    print("ShadowDots tracking:", UnitName(unit))


end




local frame = CreateFrame("Frame")


frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")



frame:SetScript("OnEvent", function(self,event,unit)


    if event == "NAME_PLATE_UNIT_ADDED" then


        AddNameplate(unit)



    elseif event == "NAME_PLATE_UNIT_REMOVED" then


        local guid = UnitGUID(unit)


        if guid then

            ShadowDots.mobs[guid] = nil

        end


    end


end)




function ShadowDots_ScanNameplates()


    for i = 1, 40 do


        local unit = "nameplate"..i


        if UnitExists(unit) then

            AddNameplate(unit)

        end


    end


end