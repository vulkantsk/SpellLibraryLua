LinkLuaModifier( "modifier_ability_burrowstrike", "heroes/sand_king/burrowstrike", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ability_burrowstrike_move", "heroes/sand_king/burrowstrike", LUA_MODIFIER_MOTION_BOTH )

ability_burrowstrike = {}

function ability_burrowstrike:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()
	if target then point = target:GetAbsOrigin() end
	local origin = caster:GetAbsOrigin()
	local width = self:GetSpecialValueFor("burrow_width")
	local projectile_direction = (point-origin)
	projectile_direction.z = 0
	projectile_direction = projectile_direction:Normalized()
	ProjectileManager:CreateLinearProjectile({
		Source = caster,
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		bDeleteOnHit = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fDistance = (point-origin):Length2D(),
		fStartRadius = width,
		fEndRadius = width,
		vVelocity = projectile_direction * self:GetSpecialValueFor("burrow_speed"),
	})

	caster:AddNewModifier(
		caster,
		self,
		"modifier_ability_burrowstrike",
		{ 
			duration = self:GetSpecialValueFor("burrow_anim_time"),
			pos_x = point.x,
			pos_y = point.y,
			pos_z = point.z,
		}
	)

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_sandking/sandking_burrowstrike.vpcf",
		PATTACH_WORLDORIGIN,
		self:GetCaster()
	)
	ParticleManager:SetParticleControl( effect_cast, 0, origin )
	ParticleManager:SetParticleControl( effect_cast, 1, point )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Ability.SandKing_BurrowStrike", self:GetCaster() )
end

function ability_burrowstrike:OnProjectileHit( target, location )
	if not target then return end

	if target:TriggerSpellAbsorb( self ) then return end

	local pos = target:GetAbsOrigin()

	target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_stunned",
		{ duration = self:GetSpecialValueFor( "burrow_duration" ) }
	)

	target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_knockback",
		{
			should_stun = 1,
			knockback_duration = 0.52,
			duration = 0.52,
			knockback_distance = 0,
			knockback_height = 350,
			center_x = pos.x,
			center_y = pos.y,
			center_z = pos.z
		}
	)

	ApplyDamage({
		victim = target,
		attacker = self:GetCaster(),
		damage = self:GetAbilityDamage(),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self,
	})
end

modifier_ability_burrowstrike = {}

function modifier_ability_burrowstrike:IsHidden()
	return true
end

function modifier_ability_burrowstrike:IsPurgable()
	return false
end

function modifier_ability_burrowstrike:OnCreated( kv )
	if IsServer() then
		self.point = Vector( kv.pos_x, kv.pos_y, kv.pos_z )
		self:StartIntervalThink( self:GetDuration()/2 )
		self:GetParent():AddNoDraw()
	end
end

function modifier_ability_burrowstrike:OnIntervalThink()
	FindClearSpaceForUnit( self:GetParent(), self.point, true )
end

function modifier_ability_burrowstrike:CheckState()
	return { [MODIFIER_STATE_STUNNED] = true }
end

function modifier_ability_burrowstrike:OnDestroy()
	if IsServer() then
		self:GetParent():RemoveNoDraw()
	end
end