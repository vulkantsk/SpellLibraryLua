ability_sunder = {}

function ability_sunder:CastFilterResultTarget( hTarget )
	if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end

	local nResult = UnitFilter(
		hTarget,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO,
		0,
		self:GetCaster():GetTeamNumber()
	)
	if nResult ~= UF_SUCCESS then
		return nResult
	end

	return UF_SUCCESS
end

function ability_sunder:GetCustomCastErrorTarget( hTarget )
	if self:GetCaster() == hTarget then
		return "#dota_hud_error_cant_cast_on_self"
	end

	return ""
end

function ability_sunder:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local min_pct = self:GetSpecialValueFor( "hit_point_minimum_pct" )

	if target:TriggerSpellAbsorb( self ) then return end

	local health1 = math.max( min_pct, caster:GetHealthPercent() )/100
	local health2 = math.max( min_pct, target:GetHealthPercent() )/100

	caster:ModifyHealth( caster:GetMaxHealth() * health2, self, false, DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_DIRECTOR_EVENT )
	target:ModifyHealth( target:GetMaxHealth() * health1, self, false, DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_DIRECTOR_EVENT )

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_terrorblade/terrorblade_sunder.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )

	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Terrorblade.Sunder.Cast", self:GetCaster() )
	EmitSoundOn( "Hero_Terrorblade.Sunder.Target", target )
end