local function GetHealthBar(mob)

    if not mob.plate or not mob.plate.UnitFrame then
        return nil
    end

    return mob.plate.UnitFrame.HealthBar
        or mob.plate.UnitFrame.Health
        or mob.plate.UnitFrame.healthBar

end



local function SetHealthColor(mob, r, g, b)

    local health = GetHealthBar(mob)

    if health then
        health:SetStatusBarColor(r, g, b)
    end

end



local function ResetHealthColor(mob)

    SetHealthColor(mob, 1, 1, 1)

end



function ShadowDots_HighlightTarget()

    if not ShadowDots.enabled then
        return
    end

    if not ShadowDots_IsShadowPriest() then
        return
    end


    for guid, mob in pairs(ShadowDots.mobs) do

        if UnitExists(mob.unit) then

            -- Always reset first
            ResetHealthColor(mob)

            if mob.plate and mob.plate.UnitFrame then
                mob.plate.UnitFrame:SetScale(1)
            end


            -- Only highlight enemies that are actually in combat
            if UnitAffectingCombat(mob.unit) then

                -- Missing both DoTs
                if not mob.hasVT and not mob.hasSWP then

                    if ShadowDotsDB.enableBothColor then
                        local c = ShadowDotsDB.bothColor
                        SetHealthColor(mob, c.r, c.g, c.b)
                    end

                -- Missing Vampiric Touch
                elseif mob.hasSWP and not mob.hasVT then

                    if ShadowDotsDB.enableVTColor then
                        local c = ShadowDotsDB.vtColor
                        SetHealthColor(mob, c.r, c.g, c.b)
                    end

                -- Missing Shadow Word: Pain
                elseif mob.hasVT and not mob.hasSWP then

                    if ShadowDotsDB.enableSWPColor then
                        local c = ShadowDotsDB.swpColor
                        SetHealthColor(mob, c.r, c.g, c.b)
                    end

                end

            end

        end

    end


    if ShadowDotsDB.enableScale then

        local bestTarget = nil
        local bestPriority = -1

        for guid, mob in pairs(ShadowDots.mobs) do

            if UnitExists(mob.unit)
            and UnitAffectingCombat(mob.unit) then

                local priority = 0

                if not mob.hasVT then
                    priority = priority + 100
                end

                if not mob.hasSWP then
                    priority = priority + 100
                end

                if priority > bestPriority then
                    bestPriority = priority
                    bestTarget = mob
                end

            end

        end

        if bestTarget
        and bestTarget.plate
        and bestTarget.plate.UnitFrame then

            bestTarget.plate.UnitFrame:SetScale(
                ShadowDotsDB.scaleSize
            )

        end

    end

end



function ShadowDots_UpdatePriority()

    ShadowDots_HighlightTarget()

end