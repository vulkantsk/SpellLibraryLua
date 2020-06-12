LinkLuaModifier( "modifier_ability_lina_laguna_blade", "heroes/lina/laguna_blade" ,LUA_MODIFIER_MOTION_NONE )

if ability_lina_laguna_blade == nil then
    ability_lina_laguna_blade = class({})
end

--------------------------------------------------------------------------------

function ability_lina_laguna_blade:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local damage_delay = self:GetSpecialValueFor("damage_delay")

    caster:EmitSound("Ability.LagunaBlade")

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_laguna_blade.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(fx)

    if target:TriggerSpellAbsorb(self) then return end
    
    EmitSoundOn("Ability.LagunaBladeImpact", target)
    target:AddNewModifier(caster, self, "modifier_ability_lina_laguna_blade", {duration=damage_delay})
end

--------------------------------------------------------------------------------


modifier_ability_lina_laguna_blade = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    GetAttributes           = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_lina_laguna_blade:OnRefresh()
    self:OnCreated()
end 

function modifier_ability_lina_laguna_blade:OnCreated()
    self.damage = self:GetAbility():GetSpecialValueFor("damage")
end

function modifier_ability_lina_laguna_blade:OnDestroy()
    if not self:GetParent():IsMagicImmune() and not self:GetParent():IsInvulnerable() and not self:GetParent():IsOutOfGame() then
        ApplyDamage({
            victim = self:GetParent(),
            attacker = self:GetCaster(),
            damage = self.damage,
            damage_type = self:GetAbility():GetAbilityDamageType(),
            ability = self:GetAbility()
        })
    end
end
end
