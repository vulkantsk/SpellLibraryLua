LinkLuaModifier( "modifier_ability_dual_breath", "heroes/jakiro/dual_breath", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_dual_breath_fire", "heroes/jakiro/dual_breath", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_dual_breath_ice", "heroes/jakiro/dual_breath", LUA_MODIFIER_MOTION_NONE )

ability_dual_breath = {}

function ability_dual_breath:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()

	local delay = self:GetSpecialValueFor( "fire_delay" )

	if target then
		point = target:GetAbsOrigin()
	end

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_dual_breath",
		{
			duration = delay,
			x = point.x,
			y = point.y,
		}
	)

end

function ability_dual_breath:OnProjectileHit_ExtraData( target, location, data )
	if not target then return end

	local caster = self:GetCaster()
	local delay = self:GetSpecialValueFor( "fire_delay" )
	local duration = self:GetDuration()

	local modifier = "modifier_ability_dual_breath_ice"
	if data.fire == 1 then
		modifier = "modifier_ability_dual_breath_fire"
	end

	target:AddNewModifier(
		caster,
		self,
		modifier,
		{ duration = duration }
	)
end

modifier_ability_dual_breath = {}

function modifier_ability_dual_breath:IsHidden()
	return true
end

function modifier_ability_dual_breath:IsDebuff()
	return false
end

function modifier_ability_dual_breath:IsStunDebuff()
	return false
end

function modifier_ability_dual_breath:IsPurgable()
	return false
end

function modifier_ability_dual_breath:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end

function modifier_ability_dual_breath:RemoveOnDeath()
	return false
end

function modifier_ability_dual_breath:OnCreated( kv )
	local distance = self:GetAbility():GetSpecialValueFor( "range" )
	local start_radius = self:GetAbility():GetSpecialValueFor( "start_radius" )
	local end_radius = self:GetAbility():GetSpecialValueFor( "end_radius" )
	self.speed_ice = self:GetAbility():GetSpecialValueFor( "speed" )
	self.speed_fire = self:GetAbility():GetSpecialValueFor( "speed_fire" )

	if not IsServer() then return end
	local caster = self:GetCaster()

	self.direction = Vector( kv.x, kv.y, 0 ) - caster:GetAbsOrigin()
	self.direction.z = 0
	self.direction = self.direction:Normalized()

	self.info = {
		Source = caster,
		Ability = self:GetAbility(),
		vSpawnOrigin = caster:GetAbsOrigin(),
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fDistance = distance,
		fStartRadius = start_radius,
		fEndRadius = end_radius,
	}

	self.info.EffectName = "particles/units/heroes/hero_jakiro/jakiro_dual_breath_ice.vpcf"
	self.info.vVelocity = self.direction * self.speed_ice
	self.info.ExtraData = {
		fire = 0
	}
	ProjectileManager:CreateLinearProjectile( self.info )

	EmitSoundOn( "Hero_Jakiro.DualBreath.Cast", self:GetCaster() )
end

function modifier_ability_dual_breath:OnRemoved()
	if not IsServer() then return end

	self.info.EffectName = "particles/units/heroes/hero_jakiro/jakiro_dual_breath_fire.vpcf"
	self.info.vVelocity = self.direction * self.speed_fire
	self.info.ExtraData = {
		fire = 1
	}
	ProjectileManager:CreateLinearProjectile( self.info )

	local caster = self:GetCaster()

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_jakiro/jakiro_dual_breath_fire_launch_2.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		caster
	)
	ParticleManager:SetParticleControl( effect_cast, 0, caster:GetAbsOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, self.info.vVelocity )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		9,
		caster,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_attack1",
		Vector(),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

modifier_ability_dual_breath_fire = {}

function modifier_ability_dual_breath_fire:IsHidden()
	return false
end

function modifier_ability_dual_breath_fire:IsDebuff()
	return true
end

function modifier_ability_dual_breath_fire:IsStunDebuff()
	return false
end

function modifier_ability_dual_breath_fire:IsPurgable()
	return true
end

function modifier_ability_dual_breath_fire:OnCreated( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "burn_damage" )

	if not IsServer() then return end

	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(),
	}

	self:StartIntervalThink( 0.5 )
	self:OnIntervalThink()
end

function modifier_ability_dual_breath_fire:OnRefresh( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "burn_damage" )
	if not IsServer() then return end
	
	self.damageTable.damage = damage
end

function modifier_ability_dual_breath_fire:OnIntervalThink()
	ApplyDamage( self.damageTable )
end

function modifier_ability_dual_breath_fire:GetEffectName()
	return "particles/units/heroes/hero_jakiro/jakiro_liquid_fire_debuff.vpcf"
end

function modifier_ability_dual_breath_fire:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_dual_breath_ice = {}

function modifier_ability_dual_breath_ice:IsHidden()
	return false
end

function modifier_ability_dual_breath_ice:IsDebuff()
	return true
end

function modifier_ability_dual_breath_ice:IsStunDebuff()
	return false
end

function modifier_ability_dual_breath_ice:IsPurgable()
	return true
end

function modifier_ability_dual_breath_ice:OnCreated( kv )
	self.as_slow = self:GetAbility():GetSpecialValueFor( "slow_attack_speed_pct" )
	self.ms_slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed_pct" )
end

modifier_ability_dual_breath_ice.OnRefresh = modifier_ability_dual_breath_ice.OnCreated

function modifier_ability_dual_breath_ice:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_ability_dual_breath_ice:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_slow
end

function modifier_ability_dual_breath_ice:GetModifierAttackSpeedBonus_Constant()
	return self.as_slow
end

function modifier_ability_dual_breath_ice:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_ability_dual_breath_ice:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end