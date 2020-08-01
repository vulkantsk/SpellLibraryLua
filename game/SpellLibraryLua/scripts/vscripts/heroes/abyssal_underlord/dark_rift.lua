ability_dark_rift = {}

LinkLuaModifier( "modifier_ability_dark_rift", "heroes/abyssal_underlord/dark_rift", LUA_MODIFIER_MOTION_NONE )

function ability_dark_rift:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()

	if not target then
		local targets = FindUnitsInRadius(
			caster:GetTeamNumber(),
			point,
			nil,
			FIND_UNITS_EVERYWHERE,
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			DOTA_UNIT_TARGET_BUILDING + DOTA_UNIT_TARGET_CREEP,
			DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
			FIND_CLOSEST,
			false
		)

		if #targets>0 then target = targets[1] end
	end

	if not target then return end

	local duration = self:GetSpecialValueFor( "teleport_delay" )

	local modifier = target:AddNewModifier(
		caster,
		self,
		"modifier_ability_dark_rift",
		{ duration = duration }
	)

	local ability = caster:FindAbilityByName( "ability_cancel_dark_rift" )
	if not ability then
		ability = caster:AddAbility( "ability_cancel_dark_rift" )
		ability:SetStolen( true )
	end

	ability:SetLevel( 1 )

	ability.modifier = modifier

	caster:SwapAbilities(
		self:GetAbilityName(),
		ability:GetAbilityName(),
		false,
		true
	)
end

ability_cancel_dark_rift = {}

function ability_cancel_dark_rift:OnSpellStart()
	self.modifier:Cancel()
	self.modifier = nil
end

modifier_ability_dark_rift = class({})

function modifier_ability_dark_rift:IsHidden()
	return false
end

function modifier_ability_dark_rift:IsDebuff()
	return false
end

function modifier_ability_dark_rift:IsPurgable()
	return false
end

function modifier_ability_dark_rift:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_dark_rift:OnCreated( kv )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )

	if not IsServer() then return end

	self.success = true

	self:PlayEffects1()
	self:PlayEffects2()
end

function modifier_ability_dark_rift:OnRemoved()
	if not IsServer() then return end
	if not self.success then return end

	local caster = self:GetCaster()

	self:PlayEffects3()

	local targets = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetOrigin(),
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,	-
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,
		0,
		false
	)

	local point = self:GetParent():GetOrigin()
	for _,target in pairs(targets) do
		ProjectileManager:ProjectileDodge( target )

		FindClearSpaceForUnit( target, point, true )
	end

	local ability = self:GetCaster():FindAbilityByName( "ability_cancel_dark_rift" )
	if not ability then return end

	caster:SwapAbilities(
		self:GetAbility():GetAbilityName(),
		ability:GetAbilityName(),
		true,
		false
	)
end

function modifier_ability_dark_rift:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH,
	}

	return funcs
end

function modifier_ability_dark_rift:OnDeath( params )
	if not IsServer() then return end

	if params.unit~=self:GetCaster() and params.unit~=self:GetParent() then return end

	self:Cancel()
end

function modifier_ability_dark_rift:CheckState()
	local state = {
		[MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true,
	}

	return state
end

function modifier_ability_dark_rift:Cancel()
	self.success = false

	local ability = self:GetCaster():FindAbilityByName( "ability_cancel_dark_rift" )
	if not ability then return end
	self:GetCaster():SwapAbilities(
		self:GetAbility():GetAbilityName(),
		ability:GetAbilityName(),
		true,
		false
	)

	self:PlayEffects4()

	self:Destroy()
end

function modifier_ability_dark_rift:PlayEffects1()
	local particle_cast = "particles/units/heroes/heroes_underlord/abyssal_underlord_darkrift_target.vpcf"
	local sound_cast = "Hero_AbyssalUnderlord.DarkRift.Target"

	local parent = self:GetParent()

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_OVERHEAD_FOLLOW, parent )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		6,
		parent,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0),
		true
	)

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false 
	)

	EmitSoundOn( sound_cast, parent )
end

function modifier_ability_dark_rift:PlayEffects2()
	local particle_cast = "particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_ambient.vpcf"
	local sound_cast = "Hero_AbyssalUnderlord.DarkRift.Cast"

	local caster = self:GetCaster()
	local parent = self:GetParent()

	self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( self.radius, 0, 0 ) )
	ParticleManager:SetParticleControlEnt(
		self.effect_cast,
		2,
		caster,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0),
		true
	)

	self:AddParticle(
		self.effect_cast,
		false,
		false,
		-1,
		false,
		false 
	)

	EmitSoundOn( sound_cast, caster )
end

function modifier_ability_dark_rift:PlayEffects3()
	local sound_cast1 = "Hero_AbyssalUnderlord.DarkRift.Complete"
	local sound_cast2 = "Hero_AbyssalUnderlord.DarkRift.Aftershock"

	local caster = self:GetCaster()
	local parent = self:GetParent()

	ParticleManager:SetParticleControl( self.effect_cast, 5, caster:GetOrigin() )

	EmitSoundOn( sound_cast1, parent )
	EmitSoundOnLocationWithCaster( caster:GetOrigin(), sound_cast2, caster )
end

function modifier_ability_dark_rift:PlayEffects4()
	local caster = self:GetCaster()
	local parent = self:GetParent()

	ParticleManager:DestroyParticle( self.effect_cast, true )

	StopSoundOn( "Hero_AbyssalUnderlord.DarkRift.Cast", caster )
	StopSoundOn( "Hero_AbyssalUnderlord.DarkRift.Target", parent )
	EmitSoundOn( "Hero_AbyssalUnderlord.DarkRift.Cancel", caster )
	EmitSoundOn( "Hero_AbyssalUnderlord.DarkRift.Cancel", parent )
end