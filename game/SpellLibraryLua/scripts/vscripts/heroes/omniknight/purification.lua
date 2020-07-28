if ability_omniknight_purification == nil then
    ability_omniknight_purification = class({})
end

--------------------------------------------------------------------------------

function ability_omniknight_purification:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function ability_omniknight_purification:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local radius = self:GetSpecialValueFor("radius")
    local heal = self:GetSpecialValueFor("heal")

    target:Heal(heal, caster)

    SendOverheadEventMessage( target, OVERHEAD_ALERT_HEAL, target, heal, nil )

    local all = FindUnitsInRadius(caster:GetTeamNumber(), 
    target:GetAbsOrigin(), 
    nil, 
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER, 
    false)

    for _, unit in ipairs(all) do
        ApplyDamage({
            victim = unit,
            attacker = caster,
            damage = heal,
            damage_type = self:GetAbilityDamageType(),
            ability = self
        })

        local fx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification_hit.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(fx2, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
        ParticleManager:SetParticleControlEnt(fx2, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
        ParticleManager:ReleaseParticleIndex(fx2)
    end

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl( fx, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( fx, 1, Vector( radius, radius, radius ) )
    ParticleManager:ReleaseParticleIndex(fx)

    EmitSoundOn("Hero_Omniknight.Purification", target)
end