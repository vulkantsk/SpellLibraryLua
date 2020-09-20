ability_diabolic_edict = {}

LinkLuaModifier( "modifier_ability_diabolic_edict", "heroes/leshrac/diabolic_edict", LUA_MODIFIER_MOTION_NONE )

function ability_diabolic_edict:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetDuration()

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_diabolic_edict",
		{ duration = duration }
	)
end

modifier_ability_diabolic_edict = {}

function modifier_ability_diabolic_edict:IsHidden()
	return false
end

function modifier_ability_diabolic_edict:IsDebuff()
	return false
end

function modifier_ability_diabolic_edict:IsPurgable()
	return false
end

function modifier_ability_diabolic_edict:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_diabolic_edict:RemoveOnDeath()
	return false
end

function modifier_ability_diabolic_edict:OnCreated( kv )
	if not IsServer() then return end

	local explosion = self:GetAbility():GetSpecialValueFor( "num_explosions" )
	local duration = self:GetAbility():GetSpecialValueFor( "duration_tooltip" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.tower_bonus = self:GetAbility():GetSpecialValueFor( "tower_bonus" ) / 100 + 1
	self.damage = self:GetAbility():GetAbilityDamage()

	local interval = duration / explosion
	self.parent = self:GetParent()
	self.damageTable = {
		attacker = self:GetParent(),
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(),
	}

	self:StartIntervalThink( interval )
	self:OnIntervalThink()

	EmitSoundOn( "Hero_Leshrac.Diabolic_Edict_lp", self.parent )
end

function modifier_ability_diabolic_edict:OnDestroy()
	if not IsServer() then return end

	StopSoundOn( "Hero_Leshrac.Diabolic_Edict_lp", self.parent )
end

function modifier_ability_diabolic_edict:OnIntervalThink()
	local enemies = FindUnitsInRadius(
		self.parent:GetTeamNumber(),
		self.parent:GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING,
		0,
		0,
		false
	)

	local enemy = nil

	if #enemies > 0 then
		enemy = enemies[1]

		self.damageTable.victim = enemy
		if enemy:IsTower() then
			self.damageTable.damage = self.damage * self.tower_bonus
		else
			self.damageTable.damage = self.damage
		end

		ApplyDamage( self.damageTable )
	end

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_leshrac/leshrac_diabolic_edict.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )

	if enemy then
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			1,
			enemy,
			PATTACH_ABSORIGIN_FOLLOW,
			"attach_hitloc",
			Vector( 0, 0, 0 ),
			true
		)
	else
		ParticleManager:SetParticleControl( effect_cast, 1, self.parent:GetOrigin() + RandomVector( RandomInt( 0, self.radius ) ) )
	end
	ParticleManager:ReleaseParticleIndex( effect_cast )

	if enemy then
		EmitSoundOn( "Hero_Leshrac.Diabolic_Edict", enemy )
	end
end