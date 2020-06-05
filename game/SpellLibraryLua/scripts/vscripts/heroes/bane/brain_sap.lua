ability_brain_sap = class({})

function ability_brain_sap:OnSpellStart()

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- load data
	local damage = self:GetSpecialValueFor("brain_sap_damage")
	local heal = self:GetSpecialValueFor("tooltip_brain_sap_heal_amt")

	-- cancel if linken
	if target:TriggerSpellAbsorb( self ) then
		return
    end
    
	-- damage
	local damageTable = {
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_PURE,
		ability = self, --Optional.
	}
    caster:Heal( ApplyDamage(damageTable), self )

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_bane/bane_sap.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		self:GetCaster():GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		target:GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( "Hero_Bane.BrainSap", self:GetCaster() )
	EmitSoundOn( "Hero_Bane.BrainSap.Target", target )

end