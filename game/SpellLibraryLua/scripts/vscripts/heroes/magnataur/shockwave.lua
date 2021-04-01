LinkLuaModifier( "modifier_ability_shockwave", "heroes/magnataur/shockwave", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_shockwave_arc", "heroes/magnataur/shockwave", LUA_MODIFIER_MOTION_BOTH )

ability_shockwave = {}

function ability_shockwave:OnAbilityPhaseStart()
	if not IsServer() then return end

	self:PlayEffects1()

	return true
end

function ability_shockwave:OnAbilityPhaseInterrupted()
	if not IsServer() then return end

	self:StopEffects1( true )
end

function ability_shockwave:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	self:StopEffects1( false )

	local radius = self:GetSpecialValueFor( "shock_width" )
	local direction = point - caster:GetAbsOrigin()
	direction.z = 0
	direction = direction:Normalized()

	local info = {
		Source = caster,
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		bDeleteOnHit = true,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		EffectName = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf",
		fDistance = self:GetCastRange( point, nil ),
		fStartRadius = radius,
		fEndRadius = radius,
		vVelocity = direction * self:GetSpecialValueFor( "shock_speed" ),
	}
	ProjectileManager:CreateLinearProjectile(info)

	EmitSoundOn( "Hero_Magnataur.ShockWave.Particle", caster )
end

function ability_shockwave:OnProjectileHit( target, location )
	if not target then return end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor( "shock_damage" )
	local duration = self:GetSpecialValueFor( "basic_slow_duration" )

	local pull_duration = self:GetSpecialValueFor( "pull_duration" )
	local pull_distance = self:GetSpecialValueFor( "pull_distance" )

	local damageTable = {
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self
	}
	ApplyDamage(damageTable)

	local mod = target:AddNewModifier(
		caster,
		self,
		"modifier_ability_shockwave_arc",
		{
			target_x = location.x,
			target_y = location.y,
			duration = pull_duration,
			distance = pull_distance,
			activity = ACT_DOTA_FLAIL,
		} 
	)

	target:AddNewModifier(
		caster,
		self,
		"modifier_ability_shockwave",
		{ duration = duration }
	)

	self:PlayEffects2( target, mod )

	return false
end

function ability_shockwave:PlayEffects2( target, mod )
	local effect_cast = ParticleManager:CreateParticle( 
		"particles/units/heroes/hero_magnataur/magnataur_shockwave_hit.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		target
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	mod:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	EmitSoundOn( "Hero_Magnataur.ShockWave.Target", target )
end

function ability_shockwave:PlayEffects1()
	local caster = self:GetCaster()

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_magnataur/magnataur_shockwave_cast.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		caster
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		caster,
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(),
		true
	)
	self.effect_cast = effect_cast

	EmitSoundOn( "Hero_Magnataur.ShockWave.Cast", caster )
end

function ability_shockwave:StopEffects1( interrupted )
	ParticleManager:DestroyParticle( self.effect_cast, interrupted )
	ParticleManager:ReleaseParticleIndex( self.effect_cast )

	StopSoundOn( "Hero_Magnataur.ShockWave.Cast", self:GetCaster() )
end

modifier_ability_shockwave = {}

function modifier_ability_shockwave:IsHidden()
	return false
end

function modifier_ability_shockwave:IsDebuff()
	return true
end

function modifier_ability_shockwave:IsStunDebuff()
	return false
end

function modifier_ability_shockwave:IsPurgable()
	return true
end

function modifier_ability_shockwave:OnCreated( kv )
	self.slow = -self:GetAbility():GetSpecialValueFor( "movement_slow" )
end

function modifier_ability_shockwave:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_ability_shockwave:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_ability_shockwave:GetEffectName()
	return "particles/units/heroes/hero_magnataur/magnataur_skewer_debuff.vpcf"
end

function modifier_ability_shockwave:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_shockwave_arc = {}

function modifier_ability_shockwave_arc:IsHidden()
	return true
end

function modifier_ability_shockwave_arc:IsDebuff()
	return false
end

function modifier_ability_shockwave_arc:IsStunDebuff()
	return false
end

function modifier_ability_shockwave_arc:IsPurgable()
	return true
end

function modifier_ability_shockwave_arc:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_shockwave_arc:OnCreated( kv )
	if not IsServer() then return end
	self.interrupted = false
	self:SetJumpParameters( kv )
	self:Jump()
end

function modifier_ability_shockwave_arc:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_shockwave_arc:OnDestroy()
	if not IsServer() then return end

	local pos = self:GetParent():GetAbsOrigin()

	self:GetParent():RemoveHorizontalMotionController( self )
	self:GetParent():RemoveVerticalMotionController( self )

	if self.end_offset~=0 then
		self:GetParent():SetAbsOrigin( pos )
	end

	if self.endCallback then
		self.endCallback( self.interrupted )
	end
end

function modifier_ability_shockwave_arc:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DISABLE_TURNING,
	}
	if self:GetStackCount()>0 then
		table.insert( funcs, MODIFIER_PROPERTY_OVERRIDE_ANIMATION )
	end

	return funcs
end

function modifier_ability_shockwave_arc:GetModifierDisableTurning()
	if not self.isForward then return end
	return 1
