if ability_spectre_reality == nil then
    ability_spectre_reality = class({})
end

--------------------------------------------------------------------------------

function ability_spectre_reality:OnSpellStart()
    local caster = self:GetCaster()
    local ability = caster:FindAbilityByName("ability_spectre_haunt")
    local duration = ability:GetSpecialValueFor("duration")
    local illusion_damage_outgoing = ability:GetSpecialValueFor("illusion_damage_outgoing")
    local illusion_damage_incoming = ability:GetSpecialValueFor("illusion_damage_incoming")
    local attack_delay = ability:GetSpecialValueFor("attack_delay")

    local Ttime = ability.startTime
    if Ttime == nil then Ttime = GameRules:GetGameTime() end
    local EndTime = Ttime + duration
    duration = math.abs(EndTime - GameRules:GetGameTime())

    local all = FindUnitsInRadius(caster:GetTeam(), 
    caster:GetOrigin(), 
    nil, 
    99999,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
    DOTA_UNIT_TARGET_HERO, 
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER, 
    false)

    local illusion = nil
    local distance = nil
    for _,unit in pairs(all) do
        if unit:IsIllusion() and unit.ISSPECTRE_ILLUSION_HAUNT == true then
            local distanceToAlly = (self:GetCursorPosition() - unit:GetOrigin()):Length()
            if unit:IsAlive() and (distance == nil or distanceToAlly < distance) then
                distance = distanceToAlly
                illusion = unit
            end
        end
    end

    if illusion ~= nil then
        local point = caster:GetAbsOrigin()
        local direction = caster:GetForwardVector()
        caster:SetAbsOrigin(illusion:GetAbsOrigin())
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
        caster:SetForwardVector(illusion:GetForwardVector())

        EmitSoundOn("Hero_Spectre.Reality", caster)

        local target = illusion:GetForceAttackTarget()
        if target ~= nil then
            ExecuteOrderFromTable({
                UnitIndex = caster:entindex(),
                OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
                TargetIndex = target:entindex(),
                Queue = false,
            })
        end

        illusion:Kill(self, caster)

        local illusions = CreateIllusions(caster, caster, { duration = duration, outgoing_damage = illusion_damage_outgoing, incoming_damage = illusion_damage_incoming }, 1, 0, false, true )
        for k,v in ipairs(illusions) do
            v:SetAbsOrigin(point)
            v:SetForwardVector(direction)

            local all = FindUnitsInRadius(caster:GetTeam(), 
            caster:GetOrigin(), 
            nil, 
            900,
            DOTA_UNIT_TARGET_TEAM_ENEMY, 
            DOTA_UNIT_TARGET_HERO, 
            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
            FIND_ANY_ORDER, 
            false)

            for _, unit in ipairs(all) do
                Timers:CreateTimer(attack_delay, function()
                    ExecuteOrderFromTable({
                        UnitIndex = v:entindex(),
                        OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
                        TargetIndex = unit:entindex(),
                        Queue = false,
                    })
                    v:SetForceAttackTarget(unit)
                end)
                break
            end

            v:AddNewModifier(caster, ability, "modifier_ability_spectre_haunt_illusions_buff", {duration=inf})
            v.ISSPECTRE_ILLUSION_HAUNT = true
            FindClearSpaceForUnit(v, v:GetAbsOrigin(), false)
        end
    end
end

function ability_spectre_reality:GetAssociatedSecondaryAbilities()
    return "ability_spectre_haunt"
end