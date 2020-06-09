LinkLuaModifier( "modifier_ability_bloodseeker_rupture", "heroes/bloodseeker/rupture" ,LUA_MODIFIER_MOTION_NONE )

if ability_bloodseeker_rupture == nil then
    ability_bloodseeker_rupture = class({})
end

--------------------------------------------------------------------------------

function ability_bloodseeker_rupture:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if target:TriggerSpellAbsorb(self) then return end

    local duration = self:GetSpecialValueFor("duration")

    EmitSoundOn("hero_bloodseeker.rupture.cast", caster)
    EmitSoundOn("hero_bloodseeker.rupture", target)

    local particle = ParticleManager:CreateParticle("particles/abilities/rupture_burst.vpcf", PATTACH_POINT, target)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)

    target:AddNewModifier(caster, self, "modifier_ability_bloodseeker_rupture", {duration=duration})
end

--------------------------------------------------------------------------------


modifier_ability_bloodseeker_rupture = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    GetStatusEffectName     = function(self) return "particles/status_fx/status_effect_rupture.vpcf" end,
    HeroEffectPriority      = function(self) return 100 end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_bloodseeker_rupture:OnCreated()
    self:StartIntervalThink(0.25)
    EmitSoundOn("hero_bloodseeker.rupture_FP", self:GetParent())
end

function modifier_ability_bloodseeker_rupture:OnDestroy()
    StopSoundOn("hero_bloodseeker.rupture_FP", self:GetParent())
end

function modifier_ability_bloodseeker_rupture:OnIntervalThink()
    local caster = self:GetCaster()
    local target = self:GetParent()
        
    local newPos = target:GetAbsOrigin()
    if self.oldPos == nil then
        self.oldPos = newPos
    end

    local distance = (newPos - self.oldPos):Length2D()
    if distance > 0 and distance < 1300 then
        local particle = ParticleManager:CreateParticle("particles/abilities/rupture_burst.vpcf", PATTACH_POINT, target)
        ParticleManager:SetParticleControl(particle, 0, newPos)
        ParticleManager:ReleaseParticleIndex(particle)
        local damage = distance / 100 * self:GetAbility():GetSpecialValueFor("movement_damage_pct")
        ApplyDamage({
            victim = target,
            attacker = caster,
            damage = damage,
            damage_type = self:GetAbility():GetAbilityDamageType(),
            ability = self:GetAbility()
        })
    end
    self.oldPos = newPos
end
end
