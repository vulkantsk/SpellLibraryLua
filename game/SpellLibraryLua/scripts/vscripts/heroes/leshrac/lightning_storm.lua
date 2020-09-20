ability_lightning_storm = {}

LinkLuaModifier( "modifier_ability_lightning_storm", "heroes/leshrac/lightning_storm", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_lightning_storm_thinker", "heroes/leshrac/lightning_storm", LUA_MODIFIER_MOTION_NONE )

function ability_lightning_storm:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb( self ) then return end

	local thinker = CreateModifierThinker(
		caster,
		self,
		"modifier_ability_lightning_storm_thinker",
		{},
		caster:GetOrigin(),
		caster:GetTeamNumber(),
		false
	)
	thinker:FindModifierByName( "modifier_ability_lightning_storm_thinker" ):Cast( target )
end

modifier_ability_lightning_storm = {}

function modifier_ability_lightning_storm:IsHidden()
	return false
end

function modifier_ability_lightning_storm:IsDebuff()
	return true
end

function modifier_ability_lightning_storm:IsStunDebuff()
	return false
end

function modifier_ability_lightning_storm:IsPurgable()
	return true
end

function modifier_ability_lightning_storm:OnCreated( kv )
	if IsServer() then
		self.slow = kv.slow
	end
end

function modifier_ability_lightning_storm:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACKED,
	}

	return funcs
end

function modifier_ability_lightning_storm:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

modifier_ability_lightning_storm_thinker = {}

function modifier_ability_lightning_storm_thinker:IsHidden()
	return true
end

function modifier_ability_lightning_storm_thinker:IsPurgable()
	return false
end

function modifier_ability_lightning_storm_thinker:OnCreated( kv )
	if not IsServer() then return end

	self.delay = self:GetAbility():GetSpecialValueFor( "jump_delay" )
	self.count = self:GetAbility():GetSpecialValueFor( "jump_count" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.duration = self:GetAbility():GetSpecialValueFor( "slow_duration" )
	self.slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed" )

	self.targets = {}
	self.damageTable = {
		attacker = self:GetCaster(),
		damage = self:GetAbility():GetAbilityDamage(),
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(),
	}
end

function modifier_ability_lightning_storm_thinker:Cast( target )
	self.current_target = target
	self.started = false
	self:StartIntervalThink( self.delay )
end

function modifier_ability_lightning_storm_thinker:OnDestroy()
	if not IsServer() then return end

	UTIL_Remove( self:GetParent() )
end

function modifier_ability_lightning_storm_thinker:OnIntervalThink()
	if not self.started then
		self.started = true

		self:Struck( self.current_target )
		return
	end

	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		self.current_target:GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
		FIND_CLOSEST,
		false
	)

	local found = false
	for _,enemy in pairs(enemies) do
		if not self.targets[enemy] then
			found = true
			self.current_target = enemy
			self:Struck( enemy )
			break
		end
	end

	if not found then
		self:Destroy()
	end
end

function modifier_ability_lightning_storm_thinker:Struck( target )
	if not target:IsMagicImmune() then
		self.damageTable.victim = target
		ApplyDamage( self.damageTable )

		target:AddNewModifier(
			self:GetCaster(),
			self:GetAbility(),
			"modifier_ability_lightning_storm",
			{
				duration = self.duration,
				slow = self.slow,
			}
		)

		self.targets[target] = true
	end

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_leshrac/leshrac_lightning_bolt.vpcf", PATTACH_CUSTOMORIGIN, target )
	ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin() + Vector( 0, 0, 800 ) )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector( 0, 0, 0 ),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Leshrac.Lightning_Storm", target )

	self.count = self.count - 1

	if self.count <= 0 then
		self:Destroy()
	end
end

function modifier_ability_lightning_storm_thinker:PlayEffects( target )
	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_leshrac/leshrac_lightning_bolt.vpcf", PATTACH_CUSTOMORIGIN, target )
	ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin() + Vector( 0, 0, 800 ) )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector( 0, 0, 0 ),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Leshrac.Lightning_Storm", target )
end