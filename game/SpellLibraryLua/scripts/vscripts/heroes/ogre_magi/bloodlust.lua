LinkLuaModifier( "modifier_ability_bloodlust", "heroes/ogre_magi/bloodlust", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_bloodlust_buff", "heroes/ogre_magi/bloodlust", LUA_MODIFIER_MOTION_NONE )

ability_bloodlust = {}

function ability_bloodlust:GetIntrinsicModifierName()
	return "modifier_ability_bloodlust"
end

function ability_bloodlust:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local duration = self:GetSpecialValueFor( "duration" )

	target:AddNewModifier(
		caster,
		self,
		"modifier_ability_bloodlust_buff",
		{ duration = duration }
	)

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_cast.vpcf",
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
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		2,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		3,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_OgreMagi.Bloodlust.Cast", self:GetCaster() )
end

modifier_ability_bloodlust = {}

function modifier_ability_bloodlust:IsHidden()
	return true
end

function modifier_ability_bloodlust:IsPurgable()
	return false
end

function modifier_ability_bloodlust:OnCreated( kv )
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.radius = self.ability:GetCastRange( self.caster:GetOrigin(), self.caster )
	local interval = 1

	if not IsServer() then return end

	self:StartIntervalThink( interval )
end

function modifier_ability_bloodlust:OnIntervalThink()
	if not self.ability:GetAutoCastState() then return end

	if not self.ability:IsFullyCastable() then return end

	if self.caster:IsSilenced() then return end

	local allies = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		self.caster:GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,
		0,
		0,
		false
	)

	for _,ally in pairs(allies) do
		if not ally:HasModifier( "modifier_ability_bloodlust_buff" ) then
			self.caster:CastAbilityOnTarget( ally, self.ability, self.caster:GetPlayerOwnerID() )
			break
		end
	end
end

modifier_ability_bloodlust_buff = {}

function modifier_ability_bloodlust_buff:IsHidden()
	return false
end

function modifier_ability_bloodlust_buff:IsDebuff()
	return false
end

function modifier_ability_bloodlust_buff:IsPurgable()
	return true
end

function modifier_ability_bloodlust_buff:OnCreated( kv )
	self.model_scale = self:GetAbility():GetSpecialValueFor( "modelscale" )
	self.ms_bonus = self:GetAbility():GetSpecialValueFor( "bonus_movement_speed" )
	self.as_bonus = self:GetAbility():GetSpecialValueFor( "bonus_attack_speed" )
	local as_self = self:GetAbility():GetSpecialValueFor( "self_bonus" )

	if self:GetParent()==self:GetCaster() then
		self.as_bonus = self.as_self
	end

	if not IsServer() then return end

	EmitSoundOn( "Hero_OgreMagi.Bloodlust.Target", self:GetParent() )
	EmitSoundOnClient( "Hero_OgreMagi.Bloodlust.Target.FP", self:GetParent():GetPlayerOwner() )
end

modifier_ability_bloodlust_buff.OnRefresh = modifier_ability_bloodlust_buff.OnCreated

function modifier_ability_bloodlust_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MODEL_SCALE,
	}
end

function modifier_ability_bloodlust_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.as_bonus
end
function modifier_ability_bloodlust_buff:GetModifierAttackSpeedBonus_Constant()
	return self.ms_bonus
end

function modifier_ability_bloodlust_buff:GetModifierModelScale()
	return self.model_scale
end

function modifier_ability_bloodlust_buff:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end

function modifier_ability_bloodlust_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end