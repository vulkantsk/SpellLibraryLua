LinkLuaModifier("modifier_ability_slardar_bash", "heroes/slardar/bash.lua", 0)

ability_slardar_bash = class({
	GetIntrinsicModifierName = function() return "modifier_ability_slardar_bash" end
})

modifier_ability_slardar_bash = class({
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	} end
})

function modifier_ability_slardar_bash:IsHidden()
	if self:GetStackCount() == 0 then
		return true
	end
	return false
end

function modifier_ability_slardar_bash:OnCreated()
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	self.bash_duration = self:GetAbility():GetSpecialValueFor("duration")
	self.attack_count = self:GetAbility():GetSpecialValueFor("attack_count")

	if IsServer() then
		self:SetStackCount(0)
	end
end

function modifier_ability_slardar_bash:OnRefresh()
	self:OnCreated()
end

function modifier_ability_slardar_bash:OnAttackLanded(params)
	local target = params.target
	if params.attacker == self:GetParent() and params.attacker:PassivesDisabled() == false and (target:IsHero() or target:IsCreep()) and target:GetTeam() ~= params.attacker:GetTeam() then
		if self:GetStackCount() < self.attack_count then
			self:IncrementStackCount()
		else
			self:SetStackCount(0)
			target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = self.bash_duration})
		end
	end
end

function modifier_ability_slardar_bash:GetModifierProcAttack_BonusDamage_Physical()
	if self:GetStackCount() == self.attack_count then
		return self.bonus_damage
	end
end