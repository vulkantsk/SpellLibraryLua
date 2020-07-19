LinkLuaModifier("modifier_centaur_return", "heroes/centaur/return.lua", 0)

ability_centaur_return = class({
    GetIntrinsicModifierName = function() return "modifier_centaur_return" end
})

modifier_centaur_return = class({
    isHidden = function() return true end,
    IsPurgable = function() return false end,
    IsBuff = function() return true end,
    DeclareFunctions = function() return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    } end
})

function modifier_centaur_return:OnCreated()
    self.return_damage = self:GetAbility():GetSpecialValueFor("return_damage")
    self.str_to_damage = self:GetAbility():GetSpecialValueFor("return_damage_str")
end

function modifier_centaur_return:OnRefresh()
    self:OnCreated()
end

function modifier_centaur_return:OnAttackLanded(params)
    local victim = params.unit
    if victim == self:GetParent() and victim:PassivesDisabled() == false and victim:IsRealHero() and not params.attacker:IsOther() then
        local str_damage = victim:GetStrength() / 100 * self.str_to_damage
        local damage = self.return_damage + str_to_damage
        if params.attacker:IsBuilding() then
            damage = damage / 2
        end
        ApplyDamage({
            victim = params.attacker,
            attacker = victim,
            ability = self:GetAbility(),
            damage = damage,
            damage_type = self:GetAbility():GetAbilityDamageType(),
            damage_flags = DOTA_DAMAGE_FLAG_REFLECTION
        })

        local particle = "particles/units/heroes/hero_centaur/centaur_return.vpcf"
	    local fx = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN, victim)
	    ParticleManager:SetParticleControlEnt(fx, 0, victim, PATTACH_POINT_FOLLOW, "attach_hitloc", victim:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(fx, 1, params.attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", params.attacker:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(fx)
    end
end