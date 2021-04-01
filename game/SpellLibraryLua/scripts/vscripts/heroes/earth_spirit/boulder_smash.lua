LinkLuaModifier( "modifier_ability_boulder_smash", "heroes/earth_spirit/boulder_smash", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_ability_boulder_smash_slow", "heroes/earth_spirit/boulder_smash", LUA_MODIFIER_MOTION_NONE )

ability_boulder_smash = {}

function ability_boulder_smash:GetCastRange( vLocation, hTarget )
	if IsServer() then
		local radius = self:GetSpecialValueFor("rock_search_aoe")
		local max = self:GetSpecialValueFor("rock_distance")

		if self:SearchRemnant( self:GetCaster():GetAbsOrigin(), radius ) then
			return max
		end

		if not hTarget and not self:SearchRemnant( vLocation, radius ) then
			return max
		end

		return self.BaseClass.GetCastRange( self, vLocation, hTarget )
	end
end

function ability_boulder_smash:CastFilterResultTarget( hTarget )
	if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end

	local nResult = UnitFilter(
		hTarget,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		DOTA_UNIT_TARGET_FLAG_NONE,
		self:GetCaster():GetTeamNumber()
	)

	if nResult ~= UF_SUCCESS then
		return nResult
	end

	return UF_SUCCESS
end

function ability_boulder_smash:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("rock_search_aoe")
	local dirX = 0
	local dirY = 0
	local kicked = nil
	local isRemnant = false
	local remnant = self:SearchRemnant( caster:GetAbsOrigin(), radius )

	if remnant then
		dirX = point.x-caster:GetAbsOrigin().x
		dirY = point.y-caster:GetAbsOrigin().y
		kicked = remnant
		isRemnant = true
	else
		if target then
			dirX = target:GetAbsOrigin().x-caster:GetAbsOrigin().x
			dirY = target:GetAbsOrigin().y-caster:GetAbsOrigin().y
			kicked = target
		else
			self:RefundManaCost()
			self:EndCooldown()
			return
		end
	end

	self:Kick( kicked, dirX, dirY, isRemnant )
end

function ability_boulder_smash:OnProjectileHit_ExtraData( hTarget, vLocation, extraData )
	if not hTarget then return end

	local damageTable = {
		victim = hTarget,
		attacker = self:GetCaster(),
		damage = extraData.damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self,
	}

	ApplyDamage(damageTable)

	if extraData.isRemnant==1 then
		hTarget:AddNewModifier(
			self:GetCaster(),
			self,
			"modifier_ability_boulder_smash_slow",
			{
				duration = self:GetSpecialValueFor("duration"),
			}
		)
	end

	EmitSoundOn( "Hero_EarthSpirit.BoulderSmash.Damage", hTarget )

	return false
end

function ability_boulder_smash:SearchRemnant( point, radius )
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

function ability_boulder_smash:Kick( target, x, y, isRemnant )
	local damage = self:GetSpecialValueFor("rock_damage")
	local radius = self:GetSpecialValueFor("radius")
	local speed = self:GetSpecialValueFor("speed")
	local distance = self:GetSpecialValueFor("rock_distance")
	if not isRemnant then
		distance = self:GetSpecialValueFor("unit_distance")
	end

	local mod = target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_ability_boulder_smash",
		{
			x = x,
			y = y,
			r = distance,
		}
	)

	local info = {
		Source = self:GetCaster(),
		Ability = self,
		vSpawnOrigin = target:GetAbsOrigin(),
		
	    bDeleteOnHit = false,
	    
	    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
	    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
	    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	    
	    EffectName = "",
	    fDistance = distance,
	    fStartRadius = radius,
	    fEndRadius =radius,
		vVelocity = Vector(x,y,0):Normalized() * speed,
	
		bHasFrontalCone = false,
		bReplaceExisting = false,
		
		bProvidesVision = false,

		ExtraData = {
			isRemnant = isRemnant,
			damage = damage
		}
	}
	ProjectileManager:CreateLinearProjectile(info)

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_earth_spirit/espirit_bouldersmash_caster.vpcf",
		PATTACH_WORLDORIGIN,
		nil
	)
	ParticleManager:SetParticleControl( effect_cast, 1, target:GetAbsOrigin() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_EarthSpirit.BoulderSmash.Cast", self:GetCaster() )

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_earth_spirit/espirit_bouldersmash_target.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		target
	)
	ParticleManager:SetParticleControlForward( effect_cast, 1, Vector(x,y,0):Normalized() )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( distance/speed, 0, 0 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_EarthSpirit.BoulderSmash.Target", target )
end

modifier_ability_boulder_smash = {}

function modifier_ability_boulder_smash:IsHidden()
	return false
end

function modifier_ability_boulder_smash:IsDebuff()
	return true
end

function modifier_ability_boulder_smash:IsStunDebuff()
	return false
end

function modifier_ability_boulder_smash:IsPurgable()
	return false
end

function modifier_ability_boulder_smash:OnCreated( kv )
	if IsServer() then
		self.distance = kv.r
		self.direction = Vector(kv.x,kv.y,0):Normalized()
		self.speed = self:GetAbility():GetSpecialValueFor( "speed" )
		self.damage = self:GetAbility():GetSpecialValueFor( "rock_damage" )
		self.origin = self:GetParent():GetAbsOrigin()

		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
		end
	end
end

function modifier_ability_boulder_smash:OnRefresh( kv )
	if IsServer() then
		self.distance = kv.r
		self.direction = Vector(kv.x,kv.y,0):Normalized()
		self.speed = self:GetAbility():GetSpecialValueFor( "speed" )
		self.damage = self:GetAbility():GetSpecialValueFor( "rock_damage" )
		self.origin = self:GetParent():GetAbsOrigin()

		if self:ApplyHorizontalMotionController() == false then 
			self:Destroy()
		end
	end	
end

function modifier_ability_boulder_smash:OnDestroy( kv )
	if IsServer() then
		self:GetParent():InterruptMotionControllers( true )
	end
end

function modifier_ability_boulder_smash:UpdateHorizontalMotion( me, dt )
	local pos = self:GetParent():GetAbsOrigin()

	if (pos-self.origin):Length2D()>=self.distance then
		self:Destroy()
		return
	end

	local target = pos + self.direction * (self.speed*dt)

	self:GetParent():SetAbsOrigin( target )
end

function modifier_ability_boulder_smash:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_ability_boulder_smash:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
end

function modifier_ability_boulder_smash:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

modifier_ability_boulder_smash_slow = {}

function modifier_ability_boulder_smash_slow:IsHidden()
	return false
end

function modifier_ability_boulder_smash_slow:IsDebuff()
	return true
end

function modifier_ability_boulder_smash_slow:IsStunDebuff()
	return false
end

function modifier_ability_boulder_smash_slow:IsPurgable()
	return true
end

function modifier_ability_boulder_smash_slow:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "move_slow" )
end

function modifier_ability_boulder_smash_slow:OnRefresh( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "move_slow" )	
end
function modifier_ability_boulder_smash_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end
function modifier_ability_boulder_smash_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end