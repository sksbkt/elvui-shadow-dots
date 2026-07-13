local frame = CreateFrame("Frame")


frame.timer = 0



frame:SetScript("OnUpdate", function(self, elapsed)


    if not ShadowDots.enabled then
        return
    end


    if not ShadowDots_IsShadowPriest() then
        return
    end



    self.timer = self.timer + elapsed


    if self.timer < 1 then
        return
    end


    self.timer = 0



    -- Do not reset hasVT / hasSWP here.
    -- Combat log handles our dots.


    ShadowDots_HighlightTarget()



end)