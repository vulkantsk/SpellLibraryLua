LinkLuaModifier( "modifier_ability_viper_viper_strike", "heroes/viper/viper_strike" ,LUA_MODIFIER_MOTION_NONE )

if ability_viper_viper_strike == nil then
    ability_viper_viper_strike = class({})
end

--------------------------------------------------------------------------------

function ability_viper_viper_strike:OnAbilityPhaseStart()
    local caster = self:GetCaster()

    self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_viper/viper_viper_strike_warmup.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl( self.fx, 0, caster:GetAbsOrigin() )
    ParticleManager:SetParticleControlEnt(self.fx, 1, caster, PATTACH_POINT_FOLLOW, "attach_wing_barb_3", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.fx, 2, caster, PATTACH_POINT_FOLLOW, "attach_wing_barb_4", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.fx, 3, caster, PATTACH_POINT_FOLLOW, "attach_wing_barb_1", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(self.fx, 4, caster, PATTACH_POINT_FOLLOW, "attach_wing_barb_2", Vector(0,0,0), true)

    return true
end

function ability_viper_viper_strike:OnAbilityPhaseInterrupted()
    ParticleManager:DestroyParticle(self.fx, false)
end

function ability_viper_viper_strike:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local projectile_speed = self:GetSpecialValueFor("projectile_speed")

    local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_viper/viper_viper_strike_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl( fx, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( fx, 6, Vector( projectile_speed, 0, 0 ) )
    ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(fx, 2, caster, PATTACH_POINT_FOLLOW, "attach_wing_barb_3", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(fx, 3, caster, PATTACH_POINT_FOLLOW, "attach_wing_barb_4", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(fx, 4, caster, PATTACH_POINT_FOLLOW, "attach_wing_barb_1", Vector(0,0,0), true)
    ParticleManager:SetParticleControlEnt(fx, 5, caster, PATTACH_POINT_FOLLOW, "attach_wing_barb_2", Vector(0,0,0), true)

    local info = {
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = "",
        bDodgeable = true,
        bProvidesVision = false,
        iMoveSpeed = projectile_speed,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        ExtraData = {
            effect = fx,
        }
    }
    ProjectileManager:CreateTrackingProjectile( info )

    EmitSoundOn("hero_viper.viperStrike", caster)
end

function ability_viper_viper_strike:OnProjectileHit_ExtraData( target, location, ExtraData )

    ParticleManager:DestroyParticle(ExtraData.effect, false)
    ParticleManager:ReleaseParticleIndex(ExtraData.effect)

    if not target then return end

    if target:TriggerSpellAbsorb( self ) then return end

    local duration = self:GetSpecialValueFor( "duration" )

    target:AddNewModifier(self:GetCaster(), self, "modifier_ability_viper_viper_strike", {duration=duration})

    local sound_cast = "hero_viper.viperStrikeImpact"
    EmitSoundOn( sound_cast, target )
end

--------------------------------------------------------------------------------


modifier_ability_viper_viper_strike = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_viper/viper_viper_strike_debuff.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
    GetStatusEffectName     = function(self) return "particles/status_fx/status_effect_poison_viper.vpcf" end,
    StatusEffectPriority    = function(self) return MODIFIER_PRIORITY_HIGH end,
})


--------------------------------------------------------------------------------

function modifier_ability_viper_viper_strike:OnCreated()
    self.damage = self:GetAbility():GetSpecialValueFor("damage")
    self.bonus_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
    self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed")

    self.start_time = GameRules:GetGameTime()
    self.duration = self:GetDuration()
    self.ticks = 0

    if not IsServer() then return end

    self:StartIntervalThink(1.0)
    self:OnIntervalThink()
end

function modifier_ability_viper_viper_strike:OnRefresh()
    self:OnCreated()
end

if IsServer() then
function modifier_ability_viper_viper_strike:OnIntervalThink()
    self.ticks = self.ticks + 1
    if self.ticks <= 5 then
        ApplyDamage({
            victim = self:GetParent(),
            attacker = self:GetCaster(),
            damage = self.damage,
            damage_type = self:GetAbility():GetAbilityDamageType(),
            ability = self:GetAbility()
        })

        SendOverheadEventMessage( self:GetParent(), OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, self:GetParent(), self.damage, nil )
    end
end
end

function modifier_ability_viper_viper_strike:GetModifierMoveSpeedBonus_Percentage()
    return self.bonus_movement_speed * ( 1 - ( GameRules:GetGameTime()-self.start_time )/self.duration )
end
function modifier_ability_viper_viper_strike:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_attack_speed * ( 1 - ( GameRules:GetGameTime()-self.start_time )/self.duration )
end