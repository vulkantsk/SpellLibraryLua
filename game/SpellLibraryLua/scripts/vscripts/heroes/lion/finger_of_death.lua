LinkLuaModifier( "modifier_ability_lion_finger_of_death_delay", "heroes/lion/finger_of_death" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_lion_finger_of_death", "heroes/lion/finger_of_death" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_lion_finger_of_death_counter", "heroes/lion/finger_of_death" ,LUA_MODIFIER_MOTION_NONE )

if ability_lion_finger_of_death == nil then
    ability_lion_finger_of_death = class({})
end

--------------------------------------------------------------------------------

function ability_lion_finger_of_death:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local damage_delay = self:GetSpecialValueFor("damage_delay")

    EmitSoundOn("Hero_Lion.FingerOfDeath", caster)

    local direction = (caster:GetOrigin() - target:GetOrigin()):Normalized()

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lion/lion_spell_finger_of_death.vpcf", PATTACH_POINT_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl( fx, 2, target:GetOrigin() )
    ParticleManager:SetParticleControl( fx, 3, target:GetOrigin() + direction )
    ParticleManager:SetParticleControlForward( fx, 3, -direction )
    ParticleManager:ReleaseParticleIndex(fx)   

    if target:TriggerSpellAbsorb(self) then return end

    target:AddNewModifier(caster, self, "modifier_ability_lion_finger_of_death_delay", {duration=damage_delay})
end

function ability_lion_finger_of_death:GetIntrinsicModifierName()
    return "modifier_ability_lion_finger_of_death_counter"
end

--------------------------------------------------------------------------------


modifier_ability_lion_finger_of_death_counter = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    GetAttributes           = function(self) return MODIFIER_ATTRIBUTE_PERMANENT end
})


--------------------------------------------------------------------------------

--------------------------------------------------------------------------------


modifier_ability_lion_finger_of_death_delay = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_lion_finger_of_death_delay:OnDestroy()
    if self:GetParent():IsMagicImmune() or self:GetParent():IsInvulnerable() or self:GetParent():IsOutOfGame() then return end
    
    self.damage = self:GetAbility():GetSpecialValueFor("damage")
    self.damage_per_kill = self:GetAbility():GetSpecialValueFor("damage_per_kill")
    self.grace_period = self:GetAbility():GetSpecialValueFor("grace_period")

    local damage = self.damage + (self.damage_per_kill * self:GetCaster():FindModifierByName("modifier_ability_lion_finger_of_death_counter"):GetStackCount())
    if self:GetCaster():HasModifier("modifier_ability_lion_finger_of_death_counter") then
        local modif = self:GetCaster():FindModifierByName("modifier_ability_lion_finger_of_death_counter")
        damage = damage + (self.damage_per_kill * modif:GetStackCount())
    end

    EmitSoundOn("Hero_Lion.FingerOfDeathImpact", self:GetParent())

    self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_ability_lion_finger_of_death", {duration=self.grace_period})

    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = damage,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility()
    })
end
end

--------------------------------------------------------------------------------


modifier_ability_lion_finger_of_death = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_lion_finger_of_death:OnDestroy()
    if not self:GetParent():IsAlive() then
        self:GetCaster():FindModifierByName("modifier_ability_lion_finger_of_death_counter"):IncrementStackCount()
    end
end
end



