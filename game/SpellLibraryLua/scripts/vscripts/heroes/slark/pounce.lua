LinkLuaModifier( "modifier_ability_pounce", "heroes/slark/pounce", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier( "modifier_ability_pounce_debuff", "heroes/slark/pounce", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier( "modifier_ability_pounce_arc", "heroes/slark/pounce", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier( "modifier_ability_pounce_leashed", "heroes/slark/pounce", LUA_MODIFIER_MOTION_BOTH )

ability_pounce = {}

function ability_pounce:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_pounce",
		{}
	)

	EmitSoundOn( "Hero_Slark.Pounce.Cast", caster )
end

modifier_ability_pounce = {}

function modifier_ability_pounce:IsHidden()
	return false
end

function modifier_ability_pounce:IsDebuff()
	return false
end

function modifier_ability_pounce:IsStunDebuff()
	return false
end

function modifier_ability_pounce:IsPurgable()
	return true
end

function modifier_ability_pounce:OnCreated( kv )
	self.parent = self:GetParent()

	local speed = self:GetAbility():GetSpecialValueFor( "pounce_speed" )
	local distance = self:GetAbility():GetSpecialValueFor( "pounce_distance" )
	self.radius = self:GetAbility():GetSpecialValueFor( "pounce_radius" )
	self.leash_radius = self:GetAbility():GetSpecialValueFor( "leash_radius" )
	self.leash_duration = self:GetAbility():GetSpecialValueFor( "leash_duration" )

	local duration = distance/speed
	local height = 160

	if not IsServer() then return end

	self.arc = self.parent:AddNewModifier(
		self.parent,
		self:GetAbility(),
		"modifier_ability_pounce_arc",
		{
			speed = speed,
			duration = duration,
			distance = distance,
			height = height,
		}
	)
	self.arc:SetEndCallback(function( interrupted )
		if self:IsNull() then return end
		self.arc = nil
		self:Destroy()
	end)

	self:SetDuration( duration, true )
	self:GetAbility():SetActivated( false )
	self:StartIntervalThink( 0.1 )
	self:OnIntervalThink()
	self:PlayEffects()
end

function modifier_ability_pounce:OnDestroy()
	if not IsServer() then return end

	self:GetAbility():SetActivated( true )

	GridNav:DestroyTreesAroundPoint( self.parent:GetOrigin(), 100, false )

	if self.arc and not self.arc:IsNull() then
		self.arc:Destroy()
	end
end

function modifier_ability_pounce:CheckState()
	return { [MODIFIER_STATE_DISARMED] = true }
end

function modifier_ability_pounce:OnIntervalThink()
	local enemies = FindUnitsInRadius(
		self.parent:GetTeamNumber(),	-- int, your team number
		self.parent:GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO,	-- int, type filter
		0,	-- int, flag filter
		FIND_CLOSEST,	-- int, order filter
		false	-- bool, can grow cache
	)

	local target
	for _,enemy in pairs(enemies) do
		if not enemy:IsIllusion() then
			target = enemy
			break
		end
	end

	if not target then return end

	target:AddNewModifier(
		self.parent,
		self:GetAbility(),
		"modifier_ability_pounce_debuff",
		{
			duration = self.leash_duration,
			radius = self.leash_radius,
			purgable = false,
		}
	)

	EmitSoundOn( "Hero_Slark.Pounce.Impact", target )

	self:Destroy()
end

function modifier_ability_pounce:GetEffectName()
	return "particles/units/heroes/hero_slark/slark_pounce_trail.vpcf"
end

function modifier_ability_pounce:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_ability_pounce:PlayEffects()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_slark/slark_pounce_start.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self.parent
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

end

modifier_ability_pounce_debuff = {}

function modifier_ability_pounce_debuff:IsHidden()
	return false
end

function modifier_ability_pounce_debuff:IsDebuff()
	return true
end

function modifier_ability_pounce_debuff:IsStunDebuff()
	return false
end

function modifier_ability_pounce_debuff:IsPurgable()
	return false
end

function modifier_ability_pounce_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_pounce_debuff:OnCreated( kv )
	if not IsServer() then return end
	self.radius = kv.radius

	self.leash = self:GetParent():AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_pounce_leashed",
		kv
	)
	self.leash:SetEndCallback(function()
		if self:IsNull() then return end
		self.leash = nil
		self:Destroy()
	end)

	self:PlayEffects1()
	self:PlayEffects2()
end

function modifier_ability_pounce_debuff:OnDestroy()
	if not IsServer() then return end

	if self.leash and not self.leash:IsNull() then
		self.leash:Destroy()
	end

	StopSoundOn( "Hero_Slark.Pounce.Leash", self:GetParent() )
	EmitSoundOn( "Hero_Slark.Pounce.End", self:GetParent() )
end

function modifier_ability_pounce_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_frost.vpcf"
end

function modifier_ability_pounce_debuff:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end

function modifier_ability_pounce_debuff:PlayEffects1()
	local caster = self:GetCaster()

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_slark/slark_pounce_ground.vpcf",
		PATTACH_WORLDORIGIN,
		caster
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		caster,
		PATTACH_WORLDORIGIN,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:SetParticleControl( effect_cast, 3, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 4, Vector( self.radius, 0, 0 ) )

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	EmitSoundOn( "Hero_Slark.Pounce.Leash", self:GetParent() )
end

function modifier_ability_pounce_debuff:PlayEffects2()
	local caster = self:GetCaster()
	local parent = self:GetParent()

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_slark/slark_pounce_leash.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		parent
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
	ParticleManager:SetParticleControl( effect_cast, 3, self:GetParent():GetOrigin() )

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)
end

