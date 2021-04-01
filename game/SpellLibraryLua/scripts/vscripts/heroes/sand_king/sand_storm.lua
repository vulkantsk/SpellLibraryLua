LinkLuaModifier( "modifier_ability_sand_storm", "heroes/sand_king/sand_storm", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_sand_storm_invis", "heroes/sand_king/sand_storm", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_sand_storm_invis_delay", "heroes/sand_king/sand_storm", LUA_MODIFIER_MOTION_NONE )

ability_sand_storm = {}

function ability_sand_storm:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier( caster, self, "modifier_ability_sand_storm", {
		duration = self:GetDuration()
	} )
	caster:AddNewModifier( caster, self, "modifier_ability_sand_storm_invis", {
		duration = self:GetDuration()
	} )

	EmitSoundOn( "Ability.SandKing_SandStorm.start", caster )
end

modifier_ability_sand_storm = {}

function modifier_ability_sand_storm:IsHidden()
	return true
end

function modifier_ability_sand_storm:OnCreated()
	if IsClient() then
		return
	end

	local ability = self:GetAbility()
	local parent = self:GetParent()

	self.radius = ability:GetSpecialValueFor( "sand_storm_radius" )
	self.damage_interval = ability:GetSpecialValueFor( "damage_tick_rate" )
	self.next_damage_time = GameRules:GetGameTime() + self.damage_interval
	self.start_pos = parent:GetAbsOrigin()
	self.damageTable = {
		attacker = parent,
		damage = ability:GetSpecialValueFor( "sand_storm_damage" ) * self.damage_interval,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability
	}
	self.effect = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_sandking/sandking_sandstorm.vpcf",
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl( self.effect, 0, parent:GetAbsOrigin() )
	ParticleManager:SetParticleControl( self.effect, 1, Vector( self.radius, self.radius, self.radius ) )

	EmitSoundOn( "Ability.SandKing_SandStorm.start", caster )

	self:StartIntervalThink( 0 )
end

function modifier_ability_sand_storm:OnDestroy()
	ParticleManager:DestroyParticle( self.effect, false )
	self:GetParent():RemoveModifierByName( "modifier_ability_sand_storm_invis" )
end

function modifier_ability_sand_storm:OnIntervalThink()
	if ( self.start_pos - self:GetParent():GetAbsOrigin() ):Length2D() > self.radius then
		self:Destroy()

		return
	end

	if GameRules:GetGameTime() >= self.next_damage_time then
		self:Damage()
	end
end

function modifier_ability_sand_storm:Damage()
	local parent = self:GetParent()
	local enemies = FindUnitsInRadius(
		parent:GetTeamNumber(),
		parent:GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		self.damageTable.victim = enemy
		ApplyDamage( self.damageTable )
	end
end

function modifier_ability_sand_storm:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_ability_sand_storm:OnAttackLanded( data )
	if IsClient() then
		return
	end

	local parent = self:GetParent()

	parent:RemoveModifierByName( "modifier_ability_sand_storm_invis" )
	parent:AddNewModifier(
		parent,
		self,
		"modifier_ability_sand_storm_invis_delay",
		{ duration = self:GetAbility():GetSpecialValueFor( "fade_delay" ) }
	)
end

modifier_ability_sand_storm_invis = {}

function modifier_ability_sand_storm_invis:DeclareFunctions()
	return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL }
end

function modifier_ability_sand_storm_invis:GetModifierInvisibilityLevel()
	return 1
end

function modifier_ability_sand_storm_invis:CheckState()
	return { [MODIFIER_STATE_INVISIBLE] = true }
end

modifier_ability_sand_storm_invis_delay = {}

function modifier_ability_sand_storm_invis_delay:IsHidden()
	return true
end

function modifier_ability_sand_storm_invis_delay:OnDestroy()
	local parent = self:GetParent()
	local modifier = parent:FindModifierByName( "modifier_ability_sand_storm" )

	if modifier then
		parent:AddNewModifier( self:GetAbility(), parent, "modifier_ability_sand_storm_invis", {
			duration = modifier:GetRemainingTime()
		} )
	end
end