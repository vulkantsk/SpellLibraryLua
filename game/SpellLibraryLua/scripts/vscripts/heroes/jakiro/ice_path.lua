LinkLuaModifier( "modifier_ability_ice_path", "heroes/jakiro/ice_path", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_ice_path_thinker", "heroes/jakiro/ice_path", LUA_MODIFIER_MOTION_NONE )

ability_ice_path = {}

function ability_ice_path:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local dir = point - caster:GetAbsOrigin()
	dir.z = 0
	dir = dir:Normalized()

	CreateModifierThinker(
		caster,
		self,
		"modifier_ability_ice_path_thinker",
		{
			x = dir.x,
			y = dir.y,
		},
		caster:GetAbsOrigin(),
		caster:GetTeamNumber(),
		false
	)
end

modifier_ability_ice_path = {}

function modifier_ability_ice_path:IsHidden()
	return false
end

function modifier_ability_ice_path:IsDebuff()
	return true
end

function modifier_ability_ice_path:IsStunDebuff()
	return true
end

function modifier_ability_ice_path:IsPurgable()
	return true
end

function modifier_ability_ice_path:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_FROZEN] = true,
	}
end

function modifier_ability_ice_path:GetEffectName()
	return "particles/units/heroes/hero_jakiro/jakiro_icepath_debuff.vpcf"
end

function modifier_ability_ice_path:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_ice_path_thinker = {}

function modifier_ability_ice_path_thinker:IsHidden()
	return false
end

function modifier_ability_ice_path_thinker:IsDebuff()
	return false
end

function modifier_ability_ice_path_thinker:IsStunDebuff()
	return false
end

function modifier_ability_ice_path_thinker:IsPurgable()
	return false
end

function modifier_ability_ice_path_thinker:OnCreated( kv )
	self.parent = self:GetParent()
	self.caster = self:GetCaster()

	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.range = self:GetAbility():GetCastRange( self.parent:GetAbsOrigin(), nil ) + self.caster:GetCastRangeBonus()
	self.delay = self:GetAbility():GetSpecialValueFor( "path_delay" )
	self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
	self.radius = self:GetAbility():GetSpecialValueFor( "path_radius" )

	if not IsServer() then return end

	self.abilityDamageType = self:GetAbility():GetAbilityDamageType()
	self.abilityTargetTeam = self:GetAbility():GetAbilityTargetTeam()
	self.abilityTargetType = self:GetAbility():GetAbilityTargetType()
	self.abilityTargetFlags = self:GetAbility():GetAbilityTargetFlags()

	self.delayed = true
	self.targets = {}
	local start_range = 12

	self.direction = Vector( kv.x, kv.y, 0 )
	self.startpoint = self.parent:GetAbsOrigin() + self.direction + start_range
	self.endpoint = self.startpoint + self.direction * self.range

	self.damageTable = {
		attacker = self.caster,
		damage = damage,
		damage_type = self.abilityDamageType,
		ability = self:GetAbility(),
	}

	self:StartIntervalThink( self.delay )

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_jakiro/jakiro_ice_path.vpcf",
		PATTACH_WORLDORIGIN,
		self.parent
	)
	ParticleManager:SetParticleControl( effect_cast, 0, self.startpoint )
	ParticleManager:SetParticleControl( effect_cast, 1, self.endpoint )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( 0, 0, self.delay ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Jakiro.IcePath.Cast", self.parent )

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_jakiro/jakiro_ice_path_b.vpcf",
		PATTACH_WORLDORIGIN,
		self.parent
	)
	ParticleManager:SetParticleControl( effect_cast, 0, self.startpoint )
	ParticleManager:SetParticleControl( effect_cast, 1, self.endpoint )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( self.delay + self.duration, 0, 0 ) )
	ParticleManager:SetParticleControl( effect_cast, 9, self.startpoint )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		9,
		self.caster,
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Jakiro.IcePath", self.parent )
end

function modifier_ability_ice_path_thinker:OnDestroy()
	if not IsServer() then return end
	UTIL_Remove( self:GetParent() )
end

function modifier_ability_ice_path_thinker:OnIntervalThink()
	if self.delayed then
		self.delayed = false
		self:SetDuration( self.duration, false )
		self:StartIntervalThink( 0.03 )

		local step = 0
		while step < self.range do
			local loc = self.startpoint + self.direction * step
			AddFOWViewer(
				self.caster:GetTeamNumber(),
				loc,
				self.radius,
				self.duration,
				false
			)

			step = step + self.radius
		end

		return
	end

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
		if not self.targets[enemy] then
			self.targets[enemy] = true
			self.damageTable.victim = enemy
			ApplyDamage( self.damageTable )

			local duration = self:GetRemainingTime()

			enemy:AddNewModifier(
				self.caster,
				self:GetAbility(),
				"modifier_ability_ice_path",
				{ duration = duration }
			)
		end
	end
end