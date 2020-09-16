ability_doom = {}

LinkLuaModifier( "modifier_ability_doom", "heroes/doom_bringer/doom", LUA_MODIFIER_MOTION_NONE )

function ability_doom:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb( self ) then return end

	local duration = self:GetSpecialValueFor( "duration" )

	target:AddNewModifier(
		caster,
		self,
		"modifier_ability_doom",
		{ duration = duration }
	)
end

modifier_ability_doom = class({})

function modifier_ability_doom:IsHidden()
	return false
end

function modifier_ability_doom:IsDebuff()
	return true
end

function modifier_ability_doom:IsStunDebuff()
	return false
end

function modifier_ability_doom:IsPurgable()
	return false
end

function modifier_ability_doom:OnCreated( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.deniable = self:GetAbility():GetSpecialValueFor( "deniable_pct" )
	self.interval = 1

	self.check_radius = 900

	if not IsServer() then return end

	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(),
	}
	ApplyDamage( self.damageTable )

	self:StartIntervalThink( self.interval )

	EmitSoundOn( "Hero_DoomBringer.Doom", self:GetParent() )
end

function modifier_ability_doom:OnRefresh( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.deniable = self:GetAbility():GetSpecialValueFor( "deniable_pct" )

	if not IsServer() then return end

	self.damageTable.damage = damage

	EmitSoundOn( "Hero_DoomBringer.Doom", self:GetParent() )
end

function modifier_ability_doom:OnDestroy()
	if not IsServer() then return end

	StopSoundOn( "Hero_DoomBringer.Doom", self:GetParent() )
end

function modifier_ability_doom:CheckState()
	return {
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
		[MODIFIER_STATE_SPECIALLY_DENIABLE] = self:GetParent():GetHealthPercent() < self.deniable,
	}
end

function modifier_ability_doom:OnIntervalThink()
	ApplyDamage( self.damageTable )
end

function modifier_ability_doom:GetStatusEffectName()
	return "particles/status_fx/status_effect_doom.vpcf"
end

function modifier_ability_doom:StatusEffectPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_ability_doom:GetEffectName()
	return "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf"
end