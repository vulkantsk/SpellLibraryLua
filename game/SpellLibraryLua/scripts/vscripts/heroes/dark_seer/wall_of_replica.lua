ability_wall_of_replica = {}

LinkLuaModifier( "modifier_ability_wall_of_replica_thinker", "heroes/dark_seer/wall_of_replica", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_wall_of_replica_debuff", "heroes/dark_seer/wall_of_replica", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_wall_of_replica_illusion", "heroes/dark_seer/wall_of_replica", LUA_MODIFIER_MOTION_NONE )

function ability_wall_of_replica:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor( "duration" )

	CreateModifierThinker(
		caster,
		self,
		"modifier_ability_wall_of_replica_thinker",
		{
			duration = duration,
			x = caster:GetRightVector().x,
			y = caster:GetRightVector().y,
		},
		caster:GetCursorPosition(),
		caster:GetTeamNumber(),
		false
	)
end

modifier_ability_wall_of_replica_debuff = {}

function modifier_ability_wall_of_replica_debuff:IsHidden()
	return false
end

function modifier_ability_wall_of_replica_debuff:IsDebuff()
	return true
end

function modifier_ability_wall_of_replica_debuff:IsStunDebuff()
	return false
end

function modifier_ability_wall_of_replica_debuff:IsPurgable()
	return true
end

function modifier_ability_wall_of_replica_debuff:OnCreated( kv )
	self.slow = -self:GetAbility():GetSpecialValueFor( "movement_slow" )
end

function modifier_ability_wall_of_replica_debuff:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_wall_of_replica_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_ability_wall_of_replica_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

modifier_ability_wall_of_replica_illusion = {}

function modifier_ability_wall_of_replica_illusion:IsHidden()
	return true
end

function modifier_ability_wall_of_replica_illusion:IsPurgable()
	return false
end

function modifier_ability_wall_of_replica_illusion:OnCreated( kv )
	if not IsServer() then return end

	self:PlayEffects()
end

function modifier_ability_wall_of_replica_illusion:GetStatusEffectName()
	return "particles/status_fx/status_effect_dark_seer_illusion.vpcf"
end

function modifier_ability_wall_of_replica_illusion:StatusEffectPriority()
	return 10001
end

function modifier_ability_wall_of_replica_illusion:PlayEffects()
	local particle_cast = "particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica_replicate.vpcf"

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

modifier_ability_wall_of_replica_thinker = {}

function modifier_ability_wall_of_replica_thinker:IsHidden()
	return false
end

function modifier_ability_wall_of_replica_thinker:IsDebuff()
	return false
end

function modifier_ability_wall_of_replica_thinker:IsStunDebuff()
	return false
end

function modifier_ability_wall_of_replica_thinker:IsPurgable()
	return false
end

function modifier_ability_wall_of_replica_thinker:OnCreated( kv )
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.team = self.caster:GetTeamNumber()

	self.outgoing = self:GetAbility():GetSpecialValueFor( "replica_damage_outgoing" )
	self.incoming = self:GetAbility():GetSpecialValueFor( "replica_damage_incoming" )
	self.duration = self:GetAbility():GetSpecialValueFor( "slow_duration" )

	local length = self:GetAbility():GetSpecialValueFor( "width" )
	if self.caster:HasScepter() then
		length = length * self:GetAbility():GetSpecialValueFor( "scepter_length_multiplier" )
	end

	if not IsServer() then
		return
	end

	local direction = Vector( kv.x, kv.y, 0 ):Normalized()
	self.origin = self:GetParent():GetOrigin() + direction*length/2
	self.target = self:GetParent():GetOrigin() - direction*length/2

	self.width = 50
	self.bounty = 5
	local tick = 0.1
	self.illusions = {}

	self:StartIntervalThink( tick )
	self:OnIntervalThink()

	self:PlayEffects()
end

function modifier_ability_wall_of_replica_thinker:OnDestroy()
	if not IsServer() then
		return
	end

	StopSoundOn( "Hero_Dark_Seer.Wall_of_Replica_lp", self:GetParent() )

	UTIL_Remove( self:GetParent() )
end

function modifier_ability_wall_of_replica_thinker:OnIntervalThink()
	local enemies = FindUnitsInLine(
		self.team,
		self.origin,
		self.target,
		nil,
		self.width,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS	-- int, flag filter
	)

	for _,enemy in pairs(enemies) do
		local id = enemy:GetEntityIndex()
		if (not self.illusions[id]) or (not self.illusions[id]:IsAlive()) then
			if (not enemy:IsMagicImmune()) and (not enemy:IsInvulnerable()) then
				enemy:AddNewModifier(
					self.caster,
					self.ability,
					"modifier_ability_wall_of_replica_debuff",
					{ duration = self.duration }
				)
			end
			local illu = CreateIllusions(
				self.caster,
				enemy,
				{
					outgoing_damage = self.outgoing,
					incoming_damage = self.incoming,
					bounty_base = self.bounty,
					duration = self:GetRemainingTime(),
				},
				1,
				64,
				false,
				true
			)
			illu = illu[1]
			illu:AddNewModifier(
				self.caster,
				self.ability,
				"modifier_ability_wall_of_replica_illusion",
				{}
			)

			self.illusions[id] = illu
		end
	end
end

function modifier_ability_wall_of_replica_thinker:PlayEffects()
	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, self.origin )
	ParticleManager:SetParticleControl( effect_cast, 1, self.target )

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false 
	)

	EmitSoundOn( "Hero_Dark_Seer.Wall_of_Replica_Start", self:GetParent() )
	EmitSoundOn( "Hero_Dark_Seer.Wall_of_Replica_lp", self:GetParent() )
end