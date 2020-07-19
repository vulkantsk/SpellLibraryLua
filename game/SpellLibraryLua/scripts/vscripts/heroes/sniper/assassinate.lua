LinkLuaModifier( "modifier_ability_sniper_assassinate", "heroes/sniper/assassinate" ,LUA_MODIFIER_MOTION_NONE )

if ability_sniper_assassinate == nil then
    ability_sniper_assassinate = class({})
end

--------------------------------------------------------------------------------

function ability_sniper_assassinate:OnAbilityPhaseStart()
    local target = self:GetCursorTarget()

    local cast_response = {"sniper_snip_ability_assass_02", "sniper_snip_ability_assass_06", "sniper_snip_ability_assass_07", "sniper_snip_ability_assass_08"}

    target:AddNewModifier(self:GetCaster(), self, "modifier_ability_sniper_assassinate", {duration=4})

    EmitSoundOn(cast_response[math.random(1, #cast_response)], self:GetCaster())

    EmitSoundOnClient("Ability.AssassinateLoad", self:GetCaster():GetPlayerOwner())
    return true
end

function ability_sniper_assassinate:OnAbilityPhaseInterrupted()
    self:GetCursorTarget():RemoveModifierByName("modifier_ability_sniper_assassinate")
end

function ability_sniper_assassinate:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local info = {
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf",
        bDodgeable = true,
        bProvidesVision = false,
        iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
    }
    ProjectileManager:CreateTrackingProjectile( info )

    EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Ability.Assassinate", caster)
    EmitSoundOn("Hero_Sniper.AssassinateProjectile", target)
end

function ability_sniper_assassinate:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() then

        Target:RemoveModifierByName("modifier_ability_sniper_assassinate")

        if Target:TriggerSpellAbsorb(self) then return end

        EmitSoundOn("Hero_Sniper.AssassinateDamage", Target)

        ApplyDamage({
            victim = Target,
            attacker = self:GetCaster(),
            damage = self:GetAbilityDamage(),
            damage_type = self:GetAbilityDamageType(),
            ability = self
        })

        Target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration=0.01})

        local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sniper/sniper_assassinate_impact_sparks.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
        ParticleManager:SetParticleControlEnt(fx, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(fx, 1, Target, PATTACH_POINT_FOLLOW, "attach_hitloc", Target:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(fx)

        local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sniper/sniper_assassinate_endpoint.vpcf", PATTACH_CUSTOMORIGIN, self:GetCaster())
        ParticleManager:SetParticleControlEnt(fx, 1, Target, PATTACH_POINT_FOLLOW, "attach_hitloc", Target:GetAbsOrigin(), true)
        ParticleManager:ReleaseParticleIndex(fx)
    end
    return true
end

--------------------------------------------------------------------------------


modifier_ability_sniper_assassinate = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_PROVIDES_VISION] = true,
            [MODIFIER_STATE_INVISIBLE] = false
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_sniper_assassinate:OnCreated()
    self.fx = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_sniper/sniper_crosshair.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent(), self:GetCaster():GetTeamNumber())
    ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
    self:AddParticle(self.fx, false, false, -1, false, true)
end