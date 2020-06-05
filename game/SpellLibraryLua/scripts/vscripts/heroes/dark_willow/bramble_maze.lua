ability_bramble_maze = class({})

-- https://github.com/Elfansoer/dota-2-lua-abilities/tree/master/scripts/vscripts/lua_abilities/dark_willow_bramble_maze_lua

LinkLuaModifier( "modifier_generic_custom_indicator", "heroes/dark_willow/bramble_maze", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_bramble_maze_thinker", "heroes/dark_willow/bramble_maze", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_bramble_maze_bramble", "heroes/dark_willow/bramble_maze", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_bramble_maze_debuff", "heroes/dark_willow/bramble_maze", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- init bramble locations
local locations = {}
local inner = Vector( 200, 0, 0 )
local outer = Vector( 500, 0, 0 )
outer = RotatePosition( Vector(0,0,0), QAngle( 0, 45, 0 ), outer )

-- real men use 0-based
for i=0,3 do
	locations[i] = RotatePosition( Vector(0,0,0), QAngle( 0, 90*i, 0 ), inner )
	locations[i+4] = RotatePosition( Vector(0,0,0), QAngle( 0, 90*i, 0 ), outer )
end
ability_bramble_maze.locations = locations

--------------------------------------------------------------------------------
-- Passive Modifier
function ability_bramble_maze:GetIntrinsicModifierName()
	return "modifier_generic_custom_indicator"
end

--------------------------------------------------------------------------------
-- Ability Cast Filter (For custom indicator)
function ability_bramble_maze:CastFilterResultLocation( vLoc )
	-- Custom indicator block start
	if IsClient() then
		-- check custom indicator
		if self.custom_indicator then
			-- register cursor position
			self.custom_indicator:Register( vLoc )
		end
	end
	-- Custom indicator block end

	return UF_SUCCESS
end

--------------------------------------------------------------------------------
-- Ability Custom Indicator
function ability_bramble_maze:CreateCustomIndicator()
	-- references
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_bramble_range_finder_aoe.vpcf"

	-- get data
	local radius = self:GetSpecialValueFor( "placement_range" )

	-- create particle
	self.effect_indicator = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl( self.effect_indicator, 1, Vector( radius, radius, radius ) )
end

function ability_bramble_maze:UpdateCustomIndicator( loc )
	-- update particle position
	ParticleManager:SetParticleControl( self.effect_indicator, 0, loc )
	for i=0,7 do
		ParticleManager:SetParticleControl( self.effect_indicator, 2 + i, loc + self.locations[i] )
	end
end

function ability_bramble_maze:DestroyCustomIndicator()
	-- destroy particle
	ParticleManager:DestroyParticle( self.effect_indicator, false )
	ParticleManager:ReleaseParticleIndex( self.effect_indicator )
end

--------------------------------------------------------------------------------
-- Ability Start
function ability_bramble_maze:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- create thinker
	CreateModifierThinker(
		caster, -- player source
		self, -- ability source
		"modifier_ability_bramble_maze_thinker", -- modifier name
		{}, -- kv
		point,
		self:GetCaster():GetTeamNumber(),
		false
	)
end



modifier_generic_custom_indicator = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_generic_custom_indicator:IsHidden()
	return true
end

function modifier_generic_custom_indicator:IsPurgable()
	return true
end

function modifier_generic_custom_indicator:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_generic_custom_indicator:OnCreated( kv )
	if IsServer() then return end

	-- register modifier to ability
	self:GetAbility().custom_indicator = self
end

function modifier_generic_custom_indicator:OnRefresh( kv )
end

function modifier_generic_custom_indicator:OnRemoved()
end

function modifier_generic_custom_indicator:OnDestroy()
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_generic_custom_indicator:OnIntervalThink()
	if IsClient() then
		-- end
		self:StartIntervalThink(-1)

		-- destroy effect
		local ability = self:GetAbility()
		if self.init and ability.DestroyCustomIndicator then
			self.init = nil
			ability:DestroyCustomIndicator()
		end
	end
end

--------------------------------------------------------------------------------
-- Helper
function modifier_generic_custom_indicator:Register( loc )
	-- TODO: check if self.ability can persist through disconnect if declared in OnCreated
	local ability = self:GetAbility()

	-- init
	if (not self.init) and ability.CreateCustomIndicator then
		self.init = true
		ability:CreateCustomIndicator()
	end

	-- update
	if ability.UpdateCustomIndicator then
		ability:UpdateCustomIndicator( loc )
	end

	-- start interval
	self:StartIntervalThink( 0.1 )
end


modifier_ability_bramble_maze_thinker = class({})


--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_bramble_maze_thinker:IsHidden()
	return false
end

function modifier_ability_bramble_maze_thinker:IsDebuff()
	return false
end

function modifier_ability_bramble_maze_thinker:IsStunDebuff()
	return false
end

function modifier_ability_bramble_maze_thinker:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_bramble_maze_thinker:OnCreated( kv )
	-- references
	local init_delay = self:GetAbility():GetSpecialValueFor( "initial_creation_delay" )
	self.interval = self:GetAbility():GetSpecialValueFor( "latch_creation_interval" )
	self.total_count = self:GetAbility():GetSpecialValueFor( "placement_count" )
	self.duration = self:GetAbility():GetSpecialValueFor( "placement_duration" )
	self.radius = self:GetAbility():GetSpecialValueFor( "placement_range" )

	self.latch_delay = self:GetAbility():GetSpecialValueFor( "latch_creation_delay" )
	self.latch_duration = self:GetAbility():GetSpecialValueFor( "latch_duration" )
	self.latch_radius = self:GetAbility():GetSpecialValueFor( "latch_range" )
	self.latch_damage = self:GetAbility():GetSpecialValueFor( "latch_damage" )

	if not IsServer() then return end
	-- init
	self.count = 0

	-- Start delay
	self:StartIntervalThink( init_delay )

	-- play effects
	self:PlayEffects1()
	self:PlayEffects2()
end

function modifier_ability_bramble_maze_thinker:OnRefresh( kv )
	
end

function modifier_ability_bramble_maze_thinker:OnRemoved()
end

function modifier_ability_bramble_maze_thinker:OnDestroy()
	if not IsServer() then return end
	UTIL_Remove( self:GetParent() )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ability_bramble_maze_thinker:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_EVENT_ON_ATTACKED,
	}

	return funcs
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ability_bramble_maze_thinker:OnIntervalThink()
	if not self.delay then
		self.delay = true

		-- start creation interval
		self:StartIntervalThink( self.interval )
		self:OnIntervalThink()
		return
	end

	-- create bramble
	CreateModifierThinker(
		self:GetCaster(), -- player source
		self:GetAbility(), -- ability source
		"modifier_ability_bramble_maze_bramble", -- modifier name
		{
			duration = self.duration,
			root = self.latch_duration,
			radius = self.latch_radius,
			damage = self.latch_damage,
			delay = self.latch_delay,
		}, -- kv
		self:GetParent():GetOrigin() + self:GetAbility().locations[self.count],
		self:GetCaster():GetTeamNumber(),
		false
	)

	self.count = self.count+1
	if self.count>=self.total_count then
		self:StartIntervalThink( -1 )
		self:Destroy()
	end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ability_bramble_maze_thinker:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_bramble_precast.vpcf"

	for _,loc in pairs(self:GetAbility().locations) do
		local location = self:GetParent():GetOrigin() + loc

		-- Create Particle
		local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl( effect_cast, 0, location )
		ParticleManager:SetParticleControl( effect_cast, 3, location )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end
