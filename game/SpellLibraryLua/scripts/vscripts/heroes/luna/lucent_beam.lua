ability_lucent_beam = {}

function ability_lucent_beam:OnAbilityPhaseStart()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_luna/luna_lucent_beam_precast.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetCaster()
	)
	ParticleManager:SetParticleControl( effect_cast, 1, Vector(0.4,0,0) )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(),
		true
	)

	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( sound_cast, self:GetCaster() )

	return true
end

function ability_lucent_beam:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb( self ) then return end

	local duration = self:GetSpecialValueFor("stun_duration")
	local damage = self:GetSpecialValueFor("beam_damage")

	local damageTable = {
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self,
		damage_flags = DOTA_DAMAGE_FLAG_NONE,
	}
	ApplyDamage(damageTable)

	target:AddNewModifier(
		caster,
		self,
		"modifier_stunned",
		{ duration = duration }
	)

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_luna/luna_lucent_beam.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		target
	)
	ParticleManager:SetParticleControl( effect_cast, 0, target:GetOrigin() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		target,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		5,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		6,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Luna.LucentBeam.Cast", self:GetCaster() )
	EmitSoundOn( "Hero_Luna.LucentBeam.Target", target )
end