LinkLuaModifier( "modifier_ability_empower", "heroes/magnataur/empower", LUA_MODIFIER_MOTION_NONE )

ability_empower = {}

function ability_empower:OnAbilityPhaseStart()
	return true
end

function ability_empower:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor( "empower_duration" )

	target:AddNewModifier(
		caster,
		self,
		"modifier_ability_empower",
		{ duration = duration }
	)

	EmitSoundOn( "Hero_Magnataur.Empower.Cast", caster )
	EmitSoundOn( "Hero_Magnataur.Empower.Target", target )
end

modifier_ability_empower = {}

function modifier_ability_empower:IsHidden()
	return false
end

function modifier_ability_empower:IsDebuff()
	return false
end

function modifier_ability_empower:IsPurgable()
	return true
end

function modifier_ability_empower:OnCreated( kv )
	self.ability = self:GetAbility()
	self.damage = self:GetAbility():GetSpecialValueFor( "bonus_damage_pct" )
	self.cleave = self:GetAbility():GetSpecialValueFor( "cleave_damage_pct" )
	self.mult = self:GetAbility():GetSpecialValueFor( "self_multiplier" )
	self.radius_start = self:GetAbility():GetSpecialValueFor( "cleave_starting_width" )
	self.radius_end = self:GetAbility():GetSpecialValueFor( "cleave_ending_width" )
	self.radius_dist = self:GetAbility():GetSpecialValueFor( "cleave_distance" )

	if self:GetParent()==self:GetCaster() then
		self.damage = self.damage*self.mult
		self.cleave = self.cleave*self.mult
	end
end

modifier_ability_empower.OnRefresh = modifier_ability_empower.OnCreated

function modifier_ability_empower:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_ability_empower:GetModifierProcAttack_Feedback( params )
	if not IsServer() then return end
	if params.attacker:GetAttackCapability()~=DOTA_UNIT_CAP_MELEE_ATTACK then return end

	local damage = params.damage*self.cleave/100

	DoCleaveAttack(
		params.attacker,
		params.target,
		self.ability,
		self.cleave,
		self.radius_start,
		self.radius_end,
		self.radius_dist,
		"particles/units/heroes/hero_magnataur/magnataur_empower_cleave_effect.vpcf"
	)
end

function modifier_ability_empower:GetModifierDamageOutgoing_Percentage()
	return self.damage
end

function modifier_ability_empower:GetEffectName()
	return "particles/units/heroes/hero_magnataur/magnataur_empower.vpcf"
end

function modifier_ability_empower:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end