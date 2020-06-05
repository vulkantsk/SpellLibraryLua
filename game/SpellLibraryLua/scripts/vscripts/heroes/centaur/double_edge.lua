ability_double_edge = class({})

function ability_double_edge:OnSpellStart() 
    self:GetCaster():EmitSound('Hero_Centaur.DoubleEdge')


    local target = self:GetCursorTarget()
    local caster = self:GetCaster()
    local damage = self:GetSpecialValueFor('edge_damage') + (self:GetSpecialValueFor('strength_damage') * caster:GetStrength())*0.01

    ApplyDamage({
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        victim = caster,
        attacker = caster,
        damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL,
        ability = self,
    })

    local units = FindUnitsInRadius(self:GetCaster():GetTeam(), 
    target:GetOrigin(), 
    nil, 
    self:GetSpecialValueFor('radius'),
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    self:GetAbilityTargetFlags(),
    FIND_ANY_ORDER, 
    false)

    for _, unit in pairs(units) do 
        ApplyDamage({
            damage = damage,
            damage_type = self:GetAbilityDamageType(),
            victim = unit,
            attacker = caster,
            ability = self,
        })

        local nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_centaur/centaur_double_edge.vpcf', PATTACH_ABSORIGIN, self:GetCaster())
        ParticleManager:SetParticleControl(nfx, 1, unit:GetOrigin())
        ParticleManager:SetParticleControl(nfx, 2, unit:GetOrigin())
        ParticleManager:SetParticleControl(nfx, 4, unit:GetOrigin())
        ParticleManager:SetParticleControl(nfx, 5, unit:GetOrigin())
        ParticleManager:SetParticleControl(nfx, 9, unit:GetOrigin())
        ParticleManager:ReleaseParticleIndex(nfx)
    end 


    
end 