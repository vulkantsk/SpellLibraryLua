LinkLuaModifier( "modifier_ability_omniknight_degen_aura", "heroes/omniknight/degen_aura" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_omniknight_degen_aura_slow", "heroes/omniknight/degen_aura" ,LUA_MODIFIER_MOTION_NONE )

if ability_omniknight_degen_aura == nil then
    ability_omniknight_degen_aura = class({})
end

--------------------------------------------------------------------------------

function ability_omniknight_degen_aura:GetIntrinsicModifierName()
    return "modifier_ability_omniknight_degen_aura"
end

--------------------------------------------------------------------------------


modifier_ability_omniknight_degen_aura = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
})


--------------------------------------------------------------------------------

function modifier_ability_omniknight_degen_aura:IsAura()
    return true
end

function modifier_ability_omniknight_degen_aura:GetModifierAura()
    return "modifier_ability_omniknight_degen_aura_slow"
end

function modifier_ability_omniknight_degen_aura:GetAuraRadius()
    return self.radius
end

function modifier_ability_omniknight_degen_aura:GetAuraSearchTeam()    
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_omniknight_degen_aura:GetAuraDuration()    
    return 1.0
end

function modifier_ability_omniknight_degen_aura:GetAuraSearchType()    
    return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_ability_omniknight_degen_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_ability_omniknight_degen_aura:OnCreated()
    self.radius = self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_ability_omniknight_degen_aura:OnRefresh()
    self:OnCreated()
end

--------------------------------------------------------------------------------


modifier_ability_omniknight_degen_aura_slow = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsPurgeException        = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
        }
    end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_omniknight/omniknight_degen_aura_debuff.vpcf" end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
})


--------------------------------------------------------------------------------

function modifier_ability_omniknight_degen_aura_slow:OnCreated()
    self.speed_bonus = self:GetAbility():GetSpecialValueFor("speed_bonus") * (-1)
end

function modifier_ability_omniknight_degen_aura_slow:OnRefresh()
    self:OnCreated()
end

function modifier_ability_omniknight_degen_aura_slow:GetModifierMoveSpeedBonus_Percentage() return self.speed_bonus end