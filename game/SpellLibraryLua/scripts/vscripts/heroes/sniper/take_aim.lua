LinkLuaModifier( "modifier_ability_sniper_take_aim", "heroes/sniper/take_aim" ,LUA_MODIFIER_MOTION_NONE )

if ability_sniper_take_aim == nil then
    ability_sniper_take_aim = class({})
end

--------------------------------------------------------------------------------

function ability_sniper_take_aim:OnSpellStart()
    local caster = self:GetCaster()

    self:SetActivated(false)
    self:EndCooldown()

    local modif = caster:FindModifierByName("modifier_ability_sniper_take_aim")
    if modif then
        modif:SetStackCount(0)
    end
end

function ability_sniper_take_aim:GetIntrinsicModifierName()
    return "modifier_ability_sniper_take_aim"
end

--------------------------------------------------------------------------------


modifier_ability_sniper_take_aim = class({
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
            MODIFIER_EVENT_ON_ATTACK
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_sniper_take_aim:IsHidden() 
    if self:GetStackCount() == 0 then
        return false
    else
        return true
    end
end

function modifier_ability_sniper_take_aim:GetModifierAttackRangeBonus() 
    if not self:GetParent():PassivesDisabled() then
        if self:GetStackCount() == 0 then
            return self.bonus_attack_range * self.multiplier 
        else
            return self.bonus_attack_range
        end
    end
    return
end

function modifier_ability_sniper_take_aim:OnCreated()
    self.bonus_attack_range = self:GetAbility():GetSpecialValueFor("bonus_attack_range")
    self.multiplier = self:GetAbility():GetSpecialValueFor("active_attack_range_multiplier")
    self:SetStackCount(1)
end

function modifier_ability_sniper_take_aim:OnRefresh()
    self.bonus_attack_range = self:GetAbility():GetSpecialValueFor("bonus_attack_range")
    self.multiplier = self:GetAbility():GetSpecialValueFor("active_attack_range_multiplier")
end

function modifier_ability_sniper_take_aim:OnAttack(keys)
    local attacker = keys.attacker
    if self:GetCaster() == attacker then
        if self:GetStackCount() == 0 and self:GetAbility():IsCooldownReady() then
            self:GetAbility():UseResources(false, false, true)
            self:GetAbility():SetActivated(true)
            self:SetStackCount(1)
        end
    end
end