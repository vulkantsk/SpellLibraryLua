LinkLuaModifier( "modifier_ability_shadow_dance", "heroes/slark/shadow_dance", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_shadow_dance_passive", "heroes/slark/shadow_dance", LUA_MODIFIER_MOTION_NONE )

ability_shadow_dance = {}

function ability_shadow_dance:GetIntrinsicModifierName()
	return "modifier_ability_shadow_dance_passive"
end

function ability_shadow_dance:OnSpellStart()
	local caster = self:GetCaster()
	local bDuration = self:GetSpecialValueFor("duration")

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_shadow_dance",
		{ duration = bDuration }
	)
end

modifier_ability_shadow_dance = {}

function modifier_ability_shadow_dance:IsHidden()
	return false
end

function modifier_ability_shadow_dance:IsDebuff()
	return false
end

function modifier_ability_shadow_dance:IsPurgable()
	return false
end

function modifier_ability_shadow_dance:GetPriority()
	return MODIFIER_PRIORITY_HIGH
end

function modifier_ability_shadow_dance:OnCreated( kv )
	if not IsServer() then return end
	local parent = self:GetParent()
	local effect_cast = ParticleManager:CreateParticleForTeam(
		"particles/units/heroes/hero_slark/slark_shadow_dance.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		parent,
		parent:GetTeamNumber()
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		parent,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		3,
		parent,
		PATTACH_POINT_FOLLOW,
		"attach_eyeR",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		4,
		parent,
		PATTACH_POINT_FOLLOW,
		"attach_eyeL",
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

	EmitSoundOn( "Hero_Slark.ShadowDance", parent )

	effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_slark/slark_shadow_dance_dummy.vpcf",
		PATTACH_WORLDORIGIN,
		parent
	)
	ParticleManager:SetParticleControl( effect_cast, 0, parent:GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, parent:GetOrigin() )

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	self.effect_cast = effect_cast

	self:StartIntervalThink(FrameTime())
end

function modifier_ability_shadow_dance:OnDestroy( kv )
	if IsServer() then
		local sound_cast = "Hero_Slark.ShadowDance"
		StopSoundOn( sound_cast, self:GetParent() )
	end
end

function modifier_ability_shadow_dance:DeclareFunctions()
	return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL }
end

function modifier_ability_shadow_dance:GetModifierInvisibilityLevel()
	return 2
end

function modifier_ability_shadow_dance:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
	}
end

function modifier_ability_shadow_dance:OnIntervalThink()
	ParticleManager:SetParticleControl( self.effect_cast, 1, self:GetParent():GetOrigin() )
end

function modifier_ability_shadow_dance:GetStatusEffectName()
	return "particles/status_fx/status_effect_slark_shadow_dance.vpcf"
end

function modifier_ability_shadow_dance:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end

modifier_ability_shadow_dance_passive = {}

function modifier_ability_shadow_dance_passive:IsHidden()
	return self:GetStackCount()==1
end

function modifier_ability_shadow_dance_passive:IsDebuff()
	return false
end

function modifier_ability_shadow_dance_passive:IsPurgable()
	return false
end

function modifier_ability_shadow_dance_passive:OnCreated( kv )
	self.interval = self:GetAbility():GetSpecialValueFor( "activation_delay" )
	self.neutral_disable = self:GetAbility():GetSpecialValueFor( "neutral_disable" )
	self.bonus_regen = self:GetAbility():GetSpecialValueFor( "bonus_regen_pct" )
	self.bonus_movespeed = self:GetAbility():GetSpecialValueFor( "bonus_movement_speed" )

	if not IsServer() then return end

	local fountains = Entities:FindAllByClassname( 'ent_dota_fountain' )

	for _,foun in pairs(fountains) do
		if foun:GetTeamNumber()~=self:GetParent():GetTeamNumber() then
			self.fountain = foun
		end
	end

	if not self.fountain then self.fountain = self:GetParent() end

	self:StartIntervalThink( self.interval )
	self:OnIntervalThink()
end

function modifier_ability_shadow_dance_passive:OnRefresh( kv )
	self.interval = self:GetAbility():GetSpecialValueFor( "activation_delay" )
	self.neutral_disable = self:GetAbility():GetSpecialValueFor( "neutral_disable" )
end

function modifier_ability_shadow_dance_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_shadow_dance_passive:OnTakeDamage( params )
	if not IsServer() then return end
	if params.unit~=self:GetParent() then return end
	if not params.attacker:IsNeutralUnitType() then return end

	self.disable = true
	self:SetStackCount( 1 )
	self:StartIntervalThink( self.neutral_disable )
end

function modifier_ability_shadow_dance_passive:GetModifierHealthRegenPercentage()
	return self.bonus_regen * (1-self:GetStackCount())
end

function modifier_ability_shadow_dance_passive:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movespeed * (1-self:GetStackCount())
end

function modifier_ability_shadow_dance_passive:OnIntervalThink()
	if self.fountain:CanEntityBeSeenByMyTeam( self:GetParent() ) then
		self:SetStackCount( 1 )
	else
		self:SetStackCount( 0 )
	end
end

function modifier_ability_shadow_dance_passive:OnStackCountChanged( prev )
	if not IsServer() then return end
	if prev==self:GetStackCount() then return end

	if self:GetStackCount()==0 then
		self:PlayEffects()
	elseif self:GetStackCount()==1 then
		self:StopEffects()
	end
end

function modifier_ability_shadow_dance_passive:PlayEffects()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_slark/slark_regen.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetParent()
	)
	self.effect_cast = effect_cast
end

function modifier_ability_shadow_dance_passive:StopEffects()
	if not self.effect_cast then return end
	ParticleManager:DestroyParticle( self.effect_cast, false )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )
	self.effect_cast = nil
end