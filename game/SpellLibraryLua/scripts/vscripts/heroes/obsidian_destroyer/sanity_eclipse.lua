ability_sanity_eclipse = {}

function ability_sanity_eclipse:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

function ability_sanity_eclipse:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor( "radius" )
	local mana_loss = self:GetSpecialValueFor( "mana_drain" )
	local int_mult = self:GetSpecialValueFor( "damage_multiplier" )
	local caster_int = caster:GetIntellect()
	local damageTable = {
		attacker = caster,
		damage_type = self:GetAbilityDamageType(),
		ability = self
	}

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		point,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		local astral = enemy:HasModifier( "modifier_outworld_devourer_astral_imprisonment_lua" )
		if enemy:IsOutOfGame() == astral then
			local mana = enemy:GetMaxMana() * mana_loss/100
			enemy:ReduceMana( mana )

			if enemy.GetIntellect then
				damageTable.victim = enemy

				local enemy_int = enemy:GetIntellect()
				damageTable.damage = math.max( caster_int-enemy_int, 0 ) * int_mult

				if astral then
					damageTable.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY
				else
					damageTable.damage_flags = 0
				end

				ApplyDamage(damageTable)

			end
		end
	end

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf",
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl( effect_cast, 0, point )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, 0 ) )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( radius, radius, radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_ObsidianDestroyer.Sanityeclipse.Cast", self:GetCaster() )
	EmitSoundOnLocationWithCaster( point, "Hero_ObsidianDestroyer.Sanityeclipse", self:GetCaster() )
end