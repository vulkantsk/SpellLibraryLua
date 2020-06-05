ability_mana_void = class({})
-- Original https://github.com/Elfansoer/dota-2-lua-abilities/blob/master/scripts/vscripts/lua_abilities/antimage_mana_void_lua/antimage_mana_void_lua.lua
function ability_mana_void:GetAOERadius()
	return self:GetSpecialValueFor( "mana_void_aoe_radius" )
end

--------------------------------------------------------------------------------
-- Ability Phase Start
function ability_mana_void:OnAbilityPhaseStart( kv )
	local target = self:GetCursorTarget()
	self:PlayEffects1( true )

	return true -- if success
end
function ability_mana_void:OnAbilityPhaseInterrupted()
	self:PlayEffects1( false )
end

--------------------------------------------------------------------------------
-- Ability Start
function ability_mana_void:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- cancel if got linken
	if target == nil or target:IsInvulnerable() or target:TriggerSpellAbsorb( self ) then
		return
	end

	-- load data
	local mana_damage_pct = self:GetSpecialValueFor("mana_void_damage_per_mana")
	local mana_stun = self:GetSpecialValueFor("mana_void_ministun")
	local radius = self:GetSpecialValueFor( "mana_void_aoe_radius" )

	-- Add modifier
	target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_stunned", -- modifier name
		{ duration = mana_stun } -- kv
	)

	local mana_damage_pct = (target:GetMaxMana() - target:GetMana()) * mana_damage_pct

	local damageTable = {
		victim = target,
		attacker = caster,
		damage = mana_damage_pct,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self, 
	}

	-- Find Units in Radius
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		target:GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	for _,enemy in pairs(enemies) do
		damageTable.victim = enemy
		ApplyDamage(damageTable)
	end

	-- Play Effects
	self:PlayEffects2( target, radius )
end
--------------------------------------------------------------------------------
function ability_mana_void:PlayEffects1( bStart )
	local sound_cast = "Hero_Antimage.ManaVoidCast"

	if bStart then
		self.target = self:GetCursorTarget()
		EmitSoundOn( sound_cast, self.target )
	else
		StopSoundOn(sound_cast, self.target)
		self.target = nil
	end
end

function ability_mana_void:PlayEffects2( target, radius )
	-- Get Resources
	local particle_target = "particles/units/heroes/hero_antimage/antimage_manavoid.vpcf"
	local sound_target = "Hero_Antimage.ManaVoid"

	local effect_target = ParticleManager:CreateParticle( particle_target, PATTACH_POINT_FOLLOW, target )
	ParticleManager:SetParticleControl( effect_target, 1, Vector( radius, 0, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_target )

	-- Create Sound
	EmitSoundOn( sound_target, target )
end