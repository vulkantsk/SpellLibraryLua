LinkLuaModifier( "modifier_ability_multicast", "heroes/ogre_magi/multicast", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_multicast_proc", "heroes/ogre_magi/multicast", LUA_MODIFIER_MOTION_NONE )

ability_multicast = {}

function ability_multicast:GetIntrinsicModifierName()
	return "modifier_ability_multicast"
end

function ability_multicast:OnInventoryContentsChanged( params )
	local caster = self:GetCaster()

	local scepter = caster:HasScepter()
	local ability = caster:FindAbilityByName( "ogre_magi_unrefined_fireblast_lua" )

	if not ability then return end

	ability:SetActivated( scepter )
	ability:SetHidden( not scepter )

	if ability:GetLevel()~=1 then
		ability:SetLevel( 1 )
	end
end

modifier_ability_multicast = {}
modifier_ability_multicast.singles = {
	["ability_fireblast"] = true,
	["ability_unrefined_fireblast"] = true,
	["ogre_magi_fireblast"] = true,
	["ogre_magi_unrefined_fireblast"] = true,
}

function modifier_ability_multicast:IsHidden()
	return false
end

function modifier_ability_multicast:IsDebuff()
	return false
end

function modifier_ability_multicast:IsPurgable()
	return false
end

function modifier_ability_multicast:OnCreated( kv )
	self.chance_2 = self:GetAbility():GetSpecialValueFor( "multicast_2_times" ) * 100
	self.chance_3 = self:GetAbility():GetSpecialValueFor( "multicast_3_times" ) * 100
	self.chance_4 = self:GetAbility():GetSpecialValueFor( "multicast_4_times" ) * 100
	self.buffer_range = 300
end

modifier_ability_multicast.OnRefresh = modifier_ability_multicast.OnCreated

function modifier_ability_multicast:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_ability_multicast:OnAbilityFullyCast( params )
	if params.unit~=self:GetCaster() then return end
	if params.ability==self:GetAbility() then return end
	if self:GetCaster():PassivesDisabled() then return end
	if not params.target then return end
	local behavior = tonumber( tostring( params.ability:GetBehavior() ) )
	if bit.band( behavior, DOTA_ABILITY_BEHAVIOR_POINT ) ~= 0 then return end
	if bit.band( behavior, DOTA_ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET ) ~= 0 then return end

	local casts = 1
	if RandomInt( 0,100 ) < self.chance_2 then casts = 2 end
	if RandomInt( 0,100 ) < self.chance_3 then casts = 3 end
	if RandomInt( 0,100 ) < self.chance_4 then casts = 4 end

	local delay = params.ability:GetSpecialValueFor( "multicast_delay" ) or 0

	local single = self.singles[params.ability:GetAbilityName()] or false

	self:GetCaster():AddNewModifier(
		self:GetCaster(),
		self:GetAbility(),
		"modifier_ability_multicast_proc",
		{
			ability = params.ability:entindex(),
			target = params.target:entindex(),
			multicast = casts,
			delay = delay,
			single = single,
		}
	)
end

modifier_ability_multicast_proc = {}

function modifier_ability_multicast_proc:IsHidden()
	return true
end

function modifier_ability_multicast_proc:IsDebuff()
	return false
end

function modifier_ability_multicast_proc:IsStunDebuff()
	return false
end

function modifier_ability_multicast_proc:IsPurgable()
	return true
end

function modifier_ability_multicast_proc:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_multicast_proc:OnCreated( kv )
	if not IsServer() then return end
	self.caster = self:GetParent()
	self.ability = EntIndexToHScript( kv.ability )
	self.target = EntIndexToHScript( kv.target )
	self.multicast = kv.multicast
	self.delay = kv.delay
	self.single = kv.single==1
	self.buffer_range = 300

	self:SetStackCount( self.multicast )

	self.casts = 0
	if self.multicast==1 then
		self:Destroy()
		return
	end

	self.targets = {}
	self.targets[self.target] = true

	self.radius = self.ability:GetCastRange( self.target:GetOrigin(), self.target ) + self.buffer_range

	self.target_team = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	if self.target:GetTeamNumber()~=self.caster:GetTeamNumber() then
		self.target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	end

	self.target_type = self.ability:GetAbilityTargetType()
	if self.target_type==DOTA_UNIT_TARGET_CUSTOM then
		self.target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	end

	self.target_flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
	if bit.band( self.ability:GetAbilityTargetFlags(), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES ) ~= 0 then
		self.target_flags = self.target_flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end

	self:Effect()

	self:StartIntervalThink( self.delay )
end

function modifier_ability_multicast_proc:OnIntervalThink()
	local current_target = nil

	if self.single then
		current_target = self.target
	else
		local units = FindUnitsInRadius(
			self.caster:GetTeamNumber(),
			self.caster:GetOrigin(),
			nil,
			self.radius,
			self.target_team,
			self.target_type,
			self.target_flags,
			FIND_CLOSEST,
			false
		)

		for _,unit in pairs(units) do
			if not self.targets[unit] then

				local filter = false
				if self.ability.CastFilterResultTarget then
					filter = self.ability:CastFilterResultTarget( unit ) == UF_SUCCESS
				else
					filter = true
				end

				if filter then
					self.targets[unit] = true
					current_target = unit

					break
				end
			end
		end

		if not current_target then
			self:StartIntervalThink( -1 )
			self:Destroy()
			return
		end
	end

	self.caster:SetCursorCastTarget( current_target )
	self.ability:OnSpellStart()

	self.casts = self.casts + 1
	if self.casts>=(self.multicast-1) then
		self:StartIntervalThink( -1 )
		self:Destroy()
	end

	self:Effect()
end

function modifier_ability_multicast_proc:Effect()
	local value = self.casts + 1

	local counter_speed = 2
	if value==self.multicast then
		counter_speed = 1
	end

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf",
		PATTACH_OVERHEAD_FOLLOW,
		self.caster
	)
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( value, counter_speed, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	local sound = math.min( value-1, 3 )
	local sound_cast = "Hero_OgreMagi.Fireblast.x" .. sound
	if sound>0 then
		EmitSoundOn( sound_cast, self.caster )
	end
end