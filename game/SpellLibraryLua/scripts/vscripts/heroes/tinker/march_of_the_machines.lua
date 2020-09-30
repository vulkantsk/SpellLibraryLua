ability_march_of_the_machines = {}

LinkLuaModifier( "modifier_ability_march_of_the_machines_thinker", "heroes/tinker/march_of_the_machines", LUA_MODIFIER_MOTION_NONE )

function ability_march_of_the_machines:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	CreateModifierThinker(
		caster,
		self,
		"modifier_ability_march_of_the_machines_thinker",
		{},
		point,
		caster:GetTeamNumber(),
		false
	)

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_tinker/tinker_motm.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(0,0,0),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOnLocationForAllies( self:GetCaster():GetOrigin(), "Hero_Tinker.March_of_the_Machines.Cast", self:GetCaster() )
end

function ability_march_of_the_machines:OnProjectileHit_ExtraData( target, location, extraData )
	if not target then return true end

	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		location,
		nil,
		extraData.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	local damageTable = {
		attacker = self:GetCaster(),
		damage = extraData.damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self,
	}
	for _,enemy in pairs(enemies) do
		damageTable.victim = enemy
		ApplyDamage(damageTable)
	end

	return true
end

modifier_ability_march_of_the_machines_thinker = {}

function modifier_ability_march_of_the_machines_thinker:IsHidden()
	return true
end

function modifier_ability_march_of_the_machines_thinker:IsDebuff()
	return false
end

function modifier_ability_march_of_the_machines_thinker:IsPurgable()
	return false
end

function modifier_ability_march_of_the_machines_thinker:OnCreated( kv )
	if IsServer() then
		local duration = self:GetAbility():GetSpecialValueFor( "duration" )
		self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
		
		local speed = self:GetAbility():GetSpecialValueFor( "speed" )
		local distance = self:GetAbility():GetSpecialValueFor( "distance" )
		if self:GetCaster():HasScepter() then
			distance = self:GetAbility():GetSpecialValueFor( "distance_scepter" )
		end

		local machines_per_sec = self:GetAbility():GetSpecialValueFor( "machines_per_sec" )
		local collision_radius = self:GetAbility():GetSpecialValueFor( "collision_radius" )
		local splash_radius = self:GetAbility():GetSpecialValueFor( "splash_radius" )
		local splash_damage = self:GetAbility():GetSpecialValueFor( "damage" )
		local interval = 1/machines_per_sec
		local center = self:GetParent():GetOrigin()
		local direction = (center-self:GetCaster():GetOrigin())
		direction = Vector( direction.x, direction.y, 0 ):Normalized()
		self:GetParent():SetForwardVector( direction )
		
		self.spawn_vector = self:GetParent():GetRightVector()

		self.center_start = center - direction*self.radius

		self.projectile_info = {
			Source = self:GetCaster(),
			Ability = self:GetAbility(),
			bDeleteOnHit = true,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			EffectName = "particles/econ/items/tinker/tinker_motm_rollermaw/tinker_rollermaw.vpcf",
			fDistance = distance,
			fStartRadius = collision_radius,
			fEndRadius = collision_radius,
			vVelocity = direction * speed,
			ExtraData = {
				radius = splash_radius,
				damage = splash_damage,
			}
		}

		self:SetDuration( duration, false )

		self:StartIntervalThink( interval )
		self:OnIntervalThink()

		EmitSoundOn( "Hero_Tinker.March_of_the_Machines", self:GetParent() )
	end
end

function modifier_ability_march_of_the_machines_thinker:OnDestroy( kv )
	if IsServer() then
		local sound_cast = "Hero_Tinker.March_of_the_Machines"
		StopSoundOn( sound_cast, self:GetParent() )

		UTIL_Remove( self:GetParent() )
	end
end

function modifier_ability_march_of_the_machines_thinker:OnIntervalThink()
	local spawn = self.center_start + self.spawn_vector*RandomInt( -self.radius, self.radius )

	self.projectile_info.vSpawnOrigin = spawn
	ProjectileManager:CreateLinearProjectile(self.projectile_info)
end