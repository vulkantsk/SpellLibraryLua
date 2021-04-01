ability_fireblast = {}

function ability_fireblast:GetManaCost( level )
	local pct = self:GetSpecialValueFor( "scepter_mana" )

	return math.floor( self:GetCaster():GetMana() * pct )
end

function ability_fireblast:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb( self ) then
		return
	end

	ApplyDamage( {
		victim = target,
		attacker = caster,
		damage = self:GetSpecialValueFor( "fireblast_damage" ),
		damage_type = self:GetAbilityDamageType(),
		ability = self
	} )

	target:AddNewModifier(
		self:GetCaster(),
		self, 
		"modifier_stunned", 
		{duration = self:GetSpecialValueFor( "stun_duration" )}
	)

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_ogre_magi/ogre_magi_unr_fireblast.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		target
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:SetParticleControl( effect_cast, 1, target:GetOrigin() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_OgreMagi.Fireblast.Cast", self:GetCaster() )
	EmitSoundOn( "Hero_OgreMagi.Fireblast.Target", target )
end