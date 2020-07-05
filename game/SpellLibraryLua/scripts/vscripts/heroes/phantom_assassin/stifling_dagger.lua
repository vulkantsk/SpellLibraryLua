LinkLuaModifier( "modifier_ability_phantom_assassin_stifling_dagger_debuff", "heroes/phantom_assassin/stifling_dagger" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_phantom_assassin_stifling_dagger_target_debuff", "heroes/phantom_assassin/stifling_dagger" ,LUA_MODIFIER_MOTION_NONE )

if ability_phantom_assassin_stifling_dagger == nil then
    ability_phantom_assassin_stifling_dagger = class({})
end

--------------------------------------------------------------------------------

function ability_phantom_assassin_stifling_dagger:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local info = {
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf",
        bDodgeable = true,
        bProvidesVision = true,
        iMoveSpeed = self:GetSpecialValueFor("dagger_speed"),
        iVisionRadius = 450,
        iVisionTeamNumber = caster:GetTeamNumber(),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
    }
    ProjectileManager:CreateTrackingProjectile( info )
    EmitSoundOn("Hero_PhantomAssassin.Dagger.Cast", caster)
end

function ability_phantom_assassin_stifling_dagger:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() then

        if Target:TriggerSpellAbsorb(self) then return end

        EmitSoundOn("Hero_PhantomAssassin.Dagger.Target", Target)
        local oldForward =  self:GetCaster():GetForwardVector()
        local pos = self:GetCaster():GetAbsOrigin()
        local point = Target:GetAbsOrigin() + (self:GetCaster():GetAbsOrigin() - Target:GetAbsOrigin()):Normalized() * 100
        local forward = (Target:GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Normalized()
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_ability_phantom_assassin_stifling_dagger_debuff", {})

        if not Target:IsMagicImmune() then
            local duration = self:GetSpecialValueFor("duration")
            Target:AddNewModifier(self:GetCaster(), self, "modifier_ability_phantom_assassin_stifling_dagger_target_debuff", {Duration=duration})
        end
        self:GetCaster():SetForwardVector(forward)
        self:GetCaster():SetAbsOrigin(point)
        self:GetCaster():PerformAttack(Target, true, true, true, false, false, false, true)
        self:GetCaster():SetAbsOrigin(pos)
        self:GetCaster():SetForwardVector(oldForward)
        self:GetCaster():RemoveModifierByName("modifier_ability_phantom_assassin_stifling_dagger_debuff")
        AddFOWViewer(self:GetCaster():GetTeamNumber(), Target:GetAbsOrigin(), 450, 3.34, false)
    end
    return true
end

--------------------------------------------------------------------------------


modifier_ability_phantom_assassin_stifling_dagger_debuff = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
            MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_phantom_assassin_stifling_dagger_debuff:OnCreated()
    self.damage_reduce = self:GetAbility():GetSpecialValueFor("attack_factor")
    self.base_damage = self:GetAbility():GetSpecialValueFor("base_damage")
end

function modifier_ability_phantom_assassin_stifling_dagger_debuff:OnRefresh()
    self:OnCreated()
end

function modifier_ability_phantom_assassin_stifling_dagger_debuff:GetModifierDamageOutgoing_Percentage() return self.damage_reduce end
function modifier_ability_phantom_assassin_stifling_dagger_debuff:GetModifierProcAttack_BonusDamage_Physical() return self.base_damage end


--------------------------------------------------------------------------------


modifier_ability_phantom_assassin_stifling_dagger_target_debuff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger_debuff.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
})


--------------------------------------------------------------------------------

function modifier_ability_phantom_assassin_stifling_dagger_target_debuff:OnCreated()
    self.move_slow = self:GetAbility():GetSpecialValueFor("move_slow")
end

function modifier_ability_phantom_assassin_stifling_dagger_target_debuff:OnRefresh()
    self:OnCreated()
end

function modifier_ability_phantom_assassin_stifling_dagger_target_debuff:GetModifierMoveSpeedBonus_Percentage() return self.move_slow end