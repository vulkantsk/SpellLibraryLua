LinkLuaModifier( "modifier_ability_sniper_headshot", "heroes/sniper/headshot" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_sniper_headshot_slow", "heroes/sniper/headshot" ,LUA_MODIFIER_MOTION_NONE )

if ability_sniper_headshot == nil then
    ability_sniper_headshot = class({})
end

--------------------------------------------------------------------------------

function ability_sniper_headshot:GetIntrinsicModifierName()
    return "modifier_ability_sniper_headshot"
end

--------------------------------------------------------------------------------


modifier_ability_sniper_headshot = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_sniper_headshot:OnRefresh()
    self:OnCreated()
end

function modifier_ability_sniper_headshot:OnCreated()
    self.proc_chance = self:GetAbility():GetSpecialValueFor("proc_chance")
    self.knockback_distance = self:GetAbility():GetSpecialValueFor("knockback_distance")
    self.slow_duration = self:GetAbility():GetSpecialValueFor("slow_duration")
end

function modifier_ability_sniper_headshot:GetModifierProcAttack_BonusDamage_Physical(k) 
    local target = k.target
    local attacker = k.attacker
    local caster = self:GetCaster()
    if attacker == caster and not caster:PassivesDisabled() and RollPseudoRandomPercentage(self.proc_chance, 1, caster) and not target:IsOther() and not target:IsBuilding() then
        local knockbackProperties =
        {
            center_x = caster:GetAbsOrigin().x,
            center_y = caster:GetAbsOrigin().y,
            center_z = caster:GetAbsOrigin().z,
            duration = 0.1,
            knockback_duration = 0.1,
            knockback_distance = self.knockback_distance,
            knockback_height = 0
        }

        target:AddNewModifier( caster, self:GetAbility(), "modifier_knockback", knockbackProperties )
        target:AddNewModifier( caster, self:GetAbility(), "modifier_ability_sniper_headshot_slow", {duration=self.slow_duration} )

        if IsServer() then
            self.damage = self:GetAbility():GetAbilityDamage()
            return self.damage
        end
    end
    return
end

--------------------------------------------------------------------------------


modifier_ability_sniper_headshot_slow = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return true end,
    IsPurgeException        = function(self) return true end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_sniper_headshot_slow:OnCreated()
    self.slow = self:GetAbility():GetSpecialValueFor("slow")

    if IsServer() then
        local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sniper/sniper_headshot_slow.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(fx, 0, self:GetParent():GetAbsOrigin())
        self:AddParticle(fx, false, false, -1, false, true)
    end
end

function modifier_ability_sniper_headshot_slow:GetModifierMoveSpeedBonus_Percentage() return self.slow end
function modifier_ability_sniper_headshot_slow:GetModifierAttackSpeedBonus_Constant() return self.slow end