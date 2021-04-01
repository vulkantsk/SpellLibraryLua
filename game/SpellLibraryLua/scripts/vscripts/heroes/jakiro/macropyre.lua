LinkLuaModifier( "modifier_ability_macropyre", "heroes/jakiro/macropyre", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_macropyre_thinker", "heroes/jakiro/macropyre", LUA_MODIFIER_MOTION_NONE )

ability_macropyre = {}

function ability_macropyre:GetCastRange( vLocation, hTarget )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "cast_range_scepter" )
	end

	return self:GetSpecialValueFor( "cast_range" )
end

function ability_macropyre:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local dir = point - caster:GetAbsOrigin()
	dir.z = 0
	dir = dir:Normalized()

	local duration = self:GetSpecialValueFor( "duration" )
	if caster:HasScepter() then
		duration = self:GetSpecialValueFor( "duration_scepter" )
	end

	CreateModifierThinker(
		caster,
		self,
		"modifier_ability_macropyre_thinker",
		{
			duration = duration,
			x = dir.x,
			y = dir.y,
		},
		caster:GetAbsOrigin(),
		caster:GetTeamNumber(),
		false
	)

	EmitSoundOn( "Hero_Jakiro.Macropyre.Cast", caster )
end

modifier_ability_macropyre = {}

function modifier_ability_macropyre:IsHidden()
	return false
end

function modifier_ability_macropyre:IsDebuff()
	return true
end

function modifier_ability_macropyre:IsStunDebuff()
	return false
end

function modifier_ability_macropyre:IsPurgable()
	return false
end

function modifier_ability_macropyre:OnCreated( kv )
	if not IsServer() then return end

	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = kv.damage,
		damage_type = kv.damage_type,
		ability = self:GetAbility(),
	}

	self:StartIntervalThink( kv.interval )
end

function modifier_ability_macropyre:OnRefresh( kv )
	if not IsServer() then return end
	self.damageTable.damage = kv.damage
	self.damageTable.damage_type = kv.damage_type
end

function modifier_ability_macropyre:OnIntervalThink()
	ApplyDamage( self.damageTable )
end

function modifier_ability_macropyre:GetEffectName()
	return "particles/units/heroes/hero_jakiro/jakiro_liquid_fire_debuff.vpcf"
end

function modifier_ability_macropyre:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_macropyre_thinker = {}

function modifier_ability_macropyre_thinker:IsHidden()
	return false
end

function modifier_ability_macropyre_thinker:IsDebuff()
	return false
end

function modifier_ability_macropyre_thinker:IsStunDebuff()
	return false
end

function modifier_ability_macropyre_thinker:IsPurgable()
	return false
end

function modifier_ability_macropyre_thinker:OnCreated( kv )
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.radius = self:GetAbility():GetSpecialValueFor( "path_radius" )
	self.duration = self:GetAbility():GetSpecialValueFor( "linger_duration" )
	self.interval = self:GetAbility():GetSpecialValueFor( "burn_interval" )
	self.range = self:GetAbility():GetCastRange( self.parent:GetAbsOrigin(), nil ) + self.caster:GetCastRangeBonus()
	if self:GetCaster():HasScepter() then
		self.damage = self:GetAbility():GetSpecialValueFor( "damage_scepter" )
	else
		self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
	end

	if not IsServer() then return end

	self.abilityDamageType = self:GetAbility():GetAbilityDamageType()
	self.abilityTargetTeam = self:GetAbility():GetAbilityTargetTeam()
	self.abilityTargetType = self:GetAbility():GetAbilityTargetType()
	self.abilityTargetFlags = self:GetAbility():GetAbilityTargetFlags()

	local start_range = 234
	self.direction = Vector( kv.x, kv.y, 0 )
	self.startpoint = self.parent:GetAbsOrigin() + self.direction * start_range
	self.endpoint = self.startpoint + self.direction * self.range

	local step = 0
	while step < self.range do
		local loc = self.startpoint + self.direction * step
		GridNav:DestroyTreesAroundPoint( loc, self.radius, true )

		step = step + self.radius
	end

	self:StartIntervalThink( self.interval )

	local duration = self:GetDuration()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_jakiro/jakiro_macropyre.vpcf",
		PATTACH_WORLDORIGIN,
		self.parent
	)
	ParticleManager:SetParticleControl( effect_cast, 0, self.startpoint )
	ParticleManager:SetParticleControl( effect_cast, 1, self.endpoint )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( duration, 0, 0 ) )

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	EmitSoundOn( "hero_jakiro.macropyre", self.parent )
end

function modifier_ability_macropyre_thinker:OnDestroy()
	if not IsServer() then return end
	UTIL_Remove( self:GetParent() )
end

function modifier_ability_macropyre_thinker:OnIntervalThink()
	local enemies = FindUnitsInLine(
		self.caster:GetTeamNumber(),
		self.startpoint,
		self.endpoint,
		nil,
		self.radius,
		self.abilityTargetTeam,
		self.abilityTargetType,
		self.abilityTargetFlags
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			self.caster,
			self:GetAbility(),
			"modifier_ability_macropyre",
			{
				duration = self.duration,
				interval = self.interval,
				damage = self.damage * self.interval,
				damage_type = self.abilityDamageType,
			}
		)
	end
end