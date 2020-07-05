LinkLuaModifier( "modifier_ability_phantom_assassin_coup_de_grace", "heroes/phantom_assassin/coup_de_grace" ,LUA_MODIFIER_MOTION_NONE )

if ability_phantom_assassin_coup_de_grace == nil then
    ability_phantom_assassin_coup_de_grace = class({})
end

--------------------------------------------------------------------------------

function ability_phantom_assassin_coup_de_grace:GetIntrinsicModifierName()
    return "modifier_ability_phantom_assassin_coup_de_grace"
end

--------------------------------------------------------------------------------


modifier_ability_phantom_assassin_coup_de_grace = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
            MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_phantom_assassin_coup_de_grace:OnRefresh()
    self:OnCreated()
end

function modifier_ability_phantom_assassin_coup_de_grace:OnCreated()
    self.crit_chance = self:GetAbility():GetSpecialValueFor("crit_chance")
    self.crit_bonus = self:GetAbility():GetSpecialValueFor("crit_bonus")
    self.crit = false
end

function modifier_ability_phantom_assassin_coup_de_grace:GetModifierPreAttack_CriticalStrike(keys)
    local target = keys.target
    self.crit = false
    if keys.attacker == self:GetCaster() and (target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == keys.attacker:GetTeamNumber()) then return end

    if keys.attacker == self:GetCaster() and not self:GetCaster():PassivesDisabled() and RollPseudoRandomPercentage(self.crit_chance, 1, self:GetCaster()) then
        self.crit = true

        return self.crit_bonus
    end
    return
end

function modifier_ability_phantom_assassin_coup_de_grace:OnAttackLanded(keys)
    local target = keys.target
    if self:GetCaster() == keys.attacker then
        if self.crit then
            EmitSoundOnLocationWithCaster(target:GetAbsOrigin(), "Hero_PhantomAssassin.CoupDeGrace", self:GetCaster())

            local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
            ParticleManager:SetParticleControlEnt(fx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
            ParticleManager:SetParticleControl(fx, 1, target:GetAbsOrigin())
            ParticleManager:SetParticleControlOrientation(fx, 1, self:GetCaster():GetForwardVector() * (-1), self:GetCaster():GetRightVector(), self:GetParent():GetUpVector())
            ParticleManager:ReleaseParticleIndex(fx)
        end
    end
end



