ability_enfeeble = class({})

function ability_enfeeble:GetIntrinsicModifierName()
    return 'modifier_ability_enfeeble_buff'
end 

LinkLuaModifier( "modifier_ability_enfeeble_buff", "heroes/bane/enfeeble", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_enfeeble_debuff", "heroes/bane/enfeeble", LUA_MODIFIER_MOTION_NONE )
modifier_ability_enfeeble_buff = class({
    IsPurgable  = function(self) return false end,
    IsHidden    = function(self) return true end,

    DeclareFunctions = function(self)
        return {
            MODIFIER_EVENT_ON_ABILITY_EXECUTED
        }
    end,
})

function modifier_ability_enfeeble_buff:OnAbilityExecuted(keys)
    DeepPrintTable(keys)

	if keys.ability and keys.target and keys.unit == self:GetParent() and not self:GetParent():PassivesDisabled() and not keys.ability:IsItem() then
        keys.target:AddNewModifier(keys.unit, self:GetAbility(), 'modifier_ability_enfeeble_debuff', {
            duration = self:GetAbility():GetSpecialValueFor('duration')
        })
	end
end

modifier_ability_enfeeble_debuff = class({
    IsPurgable  = function(self) return false end,
    DeclareFunctions    = function(self)
        return {
            MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
            MODIFIER_PROPERTY_STATUS_RESISTANCE,

        }
    end,

    GetEffectAttachType     = function(self) return PATTACH_OVERHEAD_FOLLOW end,
    GetEffectName           = function(self) return 'particles/units/heroes/hero_bane/bane_enfeeble.vpcf' end,
})

function modifier_ability_enfeeble_debuff:GetModifierMagicalResistanceBonus()
    return self.magic_resistance_reduction
end

function modifier_ability_enfeeble_debuff:GetModifierStatusResistance()
    return self.status_resistance_reduction
end

function modifier_ability_enfeeble_debuff:OnCreated()
    self.status_resistance_reduction = -self:GetAbility():GetSpecialValueFor('status_resistance_reduction')
    self.magic_resistance_reduction = -self:GetAbility():GetSpecialValueFor('magic_resistance_reduction')
end 

function modifier_ability_enfeeble_debuff:OnRefresh()
    self:OnCreated()
end 