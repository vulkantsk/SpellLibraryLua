ability_malefice = {}

LinkLuaModifier( "modifier_ability_malefice", "heroes/enigma/malefice", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_malefice_stun", "heroes/enigma/malefice", LUA_MODIFIER_MOTION_NONE )

function ability_malefice:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb( self ) then return end

	local duration = self:GetSpecialValueFor("duration")

	target:AddNewModifier(
		caster,
		self,
		"modifier_ability_malefice",
		{ duration = duration }
	)

	EmitSoundOn( "Hero_Enigma.Malefice", target )
end

modifier_ability_malefice = {}

function modifier_ability_malefice:IsHidden()
	return false
end

function modifier_ability_malefice:IsDebuff()
	return true
end

function modifier_ability_malefice:IsStunDebuff()
	return false
end

function modifier_ability_malefice:IsPurgable()
	return true
end

function modifier_ability_malefice:OnCreated( kv )
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

function modifier_ability_malefice:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_malefice:OnIntervalThink()
	self:GetParent():AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_malefice_stun",
		{ duration = self.stun }
	)

	ApplyDamage( self.damageTable )

	EmitSoundOn( "Hero_Enigma.MaleficeTick", self:GetParent() )
end

function modifier_ability_malefice:GetEffectName()
	return "particles/units/heroes/hero_enigma/enigma_malefice.vpcf"
end

function modifier_ability_malefice:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ability_malefice:GetStatusEffectName()
	return "particles/status_fx/status_effect_enigma_malefice.vpcf"
end

modifier_ability_malefice_stun = {}

function modifier_ability_malefice_stun:IsDebuff()
	return true
end

function modifier_ability_malefice_stun:IsStunDebuff()
	return true
end

function modifier_ability_malefice_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_ability_malefice_stun:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_ability_malefice_stun:GetOverrideAnimation( params )
	return ACT_DOTA_DISABLED
end

function modifier_ability_malefice_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_ability_malefice_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
