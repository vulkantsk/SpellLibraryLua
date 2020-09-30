ability_enrage = {}

LinkLuaModifier( "modifier_ability_enrage", "heroes/ursa/enrage", LUA_MODIFIER_MOTION_NONE )

function ability_enrage:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE

 	if self:GetCaster():HasScepter() then
 		behavior = behavior + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE
 	end

 	return behavior
end

function ability_enrage:GetCooldown( level )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "cooldown_scepter" )
	end

	return self.BaseClass.GetCooldown( self, level )
end

function ability_enrage:OnSpellStart()
	self:GetCaster():Purge(false, true, false, true, false)

	self:GetCaster():AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_ability_enrage",
		{ duration = self:GetSpecialValueFor("duration") }
	)

	EmitSoundOn( "Hero_Ursa.Enrage", self:GetCaster() )
end

modifier_ability_enrage = {}

function modifier_ability_enrage:IsHidden()
	return false
end

function modifier_ability_enrage:IsDebuff()
	return false
end

function modifier_ability_enrage:IsPurgable()
	return false
end

function modifier_ability_enrage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
	}
end

function modifier_ability_enrage:GetModifierIncomingDamage_Percentage()
	return -self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function modifier_ability_enrage:GetModifierModelScale()
	return 40
end

function modifier_ability_enrage:GetModifierStatusResistanceStacking()
	return self:GetAbility():GetSpecialValueFor("status_resistance")
end

function modifier_ability_enrage:GetEffectName()
	return "particles/units/heroes/hero_ursa/ursa_enrage_buff.vpcf"
end

function modifier_ability_enrage:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end