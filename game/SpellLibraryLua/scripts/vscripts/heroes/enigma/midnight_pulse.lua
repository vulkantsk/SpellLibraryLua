ability_midnight_pulse = {}

LinkLuaModifier( "modifier_ability_midnight_pulse_thinker", "heroes/enigma/midnight_pulse", LUA_MODIFIER_MOTION_NONE )

function ability_midnight_pulse:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

function ability_midnight_pulse:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local duration = self:GetSpecialValueFor("duration")

	CreateModifierThinker(
		caster,
		self,
		"modifier_ability_midnight_pulse_thinker",
		{ duration = duration },
		point,
		caster:GetTeamNumber(),
		false
	)
end

modifier_ability_midnight_pulse_thinker = {}

function modifier_ability_midnight_pulse_thinker:IsHidden()
	return true
end

function modifier_ability_midnight_pulse_thinker:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.damage = self:GetAbility():GetSpecialValueFor( "damage_percent" )
	local interval = 1

	if IsServer() then
		GridNav:DestroyTreesAroundPoint( self:GetParent():GetOrigin(), self.radius, true )

		self.damageTable = {
			attacker = self:GetCaster(),
			damage_type = self:GetAbility():GetAbilityDamageType(),
			ability = self:GetAbility(),
		}

		self:StartIntervalThink( interval )

		local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_enigma/enigma_midnight_pulse.vpcf", PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
		ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )

		self:AddParticle(
			effect_cast,
			false,
			false,
			-1,
			false,
			false
		)

		EmitSoundOn( "Hero_Enigma.Midnight_Pulse", self:GetParent() )
	end
end

function modifier_ability_midnight_pulse_thinker:OnDestroy()
	if IsServer() then
		UTIL_Remove( self:GetParent() )
	end
end

function modifier_ability_midnight_pulse_thinker:OnIntervalThink()
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		self:GetParent():GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		self.damageTable.victim = enemy
		self.damageTable.damage = enemy:GetMaxHealth()*self.damage/100
		ApplyDamage( self.damageTable )
	end
end