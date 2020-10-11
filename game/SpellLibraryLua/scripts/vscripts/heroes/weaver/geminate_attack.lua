LinkLuaModifier("modifier_geminate_attack", "heroes/weaver/geminate_attack", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_geminate_attack_handler", "heroes/weaver/geminate_attack", LUA_MODIFIER_MOTION_NONE)

ability_geminate_attack = class({
    GetIntrinsicModifierName = function()
        return "modifier_geminate_attack"
    end,
})

modifier_geminate_attack = class({
    IsHidden = function()
        return true
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_EVENT_ON_ATTACK
        }
    end
})

function modifier_geminate_attack:OnCreated()
    if (not IsServer()) then
        return
    end
    self.ability = self:GetAbility()
    self.parent = self:GetParent()
end

function modifier_geminate_attack:OnAttack(keys)
    if (not IsServer()) then
        return
    end
    if (keys.attacker ~= self.parent or not self.ability:IsFullyCastable()) then
        return
    end
    if (keys.no_attack_cooldown or self.parent:IsIllusion() or self.parent:PassivesDisabled()) then
        return
    end
    if (keys.target:GetUnitName() == "npc_dota_observer_wards" or keys.target:GetUnitName() == "npc_dota_sentry_wards") then
        return
    end
    local modifier = keys.target:AddNewModifier(
            self.parent,
            self.ability,
            "modifier_geminate_attack_handler",
            {}
    )
    modifier:SetStackCount(self.ability:GetSpecialValueFor("tooltip_attack"))
    self.ability:UseResources(true, true, true)
end

modifier_geminate_attack_handler = class({
    IsHidden = function()
        return false
    end,
    IsPurgable = function()
        return false
    end,
    GetAttributes = function()
        return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_PERMANENT
    end,
    DeclareFunctions = function()
        return {
            MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
        }
    end
})

function modifier_geminate_attack_handler:GetModifierPreAttack_BonusDamage()
    if not IsServer() or not self.attack_bonus then
        return
    end
    return self.bonus_damage
end

function modifier_geminate_attack_handler:OnCreated()
    if not IsServer() then
        return
    end
    self.ability = self:GetAbility()
    self.bonus_damage = self.ability:GetSpecialValueFor("bonus_damage")
    self.caster = self.ability:GetCaster()
    self.target = self:GetParent()
    self:StartIntervalThink(self.ability:GetSpecialValueFor("delay"))
end

function modifier_geminate_attack_handler:OnIntervalThink()
    if (self.caster:IsAlive()) then
        self.attack_bonus = true
        self.caster:PerformAttack(self.target, true, true, true, false, true, false, false)
        self.attack_bonus = false
    end
    local stacks = self:GetStackCount() - 1
    if (stacks < 1) then
        self:Destroy()
    else
        self:SetStackCount(stacks)
    end
end