modifier_ability_pounce_arc = {}

function modifier_ability_pounce_arc:IsHidden()
	return true
end

function modifier_ability_pounce_arc:IsDebuff()
	return false
end

function modifier_ability_pounce_arc:IsStunDebuff()
	return false
end

function modifier_ability_pounce_arc:IsPurgable()
	return true
end

function modifier_ability_pounce_arc:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_pounce_arc:OnCreated( kv )
	if not IsServer() then return end
	self.interrupted = false
	self:SetJumpParameters( kv )
	self:Jump()
end

function modifier_ability_pounce_arc:OnRefresh( kv )
	self:OnCreated( kv )
end

function modifier_ability_pounce_arc:OnDestroy()
	if not IsServer() then return end

	local pos = self:GetParent():GetOrigin()

	self:GetParent():RemoveHorizontalMotionController( self )
	self:GetParent():RemoveVerticalMotionController( self )

	if self.end_offset~=0 then
		self:GetParent():SetOrigin( pos )
	end

	if self.endCallback then
		self.endCallback( self.interrupted )
	end
end

function modifier_ability_pounce_arc:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DISABLE_TURNING,
	}

	if self:GetStackCount()>0 then
		table.insert( funcs, MODIFIER_PROPERTY_OVERRIDE_ANIMATION )
	end

	return funcs
end

function modifier_ability_pounce_arc:GetModifierDisableTurning()
	if not self.isForward then return end
	return 1
end

function modifier_ability_pounce_arc:GetOverrideAnimation()
	return self:GetStackCount()
end

function modifier_ability_pounce_arc:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = self.isStun or false,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = self.isRestricted or false,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_ability_pounce_arc:UpdateHorizontalMotion( me, dt )
	if self.fix_duration and self:GetElapsedTime()>=self.duration then return end

	local pos = me:GetOrigin() + self.direction * self.speed * dt
	me:SetOrigin( pos )
end

