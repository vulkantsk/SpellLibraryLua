LinkLuaModifier( "modifier_ability_moon_glaive", "heroes/luna/moon_glaive", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_moon_glaive_thinker", "heroes/luna/moon_glaive", LUA_MODIFIER_MOTION_NONE )

ability_moon_glaive = {}

function ability_moon_glaive:GetIntrinsicModifierName()
	return "modifier_ability_moon_glaive"
end

modifier_ability_moon_glaive = {}

function modifier_ability_moon_glaive:IsHidden()
	return true
end

function modifier_ability_moon_glaive:IsPurgable()
	return false
end

function modifier_ability_moon_glaive:OnCreated( kv )
	self.bounces = self:GetAbility():GetSpecialValueFor( "bounces" )
	self.range = self:GetAbility():GetSpecialValueFor( "range" )
	self.reduction = self:GetAbility():GetSpecialValueFor( "damage_reduction_percent" )
	self.ability = self:GetAbility()
end

modifier_ability_moon_glaive.OnRefresh = modifier_ability_moon_glaive.OnCreated

function modifier_ability_moon_glaive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_ability_moon_glaive:GetModifierProcAttack_Feedback( params )
	if not IsServer() then return end

	if self:GetParent():PassivesDisabled() then return end

	CreateModifierThinker(
		self:GetParent(),
		self:GetAbility(),
		"modifier_ability_moon_glaive_thinker",
		{},
		params.target:GetAbsOrigin(),
		self:GetParent():GetTeamNumber(),
		false
	)
end

function modifier_ability_moon_glaive:GetModifierDamageOutgoing_Percentage()
	return self.ability.outgoing or 0
end

modifier_ability_moon_glaive_thinker = {}

function modifier_ability_moon_glaive_thinker:IsHidden()
	return true
end

function modifier_ability_moon_glaive_thinker:IsPurgable()
	return false
end

function modifier_ability_moon_glaive_thinker:OnCreated( kv )
	self.bounces = self:GetAbility():GetSpecialValueFor( "bounces" )
	self.range = self:GetAbility():GetSpecialValueFor( "range" )
	self.reduction = self:GetAbility():GetSpecialValueFor( "damage_reduction_percent" )
	self.reduction = (100-self.reduction)/100

	if IsServer() then
		self.parent = self:GetParent()
		self.caster = self:GetCaster()
		self.bounce = 0
		self.targets = {}

		self.parent:SetOrigin( self.parent:GetAbsOrigin() + Vector( 0, 0, 100 ) )
		self.parent:SetAttackCapability( self.caster:GetAttackCapability() )
		self.parent:SetRangedProjectileName( self.caster:GetRangedProjectileName() )
		self.projectile_speed = self.parent:GetProjectileSpeed()

		local units = FindUnitsInRadius(
			self.caster:GetTeamNumber(),
			self.parent:GetAbsOrigin(),
			nil,
			1,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING,
			DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_CLOSEST,
			false
		)
		if #units>0 then
			self.targets[units[1]] = true
		end

		self:Attack()
	end
end

function modifier_ability_moon_glaive_thinker:OnDestroy()
	if not IsServer() then return end
	UTIL_Remove( self:GetParent() )
end

function modifier_ability_moon_glaive_thinker:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
		MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
	}
end

function modifier_ability_moon_glaive_thinker:GetModifierProjectileSpeedBonus()
	if not IsServer() then return end

	return self.caster:GetProjectileSpeed() - (self.projectile_speed or 900)
end

function modifier_ability_moon_glaive_thinker:GetAttackSound()
	return "Hero_Luna.MoonGlaive.Impact"
end

function modifier_ability_moon_glaive_thinker:GetModifierProcAttack_Feedback( params )
	if not IsServer() then return end

	self:GetAbility().outgoing = math.pow( self.reduction, self.bounce )*100 - 100
	self.caster:PerformAttack(
		params.target,
		false,
		false,
		true,
		true,
		false,
		false,
		true
	)
	self:GetAbility().outgoing = 0

	self.parent:SetOrigin( params.target:GetAbsOrigin() + Vector( 0, 0, 100 ) )

	if self.bounce>=self.bounces then
		self:Destroy()
	else
		self:StartIntervalThink( 0.05 )
	end

	EmitSoundOn( "Hero_Luna.MoonGlaive.Impact", params.target )
end

function modifier_ability_moon_glaive_thinker:OnAttackFail( params )
	if not IsServer() then return end
	if params.attacker==self.parent then
		self:Destroy()
	end
end

function modifier_ability_moon_glaive_thinker:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true }
end

function modifier_ability_moon_glaive_thinker:OnIntervalThink()
	self:StartIntervalThink( -1 )
	self:Attack()
end

function modifier_ability_moon_glaive_thinker:Attack()
	self.bounce = self.bounce+1

	local units = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		self.parent:GetAbsOrigin(),
		nil,
		self.range,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_CLOSEST,
		false
	)

	if #units<2 then
		self:Destroy()
		return
	end

	local unit = nil
	for i=2,#units do
		unit = units[i]
		if not self.targets[unit] then
			self.targets[unit] = true
			break
		end

		unit = nil
	end

	if unit == nil then
		self.targets = {}

		self.targets[units[1]] = true

		unit = units[2]
	end

	self.parent:PerformAttack(
		unit,
		false,
		true,
		true,
		true,
		true,
		true,
		true
	)
end