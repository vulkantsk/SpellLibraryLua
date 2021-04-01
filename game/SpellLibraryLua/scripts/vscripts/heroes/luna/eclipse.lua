LinkLuaModifier( "modifier_ability_eclipse", "heroes/luna/eclipse", LUA_MODIFIER_MOTION_NONE )

ability_eclipse = {}

function ability_eclipse:GetAOERadius()
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "radius" )
	end
	return 0
end

function ability_eclipse:GetBehavior()
	if self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_OPTIONAL_POINT + DOTA_ABILITY_BEHAVIOR_AOE
	end

	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end

function ability_eclipse:GetCastRange( vLocation, hTarget )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "cast_range_tooltip_scepter" )
	end
	return self:GetSpecialValueFor( "radius" )
end

function ability_eclipse:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()

	local damage = 0
	if self.damage then
		damage = self.damage
	else
		local ability = caster:FindAbilityByName( "ability_lucent_beam" )
		if ability and ability:GetLevel()>0 then
			damage = ability:GetLevelSpecialValueFor( "beam_damage", ability:GetLevel()-1 )
		end
	end

	local unit = caster
	if caster:HasScepter() then
		if target then
			unit = target
		else
			unit = nil
		end
	end

	if unit then
		unit:AddNewModifier(
			caster,
			self,
			"modifier_ability_eclipse",
			{ damage = damage }
		)
	else
		caster:AddNewModifier(
			caster,
			self,
			"modifier_ability_eclipse",
			{
				damage = damage,
				point = 1,
				pointx = point.x,
				pointy = point.y,
				pointz = point.z,
			}
		)
	end

	GameRules:BeginTemporaryNight( 10 )
end

function ability_eclipse:OnStolen( hSourceAbility )
	self.damage = 0
	local ability = hSourceAbility:GetCaster():FindAbilityByName( "ability_lucent_beam" )
	if ability and ability:GetLevel()>0 then
		self.damage = ability:GetLevelSpecialValueFor( "beam_damage", ability:GetLevel()-1 )
	end
end

modifier_ability_eclipse = {}

function modifier_ability_eclipse:IsHidden()
	return false
end

function modifier_ability_eclipse:IsDebuff()
	return false
end

function modifier_ability_eclipse:IsPurgable()
	return false
end

function modifier_ability_eclipse:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ability_eclipse:OnCreated( kv )
	if self:GetCaster():HasScepter() then
		self.beams = self:GetAbility():GetSpecialValueFor( "beams_scepter" )
		self.hit_count = self:GetAbility():GetSpecialValueFor( "hit_count_scepter" )
		self.beam_interval = self:GetAbility():GetSpecialValueFor( "beam_interval_scepter" )
	else
		self.beams = self:GetAbility():GetSpecialValueFor( "beams" )
		self.hit_count = self:GetAbility():GetSpecialValueFor( "hit_count" )
		self.beam_interval = self:GetAbility():GetSpecialValueFor( "beam_interval" )
	end
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )


	self.parent = self:GetParent()
	self.caster = self:GetCaster()

	if IsServer() then
		if kv.point==1 then
			self.point = Vector( kv.pointx, kv.pointy, kv.pointz )

			AddFOWViewer( self:GetCaster():GetTeamNumber(), self.point, self.radius + 75, self.beams*self.beam_interval, true)
		end
		self.counter = 0
		self.hits = {}


		self.damageTable = {
			attacker = self.caster,
			damage = kv.damage,
			damage_type = self:GetAbility():GetAbilityDamageType(),
			ability = self:GetAbility()
		}

		self:StartIntervalThink( self.beam_interval )
		self:OnIntervalThink()

		local effect_cast = nil
		if self.point then
			effect_cast = ParticleManager:CreateParticle(
				"particles/units/heroes/hero_luna/luna_eclipse.vpcf",
				PATTACH_WORLDORIGIN,
				nil
			)
			ParticleManager:SetParticleControl( effect_cast, 0, self.point )

			EmitSoundOnLocationWithCaster( self.point, "Hero_Luna.Eclipse.Cast", self:GetParent() )
		else
			effect_cast = ParticleManager:CreateParticle(
				"particles/units/heroes/hero_luna/luna_eclipse.vpcf",
				PATTACH_ABSORIGIN_FOLLOW,
				self:GetParent()
			)

			EmitSoundOn( "Hero_Luna.Eclipse.Cast", self:GetParent() )
		end

		ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )

		self:AddParticle(
			effect_cast,
			false,
			false,
			-1,
			false,
			false
		)
	end
end

function modifier_ability_eclipse:OnIntervalThink()
	local point = self.point or self.parent:GetOrigin()
	local units = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		point,
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
		0,
		false
	)

	local unit = nil
	if #units>0 then
		for i=1,#units do
			unit = units[i]
			self.hits[unit] = self.hits[unit] or 0
			self.hits[unit] = self.hits[unit]+1
			if self.hits[unit]<=self.hit_count then
				self.damageTable.victim = unit
				ApplyDamage(self.damageTable)
				break
			end
			unit = nil
		end
	end

	if not unit then
		local vector = point + RandomVector( RandomInt( 0, self.radius ) )
		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_luna/luna_lucent_beam.vpcf",
			PATTACH_WORLDORIGIN,
			nil
		)
		ParticleManager:SetParticleControl( effect_cast, 0, vector )
		ParticleManager:SetParticleControl( effect_cast, 1, vector )
		ParticleManager:SetParticleControl( effect_cast, 5, vector )
		ParticleManager:SetParticleControl( effect_cast, 6, vector )
		ParticleManager:ReleaseParticleIndex( effect_cast )

		EmitSoundOnLocationWithCaster( vector, "Hero_Luna.Eclipse.NoTarget", self.caster )

		return
	end

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_luna/luna_lucent_beam.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		unit
	)
	ParticleManager:SetParticleControl( effect_cast, 0, unit:GetOrigin() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		unit,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		5,
		unit,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		6,
		unit,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Luna.Eclipse.Target", unit )

	self.counter = self.counter + 1
	if self.counter>=self.beams then
		self:StartIntervalThink( -1 )
		self:Destroy()
	end
end