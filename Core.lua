if type(ShadowDotsDB) ~= "table" then
    ShadowDotsDB = {}
end
if type(ShadowDotsDB.dots) ~= "table" then
    ShadowDotsDB.dots = {}
end

ShadowDots = ShadowDots or {}
ShadowDots.enabled = false
ShadowDots.mobs = ShadowDots.mobs or {}
ShadowDots.plates = ShadowDots.plates or {}

function ShadowDots_Debug(...)
    if ShadowDotsDB.debug then
        print("|cffb366ffShadowDots:|r", ...)
    end
end

function ShadowDots_Enable()
    if ShadowDots.enabled or not ShadowDotsDB.enabled then
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

function ShadowDots_CheckEnabled()
    if ShadowDotsDB.enabled then
        ShadowDots_Enable()
    else
        ShadowDots_Disable()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        ShadowDots_CheckEnabled()
    end
end)
