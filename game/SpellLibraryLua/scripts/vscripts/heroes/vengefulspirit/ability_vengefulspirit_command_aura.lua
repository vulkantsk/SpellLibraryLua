LinkLuaModifier( "modifier_ability_vengefulspirit_command_aura", "heroes/vengefulspirit/ability_vengefulspirit_command_aura" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_vengefulspirit_command_aura_buff", "heroes/vengefulspirit/ability_vengefulspirit_command_aura" ,LUA_MODIFIER_MOTION_NONE )

if ability_vengefulspirit_command_aura == nil then
    ability_vengefulspirit_command_aura = class({})
end

--------------------------------------------------------------------------------

function ability_vengefulspirit_command_aura:GetIntrinsicModifierName()
    return "modifier_ability_vengefulspirit_command_aura"
end

function ability_vengefulspirit_command_aura:OnOwnerDied()
    if self:IsTrained() and not self:GetCaster():IsIllusion() and not self:GetCaster():PassivesDisabled() then
        local bounty_base = self:GetCaster():GetLevel() * 2
        
        local illusion = CreateIllusions(self:GetCaster(), self:GetCaster(), 
        {
            outgoing_damage             = 100 - self:GetSpecialValueFor("illusion_damage_out_pct"),
            incoming_damage             = self:GetSpecialValueFor("illusion_damage_in_pct") - 100,
            bounty_base                 = bounty_base,
            bounty_growth               = nil,
            outgoing_damage_structure   = nil,
            outgoing_damage_roshan      = nil,
            duration                    = nil
        }
        , 1, self:GetCaster():GetHullRadius(), true, true)
    
        for _, illus in pairs(illusion) do
            illus:SetHealth(illus:GetMaxHealth())
            illus:AddNewModifier(self:GetCaster(), self, "modifier_vengefulspirit_hybrid_special", {})
            FindClearSpaceForUnit(illus, self:GetCaster():GetAbsOrigin() + Vector(RandomInt(0, 1), RandomInt(0, 1), 0) * 108, true)
        end
    end
end

--------------------------------------------------------------------------------


modifier_ability_vengefulspirit_command_aura = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

function modifier_ability_vengefulspirit_command_aura:IsAura()
    return true
end

function modifier_ability_vengefulspirit_command_aura:GetModifierAura()
    return "modifier_ability_vengefulspirit_command_aura_buff"
end

function modifier_ability_vengefulspirit_command_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_ability_vengefulspirit_command_aura:GetAuraDuration()
    return 0.5
end

function modifier_ability_vengefulspirit_command_aura:GetAuraSearchTeam()    
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ability_vengefulspirit_command_aura:GetAuraSearchType()    
    return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_ability_vengefulspirit_command_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD
end

--------------------------------------------------------------------------------


modifier_ability_vengefulspirit_command_aura_buff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
            MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
            MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
            MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_vengefulspirit_command_aura_buff:GetModifierAttackRangeBonus()
    if self:GetParent():IsRangedAttacker() and self:GetAbility() then 
        return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
    end
    return
end

function modifier_ability_vengefulspirit_command_aura_buff:GetModifierBonusStats_Strength()
    if self:GetParent():GetPrimaryAttribute() == 0 and self:GetAbility() then 
        return self:GetAbility():GetSpecialValueFor("bonus_attributes")
    end
    return
end

function modifier_ability_vengefulspirit_command_aura_buff:GetModifierBonusStats_Agility()
    if self:GetParent():GetPrimaryAttribute() == 1 and self:GetAbility() then 
        return self:GetAbility():GetSpecialValueFor("bonus_attributes")
    end
    return
end

function modifier_ability_vengefulspirit_command_aura_buff:GetModifierBonusStats_Intellect()
    if self:GetParent():GetPrimaryAttribute() == 2 and self:GetAbility() then 
        return self:GetAbility():GetSpecialValueFor("bonus_attributes")
    end
    return
end