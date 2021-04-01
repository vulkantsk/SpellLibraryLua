LinkLuaModifier( "modifier_ability_global_silence", "heroes/silencer/global_silence", LUA_MODIFIER_MOTION_NONE )

ability_global_silence = {}

function ability_global_silence:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor( "tooltip_duration" )

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetOrigin(),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_MANA_ONLY,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			caster,
			self,
			"modifier_ability_global_silence",
			{ duration = duration }
		)

		if enemy:IsHero() then
			local effect_cast = ParticleManager:CreateParticle(
				"particles/units/heroes/hero_silencer/silencer_global_silence_hero.vpcf",
				PATTACH_ABSORIGIN_FOLLOW,
				enemy
			)
			ParticleManager:SetParticleControlEnt(
				effect_cast,
				1,
				enemy,
				PATTACH_ABSORIGIN_FOLLOW,
				"attach_attack1",
				Vector(),
				true
			)
			ParticleManager:ReleaseParticleIndex( effect_cast )

			EmitSoundOnClient( "Hero_Silencer.GlobalSilence.Effect", enemy:GetPlayerOwner() )
		end
	end

	local effect_cast =  ParticleManager:CreateParticle(
		"particles/units/heroes/hero_silencer/silencer_global_silence.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetCaster()
	)
	ParticleManager:SetParticleControlForward( effect_cast, 0, self:GetCaster():GetForwardVector() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitGlobalSound( "Hero_Silencer.GlobalSilence.Cast" )
end

modifier_ability_global_silence = {}

function modifier_ability_global_silence:IsDebuff()
	return true
end

function modifier_ability_global_silence:IsStunDebuff()
	return false
end

function modifier_ability_global_silence:IsPurgable()
	return true
end

function modifier_ability_global_silence:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true }
end

function modifier_ability_global_silence:GetEffectName()
	return "particles/generic_gameplay/generic_silenced.vpcf"
end

function modifier_ability_global_silence:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end