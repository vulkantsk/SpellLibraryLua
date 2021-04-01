LinkLuaModifier( "modifier_ability_song_of_the_siren", "heroes/naga_siren/song_of_the_siren", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_song_of_the_siren_debuff", "heroes/naga_siren/song_of_the_siren", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_song_of_the_siren_scepter", "heroes/naga_siren/song_of_the_siren", LUA_MODIFIER_MOTION_NONE )

ability_song_of_the_siren = {}

function ability_song_of_the_siren:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor( "duration" )
	local modifier = caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_song_of_the_siren",
		{ duration = duration }
	)

	local ability = caster:FindAbilityByName( "ability_song_of_the_siren_cancel" )

	if not ability then
		ability = caster:AddAbility( "ability_song_of_the_siren_cancel" )
		ability:SetStolen( true )
	end

	ability:SetLevel( 1 )

	ability.modifier = modifier

	caster:SwapAbilities(
		self:GetAbilityName(),
		ability:GetAbilityName(),
		false,
		true
	)

	ability:StartCooldown( ability:GetCooldown( 1 ) )
end

modifier_ability_song_of_the_siren = {}

function modifier_ability_song_of_the_siren:IsHidden()
	return false
end

function modifier_ability_song_of_the_siren:IsDebuff()
	return false
end

function modifier_ability_song_of_the_siren:IsPurgable()
	return false
end

function modifier_ability_song_of_the_siren:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

	if not IsServer() then return end
	local caster = self:GetCaster()

	if caster:HasScepter() then
		self.scepter = caster:AddNewModifier(
			caster,
			self:GetAbility(),
			"modifier_ability_song_of_the_siren_scepter",
			{}
		)
	end

	local caster = self:GetCaster()

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_siren/naga_siren_siren_song_cast.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		caster
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_siren/naga_siren_song_aura.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		caster
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		caster,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	EmitSoundOn( "Hero_NagaSiren.SongOfTheSiren", caster )
end

function modifier_ability_song_of_the_siren:OnRefresh( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )	
end

function modifier_ability_song_of_the_siren:OnDestroy()
	if not IsServer() then return end

	if self.scepter and not self.scepter:IsNull() then
		self.scepter:Destroy()
	end

	local ability = self:GetCaster():FindAbilityByName( "ability_song_of_the_siren_cancel" )
	if not ability then return end

	self:GetCaster():SwapAbilities(
		self:GetAbility():GetAbilityName(),
		ability:GetAbilityName(),
		true,
		false
	)
end

function modifier_ability_song_of_the_siren:End()
	StopSoundOn( "Hero_NagaSiren.SongOfTheSiren", self:GetCaster() )
	EmitSoundOn( "Hero_NagaSiren.SongOfTheSiren.Cancel", self:GetCaster() )

	self:Destroy()
end

function modifier_ability_song_of_the_siren:IsAura()
	return true
end

function modifier_ability_song_of_the_siren:GetModifierAura()
	return "modifier_ability_song_of_the_siren_debuff"
end

function modifier_ability_song_of_the_siren:GetAuraRadius()
	return self.radius
end

function modifier_ability_song_of_the_siren:GetAuraDuration()
	return 0.4
end

function modifier_ability_song_of_the_siren:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_song_of_the_siren:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_ability_song_of_the_siren:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_ability_song_of_the_siren:GetAuraEntityReject( hEntity )
	return false
end

modifier_ability_song_of_the_siren_debuff = {}

function modifier_ability_song_of_the_siren_debuff:IsHidden()
	return false
end

function modifier_ability_song_of_the_siren_debuff:IsDebuff()
	return true
end

function modifier_ability_song_of_the_siren_debuff:IsStunDebuff()
	return false
end

function modifier_ability_song_of_the_siren_debuff:IsPurgable()
	return false
end

function modifier_ability_song_of_the_siren_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE 
end

function modifier_ability_song_of_the_siren_debuff:OnCreated( kv )
	self.rate = self:GetAbility():GetSpecialValueFor( "animation_rate" )
end

function modifier_ability_song_of_the_siren_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
end

function modifier_ability_song_of_the_siren_debuff:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

function modifier_ability_song_of_the_siren_debuff:GetOverrideAnimationRate()
	return self.rate
end

function modifier_ability_song_of_the_siren_debuff:CheckState()
	return {
		[MODIFIER_STATE_NIGHTMARED] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
	}
end

function modifier_ability_song_of_the_siren_debuff:GetEffectName()
	return "particles/units/heroes/hero_siren/naga_siren_song_debuff.vpcf"
end

function modifier_ability_song_of_the_siren_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_ability_song_of_the_siren_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_siren_song.vpcf"
end

function modifier_ability_song_of_the_siren_debuff:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end

modifier_ability_song_of_the_siren_scepter = class({})

function modifier_ability_song_of_the_siren_scepter:IsHidden()
	return false
end

function modifier_ability_song_of_the_siren_scepter:IsDebuff()
	return false
end

function modifier_ability_song_of_the_siren_scepter:IsPurgable()
	return false
end

function modifier_ability_song_of_the_siren_scepter:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE 
end

function modifier_ability_song_of_the_siren_scepter:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.regen = self:GetAbility():GetSpecialValueFor( "regen_rate" )
	self.regen_self = self:GetAbility():GetSpecialValueFor( "regen_rate_self" )
end

modifier_ability_song_of_the_siren_scepter.OnRefresh = modifier_ability_song_of_the_siren_scepter.OnCreated

function modifier_ability_song_of_the_siren_scepter:DeclareFunctions()
	return { MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE }
end

function modifier_ability_song_of_the_siren_scepter:GetModifierHealthRegenPercentage()
	if self:GetParent()==self:GetCaster() then
		return self.regen_self
	end

	return self.regen
end

function modifier_ability_song_of_the_siren_scepter:IsAura()
	return self:GetParent() == self:GetCaster()
end

function modifier_ability_song_of_the_siren_scepter:GetModifierAura()
	return "modifier_ability_song_of_the_siren_scepter"
end

function modifier_ability_song_of_the_siren_scepter:GetAuraRadius()
	return self.radius
end

function modifier_ability_song_of_the_siren_scepter:GetAuraDuration()
	return 0.4
end

function modifier_ability_song_of_the_siren_scepter:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ability_song_of_the_siren_scepter:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_ability_song_of_the_siren_scepter:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_ability_song_of_the_siren_scepter:GetAuraEntityReject( hEntity )
	return false
end