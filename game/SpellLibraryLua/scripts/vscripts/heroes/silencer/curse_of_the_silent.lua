LinkLuaModifier( "modifier_ability_curse_of_the_silent", "heroes/silencer/curse_of_the_silent", LUA_MODIFIER_MOTION_NONE )

ability_curse_of_the_silent = {}

function ability_curse_of_the_silent:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

function ability_curse_of_the_silent:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local duration = self:GetSpecialValueFor( "duration" )
	local radius = self:GetSpecialValueFor( "radius" )

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		point,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			caster,
			self,
			"modifier_ability_curse_of_the_silent",
			{ duration = duration }
		)
	end

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_silencer/silencer_curse_cast.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetCaster()
	)
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

	EmitSoundOn( "Hero_Silencer.Curse.Cast", self:GetCaster() )

	local effect_aoe = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_silencer/silencer_curse_aoe.vpcf",
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl( effect_aoe, 0, point )
	ParticleManager:SetParticleControl( effect_aoe, 1, Vector( radius, 0, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_aoe )

	EmitSoundOnLocationWithCaster( point, "Hero_Silencer.Curse", self:GetCaster() )
end

modifier_ability_curse_of_the_silent = {}

function modifier_ability_curse_of_the_silent:IsHidden()
	return false
end

function modifier_ability_curse_of_the_silent:IsDebuff()
	return true
end

function modifier_ability_curse_of_the_silent:IsStunDebuff()
	return false
end

function modifier_ability_curse_of_the_silent:IsPurgable()
	return true
end

function modifier_ability_curse_of_the_silent:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_curse_of_the_silent:OnCreated( kv )
	self.penalty = self:GetAbility():GetSpecialValueFor( "penalty_duration" )
	self.slow = self:GetAbility():GetSpecialValueFor( "movespeed" )
	local damage = self:GetAbility():GetSpecialValueFor( "damage" )

	if not IsServer() then return end
	self.interval = 1

	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility()
	}

	self:StartIntervalThink( self.interval )

	EmitSoundOn( "Hero_Silencer.Curse.Impact", self:GetParent() )
end

function modifier_ability_curse_of_the_silent:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
	}
end

function modifier_ability_curse_of_the_silent:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_ability_curse_of_the_silent:OnAbilityFullyCast( params )
	if not IsServer() then return end
	if params.unit~=self:GetParent() then return end
	if params.ability:IsItem() then return end

	self:SetDuration( self:GetRemainingTime() + self.penalty, true )
end

function modifier_ability_curse_of_the_silent:OnIntervalThink()
	if self:GetParent():IsSilenced() then
		self:SetDuration( self:GetRemainingTime() + self.interval, true )
		return
	end

	ApplyDamage( self.damageTable )

	EmitSoundOn( "Hero_Silencer.Curse_Tick", self:GetParent() )
end

function modifier_ability_curse_of_the_silent:GetEffectName()
	return "particles/units/heroes/hero_silencer/silencer_curse.vpcf"
end

function modifier_ability_curse_of_the_silent:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end