end

function modifier_ability_shockwave_arc:GetOverrideAnimation()
	return self:GetStackCount()
end

function modifier_ability_shockwave_arc:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = self.isStun or false,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = self.isRestricted or false,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_ability_shockwave_arc:UpdateHorizontalMotion( me, dt )
	if self.fix_duration and self:GetElapsedTime()>=self.duration then return end

	local pos = me:GetAbsOrigin() + self.direction * self.speed * dt
	me:SetAbsOrigin( pos )
end

function modifier_ability_shockwave_arc:UpdateVerticalMotion( me, dt )
	if self.fix_duration and self:GetElapsedTime()>=self.duration then return end

	local pos = me:GetAbsOrigin()
	local time = self:GetElapsedTime()

	local height = pos.z
	local speed = self:GetVerticalSpeed( time )
	pos.z = height + speed * dt
	me:SetAbsOrigin( pos )

	if not self.fix_duration then
		local ground = GetGroundHeight( pos, me ) + self.end_offset
		if pos.z <= ground then
			pos.z = ground
			me:SetAbsOrigin( pos )
			self:Destroy()
		end
	end
end

function modifier_ability_shockwave_arc:OnHorizontalMotionInterrupted()
	self.interrupted = true
	self:Destroy()
end

function modifier_ability_shockwave_arc:OnVerticalMotionInterrupted()
	self.interrupted = true
	self:Destroy()
end

function modifier_ability_shockwave_arc:SetJumpParameters( kv )
	self.parent = self:GetParent()
	self.fix_end = true
	self.fix_duration = true
	self.fix_height = true

	if kv.fix_end then
		self.fix_end = kv.fix_end==1
	end
	if kv.fix_duration then
		self.fix_duration = kv.fix_duration==1
	end
	if kv.fix_height then
		self.fix_height = kv.fix_height==1
	end

	self.isStun = kv.isStun==1
	self.isRestricted = kv.isRestricted==1
	self.isForward = kv.isForward==1
	self.activity = kv.activity or 0
	self:SetStackCount( self.activity )

	if kv.target_x and kv.target_y then
		local origin = self.parent:GetAbsOrigin()
		local dir = Vector( kv.target_x, kv.target_y, 0 ) - origin
		dir.z = 0
		dir = dir:Normalized()
		self.direction = dir
	end

	if kv.dir_x and kv.dir_y then
		self.direction = Vector( kv.dir_x, kv.dir_y, 0 ):Normalized()
	end

	if not self.direction then
		self.direction = self.parent:GetForwardVector()
	end

	self.duration = kv.duration
	self.distance = kv.distance
	self.speed = kv.speed
	if not self.duration then
		self.duration = self.distance/self.speed
	end
	if not self.distance then
		self.speed = self.speed or 0
		self.distance = self.speed*self.duration
	end
	if not self.speed then
		self.distance = self.distance or 0
		self.speed = self.distance/self.duration
	end

	self.height = kv.height or 0
	self.start_offset = kv.start_offset or 0
	self.end_offset = kv.end_offset or 0

	local pos_start = self.parent:GetAbsOrigin()
	local pos_end = pos_start + self.direction * self.distance
	local height_start = GetGroundHeight( pos_start, self.parent ) + self.start_offset
	local height_end = GetGroundHeight( pos_end, self.parent ) + self.end_offset
	local height_max

	if not self.fix_height then
		self.height = math.min( self.height, self.distance/4 )
	end

	if self.fix_end then
		height_end = height_start
		height_max = height_start + self.height
	else
		local tempmin, tempmax = height_start, height_end
		if tempmin>tempmax then
			tempmin,tempmax = tempmax, tempmin
		end
		local delta = (tempmax-tempmin)*2/3

		height_max = tempmin + delta + self.height
	end

	if not self.fix_duration then
		self:SetDuration( -1, false )
	else
		self:SetDuration( self.duration, true )
	end

	self:InitVerticalArc( height_start, height_max, height_end, self.duration )
end

function modifier_ability_shockwave_arc:Jump()
	if self.distance>0 then
		if not self:ApplyHorizontalMotionController() then
			self.interrupted = true
			self:Destroy()
		end
	end

	if self.height>0 then
		if not self:ApplyVerticalMotionController() then
			self.interrupted = true
			self:Destroy()
		end
	end
end

function modifier_ability_shockwave_arc:InitVerticalArc( height_start, height_max, height_end, duration )
	local height_end = height_end - height_start
	local height_max = height_max - height_start

	if height_max<height_end then
		height_max = height_end+0.01
	end

	if height_max<=0 then
		height_max = 0.01
	end

	local duration_end = ( 1 + math.sqrt( 1 - height_end/height_max ) )/2
	self.const1 = 4*height_max*duration_end/duration
	self.const2 = 4*height_max*duration_end*duration_end/(duration*duration)
end

function modifier_ability_shockwave_arc:GetVerticalPos( time )
	return self.const1*time - self.const2*time*time
end

function modifier_ability_shockwave_arc:GetVerticalSpeed( time )
	return self.const1 - 2*self.const2*time
end

function modifier_ability_shockwave_arc:SetEndCallback( func )
	self.endCallback = func
end