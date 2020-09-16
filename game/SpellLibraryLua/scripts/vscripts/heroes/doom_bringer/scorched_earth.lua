ability_scorched_earth = {}

LinkLuaModifier( "modifier_ability_scorched_earth", "heroes/doom_bringer/scorched_earth", LUA_MODIFIER_MOTION_NONE )

function ability_scorched_earth:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor( "duration" )

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_scorched_earth",
		{ duration = duration }
	)
end

modifier_ability_scorched_earth = {}

function modifier_ability_scorched_earth:IsHidden()
	return false
end

function modifier_ability_scorched_earth:IsDebuff()
	return false
end

function modifier_ability_scorched_earth:IsPurgable()
	return false
end

function modifier_ability_scorched_earth:OnCreated( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage_per_second" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.ms_bonus = self:GetAbility():GetSpecialValueFor( "bonus_movement_speed_pct" )

	if not IsServer() then return end
	local interval = 1
	self.owner = kv.isProvidedByAura~=1

	if not self.owner then return end

	self.damageTable = {
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(),
	}

	self:StartIntervalThink( interval )

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_doom_bringer/doom_scorched_earth.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetParent()
	)
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false 
	)

	EmitSoundOn( "Hero_DoomBringer.ScorchedEarthAura", self:GetParent() )
end

function modifier_ability_scorched_earth:OnRefresh( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage_per_second" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.ms_bonus = self:GetAbility():GetSpecialValueFor( "bonus_movement_speed_pct" )	

	if not IsServer() then return end
	if not self.owner then return end

	self.damageTable.damage = damage
end

function modifier_ability_scorched_earth:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_ability_scorched_earth:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_bonus
end

function modifier_ability_scorched_earth:OnIntervalThink()
	local enemies = FindUnitsInRadius(
		self:GetParent():GetTeamNumber(),
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
		self.damageTable.victim = enemy
		ApplyDamage( self.damageTable )

		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_doom_bringer/doom_bringer_scorched_earth_debuff.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			target 
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end
end

function modifier_ability_scorched_earth:IsAura()
	return self.owner
end

function modifier_ability_scorched_earth:GetModifierAura()
	return "modifier_ability_scorched_earth"
end

function modifier_ability_scorched_earth:GetAuraRadius()
	return self.radius
end

function modifier_ability_scorched_earth:GetAuraDuration()
	return 0.5
end

function modifier_ability_scorched_earth:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ability_scorched_earth:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_ability_scorched_earth:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED
end

function modifier_ability_scorched_earth:GetAuraEntityReject( hEntity )
	if not IsServer() then return end

	if hEntity==self:GetParent() then return true end

	return hEntity:GetPlayerOwnerID()~=self:GetParent():GetPlayerOwnerID()
end

function modifier_ability_scorched_earth:GetEffectName()
	return "particles/units/heroes/hero_doom_bringer/doom_bringer_scorched_earth_buff.vpcf"
end

function modifier_ability_scorched_earth:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end