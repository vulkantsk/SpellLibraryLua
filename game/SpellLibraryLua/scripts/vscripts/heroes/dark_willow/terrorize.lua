ability_terrorize = class({})
-- https://github.com/Elfansoer/dota-2-lua-abilities/tree/master/scripts/vscripts/lua_abilities/dark_willow_terrorize_lua
function ability_terrorize:GetAOERadius()
	return self:GetSpecialValueFor( "destination_radius" )
end
LinkLuaModifier( "modifier_wisp_ambient_terrorize", "heroes/dark_willow/terrorize", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_terrorize", "heroes/dark_willow/terrorize", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Phase Start
function ability_terrorize:OnAbilityPhaseStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local vector = point-caster:GetOrigin()
	vector.z = 0

	-- get data
	local radius = self:GetSpecialValueFor( "destination_radius" )
	local height = self:GetSpecialValueFor( "starting_height" )

	-- create wisp
	self.wisp = CreateUnitByName(
		"npc_dota_dark_willow_creature",
		caster:GetOrigin(),
		true,
		caster,
		caster:GetOwner(),
		caster:GetTeamNumber()
	)
	self.wisp:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_wisp_ambient_terrorize", -- modifier name
		{} -- kv
	)
	self.wisp:SetForwardVector( vector:Normalized() )
	self.wisp:SetOrigin( self.wisp:GetOrigin() + Vector( 0,0,height ) )

	-- create effects
	self:PlayEffects1( point, radius )
	self:PlayEffects2()

	return true -- if success
end
function ability_terrorize:OnAbilityPhaseInterrupted()
	UTIL_Remove( self.wisp )

	self:StopEffects1()
	self:StopEffects2()
end

--------------------------------------------------------------------------------
-- Ability Start
function ability_terrorize:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local vector = point-caster:GetOrigin()
	vector.z = 0
	local origin = caster:GetOrigin()

	-- load data
	local height = self:GetSpecialValueFor( "starting_height" )

	local projectile_name = ""
	local projectile_speed = self:GetSpecialValueFor( "destination_travel_speed" )
	local projectile_distance = vector:Length2D()
	local projectile_direction = vector:Normalized()

	-- projectiles don't change height, so better pre-set it to have nice effect
	local spawn_origin = caster:GetOrigin()
	spawn_origin.z = GetGroundHeight( point, caster )
	height = origin.z + height - spawn_origin.z

	-- create projectile
	local info = {
		Source = caster,
		Ability = self,
		vSpawnOrigin = spawn_origin,
		
	    bDeleteOnHit = true,
	    
	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	    iUnitTargetType = DOTA_UNIT_TARGET_NONE,
	    
	    EffectName = projectile_name,
	    fDistance = projectile_distance,
	    fStartRadius = 0,
	    fEndRadius = 0,
		vVelocity = projectile_direction * projectile_speed,

		ExtraData = {
			origin_x = origin.x,
			origin_y = origin.y,
			origin_z = origin.z,
			distance = projectile_distance,
			height = height,
			returning = 0,
		}
	}
	ProjectileManager:CreateLinearProjectile(info)

	-- deactivate ability
	self:SetActivated( false )
	local ability = caster:FindAbilityByName( "ability_bedlam" )
	if ability then ability:SetActivated( false ) end
end
--------------------------------------------------------------------------------
-- Projectile
function ability_terrorize:OnProjectileHit_ExtraData( target, location, ExtraData )
	local returning = ExtraData.returning==1

	if returning then
		-- kill the wisp
		UTIL_Remove( self.wisp )

		-- deactivate ability
		self:SetActivated( true )
		local ability = self:GetCaster():FindAbilityByName( "ability_bedlam" )
		if ability then ability:SetActivated( true ) end
		return
	end

	-- get data
	local radius = self:GetSpecialValueFor( "destination_radius" )
	local duration = self:GetSpecialValueFor( "destination_status_duration" )

	-- find enemies
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		location,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	for _,enemy in pairs(enemies) do
		-- add fear
		enemy:AddNewModifier(
			self:GetCaster(), -- player source
			self, -- ability source
			"modifier_ability_terrorize", -- modifier name
			{ duration = duration } -- kv
		)
	end

	-- create return projectile
	local projectile_speed = self:GetSpecialValueFor( "return_travel_speed" )
	local info = {
		Target = self:GetCaster(),
		Source = self.wisp,
		Ability = self,	
		
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		bDodgeable = false,                           -- Optional

		ExtraData = {
			returning = 1,
		}
	}
	ProjectileManager:CreateTrackingProjectile(info)

	-- set wisp activity
	self.wisp:StartGesture( ACT_DOTA_CAST_ABILITY_5 )

	-- play effects
	self:PlayEffects3( location, radius, #enemies )
end

function ability_terrorize:OnProjectileThink_ExtraData( location, ExtraData )
	local returning = ExtraData.returning==1
	if returning then
		-- get facing direction
		local direction = self:GetCaster():GetOrigin()-location
		direction.z = 0
		direction = direction:Normalized()

		-- set position
		self.wisp:SetOrigin( location )
		self.wisp:SetForwardVector( direction )
		return
	end

	-- get data
	local origin = Vector( ExtraData.origin_x, ExtraData.origin_y, ExtraData.origin_z )
	local distance = ExtraData.distance
	local height = ExtraData.height

	-- interpolate height
	local current_dist = (location-origin):Length2D()

	local current_height = height - (current_dist/distance)*height

	self.wisp:SetOrigin( location + Vector( 0,0,current_height ) )
end

--------------------------------------------------------------------------------
function ability_terrorize:PlayEffects1( point, radius )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_marker.vpcf"

	-- Create Particle
	self.effect_cast1 = ParticleManager:CreateParticleForTeam( particle_cast, PATTACH_WORLDORIGIN, nil, self:GetCaster():GetTeamNumber() )
	ParticleManager:SetParticleControl( self.effect_cast1, 0, point )
	ParticleManager:SetParticleControl( self.effect_cast1, 1, Vector( radius, 0, 0 ) )

	-- play sound
	local sound_cast1 = "Hero_DarkWillow.Fear.Cast"
	local sound_cast2 = "Hero_DarkWillow.Fear.Wisp"
	local sound_cast3 = "Hero_DarkWillow.Fear.Location"
	EmitSoundOn( sound_cast1, self:GetCaster() )
	EmitSoundOn( sound_cast2, self:GetCaster() )
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast3, self:GetCaster() )
end
function ability_terrorize:StopEffects1()
	-- destroy particle
	ParticleManager:DestroyParticle( self.effect_cast1, false )
	ParticleManager:ReleaseParticleIndex( self.effect_cast1 )

	-- stop sound
	local sound_cast1 = "Hero_DarkWillow.Fear.Cast"
	local sound_cast2 = "Hero_DarkWillow.Fear.Wisp"
	local sound_cast3 = "Hero_DarkWillow.Fear.Location"
	StopSoundOn( sound_cast1, self:GetCaster() )
	StopSoundOn( sound_cast2, self:GetCaster() )
	StopSoundOn( sound_cast3, self:GetCaster() )
