ability_laser = {}

LinkLuaModifier( "modifier_ability_laser", "heroes/tinker/laser", LUA_MODIFIER_MOTION_NONE )

function ability_laser:OnAbilityPhaseStart()
	EmitSoundOn( "Hero_Tinker.LaserAnim", self:GetCaster() )

	return true
end

function ability_laser:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb( self ) then
		return
	end

	local duration_hero = self:GetSpecialValueFor("duration_hero")
	local duration_creep = self:GetSpecialValueFor("duration_creep")
	local damage = self:GetSpecialValueFor("laser_damage")

	local targets = {}
	table.insert( targets, target )
	if caster:HasScepter() then
		self:Refract( targets, 1 )
	end

	local damage = {
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_PURE,
		ability = self
	}
	for _,enemy in pairs(targets) do
		damage.victim = enemy
		ApplyDamage( damage )

		local duration = duration_hero
		if enemy:IsCreep() then
			duration = duration_creep
		end
		enemy:AddNewModifier(
			caster,
			self,
			"modifier_ability_laser",
			{ duration = duration }
		)
	end

	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_tinker/tinker_laser.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	local attach = "attach_attack1"
	if self:GetCaster():ScriptLookupAttachment( "attach_attack2" )~=0 then attach = "attach_attack2" end
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		9,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		attach,
		Vector(0,0,0),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		targets[1],
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Tinker.Laser", self:GetCaster() )
	EmitSoundOn( "Hero_Tinker.LaserImpact", targets[1] )

	if #targets>1 then
		for i=2,#targets do
			local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
			ParticleManager:SetParticleControlEnt(
				effect_cast,
				9,
				targets[i-1],
				PATTACH_POINT_FOLLOW,
				"attach_hitloc",
				Vector(0,0,0),
				true 
			)
			ParticleManager:SetParticleControlEnt(
				effect_cast,
				1,
				targets[i],
				PATTACH_POINT_FOLLOW,
				"attach_hitloc",
				Vector(0,0,0),
				true
			)
			ParticleManager:ReleaseParticleIndex( effect_cast )

			EmitSoundOn( "Hero_Tinker.LaserImpact", targets[i] )
		end
	end
end

function ability_laser:Refract( targets, jumps )
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		targets[jumps]:GetOrigin(),
		nil,
		self:GetSpecialValueFor("scepter_bounce_range"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
		FIND_CLOSEST,
		false
	)

	local next_target = nil
	for _,enemy in pairs(enemies) do
		local candidate = true
		for _,target in pairs(targets) do
			if enemy==target then
				candidate = false
				break
			end
		end
		if candidate then
			next_target = enemy
			break
		end
	end

	if next_target then
		table.insert( targets, next_target )
		self:Refract( targets, jumps+1 )
	end
end

modifier_ability_laser = {}

function modifier_ability_laser:IsHidden()
	return false
end

function modifier_ability_laser:IsDebuff()
	return true
end

function modifier_ability_laser:IsStunDebuff()
	return false
end

function modifier_ability_laser:IsPurgable()
	return true
end

function modifier_ability_laser:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MISS_PERCENTAGE,
	}
end

function modifier_ability_laser:GetModifierMiss_Percentage()
	return self:GetAbility():GetSpecialValueFor( "miss_rate" )
end