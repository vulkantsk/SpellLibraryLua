LinkLuaModifier( "modifier_ability_lunar_blessing", "heroes/luna/lunar_blessing", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_lunar_blessing_bonus", "heroes/luna/lunar_blessing", LUA_MODIFIER_MOTION_NONE )

ability_lunar_blessing = {}

function ability_lunar_blessing:GetIntrinsicModifierName()
	return "modifier_ability_lunar_blessing"
end

modifier_ability_lunar_blessing = {}

function modifier_ability_lunar_blessing:IsHidden()
	return true
end

function modifier_ability_lunar_blessing:IsAura()
	if self:GetParent():PassivesDisabled() then return false end

	return true
end

function modifier_ability_lunar_blessing:GetModifierAura()
	return "modifier_ability_lunar_blessing_bonus"
end

function modifier_ability_lunar_blessing:GetAuraRadius()
	if self:GetParent():PassivesDisabled() then return 0 end

	return self:GetAbility():GetSpecialValueFor( "radius" )
end

function modifier_ability_lunar_blessing:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ability_lunar_blessing:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

modifier_ability_lunar_blessing_bonus = {}

function modifier_ability_lunar_blessing_bonus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION
	}
end

function modifier_ability_lunar_blessing_bonus:GetBonusNightVision()
	return self:GetAbility():GetSpecialValueFor( "bonus_night_vision" )
end

function modifier_ability_lunar_blessing_bonus:GetModifierDamageOutgoing_Percentage()
	return self:GetAbility():GetSpecialValueFor( "bonus_damage" )
end