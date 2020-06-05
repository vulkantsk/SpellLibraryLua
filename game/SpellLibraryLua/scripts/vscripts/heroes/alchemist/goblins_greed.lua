ability_goblins_greed = class({})

function ability_goblins_greed:GetIntrinsicModifierName()
    return 'modifier_ability_goblins_greed_lua'
end

function ability_goblins_greed:OnUpgrade()
    local modifier = self:GetCaster():FindModifierByName('modifier_ability_goblins_greed_lua')
    if not modifier then 
        modifier = self:GetCaster():AddNewModifier(self:GetCaster(),self,'modifier_ability_goblins_greed_lua',{duration = -1})
    end 
    modifier.bountyBonus = self:GetSpecialValueFor('bounty_multiplier')
    modifier.bonus_bonus_gold = self:GetSpecialValueFor('bonus_bonus_gold')
    modifier.bonus_gold_cap = self:GetSpecialValueFor('bonus_gold_cap')
    modifier.duration = self:GetSpecialValueFor('duration')
    modifier.startGold = self:GetSpecialValueFor('bonus_gold')
end

LinkLuaModifier('modifier_ability_goblins_greed_lua', 'heroes/alchemist/goblins_greed', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ability_goblins_greed_lua_timer', 'heroes/alchemist/goblins_greed', LUA_MODIFIER_MOTION_NONE)
modifier_ability_goblins_greed_lua = class({
    IsHidden                = function(self) return false end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return true end,
    AllowIllusionDuplicate  = function(self) return true end,
    IsPermanent             = function(self) return true end,
    DeclareFunctions        = function(self) return {MODIFIER_EVENT_ON_DEATH} end,
    -- Custom Property 
    GetBountyMultiplyBonus  = function(self) return self.bountyBonus end, 
})
function modifier_ability_goblins_greed_lua:OnCreated(data) 
    self.parent = self:GetParent()
    self.bountyBonus = self:GetAbility():GetSpecialValueFor('bounty_multiplier')
    self.bonus_bonus_gold = self:GetAbility():GetSpecialValueFor('bonus_bonus_gold')
    self.bonus_gold_cap = self:GetAbility():GetSpecialValueFor('bonus_gold_cap')
    self.duration = self:GetAbility():GetSpecialValueFor('duration')
    self.startGold = self:GetAbility():GetSpecialValueFor('bonus_gold')
    self:SetStackCount(self.startGold)
end

function modifier_ability_goblins_greed_lua:OnDeath(data) 

    if data.unit:IsCreep() and data.attacker == self.parent then 

        self.parent:ModifyGold(self:GetStackCount(), true, DOTA_ModifyGold_CreepKill)
        SendOverheadEventMessage(self.parent:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, self.parent, self:GetStackCount(), self.parent:GetPlayerOwner())
        if self:GetStackCount() >= self.bonus_gold_cap then return end
        self:SetStackCount(math.min(self:GetStackCount() + self.bonus_bonus_gold,self.bonus_gold_cap))
        self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), 'modifier_ability_goblins_greed_lua_timer', {duration = self.duration}):SetStackCount(self.bonus_bonus_gold)
    end
end

modifier_ability_goblins_greed_lua_timer = class({
    IsHidden                = function(self) return true end,
    IsPurgable              = function(self) return false end,
    IsDebuff                = function(self) return false end,
    IsBuff                  = function(self) return true end,
    RemoveOnDeath           = function(self) return false end,
    AllowIllusionDuplicate  = function(self) return true end,
    IsPermanent             = function(self) return true end,
    GetAttributes           = function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,

})

function modifier_ability_goblins_greed_lua_timer:OnDestroy()
    if IsClient() then return end

    local modifier = self:GetParent():FindModifierByName('modifier_ability_goblins_greed_lua')
    if not modifier then return end

    modifier:SetStackCount(math.max(modifier:GetStackCount() - self:GetStackCount(),modifier.startGold))
end 