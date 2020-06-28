LinkLuaModifier( "modifier_ability_disruptor_static_storm_thinker", "heroes/disruptor/static_storm" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_disruptor_static_storm", "heroes/disruptor/static_storm" ,LUA_MODIFIER_MOTION_NONE )

if ability_disruptor_static_storm == nil then
    ability_disruptor_static_storm = class({})
end

--------------------------------------------------------------------------------

function ability_disruptor_static_storm:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local duration = self:GetSpecialValueFor("duration")

    if RollPercentage(65) then
        EmitSoundOn("disruptor_dis_staticstorm_0"..RandomInt(1, 5), caster)
    end

    EmitSoundOnLocationWithCaster(point, "Hero_Disruptor.StaticStorm.Cast", caster)

    AddFOWViewer(caster:GetTeamNumber(), caster:GetAbsOrigin(), 450, duration, false)
    CreateModifierThinker(caster, self, "modifier_ability_disruptor_static_storm_thinker", {duration = duration}, point, caster:GetTeam(), false)
end

function ability_disruptor_static_storm:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

--------------------------------------------------------------------------------


modifier_ability_disruptor_static_storm_thinker = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

function modifier_ability_disruptor_static_storm_thinker:IsAura()
    return true
end

function modifier_ability_disruptor_static_storm_thinker:GetModifierAura()
    return "modifier_ability_disruptor_static_storm"
end

function modifier_ability_disruptor_static_storm_thinker:GetAuraRadius()
    return self.radius
end

function modifier_ability_disruptor_static_storm_thinker:GetAuraSearchTeam()    
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_disruptor_static_storm_thinker:GetAuraSearchType()    
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_ability_disruptor_static_storm_thinker:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

if IsServer() then
function modifier_ability_disruptor_static_storm_thinker:OnCreated()
    self.pulses = self:GetAbility():GetSpecialValueFor("pulses")
    self.damage_max = self:GetAbility():GetSpecialValueFor("damage_max") * 0.25
    self.duration = self:GetAbility():GetSpecialValueFor("duration")
    self.radius = self:GetAbility():GetSpecialValueFor("radius")

    self.pulses_affect = 0

    self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", PATTACH_WORLDORIGIN, self:GetCaster())
    ParticleManager:SetParticleControl(self.fx, 0,self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.fx, 1, Vector(self.radius, 0, 0))
    ParticleManager:SetParticleControl(self.fx, 2, Vector(self.duration, 0, 0))

    EmitSoundOn("Hero_Disruptor.StaticStorm", self:GetParent())
    self:StartIntervalThink(0.25)
end

function modifier_ability_disruptor_static_storm_thinker:OnIntervalThink()
    self.pulses_affect = self.pulses_affect + 1

    local all = FindUnitsInRadius(self:GetCaster():GetTeam(), 
    self:GetParent():GetAbsOrigin(), 
    nil, 
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER, 
    false)

    local damage = (self.damage_max / self.pulses) * self.pulses_affect

    for _,unit in ipairs(all) do
        local fx = ParticleManager:CreateParticle( "particles/units/heroes/hero_disruptor/disruptor_static_storm_bolt_hero.vpcf", PATTACH_OVERHEAD_FOLLOW, unit )

        ApplyDamage({
            victim = unit,
            attacker = self:GetCaster(),
            damage = damage,
            damage_type = self:GetAbility():GetAbilityDamageType(),
            ability = self:GetAbility()
        })
    end
end

function modifier_ability_disruptor_static_storm_thinker:OnDestroy()
    StopSoundEvent("Hero_Disruptor.StaticStorm", self:GetParent())
    EmitSoundOnLocationWithCaster(self:GetParent():GetAbsOrigin(), "Hero_Disruptor.StaticStorm.End", self:GetCaster())
end
end

--------------------------------------------------------------------------------


modifier_ability_disruptor_static_storm = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    CheckState              = function(self)
        return {
            [MODIFIER_STATE_SILENCED] = true,
        }
    end,
    GetEffectName           = function(self) return "particles/generic_gameplay/generic_silenced.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_OVERHEAD_FOLLOW end,
})


--------------------------------------------------------------------------------