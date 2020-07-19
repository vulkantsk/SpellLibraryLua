ability_crystal_nova = class({})

function ability_crystal_nova:GetAOERadius() return self:GetSpecialValueFor("radius") end

function ability_crystal_nova:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- load data
	local damage = self:GetSpecialValueFor("nova_damage")
	local radius = self:GetSpecialValueFor("radius")
	local debuffDuration = self:GetSpecialValueFor("duration")

	local vision_radius = 900
	local vision_duration = self:GetSpecialValueFor("vision_duration")

	-- Find Units in Radius
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		point,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	-- Precache damage	 
	local damageTable = {
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self, --Optional.
	}

	for _,enemy in pairs(enemies) do
		-- Apply damage
		damageTable.victim = enemy
		ApplyDamage(damageTable)

		-- Add modifier
		enemy:AddNewModifier(
			caster, -- player source
			self, -- ability source
			"modifier_ability_crystal_nova_debuff", -- modifier name
			{ duration = debuffDuration } -- kv
		)
	end

	AddFOWViewer( self:GetCaster():GetTeamNumber(), point, vision_radius, vision_duration, true )

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_crystalmaiden/maiden_crystal_nova.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, point )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, debuffDuration, radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( point, "Hero_Crystal.CrystalNova", self:GetCaster() )
end
LinkLuaModifier( "modifier_ability_crystal_nova_debuff", "heroes/crystal_maiden/crystal_nova", LUA_MODIFIER_MOTION_NONE )

modifier_ability_crystal_nova_debuff = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_ability_crystal_nova_debuff:IsHidden()
	return false
end

function modifier_ability_crystal_nova_debuff:IsDebuff()
	return true
end

function modifier_ability_crystal_nova_debuff:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_ability_crystal_nova_debuff:OnCreated( kv )
	-- references
	self.as_slow = self:GetAbility():GetSpecialValueFor( "attackspeed_slow" ) -- special value
	self.ms_slow = self:GetAbility():GetSpecialValueFor( "movespeed_slow" ) -- special value
end

function modifier_ability_crystal_nova_debuff:OnRefresh( kv )
	-- references
	self.as_slow = self:GetAbility():GetSpecialValueFor( "attackspeed_slow" ) -- special value
	self.ms_slow = self:GetAbility():GetSpecialValueFor( "movespeed_slow" ) -- special value	
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_ability_crystal_nova_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}

	return funcs
end

function modifier_ability_crystal_nova_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_slow
end

function modifier_ability_crystal_nova_debuff:GetModifierAttackSpeedBonus_Constant()
	return self.as_slow
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_ability_crystal_nova_debuff:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_ability_crystal_nova_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end