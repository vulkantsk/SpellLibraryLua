LinkLuaModifier( "modifier_ability_rip_tide", "heroes/naga_siren/rip_tide", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_rip_tide_debuff", "heroes/naga_siren/rip_tide", LUA_MODIFIER_MOTION_NONE )

ability_rip_tide = {}

function ability_rip_tide:GetIntrinsicModifierName()
	return "modifier_ability_rip_tide"
end

modifier_ability_rip_tide = {}

function modifier_ability_rip_tide:IsHidden()
	return true
end

function modifier_ability_rip_tide:IsDebuff()
	return false
end

function modifier_ability_rip_tide:IsPurgable()
	return false
end

function modifier_ability_rip_tide:OnCreated( kv )
	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	self.chance = self:GetAbility():GetSpecialValueFor( "chance" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.duration = self:GetAbility():GetSpecialValueFor( "duration" )

	if not IsServer() then return end

	self.abilityDamageType = self:GetAbility():GetAbilityDamageType()
	self.abilityTargetTeam = self:GetAbility():GetAbilityTargetTeam()
	self.abilityTargetType = self:GetAbility():GetAbilityTargetType()
	self.abilityTargetFlags = self:GetAbility():GetAbilityTargetFlags()

	local damage = self:GetAbility():GetSpecialValueFor( "damage" )

	self.damageTable = {
		attacker = self.parent,
		damage = damage,
		damage_type = self.abilityDamageType,
		ability = self:GetAbility()
	}
end

modifier_ability_rip_tide.OnRefresh = modifier_ability_rip_tide.OnCreated

function modifier_ability_rip_tide:DeclareFunctions()
	return { MODIFIER_PROPERTY_PROCATTACK_FEEDBACK }
end

function modifier_ability_rip_tide:GetModifierProcAttack_Feedback( params )
	if not IsServer() then return end
	if self.parent:PassivesDisabled() then return end

	local rand = RandomInt( 0,100 )
	if rand>=self.chance then return end

	local enemies = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		self.parent:GetAbsOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			self.caster,
			self:GetAbility(),
			"modifier_ability_rip_tide_debuff",
			{ duration = self.duration }
		)

		self.damageTable.victim = enemy
		ApplyDamage( self.damageTable )
	end

	self:PlayEffects()
end

function modifier_ability_rip_tide:PlayEffects()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_siren/naga_siren_riptide.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self.parent
	)
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, self.radius, self.radius ) )
	ParticleManager:SetParticleControl( effect_cast, 3, Vector( self.radius, self.radius, self.radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_NagaSiren.Riptide.Cast", self.parent )
end

modifier_ability_rip_tide_debuff = {}

function modifier_ability_rip_tide_debuff:IsHidden()
	return false
end

function modifier_ability_rip_tide_debuff:IsDebuff()
	return true
end

function modifier_ability_rip_tide_debuff:IsStunDebuff()
	return false
end

function modifier_ability_rip_tide_debuff:IsPurgable()
	return true
end

function modifier_ability_rip_tide_debuff:OnCreated( kv )
	self.armor = self:GetAbility():GetSpecialValueFor( "armor_reduction" )
end

modifier_ability_rip_tide_debuff.OnRefresh = modifier_ability_rip_tide_debuff.OnCreated

function modifier_ability_rip_tide_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_ability_rip_tide_debuff:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_ability_rip_tide_debuff:GetEffectName()
	return "particles/units/heroes/hero_siren/naga_siren_riptide_debuff.vpcf"
end

function modifier_ability_rip_tide_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end