end

function ability_terrorize:PlayEffects2()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_channel.vpcf"

	-- Create Particle
	self.effect_cast2 = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self.wisp )
end
function ability_terrorize:StopEffects2()
	-- destroy particle
	ParticleManager:DestroyParticle( self.effect_cast2, false )
	ParticleManager:ReleaseParticleIndex( self.effect_cast2 )
end

function ability_terrorize:PlayEffects3( point, radius, number )
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell.vpcf"
	local sound_cast = "Hero_DarkWillow.Fear.FP"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, point )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, 0, radius*2 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	if number>0 then
		EmitSoundOnLocationWithCaster( point, sound_cast, self:GetCaster() )
	end
end


modifier_ability_terrorize = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_terrorize:IsHidden()
	return false
end

function modifier_ability_terrorize:IsDebuff()
	return true
end

function modifier_ability_terrorize:IsStunDebuff()
	return false
end

function modifier_ability_terrorize:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_terrorize:OnCreated( kv )
	if not IsServer() then return end
	-- play effects
	self:PlayEffects()



	-- find enemy fountain
	local buildings = FindUnitsInRadius(
		self:GetParent():GetTeamNumber(),	-- int, your team number
		Vector(0,0,0),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		FIND_UNITS_EVERYWHERE,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,	-- int, team filter
		DOTA_UNIT_TARGET_BUILDING,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	local fountain = nil
	for _,building in pairs(buildings) do
		if building:GetClassname()=="ent_dota_fountain" then
			fountain = building
			break
		end
	end

	-- if no fountain, just don't do anything
	if not fountain then return end

	-- for lane creep, MoveToPosition won't work, so use this
	if self:GetParent():IsCreep() then
		self:GetParent():SetForceAttackTargetAlly( fountain ) -- for creeps
	end

	-- for others, order to run to fountain
	self:GetParent():MoveToPosition( fountain:GetOrigin() )
end

function modifier_ability_terrorize:OnDestroy()
	if not IsServer() then return end

	-- stop running
	self:GetParent():Stop()
	if self:GetParent():IsCreep() then
		self:GetParent():SetForceAttackTargetAlly( nil ) -- for creeps
	end
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ability_terrorize:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}

	return funcs
end

function modifier_ability_terrorize:GetModifierProvidesFOWVision()
	return 1
end
--------------------------------------------------------------------------------
-- Status Effects
function modifier_ability_terrorize:CheckState()
	local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_FEARED] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ability_terrorize:GetStatusEffectName()
	return "particles/status_fx/status_effect_dark_willow_wisp_fear.vpcf"
end

function modifier_ability_terrorize:PlayEffects()
	-- Get Resources
	local particle_cast1 = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_debuff.vpcf"
	local particle_cast2 = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_fear_debuff.vpcf"

	-- Create Particle
	local effect_cast1 = ParticleManager:CreateParticle( particle_cast1, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
	local effect_cast2 = ParticleManager:CreateParticle( particle_cast2, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )

	-- buff particle
	self:AddParticle(
		effect_cast1,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
	self:AddParticle(
		effect_cast2,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
end



modifier_wisp_ambient_terrorize = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_wisp_ambient_terrorize:IsHidden()
	return false
end

function modifier_wisp_ambient_terrorize:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_wisp_ambient_terrorize:OnCreated( kv )
	if not IsServer() then return end
	self:GetParent():SetModel( "models/heroes/dark_willow/dark_willow_wisp.vmdl" )
	self:PlayEffects()

end

function modifier_wisp_ambient_terrorize:OnRefresh( kv )
	
end

function modifier_wisp_ambient_terrorize:OnRemoved()
end

function modifier_wisp_ambient_terrorize:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_wisp_ambient_terrorize:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
	}

	return funcs
end

function modifier_wisp_ambient_terrorize:GetModifierBaseAttack_BonusDamage()
	if not IsServer() then return end

	-- update cp
	local target = self:GetParent():GetOrigin() + self:GetParent():GetForwardVector()
	local forward = self:GetParent():GetForwardVector()
	ParticleManager:SetParticleControl( self.effect_cast, 2, target )
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_wisp_ambient_terrorize:CheckState()
	local state = {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_wisp_ambient_terrorize:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_willowisp_ambient.vpcf"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		self.effect_cast,
		0,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		self.effect_cast,
		1,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)

	-- buff particle
	self:AddParticle(
		self.effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
end