LinkLuaModifier( "modifier_ability_rolling_boulder", "heroes/earth_spirit/rolling_boulder", LUA_MODIFIER_MOTION_HORIZONTAL )

ability_rolling_boulder = {}

function ability_rolling_boulder:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local direction = point-caster:GetAbsOrigin()
	direction.z = 0
	direction = direction:Normalized()

	self.direction = direction

	self.modifier = caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_rolling_boulder",
		{
			x = direction.x,
			y = direction.y,
		}
	)

	EmitSoundOn( "Hero_EarthSpirit.RollingBoulder.Cast", caster )
end

function ability_rolling_boulder:OnProjectileHitHandle( target, location, iHandle )
	if not IsServer() then return end
	if not target then return end

	local rock_speed = self:GetSpecialValueFor( "rock_speed" )
	local rock_distance = self:GetSpecialValueFor( "rock_distance" )
	local damage = self:GetSpecialValueFor( "damage" )
	local duration = self:GetSpecialValueFor( "stun_duration" )
	local remnant = target:FindModifierByName( "modifier_ability_stone_caller" )
	
	if remnant then
		remnant:Destroy()

		ProjectileManager:UpdateLinearProjectileDirection( iHandle, self.direction*rock_speed, rock_distance )
		self.modifier:Upgrade()
		self.upgrade = true
		return false
	end

	local filter = UnitFilter(
		target,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		self:GetCaster():GetTeamNumber()
	)

	if filter~=UF_SUCCESS then
		return false
	end

	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self
	}

	ApplyDamage(damageTable)

	if self.upgrade then
		duration = duration + self:GetSpecialValueFor( "rock_bonus_duration" )
	end

	target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_stunned",
		{ duration = duration }
	)

	if target:IsConsideredHero() then
		if self.modifier and not self.modifier:IsNull() then
			self.modifier:End( self:GetCaster():GetAbsOrigin() )
			self.modifier = nil
		end

		self:GetCaster():SetAbsOrigin( target:GetAbsOrigin() + self.direction*80 )

		if self.upgrade then
			self.upgrade = nil
		end

		return true
	end
end

modifier_ability_rolling_boulder = {}

function modifier_ability_rolling_boulder:IsHidden()
	return false
end

function modifier_ability_rolling_boulder:IsDebuff()
	return false
end

function modifier_ability_rolling_boulder:IsPurgable()
	return false
end

function modifier_ability_rolling_boulder:OnCreated( kv )
	self.delay = self:GetAbility():GetSpecialValueFor( "delay" )
	self.speed = self:GetAbility():GetSpecialValueFor( "speed" )
	self.distance = self:GetAbility():GetSpecialValueFor( "distance" )

	if IsServer() then
		self.direction = Vector( kv.x, kv.y, 0 )
		self.origin = self:GetParent():GetAbsOrigin()

		self:StartIntervalThink( self.delay )

		self.effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_earth_spirit/espirit_rollingboulder.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			self:GetParent()
		)

		self:AddParticle(
			self.effect_cast,
			false,
			false,
			-1,
			false,
			false
		)

		EmitSoundOn( "Hero_EarthSpirit.RollingBoulder.Loop", self:GetParent() )
	end
end

function modifier_ability_rolling_boulder:OnDestroy( kv )
	if IsServer() then
		self:GetParent():InterruptMotionControllers( true )
	end
end

function modifier_ability_rolling_boulder:OnRemoved( kv )
	if IsServer() then
		if self.pre_collide then
			ParticleManager:SetParticleControl( self.effect_cast, 3, self.pre_collide )
		else
			ParticleManager:SetParticleControl( self.effect_cast, 3, self:GetParent():GetAbsOrigin() )
		end

		StopSoundOn( "Hero_EarthSpirit.RollingBoulder.Loop", self:GetParent() )
		EmitSoundOn( "Hero_EarthSpirit.RollingBoulder.Destroy", self:GetParent() )

	end
end

function modifier_ability_rolling_boulder:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function modifier_ability_rolling_boulder:OnIntervalThink()
	if self:ApplyHorizontalMotionController() == false then
		self:Destroy()
		return
	end

	local info = {
		Source = self:GetCaster(),
		Ability = self:GetAbility(),
		vSpawnOrigin = self:GetParent():GetAbsOrigin(),
		
	    bDeleteOnHit = true,
	    
	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
	    iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	    
	    EffectName = "",
	    fDistance = self.distance,
	    fStartRadius = 150,
	    fEndRadius =150,
		vVelocity = self.direction * self.speed,
	
		bHasFrontalCone = false,
		bReplaceExisting = false,
	}
	ProjectileManager:CreateLinearProjectile(info)
end

function modifier_ability_rolling_boulder:UpdateHorizontalMotion( me, dt )
	local pos = self:GetParent():GetAbsOrigin()
	
	if (pos-self.origin):Length2D()>=self.distance then
		self:Destroy()
		return
	end

	local target = pos + self.direction * (self.speed*dt)

	self:GetParent():SetAbsOrigin( target )
end

function modifier_ability_rolling_boulder:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_ability_rolling_boulder:Upgrade()
	self.speed = self:GetAbility():GetSpecialValueFor( "rock_speed" )
	self.distance = self:GetAbility():GetSpecialValueFor( "rock_distance" )
end

function modifier_ability_rolling_boulder:End( vector )
	self.pre_collide = vector
	self:Destroy()
end