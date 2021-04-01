puck_waning_rift_lua = {}

function puck_waning_rift_lua:OnSpellStart()
	local caster = self:GetCaster()
	local pos = caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("silence_duration")
	local damage = self:GetSpecialValueFor("damage")
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		pos,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	local damageTable = {
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self,
		damage_flags = DOTA_DAMAGE_FLAG_NONE,
	}
	for _,enemy in pairs(enemies) do
		damageTable.victim = enemy
		ApplyDamage(damageTable)

		enemy:AddNewModifier(
			caster,
			self,
			"modifier_silenced",
			{ duration = duration }
		)
	end

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_puck/puck_waning_rift.vpcf",
		PATTACH_WORLDORIGIN,
		caster
	)
	ParticleManager:SetParticleControl( effect_cast, 0, pos )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOnLocationWithCaster( caster:GetAbsOrigin(), "Hero_Puck.Waning_Rift", caster )
end