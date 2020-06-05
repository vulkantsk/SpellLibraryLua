ability_hoof_stomp = class({})


function ability_hoof_stomp:OnSpellStart()

    local radius = self:GetSpecialValueFor('radius')
    local duration = self:GetSpecialValueFor('stun_duration')
    local damage = self:GetSpecialValueFor('stomp_damage')

    local nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_centaur/centaur_warstomp.vpcf', PATTACH_ABSORIGIN, self:GetCaster())
    ParticleManager:SetParticleControl(nfx, 1, Vector(radius,radius,radius))
    ParticleManager:SetParticleControl(nfx, 2, self:GetCaster():GetOrigin())
    ParticleManager:SetParticleControl(nfx, 3, self:GetCaster():GetOrigin())
    ParticleManager:SetParticleControl(nfx, 4, self:GetCaster():GetOrigin())
    ParticleManager:SetParticleControl(nfx, 5, self:GetCaster():GetOrigin())
    ParticleManager:ReleaseParticleIndex(nfx)
    self:GetCaster():EmitSound('Hero_Centaur.HoofStomp')

    local units = FindUnitsInRadius(self:GetCaster():GetTeam(), 
    self:GetCaster():GetOrigin(), 
    nil, 
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    self:GetAbilityTargetFlags(),
    FIND_ANY_ORDER, 
    false)
    for _,unit in pairs(units) do 
        unit:AddNewModifier(self:GetCaster(), self, 'modifier_stunned', {duration = duration})

        ApplyDamage({
            victim = unit,
            attacker = self:GetCaster(),
            damage_type = self:GetAbilityDamageType(),
            damage = damage,
            ability = self,
        })
    end 

end