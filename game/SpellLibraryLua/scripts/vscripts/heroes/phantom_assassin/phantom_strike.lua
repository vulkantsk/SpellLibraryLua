LinkLuaModifier( "modifier_ability_phantom_assassin_phantom_strike", "heroes/phantom_assassin/phantom_strike" ,LUA_MODIFIER_MOTION_NONE )

if ability_phantom_assassin_phantom_strike == nil then
    ability_phantom_assassin_phantom_strike = class({})
end

--------------------------------------------------------------------------------

function ability_phantom_assassin_phantom_strike:CastFilterResultTarget(target)
    if target == self:GetCaster() then
        return UF_FAIL_CUSTOM
    else
        return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())
    end
end

function ability_phantom_assassin_phantom_strike:GetCustomCastErrorTarget(target)
    if target == self:GetCaster() then
        return "#dota_hud_error_cant_cast_on_self"
    end
end

function ability_phantom_assassin_phantom_strike:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if target:TriggerSpellAbsorb(self) then return end

    local duration = self:GetSpecialValueFor("duration")

    EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_PhantomAssassin.Strike.Start", caster)

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_phantom_strike_start.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:ReleaseParticleIndex(fx)

    local point = target:GetAbsOrigin() + (caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized() * 50
    FindClearSpaceForUnit(caster, point, false)

    if target:GetTeamNumber() ~= caster:GetTeamNumber() then
        caster:AddNewModifier(caster, self, "modifier_ability_phantom_assassin_phantom_strike", {duration=duration})
    end

    EmitSoundOnLocationWithCaster(point, "Hero_PhantomAssassin.Strike.End", caster)

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_phantom_strike_end.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(fx, 0, point)
    ParticleManager:ReleaseParticleIndex(fx)

    ExecuteOrderFromTable({
        UnitIndex = caster:entindex(),
        OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
        TargetIndex = target:entindex(),
        Queue = false,
    })
end

--------------------------------------------------------------------------------


modifier_ability_phantom_assassin_phantom_strike = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_phantom_assassin_phantom_strike:OnCreated()
    self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_ability_phantom_assassin_phantom_strike:OnRefresh()
    self:OnCreated()
end

function modifier_ability_phantom_assassin_phantom_strike:GetModifierAttackSpeedBonus_Constant() return self.bonus_attack_speed end