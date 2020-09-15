ability_vacuum = {}

LinkLuaModifier( "modifier_ability_vacuum", "heroes/dark_seer/vacuum", LUA_MODIFIER_MOTION_HORIZONTAL )

function ability_vacuum:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

function ability_vacuum:GetCooldown( level )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "scepter_cooldown" )
	end

	return self.BaseClass.GetCooldown( self, level )
end

function ability_vacuum:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local radius = self:GetSpecialValueFor( "radius" )
	local tree = self:GetSpecialValueFor( "radius_tree" )
	local duration = self:GetSpecialValueFor( "duration" )

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		point,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS,
		0,
		false
	)

	for _,enemy in pairs( enemies ) do
		enemy:AddNewModifier(
			caster,
			self,
			"modifier_ability_vacuum",
			{
				duration = duration,
				x = point.x,
				y = point.y,
			}
		)
	end

	GridNav:DestroyTreesAroundPoint( point, tree, false )

	self:PlayEffects( point, radius )
end

function ability_vacuum:PlayEffects( point, radius )
	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_dark_seer/dark_seer_vacuum.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, point )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOnLocationWithCaster( point, "Hero_Dark_Seer.Vacuum", self:GetCaster() )
end

modifier_ability_vacuum = {}

function modifier_ability_vacuum:IsHidden()
	return false
end

function modifier_ability_vacuum:IsDebuff()
	return true
end

function modifier_ability_vacuum:IsStunDebuff()
	return true
end

function modifier_ability_vacuum:IsPurgable()
	return true
end

function modifier_ability_vacuum:OnCreated( kv )
	self.damage = self:GetAbility():GetSpecialValueFor( "damage" )

	if not IsServer() then
		return
	end

	self.abilityDamageType = self:GetAbility():GetAbilityDamageType()

	local center = Vector( kv.x, kv.y, 0 )
	self.direction = center - self:GetParent():GetOrigin()
	self.speed = self.direction:Length2D()/self:GetDuration()

	self.direction.z = 0
	self.direction = self.direction:Normalized()

	if not self:ApplyHorizontalMotionController() then
		self:Destroy()
	end
end

function modifier_ability_vacuum:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_vacuum:OnDestroy()
	if not IsServer() then
		return
	end

	self:GetParent():RemoveHorizontalMotionController( self )

	local damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.damage,
		damage_type = self.abilityDamageType,
		ability = self:GetAbility()
	}
	ApplyDamage(damageTable)
end

function modifier_ability_vacuum:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}

	return funcs
end

function modifier_ability_vacuum:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function modifier_ability_vacuum:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end

function modifier_ability_vacuum:UpdateHorizontalMotion( me, dt )
	local target = me:GetAbsOrigin() + self.direction * self.speed * dt
	me:SetAbsOrigin( target )
end

function modifier_ability_vacuum:OnHorizontalMotionInterrupted()
	self:Destroy()
end