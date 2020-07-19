LinkLuaModifier("modifier_ability_slardar_sprint", "heroes/slardar/sprint.lua", 0)

ability_slardar_sprint = class({})

function ability_slardar_sprint:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")

	caster:AddNewModifier(caster, self, "modifier_ability_slardar_sprint", {duration = duration})

	caster:EmitSound("Hero_Slardar.Sprint")
end

modifier_ability_slardar_sprint = class({
	IsPurgable = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	} end,
	GetModifierIgnoreMovespeedLimit = function() return 1 end,
	CheckState = function() return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true
	} end,
	GetEffectName = function() return "particles/units/heroes/hero_slardar/slardar_sprint.vpcf" end,
	GetEffectAttachType = function() return PATTACH_ABSORIGIN_FOLLOW end
})

function modifier_ability_slardar_sprint:OnCreated()
	self.bonus_speed = self:GetAbility():GetSpecialValueFor("bonus_speed")
	self.river_bonus_speed = self:GetAbility():GetSpecialValueFor("river_speed")
end

function modifier_ability_slardar_sprint:GetModifierMoveSpeedBonus_Percentage()
	local bonus = self.bonus_speed
	if self:GetParent():GetAbsOrigin().z <= 0.5 then
		bonus = bonus + self.river_bonus_speed
	end
	return bonus
end