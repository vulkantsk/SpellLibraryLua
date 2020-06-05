ability_chemical_rage = class({})
LinkLuaModifier('modifier_ability_chemical_rage_lua', 'heroes/alchemist/chemical_rage', LUA_MODIFIER_MOTION_NONE)
function ability_chemical_rage:OnSpellStart()
    self:GetCaster():AddNewModifier(self:GetCaster(),self,'modifier_ability_chemical_rage_lua',{duration = self:GetSpecialValueFor('duration')})
end 

modifier_ability_chemical_rage_lua = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    AllowIllusionDuplicate  = function(self) return true end,
    IsPermanent             = function(self) return true end,
    DeclareFunctions        = function(self) return {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    } end,
    GetOverrideAnimation                = function(self) return ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_START end,
    GetModifierConstantHealthRegen      = function(self) return self.regen end,
    GetModifierBaseAttackTimeConstant   = function(self) return self.baseAttackSpeed end,
    GetModifierMoveSpeedBonus_Constant  = function(self) return self.bonus_movespeed end,
})

function modifier_ability_chemical_rage_lua:OnCreated()

    local ability = self:GetAbility()
    self.regen = ability:GetSpecialValueFor('bonus_health_regen')
    self.baseAttackSpeed = ability:GetSpecialValueFor('base_attack_time')
    self.bonus_movespeed = ability:GetSpecialValueFor('bonus_movespeed')
    self:GetParent():EmitSound('Hero_Alchemist.ChemicalRage.Cast')
    self:GetParent():EmitSound('Hero_Alchemist.ChemicalRage')
end 

function modifier_ability_chemical_rage_lua:OnCreated()
    if IsClient() then return end
    self:GetParent():StopSound('Hero_Alchemist.ChemicalRage')
end