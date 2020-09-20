ability_split_earth = {}

LinkLuaModifier( "modifier_ability_split_earth", "heroes/leshrac/split_earth", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_split_earth_stun", "heroes/leshrac/split_earth", LUA_MODIFIER_MOTION_NONE )

function ability_split_earth:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

function ability_split_earth:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local delay = self:GetSpecialValueFor("delay")

	CreateModifierThinker(
		caster,
		self,
		"modifier_ability_split_earth",
		{ duration = delay },
		point,
		caster:GetTeamNumber(),
		false
	)
end

modifier_ability_split_earth = {}

function modifier_ability_split_earth:IsHidden()
	return true
end

function modifier_ability_split_earth:IsPurgable()
	return false
end

function modifier_ability_split_earth:OnCreated( kv )
	if not IsServer() then return end

	self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	local damage = self:GetAbility():GetAbilityDamage()

	self.damageTable = {
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(),
	}
end

function modifier_ability_split_earth:OnDestroy()
	if not IsServer() then return end

	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		self:GetParent():GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			self:GetCaster(),
			self:GetAbility(),
			"modifier_ability_split_earth_stun",
			{ duration = self.duration }
		)

		self.damageTable.victim = enemy
		ApplyDamage( self.damageTable )
	end

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_leshrac/leshrac_split_earth.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), "Hero_Leshrac.Split_Earth", self:GetCaster() )

	UTIL_Remove( self:GetParent() )
end

modifier_ability_split_earth_stun = {}

function modifier_ability_split_earth_stun:IsHidden()
	return false
end

function modifier_ability_split_earth_stun:IsDebuff()
	return true
end

function modifier_ability_split_earth_stun:IsStunDebuff()
	return false
end

function modifier_ability_split_earth_stun:IsPurgable()
	return true
end

function modifier_ability_split_earth_stun:OnCreated( kv )
	local tick_rate = self:GetAbility():GetSpecialValueFor( "tick_rate" )
	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.stun = self:GetAbility():GetSpecialValueFor( "stun_duration" )

	if IsServer() then
		self.damageTable = {
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			damage = damage,
			damage_type = self:GetAbility():GetAbilityDamageType(),
			ability = self:GetAbility(),
		}

		self:StartIntervalThink( tick_rate )
		self:OnIntervalThink()
	end
end

function modifier_ability_split_earth_stun:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_split_earth_stun:OnIntervalThink()
	self:GetParent():AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_split_earth_stun_stun",
		{ duration = self.stun }
	)

	ApplyDamage( self.damageTable )

	EmitSoundOn( "Hero_Enigma.MaleficeTick", self:GetParent() )
end

function modifier_ability_split_earth_stun:GetEffectName()
	return "particles/units/heroes/hero_enigma/enigma_malefice.vpcf"
end

function modifier_ability_split_earth_stun:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ability_split_earth_stun:GetStatusEffectName()
	return "particles/status_fx/status_effect_enigma_malefice.vpcf"
end

modifier_ability_split_earth_stun_stun = {}

function modifier_ability_split_earth_stun_stun:IsDebuff()
	return true
end

function modifier_ability_split_earth_stun_stun:IsStunDebuff()
	return true
end

function modifier_ability_split_earth_stun_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_ability_split_earth_stun_stun:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_ability_split_earth_stun_stun:GetOverrideAnimation( params )
	return ACT_DOTA_DISABLED
end

function modifier_ability_split_earth_stun_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_ability_split_earth_stun_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end