LinkLuaModifier( "modifier_ability_disruptor_thunder_strike", "heroes/disruptor/thunder_strike" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_disruptor_thunder_strike_slow", "heroes/disruptor/thunder_strike" ,LUA_MODIFIER_MOTION_NONE )

if ability_disruptor_thunder_strike == nil then
    ability_disruptor_thunder_strike = class({})
end

--------------------------------------------------------------------------------

function ability_disruptor_thunder_strike:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if target:TriggerSpellAbsorb(self) then return end

    local strikes = self:GetSpecialValueFor("strikes")
    local strike_interval = self:GetSpecialValueFor("strike_interval")

    local duration = (strikes - 1) * strike_interval

    EmitSoundOn("Hero_Disruptor.ThunderStrike.Cast", caster)
    
    target:AddNewModifier(caster, self, "modifier_ability_disruptor_thunder_strike", {duration=duration})
end

--------------------------------------------------------------------------------


modifier_ability_disruptor_thunder_strike = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return false end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
        }
    end,
})


--------------------------------------------------------------------------------

if IsServer() then
function modifier_ability_disruptor_thunder_strike:OnCreated()
    self.slow_duration = self:GetAbility():GetSpecialValueFor("slow_duration")
    self.strike_damage = self:GetAbility():GetSpecialValueFor("strike_damage")
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
    self.strike_interval = self:GetAbility():GetSpecialValueFor("strike_interval")

    self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_buff.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    self:AddParticle(self.fx, false, false, -1, false, true)

    self:CreateThunderStrike()

    EmitSoundOn("Hero_Disruptor.ThunderStrike.Thunderator", self:GetParent())

    self:StartIntervalThink(self.strike_interval)
end

function modifier_ability_disruptor_thunder_strike:OnDestroy()
    AddFOWViewer(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), 450, 3.34, false)
end

function modifier_ability_disruptor_thunder_strike:OnIntervalThink()
    self:CreateThunderStrike()
end

function modifier_ability_disruptor_thunder_strike:CreateThunderStrike()
    local parent = self:GetParent()
    local caster = self:GetCaster()

    local all = FindUnitsInRadius(caster:GetTeam(), 
    parent:GetAbsOrigin(), 
    nil, 
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY, 
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER, 
    false)
    
    EmitSoundOn("Hero_Disruptor.ThunderStrike.Target", self:GetParent())

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(fx, 0, self:GetParent(), PATTACH_OVERHEAD_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(fx, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(fx, 2, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetParent():GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(fx)

    for _, unit in ipairs(all) do
        unit:AddNewModifier(caster, self:GetAbility(), "modifier_ability_disruptor_thunder_strike_slow", {duration=self.slow_duration})

        ApplyDamage({
            victim = unit,
            attacker = caster,
            damage = self.strike_damage,
            damage_type = self:GetAbility():GetAbilityDamageType(),
            ability = self:GetAbility()
        })
    end
end
end

function modifier_ability_disruptor_thunder_strike:GetModifierProvidesFOWVision() return 1 end

--------------------------------------------------------------------------------


modifier_ability_disruptor_thunder_strike_slow = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return false end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_disruptor_thunder_strike_slow:OnCreated(kv)
    self.slow_amount = self:GetAbility():GetSpecialValueFor("slow_amount")
    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_aoe.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_ability_disruptor_thunder_strike_slow:GetModifierMoveSpeedBonus_Percentage() return self.slow_amount * (-1) end
function modifier_ability_disruptor_thunder_strike_slow:GetModifierAttackSpeedBonus_Constant() return self.slow_amount * (-1) end