end

function modifier_ability_bramble_maze_thinker:PlayEffects2()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_bramble_cast.vpcf"
	local sound_cast = "Hero_DarkWillow.Brambles.Cast"
	local sound_target = "Hero_DarkWillow.Brambles.CastTarget"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( self.radius, self.radius, self.radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
	EmitSoundOn( sound_target, self:GetParent() )
end


modifier_ability_bramble_maze_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_bramble_maze_debuff:IsHidden()
	return false
end

function modifier_ability_bramble_maze_debuff:IsDebuff()
	return true
end

function modifier_ability_bramble_maze_debuff:IsStunDebuff()
	return false
end

function modifier_ability_bramble_maze_debuff:IsPurgable()
	return true
end

function modifier_ability_bramble_maze_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_bramble_maze_debuff:OnCreated( kv )

	if not IsServer() then return end
	-- references
	local duration = kv.duration
	local damage = kv.damage
	local interval = 0.5

	-- set dps
	local instances = duration/interval
	local dps = damage/instances

	-- precache damage
	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = dps,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(), --Optional.
	}
	-- ApplyDamage(damageTable)

	-- Start interval
	self:StartIntervalThink( interval )

	-- play effects
	local sount_cast1 = "Hero_DarkWillow.Bramble.Target"
	local sount_cast2 = "Hero_DarkWillow.Bramble.Target.Layer"
	EmitSoundOn( sount_cast1, self:GetParent() )
	EmitSoundOn( sount_cast2, self:GetParent() )
