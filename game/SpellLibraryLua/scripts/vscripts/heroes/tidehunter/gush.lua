LinkLuaModifier( "modifier_ability_tidehunter_gush", "heroes/tidehunter/gush" ,LUA_MODIFIER_MOTION_NONE )

if ability_tidehunter_gush == nil then
    ability_tidehunter_gush = class({})
end

--------------------------------------------------------------------------------

function ability_tidehunter_gush:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local projectile_speed = self:GetSpecialValueFor("projectile_speed")

    local info = {
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = "particles/units/heroes/hero_tidehunter/tidehunter_gush.vpcf",
        bDodgeable = true,
        bProvidesVision = false,
        iMoveSpeed = projectile_speed,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
    }
    ProjectileManager:CreateTrackingProjectile( info )

    EmitSoundOn("Ability.GushCast", caster)
end

function ability_tidehunter_gush:OnProjectileHit(Target, Location)
    if Target ~= nil and not Target:IsInvulnerable() and not Target:IsMagicImmune() then

        if Target:TriggerSpellAbsorb(self) then return false end

        local duration = self:GetDuration()

        EmitSoundOn("Ability.GushImpact", Target)


        Target:AddNewModifier( self:GetCaster(), self, "modifier_ability_tidehunter_gush", {duration=duration} )

        local damageTable = {
            victim = Target,
            attacker = self:GetCaster(), 
            damage = self:GetSpecialValueFor("gush_damage"),
            damage_type = self:GetAbilityDamageType(),
            ability = self
        }
    
        ApplyDamage(damageTable)  
    end
    return false
end

--------------------------------------------------------------------------------


modifier_ability_tidehunter_gush = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsPurgeException        = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS

        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_tidehunter/tidehunter_gush_slow.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
    GetStatusEffectName     = function(self) return "particles/status_fx/status_effect_gush.vpcf" end,
    StatusEffectPriority    = function(self) return 5 end,
})


--------------------------------------------------------------------------------

function modifier_ability_tidehunter_gush:OnCreated()
    self.movement_speed = self:GetAbility():GetSpecialValueFor("movement_speed")
    self.negative_armor = self:GetAbility():GetSpecialValueFor("negative_armor") * (-1)
end

function modifier_ability_tidehunter_gush:OnRefresh()
    self:OnCreated()
end

function modifier_ability_tidehunter_gush:GetModifierMoveSpeedBonus_Percentage() return self.movement_speed end
function modifier_ability_tidehunter_gush:GetModifierPhysicalArmorBonus() return self.negative_armor end