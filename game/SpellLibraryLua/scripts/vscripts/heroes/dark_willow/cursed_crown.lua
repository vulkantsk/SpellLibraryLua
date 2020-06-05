ability_cursed_crown = class({})

-- https://github.com/Elfansoer/dota-2-lua-abilities/tree/master/scripts/vscripts/lua_abilities/dark_willow_cursed_crown_lua

LinkLuaModifier( "modifier_ability_cursed_crown", "heroes/dark_willow/cursed_crown", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function ability_cursed_crown:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- cancel if linken
	if target:TriggerSpellAbsorb( self ) then return end

	-- load data
	local duration = self:GetSpecialValueFor( "delay" )

	-- add debuff
	target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_ability_cursed_crown", -- modifier name
		{ duration = duration } -- kv
	)
end

modifier_ability_cursed_crown = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_cursed_crown:IsHidden()
	return false
end

function modifier_ability_cursed_crown:IsDebuff()
	return true
end

function modifier_ability_cursed_crown:IsStunDebuff()
	return false
end

function modifier_ability_cursed_crown:IsPurgable()
	return true
end

function modifier_ability_cursed_crown:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_cursed_crown:OnCreated( kv )
	-- references
	self.stun = self:GetAbility():GetSpecialValueFor( "stun_duration" )
	self.radius = self:GetAbility():GetSpecialValueFor( "stun_radius" )
	self.delay = self:GetAbility():GetSpecialValueFor( "delay" )

	if not IsServer() then return end
	local interval = 1
	self.count = 0

	-- Start interval
	self:StartIntervalThink( interval )

	-- Play effects
	self:PlayEffects1()
	self:PlayEffects2()
end

function modifier_ability_cursed_crown:OnRefresh( kv )
	
end

function modifier_ability_cursed_crown:OnRemoved()
end

function modifier_ability_cursed_crown:OnDestroy()

end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ability_cursed_crown:OnIntervalThink()
	self.count = self.count + 1
	if self.count < self.delay then
		-- Play effects
		self:PlayEffects4()
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

	for _,enemy in pairs(enemies) do
		-- stun
		enemy:AddNewModifier(
			self:GetCaster(), -- player source
			self:GetAbility(), -- ability source
			"modifier_stunned", -- modifier name
			{ duration = self.stun } -- kv
		)
	end

	-- play effects
	self:PlayEffects3()
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ability_cursed_crown:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_ley_cast.vpcf"
	local sound_cast = "Hero_DarkWillow.Ley.Cast"
	local sound_target = "Hero_DarkWillow.Ley.Target"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector( 0, 0, 0 ), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector( 0, 0, 0 ), -- unknown
		true -- unknown, true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetCaster() )
	EmitSoundOn( sound_target, self:GetParent() )
end

function modifier_ability_cursed_crown:PlayEffects2()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_leyconduit_start.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_OVERHEAD_FOLLOW, self:GetParent() )

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)
end

function modifier_ability_cursed_crown:PlayEffects3()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_leyconduit_marker.vpcf"
	local sound_cast = "Hero_DarkWillow.Ley.Stun"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( self.radius, self.radius, self.radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), sound_cast, self:GetCaster() )
end

function modifier_ability_cursed_crown:PlayEffects4()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_leyconduit_marker_helper.vpcf"
	local sound_cast = "Hero_DarkWillow.Ley.Count"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( self.radius, self.radius, self.radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetParent() )
end