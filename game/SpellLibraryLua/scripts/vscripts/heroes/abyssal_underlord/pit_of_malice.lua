ability_pit_of_malice = {}

LinkLuaModifier( "modifier_ability_pit_of_malice", "heroes/abyssal_underlord/pit_of_malice", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_pit_of_malice_cooldown", "heroes/abyssal_underlord/pit_of_malice", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_pit_of_malice_thinker", "heroes/abyssal_underlord/pit_of_malice", LUA_MODIFIER_MOTION_NONE )

function ability_pit_of_malice:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

function ability_pit_of_malice:OnAbilityPhaseStart()
	local point = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor( "radius" )

	self.effect_cast = ParticleManager:CreateParticleForTeam( "particles/units/heroes/heroes_underlord/underlord_pitofmalice_pre.vpcf", PATTACH_WORLDORIGIN, self:GetCaster(), self:GetCaster():GetTeamNumber() )
	ParticleManager:SetParticleControl( self.effect_cast, 0, point )
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( radius, 1, 1 ) )

	EmitSoundOnLocationForAllies( point, "Hero_AbyssalUnderlord.PitOfMalice.Start", self:GetCaster() )

	return true
end
function ability_pit_of_malice:OnAbilityPhaseInterrupted()
	ParticleManager:DestroyParticle( self.effect_cast, true )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

end

function ability_pit_of_malice:OnSpellStart()
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local duration = self:GetSpecialValueFor( "pit_duration" )

	CreateModifierThinker(
		caster,
		self,
		"modifier_ability_pit_of_malice_thinker",
		{ duration = duration },
		point,
		caster:GetTeamNumber(),
		false
	)
end


modifier_ability_pit_of_malice = {}

function modifier_ability_pit_of_malice:IsHidden()
	return false
end

function modifier_ability_pit_of_malice:IsDebuff()
	return true
end

function modifier_ability_pit_of_malice:IsStunDebuff()
	return false
end

function modifier_ability_pit_of_malice:IsPurgable()
	return true
end

function modifier_ability_pit_of_malice:GetPriority()
	return MODIFIER_PRIORITY_HIGH
end

function modifier_ability_pit_of_malice:OnCreated( kv )
	local interval = self:GetAbility():GetSpecialValueFor( "pit_interval" )

	if not IsServer() then return end

	self:GetParent():AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_pit_of_malice_cooldown",
		{
			duration = interval,
		}
	)

	EmitSoundOn( self:GetParent():IsHero() and "Hero_AbyssalUnderlord.Pit.TargetHero" or "Hero_AbyssalUnderlord.Pit.Target", self:GetParent() )

end

function modifier_ability_pit_of_malice:CheckState()
	local state = {
		[MODIFIER_STATE_INVISIBLE] = false,
		[MODIFIER_STATE_ROOTED] = true,
	}

	return state
end

function modifier_ability_pit_of_malice:GetEffectName()
	return "particles/units/heroes/heroes_underlord/abyssal_underlord_pitofmalice_stun.vpcf"
end

function modifier_ability_pit_of_malice:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_pit_of_malice_cooldown = {}

function modifier_ability_pit_of_malice_cooldown:IsHidden()
	return true
end

function modifier_ability_pit_of_malice_cooldown:IsDebuff()
	return true
end

function modifier_ability_pit_of_malice_cooldown:IsPurgable()
	return false
end

function modifier_ability_pit_of_malice_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end

modifier_ability_pit_of_malice_thinker = class({})

function modifier_ability_pit_of_malice_thinker:IsHidden()
	return false
end

function modifier_ability_pit_of_malice_thinker:IsDebuff()
	return false
end

function modifier_ability_pit_of_malice_thinker:IsPurgable()
	return false
end

function modifier_ability_pit_of_malice_thinker:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.pit_damage = self:GetAbility():GetSpecialValueFor( "pit_damage" )
	self.duration = self:GetAbility():GetSpecialValueFor( "ensnare_duration" )

	if not IsServer() then return end
	self.caster = self:GetCaster()
	self.parent = self:GetParent()

	self:StartIntervalThink( 0.033 )
	self:OnIntervalThink()

	self:PlayEffects()

end

function modifier_ability_pit_of_malice_thinker:OnIntervalThink()
	local enemies = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		self.parent:GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		local modifier = enemy:FindModifierByNameAndCaster( "modifier_ability_pit_of_malice_cooldown", self:GetCaster() )
		if not modifier then
			enemy:AddNewModifier(
				self.caster,
				self:GetAbility(),
				"modifier_ability_pit_of_malice",
				{ duration = self.duration }
			)
		end
	end
end

function modifier_ability_pit_of_malice_thinker:PlayEffects()
	local parent = self:GetParent()

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/underlord_pitofmalice.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
	ParticleManager:SetParticleControl( effect_cast, 0, parent:GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 1, 1 ) )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( self:GetDuration(), 0, 0 ) )

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false, 
		false 
	)

	EmitSoundOn( "Hero_AbyssalUnderlord.PitOfMalice", parent )
end