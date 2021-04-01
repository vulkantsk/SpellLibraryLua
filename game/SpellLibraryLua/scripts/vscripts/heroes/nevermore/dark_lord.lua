LinkLuaModifier( "modifier_ability_dark_lord", "heroes/nevermore/dark_lord", LUA_MODIFIER_MOTION_NONE )

ability_dark_lord = {}

function ability_dark_lord:GetIntrinsicModifierName()
	return "modifier_ability_dark_lord"
end

modifier_ability_dark_lord = {}

function modifier_ability_dark_lord:IsDebuff()
	return self:GetParent()~=self:GetAbility():GetCaster()
end

function modifier_ability_dark_lord:IsHidden()
	return self:GetParent()==self:GetAbility():GetCaster()
end

function modifier_ability_dark_lord:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_dark_lord:IsAura()
	if self:GetCaster() == self:GetParent() then
		if not self:GetCaster():PassivesDisabled() then
			return true
		end
	end
	
	return false
end

function modifier_ability_dark_lord:GetModifierAura()
	return "modifier_ability_dark_lord"
end


function modifier_ability_dark_lord:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end


function modifier_ability_dark_lord:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_ability_dark_lord:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_ability_dark_lord:GetAuraRadius()
	return self.aura_radius
end

function modifier_ability_dark_lord:GetAuraEntityReject( hEntity )
	return not hEntity:CanEntityBeSeenByMyTeam(self:GetCaster())
end

function modifier_ability_dark_lord:OnCreated( kv )
	self.aura_radius = self:GetAbility():GetSpecialValueFor( "presence_radius" )
	self.armor_reduction = self:GetAbility():GetSpecialValueFor( "presence_armor_reduction" )
end

modifier_ability_dark_lord.OnRefresh = modifier_ability_dark_lord.OnCreated

function modifier_ability_dark_lord:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_ability_dark_lord:GetModifierPhysicalArmorBonus( params )
	if self:GetParent() == self:GetCaster() then
		return 0
	end

	return self.armor_reduction
end