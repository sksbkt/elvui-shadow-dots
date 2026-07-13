local frame = CreateFrame("Frame")


frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")



local VT = 34914

local SWP = 589



frame:SetScript("OnEvent", function(self,event,...)



    if not ShadowDots.enabled then
        return
    end



    if not ShadowDots_IsShadowPriest() then
        return
    end




    local eventType =
        select(2,...)



    local sourceGUID =
        select(4,...)



    local destGUID =
        select(8,...)



    local spellID =
        select(12,...)





    local mob =
        ShadowDots.mobs[destGUID]



    -- mark enemy as fighting us

    if mob then

        mob.inCombat = true

    end




    -- only track our spells

    if sourceGUID ~= UnitGUID("player") then

        return

    end



    if not mob then

        return

    end





    if eventType == "SPELL_AURA_APPLIED"
    or eventType == "SPELL_AURA_REFRESH" then




        if spellID == VT then



            mob.hasVT = true



            print(
                "VT applied:",
                mob.name
            )



            ShadowDots_UpdatePriority()




        elseif spellID == SWP then




            mob.hasSWP = true



            print(
                "SW:P applied:",
                mob.name
            )



            ShadowDots_UpdatePriority()




        end






    elseif eventType == "SPELL_AURA_REMOVED" then





        if spellID == VT then



            mob.hasVT = false



            ShadowDots_UpdatePriority()




        elseif spellID == SWP then



            mob.hasSWP = false



            ShadowDots_UpdatePriority()




        end



    end



end)