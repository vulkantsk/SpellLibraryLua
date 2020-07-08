LinkLuaModifier( "modifier_ability_lion_mana_drain", "heroes/lion/mana_drain" ,LUA_MODIFIER_MOTION_NONE )

if ability_lion_mana_drain == nil then
    ability_lion_mana_drain = class({})
end

--------------------------------------------------------------------------------

function ability_lion_mana_drain:CastFilterResultTarget(target)
    local caster = self:GetCaster()

    if target:GetTeamNumber() == caster:GetTeamNumber() then
        return UF_FAIL_FRIENDLY
    end

    if target:GetMaxMana() == 0 then
        return UF_FAIL_CUSTOM
    end

    local nResult = UnitFilter( target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, self:GetCaster():GetTeamNumber() )
    return nResult
end

function ability_lion_mana_drain:GetCustomCastErrorTarget(target)
    if target:GetMaxMana() == 0 then
        return "dota_hud_error_only_cast_mana_units"
    end
end

function ability_lion_mana_drain:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")

    if target:TriggerSpellAbsorb(self) then caster:Interrupt() return end

    EmitSoundOn("Hero_Lion.ManaDrain", target)

    target:AddNewModifier(caster, self, "modifier_ability_lion_mana_drain", {duration=duration})
end

--------------------------------------------------------------------------------


modifier_ability_lion_mana_drain = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_lion_mana_drain:OnCreated()
    self.movespeed = self:GetAbility():GetSpecialValueFor("movespeed")
    self.tick_interval = self:GetAbility():GetSpecialValueFor("tick_interval")
    self.mana_per_second = self:GetAbility():GetSpecialValueFor("mana_per_second")
    self.break_distance = self:GetAbility():GetSpecialValueFor("break_distance")

    self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lion/lion_spell_mana_drain.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt(self.fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)        
    ParticleManager:SetParticleControlEnt(self.fx, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_mouth", self:GetCaster():GetAbsOrigin(), true)        
    self:AddParticle(self.fx, false, false, -1, false, false)

    self:StartIntervalThink(self.tick_interval)
end

if IsServer() then
function modifier_ability_lion_mana_drain:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    if parent:IsIllusion() then parent:Kill(self:GetAbility(), caster) return end

    if not self:GetAbility():IsChanneling() then self:Destroy() return end

    local TargetMana = parent:GetMana()
    if TargetMana == 0 then self:Destroy() return end

    local distance = (parent:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()

    if distance > self.break_distance then self:Destroy() return end

    if UnitFilter(
        parent, 
        DOTA_UNIT_TARGET_TEAM_ENEMY, 
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, 
        caster:GetTeamNumber()
    ) ~= 0 then self:Destroy() return end

    local mana = self.mana_per_second * self.tick_interval
    parent:ReduceMana(mana)
    caster:GiveMana(mana)
end

function modifier_ability_lion_mana_drain:OnDestroy()
    self:GetCaster():InterruptChannel()
    StopSoundOn("Hero_Lion.ManaDrain", self:GetParent())
end
end

function modifier_ability_lion_mana_drain:GetModifierMoveSpeedBonus_Percentage() return self.movespeed * (-1) end