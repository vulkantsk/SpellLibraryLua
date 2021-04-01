LinkLuaModifier( "modifier_ability_last_word_silence", "heroes/silencer/last_word", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_last_word", "heroes/silencer/last_word", LUA_MODIFIER_MOTION_NONE )

ability_last_word = {}

function ability_last_word:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor( "debuff_duration" )

	target:AddNewModifier(
		caster,
		self,
		"modifier_ability_last_word",
		{ duration = duration }
	)

	local direction = target:GetOrigin()-self:GetCaster():GetOrigin()
	direction.z = 0
	direction = direction:Normalized()

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_silencer/silencer_last_word_status_cast.vpcf",
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
	ParticleManager:SetParticleControlForward( effect_cast, 1, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Silencer.LastWord.Cast", self:GetCaster() )
end

modifier_ability_last_word = {}

function modifier_ability_last_word:IsHidden()
	return false
end

function modifier_ability_last_word:IsDebuff()
	return true
end

function modifier_ability_last_word:IsStunDebuff()
	return false
end

function modifier_ability_last_word:IsPurgable()
	return true
end

function modifier_ability_last_word:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_last_word:OnCreated( kv )
	self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
	self.damage = self:GetAbility():GetSpecialValueFor( "damage" )

	if not IsServer() then return end

	self:StartIntervalThink( kv.duration )

	EmitSoundOn( "Hero_Silencer.LastWord.Target", self:GetParent() )
end


function modifier_ability_last_word:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
	}
end

function modifier_ability_last_word:GetModifierProvidesFOWVision()
	return 1
end

function modifier_ability_last_word:OnAbilityFullyCast( params )
	if not IsServer() then return end
	if params.unit~=self:GetParent() then return end
	if params.ability:IsItem() then return end

	self:Silence()
end

function modifier_ability_last_word:OnIntervalThink()
	self:Silence()
end

function modifier_ability_last_word:Silence()
	self:GetParent():AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_last_word_silence",
		{ duration = self.duration }
	)

	local damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self
	}
	ApplyDamage( damageTable )

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_silencer/silencer_last_word_dmg.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetParent()
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Silencer.LastWord.Damage", self:GetParent() )
	StopSoundOn( "Hero_Silencer.LastWord.Target", self:GetParent() )

	self:Destroy()
end

function modifier_ability_last_word:GetEffectName()
	return "particles/units/heroes/hero_silencer/silencer_last_word_status.vpcf"
end

function modifier_ability_last_word:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_last_word_silence = {}

function modifier_ability_last_word_silence:IsDebuff()
	return true
end

function modifier_ability_last_word_silence:IsStunDebuff()
	return false
end

function modifier_ability_last_word_silence:IsPurgable()
	return true
end

function modifier_ability_last_word_silence:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true }
end

function modifier_ability_last_word_silence:GetEffectName()
	return "particles/generic_gameplay/generic_silenced.vpcf"
end

function modifier_ability_last_word_silence:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end