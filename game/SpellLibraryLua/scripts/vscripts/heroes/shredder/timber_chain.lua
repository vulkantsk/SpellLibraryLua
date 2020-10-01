ability_timber_chain = {}

LinkLuaModifier( "modifier_ability_timber_chain", "heroes/shredder/timber_chain", LUA_MODIFIER_MOTION_HORIZONTAL )

function ability_timber_chain:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local projectile_speed = self:GetSpecialValueFor( "speed" )
	local projectile_distance = self:GetSpecialValueFor( "range" )
	local projectile_radius = self:GetSpecialValueFor( "radius" )
	local projectile_direction = point-caster:GetOrigin()
	projectile_direction.z = 0
	projectile_direction = projectile_direction:Normalized()

	local tree_radius = self:GetSpecialValueFor( "chain_radius" )
	local vision = 100

	local effect = self:PlayEffects( caster:GetOrigin() + projectile_direction * projectile_distance, projectile_speed, projectile_distance/projectile_speed )

	local info = {
		Source = caster,
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		bDeleteOnHit = false,
		EffectName = "",
		fDistance = projectile_distance,
		fStartRadius = projectile_radius,
		fEndRadius = projectile_radius,
		vVelocity = projectile_direction * projectile_speed,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		fExpireTime = GameRules:GetGameTime() + 10.0,
		bProvidesVision = true,
		iVisionRadius = vision,
		iVisionTeamNumber = caster:GetTeamNumber(),
	}

	local projectile = ProjectileManager:CreateLinearProjectile(info)
	local ExtraData = {
		effect = effect,
		radius = tree_radius,
	}
	self.projectiles[ projectile ] = ExtraData
end

ability_timber_chain.projectiles = {}
function ability_timber_chain:OnProjectileThinkHandle( handle )
	local ExtraData = self.projectiles[ handle ]
	local location = ProjectileManager:GetLinearProjectileLocation( handle )

	local trees = GridNav:GetAllTreesAroundPoint( location, ExtraData.radius, false )

	if #trees>0 then
		local point = trees[1]:GetOrigin()

		self:GetCaster():AddNewModifier(
			self:GetCaster(),
			self,
			"modifier_ability_timber_chain",
			{
				point_x = point.x,
				point_y = point.y,
				point_Z = point.z,
				effect = ExtraData.effect,
			}
		)

		self:ModifyEffects2( ExtraData.effect, point )

		ProjectileManager:DestroyLinearProjectile( handle )
		self.projectiles[ handle ] = nil

		AddFOWViewer( self:GetCaster():GetTeamNumber(), point, 400, 1, true )
	end
end

function ability_timber_chain:OnProjectileHitHandle( target, location, handle )
	local ExtraData = self.projectiles[ handle ]
	if not ExtraData then return end

	AddFOWViewer( self:GetCaster():GetTeamNumber(), location, 400, 0.1, true )

	self:ModifyEffects1( ExtraData.effect )

	self.projectiles[ handle ] = nil
end

function ability_timber_chain:PlayEffects( point, speed, duration )
	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_shredder/shredder_timberchain.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(0,0,0),
		true
	)
	ParticleManager:SetParticleControl( effect_cast, 1, point )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( speed, 0, 0 ) )
	ParticleManager:SetParticleControl( effect_cast, 3, Vector( duration*2 + 0.3, 0, 0 ) )

	EmitSoundOn( "Hero_Shredder.TimberChain.Cast", self:GetCaster() )

	return effect_cast
end

function ability_timber_chain:ModifyEffects1( effect )
	ParticleManager:SetParticleControlEnt(
		effect,
		1,
		self:GetCaster(),
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_attack1",
		Vector(0,0,0),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect )

	EmitSoundOn( "Hero_Shredder.TimberChain.Retract", self:GetCaster() )
end

function ability_timber_chain:ModifyEffects2( effect, point )
	ParticleManager:SetParticleControl( effect, 1, point )

	ParticleManager:SetParticleControl( effect, 3, Vector( 20, 0, 0 ) )
	EmitSoundOn( "Hero_Shredder.TimberChain.Retract", self:GetCaster() )
	EmitSoundOnLocationWithCaster( point, "Hero_Shredder.TimberChain.Impact", self:GetCaster() )
end

modifier_ability_timber_chain = {}

function modifier_ability_timber_chain:IsHidden()
	return false
end

function modifier_ability_timber_chain:IsDebuff()
	return false
end

function modifier_ability_timber_chain:IsStunDebuff()
	return false
end

function modifier_ability_timber_chain:IsPurgable()
	return false
end

function modifier_ability_timber_chain:OnCreated( kv )
	if not IsServer() then return end

	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.speed = self:GetAbility():GetSpecialValueFor( "speed" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.point = Vector( kv.point_x, kv.point_y, kv.point_z )
	self.effect = kv.effect

	self.damageTable = {
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self:GetAbility(),
	}

	self.proximity = 50
	self.caught_enemies = {}

	if not self:ApplyHorizontalMotionController() then
		self:Destroy()
	end
end

function modifier_ability_timber_chain:OnRefresh( kv )
	if not IsServer() then return end
	local old_effect = self.effect

	local damage = self:GetAbility():GetSpecialValueFor( "damage" )
	self.speed = self:GetAbility():GetSpecialValueFor( "speed" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	self.point = Vector( kv.point_x, kv.point_y, kv.point_z )
	self.effect = kv.effect

	self.damageTable.damage = damage

	self.caught_enemies = {}

	ParticleManager:DestroyParticle( old_effect, false )
	ParticleManager:ReleaseParticleIndex( old_effect )
end

function modifier_ability_timber_chain:OnDestroy()
	if not IsServer() then return end

	ParticleManager:DestroyParticle( self.effect, false )
	ParticleManager:ReleaseParticleIndex( self.effect )

	EmitSoundOn( "Hero_Shredder.TimberChain.Impact", self:GetParent() )
end

function modifier_ability_timber_chain:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_ability_timber_chain:UpdateHorizontalMotion( me, dt )
	local origin = me:GetOrigin()
	local direction = (self.point-origin)
	direction.z = 0
	direction = direction:Normalized()

	local target = origin + direction * self.speed * dt
	me:SetOrigin( target )

	local enemies = FindUnitsInRadius(
		me:GetTeamNumber(),
		origin,
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		0,
		0,
		false
	)

	for _,enemy in pairs(enemies) do
		if not self.caught_enemies[enemy] then
			self.caught_enemies[enemy] = true

			self.damageTable.victim = enemy
			ApplyDamage( self.damageTable )

			self:PlayEffects( enemy )
		end
	end

	if me:IsStunned() then
		me:RemoveHorizontalMotionController( self )
		self:Destroy()
	end

	if (self.point-origin):Length2D()<self.proximity then
		GridNav:DestroyTreesAroundPoint( self:GetParent():GetOrigin(), 20, true )

		self:GetParent():SetOrigin( self.point )

		me:RemoveHorizontalMotionController( self )
		self:Destroy()
	end
end

function modifier_ability_timber_chain:OnHorizontalMotionInterrupted()
	self:GetParent():RemoveHorizontalMotionController( self )
	self:Destroy()
end

function modifier_ability_timber_chain:PlayEffects( target )
	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_shredder/shredder_timber_dmg.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Shredder.TimberChain.Damage", target )
end