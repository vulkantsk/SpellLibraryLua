ability_earthshock = {}

LinkLuaModifier( "modifier_ability_earthshock", "heroes/ursa/earthshock", LUA_MODIFIER_MOTION_NONE )

function ability_earthshock:GetCastRange()
	return self:GetSpecialValueFor("shock_radius")
end

function ability_earthshock:OnSpellStart()
	local slow_radius = self:GetSpecialValueFor("shock_radius")
	local slow_duration = self:GetDuration()
	local ability_damage = self:GetAbilityDamage()

	local enemies = FindUnitsInRadius (
		self:GetCaster():GetTeamNumber(),
		self:GetCaster():GetOrigin(),
		nil,
		slow_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _,enemy in pairs(enemies) do
		local damage = {
			victim = enemy,
			attacker = self:GetCaster(),
			damage = ability_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self
		}
		ApplyDamage( damage )

		enemy:AddNewModifier(
			self:GetCaster(),
			self,
			"modifier_ability_earthshock",
			{ duration = slow_duration }
		)
	end

	local slow_radius = self:GetSpecialValueFor("shock_radius")

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 0, self:GetCaster():GetForwardVector() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector(slow_radius/2, slow_radius/2, slow_radius/2) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Ursa.Earthshock", self:GetCaster() )
end

modifier_ability_earthshock = {}

function modifier_ability_earthshock:IsDebuff()
	return true
end

function modifier_ability_earthshock:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_earthshock:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movement_slow")
end

function modifier_ability_earthshock:GetEffectName()
	return "particles/units/heroes/hero_ursa/ursa_earthshock_modifier.vpcf"
end

function modifier_ability_earthshock:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end