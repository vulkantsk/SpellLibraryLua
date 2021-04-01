LinkLuaModifier( "modifier_ability_magnetize", "heroes/earth_spirit/magnetize", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_magnetize_expire", "heroes/earth_spirit/magnetize", LUA_MODIFIER_MOTION_NONE )

ability_magnetize = {}

function ability_magnetize:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("cast_radius")
	local duration = self:GetSpecialValueFor("damage_duration")
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		caster:GetOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(
			caster,
			self,
			"modifier_ability_magnetize",
			{ duration = duration }
		)
	end

	self:PlayEffects( radius )
end

ability_magnetize.debuff_tracker = {}

function ability_magnetize:AddDebuff( modifier )
	table.insert( self.debuff_tracker, modifier )
end

function ability_magnetize:RemoveDebuff( modifier )
	for i,mod in pairs(self.debuff_tracker) do
		if mod==modifier then
			table.remove( self.debuff_tracker, i )
		end
	end
end

function ability_magnetize:ApplyDebuff( ability, modifier_name, duration )
	for _,mod in pairs(self.debuff_tracker) do
		local parent = mod:GetParent()
		if parent:IsAlive() and (not parent:IsMagicImmune()) and (not parent:IsInvulnerable()) then
			parent:AddNewModifier(
				self:GetCaster(),
				ability,
				modifier_name,
				{ duration = duration }
			)
		end
	end
end

function ability_magnetize:PlayEffects( radius )
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_earth_spirit/espirit_magnetize_pulse.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetCaster()
	)
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( radius, 0, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_EarthSpirit.Magnetize.Cast", self:GetCaster() )
end

modifier_ability_magnetize = {}

function modifier_ability_magnetize:IsHidden()
	return false
end

function modifier_ability_magnetize:IsDebuff()
	return true
end

function modifier_ability_magnetize:IsStunDebuff()
	return false
end

function modifier_ability_magnetize:IsPurgable()
	return true
end

function modifier_ability_magnetize:OnCreated( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage_per_second" )
	self.search = self:GetAbility():GetSpecialValueFor( "rock_search_radius" )
	self.explode = self:GetAbility():GetSpecialValueFor( "rock_explosion_radius" )
	self.duration = self:GetAbility():GetSpecialValueFor( "damage_duration" )
	self.expire = self:GetAbility():GetSpecialValueFor( "rock_explosion_delay" )
	
	self.interval = 0.5

	if IsServer() then
		self.damageTable = {
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			damage = damage*self.interval,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self:GetAbility(),
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
		}

		self:StartIntervalThink( self.interval )
		self:GetAbility():AddDebuff( self )
	end
end

function modifier_ability_magnetize:OnRefresh( kv )
	local damage = self:GetAbility():GetSpecialValueFor( "damage_per_second" )
	self.search = self:GetAbility():GetSpecialValueFor( "rock_search_radius" )
	self.explode = self:GetAbility():GetSpecialValueFor( "rock_explosion_radius" )
	self.duration = self:GetAbility():GetSpecialValueFor( "damage_duration" )
	self.expire = self:GetAbility():GetSpecialValueFor( "rock_explosion_delay" )

	if IsServer() then
		self.damageTable.damage = damage*self.interval

		self:StartIntervalThink( -1 )
		self:StartIntervalThink( self.interval )
	end
end

function modifier_ability_magnetize:OnRemoved( kv )
	if IsServer() then
		self:GetAbility():RemoveDebuff( self )
		EmitSoundOn( "Hero_EarthSpirit.Magnetize.End", self:GetParent() )
	end
end

function modifier_ability_magnetize:OnIntervalThink()
	ApplyDamage(self.damageTable)

	local remnant = self:SearchRemnant( self:GetParent():GetOrigin(), self.search )
	if remnant and (not remnant:HasModifier( "modifier_ability_magnetize_expire" ) ) then
		remnant:AddNewModifier(
			self:GetCaster(),
			self:GetAbility(),
			"modifier_ability_magnetize_expire",
			{ duration = self.expire }
		)

		local enemies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),
			remnant:GetOrigin(),
			nil,
			self.explode,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			0,
			false
		)

		for _,enemy in pairs(enemies) do
			enemy:AddNewModifier(
				self:GetCaster(),
				self:GetAbility(),
				"modifier_ability_magnetize",
				{ duration = self.duration }
			)
		end

		self:PlayEffects2( remnant, enemies )
	end

	self:PlayEffects1()
end

function modifier_ability_magnetize:SearchRemnant( point, radius )
	local remnants = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		point,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_CLOSEST,
		false
	)

	local ret = nil
	for _,remnant in pairs(remnants) do
		if remnant:HasModifier( "modifier_ability_stone_caller" ) then
			return remnant
		end
	end
	return ret
end

function modifier_ability_magnetize:ApplyDebuff( ability, modifier_name, duration )
	self:GetAbility():ApplyDebuff( ability, modifier_name, duration )
end

function modifier_ability_magnetize:PlayEffects1()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_earth_spirit/espirit_magnetize_target.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetParent()
	)
	ParticleManager:SetParticleControl( effect_cast, 1, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( self.search, 0, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_EarthSpirit.Magnetize.Target.Tick", self:GetParent() )
end

function modifier_ability_magnetize:PlayEffects2( remnant, enemies )
	local effect_cast = 0
	for _,enemy in pairs(enemies) do
		effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_earth_spirit/espirit_magnet_arclightning.vpcf",
			PATTACH_ABSORIGIN_FOLLOW,
			remnant
		)
		ParticleManager:SetParticleControlEnt(
			effect_cast,
			1,
			enemy,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			Vector(0,0,0),
			true
		)
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end

	EmitSoundOn( "Hero_EarthSpirit.Magnetize.StoneBolt", remnant )
end

modifier_ability_magnetize_expire = {}

function modifier_ability_magnetize_expire:IsHidden()
	return true
end

function modifier_ability_magnetize_expire:IsPurgable()
	return false
end

function modifier_ability_magnetize_expire:OnCreated( kv )
	if IsServer() then
		self:PlayEffects()
	end
end

function modifier_ability_magnetize_expire:OnRemoved( kv )
	if IsServer() then
		local modifier = self:GetParent():FindModifierByName( "modifier_ability_stone_caller" )
		if modifier then
			modifier:Destroy()
		end
	end
end

function modifier_ability_magnetize_expire:PlayEffects()
	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_earth_spirit/espirit_stoneismagnetized_xpld.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		self:GetParent()
	)

	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)
end