ability_return = class({})

function ability_return:GetIntrinsicModifierName() return 'modifier_ability_return_buff_lua' end
LinkLuaModifier('modifier_ability_return_buff_lua_active', 'heroes/centaur/return', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ability_return_buff_lua', 'heroes/centaur/return', LUA_MODIFIER_MOTION_NONE)

function ability_return:OnAbilityPhaseStart()
    local modifier = self:GetCaster():FindModifierByName("modifier_ability_return_buff_lua")
    return not not (modifier and modifier:GetStackCount() ~= 0)
end

function ability_return:OnSpellStart()
    self:GetCaster():AddNewModifier(self:GetCaster(), self, 'modifier_ability_return_buff_lua_active', {
        duration = self:GetSpecialValueFor('damage_gain_duration'),
    }):SetStackCount(self:GetCaster():FindModifierByName("modifier_ability_return_buff_lua"):GetStackCount())
    self:GetCaster():EmitSound("Hero_Centaur.Retaliate.Cast")
end 

modifier_ability_return_buff_lua_active = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    AllowIllusionDuplicate  = function(self) return true end,
    IsPermanent             = function(self) return true end,
    GetEffectName           = function(self) return "particles/units/heroes/hero_centaur/centaur_return_buff.vpcf" end,
    GetEffectAttachType     = function(self) return "attach_attack1" end,
    DeclareFunctions        = function(self) return {
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
    } end,
})

function modifier_ability_return_buff_lua_active:GetModifierBaseDamageOutgoing_Percentage(keys)
    return (self.bonus_dmg or 0) * self:GetStackCount()
end

function modifier_ability_return_buff_lua_active:OnCreated()
    if IsClient() then return end 

    self.bonus_dmg = self:GetAbility():GetSpecialValueFor('damage_gain_pct')
end 

function modifier_ability_return_buff_lua_active:OnDestroy()
    if IsClient() then return end 

    self:GetParent():FindModifierByName('modifier_ability_return_buff_lua'):SetStackCount(0)
end 

function modifier_ability_return_buff_lua_active:OnRefresh()
    self:OnCreated()
end

modifier_ability_return_buff_lua = class({
    IsHidden                = function(self) return self:GetStackCount() == 0 end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    AllowIllusionDuplicate  = function(self) return true end,
    IsPermanent             = function(self) return true end,
    DeclareFunctions        = function(self) return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    } end,
})
-- particles/units/heroes/hero_centaur/centaur_return_buff.vpcf
function modifier_ability_return_buff_lua:OnAttackLanded(data)
    if IsClient() then return end 
    if data.target ~= self.parent  then return end 

    if not ( data.attacker:IsTower() or data.attacker:IsHero()) then return end

    if self:GetStackCount() < self.max and not data.target:HasModifier('modifier_ability_return_buff_lua_active') then 
        self:SetStackCount(self:GetStackCount() + 1)
    end
    local nfx = ParticleManager:CreateParticle('particles/units/heroes/hero_centaur/centaur_return.vpcf', PATTACH_ABSORIGIN_FOLLOW, data.target)
    ParticleManager:SetParticleControlEnt(nfx, 1, data.attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", data.attacker:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(nfx)
    ApplyDamage({
        victim = data.attacker,
        attacker = self.parent,
        damage = self.return_damage,
        damage_type = self.dmg_type,
        ability = self.ability,
    })

end

function modifier_ability_return_buff_lua:OnCreated()
    if IsClient() then return end 
    self.parent = self:GetParent()
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()

    self.max = self.ability:GetSpecialValueFor('max_stacks')
    self.return_damage = self.ability:GetSpecialValueFor('return_damage')
    self.dmg_type = self.ability:GetAbilityDamageType()
end

function modifier_ability_return_buff_lua:OnRefresh()
    self:OnCreated()
end 