function modifier_ability_pounce_arc:UpdateVerticalMotion( me, dt )
	if self.fix_duration and self:GetElapsedTime()>=self.duration then return end

	local pos = me:GetOrigin()
	local time = self:GetElapsedTime()
	local height = pos.z
	local speed = self:GetVerticalSpeed( time )
	pos.z = height + speed * dt
	me:SetOrigin( pos )

	if not self.fix_duration then
		local ground = GetGroundHeight( pos, me ) + self.end_offset
		if pos.z <= ground then
			pos.z = ground
			me:SetOrigin( pos )
			self:Destroy()
		end
	end
end

function modifier_ability_pounce_arc:OnHorizontalMotionInterrupted()
	self.interrupted = true
	self:Destroy()
end

function modifier_ability_pounce_arc:OnVerticalMotionInterrupted()
	self.interrupted = true
	self:Destroy()
end

function modifier_ability_pounce_arc:SetJumpParameters( kv )
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
		local origin = self.parent:GetOrigin()
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

	local pos_start = self.parent:GetOrigin()
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

function modifier_ability_pounce_arc:Jump()
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

function modifier_ability_pounce_arc:InitVerticalArc( height_start, height_max, height_end, duration )
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

function modifier_ability_pounce_arc:GetVerticalPos( time )
	return self.const1*time - self.const2*time*time
end

function modifier_ability_pounce_arc:GetVerticalSpeed( time )
	return self.const1 - 2*self.const2*time
end

function modifier_ability_pounce_arc:SetEndCallback( func )
	self.endCallback = func
end

modifier_ability_pounce_leashed = {}

function modifier_ability_pounce_leashed:IsHidden()
	return true
end

function modifier_ability_pounce_leashed:IsDebuff()
	return true
end

function modifier_ability_pounce_leashed:IsStunDebuff()
	return false
end

function modifier_ability_pounce_leashed:IsPurgable()
	if not IsServer() then return end
	return self.purgable
end

function modifier_ability_pounce_leashed:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_pounce_leashed:OnCreated( kv )
	if not IsServer() then return end
	self.parent = self:GetParent()
	self.rooted = true
	self.purgable = true
	if kv.rooted then self.rooted = kv.rooted==1 end
	if kv.purgable then self.purgable = kv.purgable==1 end
	if self.rooted then self:SetStackCount(1) end

	self.radius = kv.radius or 300
	if kv.center_x and kv.center_y then
		self.center = Vector( kv.center_x, kv.center_y, 0 )
	else
		self.center = self:GetParent():GetOrigin()
	end

	self.max_speed = 550
	self.min_speed = 0.1
	self.max_min = self.max_speed-self.min_speed
	self.half_width = 50
end

function modifier_ability_pounce_leashed:OnDestroy()
	if not IsServer() then return end
	if self.endCallback then
		self.endCallback()
	end
end

function modifier_ability_pounce_leashed:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_LIMIT }
end

function modifier_ability_pounce_leashed:GetModifierMoveSpeed_Limit( params )
	if not IsServer() then return end

	local parent_vector = self.parent:GetOrigin()-self.center
	local parent_direction = parent_vector:Normalized()
	local actual_distance = parent_vector:Length2D()
	local wall_distance = self.radius-actual_distance

	if wall_distance<(-self.half_width) then
		self:Destroy()
		return 0
	end

	local parent_angle = VectorToAngles(parent_direction).y
	local unit_angle = self:GetParent():GetAnglesAsVector().y
	local wall_angle = math.abs( AngleDiff( parent_angle, unit_angle ) )
	local limit = 0

	if wall_angle<=90 then
		if wall_distance<0 then
			limit = self.min_speed
		else
			limit = (wall_distance/self.half_width)*self.max_min + self.min_speed
		end
	end

	return limit
end

function modifier_ability_pounce_leashed:CheckState()
	return { [MODIFIER_STATE_TETHERED] = self:GetStackCount()==1 }
end

function modifier_ability_pounce_leashed:SetEndCallback( func )
	self.endCallback = func
end