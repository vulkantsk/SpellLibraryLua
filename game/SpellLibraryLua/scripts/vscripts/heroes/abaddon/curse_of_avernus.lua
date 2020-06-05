ability_curse_of_avernus = class({})

function ability_curse_of_avernus:GetIntrinsicModifierName() 
    return 'modifier_ability_curse_of_avernus_lua'
end

LinkLuaModifier('modifier_ability_curse_of_avernus_lua_debuff', 'heroes/abaddon/curse_of_avernus', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ability_curse_of_avernus_lua_buff', 'heroes/abaddon/curse_of_avernus', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ability_curse_of_avernus_lua_debuff_visible', 'heroes/abaddon/curse_of_avernus', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ability_curse_of_avernus_lua', 'heroes/abaddon/curse_of_avernus', LUA_MODIFIER_MOTION_NONE)
modifier_ability_curse_of_avernus_lua = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    IsPermanent             = function(self) return true end,
    DeclareFunctions        = function(self) return {MODIFIER_EVENT_ON_ATTACK_LANDED} end,
})

function modifier_ability_curse_of_avernus_lua:OnCreated()
    self.parent = self:GetParent()
end

function modifier_ability_curse_of_avernus_lua:OnAttackLanded(data)
    if IsClient() then return end
    if data.attacker ~= self.parent or data.target:HasModifier('modifier_ability_curse_of_avernus_lua_debuff') then return end
    local modifier = data.target:AddNewModifier(self:GetCaster(), self:GetAbility(), 'modifier_ability_curse_of_avernus_lua_debuff_visible', {duration = self:GetAbility():GetSpecialValueFor('curse_duration')})
    modifier:SetStackCount(modifier:GetStackCount() + 1)
    modifier:UpdateCounter()
    if modifier:GetStackCount() >= self:GetAbility():GetSpecialValueFor('hit_count') then 
        modifier:Destroy()
        data.attacker:AddNewModifier(self:GetCaster(), self:GetAbility(), 'modifier_ability_curse_of_avernus_lua_buff', {
            duration = self:GetAbility():GetSpecialValueFor('curse_duration')
        }):SetStackCount(self:GetAbility():GetSpecialValueFor('curse_attack_speed'))
        data.target:AddNewModifier(self:GetCaster(), self:GetAbility(), 'modifier_ability_curse_of_avernus_lua_debuff', {
            duration = self:GetAbility():GetSpecialValueFor('slow_duration')
        })
        data.target:EmitSound('Hero_Abaddon.Curse.Proc')
    end
end

modifier_ability_curse_of_avernus_lua_buff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    DeclareFunctions        = function(self) return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT} end,
    GetModifierAttackSpeedBonus_Constant = function(self) return self:GetStackCount() end,
})

modifier_ability_curse_of_avernus_lua_debuff = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,
    GetStatusEffectName     = function(self) return 'particles/status_fx/status_effect_abaddon_frostmourne.vpcf' end,
    GetEffectName           = function(self) return 'particles/units/heroes/hero_abaddon/abaddon_curse_frostmourne_debuff.vpcf' end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN end,
    StatusEffectPriority    = function(self) return 20000 end,
    CheckState              = function(self) return {[MODIFIER_STATE_SILENCED] = true, } end,
    DeclareFunctions        = function(self) return {MODIFIER_EVENT_ON_ATTACK_LANDED,MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE} end,
    GetModifierMoveSpeedBonus_Percentage = function(self) return self.slow end,
})

function modifier_ability_curse_of_avernus_lua_debuff:OnCreated(data)
    if IsClient() then return end
    self.slow = -self:GetAbility():GetSpecialValueFor('movement_speed')
end

function modifier_ability_curse_of_avernus_lua_debuff:OnAttackLanded(data)
    if IsClient() then return end
    if data.attacker:IsHero() and data.target == self:GetParent() then 
        data.attacker:AddNewModifier(self:GetCaster(), self:GetAbility(), 'modifier_ability_curse_of_avernus_lua_buff', {
            duration = self:GetAbility():GetSpecialValueFor('curse_duration')
        }):SetStackCount(self:GetAbility():GetSpecialValueFor('curse_attack_speed'))
    end
end

modifier_ability_curse_of_avernus_lua_debuff_visible = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return true end,
    IsBuff                  = function(self) return false end,
    RemoveOnDeath           = function(self) return true end,  
    GetEffectName           = function(self) return 'particles/units/heroes/hero_abaddon/abaddon_curse_frostmourne_debuff_frost.vpcf' end,
    GetEffectAttachType     = function(self) return PATTACH_ABSORIGIN end,

})

function modifier_ability_curse_of_avernus_lua_debuff_visible:OnCreated()
    if IsClient() then return end

    self.nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf', PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.nfx, 1, Vector(0,1,0))
end

function modifier_ability_curse_of_avernus_lua_debuff_visible:OnDestroy()
    if IsClient() then return end

    ParticleManager:DestroyParticle(self.nfx, true)
    ParticleManager:ReleaseParticleIndex(self.nfx)
end

function modifier_ability_curse_of_avernus_lua_debuff_visible:UpdateCounter()
    ParticleManager:SetParticleControl(self.nfx, 1, Vector(0,self:GetStackCount(),0))
end