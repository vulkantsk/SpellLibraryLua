ability_freezing_field = class({})
-- https://github.com/Elfansoer/dota-2-lua-abilities/tree/master/scripts/vscripts/lua_abilities/crystal_maiden_freezing_field_lua
LinkLuaModifier( "modifier_ability_freezing_field_aura", "heroes/crystal_maiden/freezing_field", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_freezing_field_aura_effect", "heroes/crystal_maiden/freezing_field", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function ability_freezing_field:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- Add modifier
	self.modifier = caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_ability_freezing_field_aura", -- modifier name
		{ duration = self:GetChannelTime() } -- kv
	)
end

--------------------------------------------------------------------------------
-- Ability Channeling
-- function crystal_maiden_freezing_field_lua:GetChannelTime()

-- end

function ability_freezing_field:OnChannelFinish( bInterrupted )
	if self.modifier then
		self.modifier:Destroy()
		self.modifier = nil
	end
end

modifier_ability_freezing_field_aura = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_freezing_field_aura:IsHidden()
	return true
end

function modifier_ability_freezing_field_aura:IsDebuff()
	return false
end

function modifier_ability_freezing_field_aura:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Aura
function modifier_ability_freezing_field_aura:IsAura()
	return true
end

function modifier_ability_freezing_field_aura:GetModifierAura()
	return "modifier_ability_freezing_field_aura_effect"
end

function modifier_ability_freezing_field_aura:GetAuraRadius()
	return self.slow_radius
end

function modifier_ability_freezing_field_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_ability_freezing_field_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
end

function modifier_ability_freezing_field_aura:GetAuraDuration()
	return self.slow_duration
end

function modifier_ability_freezing_field_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end 

function modifier_ability_freezing_field_aura:GetModifierPhysicalArmorBonus()
    return self:GetStackCount()
end 

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_freezing_field_aura:OnCreated( kv )
	-- references
	self.slow_radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.slow_duration = self:GetAbility():GetSpecialValueFor( "slow_duration" )
	self.explosion_radius = self:GetAbility():GetSpecialValueFor( "explosion_radius" )
	self.explosion_interval = self:GetAbility():GetSpecialValueFor( "explosion_interval" )
	self.explosion_min_dist = self:GetAbility():GetSpecialValueFor( "explosion_min_dist" )
    self.explosion_max_dist = self:GetAbility():GetSpecialValueFor( "explosion_max_dist" )
    self:SetStackCount(self:GetAbility():GetSpecialValueFor( "bonus_armor" ))
	local explosion_damage = self:GetAbility():GetSpecialValueFor( "damage" )

	-- generate data
	self.quartal = -1

	if IsServer() then
		-- precache damage
		self.damageTable = {
			-- victim = target,
			attacker = self:GetCaster(),
			damage = explosion_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self, --Optional.
		}

		-- Start interval
		self:StartIntervalThink( self.explosion_interval )
		self:OnIntervalThink()

		-- Play Effects
		self:PlayEffects1()
	end
end

function modifier_ability_freezing_field_aura:OnRefresh( kv )
	-- references
	self.slow_radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.explosion_radius = self:GetAbility():GetSpecialValueFor( "explosion_radius" )
	self.explosion_interval = self:GetAbility():GetSpecialValueFor( "explosion_interval" )
	self.explosion_min_dist = self:GetAbility():GetSpecialValueFor( "explosion_min_dist" )
	self.explosion_max_dist = self:GetAbility():GetSpecialValueFor( "explosion_max_dist" )
	local explosion_damage = self:GetAbility():GetSpecialValueFor( "damage" )

	-- generate data
	self.quartal = -1

	if IsServer() then
		-- precache damage
		self.damageTable = {
			-- victim = target,
			attacker = self:GetCaster(),
			damage = explosion_damage,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self, --Optional.
		}

		-- Start interval
		self:StartIntervalThink( self.explosion_interval )
		self:OnIntervalThink()
	end
end

function modifier_ability_freezing_field_aura:OnDestroy( kv )
	if IsServer() then
		self:StartIntervalThink( -1 )
		self:StopEffects1()
	end
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_ability_freezing_field_aura:OnIntervalThink()
	-- Set explosion quartal
	self.quartal = self.quartal+1
	if self.quartal>3 then self.quartal = 0 end

	-- determine explosion relative position
	local a = RandomInt(0,90) + self.quartal*90
	local r = RandomInt(self.explosion_min_dist,self.explosion_max_dist)
	local point = Vector( math.cos(a), math.sin(a), 0 ):Normalized() * r

	-- actual position
	point = self:GetCaster():GetOrigin() + point

	-- Explode at point
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		point,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.explosion_radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	-- damage units
	for _,enemy in pairs(enemies) do
		self.damageTable.victim = enemy
		ApplyDamage( self.damageTable )
	end

	-- Play effects
	self:PlayEffects2( point )
end

--------------------------------------------------------------------------------
-- Effects
function modifier_ability_freezing_field_aura:PlayEffects1()
	local particle_cast = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_snow.vpcf"
	self.sound_cast = "hero_Crystal.freezingField.wind"

	-- Create Particle
	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( self.slow_radius, self.slow_radius, 1 ) )
	self:AddParticle(
		self.effect_cast,
		false,
		false,
		-1,
		false,
		false
	)

	-- Play sound
	EmitSoundOn( self.sound_cast, self:GetCaster() )
end

function modifier_ability_freezing_field_aura:PlayEffects2( point )
	-- Play particles
	local particle_cast = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"

	-- Create particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, point )

	-- Play sound
	local sound_cast = "hero_Crystal.freezingField.explosion"
	EmitSoundOnLocationWithCaster( point, sound_cast, self:GetCaster() )
end

function modifier_ability_freezing_field_aura:StopEffects1()
	StopSoundOn( self.sound_cast, self:GetCaster() )
end

modifier_ability_freezing_field_aura_effect = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_freezing_field_aura_effect:IsHidden()
	return false
end

function modifier_ability_freezing_field_aura_effect:IsDebuff()
	return true
end

function modifier_ability_freezing_field_aura_effect:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_freezing_field_aura_effect:OnCreated( kv )
	-- references
	self.ms_slow = self:GetAbility():GetSpecialValueFor( "movespeed_slow" )
	self.as_slow = self:GetAbility():GetSpecialValueFor( "attack_slow" )
end

function modifier_ability_freezing_field_aura_effect:OnRefresh( kv )
	-- references
	self.ms_slow = self:GetAbility():GetSpecialValueFor( "movespeed_slow" )
	self.as_slow = self:GetAbility():GetSpecialValueFor( "attack_slow" )	
end

function modifier_ability_freezing_field_aura_effect:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ability_freezing_field_aura_effect:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}

	return funcs
end

function modifier_ability_freezing_field_aura_effect:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_slow
end

function modifier_ability_freezing_field_aura_effect:GetModifierAttackSpeedBonus_Constant()
	return self.as_slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ability_freezing_field_aura_effect:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_ability_freezing_field_aura_effect:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end