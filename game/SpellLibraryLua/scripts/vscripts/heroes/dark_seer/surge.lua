ability_surge = class({})

LinkLuaModifier( "modifier_ability_surge", "heroes/dark_seer/surge", LUA_MODIFIER_MOTION_NONE )

function ability_surge:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor( "duration" )

	target:AddNewModifier(
		caster,
		self,
		"modifier_ability_surge",
		{ duration = duration }
	)
end

modifier_ability_surge = class({})

function modifier_ability_surge:IsHidden()
	return false
end

function modifier_ability_surge:IsDebuff()
	return false
end

function modifier_ability_surge:IsStunDebuff()
	return false
end

function modifier_ability_surge:IsPurgable()
	return true
end

function modifier_ability_surge:OnCreated( kv )
	self.speed = self:GetAbility():GetSpecialValueFor( "speed_boost" )

	if not IsServer() then
		return
	end

	EmitSoundOn( "Hero_Dark_Seer.Surge", self:GetParent() )
end

function modifier_ability_surge:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_surge:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
	}

	return funcs
end

function modifier_ability_surge:GetModifierMoveSpeedBonus_Constant()
	return self.speed
end

function modifier_ability_surge:GetModifierIgnoreMovespeedLimit()
	return 1
end

function modifier_ability_surge:GetActivityTranslationModifiers()
	return "haste"
end

function modifier_ability_surge:CheckState()
	local state = {
		[MODIFIER_STATE_UNSLOWABLE] = true,
	}

	return state
end

function modifier_ability_surge:GetEffectName()
	return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf"
end

function modifier_ability_surge:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end