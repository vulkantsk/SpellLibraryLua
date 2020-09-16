ability_breathe_fire = {}

LinkLuaModifier( "modifier_ability_breathe_fire", "heroes/dragon_knight/breathe_fire", LUA_MODIFIER_MOTION_NONE )

function ability_breathe_fire:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()

	if target then point = target:GetOrigin() end

	local projectile_direction = point - caster:GetOrigin()

	local info = {
		Source = caster,
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		bDeleteOnHit = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		EffectName = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf",
		fDistance = self:GetSpecialValueFor( "range" ),
		fStartRadius = self:GetSpecialValueFor( "start_radius" ),
		fEndRadius = self:GetSpecialValueFor( "end_radius" ),
		vVelocity = projectile_direction:Normalized() * self:GetSpecialValueFor( "speed" ),
	}

	ProjectileManager:CreateLinearProjectile(info)

	EmitSoundOn( "Hero_DragonKnight.BreathFire", caster )
end

function ability_breathe_fire:OnProjectileHit( target, location )
	if not target then return end

	local damage = self:GetAbilityDamage()
	local duration = self:GetSpecialValueFor( "duration" )

	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
		ability = self,
	}

	ApplyDamage(damageTable)

	target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_ability_breathe_fire",
		{ duration = duration }
	)
end

modifier_ability_breathe_fire = {}

function modifier_ability_breathe_fire:IsHidden()
	return false
end

function modifier_ability_breathe_fire:IsDebuff()
	return true
end

function modifier_ability_breathe_fire:IsStunDebuff()
	return false
end

function modifier_ability_breathe_fire:IsPurgable()
	return true
end

function modifier_ability_breathe_fire:OnCreated( kv )
	self.reduction = self:GetAbility():GetSpecialValueFor( "reduction" )
end

function modifier_ability_breathe_fire:OnRefresh( kv )
	self.reduction = self:GetAbility():GetSpecialValueFor( "reduction" )	
end

function modifier_ability_breathe_fire:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_ability_breathe_fire:GetModifierDamageOutgoing_Percentage()
	return self.reduction
end