LinkLuaModifier( "modifier_ability_lina_fiery_soul", "heroes/lina/fiery_soul" ,LUA_MODIFIER_MOTION_NONE )

if ability_lina_fiery_soul == nil then
    ability_lina_fiery_soul = class({})
end

--------------------------------------------------------------------------------

function ability_lina_fiery_soul:GetIntrinsicModifierName()
    return "modifier_ability_lina_fiery_soul"
end

--------------------------------------------------------------------------------


modifier_ability_lina_fiery_soul = class({
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    AllowIllusionDuplicate  = function(self) return false end,
    DestroyOnExpire         = function(self) return false end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_EVENT_ON_ABILITY_EXECUTED,
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_lina_fiery_soul:OnRefresh()
    self.attack_speed_bonus = self:GetAbility():GetSpecialValueFor("fiery_soul_attack_speed_bonus")
    self.move_speed_bonus = self:GetAbility():GetSpecialValueFor("fiery_soul_move_speed_bonus")
    self.max_stacks = self:GetAbility():GetSpecialValueFor("fiery_soul_max_stacks")
    self.stack_duration = self:GetAbility():GetSpecialValueFor("fiery_soul_stack_duration")
end 

function modifier_ability_lina_fiery_soul:OnCreated()
    self.attack_speed_bonus = self:GetAbility():GetSpecialValueFor("fiery_soul_attack_speed_bonus")
    self.move_speed_bonus = self:GetAbility():GetSpecialValueFor("fiery_soul_move_speed_bonus")
    self.max_stacks = self:GetAbility():GetSpecialValueFor("fiery_soul_max_stacks")
    self.stack_duration = self:GetAbility():GetSpecialValueFor("fiery_soul_stack_duration")

    self:StartIntervalThink(0.03)
end

function modifier_ability_lina_fiery_soul:OnAbilityExecuted(k)
    local ability = k.ability
    local caster = k.unit
    if caster == self:GetCaster() then
        if not ability:IsItem() then
            if self:GetStackCount() < self.max_stacks then
                self:SetStackCount(self:GetStackCount()+1)
            end
            self:SetDuration(self.stack_duration, true)
        end
    end
end

function modifier_ability_lina_fiery_soul:OnIntervalThink()
    if self:GetRemainingTime() <= 0 and self:GetRemainingTime() > -1 then
        self:SetStackCount(0)
        self:SetDuration(-1, true)
    end
end

function modifier_ability_lina_fiery_soul:IsHidden()
    if self:GetStackCount() > 0 then
        return false
    end
    return true
end

function modifier_ability_lina_fiery_soul:GetModifierAttackSpeedBonus_Constant() return self.attack_speed_bonus * self:GetStackCount() end
function modifier_ability_lina_fiery_soul:GetModifierMoveSpeedBonus_Percentage() return self.move_speed_bonus * self:GetStackCount() end