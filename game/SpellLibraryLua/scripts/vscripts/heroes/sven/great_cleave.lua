LinkLuaModifier( "modifier_ability_sven_great_cleave", "heroes/sven/great_cleave" ,LUA_MODIFIER_MOTION_NONE )

if ability_sven_great_cleave == nil then
    ability_sven_great_cleave = class({})
end

--------------------------------------------------------------------------------

function ability_sven_great_cleave:GetIntrinsicModifierName()
    return "modifier_ability_sven_great_cleave"
end

--------------------------------------------------------------------------------


modifier_ability_sven_great_cleave = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return false end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_EVENT_ON_ATTACK_LANDED
        }
    end,
})


--------------------------------------------------------------------------------

function modifier_ability_sven_great_cleave:OnRefresh()
    self:OnCreated()
end 

function modifier_ability_sven_great_cleave:OnCreated()
    self.cleave_starting_width = self:GetAbility():GetSpecialValueFor("cleave_starting_width")
    self.cleave_ending_width = self:GetAbility():GetSpecialValueFor("cleave_ending_width")
    self.cleave_distance = self:GetAbility():GetSpecialValueFor("cleave_distance")
    self.great_cleave_damage = self:GetAbility():GetSpecialValueFor("great_cleave_damage")
end

function modifier_ability_sven_great_cleave:OnAttackLanded(k)
    local caster = self:GetParent()
    local target = k.target
    local attacker = k.attacker
    if caster == attacker and not caster:PassivesDisabled() then
        local fx = "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"
        DoCleaveAttack(caster, target, self:GetAbility(), self.great_cleave_damage, self.cleave_starting_width, self.cleave_ending_width, self.cleave_distance, fx)
    end
end