ability_metamorphosis = {}

LinkLuaModifier( "modifier_ability_metamorphosis", "heroes/terrorblade/metamorphosis", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_metamorphosis_aura", "heroes/terrorblade/metamorphosis", LUA_MODIFIER_MOTION_NONE )

function ability_metamorphosis:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor( "duration" )

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_metamorphosis_aura",
		{ duration = duration }
	)
end

modifier_ability_metamorphosis_aura = {}

function modifier_ability_metamorphosis_aura:IsHidden()
	return false
end

function modifier_ability_metamorphosis_aura:IsDebuff()
	return false
end

function modifier_ability_metamorphosis_aura:IsStunDebuff()
	return false
end

function modifier_ability_metamorphosis_aura:IsPurgable()
	return false
end

function modifier_ability_metamorphosis_aura:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "metamorph_aura_tooltip" )

	if not IsServer() then return end
end

function modifier_ability_metamorphosis_aura:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_metamorphosis_aura:IsAura()
	return true
end

function modifier_ability_metamorphosis_aura:GetModifierAura()
	return "modifier_ability_metamorphosis"
end

function modifier_ability_metamorphosis_aura:GetAuraRadius()
	return self.radius
end

function modifier_ability_metamorphosis_aura:GetAuraDuration()
	return 1
end

function modifier_ability_metamorphosis_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ability_metamorphosis_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_ability_metamorphosis_aura:GetAuraSearchFlags()
	return 0
end

function modifier_ability_metamorphosis_aura:GetAuraEntityReject( hEntity )
	if IsServer() then
		if hEntity:GetPlayerOwnerID()~=self:GetParent():GetPlayerOwnerID() then
			return true
		end
	end

	return false
end

modifier_ability_metamorphosis = {}

function modifier_ability_metamorphosis:IsHidden()
	return false
end

function modifier_ability_metamorphosis:IsDebuff()
	return false
end

function modifier_ability_metamorphosis:IsStunDebuff()
	return false
end

function modifier_ability_metamorphosis:IsPurgable()
	return false
end

function modifier_ability_metamorphosis:OnCreated( kv )
	self.bat = self:GetAbility():GetSpecialValueFor( "base_attack_time" )
	self.range = self:GetAbility():GetSpecialValueFor( "bonus_range" )
	self.damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
	self.slow = self:GetAbility():GetSpecialValueFor( "speed_loss" )
	local delay = self:GetAbility():GetSpecialValueFor( "transformation_time" )

	self.projectile = 900

	if not IsServer() then return end

	self.attack = self:GetParent():GetAttackCapability()
	if self.attack == DOTA_UNIT_CAP_RANGED_ATTACK then
		self.range = 0
		self.projectile = 0
	end
	self:GetParent():SetAttackCapability( DOTA_UNIT_CAP_RANGED_ATTACK )

	self:GetAbility():SetContextThink(DoUniqueString( "ability_metamorphosis" ), function()
		self:GetParent():StartGesture( ACT_DOTA_CAST_ABILITY_3 )
	end, FrameTime())

	self.stun = true
	self:StartIntervalThink( delay )

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_transform.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Terrorblade.Metamorphosis", self:GetParent() )
end

function modifier_ability_metamorphosis:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_metamorphosis:OnDestroy()
	if not IsServer() then return end

	self:GetParent():SetAttackCapability( self.attack )
end

function modifier_ability_metamorphosis:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
		MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
	}
end

function modifier_ability_metamorphosis:GetModifierBaseAttack_BonusDamage()
	return self.damage
end

function modifier_ability_metamorphosis:GetModifierBaseAttackTimeConstant()
	return self.bat
end

function modifier_ability_metamorphosis:GetModifierMoveSpeedBonus_Constant()
	return self.slow
end

function modifier_ability_metamorphosis:GetModifierProjectileSpeedBonus()
	return self.projectile
end

function modifier_ability_metamorphosis:GetModifierAttackRangeBonus()
	return self.range
end

function modifier_ability_metamorphosis:GetModifierModelChange()
	return "models/heroes/terrorblade/demon.vmdl"
end

function modifier_ability_metamorphosis:GetModifierModelScale()
	return 10
end

function modifier_ability_metamorphosis:GetModifierProjectileName()
	return "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf"
end

function modifier_ability_metamorphosis:GetAttackSound()
	return "Hero_Terrorblade_Morphed.Attack"
end

function modifier_ability_metamorphosis:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = self.stun,
	}
end

function modifier_ability_metamorphosis:OnIntervalThink()
	self.stun = false
end

function modifier_ability_metamorphosis:GetEffectName()
	return "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf"
end

function modifier_ability_metamorphosis:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end