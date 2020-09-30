ability_heat_seeking_missile = {}

function ability_heat_seeking_missile:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")	
	local targets = self:GetSpecialValueFor("targets")

	if caster:HasScepter() then
		targets = self:GetSpecialValueFor("targets_scepter")
	end

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
		FIND_CLOSEST,
		false
	)

	local info = {
		Source = caster,
		Ability = self,
		EffectName = "particles/units/heroes/hero_tinker/tinker_missile.vpcf",
		iMoveSpeed = self:GetSpecialValueFor("speed"),
		bDodgeable = true,
		ExtraData = {
			damage = damage,
		}
	}
	for i=1,math.min(targets,#enemies) do
		info.Target = enemies[i]
		ProjectileManager:CreateTrackingProjectile( info )
	end

	if #enemies<1 then
		local attach = "attach_attack1"
		if self:GetCaster():ScriptLookupAttachment( "attach_attack3" )~=0 then attach = "attach_attack3" end
		local point = self:GetCaster():GetAttachmentOrigin( self:GetCaster():ScriptLookupAttachment( attach ) )

		local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_tinker/tinker_missile_dud.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		ParticleManager:SetParticleControl( effect_cast, 0, point )
		ParticleManager:SetParticleControlForward( effect_cast, 0, self:GetCaster():GetForwardVector() )
		ParticleManager:ReleaseParticleIndex( effect_cast )

		EmitSoundOn( "Hero_Tinker.Heat-Seeking_Missile_Dud", self:GetCaster() )
	else
		EmitSoundOn( "Hero_Tinker.Heat-Seeking_Missile", caster )
	end
end

function ability_heat_seeking_missile:OnProjectileHit_ExtraData( target, location, extraData )
	local damage = {
		victim = target,
		attacker = self:GetCaster(),
		damage = extraData.damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self
	}
	ApplyDamage( damage )

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_tinker/tinker_missle_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Tinker.Heat-Seeking_Missile.Impact", target )
end