
LinkLuaModifier('modifier_abaddon_borrowed_time_lua_active', 'heroes/abaddon/borrowed_time', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ability_borrowed_time_passive', 'heroes/abaddon/borrowed_time', LUA_MODIFIER_MOTION_NONE)
ability_borrowed_time = class({})

function ability_borrowed_time:OnSpellStart()
    self:GetCaster():AddNewModifier(self:GetCaster(), self, 'modifier_abaddon_borrowed_time_lua_active', {
        duration = self:GetSpecialValueFor('duration')
    })
    self:GetCaster():EmitSound('Hero_Abaddon.BorrowedTime')
end

function ability_borrowed_time:GetIntrinsicModifierName()
    return 'modifier_ability_borrowed_time_passive'
end

modifier_ability_borrowed_time_passive = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    IsPermanent             = function(self) return true end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
        }
    end,
})

function modifier_ability_borrowed_time_passive:OnCreated(data)
    
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.hp_threshold = self.ability:GetSpecialValueFor('hp_threshold')
end

function modifier_ability_borrowed_time_passive:OnRefresh(data)
    self:OnCreated()
end

function modifier_ability_borrowed_time_passive:GetModifierIncomingDamage_Percentage(data)
    local health = self.parent:GetHealth()
    if health - data.damage <= self.hp_threshold and self.ability:IsCooldownReady() then 
        data.target:CastAbilityNoTarget(self.ability, self.parent:GetPlayerOwnerID())
        return -100
    end 

    return 0
end

modifier_abaddon_borrowed_time_lua_active = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    GetStatusEffectName     = function(self) return 'particles/status_fx/status_effect_abaddon_borrowed_time.vpcf' end,
    GetEffectName           = function(self) return 'particles/units/heroes/hero_abaddon/abaddon_borrowed_time.vpcf' end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN_FOLLOW end,
    StatusEffectPriority    = function(self) return MODIFIER_PRIORITY_HIGH end,
    DeclareFunctions        = function(self)
        return {
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
        }
    end,
})

function modifier_abaddon_borrowed_time_lua_active:GetModifierIncomingDamage_Percentage(data)

    self.parent:Heal(data.damage, self.parent)
    return -100
end

function modifier_abaddon_borrowed_time_lua_active:OnCreated()
    if IsClient() then return end
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.caster:Purge(false, true, true, true, false)
end


