ability_brilliance_aura = class({})

LinkLuaModifier( "modifier_ability_brilliance_aura", "heroes/crystal_maiden/brilliance_aura", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_brilliance_aura_effect", "heroes/crystal_maiden/brilliance_aura", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function ability_brilliance_aura:GetIntrinsicModifierName()
	return "modifier_ability_brilliance_aura"
end

modifier_ability_brilliance_aura = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_brilliance_aura:IsHidden()
	return true
end

function modifier_ability_brilliance_aura:IsDebuff()
	return false
end

function modifier_ability_brilliance_aura:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
-- Aura
function modifier_ability_brilliance_aura:IsAura()
	return (not self:GetCaster():PassivesDisabled())
end

function modifier_ability_brilliance_aura:GetModifierAura()
	return "modifier_ability_brilliance_aura_effect"
end

function modifier_ability_brilliance_aura:GetAuraRadius()
	return FIND_UNITS_EVERYWHERE
end

function modifier_ability_brilliance_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ability_brilliance_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

modifier_ability_brilliance_aura_effect = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_brilliance_aura_effect:IsHidden()
	return false
end

function modifier_ability_brilliance_aura_effect:IsDebuff()
	return false
end

function modifier_ability_brilliance_aura_effect:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_brilliance_aura_effect:OnCreated( kv )
	-- references
    self.regen_ally = self:GetAbility():GetSpecialValueFor( "mana_regen" ) -- special value
    self.regen_self = self.regen_ally * self:GetAbility():GetSpecialValueFor( "self_factor" )
end

function modifier_ability_brilliance_aura_effect:OnRefresh( kv )
	-- references
	self:OnCreated()
end

function modifier_ability_brilliance_aura_effect:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ability_brilliance_aura_effect:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
	return funcs
end
function modifier_ability_brilliance_aura_effect:GetModifierConstantManaRegen()
	if self:GetParent()==self:GetCaster() then return self.regen_self end
	return self.regen_ally
end