end

function modifier_ability_bramble_maze_debuff:OnRefresh( kv )
	
end

function modifier_ability_bramble_maze_debuff:OnRemoved()
end

function modifier_ability_bramble_maze_debuff:OnDestroy()
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_ability_bramble_maze_debuff:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ability_bramble_maze_debuff:OnIntervalThink()
	-- apply damage
	ApplyDamage( self.damageTable )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ability_bramble_maze_debuff:GetEffectName()
	return "particles/units/heroes/hero_dark_willow/dark_willow_bramble.vpcf"
end

function modifier_ability_bramble_maze_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_ability_bramble_maze_bramble = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_bramble_maze_bramble:IsHidden()
	return false
end

function modifier_ability_bramble_maze_bramble:IsDebuff()
	return false
end

function modifier_ability_bramble_maze_bramble:IsStunDebuff()
	return false
end

function modifier_ability_bramble_maze_bramble:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_bramble_maze_bramble:OnCreated( kv )
	if not IsServer() then return end
	-- references
	self.radius = kv.radius
	self.root = kv.root
	self.damage = kv.damage
	local delay = kv.delay

	-- start delay
	self:StartIntervalThink( delay )

	-- play effects
	self:PlayEffects()
end

function modifier_ability_bramble_maze_bramble:OnRefresh( kv )
	
end

function modifier_ability_bramble_maze_bramble:OnRemoved()
end

function modifier_ability_bramble_maze_bramble:OnDestroy()
	if not IsServer() then return end
	-- stop loop sound
	local sound_loop = "Hero_DarkWillow.BrambleLoop"
	StopSoundOn( sound_loop, self:GetParent() )

	-- play stopping sound
	local sound_stop = "Hero_DarkWillow.Bramble.Destroy"
	EmitSoundOn( sound_stop, self:GetParent() )

	UTIL_Remove( self:GetParent() )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ability_bramble_maze_bramble:OnIntervalThink()
	if not self.delay then
		self.delay = true

		-- start search interval
		local interval = 0.03
		self:StartIntervalThink( interval )
		return
	end

	-- find enemies
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self:GetParent():GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	local target = nil
	for _,enemy in pairs(enemies) do
		-- find the first occurence
		target = enemy
		break
	end
	if not target then return end

	-- root target
	target:AddNewModifier(
		self:GetCaster(), -- player source
		self:GetAbility(), -- ability source
		"modifier_ability_bramble_maze_debuff", -- modifier name
		{
			duration = self.root,
			damage = self.damage,
		} -- kv
	)

	self:Destroy()
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ability_bramble_maze_bramble:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_bramble_wraith.vpcf"
	local sound_cast = "Hero_DarkWillow.Bramble.Spawn"
	local sound_loop = "Hero_DarkWillow.BrambleLoop"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, self.radius, self.radius ) )

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetParent() )
	EmitSoundOn( sound_loop, self:GetParent() )
end

