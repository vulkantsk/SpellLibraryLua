ability_scream_of_pain = {}

function ability_scream_of_pain:OnSpellStart()
	self.caster = self:GetCaster()
	local point = self:GetCaster():GetOrigin()

	local radius = self:GetSpecialValueFor("area_of_effect")
	self.screamDamage = self:GetAbilityDamage()

	local projectile_name = "particles/units/heroes/hero_queenofpain/queen_scream_of_pain.vpcf"
	local projectile_speed = self:GetSpecialValueFor("projectile_speed")

	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		point,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	local info = {
		Source = caster,
		Ability = self,	
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		vSourceLoc= point,
		bDodgeable = false,
		bVisibleToEnemies = true,
		bReplaceExisting = false,
		bProvidesVision = false
	}

	for _,enemy in pairs(enemies) do
		info.Target = enemy
		ProjectileManager:CreateTrackingProjectile(info)
	end

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_queenofpain/queen_scream_of_pain_owner.vpcf",
		PATTACH_ABSORIGIN,
		self:GetCaster()
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_QueenOfPain.ScreamOfPain", self:GetCaster() )
end

function ability_scream_of_pain:OnProjectileHit( target, location )
	ApplyDamage({
		victim = target,
		attacker = self.caster,
		damage = self.screamDamage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self,
	})
end